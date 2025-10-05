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
        showingScanner = false

        scanProductUseCase.execute(barcode: barcode)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Error fetching product: \(error)")
                    }
                },
                receiveValue: { [weak self] productInfo in
                    if let productInfo = productInfo {
                        print("✅ Product info received, showing detail view")
                        self?.scannedProduct = productInfo
                    } else {
                        print("⚠️ Product not found in database")
                        // TODO: Show alert to user
                    }
                }
            )
            .store(in: &cancellables)
    }
}
