//
//  PriceOptimizationTrainingData.swift
//  Grocery-budget-optimizer
//
//  Created on 10/3/25.
//

import Foundation

/// Training data for Price Optimization ML Model
struct PriceOptimizationTrainingData: Codable {
    let itemName: String
    let category: String
    let prices: [Double] // Historical prices
    let dates: [Date] // Corresponding dates
    let storeName: String?
    let dayOfWeek: Int
    let weekOfMonth: Int
    let month: Int
    
    // Labels for training
    let isGoodPrice: Bool // Below average
    let isBestPrice: Bool // In bottom 20%
    let priceTrend: String // "increasing", "stable", "decreasing"
    let priceScore: Double // 0-1, where 1 is the best price
}

/// Price history record
struct PriceHistory: Identifiable {
    let id = UUID()
    let groceryItemId: UUID
    let price: Decimal
    let recordedAt: Date
    let storeName: String?
    let location: String?
    
    init(groceryItemId: UUID, price: Decimal, recordedAt: Date = Date(), storeName: String? = nil, location: String? = nil) {
        self.groceryItemId = groceryItemId
        self.price = price
        self.recordedAt = recordedAt
        self.storeName = storeName
        self.location = location
    }
}

// MARK: - Training Data Generation