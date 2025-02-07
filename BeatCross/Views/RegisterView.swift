//
//  RegisterView.swift
//  BeatCross
//
//  Created by X on 2025/01/06.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RegisterView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var errorMessage: String? = nil
    @State private var navigateToHome: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Register")
                    .font(.title)
                    .fontWeight(.bold)
                
                TextField("Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)

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
            .navigationDestination(isPresented: $navigateToHome) {
                HomeView()
            }
        }
    }
    
    func registerUser() {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            
            guard let user = authResult?.user else {
                self.errorMessage = "Failed to get user."
                return
            }
            
            // Firestoreにユーザー情報を追加
            let db = Firestore.firestore()
            let userData: [String: Any] = [
                "email": email,
                "name": name,
                "favorite_song": NSNull(), // nilの代わりにNSNull()
                "createdAt": Timestamp(date: Date()),
                "encounter_uid": [] // 空の配列で初期化
            ]
            
            db.collection("users").document(user.uid).setData(userData) { error in
                if let error = error {
                    self.errorMessage = "Firestore error: \(error.localizedDescription)"
                } else {
                    self.errorMessage = nil
                    self.navigateToHome = true // 成功時にHomeViewへ遷移
                }
            }
        }
    }
}

#Preview {
    RegisterView()
}
