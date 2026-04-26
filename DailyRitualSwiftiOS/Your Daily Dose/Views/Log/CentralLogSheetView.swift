import SwiftUI

struct CentralLogSheetView: View {
    let onMeal: () -> Void
    let onVoice: () -> Void
    let onWorkout: () -> Void
    let onCheckIn: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            Capsule()
                .fill(DesignSystem.Colors.divider)
                .frame(width: 42, height: 4)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Log what matters.")
                    .font(DesignSystem.Typography.displaySmallSafe)
                    .foregroundColor(DesignSystem.Colors.primaryText)

                Text("Capture food, voice context, workouts, or a quick check-in.")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.md) {
                captureButton(title: "Meal", subtitle: "Photo + macros", icon: "camera", action: onMeal)
                captureButton(title: "Voice", subtitle: "Dictate context", icon: "waveform", action: onVoice)
                captureButton(title: "Workout", subtitle: "Reflect fast", icon: "checkmark.circle", action: onWorkout)
                captureButton(title: "Check-in", subtitle: "Energy, stress", icon: "slider.horizontal.3", action: onCheckIn)
            }

            Text("Long press the center Log button can start voice capture in a later slice.")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
                .padding(.top, DesignSystem.Spacing.xs)
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .background(DesignSystem.Colors.background.ignoresSafeArea())
    }

    private func captureButton(title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.tap()
            action()
        } label: {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Image(systemName: icon)
                    .font(DesignSystem.Typography.headlineLarge)
                    .foregroundColor(DesignSystem.Colors.primaryText)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    Text(subtitle)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
    }
}

#Preview {
    CentralLogSheetView(onMeal: {}, onVoice: {}, onWorkout: {}, onCheckIn: {})
}
