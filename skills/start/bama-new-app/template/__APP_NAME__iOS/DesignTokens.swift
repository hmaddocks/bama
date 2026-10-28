import UIKit

/// The iOS app's design tokens: the same names and values as the Mac
/// target's DesignTokens.swift, as UIColor. Only Space.margin differs, for
/// touch. DESIGN.md says which to use when.
enum DesignTokens {
    // MARK: Colours
    // Add tokens here, each with a light and a dark value, and a comment
    // with its contrast when text sits on it or is drawn in it.

    /// A colour with a light and a dark value, resolved per trait collection.
    static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { traits in traits.userInterfaceStyle == .dark ? dark : light }
    }

    /// The same, from hex strings: dynamic(light: "#047857", dark: "#34d399").
    static func dynamic(light: String, dark: String) -> UIColor {
        dynamic(light: UIColor(hex: light), dark: UIColor(hex: dark))
    }
}

extension UIColor {
    /// An sRGB colour from "#rrggbb" (the # is optional).
    convenience init(hex: String) {
        let digits = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let value = UInt32(digits, radix: 16) ?? 0
        self.init(red: CGFloat((value >> 16) & 0xFF) / 255,
                  green: CGFloat((value >> 8) & 0xFF) / 255,
                  blue: CGFloat(value & 0xFF) / 255,
                  alpha: 1)
    }
}

/// The 4 pt spacing scale, the same as the Mac target's. Every constraint
/// constant, stack view spacing, and inset uses one of these.
enum Space {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let section: CGFloat = 32
    /// The margin between the screen edge and content, where the system's
    /// layout margins do not already give one.
    static let margin: CGFloat = lg
}
