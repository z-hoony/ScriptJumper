//
//  SAMIParser.swift
//  ScriptJumper
//
//  Created by 현지훈 on 09/05/2019.
//  Copyright © 2019 현지훈. All rights reserved.
//

import Foundation

enum Status {
    case tag
    case optionName
    case optionValue
    case content
    case ready
    case close
}

class Tag {
    var status: Status
    var name: String
    var options: [String:String]
    var content: String
    
    init(status: Status = .ready) {
        self.status = status
        self.name = ""
        self.options = [:]
        self.content = ""
    }
}

struct SAMIParser {
    private let ignorableOpenTags: [String] = ["font", "i", "b", "u", "small", "big", "sub", "sup", "q", "s"]
    private let ignorableCloseTags: [String] = ["/font", "/i", "/b", "/u", "/small", "/big", "/sub", "/sup", "/q", "/s"]
    private var ignorableTags: [String] { return ignorableOpenTags + ignorableCloseTags }
    
    func parse(_ forString: String?) -> [Tag]? {
        guard let forString = forString else { return nil }
        
        var optionName = ""
        var preOptionName = ""
        var optionValue = ""
        var tags = [Tag(status: .ready)]
        
        for char in forString {
            guard let last = tags.last else { return nil }
            
            switch last.status {
            case .tag:
                if char == ">" {
                    if last.name.lowercased() == "br" || last.name.lowercased() == "br/" {
                        tags.removeLast()
                        tags.last?.content += "<br>"
                        tags.last?.status = .content
                        continue
                    } else if ignorableTags.contains(last.name.lowercased()) {
                        tags.removeLast()
                        tags.last?.status = .content
                        continue
                    } else if let first = last.name.first, first == "/" {
                        tags.removeLast()
                        for num in (0..<tags.count).reversed() {
                            tags[num].status = .close
                            if tags[num].name.lowercased() == last.name.dropFirst().lowercased() { break }
                        }
                    }
                    last.status = .content
                } else if last.name.isEmpty || !char.isWhitespace {
                    last.name = "\(last.name)\(char)".trimmed
                } else {
                    optionName = ""
                    last.status = .optionName
                }
            case .optionName:
                if char == "=" {
                    if optionName.isEmpty { optionName = preOptionName }
                    optionName = optionName.trimmed.lowercased()
                    optionValue = ""
                    last.status = .optionValue
                } else if char == ">" {
                    if ignorableOpenTags.contains(last.name.lowercased()) {
                        tags.removeLast()
                        tags.last?.status = .content
                        continue
                    }
                    last.status = .content
                } else if optionName.isEmpty || !char.isWhitespace {
                    optionName = "\(optionName)\(char)".trimmed
                } else {
                    preOptionName = optionName
                    optionName = ""
                }
            case .optionValue:
                if char == ">" {
                    if ignorableOpenTags.contains(last.name.lowercased()) {
                        tags.removeLast()
                        tags.last?.status = .content
                        continue
                    }
                    last.options[optionName] = optionValue
                    last.status = .content
                } else if optionValue.isEmpty
                    || (optionValue.first?.isQuote != true
                    && !char.isWhitespace) {
                    optionValue = "\(optionValue)\(char)".trimmed
                } else if optionValue.first?.isQuote == true {
                    if (optionValue.first == char) {
                        last.options[optionName] = String(optionValue.dropFirst())
                        optionName = ""
                        last.status = .optionName
                    } else {
                        optionValue = "\(optionValue)\(char)"
                    }
                } else {
                    last.options[optionName] = optionValue
                    optionName = ""
                    last.status = .optionName
                }
            case .content:
                if char == "<" {
                    last.content = last.content.trimmed.replacingOccurrences(of: "<br>", with: "\n")
                    last.status = .tag
                    tags.append(Tag(status: .tag))
                } else if !char.isNewline {
                    for num in (0..<tags.count).reversed() {
                        if tags[num].status != .close {
                            tags[num].content += "\(char)"
                            break
                        }
                    }
                }
            case .close: fallthrough
            case .ready:
                if char == "<" {
                    last.content = last.content.trimmed
                    if last.status != .close {
                        last.status = .ready
                    }
                    tags.append(Tag(status: .tag))
                } else {
                    for num in (0..<tags.count).reversed() {
                        if tags[num].status != .close {
                            if !char.isNewline {
                                tags[num].content += "\(char)"
                            }
                            break
                        }
                    }
                }
            }
        }
        return tags
    }
}

extension String {
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Character {
    var isQuote: Bool {
        return "\"'".contains(self)
    }
}

extension Array where Element == Tag {
    func toSyncs() -> [SAMISync] {
        let tags = self.filter { $0.name.lowercased() == "sync" || $0.name.lowercased() == "p" }
        var syncs = [SAMISync]()
        
        for tag in tags {
            if tag.name.lowercased() == "sync" {
                let time = tag.options["start"].map(Int.init)
                
                syncs.append(SAMISync(time: SAMITime(time ?? nil), paragraphs: []))
            } else {
                let cls = tag.options["class"]
                
                let para = SAMIParagraph(class: cls, content: tag.content)
                syncs[syncs.count-1].paragraphs.append(para)
            }
        }
        return syncs
    }
}
