import SwiftUI
import PhotosUI

struct ProfileView: View {
    @State private var username: String = "ユーザー名"
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = UIImage(systemName: "person.circle.fill")
    
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
            
            // 保存ボタン（今後Firebaseに保存する実装）
            Button(action: {
                print("プロフィール更新: \(username)")
                // Firebaseにプロフィール画像と名前を保存する処理をここに追加
            }) {
                Text("保存")
                    .bold()
                    .frame(width: 100, height: 40)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Spacer()
        }
        .navigationTitle("Profile")
    }
}

#Preview {
    ProfileView()
}
