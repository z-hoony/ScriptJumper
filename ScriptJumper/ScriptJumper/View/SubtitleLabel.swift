//
//  SubtitleLabel.swift
//  ScriptJumper
//
//  Created by 현지훈 on 16/05/2019.
//  Copyright © 2019 현지훈. All rights reserved.
//

import UIKit

class SubtitleLabel: UILabel {
    static let horizontalPadding: CGFloat = 8
    static let verticalPadding: CGFloat = 4

    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: SubtitleLabel.verticalPadding,
                                  left: SubtitleLabel.horizontalPadding,
                                  bottom: SubtitleLabel.verticalPadding,
                                  right: SubtitleLabel.horizontalPadding)
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.width += SubtitleLabel.horizontalPadding * 2
        size.height += SubtitleLabel.verticalPadding * 2
        return size
    }
}
