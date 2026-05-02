import Foundation
import Testing
@testable import Your_Daily_Dose

struct ArgoCoachProposalTests {
    @Test func generatorCreatesPendingProposalForNextAction() {
        let date = Date(timeIntervalSince1970: 5_000)
        let context = makeContext(date: date, action: makeAction(id: "log-meal", kind: .logMeal))

        let proposals = ArgoCoachProposalGenerator.makeProposals(
            for: context,
            existing: [],
            now: date
        )

        #expect(proposals.count == 1)
        #expect(proposals.first?.id == "\(ArgoCoachProposal.dateKey(for: date))-log-meal")
        #expect(proposals.first?.status == .pending)
    }

    @Test func rejectedProposalSuppressesSameDayRegeneration() {
        let date = Date(timeIntervalSince1970: 5_000)
        let action = makeAction(id: "log-meal", kind: .logMeal)
        let context = makeContext(date: date, action: action)
        let existing = ArgoCoachProposal(
            id: ArgoCoachProposal.stableID(date: date, action: action),
            dateKey: ArgoCoachProposal.dateKey(for: date),
            action: action,
            status: .rejected,
            payload: [:],
            createdAt: date,
            updatedAt: date
        )

        let proposals = ArgoCoachProposalGenerator.makeProposals(
            for: context,
            existing: [existing],
            now: date
        )

        #expect(proposals.isEmpty)
    }

    @Test func coachProposalEventCarriesStatusAndAttentionState() {
        let date = Date(timeIntervalSince1970: 5_000)
        let action = makeAction(id: "check-in", kind: .checkIn)
        let proposal = ArgoCoachProposal(
            id: ArgoCoachProposal.stableID(date: date, action: action),
            dateKey: ArgoCoachProposal.dateKey(for: date),
            action: action,
            status: .pending,
            payload: [:],
            createdAt: date,
            updatedAt: date
        )

        let event = ArgoDailyEventMapper.makeCoachProposalEvent(proposal)

        #expect(event.source == .coach)
        #expect(event.type == .coachRecommendation)
        #expect(event.requiresReview)
        #expect(event.sourceRecordId == proposal.id)
    }

    private func makeAction(id: String, kind: ArgoCoachAction.Kind) -> ArgoCoachAction {
        ArgoCoachAction(
            id: id,
            title: "Action",
            body: "Take action.",
            primaryLabel: "Start",
            kind: kind
        )
    }

    private func makeContext(date: Date, action: ArgoCoachAction) -> ArgoDailyContext {
        ArgoDailyContext(
            date: date,
            dailyEntry: nil,
            events: [],
            nutrition: nil,
            journalEntries: [],
            workoutReflections: [],
            plannedWorkouts: [],
            healthKitWorkouts: [],
            whoop: nil,
            coachProposals: [],
            derived: ArgoDailySignals(
                recoveryStatus: .unknown,
                fuelStatus: .notStarted,
                trainingLoadStatus: .open,
                missingContext: [],
                nextAction: action,
                summaryText: "Test"
            )
        )
    }
}
