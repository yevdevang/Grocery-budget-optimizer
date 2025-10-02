# Phase 4: ML Integration - Connecting Intelligence with Features

## 📋 Overview

Integrate the 4 ML models with core features to create intelligent, automated experiences. This phase brings AI-powered recommendations and predictions into the user workflow.

**Duration**: 1 week
**Dependencies**: Phase 2 (ML Models), Phase 3 (Core Features)

---

## 🎯 Objectives

- ✅ Integrate Shopping List Generator with shopping lists
- ✅ Connect Purchase Predictor with item tracking
- ✅ Integrate Price Optimizer with purchases
- ✅ Connect Expiration Predictor with inventory
- ✅ Create ML coordinator for orchestrating predictions
- ✅ Implement feedback loop for model improvement
- ✅ Add ML-powered use cases

---

## 🤖 Integration 1: Smart Shopping List Generation

### 1.1 Generate Smart Shopping List Use Case

Create `Domain/UseCases/ShoppingList/GenerateSmartShoppingListUseCase.swift`:

```swift
import Foundation
import Combine

protocol GenerateSmartShoppingListUseCaseProtocol {
    func execute(
        budget: Decimal,
        preferences: [String: Double],
        days: Int
    ) -> AnyPublisher<ShoppingList, Error>
}

class GenerateSmartShoppingListUseCase: GenerateSmartShoppingListUseCaseProtocol {
    private let shoppingListGenerator: ShoppingListGeneratorService
    private let purchaseRepository: PurchaseRepositoryProtocol
    private let groceryItemRepository: GroceryItemRepositoryProtocol
    private let shoppingListRepository: ShoppingListRepositoryProtocol
    private let purchasePredictor: PurchasePredictionService

    init(
        shoppingListGenerator: ShoppingListGeneratorService,
        purchaseRepository: PurchaseRepositoryProtocol,
        groceryItemRepository: GroceryItemRepositoryProtocol,
        shoppingListRepository: ShoppingListRepositoryProtocol,
        purchasePredictor: PurchasePredictionService
    ) {
        self.shoppingListGenerator = shoppingListGenerator
        self.purchaseRepository = purchaseRepository
        self.groceryItemRepository = groceryItemRepository
        self.shoppingListRepository = shoppingListRepository
        self.purchasePredictor = purchasePredictor
    }

    func execute(
        budget: Decimal,
        preferences: [String: Double],
        days: Int
    ) -> AnyPublisher<ShoppingList, Error> {

        // Step 1: Get purchase history
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -90, to: endDate) ?? endDate

        return purchaseRepository.fetchPurchases(from: startDate, to: endDate)
            .flatMap { [weak self] purchases -> AnyPublisher<[GroceryItem], Error> in
                guard let self = self else {
                    return Fail(error: MLIntegrationError.unknown).eraseToAnyPublisher()
                }

                // Get unique grocery items from purchases
                let itemIds = Set(purchases.map { $0.groceryItemId })
                return self.fetchGroceryItems(ids: Array(itemIds))
            }
            .flatMap { [weak self] items -> AnyPublisher<[ShoppingListRecommendation], Error> in
                guard let self = self else {
                    return Fail(error: MLIntegrationError.unknown).eraseToAnyPublisher()
                }

                // Step 2: Generate recommendations using ML
                let householdSize = UserDefaults.standard.integer(forKey: "householdSize")

                let result = self.shoppingListGenerator.generateShoppingList(
                    budget: budget,
                    householdSize: max(1, householdSize),
                    previousPurchases: items,
                    preferences: preferences
                )

                switch result {
                case .success(let recommendations):
                    return Just(recommendations)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                case .failure(let error):
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            .flatMap { [weak self] recommendations -> AnyPublisher<ShoppingList, Error> in
                guard let self = self else {
                    return Fail(error: MLIntegrationError.unknown).eraseToAnyPublisher()
                }

                // Step 3: Convert recommendations to shopping list
                return self.createShoppingListFromRecommendations(
                    recommendations: recommendations,
                    budget: budget,
                    days: days
                )
            }
            .eraseToAnyPublisher()
    }

    private func fetchGroceryItems(ids: [UUID]) -> AnyPublisher<[GroceryItem], Error> {
        let publishers = ids.map { id in
            groceryItemRepository.fetchItem(byId: id)
        }

        return Publishers.MergeMany(publishers)
            .collect()
            .map { items in
                items.compactMap { $0 }
            }
            .eraseToAnyPublisher()
    }

    private func createShoppingListFromRecommendations(
        recommendations: [ShoppingListRecommendation],
        budget: Decimal,
        days: Int
    ) -> AnyPublisher<ShoppingList, Error> {

        return groceryItemRepository.fetchAllItems()
            .flatMap { [weak self] allItems -> AnyPublisher<ShoppingList, Error> in
                guard let self = self else {
                    return Fail(error: MLIntegrationError.unknown).eraseToAnyPublisher()
                }

                let itemMap = Dictionary(uniqueKeysWithValues: allItems.map { ($0.name, $0) })

                let shoppingListItems = recommendations.compactMap { rec -> ShoppingListItem? in
                    guard let groceryItem = itemMap[rec.itemName] else { return nil }

                    return ShoppingListItem(
                        groceryItemId: groceryItem.id,
                        quantity: rec.quantity,
                        estimatedPrice: rec.estimatedPrice
                    )
                }

                let shoppingList = ShoppingList(
                    id: UUID(),
                    name: "Smart List - \(Date().formatted(style: .short))",
                    budgetAmount: budget,
                    items: shoppingListItems,
                    createdAt: Date(),
                    updatedAt: Date(),
                    isCompleted: false,
                    completedAt: nil
                )

                return self.shoppingListRepository.createShoppingList(shoppingList)
            }
            .eraseToAnyPublisher()
    }
}

enum MLIntegrationError: Error {
    case unknown
    case modelFailed
    case insufficientData
}
```

