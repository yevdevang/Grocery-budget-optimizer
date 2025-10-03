//
//  PurchasePredictionService.swift
//  Grocery-budget-optimizer
//
//  Created on 10/3/25.
//

import Foundation
import CoreML
import Combine

/// ML Error types
// Note: Using MLError from ShoppingListGeneratorService to avoid conflicts

/// Purchase prediction result
struct PurchasePrediction: Identifiable {
    let id = UUID()
    let itemName: String
    let category: String
    let predictedDate: Date
    let confidence: Double
    let recommendedQuantity: Decimal
    let urgency: PurchaseUrgency
    
    var daysUntilPurchase: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: predictedDate).day ?? 0
    }
    
    var isOverdue: Bool {
        daysUntilPurchase < 0
    }
}

/// Purchase urgency levels
enum PurchaseUrgency: String, CaseIterable {
    case overdue = "Overdue"
    case urgent = "Buy Today"
    case soon = "Buy This Week"
    case planned = "Buy Next Week"
    case future = "Future Purchase"
    
    var priority: Int {
        switch self {
        case .overdue: return 5
        case .urgent: return 4
        case .soon: return 3
        case .planned: return 2
        case .future: return 1
        }
    }
    
    var color: String {
        switch self {
        case .overdue: return "red"
        case .urgent: return "orange"
        case .soon: return "yellow"
        case .planned: return "blue"
        case .future: return "gray"
        }
    }
}

/// Mock purchase for training
struct MockPurchase {
    let itemName: String
    let category: String
    let quantity: Decimal
    let purchaseDate: Date
    let storeName: String?
}

/// Service for predicting when items need to be repurchased
class PurchasePredictionService: ObservableObject {
    
    init() {
        // Initialize service
    }
    
    /// Predict next purchase for an item based on history
    func predictNextPurchase(
        for itemName: String,
        category: String,
        history: [MockPurchase]
    ) -> Result<PurchasePrediction, MLError> {
        
        guard history.count >= 2 else {
            return .failure(.insufficientData)
        }
        
        do {
            let prediction = try generatePredictionUsingLogic(
                itemName: itemName,
                category: category,
                history: history
            )
            
            return .success(prediction)
            
        } catch {
            return .failure(.predictionFailed(error))
        }
    }
    
    /// Generate prediction using rule-based logic
    private func generatePredictionUsingLogic(
        itemName: String,
        category: String,
        history: [MockPurchase]
    ) throws -> PurchasePrediction {
        
        let sortedHistory = history.sorted { $0.purchaseDate < $1.purchaseDate }
        
        // Calculate intervals between purchases
        let intervals = zip(sortedHistory, sortedHistory.dropFirst()).map {
            $1.purchaseDate.timeIntervalSince($0.purchaseDate)
        }
        
        // Calculate average interval
        let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
        
        // Predict next purchase
        let lastPurchase = sortedHistory.last!
        let predictedDate = lastPurchase.purchaseDate.addingTimeInterval(avgInterval)
        
        // Calculate confidence based on consistency
        let confidence = calculateConfidence(intervals: intervals)
        
        // Determine urgency
        let daysUntilPurchase = Calendar.current.dateComponents([.day], from: Date(), to: predictedDate).day ?? 0
        let urgency = determineUrgency(daysUntil: daysUntilPurchase)
        
        // Calculate recommended quantity based on historical average
        let avgQuantity = sortedHistory.map { Double(truncating: $0.quantity as NSNumber) }
            .reduce(0, +) / Double(sortedHistory.count)
        
        return PurchasePrediction(
            itemName: itemName,
            category: category,
            predictedDate: predictedDate,
            confidence: confidence,
            recommendedQuantity: Decimal(avgQuantity),
            urgency: urgency
        )
    }
    
    /// Calculate confidence based on interval consistency
    private func calculateConfidence(intervals: [TimeInterval]) -> Double {
        guard !intervals.isEmpty else { return 0.0 }
        
        let mean = intervals.reduce(0, +) / Double(intervals.count)
        let variance = intervals.map { pow($0 - mean, 2) }.reduce(0, +) / Double(intervals.count)
        let stdDev = sqrt(variance)
        
        // Lower standard deviation = higher confidence
        let coefficientOfVariation = stdDev / mean
        return max(0.1, min(1.0, 1.0 - coefficientOfVariation))
    }
    
    /// Determine urgency based on days until purchase
    private func determineUrgency(daysUntil: Int) -> PurchaseUrgency {
        if daysUntil < 0 {
            return .overdue
        } else if daysUntil <= 1 {
            return .urgent
        } else if daysUntil <= 7 {
            return .soon
        } else if daysUntil <= 14 {
            return .planned
        } else {
            return .future
        }
    }
    
    /// Get items that need to be purchased soon
    func getUpcomingPurchases(predictions: [PurchasePrediction]) -> [PurchasePrediction] {
        return predictions
            .filter { $0.daysUntilPurchase <= 7 }
            .sorted { $0.urgency.priority > $1.urgency.priority }
    }
    
    /// Generate mock purchase history for testing
    func generateMockHistory(for itemName: String, category: String) -> [MockPurchase] {
        let baseInterval: TimeInterval = {
            switch category {
            case "Dairy": return 7 * 24 * 3600 // 7 days
            case "Produce": return 5 * 24 * 3600 // 5 days
            case "Meat & Seafood": return 10 * 24 * 3600 // 10 days
            case "Pantry": return 30 * 24 * 3600 // 30 days
            default: return 14 * 24 * 3600 // 14 days
            }
        }()
        
        var history: [MockPurchase] = []
        var currentDate = Date().addingTimeInterval(-90 * 24 * 3600) // Start 90 days ago
        
        for _ in 0..<Int.random(in: 3...6) {
            let purchase = MockPurchase(
                itemName: itemName,
                category: category,
                quantity: Decimal(Double.random(in: 1...3)),
                purchaseDate: currentDate,
                storeName: ["Whole Foods", "Safeway", "Trader Joe's"].randomElement()
            )
            
            history.append(purchase)
            
            // Add some variation to the interval
            let variation = Double.random(in: 0.8...1.2)
            currentDate = currentDate.addingTimeInterval(baseInterval * variation)
        }
        
        return history
    }
}