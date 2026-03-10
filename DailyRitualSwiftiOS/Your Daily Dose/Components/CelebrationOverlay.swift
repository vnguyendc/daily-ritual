//
//  CelebrationOverlay.swift
//  Your Daily Dose
//
//  Full-screen celebration animation for streak milestones and completions
//  Created by Claude Code on 2/17/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
import AudioToolbox
#endif

struct CelebrationOverlay: View {
    let type: CelebrationType
    let streakCount: Int
    let onDismiss: () -> Void

    @State private var iconScale: CGFloat = 0.3
    @State private var textOpacity: Double = 0
    @State private var backgroundOpacity: Double = 0
    @State private var confettiParticles: [ConfettiParticle] = []
    @State private var dismissed = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    private var milestone: CelebrationMilestone? {
        CelebrationMilestone.milestone(for: streakCount)
    }

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(backgroundOpacity * 0.5)
                .ignoresSafeArea()

            // Confetti layer (disabled when reduceMotion is on)
            if !reduceMotion, milestone != nil {
                ForEach(confettiParticles) { particle in
                    ConfettiPiece(particle: particle)
                }
            }

            // Main content
            VStack(spacing: DesignSystem.Spacing.xl) {
                Spacer()

                // Icon
                Image(systemName: type.icon)
                    .font(.system(size: 80))
                    .foregroundColor(type.color)
                    .scaleEffect(iconScale)

                // Message
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text(type.message)
                        .font(DesignSystem.Typography.displaySmall)
                        .foregroundColor(DesignSystem.Colors.primaryText)

                    if streakCount > 0 {
                        Text("\(streakCount) day streak")
                            .font(DesignSystem.Typography.headlineSmall)
                            .foregroundColor(type.color)
                    }

                    if let milestone = milestone {
                        Text(milestone.message)
                            .font(DesignSystem.Typography.bodyLargeSafe)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.top, DesignSystem.Spacing.xs)
                    }
                }
                .opacity(textOpacity)

                if milestone != nil {
                    ShareLink(
                        item: shareText,
                        label: {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(.white)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .background(
                                Capsule()
                                    .fill(type.color.opacity(0.8))
                            )
                        }
                    )
                    .opacity(textOpacity)
                }

                Spacer()
                Spacer()
            }
            .padding(DesignSystem.Spacing.xl)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(overlayAccessibilityLabel)
        .accessibilityHint("Tap to dismiss")
        .accessibilityAddTraits(.isButton)
        .onAppear {
            animate()
        }
        .onTapGesture {
            guard !dismissed else { return }
            dismissed = true
            onDismiss()
        }
    }

    private var shareText: String {
        let milestoneMsg = milestone?.message ?? ""
        return "I just hit a \(streakCount)-day streak on Daily Ritual! \(milestoneMsg) 🔥"
    }

    private var overlayAccessibilityLabel: String {
        var parts = [type.message]
        if streakCount > 0 {
            parts.append("\(streakCount) day streak")
        }
        if let milestone = milestone {
            parts.append(milestone.message)
        }
        return parts.joined(separator: ". ")
    }

    private func animate() {
        // Haptic — heavier impact for milestones
        if milestone != nil {
            HapticManager.milestone()
        } else {
            HapticManager.success()
        }

        if reduceMotion {
            // Skip animations — jump to final state immediately
            backgroundOpacity = 1
            iconScale = 1.0
            textOpacity = 1
            // Auto-dismiss
            let duration = milestone?.intensity.duration ?? 2.0
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                guard !dismissed else { return }
                dismissed = true
                onDismiss()
            }
            return
        }

        // Background fade in
        withAnimation(.easeIn(duration: 0.2)) {
            backgroundOpacity = 1
        }

        // Icon spring
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            iconScale = 1.1
        }

        // Icon settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                iconScale = 1.0
            }
        }

        // Text fade in
        withAnimation(.easeIn(duration: 0.3).delay(0.3)) {
            textOpacity = 1
        }

        // Confetti for milestones
        if let milestone = milestone {
            spawnConfetti(count: milestone.intensity.confettiCount)
        }

        // Auto-dismiss
        let duration = milestone?.intensity.duration ?? 2.0
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            guard !dismissed else { return }
            dismissed = true
            onDismiss()
        }
    }

    private func spawnConfetti(count: Int) {
        let intensity = milestone?.intensity ?? .standard

        let colors: [Color]
        let maxSize: CGFloat
        switch intensity {
        case .standard:
            colors = [
                DesignSystem.Colors.eliteGold,
                DesignSystem.Colors.championBlue,
                DesignSystem.Colors.powerGreen,
                .white.opacity(0.8)
            ]
            maxSize = 8
        case .enhanced:
            colors = [
                DesignSystem.Colors.eliteGold,
                DesignSystem.Colors.championBlue,
                DesignSystem.Colors.powerGreen,
                .white.opacity(0.8),
                Color.orange,
                Color.pink
            ]
            maxSize = 10
        case .epic:
            colors = [
                DesignSystem.Colors.eliteGold,
                DesignSystem.Colors.championBlue,
                DesignSystem.Colors.powerGreen,
                .white.opacity(0.8),
                Color.orange,
                Color.pink,
                Color.red,
                Color.purple,
                Color.yellow,
                Color.cyan
            ]
            maxSize = 14
        }

        for i in 0..<count {
            let particle = ConfettiParticle(
                id: i,
                x: CGFloat.random(in: 0...1),
                delay: Double.random(in: 0...0.8),
                duration: Double.random(in: 1.5...3.0),
                color: colors.randomElement() ?? .white,
                size: CGFloat.random(in: 4...maxSize),
                rotation: Double.random(in: 0...360)
            )
            confettiParticles.append(particle)
        }
    }
}

// MARK: - Confetti

struct ConfettiParticle: Identifiable {
    let id: Int
    let x: CGFloat
    let delay: Double
    let duration: Double
    let color: Color
    let size: CGFloat
    let rotation: Double
}

struct ConfettiPiece: View {
    let particle: ConfettiParticle
    @State private var offset: CGFloat = -50
    @State private var opacity: Double = 1
    @State private var spin: Double = 0

    var body: some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 1)
                .fill(particle.color)
                .frame(width: particle.size, height: particle.size * 1.5)
                .rotationEffect(.degrees(particle.rotation + spin))
                .offset(
                    x: geo.size.width * particle.x,
                    y: offset
                )
                .opacity(opacity)
                .onAppear {
                    withAnimation(
                        .easeIn(duration: particle.duration)
                        .delay(particle.delay)
                    ) {
                        offset = geo.size.height + 50
                        spin = Double.random(in: 180...720)
                    }
                    withAnimation(
                        .easeIn(duration: 0.5)
                        .delay(particle.delay + particle.duration - 0.5)
                    ) {
                        opacity = 0
                    }
                }
        }
        .allowsHitTesting(false)
    }
}
