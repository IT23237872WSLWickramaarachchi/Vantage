//
//  VantageTheme.swift
//  Vantage
//
//  Created by Antigravity on 2026-10-17.
//

import SwiftUI
import SwiftData

// MARK: - Vantage Design System & Theme Tokens
public struct VantageTheme {
    /// Academic primary accent - Indigo (#7779C9)
    public static let academicAccent = Color(hex: "#7779C9")
    
    /// Work primary accent - Teal (#2A9D98)
    public static let workAccent = Color(hex: "#2A9D98")
    
    /// Dark theme background tint for subtle glassmorphic contrast
    public static let backgroundDark = Color(red: 0.07, green: 0.08, blue: 0.11)
    
    /// Surface card glass fill
    public static let surfaceGlass = Color.white.opacity(0.06)
    
    /// Subtle border stroke for spatial cards
    public static let glassBorder = Color.white.opacity(0.12)
    
    /// Event conflict warning accent - Coral (#E46B72)
    public static let conflictWarning = Color(hex: "#E46B72")
}

// MARK: - Color Hex Initializer & Convenience Extensions
extension Color {
    /// Initialize a SwiftUI Color from a hexadecimal color string (supports 3, 6, or 8 characters)
    public init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }
    
    /// Accent color for Academic domain items (#7779C9)
    public static let academicAccent = VantageTheme.academicAccent
    
    /// Accent color for Work domain items (#2A9D98)
    public static let workAccent = VantageTheme.workAccent
    
    /// Warning color for event conflicts (#E46B72)
    public static let conflictWarning = VantageTheme.conflictWarning
}

// MARK: - Glass Surface Card ViewModifier
public struct GlassSurfaceModifier: ViewModifier {
    @Query private var settingsList: [ApplicationSettings]
    var cornerRadius: CGFloat = 16
    var borderColor: Color = VantageTheme.glassBorder
    
    private var hasGlow: Bool {
        settingsList.first?.enableGlassmorphicGlow ?? true
    }
    
    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(VantageTheme.surfaceGlass)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(borderColor, lineWidth: 1)
                    )
                    .shadow(color: hasGlow ? borderColor.opacity(0.18) : .clear, radius: 8, x: 0, y: 3)
            )
    }
}

extension View {
    /// Applies a dark-themed translucent glass card surface with continuous rounded corners
    public func vantageGlassCard(cornerRadius: CGFloat = 16, borderColor: Color = VantageTheme.glassBorder) -> some View {
        self.modifier(GlassSurfaceModifier(cornerRadius: cornerRadius, borderColor: borderColor))
    }
}
