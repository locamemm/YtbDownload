import SwiftUI

public struct AppTheme {
    public static let background = Color(red: 10/255, green: 11/255, blue: 16/255)
    public static let surface = Color(red: 19/255, green: 21/255, blue: 31/255)
    public static let surfaceCard = Color(red: 26/255, green: 28/255, blue: 41/255)
    public static let surfaceElevated = Color(red: 36/255, green: 40/255, blue: 59/255)

    public static let cyanAccent = Color(red: 0/255, green: 240/255, blue: 255/255)
    public static let purpleAccent = Color(red: 123/255, green: 44/255, blue: 191/255)
    public static let mintAccent = Color(red: 0/255, green: 245/255, blue: 160/255)
    public static let redAccent = Color(red: 255/255, green: 75/255, blue: 75/255)

    public static let textPrimary = Color.white
    public static let textSecondary = Color(white: 0.72)
    public static let textMuted = Color(white: 0.45)

    public static let primaryGradient = LinearGradient(
        colors: [cyanAccent, purpleAccent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let cardBorderGradient = LinearGradient(
        colors: [Color.white.opacity(0.18), Color.white.opacity(0.04)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

public struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 0

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppTheme.cardBorderGradient, lineWidth: 1)
            )
    }
}

extension View {
    public func glassCard(cornerRadius: CGFloat = 16, padding: CGFloat = 0) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, padding: padding))
    }
}
