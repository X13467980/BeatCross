//
//  RegisterView.swift
//  SwiftTest1
//
//  Created by X on 2024/12/19.
//

import SwiftUI

struct WelcomeView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("BeatCross")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("すれ違うたび、新たなサウンドを。")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                NavigationLink(destination: RegisterView()) {
                    Text("登録")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                NavigationLink(destination: LoginView()) {
                    Text("ログイン")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
            //.navigationTitle("Null")
        }
    }
}

#Preview {
    WelcomeView()
}
