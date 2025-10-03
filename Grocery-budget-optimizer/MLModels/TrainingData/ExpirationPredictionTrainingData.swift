//
//  ExpirationPredictionTrainingData.swift
//  Grocery-budget-optimizer
//
//  Created on 10/3/25.
//

import Foundation

// MARK: - ML Training Dependencies
// Simplified GroceryItem for ML training (local version)
struct ExpirationMLGroceryItem {
    let id: UUID
    let name: String
    let category: String
    let unit: String
    let averagePrice: Decimal
    
    init(name: String, category: String, unit: String = "each", averagePrice: Decimal = 0) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.unit = unit
        self.averagePrice = averagePrice
    }
}

/// Training data for Expiration Prediction ML Model
struct ExpirationTrainingData: Codable {
    // Input Features
    let itemCategory: String
    let storageLocation: String // "Fridge", "Freezer", "Pantry"
    let packageType: String // "Fresh", "Packaged", "Canned", "Frozen"
    let purchaseDate: Date
    let labeledExpirationDate: Date?
    let temperature: String // "Cold", "Cool", "Room"
    let isOrganic: Bool
    
    // Output Label
    let actualExpirationDays: Int // Days until expiration
    let wasteCategory: String // "Consumed", "Wasted", "Unknown"
}

/// Expiration tracking for individual items
struct TrainingExpirationTracker: Identifiable {
    let id = UUID()
    let groceryItem: ExpirationMLGroceryItem
    let purchaseDate: Date
    let estimatedExpirationDate: Date
    let storageLocation: String
    let packageType: String
    var isConsumed: Bool = false
    var isWasted: Bool = false
    var actualExpirationDate: Date?
    
    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: estimatedExpirationDate).day ?? 0
    }
    
    var urgency: String {
        if daysRemaining <= 0 {
            return "expired"
        } else if daysRemaining <= 2 {
            return "useSoon"
        } else if daysRemaining <= 5 {
            return "moderate"
        } else {
            return "fresh"
        }
    }
}

/// Expiration database with standard shelf life information
enum ExpirationDatabase {
    static let standardShelfLife: [String: Int] = [
        // Dairy
        "Milk": 7,
        "Yogurt": 14,
        "Cheese": 21,
        "Butter": 30,
        
        // Produce
        "Lettuce": 7,
        "Tomatoes": 7,
        "Apples": 14,
        "Bananas": 5,
        "Berries": 3,
        "Carrots": 21,
        "Onions": 30,
        "Potatoes": 21,
        
        // Meat & Seafood
        "Chicken Breast": 2,
        "Ground Beef": 3,
        "Fish": 2,
        "Salmon": 2,
        
        // Pantry
        "Bread": 7,
        "Rice": 730, // 2 years
        "Pasta": 730,
        "Canned Goods": 1095, // 3 years
        "Cereal": 365,
        "Coffee": 365
    ]
    
    /// Get shelf life for an item with storage adjustments
    static func getShelfLife(
        for item: String,
        storage: String,
        packageType: String
    ) -> Int {
        var baseDays = standardShelfLife[item] ?? 7
        
        // Adjust for storage conditions
        switch storage {
        case "Freezer":
            baseDays *= 4 // Freezing extends shelf life significantly
        case "Pantry":
            baseDays = Int(Double(baseDays) * 0.8) // Pantry items may have shorter life
        case "Fridge":
            break // Base shelf life assumes refrigeration for perishables
        default:
            break
        }
        
        // Adjust for package type
        switch packageType {
        case "Canned":
            baseDays = max(baseDays, 365) // Canned goods last at least a year
        case "Frozen":
            baseDays *= 3 // Frozen items last longer
        case "Packaged":
            baseDays = Int(Double(baseDays) * 1.2) // Packaged items last slightly longer
        case "Fresh":
            break // Base shelf life
        default:
            break
        }
        
        return baseDays
    }
}

/// Data preparation for expiration prediction
class ExpirationPredictionDataPreparation {
    
    /// Generate synthetic expiration training data
    static func generateSyntheticData(count: Int = 400) -> [ExpirationTrainingData] {
        let items = [
            "Milk", "Yogurt", "Cheese", "Lettuce", "Tomatoes", "Apples",
            "Bananas", "Chicken Breast", "Ground Beef", "Bread", "Rice", "Pasta"
        ]
        
        let categories = [
            "Milk": "Dairy", "Yogurt": "Dairy", "Cheese": "Dairy",
            "Lettuce": "Produce", "Tomatoes": "Produce", "Apples": "Produce", "Bananas": "Produce",
            "Chicken Breast": "Meat & Seafood", "Ground Beef": "Meat & Seafood",
            "Bread": "Pantry", "Rice": "Pantry", "Pasta": "Pantry"
        ]
        
        let storageOptions = ["Fridge", "Freezer", "Pantry"]
        let packageTypes = ["Fresh", "Packaged", "Canned", "Frozen"]
        let temperatures = ["Cold", "Cool", "Room"]
        
        var data: [ExpirationTrainingData] = []
        
        for _ in 0..<count {
            let item = items.randomElement() ?? "Milk"
            let category = categories[item] ?? "Pantry"
            let storage = storageOptions.randomElement() ?? "Fridge"
            let packageType = packageTypes.randomElement() ?? "Fresh"
            let temperature = temperatures.randomElement() ?? "Cool"
            let isOrganic = Bool.random()
            
            let purchaseDate = Date().addingTimeInterval(-Double.random(in: 0...14) * 24 * 3600)
            
            // Get base shelf life and add some variation
            let baseShelfLife = ExpirationDatabase.getShelfLife(for: item, storage: storage, packageType: packageType)
            let variation = Double.random(in: 0.8...1.2) // ±20% variation
            let actualShelfLife = Int(Double(baseShelfLife) * variation)
            
            let labeledExpiration = Calendar.current.date(byAdding: .day, value: baseShelfLife, to: purchaseDate)
            
            // Determine if item was consumed or wasted
            let wasteCategory: String
            let randomOutcome = Double.random(in: 0...1)
            if randomOutcome < 0.7 {
                wasteCategory = "Consumed"
            } else if randomOutcome < 0.9 {
                wasteCategory = "Wasted"
            } else {
                wasteCategory = "Unknown"
            }
            
            let trainingData = ExpirationTrainingData(
                itemCategory: category,
                storageLocation: storage,
                packageType: packageType,
                purchaseDate: purchaseDate,
                labeledExpirationDate: labeledExpiration,
                temperature: temperature,
                isOrganic: isOrganic,
                actualExpirationDays: actualShelfLife,
                wasteCategory: wasteCategory
            )
            
            data.append(trainingData)
        }
        
        return data
    }
}