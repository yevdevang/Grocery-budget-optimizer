# Phase 3: Core Features - Budget, Shopping Lists & Item Management

## 📋 Overview

Implement the core business logic and use cases for budget management, shopping list creation, item tracking, and purchase recording.

**Duration**: 1.5 weeks
**Dependencies**: Phase 1 (Foundation), Phase 2 (ML Models)

---

## 🎯 Objectives

- ✅ Implement budget management use cases
- ✅ Create shopping list management features
- ✅ Build item catalog and management
- ✅ Implement purchase tracking
- ✅ Add expiration tracking functionality
- ✅ Create price history tracking
- ✅ Build notification system

---

## 💰 Feature 1: Budget Management

### 1.1 Budget Use Cases

Create `Domain/UseCases/Budget/CreateBudgetUseCase.swift`:

```swift
import Foundation
import Combine

protocol CreateBudgetUseCaseProtocol {
    func execute(_ budget: Budget) -> AnyPublisher<Budget, Error>
}

class CreateBudgetUseCase: CreateBudgetUseCaseProtocol {
    private let repository: BudgetRepositoryProtocol

    init(repository: BudgetRepositoryProtocol) {
        self.repository = repository
    }

    func execute(_ budget: Budget) -> AnyPublisher<Budget, Error> {
        // Validation
        guard budget.amount > 0 else {
            return Fail(error: ValidationError.invalidAmount)
                .eraseToAnyPublisher()
        }

        guard budget.startDate < budget.endDate else {
            return Fail(error: ValidationError.invalidDateRange)
                .eraseToAnyPublisher()
        }

        // Deactivate other active budgets for the same period
        return repository.fetchActiveBudgets()
            .flatMap { [weak self] activeBudgets -> AnyPublisher<Budget, Error> in
                guard let self = self else {
                    return Fail(error: UseCaseError.unknown).eraseToAnyPublisher()
                }

                // Deactivate overlapping budgets
                let deactivations = activeBudgets
                    .filter { self.overlaps(budget, with: $0) }
                    .map { budget -> Budget in
                        var updated = budget
                        updated.isActive = false
                        return updated
                    }
                    .map { self.repository.updateBudget($0) }

                return Publishers.MergeMany(deactivations)
                    .collect()
                    .flatMap { _ in self.repository.createBudget(budget) }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func overlaps(_ budget1: Budget, with budget2: Budget) -> Bool {
        return budget1.startDate <= budget2.endDate && budget1.endDate >= budget2.startDate
    }
}

enum ValidationError: Error {
    case invalidAmount
    case invalidDateRange
}

enum UseCaseError: Error {
    case unknown
}
```

Create `Domain/UseCases/Budget/GetBudgetSummaryUseCase.swift`:

