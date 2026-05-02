import Foundation

protocol ArgoCoachProposalStoring: AnyObject {
    func loadProposals(for date: Date) -> [ArgoCoachProposal]
    func upsert(_ proposal: ArgoCoachProposal)
    @discardableResult func updateStatus(
        proposalId: String,
        status: ArgoCoachProposal.Status,
        at date: Date
    ) -> ArgoCoachProposal?
}

final class LocalArgoCoachProposalStore: ArgoCoachProposalStoring {
    private let defaults: UserDefaults
    private let storageKey: String

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = "argo_coach_proposals_v1"
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
    }

    func loadProposals(for date: Date) -> [ArgoCoachProposal] {
        let dateKey = ArgoCoachProposal.dateKey(for: date)
        return loadAll()
            .filter { $0.dateKey == dateKey }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func upsert(_ proposal: ArgoCoachProposal) {
        var proposals = loadAll()
        if let index = proposals.firstIndex(where: { $0.id == proposal.id }) {
            proposals[index] = proposal
        } else {
            proposals.append(proposal)
        }
        saveAll(proposals)
    }

    @discardableResult
    func updateStatus(
        proposalId: String,
        status: ArgoCoachProposal.Status,
        at date: Date = Date()
    ) -> ArgoCoachProposal? {
        var proposals = loadAll()
        guard let index = proposals.firstIndex(where: { $0.id == proposalId }) else {
            return nil
        }

        let updated = proposals[index].updatingStatus(status, at: date)
        proposals[index] = updated
        saveAll(proposals)
        return updated
    }

    private func loadAll() -> [ArgoCoachProposal] {
        guard let data = defaults.data(forKey: storageKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([ArgoCoachProposal].self, from: data)
        } catch {
            print("LocalArgoCoachProposalStore: failed to decode proposals:", error)
            return []
        }
    }

    private func saveAll(_ proposals: [ArgoCoachProposal]) {
        do {
            let data = try JSONEncoder().encode(proposals)
            defaults.set(data, forKey: storageKey)
        } catch {
            print("LocalArgoCoachProposalStore: failed to encode proposals:", error)
        }
    }
}
