import Foundation
import Combine

protocol ExpirationTrackerRepositoryProtocol {
    func createTracker(_ tracker: ExpirationTracker) -> AnyPublisher<ExpirationTracker, Error>
    func updateTracker(_ tracker: ExpirationTracker) -> AnyPublisher<ExpirationTracker, Error>
    func fetchTracker(byId id: UUID) -> AnyPublisher<ExpirationTracker?, Error>
    func fetchActiveTrackers() -> AnyPublisher<[ExpirationTracker], Error>
    func fetchExpiringSoon(days: Int) -> AnyPublisher<[ExpirationTracker], Error>
    func markAsConsumed(trackerId: UUID) -> AnyPublisher<ExpirationTracker, Error>
    func markAsWasted(trackerId: UUID) -> AnyPublisher<ExpirationTracker, Error>
    func deleteTracker(byId id: UUID) -> AnyPublisher<Void, Error>
}
