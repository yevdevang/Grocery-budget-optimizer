import Foundation
import Combine

protocol MarkItemAsPurchasedUseCaseProtocol {
    func execute(
        listId: UUID,
        itemId: UUID,
        actualPrice: Decimal,
        groceryItem: GroceryItem
    ) -> AnyPublisher<ShoppingList, Error>
}

class MarkItemAsPurchasedUseCase: MarkItemAsPurchasedUseCaseProtocol {
    private let shoppingListRepository: ShoppingListRepositoryProtocol
    private let purchaseRepository: PurchaseRepositoryProtocol

    init(
        shoppingListRepository: ShoppingListRepositoryProtocol,
        purchaseRepository: PurchaseRepositoryProtocol
    ) {
        self.shoppingListRepository = shoppingListRepository
        self.purchaseRepository = purchaseRepository
    }

    func execute(
        listId: UUID,
        itemId: UUID,
        actualPrice: Decimal,
        groceryItem: GroceryItem
    ) -> AnyPublisher<ShoppingList, Error> {

        return shoppingListRepository.fetchShoppingList(byId: listId)
            .flatMap { [weak self] shoppingList -> AnyPublisher<ShoppingList, Error> in
                guard let self = self, var shoppingList = shoppingList else {
                    return Fail(error: UseCaseError.notFound).eraseToAnyPublisher()
                }

                guard let itemIndex = shoppingList.items.firstIndex(where: {
                    $0.id == itemId
                }) else {
                    return Fail(error: UseCaseError.notFound).eraseToAnyPublisher()
                }

                // Update item
                shoppingList.items[itemIndex].isPurchased = true
                shoppingList.items[itemIndex].purchasedAt = Date()
                shoppingList.items[itemIndex].actualPrice = actualPrice

                // Create purchase record
                let item = shoppingList.items[itemIndex]
                let purchase = Purchase(
                    groceryItemId: item.groceryItemId,
                    groceryItem: groceryItem,
                    quantity: item.quantity,
                    price: actualPrice,
                    totalCost: actualPrice * item.quantity,
                    purchaseDate: Date(),
                    storeName: nil
                )

                // Save purchase and update list
                return self.purchaseRepository.createPurchase(purchase)
                    .flatMap { _ in
                        self.shoppingListRepository.updateShoppingList(shoppingList)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
