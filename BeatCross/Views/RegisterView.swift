import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RegisterView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var errorMessage: String? = nil
    @State private var navigateToHome: Bool = false
    @State private var showSuccessAlert: Bool = false // 成功アラート表示用
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Image("backGroundImage")
                    .resizable()
                    .ignoresSafeArea()
                    .scaledToFill()
                
                VStack(spacing: 20) {
                    Text("Register")
                        .font(.largeTitle)
                        .foregroundColor(.white)
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
                            .background(Color.mainDarkBlue)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .cornerRadius(10)
                            .clipShape(RoundedRectangle(cornerRadius: 10)) // 角丸の適用
                            .overlay( // ボーダーの適用
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 0.8)
                            )
                    }
                    
                }
                .padding()
                .navigationDestination(isPresented: $navigateToHome) {
                    HomeView()
                        .onAppear {
                            navigationPath = NavigationPath() // ナビゲーション履歴を完全にリセット
                        }
                }
                .alert("登録成功", isPresented: $showSuccessAlert) {
                    Button("OK") {
                        navigateToHome = true // OKを押したら HomeView へ遷移
                    }
                } message: {
                    Text("アカウントが正常に作成されました！")
                }
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
                "favorite_song": NSNull(), // nil の代わりに NSNull()
                "createdAt": Timestamp(date: Date()),
                "encounter_uid": [] // 空の配列で初期化
            ]
            
            db.collection("users").document(user.uid).setData(userData) { error in
                if let error = error {
                    self.errorMessage = "Firestore error: \(error.localizedDescription)"
                } else {
                    self.errorMessage = nil
                    self.showSuccessAlert = true // 登録成功時にアラート表示
                }
            }
        }
    }
}

#Preview {
    RegisterView()
}
