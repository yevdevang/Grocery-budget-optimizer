//
//  AppConstants.swift
//  Grocery-budget-optimizer
//
//  Created by Yevgeny Levin on 02/10/2025.
//

import Foundation

enum AppConstants {
    enum Database {
        static let modelName = "GroceryBudgetOptimizer"
        static let cloudKitContainerID = "iCloud.com.yevdevang.grocery-budget-optimizer"
    }

    enum Categories {
        static let defaultCategories = [
            "Produce", "Dairy", "Meat & Seafood", "Bakery",
            "Frozen", "Pantry", "Beverages", "Snacks",
            "Personal Care", "Household", "Other"
        ]
    }

    enum Units {
        static let weightUnits = ["kg", "g", "lbs", "oz"]
        static let volumeUnits = ["L", "ml", "gal", "fl oz"]
        static let countUnits = ["pieces", "packs", "boxes"]
    }
}