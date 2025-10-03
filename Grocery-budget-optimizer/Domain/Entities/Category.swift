//
//  Category.swift
//  Grocery-budget-optimizer
//
//  Created by Yevgeny Levin on 02/10/2025.
//

import Foundation

struct Category: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var iconName: String
    var colorHex: String
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "tag",
        colorHex: String = "#007AFF",
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.sortOrder = sortOrder
    }
    
    // Predefined categories
    static let defaultCategories: [Category] = [
        Category(name: "Produce", iconName: "leaf", colorHex: "#34C759", sortOrder: 1),
        Category(name: "Dairy", iconName: "cup.and.saucer", colorHex: "#FF9500", sortOrder: 2),
        Category(name: "Meat & Seafood", iconName: "fish", colorHex: "#FF3B30", sortOrder: 3),
        Category(name: "Bakery", iconName: "birthday.cake", colorHex: "#AF52DE", sortOrder: 4),
        Category(name: "Frozen", iconName: "snowflake", colorHex: "#5AC8FA", sortOrder: 5),
        Category(name: "Pantry", iconName: "archivebox", colorHex: "#FFCC02", sortOrder: 6),
        Category(name: "Beverages", iconName: "drop", colorHex: "#007AFF", sortOrder: 7),
        Category(name: "Snacks", iconName: "birthday.cake", colorHex: "#FF9500", sortOrder: 8),
        Category(name: "Personal Care", iconName: "heart", colorHex: "#FF2D92", sortOrder: 9),
        Category(name: "Household", iconName: "house", colorHex: "#8E8E93", sortOrder: 10),
        Category(name: "Other", iconName: "tag", colorHex: "#636366", sortOrder: 11)
    ]
}