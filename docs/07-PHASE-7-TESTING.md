# Phase 7: Testing - Comprehensive Quality Assurance

## 📋 Overview

Implement comprehensive testing strategy covering unit tests, integration tests, UI tests, and ML model validation to ensure app quality and reliability.

**Duration**: 1 week
**Dependencies**: All previous phases

---

## 🎯 Objectives

- ✅ Unit tests for all use cases (>80% coverage)
- ✅ Repository integration tests
- ✅ ViewModel tests
- ✅ ML model accuracy validation
- ✅ UI tests for critical flows
- ✅ Performance tests
- ✅ Accessibility tests
- ✅ Set up CI/CD pipeline

---

## 🧪 Unit Testing Strategy

### Test Structure

```
Tests/
├── UnitTests/
│   ├── Domain/
│   │   ├── UseCases/
│   │   │   ├── Budget/
│   │   │   ├── ShoppingList/
│   │   │   ├── GroceryItem/
│   │   │   ├── Analytics/
│   │   │   └── Prediction/
│   │   └── Entities/
│   ├── Data/
│   │   ├── Repositories/
│   │   └── MLModels/
│   └── Presentation/
│       └── ViewModels/
├── IntegrationTests/
│   ├── CoreData/
│   └── MLIntegration/
├── UITests/
│   ├── Flows/
│   └── Screens/
└── PerformanceTests/
```

---

## 🔬 Unit Tests - Use Cases

### Budget Use Case Tests

Create `Tests/UnitTests/Domain/UseCases/Budget/CreateBudgetUseCaseTests.swift`:

```swift
import XCTest
import Combine
@testable import Grocery_budget_optimizer

final class CreateBudgetUseCaseTests: XCTestCase {
    var sut: CreateBudgetUseCase!
    var mockRepository: MockBudgetRepository!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockRepository = MockBudgetRepository()
        sut = CreateBudgetUseCase(repository: mockRepository)
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    func testCreateBudget_Success() {
        // Given
        let expectation = expectation(description: "Create budget")
        let budget = makeBudget(amount: 500, startDate: Date(), endDate: Date().addingTimeInterval(2592000))

        mockRepository.createBudgetResult = .success(budget)

        // When
        sut.execute(budget)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { createdBudget in
                    // Then
                    XCTAssertEqual(createdBudget.id, budget.id)
                    XCTAssertEqual(createdBudget.amount, budget.amount)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0)
    }

    func testCreateBudget_InvalidAmount_Fails() {
        // Given
        let expectation = expectation(description: "Invalid amount")
        let budget = makeBudget(amount: -100, startDate: Date(), endDate: Date().addingTimeInterval(2592000))

        // When
        sut.execute(budget)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        // Then
                        XCTAssertTrue(error is ValidationError)
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Expected failure")
                }
            )
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0)
    }

    func testCreateBudget_InvalidDateRange_Fails() {
        // Given
        let expectation = expectation(description: "Invalid date range")
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(86400) // End before start
        let budget = makeBudget(amount: 500, startDate: startDate, endDate: endDate)

        // When
        sut.execute(budget)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        // Then
                        XCTAssertTrue(error is ValidationError)
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Expected failure")
                }
            )
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0)
    }

    func testCreateBudget_DeactivatesOverlappingBudgets() {
        // Given
        let expectation = expectation(description: "Deactivate overlapping")

        let startDate = Date()
        let endDate = startDate.addingTimeInterval(2592000)

        let existingBudget = makeBudget(
            amount: 400,
            startDate: startDate,
            endDate: endDate,
            isActive: true
        )

        let newBudget = makeBudget(
            amount: 500,
            startDate: startDate.addingTimeInterval(1296000), // Overlaps
            endDate: endDate.addingTimeInterval(1296000)
        )

        mockRepository.fetchActiveBudgetsResult = .success([existingBudget])
        mockRepository.updateBudgetResult = .success(existingBudget)
        mockRepository.createBudgetResult = .success(newBudget)

        // When
        sut.execute(newBudget)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { createdBudget in
                    // Then
                    XCTAssertTrue(self.mockRepository.updateBudgetCalled)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0)
    }

    // MARK: - Helpers

    private func makeBudget(
        amount: Decimal,
        startDate: Date,
        endDate: Date,
        isActive: Bool = true
    ) -> Budget {
        Budget(
            id: UUID(),
            name: "Test Budget",
            amount: amount,
            startDate: startDate,
            endDate: endDate,
            isActive: isActive,
            categoryBudgets: [:]
        )
    }
}
```

