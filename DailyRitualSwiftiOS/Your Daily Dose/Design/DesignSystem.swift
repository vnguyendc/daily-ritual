//
//  EliteDesignSystem.swift
//  Your Daily Dose
//
//  Elite Performance Design System - Dual Theme Architecture for Athletes
//  Created by VinhNguyen on 8/19/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Elite Performance Design System
// Dual theme architecture supporting both dark and light modes for optimal athletic performance
//
// THEME STRATEGY:
// • Dark Mode (Default): Premium feel, reduced eye strain for early morning/evening sessions, OLED battery conservation
// • Light Mode: Better visibility in bright gym environments, outdoor training, midday use
// • Universal Accents: Elite Gold and Champion Blue work perfectly on both backgrounds
// • High Contrast: 4.5:1 minimum ratio ensures readability in all lighting conditions

struct DesignSystem {
    
    // MARK: - Dual Theme Color System - Elite Performance in Any Light
    struct Colors {
        // MARK: - Universal Performance Accents (Consistent Across Themes)
        static let eliteGold = Color(red: 1.0, green: 0.72, blue: 0.0)      // #FFB800 - Primary CTA, achievements, PR indicators
        static let championBlue = Color(red: 0.0, green: 0.6, blue: 1.0)    // #0099FF - Secondary actions, links, data highlights
        static let alertRed = Color(red: 1.0, green: 0.2, blue: 0.4)        // #FF3366 - Warnings, missed targets, critical data
        
        // MARK: - Theme-Aware Colors (Automatically adapt based on system appearance)
        
        // Power Green - Success states, goals completed
        static let powerGreen = Color(red: 0.0, green: 0.9, blue: 0.46)     // #00E676 (dark) / will auto-adapt
        static let powerGreenLight = Color(red: 0.0, green: 0.78, blue: 0.32) // #00C851 (light mode version)
        
        // Background Foundation (Theme-aware - automatically adapts to light/dark mode)
        static let background = Color(
            light: Color(red: 0.97, green: 0.97, blue: 0.98),               // #F8F9FA - Clean White (light)
            dark: Color(red: 0.04, green: 0.05, blue: 0.06)                 // #0B0C10 - Deeper Obsidian (dark)
        )
        static let secondaryBackground = Color(
            light: Color.white,                                              // #FFFFFF - Pure White (light)
            dark: Color(red: 0.08, green: 0.09, blue: 0.10)                // #14161A - Near black (dark)
        )
        static let cardBackground = Color(
            light: Color(red: 0.95, green: 0.95, blue: 0.96),              // #F1F3F5 - Light Gray (light)
            dark: Color(red: 0.07, green: 0.07, blue: 0.09)                // #111217 - Deep card (dark)
        )
        
        // Dynamic Text Hierarchy (Theme-aware)
        static let primaryText = Color(
            light: Color(red: 0.10, green: 0.11, blue: 0.12),              // #1A1B1F (light)
            dark: Color.white                                                // #FFFFFF (dark)
        )
        static let secondaryText = Color(
            light: Color(red: 0.29, green: 0.31, blue: 0.34),              // #495057 (light)
            dark: Color(red: 0.72, green: 0.74, blue: 0.78)                // #B8BCC8 (dark)
        )
        static let tertiaryText = Color(
            light: Color(red: 0.42, green: 0.46, blue: 0.49),              // #6C757D (light)
            dark: Color(red: 0.42, green: 0.45, blue: 0.50)                // #6B7280 (dark)
        )
        static let invertedText = Color(
            light: Color.white,                                              // White (light)
            dark: Color(red: 0.04, green: 0.04, blue: 0.05)                // Dark (dark)
        )
        
        // Borders & Dividers (Theme-aware)
        static let border = Color(
            light: Color.gray.opacity(0.3),                                 // Light gray border (light)
            dark: Color.white.opacity(0.16)                                 // Subtle light border (dark)
        )
        static let divider = Color(
            light: Color.gray.opacity(0.2),                                 // Subtle divider (light)
            dark: Color.white.opacity(0.12)                                 // Subtle but clear (dark)
        )
        
