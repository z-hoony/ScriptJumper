//
//  MovieListViewController.swift
//  ScriptJumper
//
//  Created by 현지훈 on 16/05/2019.
//  Copyright © 2019 현지훈. All rights reserved.
//

import UIKit

class MovieListViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
    private var movies: [Movie]?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        loadDocumentFiles()
    }

    func setupUI() {
        let cellNib = UINib(nibName: String(describing: MovieTableViewCell.self), bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: MovieTableViewCell.identifier)

        self.title = "영화 목록"
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }

    func loadDocumentFiles() {
        DispatchQueue.global().async { [weak self] in
            guard let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                else { return }
            print(documentURL)
            self?.movies = try? FileManager.default.contentsOfDirectory(at: documentURL,
                                                                        includingPropertiesForKeys: nil,
                                                                        options: .skipsHiddenFiles)
                .filter {
                    $0.pathExtension == "mp4" || $0.pathExtension == "mkv"
                }
                .map {
                    let subtitleURL = $0.deletingPathExtension().appendingPathExtension("smi")
                    if FileManager.default.fileExists(atPath: subtitleURL.path) {
                         return Movie(url: $0, subtitleUrl: subtitleURL)
                    } else {
                         return Movie(url: $0, subtitleUrl: nil)
                    }
            }

            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }
}

extension MovieListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dequeueCell = tableView.dequeueReusableCell(withIdentifier: MovieTableViewCell.identifier, for: indexPath)
        guard let cell = dequeueCell as? MovieTableViewCell else { return dequeueCell}
        guard (movies?.count ?? 0) > indexPath.row else { return cell }
        guard let movie = movies?[indexPath.row] else { return cell }

        cell.setFileNameLabel(text: movie.name)
        cell.setSubtitleExistLabel(text: movie.subtitleUrl != nil ? "자막 있음" : "자막 없음")

        guard let date = movie.creationDate else { return cell }
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = "yyyy. MM. dd. HH:mm:ss"
        cell.setFileCreationTimeLabel(text: dateFormatter.string(from: date))

        guard let size = movie.size else { return cell }
        cell.setFileSizeLabel(text: ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .binary))

        return cell
    }
}

extension MovieListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard (movies?.count ?? 0) > indexPath.row else { return }
        guard let movie = movies?[indexPath.row] else { return }

        let viewContoller = PlayerViewController()
        viewContoller.movie = movie
        viewContoller.modalPresentationStyle = .fullScreen

        present(viewContoller, animated: true, completion: nil)
    }
}
