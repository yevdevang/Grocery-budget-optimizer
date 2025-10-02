# Phase 1: Foundation - Architecture & Core Data Setup

## 📋 Overview

Establish the foundational architecture using Clean Architecture principles with MVVM pattern, set up Core Data for local persistence, and create the basic domain models.

**Duration**: 1 week
**Dependencies**: None

---

## 🎯 Objectives

- ✅ Implement Clean Architecture folder structure
- ✅ Set up Core Data stack with CloudKit sync
- ✅ Create domain entities and protocols
- ✅ Implement repository pattern
- ✅ Set up dependency injection
- ✅ Create base utilities and extensions

---

## 📁 Step 1: Project Structure Setup

### Create Folder Structure

```
Grocery-budget-optimizer/
├── App/
│   ├── Grocery_budget_optimizerApp.swift
│   └── AppDelegate.swift (if needed)
├── Domain/
│   ├── Entities/
│   ├── UseCases/
│   └── RepositoryProtocols/
├── Data/
│   ├── CoreData/
│   ├── Repositories/
│   └── MLModels/
├── Presentation/
│   ├── Screens/
│   ├── ViewModels/
│   ├── Components/
│   └── Common/
├── Core/
│   ├── Extensions/
│   ├── Utilities/
│   ├── DependencyInjection/
│   └── Constants/
└── Resources/
    ├── Assets.xcassets
    └── Localization/
```

### Implementation Tasks

1. Create group folders in Xcode
2. Move existing files to appropriate locations
3. Set up proper target membership

---

## 🗄️ Step 2: Core Data Setup

### 2.1 Create Data Model

Create `GroceryBudgetOptimizer.xcdatamodeld` with the following entities:

#### Entity: GroceryItem
```
Attributes:
- id: UUID (unique identifier)
- name: String (item name)
- categoryName: String (e.g., "Dairy", "Produce")
- brand: String? (optional brand)
- unit: String (e.g., "kg", "lbs", "pieces")
- notes: String? (optional notes)
- imageData: Binary Data? (optional image)
- averagePrice: Decimal (estimated price)
- createdAt: Date
- updatedAt: Date

Relationships:
- purchases: To-Many -> Purchase
- shoppingListItems: To-Many -> ShoppingListItem
- expirationTrackers: To-Many -> ExpirationTracker
- priceHistory: To-Many -> PriceHistory
```

#### Entity: ShoppingList
```
Attributes:
- id: UUID
- name: String (e.g., "Weekly Groceries")
- budgetAmount: Decimal
- createdAt: Date
- updatedAt: Date
- isCompleted: Boolean
- completedAt: Date?
- totalEstimatedCost: Decimal

Relationships:
- items: To-Many -> ShoppingListItem
```

#### Entity: ShoppingListItem
```
Attributes:
- id: UUID
- quantity: Decimal
- estimatedPrice: Decimal
- isPurchased: Boolean
- purchasedAt: Date?
- actualPrice: Decimal?

Relationships:
- shoppingList: To-One -> ShoppingList
- groceryItem: To-One -> GroceryItem
```

#### Entity: Purchase
```
Attributes:
- id: UUID
- quantity: Decimal
- price: Decimal
- totalCost: Decimal
- purchaseDate: Date
- storeName: String?
- receiptImage: Binary Data?

Relationships:
- groceryItem: To-One -> GroceryItem
- expirationTracker: To-One? -> ExpirationTracker (optional)
```

#### Entity: Category
```
Attributes:
- id: UUID
- name: String
- iconName: String (SF Symbol name)
- colorHex: String
- sortOrder: Int16

Relationships:
- (none - referenced by string in GroceryItem)
```

#### Entity: Budget
```
Attributes:
- id: UUID
- name: String (e.g., "Monthly Budget")
- amount: Decimal
- startDate: Date
- endDate: Date
- isActive: Boolean
- categoryBudgets: Transformable (Dictionary<String, Decimal>)

Relationships:
- (none)
```

#### Entity: PriceHistory
```
Attributes:
- id: UUID
- price: Decimal
- recordedAt: Date
- storeName: String?
- source: String (e.g., "manual", "receipt_scan")

Relationships:
- groceryItem: To-One -> GroceryItem
```

#### Entity: ExpirationTracker
```
Attributes:
- id: UUID
- purchaseDate: Date
- expirationDate: Date
- estimatedExpirationDate: Date (ML prediction)
- quantity: Decimal
- remainingQuantity: Decimal
- storageLocation: String? (e.g., "Fridge", "Pantry")
- isConsumed: Boolean
- consumedAt: Date?
- isWasted: Boolean
- wastedAt: Date?

Relationships:
- groceryItem: To-One -> GroceryItem
- purchase: To-One? -> Purchase
```

### 2.2 Create Core Data Stack

Create `CoreDataStack.swift`:

