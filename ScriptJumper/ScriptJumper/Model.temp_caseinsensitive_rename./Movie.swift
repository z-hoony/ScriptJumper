//
//  Movie.swift
//  ScriptJumper
//
//  Created by 현지훈 on 16/05/2019.
//  Copyright © 2019 현지훈. All rights reserved.
//

import Foundation

struct Movie {
    let url: URL
    let subtitleUrl: URL?
    
    var name: String {
        return url.lastPathComponent
    }
    
    var size: UInt64? {
        return try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? UInt64
    }
    
    var creationDate: Date? {
        return try? FileManager.default.attributesOfItem(atPath: url.path)[.creationDate] as? Date
    }
    
    init(url: URL, subtitleUrl: URL?) {
        self.url = url
        self.subtitleUrl = subtitleUrl
    }
}