### Shopping List Use Case Tests

Create `Tests/UnitTests/Domain/UseCases/ShoppingList/AddItemToShoppingListUseCaseTests.swift`:

```swift
import XCTest
import Combine
@testable import Grocery_budget_optimizer

final class AddItemToShoppingListUseCaseTests: XCTestCase {
    var sut: AddItemToShoppingListUseCase!
    var mockShoppingListRepo: MockShoppingListRepository!
    var mockGroceryItemRepo: MockGroceryItemRepository!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockShoppingListRepo = MockShoppingListRepository()
        mockGroceryItemRepo = MockGroceryItemRepository()
        sut = AddItemToShoppingListUseCase(
            shoppingListRepository: mockShoppingListRepo,
            groceryItemRepository: mockGroceryItemRepo
        )
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        mockGroceryItemRepo = nil
        mockShoppingListRepo = nil
        super.tearDown()
    }

    func testAddItem_NewItem_AddsSuccessfully() {
        // Given
        let expectation = expectation(description: "Add new item")

        var shoppingList = makeShoppingList(budgetAmount: 100)
        let newItem = makeShoppingListItem(estimatedPrice: 10, quantity: 2)

        mockShoppingListRepo.fetchShoppingListResult = .success(shoppingList)

        shoppingList.items.append(newItem)
        mockShoppingListRepo.updateShoppingListResult = .success(shoppingList)

        // When
        sut.execute(listId: shoppingList.id, item: newItem)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { updatedList in
                    // Then
                    XCTAssertEqual(updatedList.items.count, 1)
                    XCTAssertEqual(updatedList.totalEstimatedCost, 20)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0)
    }

    func testAddItem_ExistingItem_UpdatesQuantity() {
        // Given
        let expectation = expectation(description: "Update quantity")

        let itemId = UUID()
        let existingItem = makeShoppingListItem(
            groceryItemId: itemId,
            estimatedPrice: 10,
            quantity: 2
        )

        var shoppingList = makeShoppingList(budgetAmount: 100)
        shoppingList.items = [existingItem]

        let additionalItem = makeShoppingListItem(
            groceryItemId: itemId,
            estimatedPrice: 10,
            quantity: 3
        )

        mockShoppingListRepo.fetchShoppingListResult = .success(shoppingList)

        shoppingList.items[0].quantity = 5 // 2 + 3
        mockShoppingListRepo.updateShoppingListResult = .success(shoppingList)

        // When
        sut.execute(listId: shoppingList.id, item: additionalItem)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { updatedList in
                    // Then
                    XCTAssertEqual(updatedList.items.count, 1)
                    XCTAssertEqual(updatedList.items[0].quantity, 5)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0)
    }

    func testAddItem_ExceedsBudget_Fails() {
        // Given
        let expectation = expectation(description: "Exceeds budget")

        let shoppingList = makeShoppingList(budgetAmount: 20)
        let expensiveItem = makeShoppingListItem(estimatedPrice: 30, quantity: 1)

        mockShoppingListRepo.fetchShoppingListResult = .success(shoppingList)

        // When
        sut.execute(listId: shoppingList.id, item: expensiveItem)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        // Then
                        XCTAssertTrue(error is ValidationError)
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Expected failure")
                }
            )
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0)
    }

    // MARK: - Helpers

    private func makeShoppingList(budgetAmount: Decimal) -> ShoppingList {
        ShoppingList(
            id: UUID(),
            name: "Test List",
            budgetAmount: budgetAmount,
            items: [],
            createdAt: Date(),
            updatedAt: Date(),
            isCompleted: false,
            completedAt: nil
        )
    }

    private func makeShoppingListItem(
        groceryItemId: UUID = UUID(),
        estimatedPrice: Decimal,
        quantity: Decimal
    ) -> ShoppingListItem {
        ShoppingListItem(
            groceryItemId: groceryItemId,
            quantity: quantity,
            estimatedPrice: estimatedPrice
        )
    }
}
```

---

## 🔗 Integration Tests

### Core Data Integration Tests

Create `Tests/IntegrationTests/CoreData/GroceryItemRepositoryIntegrationTests.swift`:

