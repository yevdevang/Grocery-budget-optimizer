import Foundation
import Combine

protocol SearchGroceryItemsUseCaseProtocol {
    func execute(query: String) -> AnyPublisher<[GroceryItem], Error>
}

class SearchGroceryItemsUseCase: SearchGroceryItemsUseCaseProtocol {
    private let repository: GroceryItemRepositoryProtocol

    init(repository: GroceryItemRepositoryProtocol) {
        self.repository = repository
    }

    func execute(query: String) -> AnyPublisher<[GroceryItem], Error> {
        guard !query.isEmpty else {
            return repository.fetchAllItems()
        }

        return repository.searchItems(query: query)
            .map { items in
                // Sort by relevance
                items.sorted { item1, item2 in
                    let score1 = self.relevanceScore(for: item1, query: query)
                    let score2 = self.relevanceScore(for: item2, query: query)
                    return score1 > score2
                }
            }
            .eraseToAnyPublisher()
    }

    private func relevanceScore(for item: GroceryItem, query: String) -> Int {
        let queryLower = query.lowercased()
        var score = 0

        // Exact match
        if item.name.lowercased() == queryLower {
            score += 100
        }

        // Starts with
        if item.name.lowercased().hasPrefix(queryLower) {
            score += 50
        }

        // Contains
        if item.name.lowercased().contains(queryLower) {
            score += 25
        }

        // Brand match
        if let brand = item.brand, brand.lowercased().contains(queryLower) {
            score += 10
        }

        return score
    }
}
