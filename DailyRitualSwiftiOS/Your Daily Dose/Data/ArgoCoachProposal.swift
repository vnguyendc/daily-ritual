import Foundation

struct ArgoCoachProposal: Identifiable, Codable, Sendable {
    let id: String
    let dateKey: String
    let action: ArgoCoachAction
    let status: Status
    let payload: [String: AnyCodable]
    let createdAt: Date
    let updatedAt: Date

    enum Status: String, Codable, Sendable {
        case pending
        case accepted
        case edited
        case rejected
        case completed

        var isVisible: Bool {
            switch self {
            case .pending, .accepted, .edited:
                return true
            case .rejected, .completed:
                return false
            }
        }

        var displayName: String {
            switch self {
            case .pending:
                return "Pending"
            case .accepted:
                return "Accepted"
            case .edited:
                return "Edited"
            case .rejected:
                return "Skipped"
            case .completed:
                return "Completed"
            }
        }
    }

    var isVisible: Bool {
        status.isVisible
    }

    func updatingStatus(_ newStatus: Status, at date: Date = Date()) -> ArgoCoachProposal {
        ArgoCoachProposal(
            id: id,
            dateKey: dateKey,
            action: action,
            status: newStatus,
            payload: payload,
            createdAt: createdAt,
            updatedAt: date
        )
    }

    static func stableID(date: Date, action: ArgoCoachAction) -> String {
        "\(dateKey(for: date))-\(action.id)"
    }

    static func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = Calendar.current.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

enum ArgoCoachActionGenerator {
    static func actions(for context: ArgoDailyContext) -> [ArgoCoachAction] {
        var actions: [ArgoCoachAction] = []

        func appendIfUnique(_ action: ArgoCoachAction) {
            guard !actions.contains(where: { $0.id == action.id }) else { return }
            actions.append(action)
        }

        if let nextAction = context.derived.nextAction {
            appendIfUnique(nextAction)
        }

        if context.derived.missingContext.contains(.noMeals),
           !actions.contains(where: { $0.kind == .logMeal }) {
            appendIfUnique(
                ArgoCoachAction(
                    id: "coach-log-meal",
                    title: "Add food context.",
                    body: "A quick meal photo or text note helps Argo estimate fuel for the rest of the day.",
                    primaryLabel: "Log meal",
                    kind: .logMeal
                )
            )
        }

        if context.derived.missingContext.contains(.missingWearableData) {
            appendIfUnique(
                ArgoCoachAction(
                    id: "coach-connect-wearable",
                    title: "Wearable data is missing.",
                    body: "Recovery and strain recommendations improve when Whoop, Garmin, or Apple Health data is current.",
                    primaryLabel: "Review",
                    kind: .recoveryHabit
                )
            )
        }

        return Array(actions.prefix(3))
    }
}

enum ArgoCoachProposalGenerator {
    static func makeProposals(
        for context: ArgoDailyContext,
        existing: [ArgoCoachProposal],
        now: Date = Date()
    ) -> [ArgoCoachProposal] {
        let existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })

        return ArgoCoachActionGenerator.actions(for: context).compactMap { action in
            let id = ArgoCoachProposal.stableID(date: context.date, action: action)
            if let proposal = existingByID[id] {
                return proposal.isVisible ? proposal : nil
            }

            return ArgoCoachProposal(
                id: id,
                dateKey: ArgoCoachProposal.dateKey(for: context.date),
                action: action,
                status: .pending,
                payload: [:],
                createdAt: now,
                updatedAt: now
            )
        }
    }
}
