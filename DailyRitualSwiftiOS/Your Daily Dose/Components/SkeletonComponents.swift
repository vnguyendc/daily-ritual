//
//  SkeletonComponents.swift
//  Your Daily Dose
//
//  Skeleton loading components and enhanced empty states
//

import SwiftUI

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if !reduceMotion {
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.15), .white.opacity(0.25), .white.opacity(0.15), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .offset(x: isAnimating ? 400 : -400)
                        .animation(
                            .linear(duration: 1.5).repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                        .onAppear { isAnimating = true }
                    }
                }
            )
            .clipped()
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Rectangle (internal helper)

private struct SkeletonRect: View {
    let height: CGFloat
    let width: CGFloat?
    let cornerRadius: CGFloat

    init(height: CGFloat = 16, width: CGFloat? = nil, cornerRadius: CGFloat = DesignSystem.CornerRadius.small) {
        self.height = height
        self.width = width
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(DesignSystem.Colors.border.opacity(0.5))
            .frame(width: width, height: height)
    }
}

// MARK: - Skeleton Today Card

struct SkeletonTodayCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.md) {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(DesignSystem.Colors.border.opacity(0.5))
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 6) {
                    SkeletonRect(height: 16, width: 140)
                    SkeletonRect(height: 12, width: 100)
                }

                Spacer()
            }

            SkeletonRect(height: 8, cornerRadius: 4)

            HStack {
                SkeletonRect(height: 12, width: 80)
                Spacer()
                SkeletonRect(height: 28, width: 90, cornerRadius: 14)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .shimmer()
    }
}

// MARK: - Skeleton Insight Card

struct SkeletonInsightCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                SkeletonRect(height: 16, width: 16, cornerRadius: 4)
                SkeletonRect(height: 14, width: 120)
                Spacer()
                SkeletonRect(height: 22, width: 60, cornerRadius: 11)
            }

            SkeletonRect(height: 13, width: 200)

            VStack(alignment: .leading, spacing: 6) {
                SkeletonRect(height: 14)
                SkeletonRect(height: 14)
                SkeletonRect(height: 14, width: 220)
            }

            HStack {
                SkeletonRect(height: 12, width: 80)
                Spacer()
                SkeletonRect(height: 12, width: 50)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .shimmer()
    }
}

// MARK: - Skeleton Training Card

struct SkeletonTrainingCard: View {
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Circle()
                .fill(DesignSystem.Colors.border.opacity(0.5))
                .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    SkeletonRect(height: 16, width: 120)
                    Spacer()
                    SkeletonRect(height: 22, width: 60, cornerRadius: 11)
                }

                HStack(spacing: DesignSystem.Spacing.md) {
                    SkeletonRect(height: 12, width: 60)
                    SkeletonRect(height: 12, width: 70)
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
    }
}

// MARK: - Skeleton Stat Item

struct SkeletonStatItem: View {
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            RoundedRectangle(cornerRadius: 6)
                .fill(DesignSystem.Colors.border.opacity(0.5))
                .frame(width: 50, height: 28)
                .shimmer()

            RoundedRectangle(cornerRadius: 4)
                .fill(DesignSystem.Colors.border.opacity(0.4))
                .frame(width: 60, height: 12)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Welcome Ritual Card

struct WelcomeRitualCard: View {
    @AppStorage("hasSeenWelcomeCard") private var hasSeenWelcomeCard = false
    @State private var isVisible = false

    private var timeContext: DesignSystem.TimeContext { DesignSystem.TimeContext.current() }

    var body: some View {
        if !hasSeenWelcomeCard {
            HStack(spacing: DesignSystem.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.eliteGold.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 22))
                        .foregroundColor(DesignSystem.Colors.eliteGold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to your ritual.")
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    Text("Start with your morning practice.")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }

                Spacer()

                Button {
                    withAnimation(DesignSystem.Animation.gentle) {
                        hasSeenWelcomeCard = true
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                        .padding(8)
                        .background(Circle().fill(DesignSystem.Colors.border.opacity(0.3)))
                }
                .buttonStyle(.plain)
            }
            .padding(DesignSystem.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .fill(DesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                            .stroke(DesignSystem.Colors.eliteGold.opacity(0.3), lineWidth: 1)
                    )
            )
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
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

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            ZStack {
                Circle()
                    .fill(timeContext.primaryColor.opacity(0.08))
                    .frame(width: 100, height: 100)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 48))
                    .foregroundColor(timeContext.primaryColor.opacity(0.7))

                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
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

            VStack(spacing: DesignSystem.Spacing.sm) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i == 0 ? timeContext.primaryColor : DesignSystem.Colors.border.opacity(0.5))
                            .frame(width: 10, height: 10)
                    }
                }
                Text("3 more entries needed")
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
    let onAddTap: () -> Void
    private var timeContext: DesignSystem.TimeContext { DesignSystem.TimeContext.current() }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(timeContext.primaryColor.opacity(0.08))
                    .frame(width: 90, height: 90)

                Image(systemName: "figure.run")
                    .font(.system(size: 44))
                    .foregroundColor(timeContext.primaryColor.opacity(0.7))

                ZStack {
                    Circle()
                        .fill(timeContext.primaryColor)
                        .frame(width: 26, height: 26)
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: 8, y: 8)
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

            Button(action: onAddTap) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "plus")
                    Text("Add Session")
                    Image(systemName: "arrow.right")
                        .font(.caption)
                }
                .font(DesignSystem.Typography.buttonMedium)
                .foregroundColor(DesignSystem.Colors.invertedText)
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(Capsule().fill(timeContext.primaryColor))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xxl)
    }
}

// MARK: - Meals Empty State

struct MealsEmptyStateView: View {
    let onLogTap: () -> Void
    private var timeContext: DesignSystem.TimeContext { DesignSystem.TimeContext.current() }

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
                Text("No Meals Logged")
                    .font(DesignSystem.Typography.headlineSmall)
                    .foregroundColor(DesignSystem.Colors.primaryText)

                Text("Snap a photo of your meal to log nutrition")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Button(action: onLogTap) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "camera")
                    Text("Log a Meal")
                }
                .font(DesignSystem.Typography.buttonMedium)
                .foregroundColor(timeContext.primaryColor)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xl)
        .padding(.horizontal, DesignSystem.Spacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .fill(DesignSystem.Colors.cardBackground)
        )
    }
}
