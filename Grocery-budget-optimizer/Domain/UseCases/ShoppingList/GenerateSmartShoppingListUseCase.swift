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
        print("🎯 GenerateSmartShoppingListUseCase.execute() called with budget: \(budget)")

        // Step 1: Get RECENT purchase history (last 14 days only to avoid over-filtering)
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -14, to: endDate) ?? endDate

        return purchaseRepository.fetchPurchases(from: startDate, to: endDate)
            .flatMap { [weak self] purchases -> AnyPublisher<[GroceryItem], Error> in
                guard let self = self else {
                    return Fail(error: MLIntegrationError.unknown).eraseToAnyPublisher()
                }

                print("📊 Found \(purchases.count) purchases in last 14 days")
                // Get unique grocery items from purchases
                let itemIds = Set(purchases.map { $0.groceryItemId })
                
                // Limit to most recent 10 unique items to avoid over-filtering
                let limitedItemIds = Array(itemIds).prefix(10)
                print("🔍 Using \(limitedItemIds.count) unique items from recent purchases")
                
                return self.fetchGroceryItems(ids: Array(limitedItemIds))
            }
            .flatMap { [weak self] items -> AnyPublisher<[ShoppingListRecommendation], Error> in
                guard let self = self else {
                    return Fail(error: MLIntegrationError.unknown).eraseToAnyPublisher()
                }

                print("🛒 Retrieved \(items.count) grocery items from purchase history")
                // Step 2: Generate recommendations using ML
                let householdSize = UserDefaults.standard.integer(forKey: "householdSize")

                // Convert GroceryItem to item names
                let itemNames = items.map { $0.name }

                print("🤖 Calling ML generator with \(itemNames.count) previous purchases, budget: \(budget)")
                let result = self.shoppingListGenerator.generateShoppingList(
                    budget: budget,
                    householdSize: max(1, householdSize),
                    previousPurchases: itemNames,
                    preferences: preferences
                )

                switch result {
                case .success(let recommendations):
                    print("✅ ML generator returned \(recommendations.count) recommendations")
                    return Just(recommendations)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                case .failure(let error):
                    print("❌ ML generator failed: \(error)")
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

        print("🔄 Converting \(recommendations.count) recommendations to shopping list")
        return groceryItemRepository.fetchAllItems()
            .flatMap { [weak self] allItems -> AnyPublisher<ShoppingList, Error> in
                guard let self = self else {
                    return Fail(error: MLIntegrationError.unknown).eraseToAnyPublisher()
                }

                print("📦 Fetched \(allItems.count) items from grocery repository")

                if allItems.isEmpty {
                    print("⚠️ WARNING: No grocery items in database! This will prevent matching.")
                    print("⚠️ The app may need to be deleted and reinstalled to trigger seeding.")
                }

                // Create dictionary, handling duplicate names by keeping the first occurrence
                var itemMap: [String: GroceryItem] = [:]
                for item in allItems {
                    if itemMap[item.name] == nil {
                        itemMap[item.name] = item
                    } else {
                        print("⚠️ Duplicate item name found: '\(item.name)' - keeping first occurrence")
                    }
                }

                print("📋 Available items in database: \(itemMap.keys.sorted())")
                print("🎯 ML Recommendations:")
                recommendations.forEach { rec in
                    print("  - '\(rec.itemName)' (qty: \(rec.quantity), price: \(rec.estimatedPrice))")
                }

                let shoppingListItems = recommendations.compactMap { rec -> ShoppingListItem? in
                    guard let groceryItem = itemMap[rec.itemName] else {
                        print("⚠️ Could not find grocery item for recommendation: '\(rec.itemName)'")
                        print("   Available items: \(itemMap.keys.sorted().joined(separator: ", "))")
                        return nil
                    }

                    print("✅ Matched recommendation '\(rec.itemName)' to grocery item")
                    return ShoppingListItem(
                        groceryItemId: groceryItem.id,
                        quantity: rec.quantity,
                        estimatedPrice: rec.estimatedPrice
                    )
                }

                print("✅ Matched \(shoppingListItems.count) out of \(recommendations.count) recommendations to grocery items")

                let shoppingList = ShoppingList(
                    id: UUID(),
                    name: "Smart List - \(Date().formatted(date: .abbreviated, time: .omitted))",
                    budgetAmount: budget,
                    items: shoppingListItems,
                    createdAt: Date(),
                    updatedAt: Date(),
                    isCompleted: false,
                    completedAt: nil
                )

                print("💾 Saving shopping list with \(shoppingList.items.count) items")
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
