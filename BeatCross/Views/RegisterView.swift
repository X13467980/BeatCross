//
//  RegisterView.swift
//  BeatCross
//
//  Created by X on 2025/01/06.
//

import SwiftUI
import FirebaseAuth

struct RegisterView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String? = nil
    @State private var navigateToFavoriteSong: Bool = false
    @State private var userId: String? = nil // Firebase Auth の UID を保持

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Register")
                    .font(.title)
                    .fontWeight(.bold)
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: {
                    registerUser()
                }) {
                    Text("Register")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
            .navigationTitle("Register")
            .navigationDestination(isPresented: $navigateToFavoriteSong) {
                if let userId = userId {
                    FavoriteSongView(userId: userId)
                }
            }
        }
    }
    
    func registerUser() {
        AuthManager.shared.register(email: email, password: password) { result in
            switch result {
            case .success(let userId):
                self.errorMessage = nil
                self.userId = userId
                self.navigateToFavoriteSong = true // 登録後、お気に入り曲設定画面へ遷移
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    RegisterView()
}

