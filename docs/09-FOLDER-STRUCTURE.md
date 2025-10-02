# Complete Folder Structure - Clean Architecture

## 📋 Overview

This document provides the complete folder structure for the Grocery Budget Optimizer app following Clean Architecture principles with MVVM pattern.

---

## 🗂️ Project Structure

```
Grocery-budget-optimizer/
├── Grocery-budget-optimizer/              # Main app target
│   ├── App/                               # App entry point
│   │   ├── Grocery_budget_optimizerApp.swift
│   │   └── AppDelegate.swift
│   │
│   ├── Domain/                            # Business Logic Layer
│   │   ├── Entities/                      # Domain models
│   │   │   ├── GroceryItem.swift
│   │   │   ├── ShoppingList.swift
│   │   │   ├── ShoppingListItem.swift
│   │   │   ├── Purchase.swift
│   │   │   ├── Budget.swift
│   │   │   ├── Category.swift
│   │   │   ├── PriceHistory.swift
│   │   │   ├── ExpirationTracker.swift
│   │   │   └── Analytics/
│   │   │       ├── SpendingSummary.swift
│   │   │       ├── SavingsOpportunity.swift
│   │   │       └── WasteAnalytics.swift
│   │   │
│   │   ├── UseCases/                      # Business use cases
│   │   │   ├── Budget/
│   │   │   │   ├── CreateBudgetUseCase.swift
│   │   │   │   ├── UpdateBudgetUseCase.swift
│   │   │   │   ├── GetBudgetSummaryUseCase.swift
│   │   │   │   └── DeleteBudgetUseCase.swift
│   │   │   │
│   │   │   ├── ShoppingList/
│   │   │   │   ├── CreateShoppingListUseCase.swift
│   │   │   │   ├── AddItemToShoppingListUseCase.swift
│   │   │   │   ├── RemoveItemFromShoppingListUseCase.swift
│   │   │   │   ├── MarkItemAsPurchasedUseCase.swift
│   │   │   │   ├── CompleteShoppingListUseCase.swift
│   │   │   │   └── GenerateSmartShoppingListUseCase.swift
│   │   │   │
│   │   │   ├── GroceryItem/
│   │   │   │   ├── CreateGroceryItemUseCase.swift
│   │   │   │   ├── UpdateGroceryItemUseCase.swift
│   │   │   │   ├── SearchGroceryItemsUseCase.swift
│   │   │   │   ├── GetItemPriceHistoryUseCase.swift
│   │   │   │   └── DeleteGroceryItemUseCase.swift
│   │   │   │
│   │   │   ├── Purchase/
│   │   │   │   ├── RecordPurchaseUseCase.swift
│   │   │   │   └── GetPurchaseHistoryUseCase.swift
│   │   │   │
│   │   │   ├── Prediction/
│   │   │   │   ├── GetPurchasePredictionsUseCase.swift
│   │   │   │   └── AutoAddPredictedItemsUseCase.swift
│   │   │   │
│   │   │   ├── Price/
│   │   │   │   ├── GetPriceRecommendationsUseCase.swift
│   │   │   │   └── RecordPriceUseCase.swift
│   │   │   │
│   │   │   ├── Expiration/
│   │   │   │   ├── TrackExpirationUseCase.swift
│   │   │   │   ├── GetExpiringItemsUseCase.swift
│   │   │   │   └── MarkItemConsumedUseCase.swift
│   │   │   │
│   │   │   └── Analytics/
│   │   │       ├── GetSpendingSummaryUseCase.swift
│   │   │       ├── DetectSavingsOpportunitiesUseCase.swift
│   │   │       └── GetWasteAnalyticsUseCase.swift
│   │   │
│   │   └── RepositoryProtocols/           # Repository interfaces
│   │       ├── GroceryItemRepositoryProtocol.swift
│   │       ├── ShoppingListRepositoryProtocol.swift
│   │       ├── PurchaseRepositoryProtocol.swift
│   │       ├── BudgetRepositoryProtocol.swift
│   │       ├── PriceHistoryRepositoryProtocol.swift
│   │       └── ExpirationTrackerRepositoryProtocol.swift
│   │
│   ├── Data/                              # Data Layer
│   │   ├── CoreData/
│   │   │   ├── CoreDataStack.swift
│   │   │   ├── CoreDataOptimizer.swift
│   │   │   ├── GroceryBudgetOptimizer.xcdatamodeld
│   │   │   └── Entities/                  # Core Data entity extensions
│   │   │       ├── GroceryItemEntity+Extensions.swift
│   │   │       ├── ShoppingListEntity+Extensions.swift
│   │   │       ├── PurchaseEntity+Extensions.swift
│   │   │       └── BudgetEntity+Extensions.swift
│   │   │
│   │   ├── Repositories/                  # Repository implementations
│   │   │   ├── GroceryItemRepository.swift
│   │   │   ├── ShoppingListRepository.swift
│   │   │   ├── PurchaseRepository.swift
│   │   │   ├── BudgetRepository.swift
│   │   │   ├── PriceHistoryRepository.swift
│   │   │   └── ExpirationTrackerRepository.swift
│   │   │
│   │   └── MLModels/                      # Machine Learning
│   │       ├── MLCoordinator.swift
│   │       ├── ShoppingListGeneratorService.swift
│   │       ├── PurchasePredictionService.swift
│   │       ├── PriceOptimizationService.swift
│   │       ├── ExpirationPredictionService.swift
│   │       ├── Models/                    # .mlmodel files
│   │       │   ├── ShoppingListGenerator.mlmodel
│   │       │   ├── PurchasePredictor.mlmodel
│   │       │   ├── PriceOptimizer.mlmodel
│   │       │   └── ExpirationPredictor.mlmodel
│   │       └── Training/                  # ML training scripts
│   │           ├── ShoppingListDataGenerator.swift
│   │           ├── PurchaseDataPreparation.swift
│   │           └── PriceDataPreparation.swift
│   │
│   ├── Presentation/                      # Presentation Layer
│   │   ├── Navigation/
│   │   │   └── MainTabView.swift
│   │   │
│   │   ├── Screens/
│   │   │   ├── Home/
│   │   │   │   ├── HomeView.swift
│   │   │   │   └── HomeViewModel.swift
│   │   │   │
│   │   │   ├── ShoppingLists/
│   │   │   │   ├── ShoppingListsView.swift
│   │   │   │   ├── ShoppingListsViewModel.swift
│   │   │   │   ├── ShoppingListDetailView.swift
│   │   │   │   ├── ShoppingListDetailViewModel.swift
│   │   │   │   ├── CreateShoppingListView.swift
│   │   │   │   └── AddItemToListView.swift
│   │   │   │
│   │   │   ├── Items/
│   │   │   │   ├── ItemsView.swift
│   │   │   │   ├── ItemsViewModel.swift
│   │   │   │   ├── ItemDetailView.swift
│   │   │   │   ├── ItemDetailViewModel.swift
│   │   │   │   └── AddItemView.swift
│   │   │   │
│   │   │   ├── Budget/
│   │   │   │   ├── BudgetView.swift
│   │   │   │   ├── BudgetViewModel.swift
│   │   │   │   ├── CreateBudgetView.swift
│   │   │   │   └── BudgetDetailView.swift
│   │   │   │
│   │   │   ├── Analytics/
│   │   │   │   ├── AnalyticsView.swift
│   │   │   │   ├── AnalyticsViewModel.swift
│   │   │   │   ├── SavingsOpportunitiesView.swift
│   │   │   │   └── WasteAnalyticsView.swift
│   │   │   │
│   │   │   ├── Settings/
│   │   │   │   ├── SettingsView.swift
│   │   │   │   ├── SettingsViewModel.swift
│   │   │   │   ├── PreferencesView.swift
│   │   │   │   └── AboutView.swift
│   │   │   │
│   │   │   └── Onboarding/
│   │   │       ├── OnboardingView.swift
│   │   │       ├── OnboardingPageView.swift
│   │   │       └── OnboardingSetupView.swift
│   │   │
│   │   ├── ViewModels/                    # Shared view models
│   │   │   └── BaseViewModel.swift
│   │   │
│   │   ├── Components/                    # Reusable UI components
│   │   │   ├── Cards/
│   │   │   │   ├── BudgetSummaryCard.swift
│   │   │   │   ├── ExpiringItemCard.swift
│   │   │   │   ├── PredictionCard.swift
│   │   │   │   └── SavingsOpportunityCard.swift
│   │   │   │
│   │   │   ├── Buttons/
│   │   │   │   ├── QuickActionButton.swift
│   │   │   │   └── CategoryChip.swift
│   │   │   │
│   │   │   ├── Rows/
│   │   │   │   ├── ShoppingListRow.swift
│   │   │   │   ├── ShoppingListItemRow.swift
│   │   │   │   ├── ItemRow.swift
│   │   │   │   ├── PurchaseRow.swift
│   │   │   │   └── PredictionRow.swift
│   │   │   │
│   │   │   ├── Charts/
│   │   │   │   ├── SpendingChart.swift
│   │   │   │   ├── CategoryPieChart.swift
│   │   │   │   └── TrendLineChart.swift
│   │   │   │
│   │   │   └── Common/
│   │   │       ├── LoadingView.swift
│   │   │       ├── ErrorView.swift
│   │   │       ├── EmptyStateView.swift
│   │   │       └── ShimmerLoadingView.swift
│   │   │
│   │   └── Common/                        # Common presentation utilities
│   │       ├── AnimationConstants.swift
│   │       └── ViewModifiers/
│   │           ├── CardModifier.swift
│   │           └── ShimmerModifier.swift
│   │
│   ├── Core/                              # Core utilities and extensions
│   │   ├── Extensions/
│   │   │   ├── Decimal+Extensions.swift
│   │   │   ├── Date+Extensions.swift
│   │   │   ├── String+Extensions.swift
│   │   │   ├── Color+Extensions.swift
│   │   │   └── View+Extensions.swift
│   │   │
│   │   ├── Utilities/
│   │   │   ├── NotificationManager.swift
│   │   │   ├── ImageOptimizer.swift
│   │   │   ├── MemoryManager.swift
│   │   │   ├── BackgroundTaskManager.swift
│   │   │   └── Logger.swift
│   │   │
│   │   ├── DependencyInjection/
│   │   │   ├── DIContainer.swift
│   │   │   └── ServiceLocator.swift
│   │   │
│   │   └── Constants/
│   │       ├── AppConstants.swift
│   │       ├── ColorPalette.swift
│   │       └── Typography.swift
│   │
│   └── Resources/                         # App resources
│       ├── Assets.xcassets/
│       │   ├── AppIcon.appiconset/
│       │   ├── Colors/
│       │   └── Images/
│       │
│       ├── Localization/
│       │   ├── en.lproj/
│       │   │   └── Localizable.strings
│       │   └── es.lproj/
│       │       └── Localizable.strings
│       │
│       ├── Info.plist
│       └── privacy-policy.md
│
├── Grocery-budget-optimizerTests/         # Unit & Integration Tests
│   ├── UnitTests/
│   │   ├── Domain/
│   │   │   ├── UseCases/
│   │   │   │   ├── Budget/
│   │   │   │   │   ├── CreateBudgetUseCaseTests.swift
│   │   │   │   │   └── GetBudgetSummaryUseCaseTests.swift
│   │   │   │   ├── ShoppingList/
│   │   │   │   │   ├── AddItemToShoppingListUseCaseTests.swift
│   │   │   │   │   └── MarkItemAsPurchasedUseCaseTests.swift
│   │   │   │   └── Analytics/
│   │   │   │       └── GetSpendingSummaryUseCaseTests.swift
│   │   │   │
│   │   │   └── Entities/
│   │   │       └── EntityTests.swift
│   │   │
│   │   ├── Data/
│   │   │   ├── Repositories/
│   │   │   │   └── GroceryItemRepositoryTests.swift
│   │   │   │
│   │   │   └── MLModels/
│   │   │       ├── ShoppingListGeneratorTests.swift
│   │   │       └── PurchasePredictionServiceTests.swift
│   │   │
│   │   └── Presentation/
│   │       └── ViewModels/
│   │           └── HomeViewModelTests.swift
│   │
│   ├── IntegrationTests/
│   │   ├── CoreData/
│   │   │   └── GroceryItemRepositoryIntegrationTests.swift
│   │   │
│   │   └── MLIntegration/
│   │       └── MLCoordinatorIntegrationTests.swift
│   │
│   ├── PerformanceTests/
│   │   ├── AnalyticsPerformanceTests.swift
│   │   └── MLPerformanceTests.swift
│   │
│   ├── Mocks/
│   │   ├── MockBudgetRepository.swift
│   │   ├── MockShoppingListRepository.swift
│   │   ├── MockGroceryItemRepository.swift
│   │   └── MockCoreDataStack.swift
│   │
│   └── Helpers/
│       ├── TestHelpers.swift
│       └── BaseTestCase.swift
│
├── Grocery-budget-optimizerUITests/        # UI Tests
│   ├── Flows/
│   │   ├── ShoppingListFlowTests.swift
│   │   ├── BudgetFlowTests.swift
│   │   └── OnboardingFlowTests.swift
│   │
│   ├── Screens/
│   │   ├── HomeScreenTests.swift
│   │   ├── ShoppingListScreenTests.swift
│   │   └── BudgetScreenTests.swift
│   │
│   ├── AccessibilityTests.swift
│   │
│   └── Helpers/
│       └── UITestHelpers.swift
│
├── docs/                                   # Documentation
│   ├── 00-PROJECT-OVERVIEW.md
│   ├── 01-PHASE-1-FOUNDATION.md
│   ├── 02-PHASE-2-ML-MODELS.md
│   ├── 03-PHASE-3-CORE-FEATURES.md
│   ├── 04-PHASE-4-ML-INTEGRATION.md
│   ├── 05-PHASE-5-UI-UX.md
│   ├── 06-PHASE-6-ANALYTICS.md
│   ├── 07-PHASE-7-TESTING.md
│   ├── 08-PHASE-8-POLISH.md
│   └── 09-FOLDER-STRUCTURE.md
│
├── .github/
│   └── workflows/
│       └── ios-tests.yml                  # CI/CD configuration
│
├── .gitignore
├── README.md
└── LICENSE
```

