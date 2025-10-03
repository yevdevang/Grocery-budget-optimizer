import Foundation
import Combine

protocol GetItemPriceHistoryUseCaseProtocol {
    func execute(itemId: UUID) -> AnyPublisher<[PriceHistory], Error>
}

class GetItemPriceHistoryUseCase: GetItemPriceHistoryUseCaseProtocol {
    private let priceHistoryRepository: PriceHistoryRepositoryProtocol

    init(priceHistoryRepository: PriceHistoryRepositoryProtocol) {
        self.priceHistoryRepository = priceHistoryRepository
    }

    func execute(itemId: UUID) -> AnyPublisher<[PriceHistory], Error> {
        return priceHistoryRepository.fetchPriceHistory(for: itemId)
            .map { history in
                history.sorted { $0.recordedAt > $1.recordedAt }
            }
            .eraseToAnyPublisher()
    }
}
