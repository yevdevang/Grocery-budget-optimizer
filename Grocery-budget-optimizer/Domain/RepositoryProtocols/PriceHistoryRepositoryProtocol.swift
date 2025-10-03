import Foundation
import Combine

protocol PriceHistoryRepositoryProtocol {
    func addPriceHistory(_ priceHistory: PriceHistory) -> AnyPublisher<PriceHistory, Error>
    func fetchPriceHistory(for groceryItemId: UUID) -> AnyPublisher<[PriceHistory], Error>
    func fetchPriceHistory(for groceryItemId: UUID, limit: Int) -> AnyPublisher<[PriceHistory], Error>
    func deletePriceHistory(byId id: UUID) -> AnyPublisher<Void, Error>
}
