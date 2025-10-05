//
//  GroceryItem.swift
//  Grocery-budget-optimizer
//
//  Created by Yevgeny Levin on 02/10/2025.
//

import Foundation

struct GroceryItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var category: String
    var brand: String?
    var unit: String
    var notes: String?
    var imageData: Data?
    var barcode: String?
    var averagePrice: Decimal
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        category: String,
        brand: String? = nil,
        unit: String,
        notes: String? = nil,
        imageData: Data? = nil,
        barcode: String? = nil,
        averagePrice: Decimal = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.brand = brand
        self.unit = unit
        self.notes = notes
        self.imageData = imageData
        self.barcode = barcode
        self.averagePrice = averagePrice
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Helper computed properties
    var displayName: String {
        if let brand = brand, !brand.isEmpty {
            return "\(brand) \(name)"
        }
        return name
    }
    
    var formattedPrice: String {
        String(format: "%.2f", NSDecimalNumber(decimal: averagePrice).doubleValue)
    }
}