//
//  DatabaseControl.swift
//  BeatCross
//
//  Created by 尾崎陽介 on 2025/02/03.
//

import FirebaseFirestore
import FirebaseAuth
import Foundation  // Firestore のデータ型を扱うために追加

class DatabaseControl {
    private let db = Firestore.firestore()

    // MARK: - 🎵 Spotify のトラックを Firestore に保存（favorite_song にも追加）
    func saveToFirestore(track: SpotifyTrack, completion: @escaping (Bool) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ ユーザーがログインしていません")
            completion(false)
            return
        }

        var trackData: [String: Any] = [
            "id": track.id,
            "name": track.name,
            "preview_url": track.preview_url ?? "",
            "album_name": track.album.name,
            "artists": track.artists.map { $0.name },
            "spotify_url": track.external_urls.spotify,
            "added_at": FieldValue.serverTimestamp(), // お気に入り追加時刻
            "user_id": currentUser.uid // 誰が追加したかを記録
        ]

        if let imageUrl = track.image_url {
            trackData["image_url"] = imageUrl
        }

        // ユーザーの `favorite_song` に保存
        let userFavoriteRef = db.collection("user").document(currentUser.uid).collection("favorite_song").document(track.id)
        let globalFavoriteRef = db.collection("favorite_song").document(track.id)

        // Firestore のバッチ処理を使って同時に保存
        let batch = db.batch()
        batch.setData(trackData, forDocument: userFavoriteRef)
        batch.setData(trackData, forDocument: globalFavoriteRef)

        batch.commit { error in
            if let error = error {
                print("❌ Firestore への保存エラー: \(error.localizedDescription)")
                completion(false)
            } else {
                print("✅ Firestore に保存完了: \(track.name)")
                completion(true)
            }
        }
    }

    // MARK: - 🔗 `encounter` 配列でユーザーをリレーション（余計な機能なし）
    
    /// `encounter` 配列に `user_id` を追加（リレーションのみ）
    func addEncounterRelation(targetUserId: String, completion: @escaping (Bool) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ ユーザーがログインしていません")
            completion(false)
            return
        }

        let currentUserRef = db.collection("user").document(currentUser.uid)
        let targetUserRef = db.collection("user").document(targetUserId)

        // 自分の `encounter` に相手を追加
        currentUserRef.updateData([
            "encounter": FieldValue.arrayUnion([targetUserId])
        ]) { error in
            if let error = error {
                print("❌ `encounter` 更新エラー: \(error.localizedDescription)")
                completion(false)
            } else {
                print("✅ `encounter` に \(targetUserId) を追加")
                completion(true)
            }
        }

        // 相手の `encounter` に自分を追加
        targetUserRef.updateData([
            "encounter": FieldValue.arrayUnion([currentUser.uid])
        ]) { error in
            if let error = error {
                print("❌ 相手の `encounter` 更新エラー: \(error.localizedDescription)")
            } else {
                print("✅ 相手の `encounter` に \(currentUser.uid) を追加")
            }
        }
    }
}
