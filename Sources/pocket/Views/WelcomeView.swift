import SwiftUI

/// Shown once on first launch: brand mark, tagline, three quick tips.
struct WelcomeView: View {
    var onStart: () -> Void

    private let shortcut = Shortcut.load()

    var body: some View {
        VStack(spacing: 18) {
            PocketMark(size: 72)

            VStack(spacing: 3) {
                Text("pocket").font(.title2.weight(.bold))
                Text("Cebindeki mini kasa")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                tip("bolt.fill", "\(shortcut.display) ile her yerden aç")
                tip("hand.tap.fill", "Tıkla, anında kopyala")
                tip("lock.fill", "Gizlileri Touch ID'li kasada sakla")
            }

            Button(action: onStart) {
                Text("Başla").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(28)
        .frame(width: 360)
    }

    private func tip(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 11) {
            Image(systemName: symbol)
                .font(.system(size: 15))
                .foregroundStyle(.tint)
                .frame(width: 22)
            Text(text).font(.callout)
            Spacer(minLength: 0)
        }
    }
}