```swift
import CoreData
import Foundation

class CoreDataStack {
    static let shared = CoreDataStack()

    private init() {}

    // MARK: - Core Data Stack

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "GroceryBudgetOptimizer")

        // Configure CloudKit sync (optional)
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve persistent store description")
        }

        // Enable CloudKit sync
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.yourcompany.grocerybudgetoptimizer"
        )

        // Enable persistent history tracking
        description.setOption(true as NSNumber,
                            forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber,
                            forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // Handle error appropriately
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        return container
    }()

    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // MARK: - Background Context

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    // MARK: - Save Context

    func saveContext() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("Error saving context: \(nserror), \(nserror.userInfo)")
            }
        }
    }

    func saveContext(_ context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("Error saving context: \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
```

---

## 🏛️ Step 3: Domain Layer

### 3.1 Create Domain Entities

Create entity structs in `Domain/Entities/`:

**GroceryItem.swift**:
```swift
import Foundation

struct GroceryItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var category: String
    var brand: String?
    var unit: String
    var notes: String?
    var imageData: Data?
    var averagePrice: Decimal
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        category: String,
        brand: String? = nil,
        unit: String,
        notes: String? = nil,
        imageData: Data? = nil,
        averagePrice: Decimal = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.brand = brand
        self.unit = unit
        self.notes = notes
        self.imageData = imageData
        self.averagePrice = averagePrice
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
```

**ShoppingList.swift**:
```swift
import Foundation

struct ShoppingList: Identifiable, Codable {
    let id: UUID
    var name: String
    var budgetAmount: Decimal
    var items: [ShoppingListItem]
    var createdAt: Date
    var updatedAt: Date
    var isCompleted: Bool
    var completedAt: Date?

    var totalEstimatedCost: Decimal {
        items.reduce(0) { $0 + ($1.estimatedPrice * $1.quantity) }
    }

    var totalActualCost: Decimal {
        items.reduce(0) { $0 + (($1.actualPrice ?? 0) * $1.quantity) }
    }

    var remainingBudget: Decimal {
        budgetAmount - totalEstimatedCost
    }

    var completionPercentage: Double {
        guard !items.isEmpty else { return 0 }
        let purchased = items.filter { $0.isPurchased }.count
        return Double(purchased) / Double(items.count)
    }
}
```

**ShoppingListItem.swift**:
```swift
import Foundation

struct ShoppingListItem: Identifiable, Codable {
    let id: UUID
    var groceryItemId: UUID
    var quantity: Decimal
    var estimatedPrice: Decimal
    var isPurchased: Bool
    var purchasedAt: Date?
    var actualPrice: Decimal?

    init(
        id: UUID = UUID(),
        groceryItemId: UUID,
        quantity: Decimal,
        estimatedPrice: Decimal,
        isPurchased: Bool = false,
        purchasedAt: Date? = nil,
        actualPrice: Decimal? = nil
    ) {
        self.id = id
        self.groceryItemId = groceryItemId
        self.quantity = quantity
        self.estimatedPrice = estimatedPrice
        self.isPurchased = isPurchased
        self.purchasedAt = purchasedAt
        self.actualPrice = actualPrice
    }
}
```

Create similar entities for: `Purchase`, `Budget`, `Category`, `PriceHistory`, `ExpirationTracker`

### 3.2 Create Repository Protocols

Create `Domain/RepositoryProtocols/GroceryItemRepositoryProtocol.swift`:

```swift
import Foundation
import Combine

protocol GroceryItemRepositoryProtocol {
    func fetchAllItems() -> AnyPublisher<[GroceryItem], Error>
    func fetchItem(byId id: UUID) -> AnyPublisher<GroceryItem?, Error>
    func searchItems(query: String) -> AnyPublisher<[GroceryItem], Error>
    func fetchItems(byCategory category: String) -> AnyPublisher<[GroceryItem], Error>
    func createItem(_ item: GroceryItem) -> AnyPublisher<GroceryItem, Error>
    func updateItem(_ item: GroceryItem) -> AnyPublisher<GroceryItem, Error>
    func deleteItem(byId id: UUID) -> AnyPublisher<Void, Error>
}
```

Create similar protocols for other repositories:
- `ShoppingListRepositoryProtocol`
- `PurchaseRepositoryProtocol`
- `BudgetRepositoryProtocol`
- `ExpirationTrackerRepositoryProtocol`

---

## 💾 Step 4: Data Layer - Repositories

### 4.1 Implement Repositories

Create `Data/Repositories/GroceryItemRepository.swift`:

```swift
import Foundation
import CoreData
import Combine

class GroceryItemRepository: GroceryItemRepositoryProtocol {
    private let coreDataStack: CoreDataStack
    private let context: NSManagedObjectContext

    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
        self.context = coreDataStack.viewContext
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
                promise(.failure(error))
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
                promise(.failure(error))
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
                format: "name CONTAINS[cd] %@ OR brand CONTAINS[cd] %@",
                query, query
            )
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

            do {
                let entities = try self.context.fetch(request)
                let items = entities.map { self.mapToDomain($0) }
                promise(.success(items))
            } catch {
                promise(.failure(error))
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
                promise(.success(item))
            } catch {
                promise(.failure(error))
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
                promise(.failure(error))
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
                promise(.failure(error))
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
        entity.averagePrice = domain.averagePrice as NSDecimalNumber
        entity.createdAt = domain.createdAt
        entity.updatedAt = domain.updatedAt
    }
}

enum RepositoryError: Error {
    case notFound
    case unknown
}
```