```swift
import XCTest
import CoreData
import Combine
@testable import Grocery_budget_optimizer

final class GroceryItemRepositoryIntegrationTests: XCTestCase {
    var sut: GroceryItemRepository!
    var coreDataStack: TestCoreDataStack!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        coreDataStack = TestCoreDataStack()
        sut = GroceryItemRepository(coreDataStack: coreDataStack)
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        coreDataStack = nil
        super.tearDown()
    }

    func testCreateAndFetchItem() {
        // Given
        let expectation = expectation(description: "Create and fetch")
        let item = GroceryItem(
            name: "Test Milk",
            category: "Dairy",
            unit: "L",
            averagePrice: 3.99
        )

        // When
        sut.createItem(item)
            .flatMap { _ in self.sut.fetchItem(byId: item.id) }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { fetchedItem in
                    // Then
                    XCTAssertNotNil(fetchedItem)
                    XCTAssertEqual(fetchedItem?.name, "Test Milk")
                    XCTAssertEqual(fetchedItem?.category, "Dairy")
                    XCTAssertEqual(fetchedItem?.averagePrice, 3.99)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        waitForExpectations(timeout: 2.0)
    }

    func testSearchItems() {
        // Given
        let expectation = expectation(description: "Search items")

        let items = [
            GroceryItem(name: "Whole Milk", category: "Dairy", unit: "L", averagePrice: 3.99),
            GroceryItem(name: "Skim Milk", category: "Dairy", unit: "L", averagePrice: 3.49),
            GroceryItem(name: "Bread", category: "Bakery", unit: "loaf", averagePrice: 2.99)
        ]

        let createPublishers = items.map { sut.createItem($0) }

        // When
        Publishers.MergeMany(createPublishers)
            .collect()
            .flatMap { _ in self.sut.searchItems(query: "Milk") }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { results in
                    // Then
                    XCTAssertEqual(results.count, 2)
                    XCTAssertTrue(results.allSatisfy { $0.name.contains("Milk") })
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        waitForExpectations(timeout: 2.0)
    }

    func testUpdateItem() {
        // Given
        let expectation = expectation(description: "Update item")
        var item = GroceryItem(
            name: "Milk",
            category: "Dairy",
            unit: "L",
            averagePrice: 3.99
        )

        // When
        sut.createItem(item)
            .flatMap { createdItem -> AnyPublisher<GroceryItem, Error> in
                var updatedItem = createdItem
                updatedItem.averagePrice = 4.49
                updatedItem.brand = "Brand X"
                return self.sut.updateItem(updatedItem)
            }
            .flatMap { _ in self.sut.fetchItem(byId: item.id) }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { fetchedItem in
                    // Then
                    XCTAssertEqual(fetchedItem?.averagePrice, 4.49)
                    XCTAssertEqual(fetchedItem?.brand, "Brand X")
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        waitForExpectations(timeout: 2.0)
    }

    func testDeleteItem() {
        // Given
        let expectation = expectation(description: "Delete item")
        let item = GroceryItem(
            name: "Milk",
            category: "Dairy",
            unit: "L",
            averagePrice: 3.99
        )

        // When
        sut.createItem(item)
            .flatMap { _ in self.sut.deleteItem(byId: item.id) }
            .flatMap { _ in self.sut.fetchItem(byId: item.id) }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { fetchedItem in
                    // Then
                    XCTAssertNil(fetchedItem)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        waitForExpectations(timeout: 2.0)
    }
}

// Test Core Data Stack
class TestCoreDataStack: CoreDataStack {
    override init() {
        super.init()
        // Override with in-memory store for testing
    }
}
```

---

## 🤖 ML Model Tests

### ML Service Tests

Create `Tests/UnitTests/Data/MLModels/PurchasePredictionServiceTests.swift`:

```swift
import XCTest
@testable import Grocery_budget_optimizer

final class PurchasePredictionServiceTests: XCTestCase {
    var sut: PurchasePredictionService!

    override func setUp() {
        super.setUp()
        sut = PurchasePredictionService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testPredictNextPurchase_SufficientHistory_ReturnsValidPrediction() {
        // Given
        let item = makeGroceryItem()
        let history = makeRegularPurchaseHistory(item: item, intervals: [7, 7, 7, 7])

        // When
        let result = sut.predictNextPurchase(for: item, history: history)

        // Then
        switch result {
        case .success(let prediction):
            XCTAssertGreaterThan(prediction.daysUntilPurchase, 0)
            XCTAssertLessThan(prediction.daysUntilPurchase, 14)
            XCTAssertGreaterThan(prediction.confidence, 0.5)

        case .failure:
            XCTFail("Expected success")
        }
    }

    func testPredictNextPurchase_InsufficientHistory_Fails() {
        // Given
        let item = makeGroceryItem()
        let history = [makePurchase(item: item, daysAgo: 7)]

        // When
        let result = sut.predictNextPurchase(for: item, history: history)

        // Then
        switch result {
        case .success:
            XCTFail("Expected failure")

        case .failure(let error):
            XCTAssertEqual(error, .invalidInput)
        }
    }

    func testPredictNextPurchase_IrregularPattern_LowerConfidence() {
        // Given
        let item = makeGroceryItem()
        let history = makeRegularPurchaseHistory(item: item, intervals: [3, 10, 5, 14, 7])

        // When
        let result = sut.predictNextPurchase(for: item, history: history)

        // Then
        switch result {
        case .success(let prediction):
            XCTAssertLessThan(prediction.confidence, 0.7)

        case .failure:
            XCTFail("Expected success")
        }
    }

    // MARK: - Helpers

    private func makeGroceryItem() -> GroceryItem {
        GroceryItem(
            name: "Milk",
            category: "Dairy",
            unit: "L",
            averagePrice: 3.99
        )
    }

    private func makePurchase(item: GroceryItem, daysAgo: Int) -> Purchase {
        Purchase(
            id: UUID(),
            groceryItemId: item.id,
            quantity: 1,
            price: 3.99,
            totalCost: 3.99,
            purchaseDate: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
            storeName: nil
        )
    }

    private func makeRegularPurchaseHistory(
        item: GroceryItem,
        intervals: [Int]
    ) -> [Purchase] {
        var purchases: [Purchase] = []
        var currentDate = Date()

        for interval in intervals.reversed() {
            currentDate = Calendar.current.date(byAdding: .day, value: -interval, to: currentDate)!
            purchases.append(makePurchase(item: item, daysAgo: 0))
        }

        return purchases
    }
}
```

---

## 🎨 UI Tests

### Critical Flow Tests

Create `Tests/UITests/Flows/ShoppingListFlowTests.swift`:

```swift
import XCTest

final class ShoppingListFlowTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testCreateShoppingList_ManualFlow() {
        // Navigate to shopping lists
        app.tabBars.buttons["Lists"].tap()

        // Tap create button
        app.navigationBars.buttons["plus.circle.fill"].tap()

        // Select manual list
        app.buttons["Manual List"].tap()

        // Fill in list details
        let nameField = app.textFields["List Name"]
        nameField.tap()
        nameField.typeText("Weekly Groceries")

        let budgetField = app.textFields["Budget Amount"]
        budgetField.tap()
        budgetField.typeText("150")

        // Create list
        app.buttons["Create"].tap()

        // Verify list was created
        XCTAssertTrue(app.staticTexts["Weekly Groceries"].exists)
    }

    func testAddItemToShoppingList() {
        // Assuming list already exists
        app.tabBars.buttons["Lists"].tap()

        // Tap on a list
        app.staticTexts["Weekly Groceries"].tap()

        // Add item
        app.navigationBars.buttons["plus"].tap()

        // Search for item
        let searchField = app.searchFields.firstMatch
        searchField.tap()
        searchField.typeText("Milk")

        // Select item
        app.staticTexts["Whole Milk"].tap()

        // Set quantity
        let quantityField = app.textFields["Quantity"]
        quantityField.tap()
        quantityField.typeText("2")

        // Add to list
        app.buttons["Add to List"].tap()

        // Verify item added
        XCTAssertTrue(app.staticTexts["Whole Milk"].exists)
        XCTAssertTrue(app.staticTexts["Qty: 2"].exists)
    }

    func testMarkItemAsPurchased() {
        // Navigate to list with items
        app.tabBars.buttons["Lists"].tap()
        app.staticTexts["Weekly Groceries"].tap()

        // Tap checkmark for item
        let checkmarkButton = app.buttons.matching(identifier: "circle").firstMatch
        checkmarkButton.tap()

        // Enter actual price
        let priceField = app.textFields["Actual Price"]
        XCTAssertTrue(priceField.waitForExistence(timeout: 2))
        priceField.tap()
        priceField.typeText("3.99")

        app.buttons["Confirm"].tap()

        // Verify item marked as purchased
        XCTAssertTrue(app.buttons["checkmark.circle.fill"].exists)
    }

    func testCompleteShoppingList() {
        // Navigate to list
        app.tabBars.buttons["Lists"].tap()
        app.staticTexts["Weekly Groceries"].tap()

        // Tap more button
        app.navigationBars.buttons["ellipsis.circle"].tap()

        // Complete list
        app.buttons["Complete"].tap()

        // Verify list moved to completed section
        app.navigationBars.buttons["Back"].tap()
        XCTAssertTrue(app.staticTexts["Completed"].exists)
    }
}
```

