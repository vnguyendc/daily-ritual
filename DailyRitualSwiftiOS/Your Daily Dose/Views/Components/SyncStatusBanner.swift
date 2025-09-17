//
//  SyncStatusBanner.swift
//  Your Daily Dose
//
//  Small banner to indicate offline syncing / pending ops.
//

import SwiftUI

struct SyncStatusBanner: View {
    @ObservedObject private var supabase = SupabaseManager.shared
    let timeContext: DesignSystem.TimeContext

    var body: some View {
        if supabase.isSyncing || supabase.pendingOpsCount > 0 {
            HStack(spacing: DesignSystem.Spacing.sm) {
                if supabase.isSyncing {
                    ProgressView()
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                Text(statusText)
                    .font(DesignSystem.Typography.metadata)
                Spacer()
                if !supabase.isSyncing {
                    Button("Sync Now") {
                        Task { await supabase.replayPendingOpsWithBackoff() }
                    }
                    .font(DesignSystem.Typography.buttonSmall)
                }
            }
            .padding(10)
            .background(timeContext.primaryColor.opacity(0.12))
            .foregroundColor(timeContext.primaryColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, DesignSystem.Spacing.cardPadding)
        }
    }

    private var statusText: String {
        if supabase.isSyncing { return "Syncing… \(supabase.pendingOpsCount) pending" }
        if supabase.pendingOpsCount > 0 { return "Will retry \(supabase.pendingOpsCount) change(s) when online" }
        return ""
    }
}

#Preview {
    SyncStatusBanner(timeContext: .morning)
}