        // MARK: - Custom Dark/Light Mode Definitions
        // For cases where we need explicit control beyond system colors
        
        // Deep Obsidian Dark Mode Background
        static let deepObsidian = Color(
            light: Color(red: 0.97, green: 0.97, blue: 0.98),              // #F8F9FA - Clean White (light mode)
            dark: Color(red: 0.04, green: 0.04, blue: 0.05)                // #0A0B0D - Deep Obsidian (dark mode)
        )
        
        // Carbon Black Secondary Surfaces
        static let carbonBlack = Color(
            light: Color.white,                                              // #FFFFFF - Pure White (light mode)
            dark: Color(red: 0.10, green: 0.11, blue: 0.12)                // #1A1B1F - Carbon Black (dark mode)
        )
        
        // Graphite Elevated Surfaces
        static let graphite = Color(
            light: Color(red: 0.95, green: 0.95, blue: 0.96),              // #F1F3F5 - Light Gray (light mode)
            dark: Color(red: 0.18, green: 0.18, blue: 0.20)                // #2D2E33 - Graphite (dark mode)
        )
        
        // Performance Text Colors with High Contrast
        static let performancePrimaryText = Color(
            light: Color(red: 0.10, green: 0.11, blue: 0.12),              // #1A1B1F (light mode)
            dark: Color.white                                                // #FFFFFF (dark mode)
        )
        
        static let performanceSecondaryText = Color(
            light: Color(red: 0.29, green: 0.31, blue: 0.34),              // #495057 (light mode)
            dark: Color(red: 0.72, green: 0.74, blue: 0.78)                // #B8BCC8 (dark mode)
        )
        
        static let performanceTertiaryText = Color(
            light: Color(red: 0.42, green: 0.46, blue: 0.49),              // #6C757D (light mode)
            dark: Color(red: 0.42, green: 0.45, blue: 0.50)                // #6B7280 (dark mode)
        )
        
        // MARK: - Legacy Support (for backward compatibility)
        static let primary = eliteGold                                       // Map to Elite Gold
        static let primaryLight = eliteGold.opacity(0.8)                    // Lighter version
        static let primaryDark = eliteGold.opacity(1.2)                     // Darker version
        static let premium = eliteGold                                       // Premium accent
        static let success = powerGreen                                      // Success states
        static let warning = Color.orange                                    // Warning states
        
        // Time-based theming with new palette
        static let morning = eliteGold.opacity(0.1)                         // Gold tint for morning
        static let morningAccent = eliteGold                                 // Elite Gold for morning
        static let evening = championBlue.opacity(0.1)                      // Blue tint for evening
        static let eveningAccent = championBlue                              // Champion Blue for evening
        
