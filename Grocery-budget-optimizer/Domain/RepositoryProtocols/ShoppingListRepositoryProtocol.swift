//
//  ShoppingListRepositoryProtocol.swift
//  Grocery-budget-optimizer
//
//  Created by Yevgeny Levin on 02/10/2025.
//

import Foundation
import Combine

protocol ShoppingListRepositoryProtocol {
    func fetchAllShoppingLists() -> AnyPublisher<[ShoppingList], Error>
    func fetchShoppingList(byId id: UUID) -> AnyPublisher<ShoppingList?, Error>
    func createShoppingList(_ shoppingList: ShoppingList) -> AnyPublisher<ShoppingList, Error>
    func updateShoppingList(_ shoppingList: ShoppingList) -> AnyPublisher<ShoppingList, Error>
    func deleteShoppingList(byId id: UUID) -> AnyPublisher<Void, Error>
    func fetchActiveShoppingLists() -> AnyPublisher<[ShoppingList], Error>
    func markAsCompleted(shoppingListId: UUID) -> AnyPublisher<ShoppingList, Error>
}