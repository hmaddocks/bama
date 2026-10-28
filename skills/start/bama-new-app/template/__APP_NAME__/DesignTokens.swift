import Cocoa

/// The app's design tokens. DESIGN.md says which to use when; keep the two in
/// step. Add a token when a view needs one, not before. Colours not listed
/// here are system colours (`.labelColor`, `.controlAccentColor`, ...).
enum DesignTokens {
    // MARK: Colours
    // Add tokens here, each with a light and a dark value, and a comment
    // with its contrast when text sits on it or is drawn in it.

    /// A colour with a light and a dark value, resolved per appearance.
    static func dynamic(light: NSColor, dark: NSColor) -> NSColor {
        NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        }
    }

    /// The same, from hex strings: dynamic(light: "#047857", dark: "#34d399").
    static func dynamic(light: String, dark: String) -> NSColor {
        dynamic(light: NSColor(hex: light), dark: NSColor(hex: dark))
    }
}

extension NSColor {
    /// An sRGB colour from "#rrggbb" (the # is optional).
    convenience init(hex: String) {
        let digits = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let value = UInt32(digits, radix: 16) ?? 0
        self.init(srgbRed: CGFloat((value >> 16) & 0xFF) / 255,
                  green: CGFloat((value >> 8) & 0xFF) / 255,
                  blue: CGFloat(value & 0xFF) / 255,
                  alpha: 1)
    }
}

/// The 4 pt spacing scale. Every constraint constant, stack view spacing,
/// and edge inset uses one of these. tools/grid-lint.sh flags raw numbers.
enum Space {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let section: CGFloat = 32
    /// The margin between a window's edge and its content.
    static let margin: CGFloat = xl
}
