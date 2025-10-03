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

                        // Convert PriceHistory to MockPriceHistory
                        let mockHistory = history.map { priceHistory in
                            MockPriceHistory(
                                itemName: groceryItem.name,
                                price: priceHistory.price,
                                recordedAt: priceHistory.recordedAt,
                                storeName: priceHistory.storeName,
                                location: nil
                            )
                        }

                        let analysis = self.priceOptimizer.analyzePrice(
                            for: groceryItem.name,
                            currentPrice: shoppingItem.estimatedPrice,
                            history: mockHistory
                        )

                        let bestTime = self.priceOptimizer.predictBestTimeToBuy(
                            itemName: groceryItem.name,
                            history: mockHistory
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
            return "Consider waiting. Best time: \(bestTimeToBuy.bestTimeFrame.rawValue)"
        }
    }
}