        // MARK: - Elite Performance Gradients (Theme-Aware)
        static let morningGradient = LinearGradient(
            colors: [
                DesignSystem.Colors.background,
                DesignSystem.Colors.eliteGold.opacity(0.08)         // Slightly bolder gold tint
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let eveningGradient = LinearGradient(
            colors: [
                DesignSystem.Colors.background,
                DesignSystem.Colors.championBlue.opacity(0.08)      // Slightly bolder blue tint
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let neutralGradient = LinearGradient(
            colors: [
                DesignSystem.Colors.background,                     // Adapts to theme
                DesignSystem.Colors.secondaryBackground            // Subtle depth
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // MARK: - Champion Performance Gradients (For Special States)
        static let achievementGradient = LinearGradient(
            colors: [
                eliteGold.opacity(0.8),
                eliteGold
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let successGradient = LinearGradient(
            colors: [
                powerGreen.opacity(0.8),
                powerGreen
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Premium Typography System
    // Using Instrument Sans + Crimson Pro for distinctive, premium feel
    struct Typography {
        // Headers & Display - Instrument Sans Variable Font with weights
        static let displayLarge = Font.custom("Instrument Sans", size: 34, relativeTo: .largeTitle).weight(.semibold)
        static let displayMedium = Font.custom("Instrument Sans", size: 28, relativeTo: .title).weight(.semibold)
        static let displaySmall = Font.custom("Instrument Sans", size: 22, relativeTo: .title2).weight(.medium)
        
        // Headlines - Instrument Sans Medium for clear hierarchy
        static let headlineLarge = Font.custom("Instrument Sans", size: 20, relativeTo: .title3).weight(.semibold)
        static let headlineMedium = Font.custom("Instrument Sans", size: 18, relativeTo: .headline).weight(.medium)
        static let headlineSmall = Font.custom("Instrument Sans", size: 16, relativeTo: .headline).weight(.medium)
        
        // Body Text - Instrument Sans Regular (weight 400) for optimal readability
        static let bodyLarge = Font.custom("Instrument Sans", size: 17, relativeTo: .body).weight(.regular)
        static let bodyMedium = Font.custom("Instrument Sans", size: 15, relativeTo: .callout).weight(.regular)
        static let bodySmall = Font.custom("Instrument Sans", size: 13, relativeTo: .subheadline).weight(.regular)
        
        // Quotes & Affirmations - Crimson Pro Italic Variable Font
        static let quoteText = Font.custom("Crimson Pro", size: 18, relativeTo: .body).italic()
        static let quoteAttribution = Font.custom("Crimson Pro", size: 14, relativeTo: .caption).italic()
        static let affirmationText = Font.custom("Crimson Pro", size: 16, relativeTo: .body).italic()
        
        // Specialized for journaling - Instrument Sans Regular for extended reading/writing
        static let journalTitle = Font.custom("Instrument Sans", size: 20, relativeTo: .title3).weight(.medium)
        static let journalPrompt = Font.custom("Instrument Sans", size: 15, relativeTo: .body).weight(.regular)
        static let journalText = Font.custom("Instrument Sans", size: 16, relativeTo: .body).weight(.regular)
        static let journalPlaceholder = Font.custom("Instrument Sans", size: 16, relativeTo: .body).weight(.regular)
        
        // UI Elements & Buttons - Instrument Sans Medium (weight 500)
        static let buttonLarge = Font.custom("Instrument Sans", size: 17, relativeTo: .headline).weight(.medium)
        static let buttonMedium = Font.custom("Instrument Sans", size: 15, relativeTo: .body).weight(.medium)
        static let buttonSmall = Font.custom("Instrument Sans", size: 13, relativeTo: .subheadline).weight(.medium)
        
        // Captions and metadata - Instrument Sans Regular
        static let caption = Font.custom("Instrument Sans", size: 12, relativeTo: .caption).weight(.regular)
        static let metadata = Font.custom("Instrument Sans", size: 11, relativeTo: .caption2).weight(.regular)
        
        // Fallback fonts in case custom fonts aren't available
        static let displayLargeFallback = Font.system(size: 34, weight: .semibold, design: .default)
        static let bodyLargeFallback = Font.system(size: 17, weight: .regular, design: .default)
        static let quoteTextFallback = Font.system(size: 18, weight: .regular, design: .serif).italic()
        
        // MARK: - Font Loading Helpers
        /// Checks if a UIFont with given name can be created (iOS only)
        private static func isFontAvailable(_ name: String) -> Bool {
            #if canImport(UIKit)
            return UIFont(name: name, size: 12) != nil
            #else
            return false
            #endif
        }

        /// Safe font loading with automatic fallback and dynamic type scaling
        static func safeFont(name: String, size: CGFloat, relativeTo textStyle: Font.TextStyle, fallbackDesign: Font.Design = .default, weight: Font.Weight? = nil, italic: Bool = false) -> Font {
            if isFontAvailable(name) {
                var f = Font.custom(name, size: size, relativeTo: textStyle)
                if let w = weight { f = f.weight(w) }
                if italic { f = f.italic() }
                return f
            } else {
                var f = Font.system(textStyle, design: fallbackDesign)
                if let w = weight { f = f.weight(w) }
                if italic { f = f.italic() }
                return f
            }
        }

        // MARK: - Safe Font Variants (dynamic)
        static var displayLargeSafe: Font { safeFont(name: "Instrument Sans", size: 34, relativeTo: .largeTitle, weight: .semibold) }
        static var displayMediumSafe: Font { safeFont(name: "Instrument Sans", size: 28, relativeTo: .title, weight: .semibold) }
        static var displaySmallSafe: Font { safeFont(name: "Instrument Sans", size: 22, relativeTo: .title2, weight: .medium) }
        static var headlineLargeSafe: Font { safeFont(name: "Instrument Sans", size: 20, relativeTo: .title3, weight: .semibold) }
        static var bodyLargeSafe: Font { safeFont(name: "Instrument Sans", size: 17, relativeTo: .body) }
        static var quoteTextSafe: Font { safeFont(name: "Crimson Pro", size: 18, relativeTo: .body, fallbackDesign: .serif, italic: true) }
        static var journalTitleSafe: Font { safeFont(name: "Instrument Sans", size: 20, relativeTo: .title3, weight: .medium) }
        static var journalTextSafe: Font { safeFont(name: "Instrument Sans", size: 16, relativeTo: .body) }
        static var affirmationTextSafe: Font { safeFont(name: "Crimson Pro", size: 16, relativeTo: .body, fallbackDesign: .serif, italic: true) }
        static var buttonLargeSafe: Font { safeFont(name: "Instrument Sans", size: 17, relativeTo: .headline, weight: .medium) }
    }
    
    // MARK: - Spacing System - Generous & Mindful
    struct Spacing {
        // Base spacing units
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
        
        // Semantic spacing for different contexts
        static let cardPadding: CGFloat = 20        // Mobile cards
        static let cardPaddingLarge: CGFloat = 32   // iPad cards
        static let sectionSpacing: CGFloat = 32     // Between major sections
        static let elementSpacing: CGFloat = 20     // Between related elements
        static let compactSpacing: CGFloat = 12     // For tight layouts
        
        // Touch targets - accessibility focused
        static let minTouchTarget: CGFloat = 44
        static let preferredTouchTarget: CGFloat = 50
        
        // Line spacing for enhanced readability (points)
        static let lineSpacingTight: CGFloat = 2
        static let lineSpacingNormal: CGFloat = 4
        static let lineSpacingRelaxed: CGFloat = 6  // For journal text
    }
    
    // MARK: - Corner Radius - Soft & Modern
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16     // Primary radius for cards
        static let large: CGFloat = 24      // For prominent elements
        static let extraLarge: CGFloat = 32 // For hero elements
        
        // Semantic radii
        static let card: CGFloat = 16
        static let button: CGFloat = 12
        static let input: CGFloat = 12
        static let badge: CGFloat = 20      // Fully rounded small elements
    }
    
    // MARK: - Elite Performance Shadow System - Theme-Aware Elevation
    struct Shadow {
        // Theme-aware shadows that work in both light and dark modes
        static let subtle = (
            color: Color.primary.opacity(0.08),
            radius: CGFloat(4),
            x: CGFloat(0),
            y: CGFloat(1)
        )
        
        static let card = (
            color: Color.primary.opacity(0.12),
            radius: CGFloat(8),
            x: CGFloat(0),
            y: CGFloat(2)
        )
        
        static let elevated = (
            color: Color.primary.opacity(0.16),
            radius: CGFloat(12),
            x: CGFloat(0),
            y: CGFloat(4)
        )
        
        static let floating = (
            color: Color.primary.opacity(0.20),
            radius: CGFloat(16),
            x: CGFloat(0),
            y: CGFloat(6)
        )
        
        // Elite performance shadows for special states (still used for floating controls)
        static let achievement = (
            color: DesignSystem.Colors.eliteGold.opacity(0.3),
            radius: CGFloat(20),
            x: CGFloat(0),
            y: CGFloat(8)
        )
        
        static let success = (
            color: DesignSystem.Colors.powerGreen.opacity(0.3),
            radius: CGFloat(16),
            x: CGFloat(0),
            y: CGFloat(6)
        )
    }
    
    // MARK: - Animation System - Mindful Motion
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let gentle = SwiftUI.Animation.easeInOut(duration: 0.7)  // For mindful transitions
        
        // Spring animations for organic feel
        static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.7)
        static let springGentle = SwiftUI.Animation.spring(response: 0.7, dampingFraction: 0.8)
        
        // Progress animations
        static let progress = SwiftUI.Animation.easeInOut(duration: 1.0)
    }
    
    // MARK: - Elite Performance Time-Based Theme Context
    enum TimeContext {
        case morning
        case evening
        case neutral
        
        var primaryColor: Color {
            switch self {
            case .morning: return DesignSystem.Colors.eliteGold      // Elite Gold for morning energy
            case .evening: return DesignSystem.Colors.championBlue   // Champion Blue for evening reflection
            case .neutral: return DesignSystem.Colors.eliteGold      // Default to Elite Gold
            }
        }
        
        var backgroundColor: LinearGradient {
            switch self {
            case .morning: return DesignSystem.Colors.morningGradient
            case .evening: return DesignSystem.Colors.eveningGradient
            case .neutral: return DesignSystem.Colors.neutralGradient
            }
        }
        
        var cardBackgroundColor: Color {
            switch self {
            case .morning: return DesignSystem.Colors.cardBackground    // Theme-aware card background
            case .evening: return DesignSystem.Colors.cardBackground    // Theme-aware card background
            case .neutral: return DesignSystem.Colors.cardBackground    // Theme-aware card background
            }
        }
        
        /// Elite performance accent for special states
        var eliteAccent: Color {
            switch self {
            case .morning: return DesignSystem.Colors.eliteGold
            case .evening: return DesignSystem.Colors.championBlue
            case .neutral: return DesignSystem.Colors.eliteGold
            }
        }
        
        /// Success color for achievements
        var successColor: Color {
            return DesignSystem.Colors.powerGreen
        }
    }
}

// MARK: - Premium Components

/// Premium elevated card with time-based theming
struct PremiumCard<Content: View>: View {
    let content: Content
    let timeContext: DesignSystem.TimeContext
    let padding: CGFloat
    let showsBorder: Bool
    
    init(
        timeContext: DesignSystem.TimeContext = .neutral,
        padding: CGFloat = DesignSystem.Spacing.cardPadding,
        showsBorder: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.timeContext = timeContext
        self.padding = padding
        self.showsBorder = showsBorder
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(timeContext.cardBackgroundColor)
            .cornerRadius(DesignSystem.CornerRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .stroke(showsBorder ? DesignSystem.Colors.border : .clear, lineWidth: 1)
            )
    }
}

/// Premium section header with time-based theming
struct PremiumSectionHeader: View {
    let title: String
    let subtitle: String?
    let timeContext: DesignSystem.TimeContext
    
    init(
        _ title: String,
        subtitle: String? = nil,
        timeContext: DesignSystem.TimeContext = .neutral
    ) {
        self.title = title
        self.subtitle = subtitle
        self.timeContext = timeContext
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(title)
                .font(DesignSystem.Typography.journalTitleSafe)
                .foregroundColor(timeContext.primaryColor)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(DesignSystem.Typography.bodyLargeSafe)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .lineSpacing(DesignSystem.Spacing.lineSpacingRelaxed)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Premium progress ring with gentle animations
struct PremiumProgressRing: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let timeContext: DesignSystem.TimeContext
    
    init(
        progress: Double,
        size: CGFloat = 80,
        lineWidth: CGFloat = 4,
        timeContext: DesignSystem.TimeContext = .neutral
    ) {
        self.progress = progress
        self.size = size
        self.lineWidth = lineWidth
        self.timeContext = timeContext
    }
    
    var body: some View {
        ZStack {
            // Background ring - very subtle
            Circle()
                .stroke(DesignSystem.Colors.divider, lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress ring with time-based color
            Circle()
                .trim(from: 0, to: progress)
                .stroke(timeContext.primaryColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(DesignSystem.Animation.progress, value: progress)
            
            // Progress text
            VStack(spacing: 2) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size * 0.18, weight: .medium, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.primaryText)
            }
        }
    }
}

/// Premium primary button with time-based theming
struct PremiumPrimaryButton: View {
    let title: String
    let isLoading: Bool
    let isDisabled: Bool
    let timeContext: DesignSystem.TimeContext
    let action: () -> Void
    
    init(
        _ title: String,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        timeContext: DesignSystem.TimeContext = .neutral,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.timeContext = timeContext
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.invertedText))
                        .scaleEffect(0.8)
                }
                
                Text(isLoading ? "Loading..." : title)
                    .font(DesignSystem.Typography.buttonLargeSafe)
            }
            .foregroundColor(DesignSystem.Colors.invertedText)
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.Spacing.preferredTouchTarget)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .fill(isDisabled ? DesignSystem.Colors.tertiaryText : timeContext.primaryColor)
            )
            .shadow(
                color: isDisabled ? .clear : DesignSystem.Shadow.subtle.color,
                radius: isDisabled ? 0 : DesignSystem.Shadow.subtle.radius,
                x: isDisabled ? 0 : DesignSystem.Shadow.subtle.x,
                y: isDisabled ? 0 : DesignSystem.Shadow.subtle.y
            )
        }
        .disabled(isDisabled || isLoading)
        .animation(DesignSystem.Animation.quick, value: isDisabled)
        .animation(DesignSystem.Animation.quick, value: isLoading)
    }
}

/// Premium secondary button
struct PremiumSecondaryButton: View {
    let title: String
    let isDisabled: Bool
    let timeContext: DesignSystem.TimeContext
    let action: () -> Void
    
