//
//  ExpirationPredictionService.swift
//  Grocery-budget-optimizer
//
//  Created on 10/3/25.
//

import Foundation
import CoreML
import Combine

/// Expiration prediction result
struct ExpirationPrediction: Identifiable {
    let id = UUID()
    let itemName: String
    let category: String
    let predictedExpirationDate: Date
    let daysRemaining: Int
    let urgency: ExpirationUrgency
    let confidence: Double
    let recommendation: String
    
    var isExpired: Bool {
        daysRemaining <= 0
    }
    
    var needsAttention: Bool {
        daysRemaining <= 3
    }
}

/// Expiration urgency levels
enum ExpirationUrgency: String, CaseIterable {
    case expired = "Expired"
    case useSoon = "Use Soon"
    case moderate = "Moderate"
    case fresh = "Fresh"
    
    var priority: Int {
        switch self {
        case .expired: return 4
        case .useSoon: return 3
        case .moderate: return 2
        case .fresh: return 1
        }
    }
    
    var color: String {
        switch self {
        case .expired: return "red"
        case .useSoon: return "orange"
        case .moderate: return "yellow"
        case .fresh: return "green"
        }
    }
    
    var actionText: String {
        switch self {
        case .expired: return "Check before consuming"
        case .useSoon: return "Use within 2 days"
        case .moderate: return "Plan to use this week"
        case .fresh: return "Item is fresh"
        }
    }
}

/// Food storage item tracker
struct FoodItem {
    let id = UUID()
    let name: String
    let category: String
    let purchaseDate: Date
    let storageLocation: String
    let packageType: String
    var isConsumed: Bool = false
    var isWasted: Bool = false
}

/// Service for predicting food expiration dates using ML
class ExpirationPredictionService: ObservableObject {
    
    /// Standard shelf life database
    private let shelfLifeDatabase: [String: Int] = [
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
        "Bell Peppers": 10,
        "Broccoli": 7,
        "Spinach": 5,
        
        // Meat & Seafood
        "Chicken Breast": 2,
        "Ground Beef": 3,
        "Fish": 2,
        "Salmon": 2,
        "Tuna": 3,
        
        // Pantry
        "Bread": 7,
        "Rice": 730, // 2 years
        "Pasta": 730,
        "Canned Goods": 1095, // 3 years
        "Cereal": 365,
        "Coffee": 365,
        "Oats": 365,
        "Honey": 1095
    ]
    
    init() {
        // Initialize service
    }
    
    /// Predict expiration date for an item
    func predictExpiration(
        for itemName: String,
        category: String,
        purchaseDate: Date,
        storage: String = "Fridge",
        packageType: String = "Fresh"
    ) -> ExpirationPrediction {
        
        let baseShelfLife = getShelfLife(
            for: itemName,
            storage: storage,
            packageType: packageType
        )
        
        let predictedExpiration = Calendar.current.date(
            byAdding: .day,
            value: baseShelfLife,
            to: purchaseDate
        ) ?? purchaseDate
        
        let daysRemaining = Calendar.current.dateComponents(
            [.day],
            from: Date(),
            to: predictedExpiration
        ).day ?? 0
        
        let urgency = determineUrgency(daysRemaining: daysRemaining)
        let recommendation = getRecommendation(for: urgency, itemName: itemName)
        
        // Confidence decreases with time and increases with known shelf life data
        let hasKnownShelfLife = shelfLifeDatabase[itemName] != nil
        let baseConfidence = hasKnownShelfLife ? 0.85 : 0.65
        let ageInDays = Calendar.current.dateComponents([.day], from: purchaseDate, to: Date()).day ?? 0
        let confidenceReduction = min(0.3, Double(ageInDays) * 0.02) // Reduce confidence over time
        let confidence = max(0.4, baseConfidence - confidenceReduction)
        
        return ExpirationPrediction(
            itemName: itemName,
            category: category,
            predictedExpirationDate: predictedExpiration,
            daysRemaining: daysRemaining,
            urgency: urgency,
            confidence: confidence,
            recommendation: recommendation
        )
    }
    
