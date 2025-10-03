//
//  MLModelsTests.swift
//  Grocery-budget-optimizer
//
//  Created on 10/3/25.
//

import XCTest
@testable import Grocery_budget_optimizer

/// Unit tests for ML Models and Services
final class MLModelsTests: XCTestCase {
    
    var mlManager: MLModelManager!
    
    override func setUpWithError() throws {
        super.setUp()
        mlManager = MLModelManager()
    }
    
    override func tearDownWithError() throws {
        mlManager = nil
        super.tearDown()
    }
    
    // MARK: - Shopping List Generator Tests
    
    func testShoppingListGeneration() throws {
        let service = ShoppingListGeneratorService()
        
        let result = service.generateShoppingList(
            budget: 100,
            householdSize: 2,
            previousPurchases: [],
            preferences: ["Produce": 0.3, "Dairy": 0.2]
        )
        
        switch result {
        case .success(let recommendations):
            XCTAssertFalse(recommendations.isEmpty, "Should generate recommendations")
            
            let totalCost = recommendations.reduce(Decimal(0)) { $0 + $1.totalCost }
            XCTAssertLessThanOrEqual(totalCost, 100, "Total cost should not exceed budget")
            
            // Check that recommendations have required fields
            for recommendation in recommendations {
                XCTAssertFalse(recommendation.itemName.isEmpty, "Item name should not be empty")
                XCTAssertGreaterThan(recommendation.quantity, 0, "Quantity should be positive")
                XCTAssertGreaterThan(recommendation.estimatedPrice, 0, "Price should be positive")
                XCTAssertGreaterThanOrEqual(recommendation.priority, 0, "Priority should be non-negative")
                XCTAssertLessThanOrEqual(recommendation.priority, 1, "Priority should not exceed 1")
            }
            
        case .failure(let error):
            XCTFail("Generation failed: \\(error)")
        }
    }
    
    func testSmartSuggestions() throws {
        let service = ShoppingListGeneratorService()
        
        let suggestions = service.getSmartSuggestions(
            currentPantry: ["Pasta", "Bread"],
            budget: 50,
            preferences: [:]
        )
        
        // Should suggest complementary items
        let itemNames = suggestions.map { $0.itemName }
        XCTAssertTrue(itemNames.contains("Tomatoes") || itemNames.contains("Butter") || itemNames.contains("Milk"),
                     "Should suggest complementary items")
    }
    
    // MARK: - Purchase Prediction Tests
    
    func testPurchasePrediction() throws {
        let service = PurchasePredictionService()
        
        // Generate mock history
        let history = service.generateMockHistory(for: "Milk", category: "Dairy")
        XCTAssertGreaterThanOrEqual(history.count, 3, "Should generate sufficient history")
        
        let result = service.predictNextPurchase(
            for: "Milk",
            category: "Dairy",
            history: history
        )
        
        switch result {
        case .success(let prediction):
            XCTAssertEqual(prediction.itemName, "Milk")
            XCTAssertEqual(prediction.category, "Dairy")
            XCTAssertGreaterThanOrEqual(prediction.confidence, 0.1, "Confidence should be reasonable")
            XCTAssertLessThanOrEqual(prediction.confidence, 1.0, "Confidence should not exceed 1")
            XCTAssertGreaterThan(prediction.recommendedQuantity, 0, "Quantity should be positive")
            
        case .failure(let error):
            XCTFail("Prediction failed: \\(error)")
        }
    }
    
    func testPurchaseUrgencyClassification() throws {
        let service = PurchasePredictionService()
        let history = service.generateMockHistory(for: "Milk", category: "Dairy")
        
        let result = service.predictNextPurchase(for: "Milk", category: "Dairy", history: history)
        
        if case .success(let prediction) = result {
            // Test urgency classification logic
            switch prediction.urgency {
            case .overdue:
                XCTAssertLessThan(prediction.daysUntilPurchase, 0)
            case .urgent:
                XCTAssertLessThanOrEqual(prediction.daysUntilPurchase, 1)
            case .soon:
                XCTAssertLessThanOrEqual(prediction.daysUntilPurchase, 7)
            case .planned:
                XCTAssertLessThanOrEqual(prediction.daysUntilPurchase, 14)
            case .future:
                XCTAssertGreaterThan(prediction.daysUntilPurchase, 14)
            }
        }
    }
    
    // MARK: - Price Optimization Tests
    
    func testPriceAnalysis() throws {
        let service = PriceOptimizationService()
        
        let history = service.generateMockPriceHistory(for: "Milk", basePrice: 3.50, days: 30)
        XCTAssertEqual(history.count, 30, "Should generate 30 days of history")
        
        let analysis = service.analyzePrice(
            for: "Milk",
            currentPrice: Decimal(3.50),
            history: history
        )
        
        XCTAssertGreaterThan(analysis.averagePrice, 0, "Average price should be positive")
        XCTAssertGreaterThan(analysis.medianPrice, 0, "Median price should be positive")
        XCTAssertGreaterThanOrEqual(analysis.lowestPrice, 0, "Lowest price should be non-negative")
        XCTAssertGreaterThanOrEqual(analysis.priceScore, 0, "Price score should be non-negative")
        XCTAssertLessThanOrEqual(analysis.priceScore, 1, "Price score should not exceed 1")
        XCTAssertFalse(analysis.recommendation.isEmpty, "Should provide recommendation")
    }
    
