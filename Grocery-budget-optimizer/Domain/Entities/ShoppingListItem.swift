//
//  ShoppingListItem.swift
//  Grocery-budget-optimizer
//
//  Created by Yevgeny Levin on 02/10/2025.
//

import Foundation

struct ShoppingListItem: Identifiable, Codable, Equatable {
    let id: UUID
    var groceryItemId: UUID
    var quantity: Decimal
    var estimatedPrice: Decimal
    var isPurchased: Bool
    var purchasedAt: Date?
    var actualPrice: Decimal?

    init(
        id: UUID = UUID(),
        groceryItemId: UUID,
        quantity: Decimal,
        estimatedPrice: Decimal,
        isPurchased: Bool = false,
        purchasedAt: Date? = nil,
        actualPrice: Decimal? = nil
    ) {
        self.id = id
        self.groceryItemId = groceryItemId
        self.quantity = quantity
        self.estimatedPrice = estimatedPrice
        self.isPurchased = isPurchased
        self.purchasedAt = purchasedAt
        self.actualPrice = actualPrice
    }
    
    // Helper computed properties
    var totalEstimatedCost: Decimal {
        quantity * estimatedPrice
    }
    
    var totalActualCost: Decimal {
        guard let actualPrice = actualPrice else { return 0 }
        return quantity * actualPrice
    }
    
    var priceDifference: Decimal {
        guard let actualPrice = actualPrice else { return 0 }
        return (quantity * actualPrice) - totalEstimatedCost
    }
}