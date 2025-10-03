//
//  GenerateTrainingData.swift
//  Script to generate synthetic training data for ML models
//
//  Created on 10/3/25.
//

import Foundation

/// Script to generate training data for all ML models
class TrainingDataGenerator {
    
    static func main() {
        print("🤖 Generating ML Training Data...")
        
        // Generate Shopping List training data
        generateShoppingListData()
        
        // Generate Purchase Prediction training data
        generatePurchasePredictionData()
        
        // Generate Price Optimization training data
        generatePriceOptimizationData()
        
        // Generate Expiration Prediction training data
        generateExpirationPredictionData()
        
        print("✅ Training data generation complete!")
    }
    
    private static func generateShoppingListData() {
        print("📋 Generating Shopping List training data...")
        
        let trainingData = ShoppingListDataGenerator.generateSyntheticData(count: 2000)
        
        // Convert to CSV for Create ML
        var csvContent = "budget,householdSize,timeOfYear,daysUntilNextShop,categoryPreferencesJSON,recommendedItemsJSON,estimatedTotal\\n"
        
        for data in trainingData {
            let categoryPrefsJSON = try? JSONSerialization.data(withJSONObject: data.categoryPreferences)
            let categoryPrefsString = String(data: categoryPrefsJSON ?? Data(), encoding: .utf8) ?? "{}"
            
            let itemsJSON = try? JSONSerialization.data(withJSONObject: data.recommendedItems)
            let itemsString = String(data: itemsJSON ?? Data(), encoding: .utf8) ?? "[]"
            
            let line = "\\(data.budget),\\(data.householdSize),\\(data.timeOfYear),\\(data.daysUntilNextShop),\"\\(categoryPrefsString)\",\"\\(itemsString)\",\\(data.estimatedTotal)\\n"
            csvContent += line
        }
        
        // Save to file
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsPath.appendingPathComponent("shopping_list_training_data.csv")
        
        do {
            try csvContent.write(to: filePath, atomically: true, encoding: .utf8)
            print("✅ Shopping List data saved to: \\(filePath.path)")
        } catch {
            print("❌ Error saving Shopping List data: \\(error)")
        }
    }
    
    private static func generatePurchasePredictionData() {
        print("🔮 Generating Purchase Prediction training data...")
        
        let trainingData = PurchasePredictionDataPreparation.generateSyntheticData(count: 1500)
        
        // Convert to CSV
        var csvContent = "itemName,category,daysSinceLastPurchase,averageDaysBetweenPurchases,householdSize,seasonalFactor,nextPurchaseDays,confidence\\n"
        
        for data in trainingData {
            let daysSince = Calendar.current.dateComponents([.day], from: data.lastPurchaseDate, to: Date()).day ?? 0
            let nextPurchaseDays = Calendar.current.dateComponents([.day], from: Date(), to: data.nextPurchaseDate).day ?? 0
            
            let line = "\\(data.itemName),\\(data.category),\\(daysSince),\\(data.averageDaysBetweenPurchases),\\(data.householdSize),\\(data.seasonalFactor),\\(nextPurchaseDays),\\(data.confidence)\\n"
            csvContent += line
        }
        
        // Save to file
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsPath.appendingPathComponent("purchase_prediction_training_data.csv")
        
        do {
            try csvContent.write(to: filePath, atomically: true, encoding: .utf8)
            print("✅ Purchase Prediction data saved to: \\(filePath.path)")
        } catch {
            print("❌ Error saving Purchase Prediction data: \\(error)")
        }
    }
    
    private static func generatePriceOptimizationData() {
        print("💰 Generating Price Optimization training data...")
        
        var csvContent = "itemName,category,currentPrice,averagePrice,dayOfWeek,weekOfMonth,month,isGoodPrice,isBestPrice,priceTrend,priceScore\\n"
        
        let items = ["Milk", "Bread", "Eggs", "Chicken Breast", "Apples", "Bananas"]
        let categories = ["Dairy", "Pantry", "Pantry", "Meat & Seafood", "Produce", "Produce"]
        let basePrices = [3.50, 2.49, 3.49, 6.99, 3.49, 1.49]
        
        for i in 0..<1000 {
            let itemIndex = i % items.count
            let item = items[itemIndex]
            let category = categories[itemIndex]
            let basePrice = basePrices[itemIndex]
            
            let currentPrice = basePrice * Double.random(in: 0.8...1.2)
            let averagePrice = basePrice
            let dayOfWeek = Int.random(in: 1...7)
            let weekOfMonth = Int.random(in: 1...4)
            let month = Int.random(in: 1...12)
            let isGoodPrice = currentPrice < averagePrice
            let isBestPrice = currentPrice < averagePrice * 0.85
            let priceTrend = ["increasing", "stable", "decreasing"].randomElement() ?? "stable"
            let priceScore = 1.0 - ((currentPrice - basePrice * 0.8) / (basePrice * 1.2 - basePrice * 0.8))
            
            let line = "\\(item),\\(category),\\(currentPrice),\\(averagePrice),\\(dayOfWeek),\\(weekOfMonth),\\(month),\\(isGoodPrice),\\(isBestPrice),\\(priceTrend),\\(priceScore)\\n"
            csvContent += line
        }
        
        // Save to file
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsPath.appendingPathComponent("price_optimization_training_data.csv")
        
        do {
            try csvContent.write(to: filePath, atomically: true, encoding: .utf8)
            print("✅ Price Optimization data saved to: \\(filePath.path)")
        } catch {
            print("❌ Error saving Price Optimization data: \\(error)")
        }
    }
    
    private static func generateExpirationPredictionData() {
        print("🥗 Generating Expiration Prediction training data...")
        
        let trainingData = ExpirationPredictionDataPreparation.generateSyntheticData(count: 1200)
        
        // Convert to CSV
        var csvContent = "itemCategory,storageLocation,packageType,purchaseDate,temperature,isOrganic,actualExpirationDays,wasteCategory\\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for data in trainingData {
            let purchaseDateString = dateFormatter.string(from: data.purchaseDate)
            
            let line = "\\(data.itemCategory),\\(data.storageLocation),\\(data.packageType),\\(purchaseDateString),\\(data.temperature),\\(data.isOrganic),\\(data.actualExpirationDays),\\(data.wasteCategory)\\n"
            csvContent += line
        }
        
        // Save to file
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsPath.appendingPathComponent("expiration_prediction_training_data.csv")
        
        do {
            try csvContent.write(to: filePath, atomically: true, encoding: .utf8)
            print("✅ Expiration Prediction data saved to: \\(filePath.path)")
        } catch {
            print("❌ Error saving Expiration Prediction data: \\(error)")
        }
    }
}

// Execute the script
if CommandLine.arguments.contains("--generate-data") {
    TrainingDataGenerator.main()
}