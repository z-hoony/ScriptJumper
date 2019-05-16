//
//  SAMITime.swift
//  ScriptJumper
//
//  Created by 현지훈 on 09/05/2019.
//  Copyright © 2019 현지훈. All rights reserved.
//

import Foundation

struct SAMITime: CustomStringConvertible {
    let hour: Int, min: Int, second: Float
    let time: Int
    
    init?(_ time: Int?) {
        guard let time = time else { return nil }
        
        self.second = Float(time % (60 * 1000)) / 1000
        self.min = (time % (60 * 60 * 1000)) / (60 * 1000)
        self.hour = time / (60 * 60 * 1000)
        self.time = time
    }
    
    var description: String {
        return String(format: "%02d:%02d:%05.2f", hour, min, second)
    }
}
