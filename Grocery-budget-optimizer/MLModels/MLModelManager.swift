//
//  MLModelManager.swift
//  Grocery-budget-optimizer
//
//  Created on 10/3/25.
//

import Foundation
import CoreML
import Combine

/// Central manager for all ML models and services
class MLModelManager: ObservableObject {
    
    // MARK: - Services
    @Published var shoppingListGenerator: ShoppingListGeneratorService
    @Published var purchasePrediction: PurchasePredictionService
    @Published var priceOptimization: PriceOptimizationService
    @Published var expirationPrediction: ExpirationPredictionService
    
    // MARK: - State
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Initialization
    init() {
        self.shoppingListGenerator = ShoppingListGeneratorService()
        self.purchasePrediction = PurchasePredictionService()
        self.priceOptimization = PriceOptimizationService()
        self.expirationPrediction = ExpirationPredictionService()
        
        initializeServices()
    }
    
    private func initializeServices() {
        isLoading = true
        
        // In a real implementation, this would load the Core ML models
        // For now, we'll simulate initialization
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoading = false
        }
    }
    
    // MARK: - Comprehensive ML Operations
    
    /// Generate complete shopping insights
    func generateShoppingInsights(
        budget: Decimal,
        householdSize: Int,
        currentPantry: [String] = [],
        preferences: [String: Double] = [:]
    ) -> ShoppingInsights {
        
        // Generate shopping list
        let shoppingListResult = shoppingListGenerator.generateShoppingList(
            budget: budget,
            householdSize: householdSize,
            previousPurchases: currentPantry,
            preferences: preferences
        )
        
        let recommendations: [ShoppingListRecommendation]
        switch shoppingListResult {
        case .success(let recs):
            recommendations = recs
        case .failure:
            recommendations = []
        }
        
        // Get smart suggestions
        let suggestions = shoppingListGenerator.getSmartSuggestions(
            currentPantry: currentPantry,
            budget: budget,
            preferences: preferences
        )
        
        // Generate price analysis for recommended items
        var priceAnalyses: [String: PriceAnalysis] = [:]
        for recommendation in recommendations {
            let mockHistory = priceOptimization.generateMockPriceHistory(
                for: recommendation.itemName,
                basePrice: Double(truncating: recommendation.estimatedPrice as NSNumber)
            )
            
            let analysis = priceOptimization.analyzePrice(
                for: recommendation.itemName,
                currentPrice: recommendation.estimatedPrice,
                history: mockHistory
            )
            
            priceAnalyses[recommendation.itemName] = analysis
        }
        
        return ShoppingInsights(
            recommendations: recommendations,
            suggestions: suggestions,
            priceAnalyses: priceAnalyses,
            totalEstimatedCost: recommendations.reduce(Decimal(0)) { $0 + $1.totalCost },
            budgetUtilization: recommendations.reduce(Decimal(0)) { $0 + $1.totalCost } / budget
        )
    }
    
    /// Generate purchase predictions for common items
    func generatePurchasePredictions(for items: [String]) -> [PurchasePrediction] {
        var predictions: [PurchasePrediction] = []
        
        for item in items {
            let category = getCategoryForItem(item)
            let mockHistory = purchasePrediction.generateMockHistory(for: item, category: category)
            
            let result = purchasePrediction.predictNextPurchase(
                for: item,
                category: category,
                history: mockHistory
            )
            
            if case .success(let prediction) = result {
                predictions.append(prediction)
            }
        }
        
        return predictions.sorted { $0.urgency.priority > $1.urgency.priority }
    }
    
    /// Generate expiration alerts for food items
    func generateExpirationAlerts(items: [FoodItem]) -> ExpirationAlerts {
        let predictions = expirationPrediction.getExpiringItems(items: items)
        let stats = expirationPrediction.getExpirationStats(items: items)
        
        let criticalItems = predictions.filter { $0.urgency == .expired || $0.urgency == .useSoon }
        let moderateItems = predictions.filter { $0.urgency == .moderate }
        
        return ExpirationAlerts(
            criticalItems: criticalItems,
            moderateItems: moderateItems,
            stats: stats,
            totalItemsNeedingAttention: criticalItems.count + moderateItems.count
        )
    }
    
    /// Get price optimization recommendations
    func getPriceOptimizationTips(for items: [String]) -> [PriceOptimizationTip] {
        var tips: [PriceOptimizationTip] = []
        
        for item in items {
            let basePrice = getBasePriceForItem(item)
            let mockHistory = priceOptimization.generateMockPriceHistory(
                for: item,
                basePrice: basePrice
            )
            
            let bestTime = priceOptimization.predictBestTimeToBuy(
                itemName: item,
                history: mockHistory
            )
            
            let analysis = priceOptimization.analyzePrice(
                for: item,
                currentPrice: Decimal(basePrice),
                history: mockHistory
            )
            
            let tip = PriceOptimizationTip(
                itemName: item,
                bestTimeToBuy: bestTime,
                currentAnalysis: analysis,
                potentialSavings: bestTime.savingsPercentage
            )
            
            tips.append(tip)
        }
        
        return tips.sorted { $0.potentialSavings > $1.potentialSavings }
    }
    
    // MARK: - Helper Methods
    
    private func getCategoryForItem(_ item: String) -> String {
        let categories: [String: String] = [
            "Milk": "Dairy", "Cheese": "Dairy", "Yogurt": "Dairy", "Butter": "Dairy",
            "Lettuce": "Produce", "Tomatoes": "Produce", "Apples": "Produce", "Bananas": "Produce",
            "Chicken Breast": "Meat & Seafood", "Ground Beef": "Meat & Seafood",
            "Bread": "Pantry", "Rice": "Pantry", "Pasta": "Pantry",
            "Coffee": "Beverages"
        ]
        
        return categories[item] ?? "Pantry"
    }
    
    private func getBasePriceForItem(_ item: String) -> Double {
        let prices: [String: Double] = [
            "Milk": 3.50, "Cheese": 4.99, "Yogurt": 1.29, "Butter": 3.99,
            "Lettuce": 1.99, "Tomatoes": 2.99, "Apples": 3.49, "Bananas": 1.49,
            "Chicken Breast": 6.99, "Ground Beef": 5.99,
            "Bread": 2.49, "Rice": 3.99, "Pasta": 1.99,
            "Coffee": 8.99
        ]
        
        return prices[item] ?? 5.0
    }
}

// MARK: - Data Structures

/// Comprehensive shopping insights
struct ShoppingInsights {
    let recommendations: [ShoppingListRecommendation]
    let suggestions: [ShoppingListRecommendation]
    let priceAnalyses: [String: PriceAnalysis]
    let totalEstimatedCost: Decimal
    let budgetUtilization: Decimal // 0-1, where 1 is 100% of budget
    
    var isOverBudget: Bool {
        budgetUtilization > 1.0
    }
    
    var budgetUtilizationPercentage: Double {
        Double(truncating: budgetUtilization as NSNumber) * 100
    }
}

/// Expiration alerts and statistics
struct ExpirationAlerts {
    let criticalItems: [ExpirationPrediction]
    let moderateItems: [ExpirationPrediction]
    let stats: ExpirationStats
    let totalItemsNeedingAttention: Int
    
    var hasUrgentItems: Bool {
        !criticalItems.isEmpty
    }
}

/// Price optimization tip
struct PriceOptimizationTip {
    let itemName: String
    let bestTimeToBuy: BestTimePrediction
    let currentAnalysis: PriceAnalysis
    let potentialSavings: Double
    
    var isWorthWaiting: Bool {
        potentialSavings > 5.0 // Worth waiting if savings > 5%
    }
}