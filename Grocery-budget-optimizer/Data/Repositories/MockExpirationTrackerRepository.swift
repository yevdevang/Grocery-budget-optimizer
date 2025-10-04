import Foundation
import Combine

class MockExpirationTrackerRepository: ExpirationTrackerRepositoryProtocol {
    private var trackers: [ExpirationTracker] = []

    func createTracker(_ tracker: ExpirationTracker) -> AnyPublisher<ExpirationTracker, Error> {
        trackers.append(tracker)
        return Just(tracker)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func fetchTracker(byId id: UUID) -> AnyPublisher<ExpirationTracker?, Error> {
        let tracker = trackers.first { $0.id == id }
        return Just(tracker)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func fetchActiveTrackers() -> AnyPublisher<[ExpirationTracker], Error> {
        let active = trackers.filter { !$0.isConsumed && !$0.isWasted }
        return Just(active)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func fetchExpiringSoon(days: Int) -> AnyPublisher<[ExpirationTracker], Error> {
        let threshold = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        let expiring = trackers.filter { !$0.isConsumed && !$0.isWasted && $0.estimatedExpirationDate <= threshold }
        return Just(expiring)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func updateTracker(_ tracker: ExpirationTracker) -> AnyPublisher<ExpirationTracker, Error> {
        if let index = trackers.firstIndex(where: { $0.id == tracker.id }) {
            trackers[index] = tracker
        }
        return Just(tracker)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func markAsConsumed(trackerId: UUID) -> AnyPublisher<ExpirationTracker, Error> {
        if let index = trackers.firstIndex(where: { $0.id == trackerId }) {
            var tracker = trackers[index]
            tracker.isConsumed = true
            tracker.consumedAt = Date()
            trackers[index] = tracker
            return Just(tracker)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        return Fail(error: NSError(domain: "TrackerNotFound", code: 404))
            .eraseToAnyPublisher()
    }

    func markAsWasted(trackerId: UUID) -> AnyPublisher<ExpirationTracker, Error> {
        if let index = trackers.firstIndex(where: { $0.id == trackerId }) {
            var tracker = trackers[index]
            tracker.isWasted = true
            tracker.wastedAt = Date()
            trackers[index] = tracker
            return Just(tracker)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        return Fail(error: NSError(domain: "TrackerNotFound", code: 404))
            .eraseToAnyPublisher()
    }

    func deleteTracker(byId id: UUID) -> AnyPublisher<Void, Error> {
        trackers.removeAll { $0.id == id }
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
