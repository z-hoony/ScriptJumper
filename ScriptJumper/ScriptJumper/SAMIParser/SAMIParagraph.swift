//
//  SAMIParagraph.swift
//  ScriptJumper
//
//  Created by 현지훈 on 09/05/2019.
//  Copyright © 2019 현지훈. All rights reserved.
//

import Foundation

struct SAMIParagraph: CustomStringConvertible {
    let `class`: String?
    let content: String

    var description: String {
        guard let cls = self.class else { return self.content }
        return "[\(cls)]\n\(self.content)"
    }
}
