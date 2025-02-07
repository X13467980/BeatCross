//
//  GetFavSongManager.swift
//  BeatCross
//
//  Created by 尾崎陽介 on 2025/02/07.
//

import FirebaseFirestore
import FirebaseAuth

/// Firestore から取得したお気に入り曲データを格納するための構造体
struct ExportedSong {
    let title: String
    let author: String
    let image: String
    let previewUrl: String? // 任意
    let addedBy: String? // 任意（曲を設定したユーザーの名前）
}

class GetFavSongManager {
    private let db = Firestore.firestore()
    private var favoriteSongs: [ExportedSong] = []

    /// `encounter` に登録されている `user_id` の `favorite_song` を取得
    func fetchEncounterFavoriteSongs(completion: @escaping ([ExportedSong]) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ ユーザーがログインしていません")
            completion([])
            return
        }

        let userRef = db.collection("user").document(currentUser.uid)
        
        userRef.getDocument { document, error in
            if let error = error {
                print("❌ `encounter` の取得エラー: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let document = document, document.exists,
                  let encounterUserIds = document.data()?["encounter"] as? [String] else {
                print("⚠️ `encounter` に登録されたユーザーがいません")
                completion([])
                return
            }

            let dispatchGroup = DispatchGroup()
            var songs: [ExportedSong] = []

            for userId in encounterUserIds {
                dispatchGroup.enter()
                self.fetchFavoriteSongs(for: userId) { userSongs in
                    songs.append(contentsOf: userSongs)
                    dispatchGroup.leave()
                }
            }

            dispatchGroup.notify(queue: .main) {
                self.favoriteSongs = songs
                completion(songs)
            }
        }
    }

    /// 指定した `user_id` の `favorite_song` を取得
    private func fetchFavoriteSongs(for userId: String, completion: @escaping ([ExportedSong]) -> Void) {
        let userRef = db.collection("user").document(userId)

        userRef.getDocument { document, error in
            if let error = error {
                print("❌ ユーザー情報の取得エラー: \(error.localizedDescription)")
                completion([])
                return
            }

            let userName = document?.data()?["name"] as? String ?? "Unknown User"

            let favoriteSongsRef = userRef.collection("favorite_song")
            favoriteSongsRef.getDocuments { snapshot, error in
                if let error = error {
                    print("❌ `favorite_song` の取得エラー: \(error.localizedDescription)")
                    completion([])
                    return
                }

                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }

                let songs = documents.compactMap { doc -> ExportedSong? in
                    let data = doc.data()
                    guard let title = data["name"] as? String,
                          let authors = data["artists"] as? [String],
                          let image = data["image_url"] as? String else {
                        return nil
                    }

                    let previewUrl = data["preview_url"] as? String
                    return ExportedSong(title: title, author: authors.joined(separator: ", "), image: image, previewUrl: previewUrl, addedBy: userName)
                }

                completion(songs)
            }
        }
    }
}
