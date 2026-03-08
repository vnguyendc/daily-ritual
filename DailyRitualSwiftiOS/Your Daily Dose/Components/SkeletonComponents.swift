//
//  SkeletonComponents.swift
//  Your Daily Dose
//
//  Shimmer loading effect, skeleton cards, and enhanced empty states
//

import SwiftUI

// MARK: - Shimmer Modifier

/// A view modifier that applies a sweeping highlight gradient to simulate shimmer loading.
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1.5
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .white.opacity(0.28), location: 0.35),
                        .init(color: .white.opacity(0.42), location: 0.5),
                        .init(color: .white.opacity(0.28), location: 0.65),
                        .init(color: .clear, location: 1.0)
                    ]),
                    startPoint: UnitPoint(x: phase, y: 0.5),
                    endPoint: UnitPoint(x: phase + 1.0, y: 0.5)
                )
                .allowsHitTesting(false)
            )
            .clipped()
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}

extension View {
    /// Applies a sweeping shimmer highlight effect, typically used during skeleton loading.
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Placeholder Shapes

/// A single gray placeholder rectangle used inside skeleton cards.
private struct SkeletonRect: View {
    let height: CGFloat
    let cornerRadius: CGFloat
    let maxWidth: CGFloat?

    init(height: CGFloat = 14, cornerRadius: CGFloat = DesignSystem.CornerRadius.small, maxWidth: CGFloat? = nil) {
        self.height = height
        self.cornerRadius = cornerRadius
        self.maxWidth = maxWidth
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(DesignSystem.Colors.border.opacity(0.35))
            .frame(maxWidth: maxWidth.map { CGFloat($0) } ?? .infinity)
            .frame(height: height)
    }
}

// MARK: - Skeleton Today Card

/// Mimics a ritual/activity card while data is loading.
struct SkeletonTodayCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Header row: icon + title/subtitle + badge
            HStack(spacing: DesignSystem.Spacing.md) {
                Circle()
                    .fill(DesignSystem.Colors.border.opacity(0.35))
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 8) {
                    SkeletonRect(height: 16, maxWidth: 140)
                    SkeletonRect(height: 11, maxWidth: 90)
                }

                Spacer()

                RoundedRectangle(cornerRadius: 12)
                    .fill(DesignSystem.Colors.border.opacity(0.28))
                    .frame(width: 72, height: 26)
            }

            // Content lines
            VStack(alignment: .leading, spacing: 7) {
                SkeletonRect(height: 11)
                SkeletonRect(height: 11, maxWidth: 240)
            }

            // Footer row
            HStack {
                SkeletonRect(height: 9, maxWidth: 64)
                Spacer()
                SkeletonRect(height: 9, maxWidth: 44)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .shimmer()
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
    }
}

// MARK: - Skeleton Insight Card

/// Mimics an AI insight card while data is loading.
struct SkeletonInsightCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Header: icon + type label + unread badge
            HStack {
                Circle()
                    .fill(DesignSystem.Colors.border.opacity(0.35))
                    .frame(width: 28, height: 28)

                SkeletonRect(height: 13, maxWidth: 110)

                Spacer()

                RoundedRectangle(cornerRadius: 10)
                    .fill(DesignSystem.Colors.border.opacity(0.28))
                    .frame(width: 58, height: 20)
            }

            // Summary line
            SkeletonRect(height: 11, maxWidth: 200)

            // Multi-line content
            VStack(alignment: .leading, spacing: 6) {
                SkeletonRect(height: 12)
                SkeletonRect(height: 12)
                SkeletonRect(height: 12, maxWidth: 220)
            }

            // Footer: date + confidence
            HStack {
                SkeletonRect(height: 9, maxWidth: 80)
                Spacer()
                SkeletonRect(height: 9, maxWidth: 36)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .shimmer()
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
    }
}

// MARK: - Skeleton Training Card

/// Mimics a training session card while data is loading.
struct SkeletonTrainingCard: View {
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Circle()
                .fill(DesignSystem.Colors.border.opacity(0.35))
                .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    SkeletonRect(height: 14, maxWidth: 100)
                    Spacer()
                    RoundedRectangle(cornerRadius: 10)
                        .fill(DesignSystem.Colors.border.opacity(0.28))
                        .frame(width: 58, height: 20)
                }

                HStack(spacing: DesignSystem.Spacing.md) {
                    SkeletonRect(height: 10, maxWidth: 56)
                    SkeletonRect(height: 10, maxWidth: 56)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
        .shimmer()
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
    }
}

// MARK: - Skeleton Stat Item

/// Mimics a single profile stat cell while data is loading.
struct SkeletonStatItem: View {
    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(DesignSystem.Colors.border.opacity(0.35))
                .frame(width: 22, height: 22)
                .shimmer()

            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .fill(DesignSystem.Colors.border.opacity(0.35))
                .frame(width: 44, height: 26)
                .shimmer()

            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .fill(DesignSystem.Colors.border.opacity(0.25))
                .frame(width: 56, height: 10)
                .shimmer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Welcome Ritual Card (First-time user delight)

/// Displayed on the very first app open after onboarding with an animated entrance.
struct WelcomeRitualCard: View {
    let timeContext: DesignSystem.TimeContext
    let onBegin: () -> Void

