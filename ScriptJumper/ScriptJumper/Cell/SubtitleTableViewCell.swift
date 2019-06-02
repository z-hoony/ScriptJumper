//
//  SubtitleTableViewCell.swift
//  ScriptJumper
//
//  Created by 현지훈 on 16/05/2019.
//  Copyright © 2019 현지훈. All rights reserved.
//

import UIKit

class SubtitleTableViewCell: UITableViewCell {
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    static let identifier = "subtitleCell"

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        self.selectedBackgroundView = backgroundView
    }

    func setTimeLabel(text: String?) {
        timeLabel.text = text
    }

    func setSubtitleLabel(text: String?) {
        subtitleLabel.text = text
    }
}
