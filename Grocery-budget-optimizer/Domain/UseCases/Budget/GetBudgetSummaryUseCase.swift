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
        let percentageUsed = totalSpent == 0 ? 0 : (totalSpent / budget.amount).doubleValue * 100

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
