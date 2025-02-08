import SwiftUI

struct HomeView: View {
    // Firestore から取得した曲データを格納する変数
    @State private var encounteredSongs: [EncounteredUserFavSong] = []
    
    // Firebase からデータを取得するマネージャ
    private let favSongManager = GetFavSongManager()
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Received Songs")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)

                // ここでは encounteredSongs をそのまま表示する例
                ScrollView {
                    ForEach(encounteredSongs, id: \.song_id) { song in
                        HStack {
                            // 画像URLを使う場合は、ライブラリ等でURL画像を表示
                            // ここではプレースホルダーとしてイメージを使っています
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            VStack(alignment: .leading) {
                                Text(song.name)
                                    .font(.headline)
                                Text(song.artists.joined(separator: ", "))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }

                Spacer()

                // 🔍 小さい検索ボタンを画面右下に配置
                HStack {
                    Spacer()
                    Button(action: {
                        openSpotifySearch()
                    }) {
                        Text("🔍")
                            .font(.title)
                            .frame(width: 50, height: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding(.bottom, 30)
                    .padding(.trailing, 20)
                }
            }
            .padding()
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        openSpotifySearch()
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        // HomeView が表示されたときに自動で呼び出す
        .onAppear {
            favSongManager.fetchEncounteredUsersFavSongs { fetchedSongs in
                // 1. 受け取った曲データを State に格納
                encounteredSongs = fetchedSongs
                
                // 2. ログに出してみる
                print("----- [HomeView] fetchEncounteredUsersFavSongs 結果 -----")
                for song in fetchedSongs {
                    print("""
                    \nユーザーID: \(song.userId)
                    曲ID: \(song.song_id)
                    タイトル: \(song.name)
                    アルバム: \(song.album)
                    アーティスト: \(song.artists.joined(separator: ", "))
                    保存日時: \(song.savedAt.dateValue())
                    画像URL: \(song.image_url)
                    """)
                }
            }
        }
    }
    
    // SwiftUI から UIKit の `SpotifySearchViewController` を開く
    private func openSpotifySearch() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            let searchVC = SpotifySearchViewController()
            rootVC.present(searchVC, animated: true)
        }
    }
}

#Preview {
    HomeView()
}
