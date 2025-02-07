//
//  SpotifySearchViewController.swift
//  BeatCross
//
//  Created by 尾崎陽介 on 2025/02/03.
//

import UIKit

class SpotifySearchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let searchView = SpotifySearchView()
    private let spotifyManager = SpotifySearchManager()
    private let databaseControl = DatabaseControl()
    private var searchResults: [SpotifyTrack] = []

    // MARK: - Lifecycle

    /// Viewの置き換え
    override func loadView() {
        self.view = searchView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // テーブルビューのデリゲート・データソース設定
        searchView.tableView.delegate = self
        searchView.tableView.dataSource = self
        
        // "subtitle" スタイルのセルを使うため、ここでは register() は呼ばない
        // searchView.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "trackCell")
        
        // 検索ボタンのアクション設定
        searchView.searchButton.addTarget(
            self,
            action: #selector(handleSearchButton),
            for: .touchUpInside
        )
    }

    // MARK: - Actions

    @objc private func handleSearchButton() {
        let query = searchView.searchTextField.text ?? ""
        
        // 入力が空ならエラーダイアログを表示
        guard !query.isEmpty else {
            showAlert(title: "⚠️ エラー", message: "検索キーワードを入力してください")
            return
        }

        // Spotifyのトークン取得
        spotifyManager.fetchSpotifyAccessToken { [weak self] token in
            guard let self = self, let token = token else {
                self?.showAlert(title: "⚠️ エラー", message: "Spotifyの認証に失敗しました")
                return
            }

            // トークンが取得できれば検索APIを実行
            self.spotifyManager.searchSpotify(query: query) { results in
                guard let results = results else {
                    self.showAlert(title: "⚠️ エラー", message: "楽曲が見つかりませんでした")
                    return
                }

                self.searchResults = results
                DispatchQueue.main.async {
                    // テーブルをリロードして結果を表示
                    self.searchView.tableView.reloadData()
                }
            }
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    /// 曲名（メイン）とアーティスト名（サブ）を表示するために「.subtitle」スタイルを使用
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "trackCell"
        
        // 再利用セルが無ければ「.subtitle」スタイルで新規生成する
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        }
        
        let track = searchResults[indexPath.row]
        let artistNames = track.artists.map { $0.name }.joined(separator: ", ")

        // メインテキストに曲名
        cell?.textLabel?.text = track.name
        // サブテキスト（detailTextLabel）にアーティスト名
        cell?.detailTextLabel?.text = artistNames
        
        // 万が一 cell が nil のときに備えて安全にアンラップ
        return cell ?? UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
    }

    // MARK: - UITableViewDelegate

    /// セルをタップしたらお気に入りに追加
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedTrack = searchResults[indexPath.row]
        
        // Firestore に保存 (image_url を含む)
        databaseControl.saveToFirestore(track: selectedTrack) { success in
            DispatchQueue.main.async {
                if success {
                    self.showAlert(
                        title: "✅ お気に入り追加",
                        message: "\(selectedTrack.name) をお気に入りに追加しました！"
                    )
                } else {
                    self.showAlert(
                        title: "❌ エラー",
                        message: "お気に入り追加に失敗しました。"
                    )
                }
            }
        }
        
        // 選択状態を解除
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - Alert

    /// アラート表示用共通関数
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
