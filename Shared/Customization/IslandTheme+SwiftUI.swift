import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public extension IslandTheme {
    var backgroundColor: Color { Color(hex: backgroundHex) ?? .black }
    var foregroundColor: Color { Color(hex: foregroundHex) ?? .white }
    var accentColor: Color { Color(hex: accentHex) ?? .cyan }
    var glassTintColor: Color { accentColor.opacity(0.18) }
    var glassStrokeColor: Color { foregroundColor.opacity(0.14) }
    var shadowColor: Color { accentColor.opacity(0.22) }

    var backdropGradient: LinearGradient {
        LinearGradient(
            colors: [
                backgroundColor.opacity(0.98),
                backgroundColor.opacity(0.8),
                accentColor.opacity(0.24)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

public struct LiquidGlassBackdrop: View {
    public let theme: IslandTheme

    public init(theme: IslandTheme) {
        self.theme = theme
    }

    public var body: some View {
        ZStack {
            theme.backdropGradient
            RadialGradient(
                colors: [
                    theme.accentColor.opacity(0.28),
                    theme.accentColor.opacity(0.02),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 320
            )
            .blendMode(.screen)

            RadialGradient(
                colors: [
                    theme.foregroundColor.opacity(0.12),
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 360
            )
        }
        .ignoresSafeArea()
    }
}

public extension View {
    func liquidGlassCard(
        theme: IslandTheme,
        cornerRadius: CGFloat? = nil,
        tint: Color? = nil
    ) -> some View {
        modifier(
            LiquidGlassCardModifier(
                theme: theme,
                cornerRadius: cornerRadius ?? theme.cornerRadius,
                tint: tint ?? theme.glassTintColor
            )
        )
    }
}

private struct LiquidGlassCardModifier: ViewModifier {
    let theme: IslandTheme
    let cornerRadius: CGFloat
    let tint: Color

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        tint.opacity(0.34),
                                        theme.backgroundColor.opacity(0.12),
                                        theme.foregroundColor.opacity(0.04)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        theme.foregroundColor.opacity(0.34),
                                        theme.glassStrokeColor,
                                        theme.accentColor.opacity(0.12)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: theme.shadowColor, radius: 24, y: 16)
            }
    }
}

public extension Color {
    init?(hex: String) {
        let sanitized = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        guard sanitized.count == 6 || sanitized.count == 8,
              let rawValue = UInt64(sanitized, radix: 16) else {
            return nil
        }

        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double

        if sanitized.count == 8 {
            red = Double((rawValue & 0xFF00_0000) >> 24) / 255
            green = Double((rawValue & 0x00FF_0000) >> 16) / 255
            blue = Double((rawValue & 0x0000_FF00) >> 8) / 255
            alpha = Double(rawValue & 0x0000_00FF) / 255
        } else {
            red = Double((rawValue & 0xFF0000) >> 16) / 255
            green = Double((rawValue & 0x00FF00) >> 8) / 255
            blue = Double(rawValue & 0x0000FF) / 255
            alpha = 1
        }

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    var hexString: String {
        #if canImport(UIKit)
        let components = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
        let red = Int((components[safe: 0] ?? 0) * 255)
        let green = Int((components[safe: 1] ?? 0) * 255)
        let blue = Int((components[safe: 2] ?? 0) * 255)
        return String(format: "#%02X%02X%02X", red, green, blue)
        #elseif canImport(AppKit)
        let color = NSColor(self).usingColorSpace(.sRGB) ?? .black
        return String(
            format: "#%02X%02X%02X",
            Int(color.redComponent * 255),
            Int(color.greenComponent * 255),
            Int(color.blueComponent * 255)
        )
        #else
        return "#000000"
        #endif
    }
}

private extension Array where Element == CGFloat {
    subscript(safe index: Int) -> CGFloat? {
        indices.contains(index) ? self[index] : nil
    }
}
