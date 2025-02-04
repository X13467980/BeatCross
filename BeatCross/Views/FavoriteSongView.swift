//
//  FavoriteSongView.swift
//  BeatCross
//
//  Created by X on 2025/01/29.
//

import SwiftUI
import FirebaseFirestore

struct FavoriteSongView: View {
    let userId: String // Firestore に保存するためのユーザーID
    @State private var selectedSongId: String? = nil
    @State private var navigateToHome: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Select Your Favorite Song")
                    .font(.title2)
                    .fontWeight(.bold)
                
                SongSearchView { songId in
                    self.selectedSongId = songId
                }
                
                if selectedSongId != nil {
                    Button(action: {
                        saveFavoriteSong()
                    }) {
                        Text("Save and Continue")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
            .navigationTitle("Favorite Song")
            .navigationDestination(isPresented: $navigateToHome) {
                HomeView()
            }
        }
    }

    func saveFavoriteSong() {
        guard let selectedSongId = selectedSongId else { return }
        
        Firestore.firestore().collection("users").document(userId).updateData([
            "song_id": selectedSongId
        ]) { error in
            if let error = error {
                print("Error updating favorite song: \(error.localizedDescription)")
            } else {
                navigateToHome = true
            }
        }
    }
}

#Preview {
    FavoriteSongView(userId: "testUserId")
}
