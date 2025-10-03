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
                promise(.failure(RepositoryError.saveFailed))
            }
        }
        .eraseToAnyPublisher()
    }

    func updateBudget(_ budget: Budget) -> AnyPublisher<Budget, Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let request: NSFetchRequest<BudgetEntity> = BudgetEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", budget.id as CVarArg)
            request.fetchLimit = 1

            do {
                let entities = try self.context.fetch(request)
                guard let entity = entities.first else {
                    promise(.failure(RepositoryError.notFound))
                    return
                }

                self.mapToEntity(budget, entity: entity)
                try self.context.save()
                promise(.success(budget))
            } catch {
                promise(.failure(RepositoryError.saveFailed))
            }
        }
        .eraseToAnyPublisher()
    }

    func deleteBudget(byId id: UUID) -> AnyPublisher<Void, Error> {
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
                guard let entity = entities.first else {
                    promise(.failure(RepositoryError.notFound))
                    return
                }

                self.context.delete(entity)
                try self.context.save()
                promise(.success(()))
            } catch {
                promise(.failure(RepositoryError.saveFailed))
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
                promise(.failure(RepositoryError.fetchFailed))
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
                promise(.failure(RepositoryError.fetchFailed))
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchAllBudgets() -> AnyPublisher<[Budget], Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.unknown))
                return
            }

            let request: NSFetchRequest<BudgetEntity> = BudgetEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]

            do {
                let entities = try self.context.fetch(request)
                let budgets = entities.map { self.mapToDomain($0) }
                promise(.success(budgets))
            } catch {
                promise(.failure(RepositoryError.fetchFailed))
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Mapping

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
