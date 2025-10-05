//
//  ShoppingListGeneratorService.swift
//  Grocery-budget-optimizer
//
//  Created on 10/3/25.
//

import Foundation
import CoreML
import Combine

/// ML Error types
enum MLError: Error {
    case modelNotLoaded
    case predictionFailed(Error)
    case invalidInput
    case insufficientData
}

/// Shopping List Recommendation structure
struct ShoppingListRecommendation: Identifiable {
    let id = UUID()
    let itemName: String
    let quantity: Decimal
    let estimatedPrice: Decimal
    let priority: Double // 0-1, higher is more important
    let category: String
    
    var totalCost: Decimal {
        quantity * estimatedPrice
    }
}

// MARK: - Local Dependencies
// Local item database for rule-based recommendations
private struct LocalItemDatabase {
    static let commonItems = [
        "Milk", "Bread", "Eggs", "Chicken Breast", "Ground Beef", "Rice", 
        "Pasta", "Tomatoes", "Lettuce", "Cheese", "Yogurt", "Apples",
        "Bananas", "Carrots", "Onions", "Potatoes", "Coffee", "Butter",
        "Olive Oil", "Salt", "Pepper", "Garlic", "Bell Peppers", "Broccoli",
        "Spinach", "Salmon", "Tuna", "Cereal", "Oats", "Honey"
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
}

/// Service for generating optimized shopping lists using ML
class ShoppingListGeneratorService: ObservableObject {
    
    // For now, we'll use rule-based logic until Core ML models are trained
    private let itemDatabase = LocalItemDatabase.self
    
    init() {
        // Initialize service
    }
    
    /// Generate shopping list based on budget and preferences
    func generateShoppingList(
        budget: Decimal,
        householdSize: Int,
        previousPurchases: [String] = [],
        preferences: [String: Double] = [:]
    ) -> Result<[ShoppingListRecommendation], MLError> {
        
        // Validate input
        guard budget > 0 else {
            return .failure(.invalidInput)
        }
        
        do {
            let recommendations = try generateRecommendationsUsingLogic(
                budget: budget,
                householdSize: householdSize,
                previousPurchases: previousPurchases,
                preferences: preferences
            )
            
            return .success(recommendations)
            
        } catch {
            return .failure(.predictionFailed(error))
        }
    }
    
