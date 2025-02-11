//
//  GetFavSongManager.swift
//  BeatCross
//
//  Created by (あなたの名前) on 2025/02/08.
//

import FirebaseFirestore 
import FirebaseAuth

/// encounter_uid に含まれる他のユーザーが登録したお気に入り曲のデータ
struct EncounteredUserFavSong {
    /// お気に入りを登録したユーザーのID
    let userId: String
    
    // 以下は favorite_song の各要素に対応するプロパティ
    let song_id: String
    let name: String
    let album: String
    let artists: [String]
    let external_urls: String
    let preview_url: String
    let savedAt: Timestamp
    let image_url: String
}

class GetFavSongManager {
    private let db = Firestore.firestore()
    
    /// 現在のユーザーの encounter_uid 配列に含まれるユーザーのお気に入り曲をまとめて取得
    /// - Parameter completion: 取得完了時に [EncounteredUserFavSong] を返す
    func fetchEncounteredUsersFavSongs(completion: @escaping ([EncounteredUserFavSong]) -> Void) {
        
        // 1. ログインしているユーザーをチェック
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ fetchEncounteredUsersFavSongs: 未ログインユーザーです。")
            completion([])
            return
        }
        
        // 2. 「users > {currentUser.uid}」のドキュメントを取得
        let currentUserDocRef = db.collection("users").document(currentUser.uid)
        currentUserDocRef.getDocument { snapshot, error in
            if let error = error {
                print("❌ currentUserDocRef.getDocument エラー: \(error)")
                completion([])
                return
            }
            
            // 3. encounter_uid配列を取得
            guard let data = snapshot?.data(),
                  let encounterUidArray = data["encounter_uid"] as? [String] else {
                print("⚠️ encounter_uid が存在しない / 配列ではない")
                completion([])
                return
            }
            
            // 4. encounter_uid で列挙されているユーザーのドキュメントを取得し、favorite_song をまとめて取り出す
            let group = DispatchGroup()
            var allFavSongs: [EncounteredUserFavSong] = []
            
            for encounterUserId in encounterUidArray {
                group.enter()
                
                let encounterUserDocRef = self.db.collection("users").document(encounterUserId)
                encounterUserDocRef.getDocument { userSnapshot, userError in
                    defer { group.leave() }  // このスコープを出るときに必ず leave
                    
                    if let userError = userError {
                        print("❌ encounterUserDocRef.getDocument エラー: \(userError)")
                        return
                    }
                    
                    guard let userData = userSnapshot?.data(),
                          let favSongArray = userData["favorite_song"] as? [[String: Any]] else {
                        print("⚠️ userData なし / favorite_song フィールドなし")
                        return
                    }
                    
                    // 5. favorite_song の各要素を EncounteredUserFavSong に変換して格納
                    for songDict in favSongArray {
                        // Firestoreに保存している構造 (song_id, name, artists, external_urls, ...)
                        let encounteredSong = EncounteredUserFavSong(
                            userId: encounterUserId,
                            song_id: songDict["song_id"] as? String ?? "",
                            name: songDict["name"] as? String ?? "",
                            album: songDict["album"] as? String ?? "",
                            artists: songDict["artists"] as? [String] ?? [],
                            external_urls: songDict["external_urls"] as? String ?? "",
                            preview_url: songDict["preview_url"] as? String ?? "",
                            savedAt: songDict["savedAt"] as? Timestamp ?? Timestamp(),
                            image_url: songDict["image_url"] as? String ?? ""
                        )
                        allFavSongs.append(encounteredSong)
                    }
                }
            }
            
            // 6. 全ての取得処理が完了したらコールバックを呼ぶ
            group.notify(queue: .main) {
                completion(allFavSongs)
            }
        }
    }
}