    @State private var isVisible = false

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Layered icon composition
            ZStack {
                Circle()
                    .fill(timeContext.primaryColor.opacity(0.10))
                    .frame(width: 80, height: 80)

                Image(systemName: "sun.horizon.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignSystem.Colors.eliteGold, timeContext.primaryColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("Welcome to your ritual.")
                    .font(DesignSystem.Typography.headlineMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.center)

                Text("Start with your morning practice to set the tone for a powerful day.")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Button(action: onBegin) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Text("Begin Morning Ritual")
                    Image(systemName: "arrow.right")
                }
                .font(DesignSystem.Typography.buttonMedium)
                .foregroundColor(DesignSystem.Colors.invertedText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                        .fill(timeContext.primaryColor)
                )
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(DesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                        .stroke(timeContext.primaryColor.opacity(0.18), lineWidth: 1)
                )
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 28)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.78).delay(0.25)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Enhanced Insights Empty State

/// Shows when the user has no insights yet, with a progress indicator toward earning them.
struct InsightsEmptyStateView: View {
    let timeContext: DesignSystem.TimeContext
    let entriesCompleted: Int
    let entriesNeeded: Int

    private var remaining: Int { max(0, entriesNeeded - entriesCompleted) }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Icon composition with sparkle accent
            ZStack {
                Circle()
                    .fill(timeContext.primaryColor.opacity(0.08))
                    .frame(width: 100, height: 100)

                ZStack(alignment: .bottomTrailing) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 50))
                        .foregroundColor(timeContext.primaryColor.opacity(0.65))

                    Image(systemName: "sparkles")
                        .font(.system(size: 22))
                        .foregroundColor(DesignSystem.Colors.eliteGold)
                        .offset(x: 6, y: 6)
                }
            }

            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("No Insights Yet")
                    .font(DesignSystem.Typography.headlineMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)

                Text("Complete a few rituals to unlock AI insights tailored to your performance.")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            // Progress toward unlocking insights
            if remaining > 0 {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        ForEach(0..<entriesNeeded, id: \.self) { index in
                            Circle()
                                .fill(index < entriesCompleted
                                    ? timeContext.primaryColor
                                    : DesignSystem.Colors.border.opacity(0.4))
                                .frame(width: 11, height: 11)
                                .animation(DesignSystem.Animation.spring, value: entriesCompleted)
                        }
                    }

                    Text("\(remaining) more entr\(remaining == 1 ? "y" : "ies") needed to unlock insights")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
                .padding(DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                        .fill(DesignSystem.Colors.cardBackground)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xxl)
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }
}

// MARK: - Enhanced Training Empty State

/// Shows when no training sessions are scheduled, with a prominent CTA to add one.
struct TrainingEmptyStateView: View {
    let timeContext: DesignSystem.TimeContext
    let onAddSession: () -> Void

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Icon composition with plus badge
            ZStack {
                Circle()
                    .fill(timeContext.primaryColor.opacity(0.08))
                    .frame(width: 92, height: 92)

                ZStack(alignment: .bottomTrailing) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 44))
                        .foregroundColor(timeContext.primaryColor.opacity(0.7))

                    ZStack {
                        Circle()
                            .fill(timeContext.primaryColor)
                            .frame(width: 26, height: 26)
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.invertedText)
                    }
                    .offset(x: 4, y: 4)
                }
            }

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("Plan your first session")
                    .font(DesignSystem.Typography.headlineMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)

                Text("No sessions scheduled for this day")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Button(action: onAddSession) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Training Session")
                }
                .font(DesignSystem.Typography.buttonMedium)
                .foregroundColor(DesignSystem.Colors.invertedText)
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(
                    Capsule().fill(timeContext.primaryColor)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xxl)
    }
}

// MARK: - Meals Empty State

/// Shows when no meals have been logged today, with a camera CTA.
struct MealsEmptyStateView: View {
    let timeContext: DesignSystem.TimeContext
    let onLogMeal: () -> Void

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(timeContext.primaryColor.opacity(0.08))
                    .frame(width: 80, height: 80)

                Image(systemName: "camera.fill")
                    .font(.system(size: 36))
                    .foregroundColor(timeContext.primaryColor.opacity(0.7))
            }

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("No meals logged today")
                    .font(DesignSystem.Typography.headlineSmall)
                    .foregroundColor(DesignSystem.Colors.primaryText)

                Text("Snap a photo of your meal to track nutrition")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Button(action: onLogMeal) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "camera.fill")
                    Text("Log a Meal")
                }
                .font(DesignSystem.Typography.buttonMedium)
                .foregroundColor(timeContext.primaryColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xl)
    }
}

// MARK: - Preview

#Preview("Skeleton Cards") {
    ScrollView {
        VStack(spacing: 16) {
            SkeletonTodayCard()
            SkeletonTodayCard()
            SkeletonInsightCard()
            SkeletonTrainingCard()

            HStack(spacing: 0) {
                SkeletonStatItem()
                SkeletonStatItem()
                SkeletonStatItem()
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(DesignSystem.Colors.cardBackground))
        }
        .padding()
    }
    .background(DesignSystem.Colors.background)
}

#Preview("Empty States") {
    ScrollView {
        VStack(spacing: 32) {
            WelcomeRitualCard(timeContext: .morning, onBegin: {})

            InsightsEmptyStateView(timeContext: .evening, entriesCompleted: 1, entriesNeeded: 3)

            TrainingEmptyStateView(timeContext: .morning, onAddSession: {})

            MealsEmptyStateView(timeContext: .morning, onLogMeal: {})
        }
        .padding()
    }
    .background(DesignSystem.Colors.background)
}
