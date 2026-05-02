import Foundation
import Testing
@testable import Your_Daily_Dose

struct ArgoCoachProposalStoreTests {
    @Test func localStorePersistsAndUpdatesProposalStatus() throws {
        let suiteName = "argo-coach-proposal-store-tests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let date = Date(timeIntervalSince1970: 6_000)
        let store = LocalArgoCoachProposalStore(defaults: defaults)
        let proposal = makeProposal(date: date)

        store.upsert(proposal)
        let saved = store.loadProposals(for: date)

        #expect(saved.count == 1)
        #expect(saved.first?.status == .pending)

        let updated = store.updateStatus(
            proposalId: proposal.id,
            status: .completed,
            at: date.addingTimeInterval(60)
        )

        #expect(updated?.status == .completed)
        #expect(store.loadProposals(for: date).first?.status == .completed)
    }

    private func makeProposal(date: Date) -> ArgoCoachProposal {
        let action = ArgoCoachAction(
            id: "log-meal",
            title: "Log your first meal.",
            body: "Add food context.",
            primaryLabel: "Log meal",
            kind: .logMeal
        )

        return ArgoCoachProposal(
            id: ArgoCoachProposal.stableID(date: date, action: action),
            dateKey: ArgoCoachProposal.dateKey(for: date),
            action: action,
            status: .pending,
            payload: [:],
            createdAt: date,
            updatedAt: date
        )
    }
}
