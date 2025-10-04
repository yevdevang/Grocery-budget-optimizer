import Foundation
import Combine

@MainActor
class BudgetViewModel: ObservableObject {
    @Published var currentBudgetSummary: BudgetSummary?
    @Published var dailySpending: [DailySpendingData] = []
    @Published var isLoading = false
    @Published var showingCreateBudget = false

    private let getBudgetSummary: GetBudgetSummaryUseCaseProtocol
    private let purchaseRepository: PurchaseRepositoryProtocol
    private let budgetRepository: BudgetRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    init(
        getBudgetSummary: GetBudgetSummaryUseCaseProtocol = DIContainer.shared.getBudgetSummaryUseCase,
        purchaseRepository: PurchaseRepositoryProtocol = DIContainer.shared.purchaseRepository,
        budgetRepository: BudgetRepositoryProtocol = DIContainer.shared.budgetRepository
    ) {
        self.getBudgetSummary = getBudgetSummary
        self.purchaseRepository = purchaseRepository
        self.budgetRepository = budgetRepository
    }

    func loadBudget() async {
        isLoading = true

        // Fetch active budget
        budgetRepository.fetchActiveBudgets()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] _ in
                    self?.isLoading = false
                },
                receiveValue: { [weak self] activeBudgets in
                    guard let self = self, let activeBudget = activeBudgets.first else {
                        self?.isLoading = false
                        return
                    }

                    // Get budget summary
                    self.getBudgetSummary.execute(for: activeBudget.id)
                        .receive(on: DispatchQueue.main)
                        .sink(
                            receiveCompletion: { _ in },
                            receiveValue: { [weak self] summary in
                                self?.currentBudgetSummary = summary
                                Task {
                                    await self?.loadDailySpending()
                                }
                            }
                        )
                        .store(in: &self.cancellables)
                }
            )
            .store(in: &cancellables)
    }

    private func loadDailySpending() async {
        guard let budget = currentBudgetSummary?.budget else { return }

        purchaseRepository.fetchPurchases(from: budget.startDate, to: Date())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] purchases in
                    self?.calculateDailySpending(from: purchases)
                }
            )
            .store(in: &cancellables)
    }

    private func calculateDailySpending(from purchases: [Purchase]) {
        let calendar = Calendar.current
        var dailyTotals: [Date: Decimal] = [:]

        for purchase in purchases {
            let day = calendar.startOfDay(for: purchase.purchaseDate)
            dailyTotals[day, default: 0] += purchase.totalCost
        }

        dailySpending = dailyTotals.map { date, amount in
            DailySpendingData(date: date, amount: amount)
        }.sorted { $0.date < $1.date }
    }

    func showCreateBudget() {
        showingCreateBudget = true
    }

    func refreshBudget() async {
        await loadBudget()
    }
}

struct DailySpendingData: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Decimal
}
