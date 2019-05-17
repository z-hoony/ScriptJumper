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
    private static let ignorableOpenTags: [String] = ["font", "i", "b", "u", "small", "big", "sub", "sup", "q", "s"]
    private static let ignorableTags: [String] = ["font", "i", "b", "u", "small", "big", "sub", "sup", "q", "s", "/font", "/i", "/b", "/u", "/small", "/big", "/sub", "/sup", "/q", "/s"]
    static let syncTagString = "sync"
    static let pTagString = "p"
    static let brTagString = "br"
    static let startOprionString = "start"
    static let classOptionString = "class"
    
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
                    if last.name.lowercased() == SAMIParser.brTagString || last.name.lowercased() == SAMIParser.brTagString + "/" {
                        tags.removeLast()
                        tags.last?.content += "<\(SAMIParser.brTagString)>"
                        tags.last?.status = .content
                        continue
                    } else if SAMIParser.ignorableTags.contains(last.name.lowercased()) {
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
                    if SAMIParser.ignorableOpenTags.contains(last.name.lowercased()) {
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
                    if SAMIParser.ignorableOpenTags.contains(last.name.lowercased()) {
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
                    last.content = last.content.trimmed.replacingOccurrences(of: "<\(SAMIParser.brTagString)>", with: "\n")
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
        let tags = self.filter { $0.name.lowercased() == SAMIParser.syncTagString || $0.name.lowercased() == SAMIParser.pTagString }
        var syncs = [SAMISync]()
        
        for tag in tags {
            if tag.name.lowercased() == SAMIParser.syncTagString {
                let time = tag.options[SAMIParser.startOprionString].map(Int.init)
                
                syncs.append(SAMISync(time: SAMITime(time ?? nil), paragraphs: []))
            } else {
                let cls = tag.options[SAMIParser.classOptionString]
                
                let para = SAMIParagraph(class: cls, content: tag.content)
                if syncs.count > 0 {
                    syncs[syncs.count-1].paragraphs.append(para)
                }
            }
        }
        syncs.removeFirst()
        return syncs
    }
}