---

## 📊 Integration 2: Purchase Prediction

### 2.1 Get Purchase Predictions Use Case

Create `Domain/UseCases/Prediction/GetPurchasePredictionsUseCase.swift`:

```swift
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

                let result = self.purchasePredictor.predictNextPurchase(
                    for: item,
                    history: purchases
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

struct ItemPurchasePrediction {
    let item: GroceryItem
    let prediction: PurchasePrediction
}
```

### 2.2 Auto-Add Items to Shopping List

Create `Domain/UseCases/Prediction/AutoAddPredictedItemsUseCase.swift`:

```swift
import Foundation
import Combine

protocol AutoAddPredictedItemsUseCaseProtocol {
    func execute(to shoppingListId: UUID) -> AnyPublisher<ShoppingList, Error>
}

class AutoAddPredictedItemsUseCase: AutoAddPredictedItemsUseCaseProtocol {
    private let getPredictions: GetPurchasePredictionsUseCaseProtocol
    private let addItem: AddItemToShoppingListUseCaseProtocol
    private let shoppingListRepository: ShoppingListRepositoryProtocol

    init(
        getPredictions: GetPurchasePredictionsUseCaseProtocol,
        addItem: AddItemToShoppingListUseCaseProtocol,
        shoppingListRepository: ShoppingListRepositoryProtocol
    ) {
        self.getPredictions = getPredictions
        self.addItem = addItem
        self.shoppingListRepository = shoppingListRepository
    }

    func execute(to shoppingListId: UUID) -> AnyPublisher<ShoppingList, Error> {
        return getPredictions.execute()
            .flatMap { [weak self] predictions -> AnyPublisher<ShoppingList, Error> in
                guard let self = self else {
                    return Fail(error: MLIntegrationError.unknown).eraseToAnyPublisher()
                }

                // Filter to high-confidence, imminent predictions
                let itemsToAdd = predictions.filter {
                    $0.prediction.daysUntilPurchase <= 3 &&
                    $0.prediction.confidence >= 0.7
                }

                guard !itemsToAdd.isEmpty else {
                    return self.shoppingListRepository.fetchShoppingList(byId: shoppingListId)
                        .compactMap { $0 }
                        .eraseToAnyPublisher()
                }

                // Add each predicted item
                let addPublishers = itemsToAdd.map { prediction in
                    let shoppingItem = ShoppingListItem(
                        groceryItemId: prediction.item.id,
                        quantity: prediction.prediction.recommendedQuantity,
                        estimatedPrice: prediction.item.averagePrice
                    )

                    return self.addItem.execute(listId: shoppingListId, item: shoppingItem)
                }

                // Chain all additions
                return Publishers.MergeMany(addPublishers)
                    .collect()
                    .map { lists in lists.last }
                    .compactMap { $0 }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
```

