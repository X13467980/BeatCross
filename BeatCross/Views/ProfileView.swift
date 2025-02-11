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
    @State private var favoriteSong: String = "お気に入り曲なし"
    @State private var artistName: String = ""
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

            // お気に入り曲
            VStack {
                Text("お気に入り曲")
                    .font(.headline)
                if artistName.isEmpty || favoriteSong == "お気に入り曲なし" {
                    Text("お気に入り曲なし")
                        .foregroundColor(.gray)
                } else {
                    Text("\(artistName) - \(favoriteSong)")
                        .font(.body)
                        .padding(.bottom, 5)
                }
            }
            .padding(.bottom, 10)

            // お気に入り曲変更ボタン（UIKit 画面を開く）
            Button(action: {
                openSpotifySearch()
            }) {
                Text("お気に入り曲を変更")
                    .bold()
                    .frame(width: 180, height: 40)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
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
    
    // Firestoreからユーザー情報を取得
    private func fetchUserProfile() {
        guard let user = Auth.auth().currentUser else { return }
        let userRef = db.collection("users").document(user.uid)

        userRef.getDocument { document, error in
            if let document = document, document.exists {
                if let name = document.get("name") as? String {
                    self.username = name
                }
                if let url = document.get("imageURL") as? String {
                    self.imageURL = url
                    loadImage(from: url)
                }
                if let songs = document.get("favorite_song") as? [[String: Any]], !songs.isEmpty {
                    if let latestSong = songs.last {
                        self.favoriteSong = latestSong["name"] as? String ?? "お気に入り曲なし"
                        if let artists = latestSong["artists"] as? [String], !artists.isEmpty {
                            self.artistName = artists.joined(separator: ", ")
                        } else {
                            self.artistName = ""
                        }
                    }
                } else {
                    self.favoriteSong = "お気に入り曲なし"
                    self.artistName = ""
                }
            }
        }
    }

    // Firestoreにユーザー情報を更新（画像と名前のみ）
    private func updateUserProfile() {
        guard let user = Auth.auth().currentUser else { return }
        let userRef = db.collection("users").document(user.uid)

        userRef.setData(["name": username], merge: true) { error in
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

    // Spotify検索画面を開く
    private func openSpotifySearch() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else { return }
        
        let spotifyVC = SpotifySearchViewController()

        // もし onSongSelected が存在するなら、クロージャを設定
        if let spotifyVC = spotifyVC as? NSObject {
            let selector = Selector(("setOnSongSelected:"))
            if spotifyVC.responds(to: selector) {
                spotifyVC.setValue({ (selectedSong: String, selectedArtist: String) in
                    self.favoriteSong = selectedSong
                    self.artistName = selectedArtist

                    // Firestoreに即時更新
                    guard let user = Auth.auth().currentUser else { return }
                    let userRef = self.db.collection("users").document(user.uid)
                    let newSong: [String: Any] = [
                        "name": selectedSong,
                        "artists": [selectedArtist],
                        "savedAt": Timestamp(date: Date())
                    ]
                    userRef.setData(["favorite_song": newSong], merge: true)
                }, forKey: "onSongSelected")
            }
        }

        rootVC.present(spotifyVC, animated: true)
    }

    // Spotifyで選んだ曲を Firestore に即座に保存
    private func saveFavoriteSong(songName: String, artists: [String]) {
        guard let user = Auth.auth().currentUser else { return }
        let userRef = db.collection("users").document(user.uid)

        let newSong: [String: Any] = [
            "name": songName,
            "artists": artists,
            "savedAt": Timestamp(date: Date())
        ]

        userRef.setData(["favorite_song": [newSong]], merge: true) { error in
            if let error = error {
                print("Error updating favorite song: \(error)")
            } else {
                self.favoriteSong = songName
                self.artistName = artists.joined(separator: ", ")
            }
        }
    }
}

#Preview {
    ProfileView()
}
