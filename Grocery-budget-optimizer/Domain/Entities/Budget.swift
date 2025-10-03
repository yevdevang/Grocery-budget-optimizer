//
//  Budget.swift
//  Grocery-budget-optimizer
//
//  Created by Yevgeny Levin on 02/10/2025.
//

import Foundation

struct Budget: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var amount: Decimal
    var startDate: Date
    var endDate: Date
    var isActive: Bool
    var categoryBudgets: [String: Decimal] // Category name to budget amount

    init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        startDate: Date,
        endDate: Date,
        isActive: Bool = true,
        categoryBudgets: [String: Decimal] = [:]
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.categoryBudgets = categoryBudgets
    }
    
    // Helper computed properties
    var isExpired: Bool {
        endDate < Date()
    }
    
    var remainingDays: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
    }
    
    var totalCategoryBudgets: Decimal {
        categoryBudgets.values.reduce(0, +)
    }
    
    var hasUnallocatedBudget: Bool {
        totalCategoryBudgets < amount
    }
    
    var unallocatedAmount: Decimal {
        amount - totalCategoryBudgets
    }
}