//
//  PlayerViewController.swift
//  ScriptJumper
//
//  Created by 현지훈 on 16/05/2019.
//  Copyright © 2019 현지훈. All rights reserved.
//

import UIKit
import AVFoundation

class PlayerViewController: UIViewController {
    @IBOutlet private weak var playerView: PlayerView!
    @IBOutlet private weak var subtitleView: SubtitleView!
    @IBOutlet private weak var subtitleLabel: SubtitleLabel!
    @IBOutlet private weak var controlsView: ControlsView!
    @IBOutlet private weak var subtitleLabelBottomAnchor: NSLayoutConstraint!
    @IBOutlet private weak var subtitleLabelCenterXAnchor: NSLayoutConstraint!
    @IBOutlet private weak var subtitleLabelWidthAnchor: NSLayoutConstraint!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var prefersStatusBarHidden: Bool {
        if self.controlsView.getIsHidden() {
            return true
        }
        return false
    }
    
    static let nonBreakSpace: String = "&nbsp;"
    static let subtitleLabelCornerRadius: CGFloat = 4
    static let subtitleLabelBottomMargin: CGFloat = 16
    static let subtitleLabelHorizontalMargin: CGFloat = 32
    
    private var doubleTapGestureRecognizer: UITapGestureRecognizer!
    private var singleTapGestureRecognizer: UITapGestureRecognizer!
    
    private var player: AVPlayer!
    private var periodicTimeObserverToken: Any?
    private var boundaryTimeObserverToken: Any?
    private var itemDurationContext = 0
    private var playerRateContext = 0
    
