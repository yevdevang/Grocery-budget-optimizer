//
//  ShoppingList.swift
//  Grocery-budget-optimizer
//
//  Created by Yevgeny Levin on 02/10/2025.
//

import Foundation

struct ShoppingList: Identifiable, Codable {
    let id: UUID
    var name: String
    var budgetAmount: Decimal
    var items: [ShoppingListItem]
    var createdAt: Date
    var updatedAt: Date
    var isCompleted: Bool
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        name: String,
        budgetAmount: Decimal,
        items: [ShoppingListItem] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.budgetAmount = budgetAmount
        self.items = items
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }

    // Helper computed properties
    var totalEstimatedCost: Decimal {
        items.reduce(0) { $0 + $1.totalEstimatedCost }
    }

    var totalActualCost: Decimal {
        items.reduce(0) { $0 + $1.totalActualCost }
    }

    var remainingBudget: Decimal {
        budgetAmount - totalEstimatedCost
    }

    var completionPercentage: Double {
        guard !items.isEmpty else { return 0 }
        let purchased = items.filter { $0.isPurchased }.count
        return Double(purchased) / Double(items.count)
    }
    
    var isOverBudget: Bool {
        totalEstimatedCost > budgetAmount
    }
    
    var budgetUsagePercentage: Double {
        guard budgetAmount > 0 else { return 0 }
        return (totalEstimatedCost / budgetAmount).doubleValue
    }
}