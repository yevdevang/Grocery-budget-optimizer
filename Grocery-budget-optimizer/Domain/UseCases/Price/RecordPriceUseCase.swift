import Foundation
import Combine

protocol RecordPriceUseCaseProtocol {
    func execute(
        itemId: UUID,
        price: Decimal,
        storeName: String?
    ) -> AnyPublisher<PriceHistory, Error>
}

class RecordPriceUseCase: RecordPriceUseCaseProtocol {
    private let priceHistoryRepository: PriceHistoryRepositoryProtocol
    private let groceryItemRepository: GroceryItemRepositoryProtocol

    init(
        priceHistoryRepository: PriceHistoryRepositoryProtocol,
        groceryItemRepository: GroceryItemRepositoryProtocol
    ) {
        self.priceHistoryRepository = priceHistoryRepository
        self.groceryItemRepository = groceryItemRepository
    }

    func execute(
        itemId: UUID,
        price: Decimal,
        storeName: String?
    ) -> AnyPublisher<PriceHistory, Error> {

        let priceHistory = PriceHistory(
            id: UUID(),
            groceryItemId: itemId,
            price: price,
            recordedAt: Date(),
            storeName: storeName,
            source: "manual"
        )

        return priceHistoryRepository.addPriceHistory(priceHistory)
            .flatMap { [weak self] history -> AnyPublisher<PriceHistory, Error> in
                guard let self = self else {
                    return Just(history).setFailureType(to: Error.self).eraseToAnyPublisher()
                }

                // Update item's average price
                return self.updateAveragePrice(for: itemId)
                    .map { _ in history }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func updateAveragePrice(for itemId: UUID) -> AnyPublisher<Void, Error> {
        return priceHistoryRepository.fetchPriceHistory(for: itemId)
            .flatMap { [weak self] history -> AnyPublisher<Void, Error> in
                guard let self = self, !history.isEmpty else {
                    return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
                }

                // Calculate new average (weighted towards recent prices)
                let recentPrices = history.prefix(10) // Last 10 prices
                let total = recentPrices.reduce(Decimal(0)) { $0 + $1.price }
                let average = total / Decimal(recentPrices.count)

                return self.groceryItemRepository.fetchItem(byId: itemId)
                    .compactMap { $0 }
                    .flatMap { item -> AnyPublisher<Void, Error> in
                        var updatedItem = item
                        updatedItem.averagePrice = average
                        updatedItem.updatedAt = Date()

                        return self.groceryItemRepository.updateItem(updatedItem)
                            .map { _ in () }
                            .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
