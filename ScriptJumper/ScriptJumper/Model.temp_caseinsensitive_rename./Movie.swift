//
//  Movie.swift
//  ScriptJumper
//
//  Created by 현지훈 on 16/05/2019.
//  Copyright © 2019 현지훈. All rights reserved.
//

import Foundation

struct Movie {
    let name: String
    let url: URL
    let subtitleUrl: URL?
    let size: UInt64?
    let creationDate: Date?
    
    init(url: URL, subtitleUrl: URL?) {
        self.url = url
        self.subtitleUrl = subtitleUrl
        self.name = url.lastPathComponent
        self.size = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? UInt64
        self.creationDate = try? FileManager.default.attributesOfItem(atPath: url.path)[.creationDate] as? Date
    }
}
