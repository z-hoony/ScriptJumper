//
//  ControlsView.swift
//  ScriptJumper
//
//  Created by 현지훈 on 16/05/2019.
//  Copyright © 2019 현지훈. All rights reserved.
//

import UIKit

class ControlsView: UIView {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleListButton: UIButton!
    @IBOutlet private weak var currentTimeLabel: UILabel!
    @IBOutlet private weak var timeSlider: UISlider!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var emptyView: UIView!
    @IBOutlet private weak var playButton: UIButton!
    
    static let controlsHeight: CGFloat = 50
    
    var delegate: ControlsViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupUI()
    }
    
    func setupUI() {
        guard let contentView = Bundle.main.loadNibNamed(String(describing: ControlsView.self), owner: self, options: nil)?.first as? UIView else { return }
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: self.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
            ])
        
        let singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(singleTap))
        singleTapGestureRecognizer.numberOfTapsRequired = 1
        
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTap))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        
        self.emptyView.addGestureRecognizer(singleTapGestureRecognizer)
        self.emptyView.addGestureRecognizer(doubleTapGestureRecognizer)
        
        singleTapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
    }
    
    func setTimeSlider(_ value: Float) {
        self.timeSlider.setValue(value, animated: false)
    }
    
    func setTimeSliderMaximum(_ value: Float) {
        self.timeSlider.maximumValue = value
    }
    
    func getSliderIsTracking() -> Bool {
        return self.timeSlider.isTracking
    }
    
    func setCurrentTime(_ text: String?) {
        self.currentTimeLabel.text = text
    }
    
    func setDuration(_ text: String?) {
        self.durationLabel.text = text
    }
    
    func setPlayButton(_ isPlaying: Bool) {
        if isPlaying {
            playButton.setTitle("정지", for: .normal)
        } else {
            playButton.setTitle("재생", for: .normal)
        }
    }
    
    func setSubtitleListButton(_ isEnabled: Bool) {
        subtitleListButton.isEnabled = isEnabled
    }
    
    func setTitle(_ text: String?) {
        self.titleLabel.text = text
    }
    
    func hide() {
        self.isHidden = true
    }
    
    func show() {
        self.isHidden = false
    }
    
    func getIsHidden() -> Bool {
        return self.isHidden
    }
    
    @objc func singleTap() {
        delegate?.singleTap()
    }
    
    @objc func doubleTap() {
        delegate?.doubleTap()
    }

    @IBAction private func closePlayer() {
        delegate?.dismissTouched()
    }
    
    @IBAction private func showSubtitleList() {
        delegate?.showSubtitleListTouched()
    }
    
    @IBAction private func playAndPause() {
        delegate?.playAndPauseTouched()
    }
    
    @IBAction private func timeSliderValueChanged(_ sender: UISlider) {
        delegate?.timeSliderChanged(sender.value)
    }
}

protocol ControlsViewDelegate {
    func dismissTouched()
    func showSubtitleListTouched()
    func playAndPauseTouched()
    func singleTap()
    func doubleTap()
    func timeSliderChanged(_ value: Float)
}
