//
//  MockGroceryItemRepository.swift
//  Grocery-budget-optimizer
//
//  Created by Yevgeny Levin on 02/10/2025.
//

import Foundation
import Combine

class MockGroceryItemRepository: GroceryItemRepositoryProtocol {
    private var items: [GroceryItem] = []
    
    init() {
        // Add some sample data
        items = [
            GroceryItem(
                name: "Organic Milk",
                category: "Dairy",
                brand: "Whole Foods",
                unit: "1L",
                averagePrice: 4.99
            ),
            GroceryItem(
                name: "Bananas",
                category: "Produce",
                unit: "1kg",
                averagePrice: 2.49
            ),
            GroceryItem(
                name: "Chicken Breast",
                category: "Meat & Seafood",
                unit: "1kg",
                averagePrice: 12.99
            ),
            GroceryItem(
                name: "Whole Wheat Bread",
                category: "Bakery",
                brand: "Nature's Own",
                unit: "1 loaf",
                averagePrice: 3.49
            )
        ]
    }
    
    func fetchAllItems() -> AnyPublisher<[GroceryItem], Error> {
        Just(items)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func fetchItem(byId id: UUID) -> AnyPublisher<GroceryItem?, Error> {
        let item = items.first { $0.id == id }
        return Just(item)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func searchItems(query: String) -> AnyPublisher<[GroceryItem], Error> {
        let filteredItems = items.filter { item in
            item.name.localizedCaseInsensitiveContains(query) ||
            item.brand?.localizedCaseInsensitiveContains(query) == true ||
            item.category.localizedCaseInsensitiveContains(query)
        }
        return Just(filteredItems)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func fetchItems(byCategory category: String) -> AnyPublisher<[GroceryItem], Error> {
        let filteredItems = items.filter { $0.category == category }
        return Just(filteredItems)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func createItem(_ item: GroceryItem) -> AnyPublisher<GroceryItem, Error> {
        items.append(item)
        return Just(item)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func updateItem(_ item: GroceryItem) -> AnyPublisher<GroceryItem, Error> {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            return Just(item)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } else {
            return Fail(error: RepositoryError.notFound)
                .eraseToAnyPublisher()
        }
    }
    
    func deleteItem(byId id: UUID) -> AnyPublisher<Void, Error> {
        if let index = items.firstIndex(where: { $0.id == id }) {
            items.remove(at: index)
            return Just(())
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } else {
            return Fail(error: RepositoryError.notFound)
                .eraseToAnyPublisher()
        }
    }
    
    func fetchRecentItems(limit: Int) -> AnyPublisher<[GroceryItem], Error> {
        let recentItems = Array(items.sorted { $0.updatedAt > $1.updatedAt }.prefix(limit))
        return Just(recentItems)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}