    init(
        _ title: String,
        isDisabled: Bool = false,
        timeContext: DesignSystem.TimeContext = .neutral,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isDisabled = isDisabled
        self.timeContext = timeContext
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.buttonLargeSafe)
                .foregroundColor(isDisabled ? DesignSystem.Colors.tertiaryText : timeContext.primaryColor)
                .frame(maxWidth: .infinity)
                .frame(height: DesignSystem.Spacing.preferredTouchTarget)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                        .stroke(isDisabled ? DesignSystem.Colors.tertiaryText : timeContext.primaryColor, lineWidth: 1.5)
                        .background(DesignSystem.Colors.cardBackground)
                )
        }
        .disabled(isDisabled)
        .animation(DesignSystem.Animation.quick, value: isDisabled)
    }
}

/// Premium quote display with Georgia italic typography
struct PremiumQuoteDisplay: View {
    let quote: String
    let attribution: String?
    let timeContext: DesignSystem.TimeContext
    
    init(quote: String, attribution: String? = nil, timeContext: DesignSystem.TimeContext = .neutral) {
        self.quote = quote
        self.attribution = attribution
        self.timeContext = timeContext
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("\"\(quote)\"")
                .font(DesignSystem.Typography.quoteTextSafe)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .lineSpacing(DesignSystem.Spacing.lineSpacingRelaxed)
                .fixedSize(horizontal: false, vertical: true)
            
            if let attribution = attribution {
                Text("— \(attribution)")
                    .font(Font.system(size: 14, weight: .regular, design: .serif).italic())
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(timeContext.cardBackgroundColor.opacity(0.5))
        .cornerRadius(DesignSystem.CornerRadius.large)
        .shadow(
            color: DesignSystem.Shadow.subtle.color,
            radius: DesignSystem.Shadow.subtle.radius,
            x: DesignSystem.Shadow.subtle.x,
            y: DesignSystem.Shadow.subtle.y
        )
    }
}

// MARK: - Premium Input Components

struct PremiumTextField: View {
    private let label: String?
    private let placeholder: String
    @Binding private var text: String
    private let timeContext: DesignSystem.TimeContext
    private let isSecure: Bool
    private let contentFont: Font
    private let accessibilityHint: String?
#if canImport(UIKit)
    private let keyboardType: UIKeyboardType
    private let textContentType: UITextContentType?
#endif
    #if canImport(UIKit)
    private let autocapitalization: TextInputAutocapitalization
    #endif
    private let disableAutocorrection: Bool
    private let submitLabel: SubmitLabel
    private let onSubmit: (() -> Void)?
    @FocusState private var isFocused: Bool
    
