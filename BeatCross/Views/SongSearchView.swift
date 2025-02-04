//
//  SongSearchView.swift
//  BeatCross
//
//  Created by X on 2025/01/29.
//

import SwiftUI

struct SongSearchView: View {
    @State private var searchQuery = ""
    @State private var searchResults: [Song] = []

    var onSelect: (String) -> Void // 選択時に songId を渡すクロージャ

    var body: some View {
        VStack {
            TextField("Search for a song", text: $searchQuery, onCommit: searchSongs)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            List(searchResults) { song in
                Button(action: {
                    onSelect(song.id) // 選択した曲のIDを渡す
                }) {
                    HStack {
                        AsyncImage(url: URL(string: song.imageUrl)) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 50, height: 50)
                        .cornerRadius(5)

                        VStack(alignment: .leading) {
                            Text(song.title)
                                .font(.headline)
                            Text(song.artist)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
    }

    func searchSongs() {
        SpotifyAPI.shared.searchSongs(query: searchQuery) { result in
            switch result {
            case .success(let songs):
                self.searchResults = songs
            case .failure(let error):
                print("Error searching songs: \(error.localizedDescription)")
            }
        }
    }
}

struct Song: Identifiable {
    let id: String
    let title: String
    let artist: String
    let imageUrl: String
}

#Preview {
    SongSearchView()
}
