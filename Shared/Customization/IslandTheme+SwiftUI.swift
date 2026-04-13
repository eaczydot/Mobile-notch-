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
    var glassHighlightColor: Color { foregroundColor.opacity(0.12) }

    var backdropGradient: LinearGradient {
        LinearGradient(
            colors: [
                backgroundColor.opacity(0.98),
                backgroundColor.opacity(0.86),
                accentColor.opacity(0.26)
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
            LinearGradient(
                colors: [
                    theme.foregroundColor.opacity(0.06),
                    .clear,
                    theme.accentColor.opacity(0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
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

public struct LiquidGlassCluster<Content: View>: View {
    private let spacing: CGFloat?
    private let content: Content

    public init(
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.spacing = spacing
        self.content = content()
    }

    @ViewBuilder
    public var body: some View {
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content
            }
        } else {
            content
        }
    }
}

public extension View {
    func liquidGlassCard(
        theme: IslandTheme,
        cornerRadius: CGFloat? = nil,
        tint: Color? = nil,
        isInteractive: Bool = false
    ) -> some View {
        modifier(
            LiquidGlassCardModifier(
                theme: theme,
                cornerRadius: cornerRadius ?? theme.cornerRadius,
                tint: tint ?? theme.glassTintColor,
                isInteractive: isInteractive
            )
        )
    }

    @ViewBuilder
    func liquidGlassButtonStyle(prominent: Bool = false) -> some View {
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
            if prominent {
                buttonStyle(.glassProminent)
            } else {
                buttonStyle(.glass)
            }
        } else if prominent {
            buttonStyle(.borderedProminent)
        } else {
            buttonStyle(.bordered)
        }
    }
}

private struct LiquidGlassCardModifier: ViewModifier {
    let theme: IslandTheme
    let cornerRadius: CGFloat
    let tint: Color
    let isInteractive: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
            content
                .background(theme.backgroundColor.opacity(0.12), in: cardShape)
                .overlay {
                    cardShape
                        .fill(
                            LinearGradient(
                                colors: [
                                    tint.opacity(0.18),
                                    theme.backgroundColor.opacity(0.06),
                                    theme.glassHighlightColor.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay {
                    cardShape
                        .stroke(
                            LinearGradient(
                                colors: [
                                    theme.foregroundColor.opacity(0.3),
                                    theme.glassStrokeColor,
                                    theme.accentColor.opacity(0.14)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .glassEffect(.regular.tint(tint).interactive(isInteractive), in: cardShape)
                .shadow(color: theme.shadowColor, radius: 24, y: 16)
        } else {
            content
                .background {
                    cardShape
                        .fill(.ultraThinMaterial)
                        .overlay(
                            cardShape
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
                            cardShape
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

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
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