---

## 💰 Integration 3: Price Intelligence

### 3.1 Get Price Recommendations Use Case

Create `Domain/UseCases/Price/GetPriceRecommendationsUseCase.swift`:

```swift
import Foundation
import Combine

protocol GetPriceRecommendationsUseCaseProtocol {
    func execute(for shoppingListId: UUID) -> AnyPublisher<[ItemPriceRecommendation], Error>
}

class GetPriceRecommendationsUseCase: GetPriceRecommendationsUseCaseProtocol {
    private let priceOptimizer: PriceOptimizationService
    private let shoppingListRepository: ShoppingListRepositoryProtocol
    private let groceryItemRepository: GroceryItemRepositoryProtocol
    private let priceHistoryRepository: PriceHistoryRepositoryProtocol

    init(
        priceOptimizer: PriceOptimizationService,
        shoppingListRepository: ShoppingListRepositoryProtocol,
        groceryItemRepository: GroceryItemRepositoryProtocol,
        priceHistoryRepository: PriceHistoryRepositoryProtocol
    ) {
        self.priceOptimizer = priceOptimizer
        self.shoppingListRepository = shoppingListRepository
        self.groceryItemRepository = groceryItemRepository
        self.priceHistoryRepository = priceHistoryRepository
    }

    func execute(for shoppingListId: UUID)
        -> AnyPublisher<[ItemPriceRecommendation], Error> {

        return shoppingListRepository.fetchShoppingList(byId: shoppingListId)
            .compactMap { $0 }
            .flatMap { [weak self] shoppingList -> AnyPublisher<[ItemPriceRecommendation], Error> in
                guard let self = self else {
                    return Fail(error: MLIntegrationError.unknown).eraseToAnyPublisher()
                }

                let recommendationPublishers = shoppingList.items.map { item in
                    self.getRecommendationForItem(item)
                }

                return Publishers.MergeMany(recommendationPublishers)
                    .collect()
                    .map { recommendations in
                        recommendations.compactMap { $0 }
                            .sorted { $0.potentialSavings > $1.potentialSavings }
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func getRecommendationForItem(_ shoppingItem: ShoppingListItem)
        -> AnyPublisher<ItemPriceRecommendation?, Error> {

        return groceryItemRepository.fetchItem(byId: shoppingItem.groceryItemId)
            .compactMap { $0 }
            .flatMap { [weak self] groceryItem -> AnyPublisher<ItemPriceRecommendation?, Error> in
                guard let self = self else {
                    return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
                }

                return self.priceHistoryRepository.fetchPriceHistory(for: groceryItem.id)
                    .map { [weak self] history -> ItemPriceRecommendation? in
                        guard let self = self, !history.isEmpty else { return nil }

                        let analysis = self.priceOptimizer.analyzePrice(
                            for: groceryItem,
                            currentPrice: shoppingItem.estimatedPrice,
                            history: history
                        )

                        let bestTime = self.priceOptimizer.predictBestTimeToBuy(
                            item: groceryItem,
                            history: history
                        )

                        let potentialSavings = shoppingItem.quantity *
                            (shoppingItem.estimatedPrice - analysis.averagePrice)

                        return ItemPriceRecommendation(
                            item: groceryItem,
                            shoppingItem: shoppingItem,
                            analysis: analysis,
                            bestTimeToBuy: bestTime,
                            potentialSavings: potentialSavings
                        )
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}

struct ItemPriceRecommendation {
    let item: GroceryItem
    let shoppingItem: ShoppingListItem
    let analysis: PriceAnalysis
    let bestTimeToBuy: BestTimePrediction
    let potentialSavings: Decimal

    var shouldBuyNow: Bool {
        analysis.isGoodDeal || potentialSavings < 0
    }

    var recommendation: String {
        if shouldBuyNow {
            return "Good time to buy! \(analysis.recommendation)"
        } else {
            return "Consider waiting. Best day: \(bestTimeToBuy.bestDayName)"
        }
    }
}
```

