//
//  SubtitleView.swift
//  ScriptJumper
//
//  Created by 현지훈 on 16/05/2019.
//  Copyright © 2019 현지훈. All rights reserved.
//

import UIKit

class SubtitleView: UIView {
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var searchBar: UISearchBar!

    var delegate: (SubtitleViewDelegate & UITableViewDelegate & UITableViewDataSource)? {
        didSet {
            tableView.delegate = self.delegate
            tableView.dataSource = self.delegate
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupUI()
    }

    func setupUI() {
        guard let contentView = Bundle.main.loadNibNamed(String(describing: SubtitleView.self),
                                                         owner: self, options: nil)?.first as? UIView else { return }

        contentView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: self.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
            ])

        let cellNib = UINib(nibName: String(describing: SubtitleTableViewCell.self), bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: SubtitleTableViewCell.identifier)

        searchBar.delegate = self
    }

    @IBAction func close() {
        delegate?.subtitleCloseButtonTouched()
    }

    func hide() {
        searchBar.resignFirstResponder()
        self.isHidden = true
    }

    func show() {
        self.isHidden = false
    }

    func reloadData() {
        self.tableView.reloadData()
    }

    func scrollToRow(at indexPath: IndexPath) {
        if !self.tableView.isDragging {
            self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        }
    }
}

protocol SubtitleViewDelegate: class {
    func subtitleCloseButtonTouched()
    func searchBar(textDidChange searchText: String)
}

extension SubtitleView: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.delegate?.searchBar(textDidChange: searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
