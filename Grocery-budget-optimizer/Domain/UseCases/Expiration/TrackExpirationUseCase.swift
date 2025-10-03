import Foundation
import Combine

protocol TrackExpirationUseCaseProtocol {
    func execute(
        itemId: UUID,
        purchaseDate: Date,
        quantity: Decimal,
        storage: String
    ) -> AnyPublisher<ExpirationTracker, Error>
}

class TrackExpirationUseCase: TrackExpirationUseCaseProtocol {
    private let expirationPredictor: ExpirationPredictionService
    private let expirationRepository: ExpirationTrackerRepositoryProtocol
    private let groceryItemRepository: GroceryItemRepositoryProtocol
    private let notificationManager: NotificationManager

    init(
        expirationPredictor: ExpirationPredictionService,
        expirationRepository: ExpirationTrackerRepositoryProtocol,
        groceryItemRepository: GroceryItemRepositoryProtocol,
        notificationManager: NotificationManager
    ) {
        self.expirationPredictor = expirationPredictor
        self.expirationRepository = expirationRepository
        self.groceryItemRepository = groceryItemRepository
        self.notificationManager = notificationManager
    }

    func execute(
        itemId: UUID,
        purchaseDate: Date,
        quantity: Decimal,
        storage: String
    ) -> AnyPublisher<ExpirationTracker, Error> {

        return groceryItemRepository.fetchItem(byId: itemId)
            .compactMap { $0 }
            .flatMap { [weak self] item -> AnyPublisher<ExpirationTracker, Error> in
                guard let self = self else {
                    return Fail(error: MLIntegrationError.unknown).eraseToAnyPublisher()
                }

                // Predict expiration
                let prediction = self.expirationPredictor.predictExpiration(
                    for: item.name,
                    category: item.category,
                    purchaseDate: purchaseDate,
                    storage: storage
                )

                // Create tracker
                let tracker = ExpirationTracker(
                    id: UUID(),
                    groceryItemId: item.id,
                    purchaseDate: purchaseDate,
                    expirationDate: prediction.predictedExpirationDate,
                    estimatedExpirationDate: prediction.predictedExpirationDate,
                    quantity: quantity,
                    remainingQuantity: quantity,
                    storageLocation: storage,
                    isConsumed: false,
                    consumedAt: nil,
                    isWasted: false,
                    wastedAt: nil
                )

                // Schedule notification
                self.notificationManager.scheduleExpirationReminder(
                    for: item,
                    expirationDate: prediction.predictedExpirationDate
                )

                return self.expirationRepository.createTracker(tracker)
            }
            .eraseToAnyPublisher()
    }
}