    func testBestTimeToBuyPrediction() throws {
        let service = PriceOptimizationService()
        
        let history = service.generateMockPriceHistory(for: "Milk", basePrice: 3.50, days: 30)
        let prediction = service.predictBestTimeToBuy(itemName: "Milk", history: history)
        
        XCTAssertGreaterThanOrEqual(prediction.bestDayOfWeek, 1, "Day of week should be valid")
        XCTAssertLessThanOrEqual(prediction.bestDayOfWeek, 7, "Day of week should be valid")
        XCTAssertGreaterThanOrEqual(prediction.estimatedSavings, 0, "Savings should be non-negative")
        XCTAssertGreaterThanOrEqual(prediction.confidence, 0, "Confidence should be non-negative")
        XCTAssertLessThanOrEqual(prediction.confidence, 1, "Confidence should not exceed 1")
        XCTAssertFalse(prediction.recommendation.isEmpty, "Should provide recommendation")
    }
    
    // MARK: - Expiration Prediction Tests
    
    func testExpirationPrediction() throws {
        let service = ExpirationPredictionService()
        
        let prediction = service.predictExpiration(
            for: "Milk",
            category: "Dairy",
            purchaseDate: Date(),
            storage: "Fridge",
            packageType: "Fresh"
        )
        
        XCTAssertEqual(prediction.itemName, "Milk")
        XCTAssertEqual(prediction.category, "Dairy")
        XCTAssertGreaterThanOrEqual(prediction.confidence, 0.4, "Confidence should be reasonable")
        XCTAssertLessThanOrEqual(prediction.confidence, 1.0, "Confidence should not exceed 1")
        XCTAssertFalse(prediction.recommendation.isEmpty, "Should provide recommendation")
    }
    
    func testExpirationUrgencyClassification() throws {
        let service = ExpirationPredictionService()
        
        // Test with item purchased today
        let todayPrediction = service.predictExpiration(
            for: "Milk",
            category: "Dairy",
            purchaseDate: Date(),
            storage: "Fridge"
        )
        
        XCTAssertEqual(todayPrediction.urgency, .fresh, "Fresh milk should be classified as fresh")
        
        // Test with item purchased 10 days ago
        let oldDate = Date().addingTimeInterval(-10 * 24 * 3600)
        let oldPrediction = service.predictExpiration(
            for: "Milk",
            category: "Dairy",
            purchaseDate: oldDate,
            storage: "Fridge"
        )
        
        // Milk expires in ~7 days, so 10-day-old milk should be expired or close
        XCTAssertTrue([.expired, .useSoon].contains(oldPrediction.urgency),
                     "Old milk should be expired or expiring soon")
    }
    
    func testExpiringItemsFiltering() throws {
        let service = ExpirationPredictionService()
        let mockItems = service.generateMockFoodItems(count: 10)
        
        let expiringItems = service.getExpiringItems(items: mockItems)
        
        // All expiring items should expire within 5 days
        for prediction in expiringItems {
            XCTAssertLessThanOrEqual(prediction.daysRemaining, 5,
                                   "Expiring items should expire within 5 days")
        }
        
        // Should be sorted by urgency (highest priority first)
        for i in 1..<expiringItems.count {
            XCTAssertGreaterThanOrEqual(expiringItems[i-1].urgency.priority,
                                      expiringItems[i].urgency.priority,
                                      "Items should be sorted by urgency")
        }
    }
    
    // MARK: - ML Manager Integration Tests
    
    func testMLManagerInitialization() throws {
        XCTAssertNotNil(mlManager.shoppingListGenerator, "Should initialize shopping list generator")
        XCTAssertNotNil(mlManager.purchasePrediction, "Should initialize purchase prediction")
        XCTAssertNotNil(mlManager.priceOptimization, "Should initialize price optimization")
        XCTAssertNotNil(mlManager.expirationPrediction, "Should initialize expiration prediction")
    }
    
    func testShoppingInsightsGeneration() throws {
        let insights = mlManager.generateShoppingInsights(
            budget: 100,
            householdSize: 2,
            currentPantry: ["Pasta", "Rice"],
            preferences: ["Produce": 0.3]
        )
        
        XCTAssertGreaterThanOrEqual(insights.budgetUtilization, 0, "Budget utilization should be non-negative")
        XCTAssertLessThanOrEqual(insights.budgetUtilization, 1.2, "Budget utilization should be reasonable")
        XCTAssertGreaterThanOrEqual(insights.totalEstimatedCost, 0, "Total cost should be non-negative")
        
        // Should have price analyses for recommended items
        for recommendation in insights.recommendations {
            XCTAssertNotNil(insights.priceAnalyses[recommendation.itemName],
                          "Should have price analysis for \\(recommendation.itemName)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceShoppingListGeneration() throws {
        let service = ShoppingListGeneratorService()
        
        measure {
            _ = service.generateShoppingList(
                budget: 200,
                householdSize: 4,
                previousPurchases: ["Milk", "Bread", "Eggs"],
                preferences: ["Produce": 0.3, "Dairy": 0.2, "Meat & Seafood": 0.25]
            )
        }
    }
    
    func testPerformancePurchasePrediction() throws {
        let service = PurchasePredictionService()
        let history = service.generateMockHistory(for: "Milk", category: "Dairy")
        
        measure {
            _ = service.predictNextPurchase(for: "Milk", category: "Dairy", history: history)
        }
    }
    
    func testPerformancePriceAnalysis() throws {
        let service = PriceOptimizationService()
        let history = service.generateMockPriceHistory(for: "Milk", basePrice: 3.50, days: 90)
        
        measure {
            _ = service.analyzePrice(for: "Milk", currentPrice: Decimal(3.50), history: history)
        }
    }
}