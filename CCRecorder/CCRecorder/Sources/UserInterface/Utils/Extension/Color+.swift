import SwiftUI

extension Color {
    
    enum `Any` {
        static var icon: Color                  { .init(hex: "#FEB400") }
    }
    
    enum Light {
        static var background: Color            { .init(uiColor: .systemBackground) }
        static var groupBackground: Color       { .init(uiColor: .systemGroupedBackground) }
        static var logoRed: Color               { .init(hex: "#E30111") }
        static var logoBlue: Color              { .init(hex: "#0DB0EA") }
        static var logoGreen: Color             { .init(hex: "#9DC30A") }
        static var recorder: Color              { .init(hex: "#282A30") }
    }
    
    enum Dark {
        static var background: Color             { .init(hex: "#282A30") }
        static var groupBackground: Color        { .init(hex: "#1C1E23") }
        static var logoRed: Color                { .init(hex: "#600000") }
        static var logoBlue: Color               { .init(hex: "#07387B") }
        static var logoGreen: Color              { .init(hex: "#02681B") }
        static var recorder: Color               { .init(hex: "#1C1E23") }
    }
    
}

extension Color {
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

}