    private var borderColor: Color {
        isFocused ? timeContext.primaryColor : DesignSystem.Colors.border
    }
    
#if canImport(UIKit)
    init(
        _ label: String? = nil,
        placeholder: String,
        text: Binding<String>,
        timeContext: DesignSystem.TimeContext = .neutral,
        isSecure: Bool = false,
        contentFont: Font = DesignSystem.Typography.bodyLargeSafe,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        autocapitalization: TextInputAutocapitalization = .sentences,
        disableAutocorrection: Bool = false,
        submitLabel: SubmitLabel = .done,
        onSubmit: (() -> Void)? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.timeContext = timeContext
        self.isSecure = isSecure
        self.contentFont = contentFont
        self.accessibilityHint = nil
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.autocapitalization = autocapitalization
        self.disableAutocorrection = disableAutocorrection
        self.submitLabel = submitLabel
        self.onSubmit = onSubmit
    }
#else
    init(
        _ label: String? = nil,
        placeholder: String,
        text: Binding<String>,
        timeContext: DesignSystem.TimeContext = .neutral,
        isSecure: Bool = false,
        contentFont: Font = DesignSystem.Typography.bodyLargeSafe,
        disableAutocorrection: Bool = false,
        submitLabel: SubmitLabel = .done,
        onSubmit: (() -> Void)? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.timeContext = timeContext
        self.isSecure = isSecure
        self.contentFont = contentFont
        self.accessibilityHint = nil
        self.disableAutocorrection = disableAutocorrection
        self.submitLabel = submitLabel
        self.onSubmit = onSubmit
    }
#endif
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            if let label = label {
                Text(label)
                    .font(DesignSystem.Typography.buttonMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            inputField
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .frame(minHeight: DesignSystem.Spacing.preferredTouchTarget)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.input)
                        .fill(DesignSystem.Colors.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.input)
                        .stroke(borderColor, lineWidth: 1.5)
                )
                .animation(DesignSystem.Animation.quick, value: isFocused)
                .accessibilityLabel(label ?? placeholder)
                .accessibilityHint(accessibilityHint ?? "")
        }
    }
    
    @ViewBuilder
    private var inputField: some View {
        if isSecure {
            SecureField(placeholder, text: $text)
                .focused($isFocused)
                #if canImport(UIKit)
                .textInputAutocapitalization(autocapitalization)
                #endif
                .autocorrectionDisabled(disableAutocorrection)
                .submitLabel(submitLabel)
                .onSubmit { onSubmit?() }
#if canImport(UIKit)
                .textContentType(textContentType)
#endif
        } else {
            TextField(placeholder, text: $text)
                .focused($isFocused)
                #if canImport(UIKit)
                .textInputAutocapitalization(autocapitalization)
                #endif
                .autocorrectionDisabled(disableAutocorrection)
                .submitLabel(submitLabel)
                .onSubmit { onSubmit?() }
#if canImport(UIKit)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
#endif
                .font(contentFont)
        }
    }
}

