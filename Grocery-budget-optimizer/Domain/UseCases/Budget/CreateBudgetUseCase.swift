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

                if deactivations.isEmpty {
                    return self.repository.createBudget(budget)
                }

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
    case emptyName
    case invalidBudget
    case budgetExceeded
}

enum UseCaseError: Error {
    case unknown
    case notFound
}