---

## 📦 Key Directories Explained

### `/Domain` - Business Logic
Pure Swift code, no dependencies on frameworks. Contains entities, use cases, and repository protocols.

### `/Data` - Data Sources
Implements repository protocols, handles Core Data, and manages ML models.

### `/Presentation` - UI Layer
SwiftUI views, view models, and reusable components. Depends on Domain layer.

### `/Core` - Shared Utilities
Extensions, utilities, and constants used across all layers.

### `/Resources` - Assets
Images, colors, localization files, and app configuration.

### `/Tests` - Testing
Comprehensive test coverage including unit, integration, UI, and performance tests.

---

## 🔗 Dependency Flow

```
Presentation → Domain ← Data
     ↓           ↓        ↓
   Core ←←←←←←←←←←←←←←←←←←
```

**Key Principles:**
- Presentation depends on Domain
- Data depends on Domain
- Domain depends on nothing (pure Swift)
- Core is shared by all layers

---

## 📝 File Naming Conventions

- **Views**: `*View.swift` (e.g., `HomeView.swift`)
- **ViewModels**: `*ViewModel.swift` (e.g., `HomeViewModel.swift`)
- **Use Cases**: `*UseCase.swift` (e.g., `CreateBudgetUseCase.swift`)
- **Protocols**: `*Protocol.swift` (e.g., `GroceryItemRepositoryProtocol.swift`)
- **Repositories**: `*Repository.swift` (e.g., `GroceryItemRepository.swift`)
- **Extensions**: `*+Extensions.swift` (e.g., `Date+Extensions.swift`)
- **Tests**: `*Tests.swift` (e.g., `HomeViewModelTests.swift`)

---

## 🎯 Benefits of This Structure

### Maintainability
- Clear separation of concerns
- Easy to locate files
- Logical grouping

### Testability
- Domain layer completely testable
- Easy to mock dependencies
- Isolated test targets

### Scalability
- Add features without restructuring
- Clear patterns to follow
- Team-friendly organization

### Reusability
- Common components easily shared
- Use cases can be combined
- Repository implementations swappable

---

## 🚀 Getting Started

1. **Clone the repository**
2. **Open** `Grocery-budget-optimizer.xcodeproj`
3. **Review** `/docs` for implementation guides
4. **Start with** Phase 1 (Foundation)
5. **Follow** the documented phases sequentially

---

## 📚 Additional Resources

- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [MVVM Pattern](https://www.objc.io/issues/13-architecture/mvvm/)
- [iOS Project Best Practices](https://github.com/futurice/ios-good-practices)
- [Swift Style Guide](https://google.github.io/swift/)

---

**Ready to build?** Start with [Phase 1: Foundation](01-PHASE-1-FOUNDATION.md)!
