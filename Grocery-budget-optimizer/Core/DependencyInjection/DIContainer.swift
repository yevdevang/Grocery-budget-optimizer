import Foundation

/// Dependency Injection Container for the entire app
class DIContainer {
    static let shared = DIContainer()

    private init() {
        setupRepositories()
        setupUseCases()
    }

    // MARK: - Repositories
    lazy var groceryItemRepository: GroceryItemRepositoryProtocol = {
        MockGroceryItemRepository()
    }()

    lazy var shoppingListRepository: ShoppingListRepositoryProtocol = {
        ShoppingListRepository(coreDataStack: CoreDataStack.shared)
    }()

    lazy var budgetRepository: BudgetRepositoryProtocol = {
        BudgetRepository(coreDataStack: CoreDataStack.shared)
    }()

    lazy var purchaseRepository: PurchaseRepositoryProtocol = {
        PurchaseRepository(coreDataStack: CoreDataStack.shared)
    }()

    lazy var priceHistoryRepository: PriceHistoryRepositoryProtocol = {
        PriceHistoryRepository(coreDataStack: CoreDataStack.shared)
    }()

    lazy var expirationTrackerRepository: ExpirationTrackerRepositoryProtocol = {
        // Create a mock repository for now
        MockExpirationTrackerRepository()
    }()

    // MARK: - ML Services
    lazy var mlCoordinator = MLCoordinator.shared

    // MARK: - Use Cases

    // Budget Use Cases
    lazy var getBudgetSummaryUseCase: GetBudgetSummaryUseCaseProtocol = {
        GetBudgetSummaryUseCase(
            budgetRepository: budgetRepository,
            purchaseRepository: purchaseRepository
        )
    }()

    lazy var createBudgetUseCase: CreateBudgetUseCaseProtocol = {
        CreateBudgetUseCase(repository: budgetRepository)
    }()

    // Shopping List Use Cases
    lazy var generateSmartShoppingListUseCase: GenerateSmartShoppingListUseCaseProtocol = {
        GenerateSmartShoppingListUseCase(
            shoppingListGenerator: mlCoordinator.getShoppingListGenerator(),
            purchaseRepository: purchaseRepository,
            groceryItemRepository: groceryItemRepository,
            shoppingListRepository: shoppingListRepository,
            purchasePredictor: mlCoordinator.getPurchasePredictor()
        )
    }()

    // Prediction Use Cases
    lazy var getPurchasePredictionsUseCase: GetPurchasePredictionsUseCaseProtocol = {
        GetPurchasePredictionsUseCase(
            purchasePredictor: mlCoordinator.getPurchasePredictor(),
            purchaseRepository: purchaseRepository,
            groceryItemRepository: groceryItemRepository,
            notificationManager: NotificationManager.shared
        )
    }()

    lazy var autoAddPredictedItemsUseCase: AutoAddPredictedItemsUseCaseProtocol = {
        AutoAddPredictedItemsUseCase(
            getPredictions: getPurchasePredictionsUseCase,
            addItem: addItemToShoppingListUseCase,
            shoppingListRepository: shoppingListRepository
        )
    }()

    // Price Use Cases
    lazy var getPriceRecommendationsUseCase: GetPriceRecommendationsUseCaseProtocol = {
        GetPriceRecommendationsUseCase(
            priceOptimizer: mlCoordinator.getPriceOptimizer(),
            shoppingListRepository: shoppingListRepository,
            groceryItemRepository: groceryItemRepository,
            priceHistoryRepository: priceHistoryRepository
        )
    }()

    lazy var recordPriceUseCase: RecordPriceUseCaseProtocol = {
        RecordPriceUseCase(
            priceHistoryRepository: priceHistoryRepository,
            groceryItemRepository: groceryItemRepository
        )
    }()

    // Expiration Use Cases
    lazy var getExpiringItemsUseCase: GetExpiringItemsUseCaseProtocol = {
        GetExpiringItemsUseCase(
            expirationRepository: expirationTrackerRepository,
            groceryItemRepository: groceryItemRepository
        )
    }()

    lazy var trackExpirationUseCase: TrackExpirationUseCaseProtocol = {
        TrackExpirationUseCase(
            expirationPredictor: mlCoordinator.getExpirationPredictor(),
            expirationRepository: expirationTrackerRepository,
            groceryItemRepository: groceryItemRepository,
            notificationManager: NotificationManager.shared
        )
    }()

    // Grocery Item Use Cases
    lazy var searchGroceryItemsUseCase: SearchGroceryItemsUseCaseProtocol = {
        SearchGroceryItemsUseCase(repository: groceryItemRepository)
    }()

    // Shopping List Use Cases
    lazy var addItemToShoppingListUseCase: AddItemToShoppingListUseCaseProtocol = {
        AddItemToShoppingListUseCase(
            shoppingListRepository: shoppingListRepository,
            groceryItemRepository: groceryItemRepository
        )
    }()

    // MARK: - Private Setup Methods

    private func setupRepositories() {
        // Initialize repositories
    }

    private func setupUseCases() {
        // Initialize use cases
    }
}
