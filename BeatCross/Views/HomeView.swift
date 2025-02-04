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
    // 受信した曲のデータ (サンプルデータとして作成)
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

                // 曲のリストを表示
                ScrollView {
                    ForEach(receivedSongs) { song in
                        HStack {
                            // ジャケット画像
                            Image(song.image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading) {
                                // 曲名
                                Text(song.title)
                                    .font(.headline)

                                // アーティスト名
                                Text(song.artist)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding()
            .navigationBarBackButtonHidden(true) // 戻るボタンを非表示
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeView()
}
