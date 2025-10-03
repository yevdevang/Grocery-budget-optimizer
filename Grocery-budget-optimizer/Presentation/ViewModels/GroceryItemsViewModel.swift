//
//  GroceryItemsViewModel.swift
//  Grocery-budget-optimizer
//
//  Created by Yevgeny Levin on 02/10/2025.
//

import Foundation
import Combine

@MainActor
class GroceryItemsViewModel: ObservableObject {
    @Published var groceryItems: [GroceryItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    
    private let repository: GroceryItemRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: GroceryItemRepositoryProtocol = MockGroceryItemRepository()) {
        self.repository = repository
        setupSearchSubscription()
        loadItems()
    }
    
    private func setupSearchSubscription() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                if searchText.isEmpty {
                    self?.loadItems()
                } else {
                    self?.searchItems(query: searchText)
                }
            }
            .store(in: &cancellables)
    }
    
    func loadItems() {
        isLoading = true
        errorMessage = nil
        
        repository.fetchAllItems()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] items in
                    self?.groceryItems = items
                }
            )
            .store(in: &cancellables)
    }
    
    private func searchItems(query: String) {
        isLoading = true
        errorMessage = nil
        
        repository.searchItems(query: query)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] items in
                    self?.groceryItems = items
                }
            )
            .store(in: &cancellables)
    }
    
    func addItem(name: String, category: String, unit: String, price: Decimal) {
        let newItem = GroceryItem(
            name: name,
            category: category,
            unit: unit,
            averagePrice: price
        )
        
        repository.createItem(newItem)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.loadItems() // Refresh the list
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteItem(_ item: GroceryItem) {
        repository.deleteItem(byId: item.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.loadItems() // Refresh the list
                }
            )
            .store(in: &cancellables)
    }
}