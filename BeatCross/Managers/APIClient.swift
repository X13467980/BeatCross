//
//  ApiClient.swift
//  BeatCross
//
//  Created by 神宮一敬 on 2025/01/29.
////
//
import Foundation

enum ApiError: Error {
    case invalidUrl
    case invalidResponse
    case serverError(statusCode: Int)
    case decodingError
    case unknownError
}


enum HttpMethod {
    case get
    case post
    
}

class APIClient {
    static let shared = APIClient() //シングルトン
    private let baseUrl = "" // baseURLを指す　エンドポイントの前までを指す。
    
    
    private func createReaquest(endpoint: String, body: String?, httpMethod: HttpMethod) -> URLRequest? { // [?]はnill(null)の可能性がある. 矢印の先のURLRequestは帰ってくるデータの型を指定。
        let url = baseUrl + endpoint
        let requestUrl = URL(string: url) //string型の値を取るstring変数のurl定数をURLクラスのインスタンス化！
        let method = httpMethod  == .get ? "GET" : "POST" //methodがgetだったら,method定数に"GET" ,じゃなかったら"POST"
        var request = URLRequest(url: requestUrl! ) //url型の値を取るurl変数はオプショナル変数(nullの可能性がある)を取るため,!をつけて強制アンラップすることでnullじゃないことを宣言している!
        request.httpMethod = method
        request.httpBody = body?.data(using: .utf8) //body引数をutf8でdata型に変更,bodyはstring型(stringクラス)で、stringクラスにはdata型に変換するdataメソッドを持っている。
        return request
    }
    
    func fetchData<T: Decodable>(endpoint: String, body: String?,type: T ) async throws -> T {
        //result型→使った側が成功したのか、失敗したのかわかる。成功した時はT型 , Errorの時はError型
        //throws→失敗する可能性がある。
        //asyncは非同期関数(asyncで待機可能性があることを宣言、awaitで待機を宣言!)
        //<>は帰ってくる値(T)のデータ型を決めている。念の為のbody(基本fetchするときはいらない) 、<>があることで関数の帰り値をジェネリクスにする。
        guard let request = createReaquest(endpoint: endpoint, body: body, httpMethod: .get) else {
            throw ApiError.unknownError //throwされたらcatchに処理が飛ぶ
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ApiError.invalidResponse
        }
        
        let decodedDate = try JSONDecoder().decode(T.self, from:data) //JSONDecoder() :JSONCDEcoderインスタンス
        return decodedDate
    
    }
    
    func postData<T: Decodable>(endpoint: String, body: String?,type: T? ) async throws -> T? { //T?は帰り値が帰ってこない場合の時を考えてnillの可能性を考慮しておく。
        //result型→使った側が成功したのか、失敗したのかわかる。成功した時はT型 , Errorの時はError型
        //throws→失敗する可能性がある。
        //asyncは非同期関数(asyncで待機可能性があることを宣言、awaitで待機を宣言!)
        //<>は帰ってくる値(T)のデータ型を決めている。念の為のbody(基本fetchするときはいらない) 、<>があることで関数の帰り値をジェネリクスにする。
        guard let request = createReaquest(endpoint: endpoint, body: body, httpMethod: .get) else {
            throw ApiError.unknownError //throwされたらcatchに処理が飛ぶ
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ApiError.invalidResponse
        }
        
        let decodedDate = try JSONDecoder().decode(T.self, from:data) //JSONDecoder() :JSONCDEcoderインスタンス
        return decodedDate
    
    }
        
        
    
}
