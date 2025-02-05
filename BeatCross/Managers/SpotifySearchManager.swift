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

        let headers: HTTPHeaders = [
            "Authorization": "Basic \(base64Credential)",
            "Content-Type": "application/x-www-form-urlencoded"
        ]

        AF.request(url, method: .post, parameters: parameters, encoder: URLEncodedFormParameterEncoder.default, headers: headers)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: SpotifyTokenResponse.self) { response in
                switch response.result {
                case .success(let tokenResponse):
                    self.spotifyAccessToken = tokenResponse.access_token
                    completion(tokenResponse.access_token)
                case .failure:
                    completion(nil)
                }
            }
    }

    func searchSpotify(query: String, completion: @escaping ([SpotifyTrack]?) -> Void) {
        guard let token = spotifyAccessToken else {
            completion(nil)
            return
        }

        let url = "https://api.spotify.com/v1/search"
        let parameters: [String: Any] = ["q": query, "type": "track", "limit": 10]
        let headers: HTTPHeaders = ["Authorization": "Bearer \(token)"]

        AF.request(url, method: .get, parameters: parameters, headers: headers)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: SpotifySearchResponse.self) { response in
                switch response.result {
                case .success(let searchResponse):
                    completion(searchResponse.tracks.items)
                case .failure:
                    completion(nil)
                }
            }
    }
}

