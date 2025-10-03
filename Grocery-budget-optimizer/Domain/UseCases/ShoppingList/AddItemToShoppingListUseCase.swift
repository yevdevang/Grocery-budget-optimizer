import Foundation
import Combine

protocol AddItemToShoppingListUseCaseProtocol {
    func execute(
        listId: UUID,
        item: ShoppingListItem
    ) -> AnyPublisher<ShoppingList, Error>
}

class AddItemToShoppingListUseCase: AddItemToShoppingListUseCaseProtocol {
    private let shoppingListRepository: ShoppingListRepositoryProtocol
    private let groceryItemRepository: GroceryItemRepositoryProtocol

    init(
        shoppingListRepository: ShoppingListRepositoryProtocol,
        groceryItemRepository: GroceryItemRepositoryProtocol
    ) {
        self.shoppingListRepository = shoppingListRepository
        self.groceryItemRepository = groceryItemRepository
    }

    func execute(
        listId: UUID,
        item: ShoppingListItem
    ) -> AnyPublisher<ShoppingList, Error> {

        return shoppingListRepository.fetchShoppingList(byId: listId)
            .flatMap { [weak self] shoppingList -> AnyPublisher<ShoppingList, Error> in
                guard let self = self, var shoppingList = shoppingList else {
                    return Fail(error: UseCaseError.notFound).eraseToAnyPublisher()
                }

                // Check if item already exists
                if let existingIndex = shoppingList.items.firstIndex(where: {
                    $0.groceryItemId == item.groceryItemId
                }) {
                    // Update quantity
                    shoppingList.items[existingIndex].quantity += item.quantity
                } else {
                    // Add new item
                    shoppingList.items.append(item)
                }

                // Validate budget
                if shoppingList.totalEstimatedCost > shoppingList.budgetAmount {
                    return Fail(error: ValidationError.budgetExceeded)
                        .eraseToAnyPublisher()
                }

                return self.shoppingListRepository.updateShoppingList(shoppingList)
            }
            .eraseToAnyPublisher()
    }
}
