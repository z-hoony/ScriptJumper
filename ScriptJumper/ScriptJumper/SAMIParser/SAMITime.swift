//
//  SAMITime.swift
//  ScriptJumper
//
//  Created by 현지훈 on 09/05/2019.
//  Copyright © 2019 현지훈. All rights reserved.
//

import Foundation
import CoreMedia

struct SAMITime: CustomStringConvertible {
    static let timescale: Int = 1000
    static let msecPerSec: Int = 1 * timescale
    static let msecPerMin: Int = 60 * msecPerSec
    static let mSecPerHour: Int = 60 * msecPerMin
    
    var hour: Int {
        return time / SAMITime.mSecPerHour
    }
    
    var min: Int {
        return (time % SAMITime.mSecPerHour) / SAMITime.msecPerMin
    }
    
    var second: Float {
        return Float((time % SAMITime.msecPerMin) / SAMITime.msecPerSec)
    }
    
    let time: Int
    
    init(_ time: Int) {
        self.time = time
    }
    
    init?(_ time: Int?) {
        guard let time = time else { return nil }
    
        self.time = time
    }
    
    var description: String {
        return String(format: "%02d:%02d:%05.2f", hour, min, second)
    }
    
    var simpleDescription: String {
        return String(format: "%02d:%02d:%02d", hour, min, Int(second))
    }
}

extension SAMITime {
    var cmTime: CMTime {
        return CMTime(value: CMTimeValue(self.time), timescale: CMTimeScale(SAMITime.timescale))
    }
}

extension CMTime {
    var samiTime: SAMITime {
        return SAMITime(Int(self.convertScale(Int32(SAMITime.timescale), method: .default).value))
    }
}