struct PremiumTextEditor: View {
    private let label: String?
    private let placeholder: String
    @Binding private var text: String
    private let timeContext: DesignSystem.TimeContext
    private let minHeight: CGFloat
    private let contentFont: Font
    private let accessibilityHint: String?
    private let onChange: ((String) -> Void)?
    @FocusState private var isFocused: Bool
    
    private var borderColor: Color {
        isFocused ? timeContext.primaryColor : DesignSystem.Colors.border
    }
    
    init(
        _ label: String? = nil,
        placeholder: String,
        text: Binding<String>,
        timeContext: DesignSystem.TimeContext = .neutral,
        minHeight: CGFloat = 150,
        contentFont: Font = DesignSystem.Typography.journalTextSafe,
        accessibilityHint: String? = nil,
        onChange: ((String) -> Void)? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.timeContext = timeContext
        self.minHeight = minHeight
        self.contentFont = contentFont
        self.accessibilityHint = accessibilityHint
        self.onChange = onChange
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            if let label = label {
                Text(label)
                    .font(DesignSystem.Typography.buttonMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(contentFont)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .accessibilityHidden(true)
                }
                TextEditor(text: $text)
                    .focused($isFocused)
                    .font(contentFont)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .padding(.horizontal, DesignSystem.Spacing.md - 2)
                    .padding(.vertical, DesignSystem.Spacing.sm - 2)
                    .frame(minHeight: minHeight)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .onChange(of: text) { _, newValue in
                        onChange?(newValue)
                    }
            }
            .frame(minHeight: max(minHeight, DesignSystem.Spacing.preferredTouchTarget))
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.input)
                    .fill(DesignSystem.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.input)
                    .stroke(borderColor, lineWidth: 1.5)
            )
            .animation(DesignSystem.Animation.quick, value: isFocused)
            .accessibilityLabel(label ?? placeholder)
            .accessibilityHint(accessibilityHint ?? "")
        }
    }
}

