//
//  WhoopRecoveryCard.swift
//  Your Daily Dose
//
//  Displays Whoop recovery score with zone coloring and secondary metrics.
//

import SwiftUI

struct WhoopRecoveryCard: View {
    let data: WhoopDailyData
    let timeContext: DesignSystem.TimeContext
    let onTap: () -> Void

    @AppStorage("whoop_show_recovery") private var showRecovery = true
    @AppStorage("whoop_show_sleep") private var showSleep = true
    @AppStorage("whoop_show_hr") private var showHeartRate = true

    var body: some View {
        PremiumCard(timeContext: timeContext) {
            VStack(spacing: DesignSystem.Spacing.md) {
                // Header
                HStack {
                    Text("Recovery")
                        .font(DesignSystem.Typography.headlineMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    Spacer()
                    Text("WHOOP")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }

                if showRecovery, let score = data.recoveryScore {
                    let zone = data.recoveryZone ?? .init(score: score)
                    HStack(spacing: DesignSystem.Spacing.lg) {
                        RecoveryCircle(score: score, zone: zone)
                            .frame(width: 80, height: 80)

                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text(zone.displayName)
                                .font(DesignSystem.Typography.bodyLarge)
                                .foregroundColor(zone.color)

                            Text(zone.recommendation)
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .lineLimit(2)
                        }
                    }
                }

                // Secondary metrics
                HStack(spacing: DesignSystem.Spacing.lg) {
                    if showSleep, let sleep = data.sleepPerformance {
                        MetricBadge(icon: "moon.fill", value: "\(Int(sleep))%", label: "Sleep")
                    }
                    if showHeartRate, let hrv = data.hrv {
                        MetricBadge(icon: "waveform.path.ecg", value: "\(Int(hrv))ms", label: "HRV")
                    }
                    if showHeartRate, let hr = data.restingHr {
                        MetricBadge(icon: "heart.fill", value: "\(hr)bpm", label: "HR")
                    }
                    if let strain = data.strainScore {
                        MetricBadge(icon: "flame.fill", value: String(format: "%.1f", strain), label: "Strain")
                    }
                }

                // Footer
                HStack {
                    Text("Tap for sleep details")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
            }
        }
        .onTapGesture { onTap() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(recoveryAccessibilityLabel)
        .accessibilityHint("Tap for sleep details")
        .accessibilityAddTraits(.isButton)
    }

    private var recoveryAccessibilityLabel: String {
        var parts: [String] = []
        if let score = data.recoveryScore {
            let zone = data.recoveryZone ?? .init(score: score)
            parts.append("Whoop recovery \(Int(score)) percent, \(zone.displayName)")
        }
        if let sleep = data.sleepPerformance {
            parts.append("Sleep \(Int(sleep)) percent")
        }
        if let hrv = data.hrv {
            parts.append("HRV \(Int(hrv)) milliseconds")
        }
        if let hr = data.restingHr {
            parts.append("Resting heart rate \(hr) beats per minute")
        }
        return parts.joined(separator: ". ")
    }
}

// MARK: - Recovery Circle

struct RecoveryCircle: View {
    let score: Double
    let zone: WhoopDailyData.RecoveryZone

    @State private var animatedProgress: Double = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(zone.color.opacity(0.2), lineWidth: 8)
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(zone.color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(score))%")
                .font(DesignSystem.Typography.headlineLarge)
                .foregroundColor(zone.color)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .onAppear {
            if reduceMotion {
                animatedProgress = score / 100
            } else {
                withAnimation(.easeOut(duration: 0.8)) {
                    animatedProgress = score / 100
                }
            }
        }
    }
}

// MARK: - Metric Badge

struct MetricBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            Text(value)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            Text(label)
                .font(DesignSystem.Typography.metadata)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }
}
