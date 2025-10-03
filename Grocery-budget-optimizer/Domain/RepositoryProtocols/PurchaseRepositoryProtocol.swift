import Foundation
import Combine

protocol PurchaseRepositoryProtocol {
    func createPurchase(_ purchase: Purchase) -> AnyPublisher<Purchase, Error>
    func fetchPurchase(byId id: UUID) -> AnyPublisher<Purchase?, Error>
    func fetchPurchases(from startDate: Date, to endDate: Date) -> AnyPublisher<[Purchase], Error>
    func fetchPurchases(for groceryItemId: UUID) -> AnyPublisher<[Purchase], Error>
    func fetchAllPurchases() -> AnyPublisher<[Purchase], Error>
    func deletePurchase(byId id: UUID) -> AnyPublisher<Void, Error>
}
