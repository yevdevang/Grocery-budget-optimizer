//
//  PurchasePredictionTrainingData.swift
//  Grocery-budget-optimizer
//
//  Created on 10/3/25.
//

import Foundation

// MARK: - ML Training Dependencies
// Import domain entities for ML training

// Use the centralized MLGroceryItem but keep a local simplified version for training
struct TrainingMLGroceryItem {
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

// Temporary Purchase struct for ML training
// Will be replaced with actual Purchase entity in Phase 3
struct TrainingPurchase {
    let groceryItem: TrainingMLGroceryItem
    let quantity: Decimal
    let purchaseDate: Date
    let storeName: String?
}

/// Training data structure for Purchase Prediction ML Model
struct PurchasePredictionTrainingData: Codable {
    // Input Features
    let itemName: String
    let category: String
    let lastPurchaseDate: Date
    let purchaseHistory: [Date] // Array of purchase dates
    let averageQuantity: Double
    let householdSize: Int
    let seasonalFactor: Double
    
    // Output Labels
    let nextPurchaseDate: Date
    let confidence: Double
    
    // Computed properties for ML features
    var daysSinceLastPurchase: Int {
        Calendar.current.dateComponents([.day], from: lastPurchaseDate, to: Date()).day ?? 0
    }
    
    var averageDaysBetweenPurchases: Double {
        guard purchaseHistory.count >= 2 else { return 30.0 } // Default 30 days
        
        let sortedDates = purchaseHistory.sorted()
        let intervals = zip(sortedDates, sortedDates.dropFirst()).map {
            $1.timeIntervalSince($0) / 86400 // Convert to days
        }
        
        return intervals.reduce(0, +) / Double(intervals.count)
    }
}

// Note: Using PurchasePrediction type from PurchasePredictionService to avoid conflicts

// Note: Using PurchaseUrgency enum from PurchasePredictionService to avoid conflicts

/// Data preparation class for Purchase Prediction model
class PurchasePredictionDataPreparation {
    
    /// Prepare purchase history data for training
    static func preparePurchaseHistory(purchases: [TrainingPurchase]) -> [PurchasePredictionTrainingData] {
        // Group purchases by item
        let groupedByItem = Dictionary(grouping: purchases, by: { $0.groceryItem.name })
        
        var trainingData: [PurchasePredictionTrainingData] = []
        
        for (itemName, itemPurchases) in groupedByItem {
            guard itemPurchases.count >= 3 else { continue } // Need sufficient history
            
            let sortedPurchases = itemPurchases.sorted { $0.purchaseDate < $1.purchaseDate }
            
            // Calculate average interval between purchases
            let intervals = zip(sortedPurchases, sortedPurchases.dropFirst()).map {
                $1.purchaseDate.timeIntervalSince($0.purchaseDate)
            }
            
            guard !intervals.isEmpty else { continue }
            
            let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
            
            // Use the last purchase to predict the next one
            let lastPurchase = sortedPurchases.last!
            let predictedNext = lastPurchase.purchaseDate.addingTimeInterval(avgInterval)
            
            // Calculate confidence based on consistency of intervals
            let confidence = calculateConfidence(intervals: intervals)
            
            let data = PurchasePredictionTrainingData(
                itemName: itemName,
                category: lastPurchase.groceryItem.category,
                lastPurchaseDate: lastPurchase.purchaseDate,
                purchaseHistory: sortedPurchases.map { $0.purchaseDate },
                averageQuantity: sortedPurchases.map { Double(truncating: $0.quantity as NSNumber) }
                    .reduce(0, +) / Double(sortedPurchases.count),
                householdSize: 3, // Default - would come from user settings
                seasonalFactor: calculateSeasonalFactor(
                    month: Calendar.current.component(.month, from: lastPurchase.purchaseDate)
                ),
                nextPurchaseDate: predictedNext,
                confidence: confidence
            )
            
            trainingData.append(data)
        }
        
        return trainingData
    }
    
