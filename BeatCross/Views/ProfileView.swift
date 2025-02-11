//
//  ProfileView.swift
//  BeatCross
//
//  Created by X on 2025/02/11.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("プロフィール")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Profile")
    }
}

#Preview {
    ProfileView()
}
