import Foundation
import Combine

protocol GetPurchasePredictionsUseCaseProtocol {
    func execute() -> AnyPublisher<[ItemPurchasePrediction], Error>
}

class GetPurchasePredictionsUseCase: GetPurchasePredictionsUseCaseProtocol {
    private let purchasePredictor: PurchasePredictionService
    private let purchaseRepository: PurchaseRepositoryProtocol
    private let groceryItemRepository: GroceryItemRepositoryProtocol
    private let notificationManager: NotificationManager

    init(
        purchasePredictor: PurchasePredictionService,
        purchaseRepository: PurchaseRepositoryProtocol,
        groceryItemRepository: GroceryItemRepositoryProtocol,
        notificationManager: NotificationManager
    ) {
        self.purchasePredictor = purchasePredictor
        self.purchaseRepository = purchaseRepository
        self.groceryItemRepository = groceryItemRepository
        self.notificationManager = notificationManager
    }

    func execute() -> AnyPublisher<[ItemPurchasePrediction], Error> {
        // Get all items and their purchase history
        return groceryItemRepository.fetchAllItems()
            .flatMap { [weak self] items -> AnyPublisher<[ItemPurchasePrediction], Error> in
                guard let self = self else {
                    return Fail(error: MLIntegrationError.unknown).eraseToAnyPublisher()
                }

                let predictionPublishers = items.map { item in
                    self.predictForItem(item)
                }

                return Publishers.MergeMany(predictionPublishers)
                    .collect()
                    .map { predictions in
                        predictions.compactMap { $0 }
                            .filter { $0.prediction.daysUntilPurchase <= 7 } // Next week
                            .sorted { $0.prediction.daysUntilPurchase < $1.prediction.daysUntilPurchase }
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func predictForItem(_ item: GroceryItem)
        -> AnyPublisher<ItemPurchasePrediction?, Error> {

        return purchaseRepository.fetchPurchases(for: item.id)
            .map { [weak self] purchases -> ItemPurchasePrediction? in
                guard let self = self, purchases.count >= 2 else { return nil }

                // Convert Purchase to MockPurchase
                let mockPurchases = purchases.map { purchase in
                    MockPurchase(
                        itemName: item.name,
                        category: item.category,
                        quantity: purchase.quantity,
                        purchaseDate: purchase.purchaseDate,
                        storeName: purchase.storeName
                    )
                }

                let result = self.purchasePredictor.predictNextPurchase(
                    for: item.name,
                    category: item.category,
                    history: mockPurchases
                )

                switch result {
                case .success(let prediction):
                    // Schedule notification if needed soon
                    if prediction.daysUntilPurchase <= 2 {
                        self.notificationManager.schedulePurchaseReminder(
                            for: item,
                            predictedDate: prediction.predictedDate
                        )
                    }

                    return ItemPurchasePrediction(
                        item: item,
                        prediction: prediction
                    )

                case .failure:
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }
}

struct ItemPurchasePrediction: Identifiable {
    var id: UUID { item.id }
    let item: GroceryItem
    let prediction: PurchasePrediction
}
