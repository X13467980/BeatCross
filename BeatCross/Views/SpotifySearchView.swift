//
//  SpotifySearchView.swift
//  BeatCross
//
//  Created by 尾崎陽介 on 2025/02/03.
//

import UIKit
import SwiftUICore

class SpotifySearchView: UIView {
    let searchTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "アーティスト名または曲名"
        textField.borderStyle = .roundedRect
        // デフォルトの枠線を削除
        textField.borderStyle = .none
        textField.textColor = .white// 入力文字の色を白に設定
        // カスタム枠線の適用
        textField.layer.borderColor = UIColor.white.cgColor // 枠線の色
        textField.layer.borderWidth = 2.0 // 枠線の太さ
        textField.layer.cornerRadius = 5.0 // 角丸の適用
        
        // プレースホルダーの色を白に設定
           textField.attributedPlaceholder = NSAttributedString(
               string: "アーティスト名または曲名",
               attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.7)]
           )
        return textField
    }()

    let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("検索", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(Color.mainDarkBlue)
        // 角丸の適用
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        // ボーダーの適用
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1.5
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
