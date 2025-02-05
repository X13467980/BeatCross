//
//  DatabaseControl.swift
//  BeatCross
//
//  Created by 尾崎陽介 on 2025/02/03.
//

import FirebaseFirestore
import FirebaseAuth

struct SpotifyTrack: Decodable {
    let id: String
    let name: String
    let preview_url: String?
    let album: Album
    let artists: [Artist]
    let external_urls: ExternalUrls
    
    struct Album: Decodable {
        let name: String
    }
    
    struct Artist: Decodable {
        let name: String
    }
    
    struct ExternalUrls: Decodable {
        let spotify: String
    }
}

class DatabaseControl {
    private let db = Firestore.firestore()

    /// **ユーザーのお気に入り & グローバルな favorite_song に保存**
    func saveToFirestore(track: SpotifyTrack, completion: @escaping (Bool) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ ユーザーがログインしていません")
            completion(false)
            return
        }

        let userFavoriteRef = db
            .collection("user")
            .document(currentUser.uid)
            .collection("favorite_song")
            .document(track.id)

        let globalFavoriteRef = db
            .collection("favorite_song")
            .document(track.id)

        let songData: [String: Any] = [
            "song_id": track.id,
            "name": track.name,
            "album": track.album.name,
            "artists": track.artists.map { $0.name },
            "external_urls": track.external_urls.spotify,
            "preview_url": track.preview_url ?? "",
            "savedAt": Timestamp()
        ]

        let batch = db.batch()
        batch.setData(songData, forDocument: userFavoriteRef)
        batch.setData(songData, forDocument: globalFavoriteRef, merge: true)

        batch.commit { error in
            if let error = error {
                print("❌ Firestore保存エラー: \(error)")
                completion(false)
            } else {
                print("✅ Firestore保存成功: \(track.name)")
                completion(true)
            }
        }
    }
}
