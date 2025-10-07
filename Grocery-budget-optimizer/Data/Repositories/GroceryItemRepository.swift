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
    private let ramiLevyService: RamiLevyServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(
        coreDataStack: CoreDataStack = .shared,
        ramiLevyService: RamiLevyServiceProtocol = RamiLevyService()
    ) {
        self.coreDataStack = coreDataStack
        self.context = coreDataStack.viewContext
        self.ramiLevyService = ramiLevyService

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
        if let imgData = entity.imageData {
            print("📤 Repository: Loading imageData for '\(entity.name ?? "unknown")': \(imgData.count) bytes")
        } else {
            print("ℹ️ Repository: No imageData in entity for '\(entity.name ?? "unknown")'")
        }
        
        return GroceryItem(
            id: entity.id ?? UUID(),
            name: entity.name ?? "",
            category: entity.categoryName ?? "",
            brand: entity.brand,
            unit: entity.unit ?? "",
            notes: entity.notes,
            imageData: entity.imageData,
            imageURL: entity.imageURL,
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
        entity.imageURL = domain.imageURL
        
        if let imgData = domain.imageData {
            print("💾 Repository: Saving imageData for '\(domain.name)': \(imgData.count) bytes")
        } else {
            print("⚠️ Repository: No imageData to save for '\(domain.name)'")
        }
        
        // TODO: Add barcode support when Core Data model is updated
        entity.averagePrice = domain.averagePrice as NSDecimalNumber
        entity.createdAt = domain.createdAt
        entity.updatedAt = domain.updatedAt
    }

    // MARK: - Seeding

    func clearAllData() {
        let request: NSFetchRequest<NSFetchRequestResult> = GroceryItemEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            print("🗑️ Cleared all grocery items from database")
        } catch {
            print("❌ Failed to clear grocery items: \(error)")
        }
    }

    private func seedInitialItemsIfNeeded() {
        let request: NSFetchRequest<GroceryItemEntity> = GroceryItemEntity.fetchRequest()
        request.fetchLimit = 1

        do {
            let count = try context.count(for: request)
            print("📊 Found \(count) items in database")
            
            if count == 0 {
                print("🌱 Seeding initial grocery items from Rami Levy API...")
                seedInitialItemsFromAPI()
            } else {
                print("✅ Database already seeded with \(count) items")
            }
        } catch {
            print("❌ Failed to check if seeding needed: \(error)")
        }
    }
    
    private func seedInitialItemsFromAPI() {
        print("🌐 Starting to fetch products from Rami Levy API...")
        
        // Fetch all products from Rami Levy API
        ramiLevyService.fetchGroceryItems()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to fetch from Rami Levy API: \(error.localizedDescription)")
                        print("🔄 Falling back to mock data...")
                        self.seedFallbackItems()
                    }
                },
                receiveValue: { [weak self] (items: [GroceryItem]) in
                    guard let self = self else { return }
                    print("✅ Fetched \(items.count) items from Rami Levy API")
                    
                    if items.isEmpty {
                        print("⚠️ No items fetched from API, falling back to hardcoded data")
                        self.seedFallbackItems()
                        return
                    }
                    
                    print("💾 Saving \(items.count) items to database...")
                    
                    for item in items {
                        let entity = GroceryItemEntity(context: self.context)
                        self.mapToEntity(item, entity: entity)
                    }
                    
                    do {
                        try self.context.save()
                        print("✅ Successfully seeded \(items.count) grocery items from Rami Levy API")
                    } catch {
                        print("❌ Failed to save items from API: \(error)")
                        // Clear any partial saves
                        self.context.rollback()
                        // Fall back to hardcoded data
                        self.seedFallbackItems()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func seedFallbackItems() {
        print("🔄 Using fallback hardcoded data...")
        
        let fallbackItems = [
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

            // Meat & Seafood
            GroceryItem(name: "Chicken Breast", category: "Meat & Seafood", unit: "1 lb", averagePrice: 6.99),
            GroceryItem(name: "Ground Beef", category: "Meat & Seafood", unit: "1 lb", averagePrice: 5.99),
            GroceryItem(name: "Salmon", category: "Meat & Seafood", unit: "1 lb", averagePrice: 12.99),

            // Pantry
            GroceryItem(name: "Bread", category: "Pantry", unit: "1 loaf", averagePrice: 2.49),
            GroceryItem(name: "Rice", category: "Pantry", unit: "2 lb", averagePrice: 3.99),
            GroceryItem(name: "Pasta", category: "Pantry", unit: "1 lb", averagePrice: 1.99),
            GroceryItem(name: "Eggs", category: "Pantry", unit: "1 dozen", averagePrice: 3.49),

            // Beverages
            GroceryItem(name: "Coffee", category: "Beverages", unit: "12 oz", averagePrice: 8.99),
            GroceryItem(name: "Orange Juice", category: "Beverages", unit: "64 oz", averagePrice: 4.99)
        ]

        for item in fallbackItems {
            let entity = GroceryItemEntity(context: context)
            mapToEntity(item, entity: entity)
        }

        do {
            try context.save()
            print("✅ Successfully seeded \(fallbackItems.count) fallback grocery items")
        } catch {
            print("❌ Failed to seed fallback grocery items: \(error)")
        }
    }
    
    // MARK: - Public API Methods
    
    /// Refresh items from Rami Levy API
    func refreshItemsFromAPI(category: String? = nil) -> AnyPublisher<[GroceryItem], Error> {
        return ramiLevyService.fetchGroceryItems()
            .map { [weak self] items in
                guard let self = self else { return items }
                
                // Optionally filter by category if specified
                let filteredItems = if let category = category {
                    items.filter { $0.category.lowercased() == category.lowercased() }
                } else {
                    items
                }
                
                print("✅ Fetched \(filteredItems.count) items from Rami Levy API" + (category != nil ? " for category: \(category!)" : ""))
                
                // Clear existing items and save new ones to database
                self.clearAllData()
                
                // Save the fetched items to database
                for item in filteredItems {
                    let entity = GroceryItemEntity(context: self.context)
                    self.mapToEntity(item, entity: entity)
                }
                
                do {
                    try self.context.save()
                    print("✅ Saved \(filteredItems.count) Rami Levy items to database")
                } catch {
                    print("❌ Failed to save Rami Levy items: \(error)")
                }
                
                return filteredItems
            }
            .eraseToAnyPublisher()
    }
    
    /// Search for products on Rami Levy API and optionally save them
    func searchAndSaveProducts(query: String, saveResults: Bool = false) -> AnyPublisher<[GroceryItem], Error> {
        ramiLevyService.searchGroceryItems(query: query)
            .map { [weak self] items in
                guard let self = self, saveResults else { return items }
                
                // Save the found items to database
                for item in items {
                    let entity = GroceryItemEntity(context: self.context)
                    self.mapToEntity(item, entity: entity)
                }
                
                do {
                    try self.context.save()
                    print("✅ Saved \(items.count) items from Rami Levy search to database")
                } catch {
                    print("❌ Failed to save Rami Levy search results: \(error)")
                }
                
                return items
            }
            .eraseToAnyPublisher()
    }
}