Implement similar repositories for other entities.

---

## 🔧 Step 5: Utilities & Extensions

### 5.1 Create Common Extensions

**Extensions/Decimal+Extensions.swift**:
```swift
import Foundation

extension Decimal {
    var doubleValue: Double {
        return NSDecimalNumber(decimal: self).doubleValue
    }

    func formatted(as currency: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: self as NSDecimalNumber) ?? "$0.00"
    }
}
```

**Extensions/Date+Extensions.swift**:
```swift
import Foundation

extension Date {
    func isToday() -> Bool {
        Calendar.current.isDateInToday(self)
    }

    func daysUntil(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: self, to: date).day ?? 0
    }

    func formatted(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        return formatter.string(from: self)
    }
}
```

### 5.2 Create Constants

**Core/Constants/AppConstants.swift**:
```swift
import Foundation

enum AppConstants {
    enum Database {
        static let modelName = "GroceryBudgetOptimizer"
        static let cloudKitContainerID = "iCloud.com.yourcompany.grocerybudgetoptimizer"
    }

    enum Categories {
        static let defaultCategories = [
            "Produce", "Dairy", "Meat & Seafood", "Bakery",
            "Frozen", "Pantry", "Beverages", "Snacks",
            "Personal Care", "Household", "Other"
        ]
    }

    enum Units {
        static let weightUnits = ["kg", "g", "lbs", "oz"]
        static let volumeUnits = ["L", "ml", "gal", "fl oz"]
        static let countUnits = ["pieces", "packs", "boxes"]
    }
}
```

---

## ✅ Step 6: Testing Infrastructure

### 6.1 Create Base Test Classes

**Tests/BaseTestCase.swift**:
```swift
import XCTest
import CoreData
@testable import Grocery_budget_optimizer

class BaseTestCase: XCTestCase {
    var inMemoryContainer: NSPersistentContainer!
    var testContext: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        setupInMemoryDatabase()
    }

    override func tearDown() {
        testContext = nil
        inMemoryContainer = nil
        super.tearDown()
    }

    private func setupInMemoryDatabase() {
        inMemoryContainer = NSPersistentContainer(name: "GroceryBudgetOptimizer")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        inMemoryContainer.persistentStoreDescriptions = [description]

        inMemoryContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load in-memory store: \(error)")
            }
        }

        testContext = inMemoryContainer.viewContext
    }
}
```

### 6.2 Create Repository Tests

**Tests/GroceryItemRepositoryTests.swift**:
```swift
import XCTest
import Combine
@testable import Grocery_budget_optimizer

final class GroceryItemRepositoryTests: BaseTestCase {
    var repository: GroceryItemRepository!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        repository = GroceryItemRepository(
            coreDataStack: MockCoreDataStack(context: testContext)
        )
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        repository = nil
        super.tearDown()
    }

    func testCreateItem() {
        let expectation = expectation(description: "Create item")
        let item = GroceryItem(
            name: "Milk",
            category: "Dairy",
            unit: "L",
            averagePrice: 3.99
        )

        repository.createItem(item)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Failed with error: \(error)")
                    }
                },
                receiveValue: { createdItem in
                    XCTAssertEqual(createdItem.name, "Milk")
                    XCTAssertEqual(createdItem.category, "Dairy")
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0)
    }

    // Add more tests...
}
```

---

## 📝 Acceptance Criteria

### Phase 1 Complete When:

- ✅ Clean Architecture folder structure implemented
- ✅ Core Data model created with all entities
- ✅ Core Data stack with CloudKit sync configured
- ✅ All domain entities created
- ✅ All repository protocols defined
- ✅ At least 2 repositories fully implemented
- ✅ Common extensions and utilities created
- ✅ Base test infrastructure set up
- ✅ Repository tests passing (>80% coverage)

---

## ⚠️ Potential Challenges

### Challenge 1: Core Data Migration
**Problem**: Schema changes require migrations
**Solution**: Implement lightweight migrations from the start; use versioned models

### Challenge 2: CloudKit Sync Conflicts
**Problem**: Merge conflicts with CloudKit sync
**Solution**: Implement proper merge policies; use persistent history tracking

### Challenge 3: Testing Core Data
**Problem**: Tests are slow with persistent storage
**Solution**: Use in-memory stores for unit tests

### Challenge 4: Decimal Precision
**Problem**: Decimal arithmetic precision issues
**Solution**: Use NSDecimalNumber; avoid Double for currency

---

## 🚀 Next Steps

Once Phase 1 is complete, proceed to:
- **[Phase 2: ML Models](02-PHASE-2-ML-MODELS.md)** - Train and integrate Core ML models

---

## 📚 Resources

- [Core Data Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/)
- [NSPersistentCloudKitContainer](https://developer.apple.com/documentation/coredata/nspersistentcloudkitcontainer)
- [Clean Architecture in iOS](https://clean-swift.com/)
- [Combine Framework](https://developer.apple.com/documentation/combine)
