import Foundation
import CoreData
import Combine

class ShoppingListRepository: ShoppingListRepositoryProtocol {
    private let coreDataStack: CoreDataStack
    private let context: NSManagedObjectContext

    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
        self.context = coreDataStack.viewContext
    }

    func createShoppingList(_ list: ShoppingList) -> AnyPublisher<ShoppingList, Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let entity = ShoppingListEntity(context: self.context)
            self.mapToEntity(list, entity: entity)

            do {
                try self.context.save()
                promise(.success(list))
            } catch {
                promise(.failure(RepositoryError.saveFailed))
            }
        }
        .eraseToAnyPublisher()
    }

    func updateShoppingList(_ list: ShoppingList) -> AnyPublisher<ShoppingList, Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let request: NSFetchRequest<ShoppingListEntity> = ShoppingListEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", list.id as CVarArg)
            request.fetchLimit = 1

            do {
                let entities = try self.context.fetch(request)
                guard let entity = entities.first else {
                    promise(.failure(RepositoryError.notFound))
                    return
                }

                self.mapToEntity(list, entity: entity)
                try self.context.save()
                promise(.success(list))
            } catch {
                promise(.failure(RepositoryError.saveFailed))
            }
        }
        .eraseToAnyPublisher()
    }

    func deleteShoppingList(byId id: UUID) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let request: NSFetchRequest<ShoppingListEntity> = ShoppingListEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            do {
                let entities = try self.context.fetch(request)
                guard let entity = entities.first else {
                    promise(.failure(RepositoryError.notFound))
                    return
                }

                self.context.delete(entity)
                try self.context.save()
                promise(.success(()))
            } catch {
                promise(.failure(RepositoryError.saveFailed))
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchShoppingList(byId id: UUID) -> AnyPublisher<ShoppingList?, Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let request: NSFetchRequest<ShoppingListEntity> = ShoppingListEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            do {
                let entities = try self.context.fetch(request)
                let list = entities.first.map { self.mapToDomain($0) }
                promise(.success(list))
            } catch {
                promise(.failure(RepositoryError.fetchFailed))
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchAllShoppingLists() -> AnyPublisher<[ShoppingList], Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let request: NSFetchRequest<ShoppingListEntity> = ShoppingListEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

            do {
                let entities = try self.context.fetch(request)
                let lists = entities.map { self.mapToDomain($0) }
                promise(.success(lists))
            } catch {
                promise(.failure(RepositoryError.fetchFailed))
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchActiveShoppingLists() -> AnyPublisher<[ShoppingList], Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let request: NSFetchRequest<ShoppingListEntity> = ShoppingListEntity.fetchRequest()
            request.predicate = NSPredicate(format: "isCompleted == NO")
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

            do {
                let entities = try self.context.fetch(request)
                let lists = entities.map { self.mapToDomain($0) }
                promise(.success(lists))
            } catch {
                promise(.failure(RepositoryError.fetchFailed))
            }
        }
        .eraseToAnyPublisher()
    }

    func markAsCompleted(shoppingListId: UUID) -> AnyPublisher<ShoppingList, Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let request: NSFetchRequest<ShoppingListEntity> = ShoppingListEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", shoppingListId as CVarArg)
            request.fetchLimit = 1

            do {
                let entities = try self.context.fetch(request)
                guard let entity = entities.first else {
                    promise(.failure(RepositoryError.notFound))
                    return
                }

                entity.isCompleted = true
                entity.completedAt = Date()

                try self.context.save()
                let list = self.mapToDomain(entity)
                promise(.success(list))
            } catch {
                promise(.failure(RepositoryError.saveFailed))
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Mapping

    private func mapToDomain(_ entity: ShoppingListEntity) -> ShoppingList {
        let items = (entity.items as? Set<ShoppingListItemEntity>)?
            .map { itemEntity in
                ShoppingListItem(
                    id: itemEntity.id ?? UUID(),
                    groceryItemId: itemEntity.groceryItem?.id ?? UUID(),
                    quantity: itemEntity.quantity as Decimal? ?? 0,
                    estimatedPrice: itemEntity.estimatedPrice as Decimal? ?? 0,
                    isPurchased: itemEntity.isPurchased,
                    purchasedAt: itemEntity.purchasedAt,
                    actualPrice: itemEntity.actualPrice as Decimal?
                )
            } ?? []

        return ShoppingList(
            id: entity.id ?? UUID(),
            name: entity.name ?? "",
            budgetAmount: entity.budgetAmount as Decimal? ?? 0,
            items: items,
            createdAt: entity.createdAt ?? Date(),
            updatedAt: entity.updatedAt ?? Date(),
            isCompleted: entity.isCompleted,
            completedAt: entity.completedAt
        )
    }

    private func mapToEntity(_ domain: ShoppingList, entity: ShoppingListEntity) {
        entity.id = domain.id
        entity.name = domain.name
        entity.budgetAmount = domain.budgetAmount as NSDecimalNumber
        entity.createdAt = domain.createdAt
        entity.updatedAt = domain.updatedAt
        entity.isCompleted = domain.isCompleted
        entity.completedAt = domain.completedAt

        // Clear existing items
        if let items = entity.items as? Set<ShoppingListItemEntity> {
            items.forEach { context.delete($0) }
        }

        // Add new items
        let itemEntities = Set(domain.items.map { item -> ShoppingListItemEntity in
            let itemEntity = ShoppingListItemEntity(context: context)
            itemEntity.id = item.id
            itemEntity.quantity = item.quantity as NSDecimalNumber
            itemEntity.estimatedPrice = item.estimatedPrice as NSDecimalNumber
            itemEntity.isPurchased = item.isPurchased
            itemEntity.purchasedAt = item.purchasedAt
            itemEntity.actualPrice = item.actualPrice.map { $0 as NSDecimalNumber }
            itemEntity.shoppingList = entity

            // Fetch and link grocery item
            let groceryItemRequest: NSFetchRequest<GroceryItemEntity> = GroceryItemEntity.fetchRequest()
            groceryItemRequest.predicate = NSPredicate(format: "id == %@", item.groceryItemId as CVarArg)
            groceryItemRequest.fetchLimit = 1

            if let groceryItemEntity = try? context.fetch(groceryItemRequest).first {
                itemEntity.groceryItem = groceryItemEntity
            }

            return itemEntity
        })

        entity.items = itemEntities as NSSet
    }
}
