import Foundation
import Combine

protocol BudgetRepositoryProtocol {
    func createBudget(_ budget: Budget) -> AnyPublisher<Budget, Error>
    func updateBudget(_ budget: Budget) -> AnyPublisher<Budget, Error>
    func deleteBudget(byId id: UUID) -> AnyPublisher<Void, Error>
    func fetchBudget(byId id: UUID) -> AnyPublisher<Budget?, Error>
    func fetchActiveBudgets() -> AnyPublisher<[Budget], Error>
    func fetchAllBudgets() -> AnyPublisher<[Budget], Error>
}
