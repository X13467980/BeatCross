//
//  HomeView.swift
//  BeatCross
//
//  Created by X on 2025/01/06.
//

import SwiftUI

struct Song: Identifiable, Decodable {
    let id = UUID()
    let image: String // 画像のURLまたはアセット名
    let title: String
    let artist: String
}

struct HomeView: View {
    @State private var receivedSongs: [Song] = [
        Song(image: "album1", title: "Song Title 1", artist: "Artist 1"),
        Song(image: "album2", title: "Song Title 2", artist: "Artist 2"),
        Song(image: "album3", title: "Song Title 3", artist: "Artist 3")
    ]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Received Songs")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)

                ScrollView {
                    ForEach(receivedSongs) { song in
                        HStack {
                            Image(song.image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading) {
                                Text(song.title)
                                    .font(.headline)

                                Text(song.artist)
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
