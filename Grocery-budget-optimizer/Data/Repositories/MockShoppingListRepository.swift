import Foundation
import Combine

class MockShoppingListRepository: ShoppingListRepositoryProtocol {
    private var shoppingLists: [ShoppingList] = []
    private let lock = NSLock()

    func createShoppingList(_ list: ShoppingList) -> AnyPublisher<ShoppingList, Error> {
        Future { [weak self] promise in
            self?.lock.lock()
            defer { self?.lock.unlock() }

            self?.shoppingLists.append(list)
            print("✅ Mock: Saved shopping list '\(list.name)' with \(list.items.count) items")
            promise(.success(list))
        }
        .eraseToAnyPublisher()
    }

    func updateShoppingList(_ list: ShoppingList) -> AnyPublisher<ShoppingList, Error> {
        Future { [weak self] promise in
            self?.lock.lock()
            defer { self?.lock.unlock() }

            guard let index = self?.shoppingLists.firstIndex(where: { $0.id == list.id }) else {
                promise(.failure(RepositoryError.notFound))
                return
            }

            self?.shoppingLists[index] = list
            promise(.success(list))
        }
        .eraseToAnyPublisher()
    }

    func deleteShoppingList(byId id: UUID) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            self?.lock.lock()
            defer { self?.lock.unlock() }

            guard let index = self?.shoppingLists.firstIndex(where: { $0.id == id }) else {
                promise(.failure(RepositoryError.notFound))
                return
            }

            self?.shoppingLists.remove(at: index)
            promise(.success(()))
        }
        .eraseToAnyPublisher()
    }

    func fetchShoppingList(byId id: UUID) -> AnyPublisher<ShoppingList?, Error> {
        Future { [weak self] promise in
            self?.lock.lock()
            defer { self?.lock.unlock() }

            let list = self?.shoppingLists.first(where: { $0.id == id })
            promise(.success(list))
        }
        .eraseToAnyPublisher()
    }

    func fetchAllShoppingLists() -> AnyPublisher<[ShoppingList], Error> {
        Future { [weak self] promise in
            self?.lock.lock()
            defer { self?.lock.unlock() }

            let lists = self?.shoppingLists.sorted(by: { $0.createdAt > $1.createdAt }) ?? []
            promise(.success(lists))
        }
        .eraseToAnyPublisher()
    }

    func fetchActiveShoppingLists() -> AnyPublisher<[ShoppingList], Error> {
        Future { [weak self] promise in
            self?.lock.lock()
            defer { self?.lock.unlock() }

            let lists = self?.shoppingLists
                .filter { !$0.isCompleted }
                .sorted(by: { $0.createdAt > $1.createdAt }) ?? []
            promise(.success(lists))
        }
        .eraseToAnyPublisher()
    }

    func markAsCompleted(shoppingListId: UUID) -> AnyPublisher<ShoppingList, Error> {
        Future { [weak self] promise in
            self?.lock.lock()
            defer { self?.lock.unlock() }

            guard let index = self?.shoppingLists.firstIndex(where: { $0.id == shoppingListId }) else {
                promise(.failure(RepositoryError.notFound))
                return
            }

            var list = self?.shoppingLists[index]
            list?.isCompleted = true
            list?.completedAt = Date()

            if let updatedList = list {
                self?.shoppingLists[index] = updatedList
                promise(.success(updatedList))
            } else {
                promise(.failure(RepositoryError.unknown))
            }
        }
        .eraseToAnyPublisher()
    }
}
