//
//  LoadingOverlay.swift
//  Your Daily Dose
//
//  Reusable loading states and overlays for API calls
//

import SwiftUI

// MARK: - Loading Overlay Modifier
struct LoadingOverlay: ViewModifier {
    let isLoading: Bool
    let message: String?
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
            
            if isLoading {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                
                LoadingCard(message: message)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(DesignSystem.Animation.gentle, value: isLoading)
    }
}

// MARK: - Loading Card Component
struct LoadingCard: View {
    let message: String?
    @State private var isAnimating = false
    
    private var timeContext: DesignSystem.TimeContext {
        DesignSystem.TimeContext.current()
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Custom animated loader
            ZStack {
                Circle()
                    .stroke(
                        DesignSystem.Colors.border.opacity(0.3),
                        lineWidth: 4
                    )
                    .frame(width: 48, height: 48)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        timeContext.primaryColor,
                        style: StrokeStyle(
                            lineWidth: 4,
                            lineCap: .round
                        )
                    )
                    .frame(width: 48, height: 48)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(
                        .linear(duration: 1.2).repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            }
            
            if let message = message {
                Text(message)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .fill(DesignSystem.Colors.cardBackground)
                .shadow(
                    color: DesignSystem.Shadow.elevated.color,
                    radius: DesignSystem.Shadow.elevated.radius,
                    x: DesignSystem.Shadow.elevated.x,
                    y: DesignSystem.Shadow.elevated.y
                )
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Inline Loading Indicator
struct InlineLoadingIndicator: View {
    let message: String?
    @State private var dots = ""
    
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ProgressView()
                .scaleEffect(0.8)
                .tint(DesignSystem.TimeContext.current().primaryColor)
            
            if let message = message {
                Text(message + dots)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
        .onReceive(timer) { _ in
            withAnimation {
                if dots.count >= 3 {
                    dots = ""
                } else {
                    dots += "."
                }
            }
        }
    }
}

// MARK: - Skeleton Loading View
struct SkeletonView: View {
    @State private var isAnimating = false
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(height: CGFloat = 20, cornerRadius: CGFloat = DesignSystem.CornerRadius.small) {
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        DesignSystem.Colors.border.opacity(0.3),
                        DesignSystem.Colors.border.opacity(0.1),
                        DesignSystem.Colors.border.opacity(0.3)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: height)
            .offset(x: isAnimating ? 200 : -200)
            .animation(
                .linear(duration: 1.5).repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
            .mask(
                RoundedRectangle(cornerRadius: cornerRadius)
            )
    }
}

// MARK: - Error State View
struct ErrorStateView: View {
    let message: String
    let retryAction: (() -> Void)?
    
    private var timeContext: DesignSystem.TimeContext {
        DesignSystem.TimeContext.current()
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.alertRed)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("Something went wrong")
                    .font(DesignSystem.Typography.headlineMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text(message)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            if let retryAction = retryAction {
                Button(action: retryAction) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(DesignSystem.Typography.buttonMedium)
                    .foregroundColor(DesignSystem.Colors.invertedText)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .fill(timeContext.primaryColor)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignSystem.Spacing.xl)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    private var timeContext: DesignSystem.TimeContext {
        DesignSystem.TimeContext.current()
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(DesignSystem.Colors.tertiaryText)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(title)
                    .font(DesignSystem.Typography.headlineLargeSafe)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text(message)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "plus.circle.fill")
                        Text(actionTitle)
                    }
                    .font(DesignSystem.Typography.buttonMedium)
                    .foregroundColor(timeContext.primaryColor)
                }
                .buttonStyle(.plain)
                .padding(.top, DesignSystem.Spacing.sm)
            }
        }
        .padding(DesignSystem.Spacing.xl)
    }
}

// MARK: - View Extensions
extension View {
    func loadingOverlay(isLoading: Bool, message: String? = nil) -> some View {
        self.modifier(LoadingOverlay(isLoading: isLoading, message: message))
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 40) {
        LoadingCard(message: "Loading your data...")
        
        InlineLoadingIndicator(message: "Syncing")
        
        VStack(spacing: 10) {
            SkeletonView()
            SkeletonView(height: 60)
            SkeletonView(height: 100)
        }
        .padding()
        
        ErrorStateView(
            message: "Unable to load your daily entries. Please check your connection and try again.",
            retryAction: { print("Retry") }
        )
        
        EmptyStateView(
            icon: "doc.text",
            title: "No Entries Yet",
            message: "Start your daily ritual to see your progress here",
            actionTitle: "Start Now",
            action: { print("Start") }
        )
    }
    .padding()
    .background(DesignSystem.Colors.background)
}
