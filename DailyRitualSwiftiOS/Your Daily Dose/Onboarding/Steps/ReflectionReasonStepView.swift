//
//  ReflectionReasonStepView.swift
//  Your Daily Dose
//
//  Onboarding step explaining why daily reflection matters
//

import SwiftUI

struct ReflectionReasonStepView: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var showLearnMore: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Hero Section
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [DesignSystem.Colors.eliteGold.opacity(0.3), DesignSystem.Colors.championBlue.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 52))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [DesignSystem.Colors.eliteGold, DesignSystem.Colors.championBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    Text("The Power of\nDaily Reflection")
                        .font(DesignSystem.Typography.displaySmallSafe)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text("Elite athletes don't just train their bodies—they train their minds. Daily reflection is the bridge between physical effort and mental mastery.")
                        .font(DesignSystem.Typography.bodyLargeSafe)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                }
                .padding(.top, DesignSystem.Spacing.lg)
                
                // Science-backed reasons
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Backed by research")
                        .font(DesignSystem.Typography.headlineMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    ReasonCard(
                        number: "1",
                        title: "Enhanced Self-Awareness",
                        description: "Studies show athletes who journal have 27% better emotional regulation during competition.",
                        color: DesignSystem.Colors.eliteGold
                    )
                    
                    ReasonCard(
                        number: "2",
                        title: "Accelerated Learning",
                        description: "Reflection helps consolidate motor learning, making your practice sessions more effective.",
                        color: DesignSystem.Colors.championBlue
                    )
                    
                    ReasonCard(
                        number: "3",
                        title: "Injury Prevention",
                        description: "Athletes who track their mental state are more likely to notice early warning signs of overtraining.",
                        color: DesignSystem.Colors.powerGreen
                    )
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                
                // Quote
                VStack(spacing: DesignSystem.Spacing.md) {
                    Text("\"What gets measured gets managed. What gets reflected on gets mastered.\"")
                        .font(DesignSystem.Typography.quoteTextSafe)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    
                    Text("— Performance Psychology Research")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .padding(DesignSystem.Spacing.lg)
                .background(DesignSystem.Colors.cardBackground)
                .cornerRadius(DesignSystem.CornerRadius.medium)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                
                // Learn More Button
                Button {
                    HapticFeedback.selection()
                    showLearnMore = true
                } label: {
                    HStack {
                        Image(systemName: "book.fill")
                        Text("Learn more about the science")
                    }
                    .font(DesignSystem.Typography.buttonMedium)
                    .foregroundColor(DesignSystem.Colors.championBlue)
                }
                
                Spacer(minLength: DesignSystem.Spacing.xxl)
            }
        }
        .sheet(isPresented: $showLearnMore) {
            LearnMoreSheet()
        }
    }
}

// MARK: - Reason Card
struct ReasonCard: View {
    let number: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            // Number badge
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Text(number)
                    .font(DesignSystem.Typography.headlineMedium)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignSystem.Typography.headlineSmall)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text(description)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Learn More Sheet
struct LearnMoreSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    Text("The Science of Athletic Journaling")
                        .font(DesignSystem.Typography.displaySmallSafe)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("""
                    Research in sports psychology has consistently shown that reflective practices enhance athletic performance. Here's what the science tells us:

                    **Memory Consolidation**
                    Writing about your training experiences helps transfer learning from short-term to long-term memory. This is particularly important for skill acquisition in complex sports.

                    **Emotional Regulation**
                    Athletes who regularly journal show improved ability to manage performance anxiety and maintain focus under pressure. The act of writing creates cognitive distance from emotions.

                    **Goal Achievement**
                    A study by Dr. Gail Matthews at Dominican University found that people who write down their goals are 42% more likely to achieve them compared to those who don't.

                    **Pattern Recognition**
                    Regular reflection helps athletes identify correlations between their mental state, training quality, and performance outcomes that might otherwise go unnoticed.

                    **Recovery Enhancement**
                    Journaling about setbacks and challenges has been shown to accelerate psychological recovery from injuries and poor performances.
                    """)
                        .font(DesignSystem.Typography.bodyLargeSafe)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Spacer()
                }
                .padding(DesignSystem.Spacing.lg)
            }
            .background(DesignSystem.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ReflectionReasonStepView(coordinator: OnboardingCoordinator())
        .preferredColorScheme(.dark)
}