// MARK: - Elite Performance Extensions

extension Color {
    /// Creates a color that adapts to light and dark mode
    /// - Parameters:
    ///   - light: Color for light mode
    ///   - dark: Color for dark mode
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self = Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #else
        self = light
        #endif
    }
}

extension View {
    func premiumCard(
        timeContext: DesignSystem.TimeContext = .neutral,
        padding: CGFloat = DesignSystem.Spacing.cardPadding,
        showsBorder: Bool = true
    ) -> some View {
        self
            .padding(padding)
            .background(timeContext.cardBackgroundColor)
            .cornerRadius(DesignSystem.CornerRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .stroke(showsBorder ? DesignSystem.Colors.border : .clear, lineWidth: 1)
            )
    }
    
    func premiumBackground(_ timeContext: DesignSystem.TimeContext = .neutral) -> some View {
        self.background(timeContext.backgroundColor)
    }
    
    /// Elite performance background with theme awareness
    func eliteBackground(_ timeContext: DesignSystem.TimeContext = .neutral) -> some View {
        self.background(
            timeContext.backgroundColor
        )
    }
    
    /// Premium background gradient with safe area coverage
    func premiumBackgroundGradient(_ timeContext: DesignSystem.TimeContext) -> some View {
        self.background(
            timeContext.backgroundColor
                .ignoresSafeArea()
        )
    }
}





