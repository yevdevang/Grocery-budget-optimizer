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
