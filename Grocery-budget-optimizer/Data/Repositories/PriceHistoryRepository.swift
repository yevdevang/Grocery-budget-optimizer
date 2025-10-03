import Foundation
import CoreData
import Combine

class PriceHistoryRepository: PriceHistoryRepositoryProtocol {
    private let coreDataStack: CoreDataStack
    private let context: NSManagedObjectContext

    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
        self.context = coreDataStack.viewContext
    }

    func addPriceHistory(_ priceHistory: PriceHistory) -> AnyPublisher<PriceHistory, Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let entity = PriceHistoryEntity(context: self.context)
            self.mapToEntity(priceHistory, entity: entity)

            do {
                try self.context.save()
                promise(.success(priceHistory))
            } catch {
                promise(.failure(RepositoryError.saveFailed))
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchPriceHistory(for groceryItemId: UUID) -> AnyPublisher<[PriceHistory], Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let request: NSFetchRequest<PriceHistoryEntity> = PriceHistoryEntity.fetchRequest()
            request.predicate = NSPredicate(format: "groceryItem.id == %@", groceryItemId as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "recordedAt", ascending: false)]

            do {
                let entities = try self.context.fetch(request)
                let priceHistory = entities.map { self.mapToDomain($0) }
                promise(.success(priceHistory))
            } catch {
                promise(.failure(RepositoryError.fetchFailed))
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchPriceHistory(for groceryItemId: UUID, limit: Int) -> AnyPublisher<[PriceHistory], Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let request: NSFetchRequest<PriceHistoryEntity> = PriceHistoryEntity.fetchRequest()
            request.predicate = NSPredicate(format: "groceryItem.id == %@", groceryItemId as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(key: "recordedAt", ascending: false)]
            request.fetchLimit = limit

            do {
                let entities = try self.context.fetch(request)
                let priceHistory = entities.map { self.mapToDomain($0) }
                promise(.success(priceHistory))
            } catch {
                promise(.failure(RepositoryError.fetchFailed))
            }
        }
        .eraseToAnyPublisher()
    }

    func deletePriceHistory(byId id: UUID) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let request: NSFetchRequest<PriceHistoryEntity> = PriceHistoryEntity.fetchRequest()
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

    private func mapToDomain(_ entity: PriceHistoryEntity) -> PriceHistory {
        PriceHistory(
            id: entity.id ?? UUID(),
            groceryItemId: entity.groceryItem?.id ?? UUID(),
            price: entity.price as Decimal? ?? 0,
            recordedAt: entity.recordedAt ?? Date(),
            storeName: entity.storeName,
            source: entity.source ?? "manual"
        )
    }

    private func mapToEntity(_ domain: PriceHistory, entity: PriceHistoryEntity) {
        entity.id = domain.id
        entity.price = domain.price as NSDecimalNumber
        entity.recordedAt = domain.recordedAt
        entity.storeName = domain.storeName
        entity.source = domain.source

        // Fetch and link grocery item
        let groceryItemRequest: NSFetchRequest<GroceryItemEntity> = GroceryItemEntity.fetchRequest()
        groceryItemRequest.predicate = NSPredicate(format: "id == %@", domain.groceryItemId as CVarArg)
        groceryItemRequest.fetchLimit = 1

        if let groceryItemEntity = try? context.fetch(groceryItemRequest).first {
            entity.groceryItem = groceryItemEntity
        }
    }
}
