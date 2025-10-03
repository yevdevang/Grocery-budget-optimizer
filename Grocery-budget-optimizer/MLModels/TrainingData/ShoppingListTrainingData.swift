//
//  ShoppingListTrainingData.swift
//  Grocery-budget-optimizer
//
//  Created on 10/3/25.
//

import Foundation

/// Training data structure for Shopping List Generator ML Model
struct ShoppingListTrainingData: Codable {
    // Input Features
    let budget: Double
    let householdSize: Int
    let previousPurchases: [String] // Last 30 days
    let categoryPreferences: [String: Double] // Category weights
    let timeOfYear: Int // 1-12 (month)
    let daysUntilNextShop: Int
    
    // Output Labels
    let recommendedItems: [String]
    let recommendedQuantities: [String: Double]
    let estimatedTotal: Double
}

/// Data generator for training the Shopping List Generator model
class ShoppingListDataGenerator {
    
    static let commonItems = [
        "Milk", "Bread", "Eggs", "Chicken Breast", "Ground Beef", "Rice", 
        "Pasta", "Tomatoes", "Lettuce", "Cheese", "Yogurt", "Apples",
        "Bananas", "Carrots", "Onions", "Potatoes", "Coffee", "Butter",
        "Olive Oil", "Salt", "Pepper", "Garlic", "Bell Peppers", "Broccoli",
        "Spinach", "Salmon", "Tuna", "Cereal", "Oats", "Honey"
    ]
    
    static let categories = [
        "Dairy": 0.2,
        "Produce": 0.25,
        "Meat & Seafood": 0.2,
        "Pantry": 0.2,
        "Beverages": 0.15
    ]
    
    static let itemCategories: [String: String] = [
        "Milk": "Dairy", "Cheese": "Dairy", "Yogurt": "Dairy", "Butter": "Dairy",
        "Tomatoes": "Produce", "Lettuce": "Produce", "Apples": "Produce", 
        "Bananas": "Produce", "Carrots": "Produce", "Onions": "Produce",
        "Potatoes": "Produce", "Bell Peppers": "Produce", "Broccoli": "Produce",
        "Spinach": "Produce", "Garlic": "Produce",
        "Chicken Breast": "Meat & Seafood", "Ground Beef": "Meat & Seafood",
        "Salmon": "Meat & Seafood", "Tuna": "Meat & Seafood",
        "Bread": "Pantry", "Rice": "Pantry", "Pasta": "Pantry", "Eggs": "Pantry",
        "Olive Oil": "Pantry", "Salt": "Pantry", "Pepper": "Pantry",
        "Cereal": "Pantry", "Oats": "Pantry", "Honey": "Pantry",
        "Coffee": "Beverages"
    ]
    
    static let itemPrices: [String: Double] = [
        "Milk": 3.50, "Cheese": 4.99, "Yogurt": 1.29, "Butter": 3.99,
        "Tomatoes": 2.99, "Lettuce": 1.99, "Apples": 3.49, "Bananas": 1.49,
        "Carrots": 1.79, "Onions": 1.99, "Potatoes": 2.49, "Bell Peppers": 3.99,
        "Broccoli": 2.99, "Spinach": 2.49, "Garlic": 0.99,
        "Chicken Breast": 6.99, "Ground Beef": 5.99, "Salmon": 12.99, "Tuna": 2.99,
        "Bread": 2.49, "Rice": 3.99, "Pasta": 1.99, "Eggs": 3.49,
        "Olive Oil": 6.99, "Salt": 1.99, "Pepper": 2.99, "Cereal": 4.99,
        "Oats": 3.49, "Honey": 5.99, "Coffee": 8.99
    ]
    
    /// Generate synthetic training data for the Shopping List Generator
    static func generateSyntheticData(count: Int = 1000) -> [ShoppingListTrainingData] {
        var data: [ShoppingListTrainingData] = []
        
        for _ in 0..<count {
            let budget = Double.random(in: 50...300)
            let householdSize = Int.random(in: 1...6)
            let timeOfYear = Int.random(in: 1...12)
            let daysUntilNextShop = Int.random(in: 3...14)
            
            // Generate budget-conscious item selection
            let targetItemCount = min(Int(budget / 4), commonItems.count) // Avg $4 per item
            let availableItems = commonItems.shuffled()
            
            var selectedItems: [String] = []
            var quantities: [String: Double] = [:]
            var runningTotal = 0.0
            
            // Smart selection based on budget
            for item in availableItems {
                let basePrice = itemPrices[item] ?? 5.0
                let quantity = Double.random(in: 1...3)
                let itemCost = basePrice * quantity
                
                if runningTotal + itemCost <= budget * 0.9 { // Leave 10% buffer
                    selectedItems.append(item)
                    quantities[item] = quantity
                    runningTotal += itemCost
                }
                
                if selectedItems.count >= targetItemCount {
                    break
                }
            }
            
            // Adjust for household size (larger households buy more)
            let householdMultiplier = 1.0 + (Double(householdSize - 1) * 0.2)
            for item in quantities.keys {
                quantities[item] = (quantities[item] ?? 1.0) * householdMultiplier
            }
            
            // Generate realistic category preferences
            var preferences = categories
            let preferredCategory = categories.keys.randomElement() ?? "Produce"
            preferences[preferredCategory] = (preferences[preferredCategory] ?? 0.2) + 0.1
            
            let trainingData = ShoppingListTrainingData(
                budget: budget,
                householdSize: householdSize,
                previousPurchases: selectedItems,
                categoryPreferences: preferences,
                timeOfYear: timeOfYear,
                daysUntilNextShop: daysUntilNextShop,
                recommendedItems: selectedItems,
                recommendedQuantities: quantities,
                estimatedTotal: runningTotal
            )
            
            data.append(trainingData)
        }
        
        return data
    }
    
    /// Export training data to JSON format for ML training
    static func exportToJSON(_ data: [ShoppingListTrainingData]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(data)
    }
}