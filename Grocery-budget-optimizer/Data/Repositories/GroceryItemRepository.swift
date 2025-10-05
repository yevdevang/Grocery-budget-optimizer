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
    private let openFoodFactsService: OpenFoodFactsServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(
        coreDataStack: CoreDataStack = .shared,
        openFoodFactsService: OpenFoodFactsServiceProtocol = OpenFoodFactsService()
    ) {
        self.coreDataStack = coreDataStack
        self.context = coreDataStack.viewContext
        self.openFoodFactsService = openFoodFactsService

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

    private func seedInitialItemsIfNeeded() {
        let request: NSFetchRequest<GroceryItemEntity> = GroceryItemEntity.fetchRequest()
        request.fetchLimit = 1

        do {
            let count = try context.count(for: request)
            print("📊 Found \(count) items in database")
            
            if count == 0 {
                print("🌱 Seeding initial grocery items from API...")
                seedInitialItemsFromAPI()
            } else {
                print("✅ Database already seeded with \(count) items")
            }
        } catch {
            print("❌ Failed to check if seeding needed: \(error)")
        }
    }
    
    private func seedInitialItemsFromAPI() {
        print("🌐 Starting to fetch products from Open Food Facts API...")
        
        // Categories to fetch from API
        let categories = [
            "dairy-products",
            "fruits",
            "vegetables", 
            "meats",
            "beverages",
            "cereals-and-potatoes",
            "snacks"
        ]
        
        var allItems: [GroceryItem] = []
        let group = DispatchGroup()
        
        // Fetch products from each category
        for category in categories {
            group.enter()
            
            openFoodFactsService.fetchProductsByCategory(category: category, page: 1, pageSize: 10)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("❌ Failed to fetch \(category): \(error.localizedDescription)")
                        }
                        group.leave()
                    },
                    receiveValue: { items in
                        print("✅ Fetched \(items.count) items from category: \(category)")
                        allItems.append(contentsOf: items)
                    }
                )
                .store(in: &cancellables)
        }
        
        // Wait for all API calls to complete, then save to database
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            if allItems.isEmpty {
                print("⚠️ No items fetched from API, falling back to hardcoded data")
                self.seedFallbackItems()
                return
            }
            
            print("💾 Saving \(allItems.count) items to database...")
            
            for item in allItems {
                let entity = GroceryItemEntity(context: self.context)
                self.mapToEntity(item, entity: entity)
            }
            
            do {
                try self.context.save()
                print("✅ Successfully seeded \(allItems.count) grocery items from API")
            } catch {
                print("❌ Failed to save items from API: \(error)")
                // Clear any partial saves
                self.context.rollback()
                // Fall back to hardcoded data
                self.seedFallbackItems()
            }
        }
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
    
    /// Refresh items from API for a specific category
    func refreshItemsFromAPI(category: String? = nil) -> AnyPublisher<[GroceryItem], Error> {
        if let category = category {
            return openFoodFactsService.fetchProductsByCategory(category: category, page: 1, pageSize: 20)
        } else {
            // Fetch from multiple categories
            let categories = ["dairy-products", "fruits", "vegetables", "meats", "beverages"]
            let publishers = categories.map { cat in
                openFoodFactsService.fetchProductsByCategory(category: cat, page: 1, pageSize: 10)
            }
            
            return Publishers.MergeMany(publishers)
                .collect()
                .map { arrays in
                    arrays.flatMap { $0 }
                }
                .eraseToAnyPublisher()
        }
    }
    
    /// Search for products on Open Food Facts and optionally save them
    func searchAndSaveProducts(query: String, saveResults: Bool = false) -> AnyPublisher<[GroceryItem], Error> {
        openFoodFactsService.searchProducts(query: query, page: 1, pageSize: 20)
            .handleEvents(receiveOutput: { [weak self] items in
                guard let self = self, saveResults else { return }
                
                // Save the found items to database
                for item in items {
                    let entity = GroceryItemEntity(context: self.context)
                    self.mapToEntity(item, entity: entity)
                }
                
                do {
                    try self.context.save()
                    print("✅ Saved \(items.count) items from search to database")
                } catch {
                    print("❌ Failed to save search results: \(error)")
                }
            })
            .eraseToAnyPublisher()
    }
}
