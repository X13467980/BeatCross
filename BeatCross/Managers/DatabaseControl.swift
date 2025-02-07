//
//  DatabaseControl.swift
//  BeatCross
//
//  Created by 尾崎陽介 on 2025/02/03.
//  Edited by 尾崎陽介 on 2025/02/07
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
        // images を追加してアルバムアートを取得
        let images: [AlbumImage]?
    }
    
    struct AlbumImage: Decodable {
        let url: String
        let height: Int?
        let width: Int?
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
    
    /// ユーザーのお気に入り & "songs" コレクションに保存
    /// - Parameters:
    ///   - track: Spotifyのトラック情報
    ///   - completion: 成功 / 失敗をBoolで返却
    func saveToFirestore(track: SpotifyTrack, completion: @escaping (Bool) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ ユーザーがログインしていません")
            completion(false)
            return
        }
        
        // users > {uid} (Document)
        let userDocRef = db.collection("users").document(currentUser.uid)
        
        // songs > {track.id} (Document)
        let songDocRef = db.collection("songs").document(track.id)
        
        // 取得したアルバムアートの先頭URLを使用
        let imageUrl = track.album.images?.first?.url ?? ""
        
        // Firestoreに保存したい曲情報
        let songData: [String: Any] = [
            "song_id": track.id,
            "name": track.name,
            "album": track.album.name,
            "artists": track.artists.map { $0.name },
            "external_urls": track.external_urls.spotify,
            "preview_url": track.preview_url ?? "",
            "savedAt": Timestamp(),
            "image_url": imageUrl   // 取得したアルバムアートURLを格納
        ]
        
        let batch = db.batch()
        
        // 1. ユーザードキュメントの "favorite_song" フィールド（配列）に曲情報を追加
        //    ドキュメントが無い場合も作成したいので setData(..., merge: true) を使う
        batch.setData(["favorite_song": FieldValue.arrayUnion([songData])],
                      forDocument: userDocRef,
                      merge: true)
        
        // 2. "songs" コレクションに曲情報を保存 (なければ新規作成、あればデータをマージ)
        batch.setData(songData, forDocument: songDocRef, merge: true)
        
        // 3. バッチのコミット
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
