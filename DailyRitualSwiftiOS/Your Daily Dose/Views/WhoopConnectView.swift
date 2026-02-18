//
//  WhoopConnectView.swift
//  Your Daily Dose
//
//  Settings view for Whoop connection management and privacy controls.
//

import SwiftUI

struct WhoopConnectView: View {
    @ObservedObject private var whoopService = WhoopService.shared
    @State private var showDisconnectAlert = false
    @AppStorage("whoop_show_recovery") private var showRecovery = true
    @AppStorage("whoop_show_sleep") private var showSleep = true
    @AppStorage("whoop_show_strain") private var showStrain = true
    @AppStorage("whoop_show_hr") private var showHeartRate = true

    private var timeContext: DesignSystem.TimeContext { DesignSystem.TimeContext.current() }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                if whoopService.isConnected {
                    connectedSection
                    privacySection
                } else {
                    disconnectedSection
                }
            }
            .padding(DesignSystem.Spacing.lg)
        }
        .premiumBackgroundGradient(timeContext)
        .navigationTitle("WHOOP")
        .alert("Disconnect WHOOP?", isPresented: $showDisconnectAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Disconnect", role: .destructive) {
                Task { await whoopService.disconnect() }
            }
        } message: {
            Text("Your Whoop data will be removed from the dashboard. You can reconnect anytime.")
        }
        .task {
            await whoopService.checkConnectionStatus()
        }
    }

    // MARK: - Connected State

    @ViewBuilder
    private var connectedSection: some View {
        PremiumCard(timeContext: timeContext) {
            VStack(spacing: DesignSystem.Spacing.md) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.powerGreen)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("WHOOP Connected")
                            .font(DesignSystem.Typography.headlineSmall)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        if let sync = whoopService.lastSyncDate {
                            Text("Last sync: \(sync, style: .relative) ago")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                    Spacer()
                }

                if let error = whoopService.error {
                    Text(error)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.alertRed)
                }

                HStack(spacing: DesignSystem.Spacing.md) {
                    Button {
                        Task { await whoopService.syncNow() }
                    } label: {
                        HStack(spacing: 6) {
                            if whoopService.isLoading {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .tint(DesignSystem.Colors.primaryText)
                            }
                            Text("Sync Now")
                        }
                        .font(DesignSystem.Typography.buttonMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(timeContext.primaryColor.opacity(0.15))
                        .cornerRadius(DesignSystem.CornerRadius.button)
                    }
                    .disabled(whoopService.isLoading)

                    Button {
                        showDisconnectAlert = true
                    } label: {
                        Text("Disconnect")
                            .font(DesignSystem.Typography.buttonMedium)
                            .foregroundColor(DesignSystem.Colors.alertRed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(DesignSystem.Colors.alertRed.opacity(0.1))
                            .cornerRadius(DesignSystem.CornerRadius.button)
                    }
                }
            }
        }
    }

    // MARK: - Disconnected State

    @ViewBuilder
    private var disconnectedSection: some View {
        PremiumCard(timeContext: timeContext) {
            VStack(spacing: DesignSystem.Spacing.lg) {
                Image(systemName: "applewatch")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [timeContext.primaryColor, timeContext.primaryColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text("Connect WHOOP")
                        .font(DesignSystem.Typography.headlineMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)

                    Text("See your recovery, sleep, and strain data in your daily practice. Recovery-aware training recommendations included.")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await initiateConnection() }
                } label: {
                    HStack(spacing: 8) {
                        if whoopService.isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.white)
                        }
                        Text("Connect Whoop")
                            .font(DesignSystem.Typography.buttonLarge)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(timeContext.primaryColor)
                    .cornerRadius(DesignSystem.CornerRadius.button)
                }
                .disabled(whoopService.isLoading)

                Text("Your data stays private. You control what's visible.")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
        }
    }

    // MARK: - Privacy Toggles

    @ViewBuilder
    private var privacySection: some View {
        PremiumCard(timeContext: timeContext) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Text("Dashboard Visibility")
                    .font(DesignSystem.Typography.headlineSmall)
                    .foregroundColor(DesignSystem.Colors.primaryText)

                Toggle("Recovery Score", isOn: $showRecovery)
                Toggle("Sleep Data", isOn: $showSleep)
                Toggle("Strain Score", isOn: $showStrain)
                Toggle("Heart Rate (HRV / RHR)", isOn: $showHeartRate)
            }
            .tint(timeContext.primaryColor)
        }
    }

    // MARK: - OAuth Flow

    private func initiateConnection() async {
        whoopService.isLoading = true
        defer { whoopService.isLoading = false }

        do {
            struct AuthUrlResponse: Codable {
                let success: Bool
                let data: AuthData?
                struct AuthData: Codable {
                    let authUrl: String
                    let state: String
                    private enum CodingKeys: String, CodingKey {
                        case authUrl = "auth_url"
                        case state
                    }
                }
            }

            let response: AuthUrlResponse = try await SupabaseManager.shared.api.get("/integrations/whoop/auth-url")
            guard let authUrlString = response.data?.authUrl,
                  let authUrl = URL(string: authUrlString) else {
                whoopService.error = "Failed to get authorization URL"
                return
            }

            // Open in Safari — the callback deep link will bring the user back
            await MainActor.run {
                #if canImport(UIKit)
                UIApplication.shared.open(authUrl)
                #endif
            }
        } catch {
            whoopService.error = "Failed to start Whoop connection: \(error.localizedDescription)"
        }
    }
}