---

## ⚡ Performance Tests

Create `Tests/PerformanceTests/AnalyticsPerformanceTests.swift`:

```swift
import XCTest
@testable import Grocery_budget_optimizer

final class AnalyticsPerformanceTests: XCTestCase {

    func testSpendingAnalysis_LargeDataset_CompletesQuickly() {
        // Given
        let useCase = GetSpendingSummaryUseCase(
            purchaseRepository: MockPurchaseRepository(),
            groceryItemRepository: MockGroceryItemRepository(),
            budgetRepository: MockBudgetRepository()
        )

        let period = DateInterval(
            start: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
            end: Date()
        )

        // When
        measure {
            let expectation = expectation(description: "Analytics")

            useCase.execute(for: period)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { _ in
                        expectation.fulfill()
                    }
                )
                .store(in: &cancellables)

            wait(for: [expectation], timeout: 1.0)
        }

        // Then: Should complete in < 500ms
    }

    func testMLPrediction_RespondsQuickly() {
        // Given
        let service = PurchasePredictionService()
        let item = makeGroceryItem()
        let history = makeLargePurchaseHistory()

        // When
        measure {
            _ = service.predictNextPurchase(for: item, history: history)
        }

        // Then: Should complete in < 100ms
    }
}
```

---

## ♿ Accessibility Tests

Create `Tests/UITests/AccessibilityTests.swift`:

```swift
import XCTest

final class AccessibilityTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }

    func testVoiceOverLabels_HomeScreen() {
        // Verify all interactive elements have accessibility labels
        XCTAssertNotNil(app.tabBars.buttons["Home"].label)
        XCTAssertNotNil(app.buttons["Create Smart List"].label)
    }

    func testDynamicType_SupportsLargeText() {
        // Enable large text
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge"]
        app.launch()

        // Verify text scales appropriately
        // Content should remain readable and not truncated
    }

    func testColorBlindness_SufficientContrast() {
        // Verify color contrast ratios meet WCAG AA standards
        // Red/green combinations avoided for critical information
    }
}
```

---

## 🔄 CI/CD Setup

### GitHub Actions Workflow

Create `.github/workflows/ios-tests.yml`:

```yaml
name: iOS Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    name: Test
    runs-on: macos-latest

    steps:
    - name: Checkout
      uses: actions/checkout@v3

    - name: Set up Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: latest-stable

    - name: Install Dependencies
      run: |
        cd Grocery-budget-optimizer
        # Add dependency installation if needed

    - name: Run Unit Tests
      run: |
        xcodebuild test \
          -scheme Grocery-budget-optimizer \
          -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' \
          -testPlan UnitTests \
          -enableCodeCoverage YES

    - name: Run UI Tests
      run: |
        xcodebuild test \
          -scheme Grocery-budget-optimizer \
          -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' \
          -testPlan UITests

    - name: Generate Code Coverage Report
      run: |
        xcrun xccov view --report --json \
          $(find ~/Library/Developer/Xcode/DerivedData -name '*.xccovarchive' | head -1) \
          > coverage.json

    - name: Upload Coverage
      uses: codecov/codecov-action@v3
      with:
        files: ./coverage.json
        fail_ci_if_error: true
```

---

## ✅ Acceptance Criteria

### Phase 7 Complete When:

- ✅ Unit test coverage >80% for domain layer
- ✅ All critical use cases tested
- ✅ Integration tests for repositories passing
- ✅ ML model accuracy validated (>70%)
- ✅ UI tests for main flows implemented
- ✅ Performance tests passing (<500ms for analytics)
- ✅ Accessibility tests implemented
- ✅ CI/CD pipeline running successfully
- ✅ Test documentation complete

---

## 🚀 Next Steps

Proceed to:
- **[Phase 8: Polish](08-PHASE-8-POLISH.md)** - Final polish and app store preparation

---

## 📚 Resources

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [UI Testing Guide](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/09-ui_testing.html)
- [Accessibility Testing](https://developer.apple.com/documentation/accessibility/testing-your-app-for-accessibility)
