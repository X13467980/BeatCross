//
//  LoginView.swift
//  BeatCross
//
//  Created by X on 2025/01/06.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String? = nil
    @State private var navigateToHome: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Image("backGroundImage")
                    .resizable()
                    .ignoresSafeArea()
                    .scaledToFill()
                
                VStack(spacing: 20) {
                    Text("Login")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
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
                    }
                    
                    Button(action: {
                        loginUser()
                    }) {
                        Text("Login")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.mainDarkBlue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .clipShape(RoundedRectangle(cornerRadius: 10)) // 角丸の適用
                            .overlay( // ボーダーの適用
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 1.5)
                            )
                    }
                }
                .padding()
//                .navigationTitle("Login")
                // navigationDestinationで遷移先を定義
                .navigationDestination(isPresented: $navigateToHome) {
                    HomeView()
                }
            }
           
        }
    }

    func loginUser() {
        AuthManager.shared.login(email: email, password: password) { result in
            switch result {
            case .success:
                errorMessage = nil
                navigateToHome = true // ログイン成功時にHomeViewへ遷移
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    LoginView()
}
