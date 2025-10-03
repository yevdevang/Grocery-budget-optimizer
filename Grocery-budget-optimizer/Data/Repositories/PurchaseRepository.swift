import Foundation
import CoreData
import Combine

class PurchaseRepository: PurchaseRepositoryProtocol {
    private let coreDataStack: CoreDataStack
    private let context: NSManagedObjectContext

    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
        self.context = coreDataStack.viewContext
    }

    func createPurchase(_ purchase: Purchase) -> AnyPublisher<Purchase, Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let entity = PurchaseEntity(context: self.context)
            self.mapToEntity(purchase, entity: entity)

            do {
                try self.context.save()
                promise(.success(purchase))
            } catch {
                promise(.failure(RepositoryError.saveFailed))
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchPurchase(byId id: UUID) -> AnyPublisher<Purchase?, Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let request: NSFetchRequest<PurchaseEntity> = PurchaseEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            do {
                let entities = try self.context.fetch(request)
                let purchase = entities.first.flatMap { self.mapToDomain($0) }
                promise(.success(purchase))
            } catch {
                promise(.failure(RepositoryError.fetchFailed))
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchPurchases(from startDate: Date, to endDate: Date) -> AnyPublisher<[Purchase], Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let request: NSFetchRequest<PurchaseEntity> = PurchaseEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "purchaseDate >= %@ AND purchaseDate <= %@",
                startDate as NSDate,
                endDate as NSDate
            )
            request.sortDescriptors = [NSSortDescriptor(key: "purchaseDate", ascending: false)]

            do {
                let entities = try self.context.fetch(request)
                let purchases = entities.compactMap { self.mapToDomain($0) }
                promise(.success(purchases))
            } catch {
                promise(.failure(RepositoryError.fetchFailed))
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchPurchases(for groceryItemId: UUID) -> AnyPublisher<[Purchase], Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let request: NSFetchRequest<PurchaseEntity> = PurchaseEntity.fetchRequest()
            request.predicate = NSPredicate(format: "groceryItem.id == %@", groceryItemId as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "purchaseDate", ascending: false)]

            do {
                let entities = try self.context.fetch(request)
                let purchases = entities.compactMap { self.mapToDomain($0) }
                promise(.success(purchases))
            } catch {
                promise(.failure(RepositoryError.fetchFailed))
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchAllPurchases() -> AnyPublisher<[Purchase], Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let request: NSFetchRequest<PurchaseEntity> = PurchaseEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "purchaseDate", ascending: false)]

            do {
                let entities = try self.context.fetch(request)
                let purchases = entities.compactMap { self.mapToDomain($0) }
                promise(.success(purchases))
            } catch {
                promise(.failure(RepositoryError.fetchFailed))
            }
        }
        .eraseToAnyPublisher()
    }

    func deletePurchase(byId id: UUID) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let request: NSFetchRequest<PurchaseEntity> = PurchaseEntity.fetchRequest()
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

    // MARK: - Mapping

    private func mapToDomain(_ entity: PurchaseEntity) -> Purchase? {
        guard let groceryItemEntity = entity.groceryItem else { return nil }

        let groceryItem = GroceryItem(
            id: groceryItemEntity.id ?? UUID(),
            name: groceryItemEntity.name ?? "",
            category: groceryItemEntity.categoryName ?? "",
            brand: groceryItemEntity.brand,
            unit: groceryItemEntity.unit ?? "",
            notes: groceryItemEntity.notes,
            imageData: groceryItemEntity.imageData,
            averagePrice: groceryItemEntity.averagePrice as Decimal? ?? 0,
            createdAt: groceryItemEntity.createdAt ?? Date(),
            updatedAt: groceryItemEntity.updatedAt ?? Date()
        )

        return Purchase(
            id: entity.id ?? UUID(),
            groceryItemId: groceryItemEntity.id ?? UUID(),
            groceryItem: groceryItem,
            quantity: entity.quantity as Decimal? ?? 0,
            price: entity.price as Decimal? ?? 0,
            totalCost: entity.totalCost as Decimal? ?? 0,
            purchaseDate: entity.purchaseDate ?? Date(),
            storeName: entity.storeName,
            receiptImage: entity.receiptImage
        )
    }

    private func mapToEntity(_ domain: Purchase, entity: PurchaseEntity) {
        entity.id = domain.id
        entity.quantity = domain.quantity as NSDecimalNumber
        entity.price = domain.price as NSDecimalNumber
        entity.totalCost = domain.totalCost as NSDecimalNumber
        entity.purchaseDate = domain.purchaseDate
        entity.storeName = domain.storeName
        entity.receiptImage = domain.receiptImage

        // Fetch and link grocery item
        let groceryItemRequest: NSFetchRequest<GroceryItemEntity> = GroceryItemEntity.fetchRequest()
        groceryItemRequest.predicate = NSPredicate(format: "id == %@", domain.groceryItemId as CVarArg)
        groceryItemRequest.fetchLimit = 1

        if let groceryItemEntity = try? context.fetch(groceryItemRequest).first {
            entity.groceryItem = groceryItemEntity
        }
    }
}
