//
//  LoadingOverlay.swift
//  Your Daily Dose
//
//  Reusable loading states and overlays for API calls
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Loading Overlay Options
struct LoadingOverlayOptions {
    var message: String? = nil
    var delayBeforeShow: TimeInterval = 0.2
    var minVisibleDuration: TimeInterval = 0.6
    var progress: Double? = nil // 0.0 ... 1.0
    var cancelAction: (() -> Void)? = nil
    var useMaterialBackground: Bool = false
    var hapticsOnShow: Bool = false
}

// MARK: - Loading Overlay Modifier
struct LoadingOverlay: ViewModifier {
    let isLoading: Bool
    let message: String?
    let delayBeforeShow: TimeInterval
    let minVisibleDuration: TimeInterval
    let progress: Double?
    let cancelAction: (() -> Void)?
    let useMaterialBackground: Bool
    let hapticsOnShow: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isPresenting: Bool = false
    @State private var shownAt: Date? = nil
    @State private var showWorkItem: DispatchWorkItem? = nil
    @State private var hideWorkItem: DispatchWorkItem? = nil
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
            
            if isPresenting {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                    .accessibilityHidden(true)
                
                LoadingCard(
                    message: message,
                    progress: progress,
                    cancelAction: cancelAction,
                    useMaterialBackground: useMaterialBackground
                )
                .transition(.scale.combined(with: .opacity))
                .accessibilityAddTraits(.isModal)
            }
        }
        .animation(reduceMotion ? .none : DesignSystem.Animation.gentle, value: isPresenting)
        .onAppear {
            synchronizePresentation(with: isLoading)
        }
        .onChange(of: isLoading) { newValue in
            synchronizePresentation(with: newValue)
        }
    }

    private func synchronizePresentation(with shouldLoad: Bool) {
        if shouldLoad {
            scheduleShow()
        } else {
            scheduleHide()
        }
    }

    private func scheduleShow() {
        hideWorkItem?.cancel()
        showWorkItem?.cancel()
        
        if isPresenting {
            return
        }
        
        let work = DispatchWorkItem {
            withAnimation(reduceMotion ? nil : DesignSystem.Animation.gentle) {
                isPresenting = true
                shownAt = Date()
                triggerHapticsIfNeeded()
            }
        }
        showWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + max(0, delayBeforeShow), execute: work)
    }

    private func scheduleHide() {
        showWorkItem?.cancel()
        
        guard isPresenting else {
            // Overlay hasn't presented yet; nothing to hide.
            return
        }
        
        hideWorkItem?.cancel()
        let elapsed = Date().timeIntervalSince(shownAt ?? Date())
        let remaining = max(0, minVisibleDuration - elapsed)
        let work = DispatchWorkItem {
            withAnimation(reduceMotion ? nil : DesignSystem.Animation.gentle) {
                isPresenting = false
                shownAt = nil
            }
        }
        hideWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + remaining, execute: work)
    }

    private func triggerHapticsIfNeeded() {
        guard hapticsOnShow else { return }
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
}

// MARK: - Loading Card Component
struct LoadingCard: View {
    let message: String?
    let progress: Double?
    let cancelAction: (() -> Void)?
    let useMaterialBackground: Bool
    
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private var timeContext: DesignSystem.TimeContext {
        DesignSystem.TimeContext.current()
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(
                        DesignSystem.Colors.border.opacity(0.3),
                        lineWidth: 4
                    )
                    .frame(width: 48, height: 48)
                
                if let progress = progress.map({ min(max($0, 0), 1) }) {
                    // Determinate progress ring
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            timeContext.primaryColor,
                            style: StrokeStyle(
                                lineWidth: 4,
                                lineCap: .round
                            )
                        )
                        .rotationEffect(Angle(degrees: -90))
                        .frame(width: 48, height: 48)
                    
                    Text("\(Int(progress * 100))%")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .allowsTightening(true)
                } else {
                    // Indeterminate spinner
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
                            reduceMotion ? .none : .linear(duration: 1.2).repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Loading")
            .accessibilityValue(Text(progressText ?? ""))
            
            if let message = message {
                Text(message)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            if let cancelAction = cancelAction {
                Button(action: cancelAction) {
                    Text("Cancel")
                        .font(DesignSystem.Typography.buttonMedium)
                        .foregroundColor(timeContext.primaryColor)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                .stroke(timeContext.primaryColor.opacity(0.4), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityHint("Double-tap to cancel the current operation")
                .padding(.top, DesignSystem.Spacing.xs)
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .background(
            Group {
                if useMaterialBackground {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                        .fill(.ultraThinMaterial)
                } else {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                        .fill(DesignSystem.Colors.cardBackground)
                }
            }
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
    
    private var progressText: String? {
        guard let progress = progress.map({ min(max($0, 0), 1) }) else { return nil }
        return "\(Int(progress * 100)) percent"
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
        self.modifier(
            LoadingOverlay(
                isLoading: isLoading,
                message: message,
                delayBeforeShow: 0.2,
                minVisibleDuration: 0.6,
                progress: nil,
                cancelAction: nil,
                useMaterialBackground: false,
                hapticsOnShow: false
            )
        )
    }
    
    func loadingOverlay(isLoading: Bool, options: LoadingOverlayOptions) -> some View {
        self.modifier(
            LoadingOverlay(
                isLoading: isLoading,
                message: options.message,
                delayBeforeShow: options.delayBeforeShow,
                minVisibleDuration: options.minVisibleDuration,
                progress: options.progress,
                cancelAction: options.cancelAction,
                useMaterialBackground: options.useMaterialBackground,
                hapticsOnShow: options.hapticsOnShow
            )
        )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 40) {
        LoadingCard(message: "Loading your data...", progress: nil, cancelAction: nil, useMaterialBackground: false)
        
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