### 3.2 Record Price and Update History

Create `Domain/UseCases/Price/RecordPriceUseCase.swift`:

```swift
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

        return priceHistoryRepository.createPriceHistory(priceHistory)
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
```

---

## 🥗 Integration 4: Expiration Tracking

### 4.1 Track Expiration Use Case

Create `Domain/UseCases/Expiration/TrackExpirationUseCase.swift`:

```swift
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
                    for: item,
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
```

### 4.2 Get Expiring Items Use Case

Create `Domain/UseCases/Expiration/GetExpiringItemsUseCase.swift`:

```swift
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
            .map { item -> ExpiringItemInfo? in
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

struct ExpiringItemInfo {
    let item: GroceryItem
    let tracker: ExpirationTracker
    let daysRemaining: Int
    let urgency: ExpirationUrgency
}
```

---

## 🎯 ML Coordinator

Create `Data/MLModels/MLCoordinator.swift`:

```swift
import Foundation
import Combine

class MLCoordinator {
    static let shared = MLCoordinator()

    private let shoppingListGenerator: ShoppingListGeneratorService
    private let purchasePredictor: PurchasePredictionService
    private let priceOptimizer: PriceOptimizationService
    private let expirationPredictor: ExpirationPredictionService

    private init() {
        self.shoppingListGenerator = ShoppingListGeneratorService()
        self.purchasePredictor = PurchasePredictionService()
        self.priceOptimizer = PriceOptimizationService()
        self.expirationPredictor = ExpirationPredictionService()
    }

    // Provide access to services
    func getShoppingListGenerator() -> ShoppingListGeneratorService {
        return shoppingListGenerator
    }

    func getPurchasePredictor() -> PurchasePredictionService {
        return purchasePredictor
    }

    func getPriceOptimizer() -> PriceOptimizationService {
        return priceOptimizer
    }

    func getExpirationPredictor() -> ExpirationPredictionService {
        return expirationPredictor
    }

    // Warmup models on app launch
    func warmupModels() {
        print("Warming up ML models...")
        // Perform dummy predictions to load models into memory
        // This improves first-use performance
    }
}
```

---

## ✅ Acceptance Criteria

### Phase 4 Complete When:

- ✅ Smart shopping list generation working end-to-end
- ✅ Purchase predictions displayed and actionable
- ✅ Price recommendations integrated with shopping lists
- ✅ Expiration tracking with notifications functional
- ✅ ML coordinator managing all models
- ✅ Feedback mechanisms for model improvement
- ✅ Performance acceptable (<500ms for predictions)
- ✅ Error handling comprehensive
- ✅ Integration tests passing (>75% coverage)

---

## ⚠️ Potential Challenges

### Challenge 1: Cold Start
**Problem**: New users have no data for predictions
**Solution**: Use category-based defaults; manual input options

### Challenge 2: Model Performance
**Problem**: ML inference slow on older devices
**Solution**: Async predictions; caching; background processing

### Challenge 3: Prediction Accuracy
**Problem**: Users reject ML suggestions
**Solution**: Learn from feedback; adjustable confidence thresholds

### Challenge 4: Data Quality
**Problem**: Inconsistent user data affects predictions
**Solution**: Data validation; outlier detection; user feedback

---

## 🚀 Next Steps

Proceed to:
- **[Phase 5: UI/UX](05-PHASE-5-UI-UX.md)** - Build SwiftUI screens and user interface

---

## 📚 Resources

- [Core ML Best Practices](https://developer.apple.com/documentation/coreml/core_ml_api/integrating_a_core_ml_model_into_your_app)
- [Background Tasks](https://developer.apple.com/documentation/backgroundtasks)
- [Combine Advanced Patterns](https://developer.apple.com/documentation/combine)