```swift
import Foundation
import Combine

protocol GetBudgetSummaryUseCaseProtocol {
    func execute(for budgetId: UUID) -> AnyPublisher<BudgetSummary, Error>
}

class GetBudgetSummaryUseCase: GetBudgetSummaryUseCaseProtocol {
    private let budgetRepository: BudgetRepositoryProtocol
    private let purchaseRepository: PurchaseRepositoryProtocol

    init(
        budgetRepository: BudgetRepositoryProtocol,
        purchaseRepository: PurchaseRepositoryProtocol
    ) {
        self.budgetRepository = budgetRepository
        self.purchaseRepository = purchaseRepository
    }

    func execute(for budgetId: UUID) -> AnyPublisher<BudgetSummary, Error> {
        return budgetRepository.fetchBudget(byId: budgetId)
            .flatMap { [weak self] budget -> AnyPublisher<BudgetSummary, Error> in
                guard let self = self, let budget = budget else {
                    return Fail(error: UseCaseError.notFound).eraseToAnyPublisher()
                }

                return self.purchaseRepository
                    .fetchPurchases(from: budget.startDate, to: budget.endDate)
                    .map { purchases in
                        self.createSummary(for: budget, with: purchases)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func createSummary(for budget: Budget, with purchases: [Purchase])
        -> BudgetSummary {

        let totalSpent = purchases.reduce(Decimal(0)) { $0 + $1.totalCost }
        let remainingAmount = budget.amount - totalSpent
        let percentageUsed = (totalSpent / budget.amount).doubleValue * 100

        // Calculate spending by category
        var spendingByCategory: [String: Decimal] = [:]
        for purchase in purchases {
            let category = purchase.groceryItem.category
            spendingByCategory[category, default: 0] += purchase.totalCost
        }

        // Calculate daily average
        let daysPassed = Calendar.current.dateComponents(
            [.day],
            from: budget.startDate,
            to: Date()
        ).day ?? 1

        let dailyAverage = totalSpent / Decimal(max(1, daysPassed))
        let totalDays = Calendar.current.dateComponents(
            [.day],
            from: budget.startDate,
            to: budget.endDate
        ).day ?? 1

        let projectedTotal = dailyAverage * Decimal(totalDays)

        return BudgetSummary(
            budget: budget,
            totalSpent: totalSpent,
            remainingAmount: remainingAmount,
            percentageUsed: percentageUsed,
            spendingByCategory: spendingByCategory,
            dailyAverage: dailyAverage,
            projectedTotal: projectedTotal,
            isOnTrack: projectedTotal <= budget.amount,
            daysRemaining: totalDays - daysPassed
        )
    }
}

struct BudgetSummary {
    let budget: Budget
    let totalSpent: Decimal
    let remainingAmount: Decimal
    let percentageUsed: Double
    let spendingByCategory: [String: Decimal]
    let dailyAverage: Decimal
    let projectedTotal: Decimal
    let isOnTrack: Bool
    let daysRemaining: Int
}
```

### 1.2 Budget Repository

Create `Data/Repositories/BudgetRepository.swift`:

```swift
import Foundation
import CoreData
import Combine

class BudgetRepository: BudgetRepositoryProtocol {
    private let coreDataStack: CoreDataStack
    private let context: NSManagedObjectContext

    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
        self.context = coreDataStack.viewContext
    }

    func createBudget(_ budget: Budget) -> AnyPublisher<Budget, Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let entity = BudgetEntity(context: self.context)
            self.mapToEntity(budget, entity: entity)

            do {
                try self.context.save()
                promise(.success(budget))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchActiveBudgets() -> AnyPublisher<[Budget], Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let request: NSFetchRequest<BudgetEntity> = BudgetEntity.fetchRequest()
            request.predicate = NSPredicate(format: "isActive == YES")
            request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]

            do {
                let entities = try self.context.fetch(request)
                let budgets = entities.map { self.mapToDomain($0) }
                promise(.success(budgets))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchBudget(byId id: UUID) -> AnyPublisher<Budget?, Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let request: NSFetchRequest<BudgetEntity> = BudgetEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            do {
                let entities = try self.context.fetch(request)
                let budget = entities.first.map { self.mapToDomain($0) }
                promise(.success(budget))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }

    // Mapping methods...
    private func mapToDomain(_ entity: BudgetEntity) -> Budget {
        Budget(
            id: entity.id ?? UUID(),
            name: entity.name ?? "",
            amount: entity.amount as Decimal? ?? 0,
            startDate: entity.startDate ?? Date(),
            endDate: entity.endDate ?? Date(),
            isActive: entity.isActive,
            categoryBudgets: entity.categoryBudgets as? [String: Decimal] ?? [:]
        )
    }

    private func mapToEntity(_ domain: Budget, entity: BudgetEntity) {
        entity.id = domain.id
        entity.name = domain.name
        entity.amount = domain.amount as NSDecimalNumber
        entity.startDate = domain.startDate
        entity.endDate = domain.endDate
        entity.isActive = domain.isActive
        entity.categoryBudgets = domain.categoryBudgets as NSObject
    }
}
```

---

## 🛒 Feature 2: Shopping List Management

### 2.1 Shopping List Use Cases

Create `Domain/UseCases/ShoppingList/CreateShoppingListUseCase.swift`:

```swift
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

enum ValidationError: Error {
    case emptyName
    case invalidBudget
    case invalidAmount
    case invalidDateRange
}
```

Create `Domain/UseCases/ShoppingList/AddItemToShoppingListUseCase.swift`:

```swift
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

enum ValidationError: Error {
    case budgetExceeded
    case emptyName
    case invalidBudget
}
```

