//
//  RegisterView.swift
//  SwiftTest1
//
//  Created by X on 2024/12/19.
//

import SwiftUI

extension Color {
    static let mainDarkBlue = Color(red: 34/255, green: 37/255, blue: 46/255) // #22252E
}

struct WelcomeView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Image("backGroundImage")
                    .resizable()
                    .ignoresSafeArea()
                    .scaledToFill()
                
                VStack(spacing: 30) {
                    Text("BeatCross")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .white, radius: 1.5, x: 1, y: 1)
                    
                    Text("すれ違うたび、新たなサウンドを。")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .foregroundColor( .white)
                        .shadow(color: .white, radius: 1.5, x: 1, y: 1)
                    
                    NavigationLink(destination: RegisterView()) {
                        Text("登録")
                            .frame(width:224,height:25)
                            .fontWeight(.bold)
                            .padding()
                            .background(Color.mainDarkBlue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10)) // 角丸の適用
                            .overlay( // ボーダーの適用
                                RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white, lineWidth: 0.8)
                            )
                            
                    }
                    
                    NavigationLink(destination: LoginView()) {
                        Text("ログイン")
//                            .frame(maxWidth: .infinity)
                            .frame(width:224,height:25)
                            .fontWeight(.bold)
                            .padding()
                            .background(Color.mainDarkBlue)
                            .foregroundColor(.white)
                            .clipShape( // 角丸の適用
                                RoundedRectangle(cornerRadius: 10))
                            .overlay( // ボーダーの適用
                                RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white, lineWidth: 0.8)
                            )
                    }
                }
                .padding()
            }
            //.navigationTitle("Null")
        }
    }
}

#Preview {
    WelcomeView()
}
