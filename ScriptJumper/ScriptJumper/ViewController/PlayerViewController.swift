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
    
    private var doubleTapGestureRecognizer: UITapGestureRecognizer!
    private var singleTapGestureRecognizer: UITapGestureRecognizer!
    
    private var player: AVPlayer!
    
    private var syncs: [SAMISync]?
    private var filteredSyncs: [SAMISync]?
    var movie: Movie?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        try? AVAudioSession.sharedInstance().setActive(true)
        
        guard let movie = movie else { dismiss(animated: true, completion: nil); return }
        
        setupUI()
        setupPlayer(movie.url)
        loadSyncs(movie.subtitleUrl)
    }
    
    func setupUI() {
        self.subtitleView.delegate = self
        
        singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(singleTap))
        singleTapGestureRecognizer.numberOfTapsRequired = 1
        
        doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTap))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        
        self.playerView.addGestureRecognizer(singleTapGestureRecognizer)
        self.playerView.addGestureRecognizer(doubleTapGestureRecognizer)
        
        singleTapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
        
        subtitleLabel.layer.cornerRadius = 4
        subtitleLabel.clipsToBounds = true
    }
    
    func setupPlayer(_ url: URL) {
        self.player = AVPlayer(url: url)
        self.playerView.player = self.player
        self.player.seek(to: .zero)
        self.player.play()
    }
    
    func loadSyncs(_ url: URL?) {
        let content = fileRead(url)
        let parser = SAMIParser()
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            let tags = parser.parse(content)
            self?.syncs = tags?
                .toSyncs()
            
            self?.filteredSyncs = self?.syncs?
                .filter { $0.paragraphs.first?.content != "&nbsp;" }
                .filter { $0.time != nil }
                .sorted { $0.time!.time < $1.time!.time }
            
            DispatchQueue.main.async { [weak self] in
                self?.subtitleView.reloadData()
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
        if self.subtitleView.isHidden {
            self.subtitleView.show()
        } else {
            self.subtitleView.hide()
        }
    }
    
    deinit {
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}

extension PlayerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let time = self.filteredSyncs?[indexPath.row].time else { return }
        self.player.seek(to: time.cmTime)
    }
}

extension PlayerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredSyncs?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "subtitleCell", for: indexPath) as! SubtitleTableViewCell
        
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        cell.selectedBackgroundView = selectedView
        
        guard indexPath.row < (self.filteredSyncs?.count ?? 0) else { return cell }
        
        cell.timeLabel.text = filteredSyncs?[indexPath.row].time?.description
        cell.subtitleLabel.text = filteredSyncs?[indexPath.row].paragraphs.first?.content
        
        return cell
    }
}

extension PlayerViewController: SubtitleViewDelegate {
    func searchBar(textDidChange searchText: String) {
        let text = searchText.lowercased()
        
        self.filteredSyncs = self.syncs?
            .filter {
                $0.paragraphs.first?.content != "&nbsp;"
                && ( searchText.isEmpty
                    || $0.paragraphs.first!.content.lowercased().contains(text)
                    || $0.time!.description.lowercased().contains(text)
                )
            }
            .filter { $0.time != nil }
            .sorted { $0.time!.time < $1.time!.time }
        self.subtitleView.reloadData()
    }
    
    func subtitleCloseButtonClicked() {
        self.subtitleView.hide()
    }
}
