import SwiftUI

/// The pocket logo mark: a gradient squircle with the tray glyph. Used in the
/// header and welcome screen so the brand reads consistently.
struct PocketMark: View {
    var size: CGFloat = 64

    static let gradient = LinearGradient(
        colors: [Color(red: 0.36, green: 0.36, blue: 0.96),
                 Color(red: 0.55, green: 0.36, blue: 0.96)],
        startPoint: .top, endPoint: .bottom)

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
            .fill(PocketMark.gradient)
            .overlay(
                Image(systemName: "tray.full.fill")
                    .font(.system(size: size * 0.48, weight: .semibold))
                    .foregroundStyle(.white)
            )
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.18), radius: size * 0.06, y: size * 0.03)
    }
}
