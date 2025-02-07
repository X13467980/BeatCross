//
//  SpotifySearchManager.swift
//  BeatCross
//
//  Created by 尾崎陽介 on 2025/02/03.
//

import Alamofire

struct SpotifyTokenResponse: Decodable {
    let access_token: String
    let token_type: String
    let expires_in: Int
}

struct SpotifySearchResponse: Decodable {
    let tracks: Tracks

    struct Tracks: Decodable {
        let items: [SpotifyTrack]
    }
}

// **SpotifyTrack の定義をここに統一**
struct SpotifyTrack: Decodable {
    let id: String
    let name: String
    let preview_url: String?
    let album: Album
    let artists: [Artist]
    let external_urls: ExternalUrls
    var image_url: String?  // ← `let` を `var` に変更

    struct Album: Decodable {
        let name: String
        let images: [AlbumImage]
    }

    struct AlbumImage: Decodable {
        let url: String
    }

    struct Artist: Decodable {
        let name: String
    }

    struct ExternalUrls: Decodable {
        let spotify: String
    }
}

class SpotifySearchManager {
    private let clientID = Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_CLIENT_ID") as? String ?? ""
    private let clientSecret = Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_CLIENT_SECRET") as? String ?? ""
    private var spotifyAccessToken: String?

    func fetchSpotifyAccessToken(completion: @escaping (String?) -> Void) {
        let url = "https://accounts.spotify.com/api/token"
        let parameters = ["grant_type": "client_credentials"]

        let credential = "\(clientID):\(clientSecret)"
        guard let credentialData = credential.data(using: .utf8) else {
            completion(nil)
            return
        }
        let base64Credential = credentialData.base64EncodedString()

        let headers: HTTPHeaders = ["Authorization": "Basic \(base64Credential)", "Content-Type": "application/x-www-form-urlencoded"]

        AF.request(url, method: .post, parameters: parameters, headers: headers).responseDecodable(of: SpotifyTokenResponse.self) { response in
            guard let tokenResponse = response.value else {
                completion(nil)
                return
            }
            self.spotifyAccessToken = tokenResponse.access_token
            completion(tokenResponse.access_token)
        }
    }

    func searchTrack(query: String, completion: @escaping ([SpotifyTrack]?) -> Void) {
        guard let token = spotifyAccessToken else {
            completion(nil)
            return
        }

        let url = "https://api.spotify.com/v1/search"
        let parameters: [String: Any] = ["q": query, "type": "track", "limit": 10]
        let headers: HTTPHeaders = ["Authorization": "Bearer \(token)"]

        AF.request(url, method: .get, parameters: parameters, headers: headers).responseDecodable(of: SpotifySearchResponse.self) { response in
            guard let searchResponse = response.value else {
                completion(nil)
                return
            }

            let tracks = searchResponse.tracks.items.map { track in
                var newTrack = track
                newTrack.image_url = track.album.images.first?.url  // ジャケット画像のURLを追加
                return newTrack
            }

            completion(tracks)
        }
    }
}
