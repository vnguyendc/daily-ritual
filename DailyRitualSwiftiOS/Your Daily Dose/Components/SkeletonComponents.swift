//
//  SkeletonComponents.swift
//  Your Daily Dose
//
//  Skeleton loading and enhanced empty state components.
//

import SwiftUI

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    if !reduceMotion {
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .white.opacity(0.25), location: 0.4),
                                .init(color: .white.opacity(0.35), location: 0.5),
                                .init(color: .white.opacity(0.25), location: 0.6),
                                .init(color: .clear, location: 1)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 2)
                        .offset(x: phase * geo.size.width * 2)
                        .onAppear {
                            withAnimation(
                                .linear(duration: 1.4)
                                .repeatForever(autoreverses: false)
                            ) {
                                phase = 1
                            }
                        }
                    }
                }
                .clipped()
            )
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Today Card

struct SkeletonTodayCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(DesignSystem.Colors.cardBackground)
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignSystem.Colors.cardBackground)
                        .frame(width: 140, height: 14)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignSystem.Colors.cardBackground)
                        .frame(width: 90, height: 10)
                }
                Spacer()
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignSystem.Colors.cardBackground)
                    .frame(width: 60, height: 24)
            }
            // Body lines
            RoundedRectangle(cornerRadius: 4)
                .fill(DesignSystem.Colors.cardBackground)
                .frame(maxWidth: .infinity)
                .frame(height: 10)
            RoundedRectangle(cornerRadius: 4)
                .fill(DesignSystem.Colors.cardBackground)
                .frame(width: 200, height: 10)
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(DesignSystem.Colors.secondaryBackground)
        )
        .shimmer()
    }
}

// MARK: - Skeleton Insight Card

struct SkeletonInsightCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.Colors.cardBackground)
                    .frame(width: 120, height: 12)
                Spacer()
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignSystem.Colors.cardBackground)
                    .frame(width: 50, height: 20)
            }
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.Colors.cardBackground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 12)
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.Colors.cardBackground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 12)
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.Colors.cardBackground)
                    .frame(width: 180, height: 12)
            }
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.Colors.cardBackground)
                    .frame(width: 80, height: 10)
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.Colors.cardBackground)
                    .frame(width: 40, height: 10)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(DesignSystem.Colors.secondaryBackground)
        )
        .shimmer()
    }
}

// MARK: - Skeleton Training Card

struct SkeletonTrainingCard: View {
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 25)
                .fill(DesignSystem.Colors.cardBackground)
                .frame(width: 50, height: 50)
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.Colors.cardBackground)
                    .frame(width: 130, height: 14)
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.Colors.cardBackground)
                    .frame(width: 90, height: 10)
            }
            Spacer()
            RoundedRectangle(cornerRadius: 8)
                .fill(DesignSystem.Colors.cardBackground)
                .frame(width: 56, height: 24)
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(DesignSystem.Colors.secondaryBackground)
        )
        .shimmer()
    }
}

// MARK: - Skeleton Stat Item

struct SkeletonStatItem: View {
    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4)
                .fill(DesignSystem.Colors.cardBackground)
                .frame(width: 24, height: 24)
            RoundedRectangle(cornerRadius: 4)
                .fill(DesignSystem.Colors.cardBackground)
                .frame(width: 40, height: 22)
            RoundedRectangle(cornerRadius: 4)
                .fill(DesignSystem.Colors.cardBackground)
                .frame(width: 60, height: 10)
        }
        .frame(maxWidth: .infinity)
        .shimmer()
    }
}

// MARK: - Welcome Ritual Card

struct WelcomeRitualCard: View {
    @AppStorage("hasSeenWelcomeCard") private var hasSeenWelcomeCard = false
    @State private var isVisible = false
    private var timeContext: DesignSystem.TimeContext { DesignSystem.TimeContext.current() }

    var body: some View {
        if !hasSeenWelcomeCard {
            VStack(spacing: DesignSystem.Spacing.md) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.eliteGold.opacity(0.15))
                            .frame(width: 52, height: 52)
                        Image(systemName: "sun.horizon.fill")
                            .font(.system(size: 26))
                            .foregroundColor(DesignSystem.Colors.eliteGold)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome to your ritual.")
                            .font(DesignSystem.Typography.headlineSmall)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        Text("Start with your morning practice.")
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    Spacer()
                    Button {
                        withAnimation(DesignSystem.Animation.gentle) {
                            hasSeenWelcomeCard = true
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                    }
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .fill(DesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                            .stroke(DesignSystem.Colors.eliteGold.opacity(0.3), lineWidth: 1)
                    )
            )
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 16)
            .onAppear {
                withAnimation(DesignSystem.Animation.gentle.delay(0.3)) {
                    isVisible = true
                }
            }
        }
    }
}

// MARK: - Insights Empty State

struct InsightsEmptyStateView: View {
    private var timeContext: DesignSystem.TimeContext { .evening }
    private let entriesNeeded = 3

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Illustration-style icon composition
            ZStack {
                Circle()
                    .fill(timeContext.primaryColor.opacity(0.08))
                    .frame(width: 100, height: 100)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 48))
                    .foregroundColor(timeContext.primaryColor.opacity(0.7))
                Image(systemName: "sparkles")
                    .font(.system(size: 18))
                    .foregroundColor(DesignSystem.Colors.eliteGold)
                    .offset(x: 32, y: -32)
            }

            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("No Insights Yet")
                    .font(DesignSystem.Typography.headlineMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)

                Text("Complete a few rituals to unlock AI insights")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            // Progress indicator dots
            VStack(spacing: DesignSystem.Spacing.sm) {
                HStack(spacing: 6) {
                    ForEach(0..<entriesNeeded, id: \.self) { _ in
                        Circle()
                            .fill(DesignSystem.Colors.divider)
                            .frame(width: 8, height: 8)
                    }
                }
                Text("\(entriesNeeded) more entries needed")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xxl)
    }
}

// MARK: - Training Empty State

struct TrainingEmptyStateView: View {
    let onAddSession: () -> Void
    private var timeContext: DesignSystem.TimeContext { DesignSystem.TimeContext.current() }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Illustration-style icon with + badge
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(timeContext.primaryColor.opacity(0.08))
                    .frame(width: 100, height: 100)
                Image(systemName: "figure.run")
                    .font(.system(size: 48))
                    .foregroundColor(timeContext.primaryColor.opacity(0.7))
                ZStack {
                    Circle()
                        .fill(timeContext.primaryColor)
                        .frame(width: 28, height: 28)
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: 8, y: -8)
            }

            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("Plan your first session")
                    .font(DesignSystem.Typography.headlineMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)

                Text("Add a training session to get started")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Button(action: onAddSession) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "plus")
                    Text("Add Session")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
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

struct MealsEmptyStateView: View {
    let onLogMeal: () -> Void
    private var timeContext: DesignSystem.TimeContext { DesignSystem.TimeContext.current() }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(timeContext.primaryColor.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "camera.fill")
                    .font(.system(size: 34))
                    .foregroundColor(timeContext.primaryColor.opacity(0.7))
            }

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("No meals logged today")
                    .font(DesignSystem.Typography.headlineSmall)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                Text("Snap a photo of your meal")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }

            Button(action: onLogMeal) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "camera")
                    Text("Log Meal")
                }
                .font(DesignSystem.Typography.buttonSmall)
                .foregroundColor(timeContext.primaryColor)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(
                    Capsule()
                        .stroke(timeContext.primaryColor.opacity(0.5), lineWidth: 1.5)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.lg)
    }
}
