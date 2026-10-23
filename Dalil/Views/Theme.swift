import SwiftUI

/// Couleurs de l'accueil, reprises de l'app Android.
enum Theme {
    static let pageBackground = Color(UIColor(hex: 0xF1E6CE))
    static let rowBackground = Color(UIColor(hex: 0xF8F1DD))
    static let titleBrown = Color(UIColor(hex: 0x4A3524))
    static let textInk = Color(UIColor(hex: 0x3A2A1A))
    static let accentGreen = Color(UIColor(hex: 0x2F6B4F))
    static let accentGold = Color(UIColor(hex: 0xC9A227))
    static let bookmarkRed = Color(UIColor(hex: 0xB3261E))
}

/// Petit ruban de marque-page : rectangle à bas échancré.
struct RibbonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.76))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct BookmarkRibbon: View {
    var color: Color = Theme.bookmarkRed
    var filled = true

    var body: some View {
        if filled {
            RibbonShape().fill(color)
        } else {
            RibbonShape().stroke(color, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
        }
    }
}