    /// Get shelf life for an item with storage adjustments
    private func getShelfLife(
        for item: String,
        storage: String,
        packageType: String
    ) -> Int {
        var baseDays = shelfLifeDatabase[item] ?? 7
        
        // Adjust for storage conditions
        switch storage {
        case "Freezer":
            baseDays *= 4 // Freezing extends shelf life significantly
        case "Pantry":
            baseDays = Int(Double(baseDays) * 0.8) // Pantry items may have shorter life for perishables
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
    
    /// Determine urgency based on days remaining
    private func determineUrgency(daysRemaining: Int) -> ExpirationUrgency {
        if daysRemaining <= 0 {
            return .expired
        } else if daysRemaining <= 2 {
            return .useSoon
        } else if daysRemaining <= 5 {
            return .moderate
        } else {
            return .fresh
        }
    }
    
    /// Get recommendation based on urgency
    private func getRecommendation(for urgency: ExpirationUrgency, itemName: String) -> String {
        switch urgency {
        case .expired:
            return "⚠️ This item may be expired. Check carefully before consuming."
        case .useSoon:
            return "🔥 Use \\(itemName) within 2 days to avoid waste"
        case .moderate:
            return "⏰ Plan to use \\(itemName) within this week"
        case .fresh:
            return "✅ \\(itemName) is fresh and good to use"
        }
    }
    
    /// Get items that are expiring soon
    func getExpiringItems(items: [FoodItem]) -> [ExpirationPrediction] {
        let predictions = items
            .filter { !$0.isConsumed && !$0.isWasted }
            .map { item in
                predictExpiration(
                    for: item.name,
                    category: item.category,
                    purchaseDate: item.purchaseDate,
                    storage: item.storageLocation,
                    packageType: item.packageType
                )
            }
            .filter { $0.daysRemaining <= 5 } // Only items expiring within 5 days
            .sorted { $0.urgency.priority > $1.urgency.priority }
        
        return predictions
    }
    
    /// Generate mock food items for testing
    func generateMockFoodItems(count: Int = 10) -> [FoodItem] {
        let items = [
            ("Milk", "Dairy", "Fridge", "Fresh"),
            ("Lettuce", "Produce", "Fridge", "Fresh"),
            ("Chicken Breast", "Meat & Seafood", "Fridge", "Fresh"),
            ("Bread", "Pantry", "Pantry", "Packaged"),
            ("Apples", "Produce", "Fridge", "Fresh"),
            ("Yogurt", "Dairy", "Fridge", "Packaged"),
            ("Ground Beef", "Meat & Seafood", "Freezer", "Frozen"),
            ("Bananas", "Produce", "Pantry", "Fresh"),
            ("Cheese", "Dairy", "Fridge", "Packaged"),
            ("Rice", "Pantry", "Pantry", "Packaged")
        ]
        
        var foodItems: [FoodItem] = []
        
        for i in 0..<min(count, items.count) {
            let (name, category, storage, packageType) = items[i]
            
            // Generate random purchase dates in the past
            let daysAgo = Double.random(in: 0...14)
            let purchaseDate = Date().addingTimeInterval(-daysAgo * 24 * 3600)
            
            let foodItem = FoodItem(
                name: name,
                category: category,
                purchaseDate: purchaseDate,
                storageLocation: storage,
                packageType: packageType
            )
            
            foodItems.append(foodItem)
        }
        
        return foodItems
    }
    
    /// Track expiration analytics
    func getExpirationStats(items: [FoodItem]) -> ExpirationStats {
        let predictions = items.map { item in
            predictExpiration(
                for: item.name,
                category: item.category,
                purchaseDate: item.purchaseDate,
                storage: item.storageLocation,
                packageType: item.packageType
            )
        }
        
        let expired = predictions.filter { $0.isExpired }.count
        let expiringSoon = predictions.filter { $0.urgency == .useSoon }.count
        let fresh = predictions.filter { $0.urgency == .fresh }.count
        let wastedItems = items.filter { $0.isWasted }.count
        
        return ExpirationStats(
            totalItems: items.count,
            expiredItems: expired,
            expiringSoonItems: expiringSoon,
            freshItems: fresh,
            wastedItems: wastedItems,
            wastePercentage: items.isEmpty ? 0 : Double(wastedItems) / Double(items.count) * 100
        )
    }
}

/// Expiration statistics
struct ExpirationStats {
    let totalItems: Int
    let expiredItems: Int
    let expiringSoonItems: Int
    let freshItems: Int
    let wastedItems: Int
    let wastePercentage: Double
}