import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct ProfileView: View {
    @State private var username: String = "ユーザー名"
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = UIImage(systemName: "person.circle.fill")
    @State private var imageURL: String? = nil
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    var body: some View {
        VStack {
            Spacer()
            
            // プロフィール画像
            PhotosPicker(selection: $selectedItem, matching: .images) {
                if let image = profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                        .padding(.bottom, 10)
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.gray)
                        .padding(.bottom, 10)
                }
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data) {
                            profileImage = uiImage
                            uploadImageToFirebase(image: uiImage)
                        }
                    }
                }
            }
            
            // 名前の編集
            TextField("名前を入力", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 200)
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)
            
            // 保存ボタン
            Button(action: {
                updateUserProfile()
            }) {
                Text("保存")
                    .bold()
                    .frame(width: 100, height: 40)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("保存完了"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            
            Spacer()
        }
        .navigationTitle("Profile")
        .onAppear {
            fetchUserProfile()
        }
    }
    
    // Firebase Firestoreからユーザー情報を取得
    private func fetchUserProfile() {
        guard let user = Auth.auth().currentUser else { return }
        let userRef = db.collection("users").document(user.uid)
        
        userRef.getDocument { document, error in
            if let document = document, document.exists {
                if let nickname = document.get("nickname") as? String {
                    self.username = nickname
                }
                if let url = document.get("imageURL") as? String {
                    self.imageURL = url
                    loadImage(from: url)
                }
            }
        }
    }
    
    // Firestoreにユーザー情報を更新
    private func updateUserProfile() {
        guard let user = Auth.auth().currentUser else { return }
        let userRef = db.collection("users").document(user.uid)
        
        userRef.setData(["nickname": username, "imageURL": imageURL ?? ""], merge: true) { error in
            if let error = error {
                print("Error updating profile: \(error)")
            } else {
                alertMessage = "プロフィールが更新されました"
                showAlert = true
            }
        }
    }
    
    // Firebase Storageに画像をアップロード
    private func uploadImageToFirebase(image: UIImage) {
        guard let user = Auth.auth().currentUser else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.4) else { return }
        
        let storageRef = storage.reference().child("profile_images/\(user.uid).jpg")
        
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Error uploading image: \(error)")
                return
            }
            
            storageRef.downloadURL { url, error in
                if let url = url {
                    self.imageURL = url.absoluteString
                    updateUserProfile()
                }
            }
        }
    }
    
    // Firestoreに保存された画像URLから画像を読み込む
    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = image
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}
