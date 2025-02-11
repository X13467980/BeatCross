import SwiftUI

struct Song: Identifiable, Decodable {
    let id = UUID()
    let image: String // 画像のURLまたはアセット名
    let title: String
    let artist: String
}

struct HomeView: View {
    @State private var currentIndex = 0
    @State private var encounteredSongs: [EncounteredUserFavSong] = []
    @GestureState private var dragOffset: CGFloat = 0
    private let favSongManager = GetFavSongManager()
    @StateObject var cBTVM = CBTthVerificationViewModel()
    
    // ローカルのモックデータ
    let music = [
        Song(image:"jaketTest", title:"新しい曲を探してみよう", artist:""),
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                ZStack {
                    Image("backGroundImage")
                        .resizable()
                        .ignoresSafeArea()
                        .scaledToFill()
                    
                    ForEach(0..<combinedSongs.count, id: \.self) { index in
                        VStack {
                            Text(combinedSongs[index].title)
                                .fontWeight(.heavy)
                                .foregroundColor(Color.white)
                                .font(.system(size: 20))
                            
                            Text(combinedSongs[index].artist)
                                .fontWeight(.heavy)
                                .foregroundColor(Color.white)
                                .font(.system(size: 14))
                            
                            if let url = URL(string: combinedSongs[index].image), combinedSongs[index].image.contains("http") {
                                AsyncImage(url: url) { image in
                                    image.resizable()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 120.0, height: 120.0)
                                .cornerRadius(60)
                            } else {
                                Image(combinedSongs[index].image)
                                    .resizable()
                                    .frame(width: 120.0, height: 120.0)
                                    .cornerRadius(60)
                            }
                        }
                        .frame(width: 300, height: 200)
                        .cornerRadius(25)
                        .opacity(currentIndex == index ? 1.0 : 0.5)
                        .scaleEffect(currentIndex == index ? 1.2 : 0.8)
                        .offset(x: CGFloat(index - currentIndex) * 200 + dragOffset, y: -120)
                    }
                }
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            let threshold: CGFloat = 50
                            if value.translation.width > threshold {
                                withAnimation {
                                    currentIndex = max(0, currentIndex - 1)
                                }
                            } else if value.translation.width < -threshold {
                                withAnimation {
                                    currentIndex = min(combinedSongs.count - 1, currentIndex + 1)
                                }
                            }
                        }
                )
                
                ScrollView {
                    ForEach(encounteredSongs, id: \.song_id) { song in
                        HStack {
                            AsyncImage(url: URL(string: song.image_url)) { image in
                                image.resizable()
                            } placeholder: {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .frame(width: 60, height: 60)
                            
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
            .navigationTitle("Home")
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .onAppear {
            favSongManager.fetchEncounteredUsersFavSongs { fetchedSongs in
                encounteredSongs = fetchedSongs
                print("Fetched \(fetchedSongs.count) songs")
            }
        }
    }
    
    private func openSpotifySearch() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            let searchVC = SpotifySearchViewController()
            searchVC.modalPresentationStyle = .fullScreen
            rootVC.present(searchVC, animated: true)
        }
    }
    
    private var combinedSongs: [Song] {
        music + encounteredSongs.map { song in
            Song(image: song.image_url, title: song.name, artist: song.artists.joined(separator: ", "))
        }
    }
}

#Preview {
    HomeView()
}