Create `Domain/UseCases/ShoppingList/MarkItemAsPurchasedUseCase.swift`:

```swift
import Foundation
import Combine

protocol MarkItemAsPurchasedUseCaseProtocol {
    func execute(
        listId: UUID,
        itemId: UUID,
        actualPrice: Decimal
    ) -> AnyPublisher<ShoppingList, Error>
}

class MarkItemAsPurchasedUseCase: MarkItemAsPurchasedUseCaseProtocol {
    private let shoppingListRepository: ShoppingListRepositoryProtocol
    private let purchaseRepository: PurchaseRepositoryProtocol

    init(
        shoppingListRepository: ShoppingListRepositoryProtocol,
        purchaseRepository: PurchaseRepositoryProtocol
    ) {
        self.shoppingListRepository = shoppingListRepository
        self.purchaseRepository = purchaseRepository
    }

    func execute(
        listId: UUID,
        itemId: UUID,
        actualPrice: Decimal
    ) -> AnyPublisher<ShoppingList, Error> {

        return shoppingListRepository.fetchShoppingList(byId: listId)
            .flatMap { [weak self] shoppingList -> AnyPublisher<ShoppingList, Error> in
                guard let self = self, var shoppingList = shoppingList else {
                    return Fail(error: UseCaseError.notFound).eraseToAnyPublisher()
                }

                guard let itemIndex = shoppingList.items.firstIndex(where: {
                    $0.id == itemId
                }) else {
                    return Fail(error: UseCaseError.notFound).eraseToAnyPublisher()
                }

                // Update item
                shoppingList.items[itemIndex].isPurchased = true
                shoppingList.items[itemIndex].purchasedAt = Date()
                shoppingList.items[itemIndex].actualPrice = actualPrice

                // Create purchase record
                let item = shoppingList.items[itemIndex]
                let purchase = Purchase(
                    id: UUID(),
                    groceryItemId: item.groceryItemId,
                    quantity: item.quantity,
                    price: actualPrice,
                    totalCost: actualPrice * item.quantity,
                    purchaseDate: Date(),
                    storeName: nil
                )

                // Save purchase and update list
                return self.purchaseRepository.createPurchase(purchase)
                    .flatMap { _ in
                        self.shoppingListRepository.updateShoppingList(shoppingList)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
```

### 2.2 Shopping List Repository

Create `Data/Repositories/ShoppingListRepository.swift`:

```swift
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
                promise(.failure(error))
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
                promise(.failure(error))
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
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }

    // Mapping methods...
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

        // Handle items separately
        // ... (complex relationship mapping)
    }
}
```

---

## 📦 Feature 3: Item Management

### 3.1 Item Use Cases

Create `Domain/UseCases/GroceryItem/SearchGroceryItemsUseCase.swift`:

```swift
import Foundation
import Combine

protocol SearchGroceryItemsUseCaseProtocol {
    func execute(query: String) -> AnyPublisher<[GroceryItem], Error>
}

class SearchGroceryItemsUseCase: SearchGroceryItemsUseCaseProtocol {
    private let repository: GroceryItemRepositoryProtocol

    init(repository: GroceryItemRepositoryProtocol) {
        self.repository = repository
    }

    func execute(query: String) -> AnyPublisher<[GroceryItem], Error> {
        guard !query.isEmpty else {
            return repository.fetchAllItems()
        }

        return repository.searchItems(query: query)
            .map { items in
                // Sort by relevance
                items.sorted { item1, item2 in
                    let score1 = self.relevanceScore(for: item1, query: query)
                    let score2 = self.relevanceScore(for: item2, query: query)
                    return score1 > score2
                }
            }
            .eraseToAnyPublisher()
    }

    private func relevanceScore(for item: GroceryItem, query: String) -> Int {
        let queryLower = query.lowercased()
        var score = 0

        // Exact match
        if item.name.lowercased() == queryLower {
            score += 100
        }

        // Starts with
        if item.name.lowercased().hasPrefix(queryLower) {
            score += 50
        }

        // Contains
        if item.name.lowercased().contains(queryLower) {
            score += 25
        }

        // Brand match
        if let brand = item.brand, brand.lowercased().contains(queryLower) {
            score += 10
        }

        return score
    }
}
```