// MARK: - Premium Component Extensions



// MARK: - Elite Performance Context Helpers

extension DesignSystem.TimeContext {
    static func current() -> DesignSystem.TimeContext {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return .morning   // 5 AM - 12 PM (Elite Gold energy)
        case 17..<22: return .evening  // 5 PM - 10 PM (Champion Blue reflection)
        default: return .neutral       // Rest of day (Elite Gold default)
        }
    }
    
    /// Returns appropriate color for current training environment
    static func trainingEnvironment() -> DesignSystem.TimeContext {
        // Could be enhanced with location/brightness detection
        return current()
    }
}

// MARK: - Elite Performance Color Helpers

extension DesignSystem.Colors {
    /// Returns an accent color that maintains sufficient contrast on the given surface.
    /// For light surfaces, use a darker elite gold variant to meet contrast; for dark, keep elite gold.
    static func accentOnSurface(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .light:
            // Darker gold variant for better contrast on light backgrounds
            return Color(red: 0.80, green: 0.57, blue: 0.00)
        default:
            return eliteGold
        }
    }
    /// Returns the appropriate success color based on context
    static func successColor(for achievement: AchievementType) -> Color {
        switch achievement {
        case .personalRecord: return eliteGold
        case .goalCompleted: return powerGreen
        case .streakMaintained: return championBlue
        }
    }
    
    /// Returns theme-appropriate text color with high contrast
    static func textColor(for level: TextLevel) -> Color {
        switch level {
        case .primary: return performancePrimaryText
        case .secondary: return performanceSecondaryText
        case .tertiary: return performanceTertiaryText
        }
    }
}

// MARK: - Supporting Types

enum AchievementType {
    case personalRecord
    case goalCompleted
    case streakMaintained
}

enum TextLevel {
    case primary
    case secondary
    case tertiary
}


