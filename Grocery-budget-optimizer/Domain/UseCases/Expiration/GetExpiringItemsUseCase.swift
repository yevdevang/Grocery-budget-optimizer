import Foundation
import Combine

protocol GetExpiringItemsUseCaseProtocol {
    func execute(daysThreshold: Int) -> AnyPublisher<[ExpiringItemInfo], Error>
}

class GetExpiringItemsUseCase: GetExpiringItemsUseCaseProtocol {
    private let expirationRepository: ExpirationTrackerRepositoryProtocol
    private let groceryItemRepository: GroceryItemRepositoryProtocol

    init(
        expirationRepository: ExpirationTrackerRepositoryProtocol,
        groceryItemRepository: GroceryItemRepositoryProtocol
    ) {
        self.expirationRepository = expirationRepository
        self.groceryItemRepository = groceryItemRepository
    }

    func execute(daysThreshold: Int = 7) -> AnyPublisher<[ExpiringItemInfo], Error> {
        return expirationRepository.fetchActiveTrackers()
            .flatMap { [weak self] trackers -> AnyPublisher<[ExpiringItemInfo], Error> in
                guard let self = self else {
                    return Fail(error: MLIntegrationError.unknown).eraseToAnyPublisher()
                }

                // Filter expiring items
                let expiringTrackers = trackers.filter { tracker in
                    let daysRemaining = Calendar.current.dateComponents(
                        [.day],
                        from: Date(),
                        to: tracker.estimatedExpirationDate
                    ).day ?? 0

                    return daysRemaining <= daysThreshold && daysRemaining >= 0
                }

                // Get item info for each tracker
                let infoPublishers = expiringTrackers.map { tracker in
                    self.getExpiringInfo(for: tracker)
                }

                return Publishers.MergeMany(infoPublishers)
                    .collect()
                    .map { infos in
                        infos.compactMap { $0 }
                            .sorted { $0.daysRemaining < $1.daysRemaining }
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func getExpiringInfo(for tracker: ExpirationTracker)
        -> AnyPublisher<ExpiringItemInfo?, Error> {

        return groceryItemRepository.fetchItem(byId: tracker.groceryItemId)
            .tryMap { (item: GroceryItem?) -> ExpiringItemInfo? in
                guard let item = item else { return nil }

                let daysRemaining = Calendar.current.dateComponents(
                    [.day],
                    from: Date(),
                    to: tracker.estimatedExpirationDate
                ).day ?? 0

                let urgency: ExpirationUrgency
                if daysRemaining <= 0 {
                    urgency = .expired
                } else if daysRemaining <= 2 {
                    urgency = .useSoon
                } else if daysRemaining <= 5 {
                    urgency = .moderate
                } else {
                    urgency = .fresh
                }

                return ExpiringItemInfo(
                    item: item,
                    tracker: tracker,
                    daysRemaining: daysRemaining,
                    urgency: urgency
                )
            }
            .eraseToAnyPublisher()
    }
}

struct ExpiringItemInfo: Identifiable {
    var id: UUID { tracker.id }
    let item: GroceryItem
    let tracker: ExpirationTracker
    let daysRemaining: Int
    let urgency: ExpirationUrgency
}
