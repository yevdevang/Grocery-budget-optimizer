//
//  GroceryItemRepository.swift
//  Grocery-budget-optimizer
//
//  Created by Claude on 05/10/2025.
//

import Foundation
import CoreData
import Combine

class GroceryItemRepository: GroceryItemRepositoryProtocol {
    private let coreDataStack: CoreDataStack
    private let context: NSManagedObjectContext

    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
        self.context = coreDataStack.viewContext

        // Seed initial items if needed
        seedInitialItemsIfNeeded()
    }

    func fetchAllItems() -> AnyPublisher<[GroceryItem], Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let request: NSFetchRequest<GroceryItemEntity> = GroceryItemEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

            do {
                let entities = try self.context.fetch(request)
                let items = entities.map { self.mapToDomain($0) }
                promise(.success(items))
            } catch {
                promise(.failure(RepositoryError.fetchFailed))
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchItem(byId id: UUID) -> AnyPublisher<GroceryItem?, Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let request: NSFetchRequest<GroceryItemEntity> = GroceryItemEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            do {
                let entities = try self.context.fetch(request)
                let item = entities.first.map { self.mapToDomain($0) }
                promise(.success(item))
            } catch {
                promise(.failure(RepositoryError.fetchFailed))
            }
        }
        .eraseToAnyPublisher()
    }

    func searchItems(query: String) -> AnyPublisher<[GroceryItem], Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let request: NSFetchRequest<GroceryItemEntity> = GroceryItemEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "name CONTAINS[cd] %@ OR category CONTAINS[cd] %@ OR brand CONTAINS[cd] %@",
                query, query, query
            )
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

            do {
                let entities = try self.context.fetch(request)
                let items = entities.map { self.mapToDomain($0) }
                promise(.success(items))
            } catch {
                promise(.failure(RepositoryError.fetchFailed))
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchItems(byCategory category: String) -> AnyPublisher<[GroceryItem], Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let request: NSFetchRequest<GroceryItemEntity> = GroceryItemEntity.fetchRequest()
            request.predicate = NSPredicate(format: "category == %@", category)
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

            do {
                let entities = try self.context.fetch(request)
                let items = entities.map { self.mapToDomain($0) }
                promise(.success(items))
            } catch {
                promise(.failure(RepositoryError.fetchFailed))
            }
        }
        .eraseToAnyPublisher()
    }

    func createItem(_ item: GroceryItem) -> AnyPublisher<GroceryItem, Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let entity = GroceryItemEntity(context: self.context)
            self.mapToEntity(item, entity: entity)

            do {
                try self.context.save()
                print("✅ GroceryItemRepository: Created item '\(item.name)' with ID: \(item.id.uuidString.prefix(8))")
                promise(.success(item))
            } catch {
                print("❌ GroceryItemRepository: Failed to create item - \(error.localizedDescription)")
                promise(.failure(RepositoryError.saveFailed))
            }
        }
        .eraseToAnyPublisher()
    }

    func updateItem(_ item: GroceryItem) -> AnyPublisher<GroceryItem, Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let request: NSFetchRequest<GroceryItemEntity> = GroceryItemEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", item.id as CVarArg)
            request.fetchLimit = 1

            do {
                let entities = try self.context.fetch(request)
                guard let entity = entities.first else {
                    promise(.failure(RepositoryError.notFound))
                    return
                }

                self.mapToEntity(item, entity: entity)
                try self.context.save()
                promise(.success(item))
            } catch {
                promise(.failure(RepositoryError.saveFailed))
            }
        }
        .eraseToAnyPublisher()
    }

    func deleteItem(byId id: UUID) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let request: NSFetchRequest<GroceryItemEntity> = GroceryItemEntity.fetchRequest()
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

    func fetchRecentItems(limit: Int) -> AnyPublisher<[GroceryItem], Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let request: NSFetchRequest<GroceryItemEntity> = GroceryItemEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            request.fetchLimit = limit

            do {
                let entities = try self.context.fetch(request)
                let items = entities.map { self.mapToDomain($0) }
                promise(.success(items))
            } catch {
                promise(.failure(RepositoryError.fetchFailed))
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Mapping

    private func mapToDomain(_ entity: GroceryItemEntity) -> GroceryItem {
        GroceryItem(
            id: entity.id ?? UUID(),
            name: entity.name ?? "",
            category: entity.categoryName ?? "",
            brand: entity.brand,
            unit: entity.unit ?? "",
            notes: entity.notes,
            imageData: entity.imageData,
            barcode: nil, // TODO: Add barcode to Core Data model
            averagePrice: entity.averagePrice as Decimal? ?? 0,
            createdAt: entity.createdAt ?? Date(),
            updatedAt: entity.updatedAt ?? Date()
        )
    }

    private func mapToEntity(_ domain: GroceryItem, entity: GroceryItemEntity) {
        entity.id = domain.id
        entity.name = domain.name
        entity.categoryName = domain.category
        entity.brand = domain.brand
        entity.unit = domain.unit
        entity.notes = domain.notes
        entity.imageData = domain.imageData
        // TODO: Add barcode support when Core Data model is updated
        entity.averagePrice = domain.averagePrice as NSDecimalNumber
        entity.createdAt = domain.createdAt
        entity.updatedAt = domain.updatedAt
    }

    // MARK: - Seeding

    private func seedInitialItemsIfNeeded() {
        let request: NSFetchRequest<GroceryItemEntity> = GroceryItemEntity.fetchRequest()
        request.fetchLimit = 1

        do {
            let count = try context.count(for: request)
            print("📊 Found \(count) items in database")
            
            // If we have items but not the expected 30, force reseed
            if count > 0 && count < 30 {
                print("⚠️ Database corrupted! Found \(count) items instead of 30. Force reseeding...")
                forceReseed()
            } else if count == 0 {
                print("🌱 Seeding initial grocery items...")
                seedInitialItems()
            } else {
                print("✅ Database already seeded with \(count) items")
            }
        } catch {
            print("❌ Failed to check if seeding needed: \(error)")
        }
    }
    
    private func forceReseed() {
        // Delete all existing items
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = GroceryItemEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            print("🗑️ Deleted all existing items")
            
            // Now seed fresh
            seedInitialItems()
        } catch {
            print("❌ Failed to force reseed: \(error)")
        }
    }

    private func seedInitialItems() {
        let initialItems = [
            // Dairy
            GroceryItem(name: "Milk", category: "Dairy", unit: "1 gallon", averagePrice: 3.50),
            GroceryItem(name: "Cheese", category: "Dairy", unit: "1 lb", averagePrice: 4.99),
            GroceryItem(name: "Yogurt", category: "Dairy", unit: "32 oz", averagePrice: 1.29),
            GroceryItem(name: "Butter", category: "Dairy", unit: "1 lb", averagePrice: 3.99),

            // Produce
            GroceryItem(name: "Tomatoes", category: "Produce", unit: "1 lb", averagePrice: 2.99),
            GroceryItem(name: "Lettuce", category: "Produce", unit: "1 head", averagePrice: 1.99),
            GroceryItem(name: "Apples", category: "Produce", unit: "1 lb", averagePrice: 3.49),
            GroceryItem(name: "Bananas", category: "Produce", unit: "1 lb", averagePrice: 1.49),
            GroceryItem(name: "Carrots", category: "Produce", unit: "1 lb", averagePrice: 1.79),
            GroceryItem(name: "Onions", category: "Produce", unit: "1 lb", averagePrice: 1.99),
            GroceryItem(name: "Potatoes", category: "Produce", unit: "5 lb", averagePrice: 2.49),
            GroceryItem(name: "Bell Peppers", category: "Produce", unit: "1 lb", averagePrice: 3.99),
            GroceryItem(name: "Broccoli", category: "Produce", unit: "1 lb", averagePrice: 2.99),
            GroceryItem(name: "Spinach", category: "Produce", unit: "1 bunch", averagePrice: 2.49),
            GroceryItem(name: "Garlic", category: "Produce", unit: "1 bulb", averagePrice: 0.99),

            // Meat & Seafood
            GroceryItem(name: "Chicken Breast", category: "Meat & Seafood", unit: "1 lb", averagePrice: 6.99),
            GroceryItem(name: "Ground Beef", category: "Meat & Seafood", unit: "1 lb", averagePrice: 5.99),
            GroceryItem(name: "Salmon", category: "Meat & Seafood", unit: "1 lb", averagePrice: 12.99),
            GroceryItem(name: "Tuna", category: "Meat & Seafood", unit: "5 oz can", averagePrice: 2.99),

            // Pantry
            GroceryItem(name: "Bread", category: "Pantry", unit: "1 loaf", averagePrice: 2.49),
            GroceryItem(name: "Rice", category: "Pantry", unit: "2 lb", averagePrice: 3.99),
            GroceryItem(name: "Pasta", category: "Pantry", unit: "1 lb", averagePrice: 1.99),
            GroceryItem(name: "Eggs", category: "Pantry", unit: "1 dozen", averagePrice: 3.49),
            GroceryItem(name: "Olive Oil", category: "Pantry", unit: "16 oz", averagePrice: 6.99),
            GroceryItem(name: "Salt", category: "Pantry", unit: "26 oz", averagePrice: 1.99),
            GroceryItem(name: "Pepper", category: "Pantry", unit: "2 oz", averagePrice: 2.99),
            GroceryItem(name: "Cereal", category: "Pantry", unit: "18 oz", averagePrice: 4.99),
            GroceryItem(name: "Oats", category: "Pantry", unit: "42 oz", averagePrice: 3.49),
            GroceryItem(name: "Honey", category: "Pantry", unit: "12 oz", averagePrice: 5.99),

            // Beverages
            GroceryItem(name: "Coffee", category: "Beverages", unit: "12 oz", averagePrice: 8.99)
        ]

        for item in initialItems {
            let entity = GroceryItemEntity(context: context)
            mapToEntity(item, entity: entity)
        }

        do {
            try context.save()
            print("✅ Successfully seeded \(initialItems.count) grocery items")
        } catch {
            print("❌ Failed to seed grocery items: \(error)")
        }
    }
}
