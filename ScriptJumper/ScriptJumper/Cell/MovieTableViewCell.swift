//
//  MovieTableViewCell.swift
//  ScriptJumper
//
//  Created by 현지훈 on 16/05/2019.
//  Copyright © 2019 현지훈. All rights reserved.
//

import UIKit

class MovieTableViewCell: UITableViewCell {
    @IBOutlet private weak var fileNameLabel: UILabel!
    @IBOutlet private weak var fileSizeLabel: UILabel!
    @IBOutlet private weak var fileCreationTimeLabel: UILabel!
    @IBOutlet private weak var subtitleExistLabel: UILabel!

    static let identifier = "movieCell"

    func setFileNameLabel(text: String?) {
        fileNameLabel.text = text
    }

    func setFileSizeLabel(text: String?) {
        fileSizeLabel.text = text
    }

    func setFileCreationTimeLabel(text: String?) {
        fileCreationTimeLabel.text = text
    }

    func setSubtitleExistLabel(text: String?) {
        subtitleExistLabel.text = text
    }
}