    private var syncs: [SAMISync]?
    private var filteredSyncs: [SAMISync]?
    var movie: Movie?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
        } catch {
            print("세선 카테고리 설정 실패")
        }
        
        guard let movie = movie else { return }
        
        setupUI()
        setupPlayer(movie.url)
        loadSyncs(movie.subtitleUrl)
        
        self.player.play()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if movie == nil {
            let ac = UIAlertController(title: "오류", message: "동영상을 재생할 수 없습니다.", preferredStyle: .alert)
            let action = UIAlertAction(title: "확인", style: .default) { [weak self] _ in
                self?.dismiss(animated: true) { [weak self] in
                    self?.resignPlayer()
                }
            }
            ac.addAction(action)
            present(ac, animated: true, completion: nil)
        }
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("세션 활성화 오류")
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if subtitleLabelCenterXAnchor.constant != 0 {
            subtitleLabelCenterXAnchor.constant = -self.subtitleView.bounds.width/2
            subtitleLabelWidthAnchor.constant = -PlayerViewController.subtitleLabelHorizontalMargin - self.subtitleView.bounds.width
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVPlayerItem.duration) {
            guard let duration = change?[.newKey] as? CMTime else { return }
            
            self.controlsView.setTimeSliderMaximum(Float(duration.samiTime.time))
            self.controlsView.setDuration(duration.samiTime.simpleDescription)
        } else if (keyPath == #keyPath(AVPlayer.rate)) {
            guard let rate = change?[.newKey] as? Float else { return }
            
            if rate != 0 {
                self.controlsView.setPlayButton(true)
            } else {
                self.controlsView.setPlayButton(false)
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    func setupUI() {
        self.subtitleView.delegate = self
        self.controlsView.delegate = self
        
        singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(singleTap))
        singleTapGestureRecognizer.numberOfTapsRequired = 1
        
        doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTap))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        
        self.playerView.addGestureRecognizer(singleTapGestureRecognizer)
        self.playerView.addGestureRecognizer(doubleTapGestureRecognizer)
        
        singleTapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
        
        subtitleLabel.layer.cornerRadius = PlayerViewController.subtitleLabelCornerRadius
        subtitleLabel.clipsToBounds = true
        
        controlsView.setTitle(movie?.name)
        
        if movie?.subtitleUrl == nil {
            self.controlsView.setSubtitleListButton(false)
        }
    }
    
    func setupPlayer(_ url: URL) {
        self.player = AVPlayer(url: url)
        self.playerView.player = self.player
        self.player.seek(to: .zero)
        self.addPeriodicTimeObserver()
        
        player.addObserver(self,
                           forKeyPath: #keyPath(AVPlayer.rate),
                           options: [.new],
                           context: &playerRateContext)
        
        if let item = player.currentItem {
            item.addObserver(self,
                                   forKeyPath: #keyPath(AVPlayerItem.duration),
                                   options: [.new],
                                   context: &itemDurationContext)
        }
        
    }
    
    func loadSyncs(_ url: URL?) {
        let content = fileRead(url)
        let parser = SAMIParser()
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            let tags = parser.parse(content)
            //원본 자막
            self?.syncs = tags?
                .toSyncs()
                .filter { $0.time != nil }
                .sorted { $0.time!.time < $1.time!.time }
            
            //공백 제거 및 검색 필터 적용될 자막
            self?.filteredSyncs = self?.syncs?
                .filter { $0.paragraphs.first?.content != PlayerViewController.nonBreakSpace }
            
            DispatchQueue.main.async { [weak self] in
                self?.subtitleView.reloadData()
                self?.addBoundaryTimeObserver()
            }
        }
    }
    
    func fileRead(_ url: URL?, encoding: String.Encoding = .utf8) -> String? {
        guard let url = url else { return nil }
        
        return try? String(contentsOf: url, encoding: encoding)
    }
    
    @objc func doubleTap() {
        self.playerView.playerLayer.videoGravity = self.playerView.playerLayer.videoGravity == .resizeAspect ? .resizeAspectFill : .resizeAspect
    }
    
    @objc func singleTap() {
        if self.controlsView.isHidden {
            self.controlsShow()
        } else {
            self.controlsHide()
        }
    }
    
    func controlsShow() {
        subtitleLabelBottomAnchor.constant = PlayerViewController.subtitleLabelBottomMargin + ControlsView.controlsHeight
        self.controlsView.show()
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    func controlsHide() {
        subtitleLabelBottomAnchor.constant = PlayerViewController.subtitleLabelBottomMargin
        self.controlsView.hide()
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    func subtitleViewShow() {
        subtitleLabelCenterXAnchor.constant = -self.subtitleView.bounds.width/2
        subtitleLabelWidthAnchor.constant = -PlayerViewController.subtitleLabelHorizontalMargin - self.subtitleView.bounds.width
        self.subtitleView.show()
    }
    
    func subtitleViewHide() {
        subtitleLabelCenterXAnchor.constant = 0
        subtitleLabelWidthAnchor.constant = -PlayerViewController.subtitleLabelHorizontalMargin
        self.subtitleView.hide()
    }
    
    func addPeriodicTimeObserver() {
        let time = CMTime(value: 500, timescale: CMTimeScale(SAMITime.timescale))
        periodicTimeObserverToken = player.addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] time in
            self?.controlsView.setCurrentTime(time.samiTime.simpleDescription)
            
            if self?.controlsView.getSliderIsTracking() == false {
                self?.controlsView.setTimeSlider(Float(time.samiTime.time))
            }
        }
    }
    
    func removePeriodicTimeObserver() {
        if let timeObserverToken = periodicTimeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.periodicTimeObserverToken = nil
        }
    }
    
    // 동영상이 자막 시각과 일치하는 부분을 재생할때마다 알림을 받음
    func addBoundaryTimeObserver() {
        guard let syncs = self.syncs else { return }
        let times = syncs
            .compactMap { $0.time }
            .map { $0.cmTime }
            .map { NSValue(time: $0) }
        
        boundaryTimeObserverToken = player.addBoundaryTimeObserver(forTimes: times, queue: .main) { [weak self] in
            guard let player = self?.player else { return }
            guard let index = self?.findSubtitleIndex(for: self?.syncs, at: player.currentTime()) else { return }
            
            self?.showSubtitle(at: index)
        }
    }
    
    func removeBoundaryTimeObserver() {
        if let timeObserverToken = boundaryTimeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.boundaryTimeObserverToken = nil
        }
    }
    
    func showSubtitle(at index: Int) {
        guard let syncs = self.syncs else { return }
        
        guard index >= 0 && index < syncs.count else { return }
        
        if let content = syncs[index].paragraphs.first?.content, !content.isEmpty && content != PlayerViewController.nonBreakSpace {
            self.subtitleLabel.text = content
            self.subtitleLabel.isHidden = false
            if let time = syncs[index].time?.cmTime, let filteredIndex = findSubtitleIndex(for: self.filteredSyncs, at: time) {
                self.subtitleView.scrollToRow(at: IndexPath(row: filteredIndex, section: 0))
            }
        } else {
            self.subtitleLabel.text = nil
            self.subtitleLabel.isHidden = true
        }
    }
    
    // 이진 탐색으로 자막위치 찾기
    func findSubtitleIndex(for syncs: [SAMISync]?, at time: CMTime) -> Int? {
        guard let syncs = syncs else { return nil }
        guard syncs.count > 0 else { return nil }
        
        var min = 0
        var max = syncs.count-1
        
        var index = (min+max)/2
        
        while true {
            guard let lt = syncs[index].time?.cmTime else { break }
            guard index+1 < syncs.count, let rt = syncs[index+1].time?.cmTime else { break }
            guard time < lt || rt <= time else { break }
            guard min < max else { break }
            guard let t = syncs[index].time?.cmTime else { break }
            
            if t < time {
                min = index+1
                index = (min+max)/2
            } else {
                max = index-1
                index = (min+max)/2
            }
        }
        
        if index+1 == syncs.count {
            if let t = syncs[index].time?.cmTime, t <= time {
                return index
            }
        } else {
            if let lt = syncs[index].time?.cmTime, let rt = syncs[index+1].time?.cmTime, lt <= time && time < rt {
                return index
            }
        }
        
        return nil
    }
    
    deinit {
        resignPlayer()
    }
    
    func resignPlayer() {
        self.removePeriodicTimeObserver()
        self.removeBoundaryTimeObserver()
        self.player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.rate), context: &playerRateContext)
        
        if let item = player.currentItem {
            item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.duration), context: &itemDurationContext)
        }
        
        player.rate = 0
    }
}

