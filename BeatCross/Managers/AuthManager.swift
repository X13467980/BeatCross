//
//  AuthManager.swift
//  SwiftTest1
//
//  Created by X on 2024/12/20.
//

import FirebaseAuth

class AuthManager {
    static let shared = AuthManager()
    
    private init() {}

    // ユーザー登録メソッド
    func register(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // ログインメソッド
    func login(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
