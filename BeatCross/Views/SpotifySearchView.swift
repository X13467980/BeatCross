//
//  SpotifySearchView.swift
//  BeatCross
//
//  Created by 尾崎陽介 on 2025/02/03.
//

import UIKit

class SpotifySearchView: UIView {
    let searchTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "アーティスト名または曲名"
        textField.borderStyle = .roundedRect
        return textField
    }()

    let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("検索", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        return button
    }()

    let tableView: UITableView = {
        let tableView = UITableView()
        // 今回は .subtitle スタイルのセルを使うため、ここでは register しない
        // register するとデフォルトスタイルになるので注意
        return tableView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(searchTextField)
        addSubview(searchButton)
        addSubview(tableView)

        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            searchTextField.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
            searchTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            searchTextField.trailingAnchor.constraint(equalTo: searchButton.leadingAnchor, constant: -10),
            searchTextField.heightAnchor.constraint(equalToConstant: 44),

            searchButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            searchButton.centerYAnchor.constraint(equalTo: searchTextField.centerYAnchor),
            searchButton.widthAnchor.constraint(equalToConstant: 80),
            searchButton.heightAnchor.constraint(equalToConstant: 44),

            tableView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

#Preview {
    SpotifySearchView()
}
