//
//  SleepDetailView.swift
//  Your Daily Dose
//
//  Detailed sleep metrics sheet presented from WhoopRecoveryCard tap.
//

import SwiftUI

struct SleepDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let data: WhoopDailyData

    private var timeContext: DesignSystem.TimeContext { .evening }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    sleepSummarySection

                    if let stages = data.sleepStages {
                        sleepStagesSection(stages)
                    }

                    metricsGrid

                    if let score = data.recoveryScore {
                        recoveryAssessment(score: score, zone: data.recoveryZone ?? .init(score: score))
                    }
                }
                .padding(DesignSystem.Spacing.lg)
            }
            .premiumBackgroundGradient(timeContext)
            .navigationTitle("Sleep Details")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(timeContext.primaryColor)
                }
            }
        }
    }

    // MARK: - Sleep Summary

    @ViewBuilder
    private var sleepSummarySection: some View {
        PremiumCard(timeContext: timeContext) {
            VStack(spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundColor(DesignSystem.Colors.championBlue)
                    Text("Last Night's Sleep")
                        .font(DesignSystem.Typography.headlineMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    Spacer()
                }

                HStack(spacing: DesignSystem.Spacing.lg) {
                    if let stages = data.sleepStages {
                        VStack {
                            Text(stages.formattedTotalSleep)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            Text("Total Sleep")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                    if let efficiency = data.sleepEfficiency {
                        VStack {
                            Text("\(Int(efficiency))%")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            Text("Efficiency")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                    if let perf = data.sleepPerformance {
                        VStack {
                            Text("\(Int(perf))%")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            Text("Performance")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Sleep Stages

    @ViewBuilder
    private func sleepStagesSection(_ stages: WhoopDailyData.SleepStages) -> some View {
        PremiumCard(timeContext: timeContext) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Text("Sleep Stages")
                    .font(DesignSystem.Typography.headlineSmall)
                    .foregroundColor(DesignSystem.Colors.primaryText)

                SleepStagesBar(stages: stages)

                // Stage breakdown
                VStack(spacing: DesignSystem.Spacing.sm) {
                    stageRow(label: "Awake", minutes: stages.awake, color: .gray)
                    stageRow(label: "Light", minutes: stages.light, color: DesignSystem.Colors.championBlue.opacity(0.4))
                    stageRow(label: "REM", minutes: stages.rem, color: DesignSystem.Colors.championBlue)
                    stageRow(label: "Deep", minutes: stages.deep, color: DesignSystem.Colors.championBlue.opacity(0.8))
                }
            }
        }
    }

    private func stageRow(label: String, minutes: Int, color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            Spacer()
            Text(formatMinutes(minutes))
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.primaryText)
        }
    }

    // MARK: - Key Metrics Grid

    @ViewBuilder
    private var metricsGrid: some View {
        PremiumCard(timeContext: timeContext) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Text("Key Metrics")
                    .font(DesignSystem.Typography.headlineSmall)
                    .foregroundColor(DesignSystem.Colors.primaryText)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                          spacing: DesignSystem.Spacing.md) {
                    if let hrv = data.hrv {
                        metricTile(icon: "waveform.path.ecg", value: "\(Int(hrv)) ms", label: "HRV")
                    }
                    if let hr = data.restingHr {
                        metricTile(icon: "heart.fill", value: "\(hr) bpm", label: "Resting HR")
                    }
                    if let resp = data.respiratoryRate {
                        metricTile(icon: "lungs.fill", value: String(format: "%.1f/min", resp), label: "Resp Rate")
                    }
                    if let temp = data.skinTempDelta {
                        metricTile(icon: "thermometer.medium", value: String(format: "%+.1f\u{00B0}", temp), label: "Skin Temp")
                    }
                    if let strain = data.strainScore {
                        metricTile(icon: "flame.fill", value: String(format: "%.1f", strain), label: "Day Strain")
                    }
                }
            }
        }
    }

    private func metricTile(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(timeContext.primaryColor)
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(DesignSystem.Colors.primaryText)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(DesignSystem.Colors.tertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.sm)
    }

    // MARK: - Recovery Assessment

    @ViewBuilder
    private func recoveryAssessment(score: Double, zone: WhoopDailyData.RecoveryZone) -> some View {
        PremiumCard(timeContext: timeContext) {
            HStack(spacing: DesignSystem.Spacing.md) {
                RecoveryCircle(score: score, zone: zone)
                    .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Recovery Assessment")
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    Text(zone.recommendation)
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}

// MARK: - Sleep Stages Bar

struct SleepStagesBar: View {
    let stages: WhoopDailyData.SleepStages

    var body: some View {
        let total = max(stages.totalInBed, 1)

        GeometryReader { geo in
            HStack(spacing: 1) {
                stageSegment(minutes: stages.light, total: total, color: DesignSystem.Colors.championBlue.opacity(0.4), width: geo.size.width)
                stageSegment(minutes: stages.awake, total: total, color: .gray.opacity(0.5), width: geo.size.width)
                stageSegment(minutes: stages.rem, total: total, color: DesignSystem.Colors.championBlue, width: geo.size.width)
                stageSegment(minutes: stages.deep, total: total, color: DesignSystem.Colors.championBlue.opacity(0.8), width: geo.size.width)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .frame(height: 24)
    }

    private func stageSegment(minutes: Int, total: Int, color: Color, width: CGFloat) -> some View {
        let fraction = CGFloat(minutes) / CGFloat(total)
        return color
            .frame(width: max(fraction * width - 1, 0))
    }
}
