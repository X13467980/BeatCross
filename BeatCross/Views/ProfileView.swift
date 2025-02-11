import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack {
            Text("プロフィールページ")
                .font(.largeTitle)
                .bold()
            Spacer()
        }
        .navigationTitle("Profile")
    }
}

#Preview {
    ProfileView()
}