Create `Domain/UseCases/GroceryItem/GetItemPriceHistoryUseCase.swift`:

```swift
import Foundation
import Combine

protocol GetItemPriceHistoryUseCaseProtocol {
    func execute(itemId: UUID) -> AnyPublisher<[PriceHistory], Error>
}

class GetItemPriceHistoryUseCase: GetItemPriceHistoryUseCaseProtocol {
    private let priceHistoryRepository: PriceHistoryRepositoryProtocol

    init(priceHistoryRepository: PriceHistoryRepositoryProtocol) {
        self.priceHistoryRepository = priceHistoryRepository
    }

    func execute(itemId: UUID) -> AnyPublisher<[PriceHistory], Error> {
        return priceHistoryRepository.fetchPriceHistory(for: itemId)
            .map { history in
                history.sorted { $0.recordedAt > $1.recordedAt }
            }
            .eraseToAnyPublisher()
    }
}
```

---

## 🔔 Feature 4: Notification System

### 4.1 Notification Manager

Create `Core/Utilities/NotificationManager.swift`:

```swift
import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    // MARK: - Expiration Notifications

    func scheduleExpirationReminder(for item: GroceryItem, expirationDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Item Expiring Soon"
        content.body = "\(item.name) will expire in 2 days. Use it soon to avoid waste!"
        content.sound = .default
        content.categoryIdentifier = "EXPIRATION"

        // Schedule 2 days before expiration
        let twoDaysBefore = Calendar.current.date(
            byAdding: .day,
            value: -2,
            to: expirationDate
        ) ?? expirationDate

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour],
            from: twoDaysBefore
        )

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(
            identifier: "expiration-\(item.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    // MARK: - Purchase Reminders

    func schedulePurchaseReminder(for item: GroceryItem, predictedDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Buy"
        content.body = "You usually buy \(item.name) around this time. Add it to your shopping list?"
        content.sound = .default
        content.categoryIdentifier = "PURCHASE_REMINDER"

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour],
            from: predictedDate
        )

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(
            identifier: "purchase-\(item.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Budget Alerts

    func scheduleBudgetAlert(budgetName: String, percentageUsed: Double) {
        guard percentageUsed >= 80 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Budget Alert"
        content.body = "You've used \(Int(percentageUsed))% of your \(budgetName) budget"
        content.sound = .default
        content.categoryIdentifier = "BUDGET_ALERT"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "budget-alert-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
```

---

## ✅ Acceptance Criteria

### Phase 3 Complete When:

- ✅ Budget CRUD operations implemented
- ✅ Budget summary with analytics working
- ✅ Shopping list CRUD operations implemented
- ✅ Add/remove items from shopping lists
- ✅ Mark items as purchased
- ✅ Item search with relevance scoring
- ✅ Purchase tracking implemented
- ✅ Price history tracking working
- ✅ Expiration tracking functional
- ✅ Notification system operational
- ✅ All use cases have unit tests (>80% coverage)
- ✅ Repository integration tests passing

---

## ⚠️ Potential Challenges

### Challenge 1: Complex Shopping List State
**Problem**: Managing item states and relationships
**Solution**: Use clear state machines; comprehensive validation

### Challenge 2: Budget Overlaps
**Problem**: Multiple active budgets causing confusion
**Solution**: Implement clear date range validation; auto-deactivate conflicts

### Challenge 3: Notification Timing
**Problem**: Notifications not firing at optimal times
**Solution**: User-configurable timing; learn from user behavior

### Challenge 4: Price History Accuracy
**Problem**: Inconsistent price data
**Solution**: Allow user corrections; validate outliers

---

## 🚀 Next Steps

Proceed to:
- **[Phase 4: ML Integration](04-PHASE-4-ML-INTEGRATION.md)** - Connect ML models with core features

---

## 📚 Resources

- [UserNotifications Framework](https://developer.apple.com/documentation/usernotifications)
- [Core Data Relationships](https://developer.apple.com/documentation/coredata/modeling_data)
- [Combine Operators](https://developer.apple.com/documentation/combine)
