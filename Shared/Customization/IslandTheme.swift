import Foundation

public struct IslandTheme: Codable, Hashable, Sendable {
    public var backgroundHex: String
    public var foregroundHex: String
    public var accentHex: String
    public var cornerRadius: Double
    public var iconStyle: IconStyle
    public var typographyScale: TypographyScale
    public var animationStyle: AnimationStyle

    public init(
        backgroundHex: String,
        foregroundHex: String,
        accentHex: String,
        cornerRadius: Double,
        iconStyle: IconStyle,
        typographyScale: TypographyScale,
        animationStyle: AnimationStyle
    ) {
        self.backgroundHex = backgroundHex
        self.foregroundHex = foregroundHex
        self.accentHex = accentHex
        self.cornerRadius = cornerRadius
        self.iconStyle = iconStyle
        self.typographyScale = typographyScale
        self.animationStyle = animationStyle
    }

    public enum IconStyle: String, Codable, CaseIterable, Sendable {
        case filled
        case outline
        case monochrome
    }

    public enum TypographyScale: String, Codable, CaseIterable, Sendable {
        case small
        case medium
        case large
    }

    public enum AnimationStyle: String, Codable, CaseIterable, Sendable {
        case subtle
        case expressive
        case disabled
    }

    public static let `default` = IslandTheme(
        backgroundHex: "#101826",
        foregroundHex: "#F8FAFC",
        accentHex: "#7DD3FC",
        cornerRadius: 26,
        iconStyle: .filled,
        typographyScale: .medium,
        animationStyle: .subtle
    )
}
