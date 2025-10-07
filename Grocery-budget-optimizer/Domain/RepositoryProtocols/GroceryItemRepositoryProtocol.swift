//
//  GroceryItemRepositoryProtocol.swift
//  Grocery-budget-optimizer
//
//  Created by Yevgeny Levin on 02/10/2025.
//

import Foundation
import Combine

protocol GroceryItemRepositoryProtocol {
    func fetchAllItems() -> AnyPublisher<[GroceryItem], Error>
    func fetchItem(byId id: UUID) -> AnyPublisher<GroceryItem?, Error>
    func searchItems(query: String) -> AnyPublisher<[GroceryItem], Error>
    func fetchItems(byCategory category: String) -> AnyPublisher<[GroceryItem], Error>
    func createItem(_ item: GroceryItem) -> AnyPublisher<GroceryItem, Error>
    func updateItem(_ item: GroceryItem) -> AnyPublisher<GroceryItem, Error>
    func deleteItem(byId id: UUID) -> AnyPublisher<Void, Error>
    func fetchRecentItems(limit: Int) -> AnyPublisher<[GroceryItem], Error>
    func clearAllData()
    
    // API-based methods
    func refreshItemsFromAPI(category: String?) -> AnyPublisher<[GroceryItem], Error>
    func searchAndSaveProducts(query: String, saveResults: Bool) -> AnyPublisher<[GroceryItem], Error>
}