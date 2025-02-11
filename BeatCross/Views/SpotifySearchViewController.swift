import UIKit
import SwiftUI

class SpotifySearchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let searchView = SpotifySearchView()
    private let spotifyManager = SpotifySearchManager()
    private let databaseControl = DatabaseControl()
    private var searchResults: [SpotifyTrack] = []
    var onSongSelected: ((String, String) -> Void)?

    // MARK: - Lifecycle

    override func loadView() {
        self.view = searchView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchView.tableView.delegate = self
        searchView.tableView.dataSource = self
        
        searchView.searchButton.addTarget(
            self,
            action: #selector(handleSearchButton),
            for: .touchUpInside
        )
    }

    // MARK: - Actions

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

            self.spotifyManager.searchSpotify(query: query) { results in
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

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "trackCell"
        
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        }
        
        let track = searchResults[indexPath.row]
        let artistNames = track.artists.map { $0.name }.joined(separator: ", ")

        cell?.textLabel?.text = track.name
        cell?.detailTextLabel?.text = artistNames
        
        return cell ?? UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedTrack = searchResults[indexPath.row]
        
        databaseControl.saveToFirestore(track: selectedTrack) { success in
            DispatchQueue.main.async {
                if success {
                    self.showAlert(
                        title: "✅ お気に入り追加",
                        message: "\(selectedTrack.name) をお気に入りに追加しました！"
                    ) {
                        self.navigateToHomeView()
                    }
                } else {
                    self.showAlert(
                        title: "❌ エラー",
                        message: "お気に入り追加に失敗しました。"
                    )
                }
            }
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - HomeView への遷移処理
    private func navigateToHomeView() {
        let homeView = UIHostingController(rootView: HomeView())
        if let navigationController = self.navigationController {
            navigationController.pushViewController(homeView, animated: true)
        } else {
            self.present(homeView, animated: true)
        }
    }

    // MARK: - Alert

    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?() // OKボタンを押した後にHomeViewへ遷移
        })
        present(alert, animated: true)
    }
    
    func selectSong(songName: String, artistName: String) {
            onSongSelected?(songName, artistName) // ✅ クロージャを呼び出す
            dismiss(animated: true, completion: nil) // ✅ 画面を閉じる
        }
}
