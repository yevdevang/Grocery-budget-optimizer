import Foundation
import Combine
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var currentBudget: BudgetSummary?
    @Published var expiringItems: [ExpiringItemInfo] = []
    @Published var predictedPurchases: [ItemPurchasePrediction] = []
    @Published var recentPurchases: [Purchase] = []
    @Published var isLoading = false
    @Published var showingSmartList = false
    @Published var showingAddItem = false
    @Published var showingAddExpense = false
    @Published var showingScanner = false
    @Published var scannedProduct: ScannedProductInfo?

    private let getBudgetSummary: GetBudgetSummaryUseCaseProtocol
    private let getExpiringItems: GetExpiringItemsUseCaseProtocol
    private let getPredictions: GetPurchasePredictionsUseCaseProtocol
    private let purchaseRepository: PurchaseRepositoryProtocol
    private let scanProductUseCase: ScanProductUseCaseProtocol

    private var cancellables = Set<AnyCancellable>()

    init(
        getBudgetSummary: GetBudgetSummaryUseCaseProtocol,
        getExpiringItems: GetExpiringItemsUseCaseProtocol,
        getPredictions: GetPurchasePredictionsUseCaseProtocol,
        purchaseRepository: PurchaseRepositoryProtocol,
        scanProductUseCase: ScanProductUseCaseProtocol
    ) {
        self.getBudgetSummary = getBudgetSummary
        self.getExpiringItems = getExpiringItems
        self.getPredictions = getPredictions
        self.purchaseRepository = purchaseRepository
        self.scanProductUseCase = scanProductUseCase
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return L10n.Home.Greeting.morning
        case 12..<17: return L10n.Home.Greeting.afternoon
        default: return L10n.Home.Greeting.evening
        }
    }

    func loadData() async {
        isLoading = true
        await loadBudgetSummary()
        await loadExpiringItems()
        await loadPredictions()
        await loadRecentPurchases()
        isLoading = false
    }

    func refresh() async {
        await loadData()
    }

    private func loadBudgetSummary() async {
        // TODO: Get active budget ID first, for now skip
        // Once we have the active budget ID, call:
        // getBudgetSummary.execute(for: budgetId)
    }

    private func loadExpiringItems() async {
        getExpiringItems.execute(daysThreshold: 7)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] items in
                    self?.expiringItems = items
                }
            )
            .store(in: &cancellables)
    }

    private func loadPredictions() async {
        getPredictions.execute()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] predictions in
                    self?.predictedPurchases = predictions
                }
            )
            .store(in: &cancellables)
    }

    private func loadRecentPurchases() async {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate

        purchaseRepository.fetchPurchases(from: startDate, to: endDate)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] purchases in
                    self?.recentPurchases = Array(purchases.prefix(5))
                }
            )
            .store(in: &cancellables)
    }

    func createSmartList() {
        print("🎯 createSmartList tapped")
        showingSmartList = true
        print("📋 showingSmartList = \(showingSmartList)")
    }

    func showAddItem() {
        print("🎯 showAddItem tapped")
        showingAddItem = true
        print("📋 showingAddItem = \(showingAddItem)")
    }

    func showAddExpense() {
        print("🎯 showAddExpense tapped")
        showingAddExpense = true
        print("📋 showingAddExpense = \(showingAddExpense)")
    }

    func showAnalytics() {
        print("🎯 showAnalytics tapped")
        // Will navigate to analytics tab
    }

    func showScanner() {
        print("🎯 showScanner tapped")
        showingScanner = true
        print("📋 showingScanner = \(showingScanner)")
    }

    func handleScannedBarcode(_ barcode: String) {
        print("📱 Handling scanned barcode: \(barcode)")
        
        scanProductUseCase.execute(barcode: barcode)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("❌ Error fetching product: \(error)")
                        // Close scanner even on error
                        self?.showingScanner = false
                    }
                },
                receiveValue: { [weak self] productInfo in
                    if let productInfo = productInfo {
                        print("✅ Product info received, showing detail view")
                        // Close scanner first
                        self?.showingScanner = false
                        // Then show product detail after a brief delay to avoid sheet conflict
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self?.scannedProduct = productInfo
                        }
                    } else {
                        print("⚠️ Product not found in database")
                        self?.showingScanner = false
                        // TODO: Show alert to user
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func handleTestProduct(name: String, barcode: String) {
        print("🧪 Test product selected: \(name) (\(barcode))")
        
        // Create mock product data using REAL Israeli products from Open Food Facts database
        let testImageUrl: String
        let brand: String
        let category: String
        let unit: String
        
        switch name {
        case "Tnuva Milk 3%":
            testImageUrl = "https://images.openfoodfacts.org/images/products/729/000/413/1074/front_en.49.400.jpg"
            brand = "Tnuva"
            category = "Dairy"
            unit = "1L"
            
        case "Nescafe Coffee":
            testImageUrl = "https://images.openfoodfacts.org/images/products/729/000/007/2753/front_en.3.400.jpg"
            brand = "Nescafe"
            category = "Beverages"
            unit = "200g"
            
        case "Tnuva Cottage 5%":
            testImageUrl = "https://images.openfoodfacts.org/images/products/729/000/412/7329/front_en.30.400.jpg"
            brand = "Tnuva"
            category = "Dairy"
            unit = "250g"
            
        case "Osem Ketchup":
            testImageUrl = "https://images.openfoodfacts.org/images/products/729/000/007/2623/front_en.28.400.jpg"
            brand = "Osem"
            category = "Pantry"
            unit = "570g"
            
        default:
            testImageUrl = "https://images.openfoodfacts.org/images/products/729/000/413/1074/front_en.49.400.jpg"
            brand = "Test Brand"
            category = "Pantry"
            unit = "100g"
        }
        
        // Create mock product info
        let productInfo = ScannedProductInfo(
            barcode: barcode,
            name: name,
            brand: brand,
            category: category,
            unit: unit,
            imageUrl: testImageUrl,
            nutritionalInfo: nil as String?,
            averagePrice: nil as Decimal?,
            priceSource: .unavailable
        )
        
        // Close scanner and show product detail
        showingScanner = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.scannedProduct = productInfo
        }
    }
}