    /// Calculate seasonal factor based on month
    static func calculateSeasonalFactor(month: Int) -> Double {
        // Different seasonal patterns for different months
        // Summer months (6-8) might have different consumption patterns
        let seasonalFactors: [Double] = [
            0.9,  // Jan - Post-holiday reduction
            0.9,  // Feb - Winter
            1.0,  // Mar - Spring starts
            1.0,  // Apr - Spring
            1.1,  // May - Spring/Summer prep
            1.2,  // Jun - Summer entertaining
            1.2,  // Jul - Peak summer
            1.1,  // Aug - Late summer
            1.0,  // Sep - Back to school
            1.0,  // Oct - Fall
            0.9,  // Nov - Pre-holiday
            0.9   // Dec - Holiday season
        ]
        
        return seasonalFactors[month - 1]
    }
    
    /// Calculate confidence based on interval consistency
    static func calculateConfidence(intervals: [TimeInterval]) -> Double {
        guard !intervals.isEmpty else { return 0.0 }
        
        let mean = intervals.reduce(0, +) / Double(intervals.count)
        let variance = intervals.map { pow($0 - mean, 2) }.reduce(0, +) / Double(intervals.count)
        let stdDev = sqrt(variance)
        
        // Lower standard deviation = higher confidence
        // Normalize to 0-1 range
        let coefficientOfVariation = stdDev / mean
        return max(0.0, min(1.0, 1.0 - coefficientOfVariation))
    }
    
    /// Generate synthetic purchase prediction data
    static func generateSyntheticData(count: Int = 500) -> [PurchasePredictionTrainingData] {
        let items = [
            "Milk", "Bread", "Eggs", "Chicken Breast", "Ground Beef", "Rice", 
            "Pasta", "Tomatoes", "Lettuce", "Cheese", "Yogurt", "Apples",
            "Bananas", "Carrots", "Onions", "Potatoes", "Coffee", "Butter"
        ]
        
        let itemCategories: [String: String] = [
            "Milk": "Dairy", "Cheese": "Dairy", "Yogurt": "Dairy", "Butter": "Dairy",
            "Tomatoes": "Produce", "Lettuce": "Produce", "Apples": "Produce", 
            "Bananas": "Produce", "Carrots": "Produce", "Onions": "Produce",
            "Potatoes": "Produce", "Chicken Breast": "Meat & Seafood", 
            "Ground Beef": "Meat & Seafood", "Bread": "Pantry", "Rice": "Pantry", 
            "Pasta": "Pantry", "Eggs": "Pantry", "Coffee": "Beverages"
        ]
        
        var data: [PurchasePredictionTrainingData] = []
        
        for _ in 0..<count {
            let item = items.randomElement() ?? "Milk"
            let category = itemCategories[item] ?? "Pantry"
            
            // Generate realistic purchase intervals based on item type
            let baseInterval: TimeInterval = {
                switch category {
                case "Dairy": return 7 * 24 * 3600 // 7 days
                case "Produce": return 5 * 24 * 3600 // 5 days
                case "Meat & Seafood": return 10 * 24 * 3600 // 10 days
                case "Pantry": return 30 * 24 * 3600 // 30 days
                default: return 14 * 24 * 3600 // 14 days
                }
            }()
            
            // Generate purchase history
            var purchaseHistory: [Date] = []
            var currentDate = Date().addingTimeInterval(-90 * 24 * 3600) // Start 90 days ago
            
            for _ in 0..<Int.random(in: 3...8) {
                purchaseHistory.append(currentDate)
                // Add some variation to the interval
                let variation = Double.random(in: 0.8...1.2)
                currentDate = currentDate.addingTimeInterval(baseInterval * variation)
            }
            
            let lastPurchase = purchaseHistory.last!
            let predictedNext = lastPurchase.addingTimeInterval(baseInterval)
            
            let trainingData = PurchasePredictionTrainingData(
                itemName: item,
                category: category,
                lastPurchaseDate: lastPurchase,
                purchaseHistory: purchaseHistory,
                averageQuantity: Double.random(in: 1...3),
                householdSize: Int.random(in: 1...5),
                seasonalFactor: calculateSeasonalFactor(
                    month: Calendar.current.component(.month, from: lastPurchase)
                ),
                nextPurchaseDate: predictedNext,
                confidence: Double.random(in: 0.6...0.95)
            )
            
            data.append(trainingData)
        }
        
        return data
    }
}