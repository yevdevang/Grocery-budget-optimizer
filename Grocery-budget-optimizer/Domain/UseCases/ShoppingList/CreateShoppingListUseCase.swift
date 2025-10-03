import Foundation
import Combine

protocol CreateShoppingListUseCaseProtocol {
    func execute(_ shoppingList: ShoppingList) -> AnyPublisher<ShoppingList, Error>
}

class CreateShoppingListUseCase: CreateShoppingListUseCaseProtocol {
    private let repository: ShoppingListRepositoryProtocol

    init(repository: ShoppingListRepositoryProtocol) {
        self.repository = repository
    }

    func execute(_ shoppingList: ShoppingList) -> AnyPublisher<ShoppingList, Error> {
        // Validation
        guard !shoppingList.name.isEmpty else {
            return Fail(error: ValidationError.emptyName)
                .eraseToAnyPublisher()
        }

        guard shoppingList.budgetAmount > 0 else {
            return Fail(error: ValidationError.invalidBudget)
                .eraseToAnyPublisher()
        }

        return repository.createShoppingList(shoppingList)
    }
}
