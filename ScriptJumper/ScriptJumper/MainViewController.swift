//
//  ViewController.swift
//  ScriptJumper
//
//  Created by 현지훈 on 09/05/2019.
//  Copyright © 2019 현지훈. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
    var syncs: [SAMISync]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.loadSyncs(Bundle.main.url(forResource: "test", withExtension: "smi"))
    }
    
    func loadSyncs(_ url: URL?) {
        let content = fileRead(url)
        let parser = SAMIParser()
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            let tags = parser.parse(content)
            self?.syncs = tags?
                .toSyncs()
                .filter { $0.paragraphs.first?.content != "&nbsp;" }
                .filter { $0.time != nil }
                .sorted { $0.time!.time < $1.time!.time }
            
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }
    
    func fileRead(_ url: URL?, encoding: String.Encoding = .utf8) -> String? {
        guard let url = url else { return nil }
        
        return try? String(contentsOf: url, encoding: encoding)
    }
}

extension MainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.syncs?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "subtitleCell", for: indexPath) as! SubtitleTableViewCell
        
        guard indexPath.row < (self.syncs?.count ?? 0) else { return cell }
        
        cell.timeLabel.text = syncs?[indexPath.row].time?.description
        cell.subtitleLabel.text = syncs?[indexPath.row].paragraphs.first?.description
        
        return cell
    }
}