    /// Generate recommendations using rule-based logic (temporary until ML model is ready)
    private func generateRecommendationsUsingLogic(
        budget: Decimal,
        householdSize: Int,
        previousPurchases: [String],
        preferences: [String: Double]
    ) throws -> [ShoppingListRecommendation] {
        
        let budgetDouble = Double(truncating: budget as NSNumber)
        print("💰💰💰 BUDGET ANALYSIS 💰💰💰")
        print("   Input budget (Decimal): \(budget)")
        print("   Converted to Double: \(budgetDouble)")
        print("   This budget should be in USD (not converted from Rubles)")
        print("💰💰💰💰💰💰💰💰💰💰💰")
        
        var recommendations: [ShoppingListRecommendation] = []
        var remainingBudget = budgetDouble
        
        // Calculate household multiplier
        let householdMultiplier = 1.0 + (Double(householdSize - 1) * 0.2)
        
        // Get available items and their categories
        let availableItems = itemDatabase.commonItems.shuffled()
        
        // Priority order based on essential categories - using array to maintain order
        let categoryPriority: [(String, Double)] = [
            ("Dairy", 1.0),
            ("Produce", 0.9),
            ("Meat & Seafood", 0.8),
            ("Pantry", 0.7),
            ("Beverages", 0.6)
        ]
        
        print("🔍 Starting list generation with budget: $\(budgetDouble)")
        
        // Instead of filtering out all previous purchases, we'll prioritize items
        // that haven't been purchased recently, but still include all items
        let recentPurchaseSet = Set(previousPurchases)
        
        // Separate items into previously purchased and new items
        let newItems = availableItems.filter { !recentPurchaseSet.contains($0) }
        let previouslyPurchasedItems = availableItems.filter { recentPurchaseSet.contains($0) }
        
        // Prioritize new items first, then add previously purchased items
        // This gives variety while still ensuring a full shopping list
        let candidateItems = newItems + previouslyPurchasedItems

        print("🎲 ML Generator: Total available items: \(availableItems.count)")
        print("🎲 ML Generator: Previous purchases count: \(recentPurchaseSet.count)")
        print("🎲 ML Generator: New items to prioritize: \(newItems.count)")
        print("🎲 ML Generator: Previously purchased items: \(previouslyPurchasedItems.count)")
        print("🎲 ML Generator: Budget: $\(budgetDouble), Household: \(householdSize)")
        
        // Generate recommendations for each category (in priority order)
        for (category, basePriority) in categoryPriority {
            print("\n🏷️  Category: \(category) (priority: \(basePriority))")
            let categoryItems = candidateItems.filter { item in
                itemDatabase.itemCategories[item] == category
            }
            
            print("   Found \(categoryItems.count) items in category '\(category)'")
            print("   Items: \(categoryItems.joined(separator: ", "))")
            
            // Apply user preferences
            let userPreference = preferences[category] ?? basePriority
            let adjustedPriority = basePriority * userPreference
            
            // Skip if user has low preference for this category
            guard adjustedPriority > 0.3 else {
                print("   ⏭️  Skipping category '\(category)' due to low preference: \(adjustedPriority)")
                continue
            }
            
            print("📋 Processing category '\(category)' with \(categoryItems.count) items")
            
            // Add items from this category - increase to 4-5 items per category
            let itemsToAdd = min(5, categoryItems.count)
            print("   Planning to add up to \(itemsToAdd) items from this category")
            
            var itemsAddedInCategory = 0
            
            for i in 0..<itemsToAdd {
                let item = categoryItems[i]
                let basePrice = itemDatabase.itemPrices[item] ?? 5.0
                let quantity = Decimal(1.0 * householdMultiplier)
                let estimatedPrice = Decimal(basePrice)
                let totalCost = quantity * estimatedPrice
                
                print("   [Item \(i+1)/\(itemsToAdd)] Considering '\(item)': $\(basePrice) x \(quantity) = $\(totalCost)")
                
                // Boost priority for items that haven't been purchased before
                let isNewItem = !recentPurchaseSet.contains(item)
                let priorityBoost = isNewItem ? 1.2 : 1.0
                let finalPriority = adjustedPriority * priorityBoost
                
                // Check if we can afford this item
                if Double(truncating: totalCost as NSNumber) <= remainingBudget {
                    let recommendation = ShoppingListRecommendation(
                        itemName: item,
                        quantity: quantity,
                        estimatedPrice: estimatedPrice,
                        priority: finalPriority,
                        category: category
                    )

                    recommendations.append(recommendation)
                    remainingBudget -= Double(truncating: totalCost as NSNumber)
                    itemsAddedInCategory += 1
                    let newItemMarker = isNewItem ? "🆕" : "♻️"
                    print("  ✅ \(newItemMarker) Added '\(item)' - Cost: $\(totalCost), Remaining: $\(remainingBudget)")

                    // Stop if budget is getting low (reduced threshold)
                    if remainingBudget < 3.0 {
                        print("  ⚠️ Budget low ($\(remainingBudget)) - stopping category")
                        break
                    }
                } else {
                    print("  ❌ Cannot afford '\(item)' - Cost: $\(totalCost), Available: $\(remainingBudget)")
                }
            }
            
            print("   📊 Added \(itemsAddedInCategory) items from category '\(category)'")
            
            // Stop if budget is nearly exhausted (reduced threshold)
            if remainingBudget < 2.0 {
                print("💰 Budget nearly exhausted ($\(remainingBudget)) - stopping generation")
                break
            }
        }
        
        print("📊 Generated \(recommendations.count) total recommendations before final budget check")
        
        // Sort by priority (highest first)
        recommendations.sort { $0.priority > $1.priority }
        
        print("🔍 Final budget validation - Original budget: $\(budget)")
        
        // Ensure we don't exceed budget
        var finalRecommendations: [ShoppingListRecommendation] = []
        var runningTotal = Decimal(0)
        
        for recommendation in recommendations {
            let itemCost = recommendation.totalCost
            print("  💰 Checking '\(recommendation.itemName)': Cost=$\(itemCost), Running Total=$\(runningTotal), Budget=$\(budget)")
            if runningTotal + itemCost <= budget {
                finalRecommendations.append(recommendation)
                runningTotal += itemCost
                print("    ✅ INCLUDED (new total: $\(runningTotal))")
            } else {
                print("    ❌ EXCLUDED (would exceed budget: $\(runningTotal + itemCost) > $\(budget))")
            }
        }
        
        print("✅ Final result: \(finalRecommendations.count) items, Total cost: $\(runningTotal)")
        return finalRecommendations
    }
    
    /// Get smart suggestions based on current pantry and preferences
    func getSmartSuggestions(
        currentPantry: [String],
        budget: Decimal,
        preferences: [String: Double] = [:]
    ) -> [ShoppingListRecommendation] {
        
        let pantrySet = Set(currentPantry)
        
        // Suggest complementary items
        var suggestions: [ShoppingListRecommendation] = []
        
        // If they have pasta, suggest sauce and cheese
        if pantrySet.contains("Pasta") && !pantrySet.contains("Tomatoes") {
            suggestions.append(ShoppingListRecommendation(
                itemName: "Tomatoes",
                quantity: 2,
                estimatedPrice: Decimal(itemDatabase.itemPrices["Tomatoes"] ?? 2.99),
                priority: 0.9,
                category: "Produce"
            ))
        }
        
        // If they have bread, suggest butter or jam
        if pantrySet.contains("Bread") && !pantrySet.contains("Butter") {
            suggestions.append(ShoppingListRecommendation(
                itemName: "Butter",
                quantity: 1,
                estimatedPrice: Decimal(itemDatabase.itemPrices["Butter"] ?? 3.99),
                priority: 0.8,
                category: "Dairy"
            ))
        }
        
        // If they have cereal, suggest milk
        if pantrySet.contains("Cereal") && !pantrySet.contains("Milk") {
            suggestions.append(ShoppingListRecommendation(
                itemName: "Milk",
                quantity: 1,
                estimatedPrice: Decimal(itemDatabase.itemPrices["Milk"] ?? 3.50),
                priority: 0.95,
                category: "Dairy"
            ))
        }
        
        // Filter by budget
        let budgetDouble = Double(truncating: budget as NSNumber)
        var filteredSuggestions: [ShoppingListRecommendation] = []
        var total = 0.0
        
        for suggestion in suggestions.sorted(by: { $0.priority > $1.priority }) {
            let cost = Double(truncating: suggestion.totalCost as NSNumber)
            if total + cost <= budgetDouble {
                filteredSuggestions.append(suggestion)
                total += cost
            }
        }
        
        return filteredSuggestions
    }
}