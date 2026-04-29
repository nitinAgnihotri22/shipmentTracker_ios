import SwiftUI

struct ProfileHeaderView: View {
    let initial: String
    let name: String
    let email: String
    let onLogout: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(Text(initial).font(.headline))

            VStack(alignment: .leading) {
                Text(name).font(.headline)
                Text(email).font(.footnote).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Logout", role: .destructive, action: onLogout)
                .accessibilityLabel("Logout")
        }
    }
}