extension PlayerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let time = self.filteredSyncs?[indexPath.row].time else { return }
        
        self.player.seek(to: time.cmTime-CMTime(value: CMTimeValue(SAMITime.timescale/2), timescale: CMTimeScale(SAMITime.timescale)),
                         toleranceBefore: CMTime(value: CMTimeValue(SAMITime.timescale/2), timescale: CMTimeScale(SAMITime.timescale)),
                         toleranceAfter: .zero)
    }
}

extension PlayerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredSyncs?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dequeueCell = tableView.dequeueReusableCell(withIdentifier: SubtitleTableViewCell.identifier, for: indexPath)
        
        guard let cell = dequeueCell as? SubtitleTableViewCell else {
            return dequeueCell
        }
        
        guard indexPath.row < (self.filteredSyncs?.count ?? 0) else { return cell }
        
        cell.setTimeLabel(text: filteredSyncs?[indexPath.row].time?.description)
        cell.setSubtitleLabel(text: filteredSyncs?[indexPath.row].paragraphs.first?.content)
        
        return cell
    }
}

extension PlayerViewController: SubtitleViewDelegate {
    func searchBar(textDidChange searchText: String) {
        let text = searchText.lowercased()
        
        self.filteredSyncs = self.syncs?
            .filter {
                $0.paragraphs.first?.content != PlayerViewController.nonBreakSpace
                && ( searchText.isEmpty
                    || $0.paragraphs.first!.content.lowercased().contains(text)
                    || $0.time!.description.lowercased().contains(text)
                )
            }
            .filter { $0.time != nil }
            .sorted { $0.time!.time < $1.time!.time }
        self.subtitleView.reloadData()
    }
    
    func subtitleCloseButtonTouched() {
        self.subtitleViewHide()
    }
}

extension PlayerViewController: ControlsViewDelegate {
    func dismissTouched() {
        self.dismiss(animated: true) { [weak self] in
            self?.resignPlayer()
        }
    }
    
    func showSubtitleListTouched() {
        self.controlsHide()
        self.subtitleViewShow()
    }
    
    func playAndPauseTouched() {
        if player.rate != 0 {
            player.rate = 0
        } else {
            player.rate = 1
        }
    }
    
    func timeSliderChanged(_ value: Float) {
        let time = SAMITime(Int(value)).cmTime
        self.player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] isCompleted in
            if isCompleted {
                guard let index = self?.findSubtitleIndex(for: self?.syncs, at: time) else { return }
                
                self?.showSubtitle(at: index)
            }
        }
    }
}
