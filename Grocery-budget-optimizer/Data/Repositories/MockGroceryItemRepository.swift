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
        // Populate with all items that the ML service can recommend
        items = [
            // Dairy
            GroceryItem(name: "Milk", category: "Dairy", unit: "1 gallon", averagePrice: 3.50),
            GroceryItem(name: "Cheese", category: "Dairy", unit: "1 lb", averagePrice: 4.99),
            GroceryItem(name: "Yogurt", category: "Dairy", unit: "32 oz", averagePrice: 1.29),
            GroceryItem(name: "Butter", category: "Dairy", unit: "1 lb", averagePrice: 3.99),

            // Produce
            GroceryItem(name: "Tomatoes", category: "Produce", unit: "1 lb", averagePrice: 2.99),
            GroceryItem(name: "Lettuce", category: "Produce", unit: "1 head", averagePrice: 1.99),
            GroceryItem(name: "Apples", category: "Produce", unit: "1 lb", averagePrice: 3.49),
            GroceryItem(name: "Bananas", category: "Produce", unit: "1 lb", averagePrice: 1.49),
            GroceryItem(name: "Carrots", category: "Produce", unit: "1 lb", averagePrice: 1.79),
            GroceryItem(name: "Onions", category: "Produce", unit: "1 lb", averagePrice: 1.99),
            GroceryItem(name: "Potatoes", category: "Produce", unit: "5 lb", averagePrice: 2.49),
            GroceryItem(name: "Bell Peppers", category: "Produce", unit: "1 lb", averagePrice: 3.99),
            GroceryItem(name: "Broccoli", category: "Produce", unit: "1 lb", averagePrice: 2.99),
            GroceryItem(name: "Spinach", category: "Produce", unit: "1 bunch", averagePrice: 2.49),
            GroceryItem(name: "Garlic", category: "Produce", unit: "1 bulb", averagePrice: 0.99),

            // Meat & Seafood
            GroceryItem(name: "Chicken Breast", category: "Meat & Seafood", unit: "1 lb", averagePrice: 6.99),
            GroceryItem(name: "Ground Beef", category: "Meat & Seafood", unit: "1 lb", averagePrice: 5.99),
            GroceryItem(name: "Salmon", category: "Meat & Seafood", unit: "1 lb", averagePrice: 12.99),
            GroceryItem(name: "Tuna", category: "Meat & Seafood", unit: "5 oz can", averagePrice: 2.99),

            // Pantry
            GroceryItem(name: "Bread", category: "Pantry", unit: "1 loaf", averagePrice: 2.49),
            GroceryItem(name: "Rice", category: "Pantry", unit: "2 lb", averagePrice: 3.99),
            GroceryItem(name: "Pasta", category: "Pantry", unit: "1 lb", averagePrice: 1.99),
            GroceryItem(name: "Eggs", category: "Pantry", unit: "1 dozen", averagePrice: 3.49),
            GroceryItem(name: "Olive Oil", category: "Pantry", unit: "16 oz", averagePrice: 6.99),
            GroceryItem(name: "Salt", category: "Pantry", unit: "26 oz", averagePrice: 1.99),
            GroceryItem(name: "Pepper", category: "Pantry", unit: "2 oz", averagePrice: 2.99),
            GroceryItem(name: "Cereal", category: "Pantry", unit: "18 oz", averagePrice: 4.99),
            GroceryItem(name: "Oats", category: "Pantry", unit: "42 oz", averagePrice: 3.49),
            GroceryItem(name: "Honey", category: "Pantry", unit: "12 oz", averagePrice: 5.99),

            // Beverages
            GroceryItem(name: "Coffee", category: "Beverages", unit: "12 oz", averagePrice: 8.99)
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
    
    func clearAllData() {
        items.removeAll()
    }
    
    // API-based methods (mocked)
    func refreshItemsFromAPI(category: String?) -> AnyPublisher<[GroceryItem], Error> {
        // Mock implementation: just return existing items filtered by category
        if let category = category {
            return fetchItems(byCategory: category)
        } else {
            return fetchAllItems()
        }
    }
    
    func searchAndSaveProducts(query: String, saveResults: Bool) -> AnyPublisher<[GroceryItem], Error> {
        // Mock implementation: just search existing items
        return searchItems(query: query)
    }
}