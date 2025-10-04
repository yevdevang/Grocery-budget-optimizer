//
//  AddItemViewModel.swift
//  Grocery-budget-optimizer
//
//  Created by Yevgeny Levin on 04/10/2025.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class AddItemViewModel: ObservableObject {
    // Form fields
    @Published var name: String = ""
    @Published var selectedCategory: String = "Produce"
    @Published var brand: String = ""
    @Published var unit: String = ""
    @Published var averagePrice: String = ""
    @Published var notes: String = ""
    
    // Validation & State
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let groceryItemRepository: GroceryItemRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Available categories
    let availableCategories = [
        "Produce",
        "Dairy",
        "Meat & Seafood",
        "Pantry",
        "Beverages",
        "Frozen",
        "Bakery",
        "Other"
    ]
    
    init(groceryItemRepository: GroceryItemRepositoryProtocol = DIContainer.shared.groceryItemRepository) {
        self.groceryItemRepository = groceryItemRepository
    }
    
    // MARK: - Validation
    
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isValidPrice
    }
    
    private var isValidPrice: Bool {
        guard !averagePrice.isEmpty else { return true } // Price is optional
        return Decimal(string: averagePrice) != nil
    }
    
    // MARK: - Actions
    
    func saveItem() async -> Bool {
        guard isFormValid else {
            errorMessage = "Please fill in all required fields"
            showError = true
            return false
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Parse price (default to 0 if empty)
        let price = Decimal(string: averagePrice) ?? 0
        
        // Create new item
        let newItem = GroceryItem(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            category: selectedCategory,
            brand: brand.isEmpty ? nil : brand.trimmingCharacters(in: .whitespacesAndNewlines),
            unit: unit.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
            averagePrice: price
        )
        
        // Save to repository
        return await withCheckedContinuation { continuation in
            groceryItemRepository.createItem(newItem)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case .failure(let error) = completion {
                            self?.errorMessage = "Failed to save item: \(error.localizedDescription)"
                            self?.showError = true
                            continuation.resume(returning: false)
                        }
                    },
                    receiveValue: { _ in
                        continuation.resume(returning: true)
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    func reset() {
        name = ""
        selectedCategory = "Produce"
        brand = ""
        unit = ""
        averagePrice = ""
        notes = ""
        errorMessage = nil
        showError = false
    }
}
