//
//  SpotifySaerchView.swift
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

    override func loadView() {
        self.view = searchView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        searchView.searchButton.addTarget(self, action: #selector(handleSearchButton), for: .touchUpInside)
        searchView.tableView.delegate = self
        searchView.tableView.dataSource = self
        searchView.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell") // ✅ ここを追加
    }

    @objc private func handleSearchButton() {
        let query = searchView.searchTextField.text ?? ""
        guard !query.isEmpty else {
            showAlert(title: "⚠️ エラー", message: "検索キーワードを入力してください")
            return
        }

        spotifyManager.fetchSpotifyAccessToken { [weak self] token in
            guard let self = self, let token = token else {
                self?.showAlert(title: "⚠️ エラー", message: "Spotifyの認証に失敗しました")
                return
            }

            self.spotifyManager.searchTrack(query: query) { results in
                guard let results = results else {
                    self.showAlert(title: "⚠️ エラー", message: "楽曲が見つかりませんでした")
                    return
                }

                self.searchResults = results
                DispatchQueue.main.async {
                    self.searchView.tableView.reloadData()
                }
            }
        }
    }

    // ✅ 【修正】検索結果に「曲名 - アーティスト名」を正しく表示
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "trackCell"

        // ✅ `subtitle` スタイルで `UITableViewCell` を作成（`detailTextLabel` を使うため）
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        }

        let track = searchResults[indexPath.row]
        let artistNames = track.artists.isEmpty ? "Unknown Artist" : track.artists.map { $0.name }.joined(separator: ", ")

        cell?.textLabel?.text = track.name
        cell?.detailTextLabel?.text = artistNames  // ✅ アーティスト名を表示

        return cell ?? UITableViewCell()
    }

    // ✅ 【修正】曲を選択した時の処理
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedTrack = searchResults[indexPath.row]

        // Firestore に保存
        databaseControl.saveToFirestore(track: selectedTrack) { success in
            DispatchQueue.main.async {
                if success {
                    self.showAlert(title: "✅ お気に入り設定", message: "\(selectedTrack.name) をお気に入りに設定しました！")
                } else {
                    self.showAlert(title: "❌ エラー", message: "お気に入り設定に失敗しました。")
                }
            }
        }
    }

    // ✅ 【修正】アラートを表示する関数
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

