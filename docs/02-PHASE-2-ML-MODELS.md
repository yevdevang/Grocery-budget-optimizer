# Phase 2: Machine Learning Models - Core ML Integration

## 📋 Overview

Design, train, and integrate 4 Core ML models to power the intelligent features of the app: smart shopping list generation, purchase prediction, price optimization, and expiration tracking.

**Duration**: 1 week
**Dependencies**: Phase 1 (Foundation)

---

## 🎯 Objectives

- ✅ Set up Create ML training pipeline
- ✅ Train Shopping List Generator model
- ✅ Train Purchase Prediction model
- ✅ Train Price Optimization model
- ✅ Train Expiration Prediction model
- ✅ Integrate all models with Core ML
- ✅ Create ML service layer
- ✅ Test model accuracy and performance

---

## 🤖 Model 1: Shopping List Generator

### Purpose
Generate optimized shopping lists based on budget constraints, preferences, and purchase history.

### Approach
Use a **Recommendation System** combined with **Constraint Optimization**.

### Training Data Requirements

```swift
struct ShoppingListTrainingData {
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
```

### Data Generation Script

Create `Scripts/GenerateShoppingListData.swift`:

```swift
import Foundation
import CreateML

struct ShoppingListDataGenerator {
    static func generateSyntheticData(count: Int = 1000) -> [ShoppingListTrainingData] {
        var data: [ShoppingListTrainingData] = []

        let commonItems = [
            "Milk", "Bread", "Eggs", "Chicken", "Rice", "Pasta",
            "Tomatoes", "Lettuce", "Cheese", "Yogurt", "Apples",
            "Bananas", "Carrots", "Onions", "Potatoes", "Coffee"
        ]

        let categories = [
            "Dairy": 0.2,
            "Produce": 0.25,
            "Meat": 0.2,
            "Pantry": 0.2,
            "Beverages": 0.15
        ]

        for _ in 0..<count {
            let budget = Double.random(in: 50...300)
            let householdSize = Int.random(in: 1...6)
            let timeOfYear = Int.random(in: 1...12)

            // Generate realistic shopping list based on budget
            let numItems = Int(budget / 5) // Avg $5 per item
            let selectedItems = commonItems.shuffled().prefix(numItems)

            var quantities: [String: Double] = [:]
            for item in selectedItems {
                quantities[item] = Double.random(in: 1...5)
            }

            let trainingData = ShoppingListTrainingData(
                budget: budget,
                householdSize: householdSize,
                previousPurchases: Array(selectedItems),
                categoryPreferences: categories,
                timeOfYear: timeOfYear,
                daysUntilNextShop: Int.random(in: 3...14),
                recommendedItems: Array(selectedItems),
                recommendedQuantities: quantities,
                estimatedTotal: budget * Double.random(in: 0.85...0.95)
            )

            data.append(trainingData)
        }

        return data
    }

    static func exportToCSV(_ data: [ShoppingListTrainingData], path: String) {
        // Export logic here
    }
}
```

### Training with Create ML

Create `MLModels/TrainShoppingListModel.playground`:

```swift
import CreateML
import Foundation

// Load or generate training data
let trainingData = ShoppingListDataGenerator.generateSyntheticData(count: 2000)

// Convert to MLDataTable
let dataTable = try MLDataTable(/* converted data */)

// Split data
let (trainingData, testingData) = dataTable.randomSplit(by: 0.8)

// Train Recommender Model
let recommender = try MLRecommender(
    trainingData: trainingData,
    userColumn: "householdSize",
    itemColumn: "recommendedItems"
)

// Evaluate
let evaluation = recommender.evaluation(on: testingData)
print("Precision: \(evaluation.precision)")
print("Recall: \(evaluation.recall)")

// Export model
let metadata = MLModelMetadata(
    author: "Grocery Budget Optimizer",
    shortDescription: "Generates smart shopping lists",
    version: "1.0"
)

try recommender.write(to: URL(fileURLWithPath: "ShoppingListGenerator.mlmodel"),
                     metadata: metadata)
```

### Core ML Integration

Create `Data/MLModels/ShoppingListGeneratorService.swift`:

```swift
import CoreML
import Foundation

class ShoppingListGeneratorService {
    private var model: ShoppingListGenerator?

    init() {
        loadModel()
    }

    private func loadModel() {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .cpuAndNeuralEngine
            model = try ShoppingListGenerator(configuration: config)
        } catch {
            print("Failed to load Shopping List Generator model: \(error)")
        }
    }

    func generateShoppingList(
        budget: Decimal,
        householdSize: Int,
        previousPurchases: [GroceryItem],
        preferences: [String: Double]
    ) -> Result<[ShoppingListRecommendation], MLError> {
        guard let model = model else {
            return .failure(.modelNotLoaded)
        }

        do {
            // Prepare input
            let input = ShoppingListGeneratorInput(
                budget: budget.doubleValue,
                householdSize: Int64(householdSize),
                previousPurchases: previousPurchases.map { $0.name },
                categoryPreferences: preferences
            )

            // Get predictions
            let output = try model.prediction(input: input)

            // Parse results
            let recommendations = parseRecommendations(output)
            return .success(recommendations)

        } catch {
            return .failure(.predictionFailed(error))
        }
    }

    private func parseRecommendations(_ output: ShoppingListGeneratorOutput)
        -> [ShoppingListRecommendation] {
        // Parse model output into recommendations
        return []
    }
}

struct ShoppingListRecommendation {
    let itemName: String
    let quantity: Decimal
    let estimatedPrice: Decimal
    let priority: Double // 0-1
}

enum MLError: Error {
    case modelNotLoaded
    case predictionFailed(Error)
    case invalidInput
}
```

---

## 📊 Model 2: Purchase Prediction

### Purpose
Predict when users will need to repurchase items based on historical consumption patterns.

### Approach
**Time Series Forecasting** using recurrent patterns.

### Training Data Structure

```swift
struct PurchasePredictionTrainingData {
    // Input Features
    let itemName: String
    let category: String
    let lastPurchaseDate: Date
    let purchaseHistory: [Date] // Array of purchase dates
    let averageQuantity: Double
    let householdSize: Int
    let seasonalFactor: Double

    // Output Label
    let nextPurchaseDate: Date
    let confidence: Double
}
```

### Data Preparation

```swift
class PurchasePredictionDataPreparation {
    static func preparePurchaseHistory(purchases: [Purchase])
        -> [PurchasePredictionTrainingData] {

        // Group by item
        let groupedByItem = Dictionary(grouping: purchases, by: { $0.groceryItem.name })

        var trainingData: [PurchasePredictionTrainingData] = []

        for (itemName, itemPurchases) in groupedByItem {
            guard itemPurchases.count >= 3 else { continue } // Need history

            let sortedPurchases = itemPurchases.sorted { $0.purchaseDate < $1.purchaseDate }

            // Calculate average interval
            let intervals = zip(sortedPurchases, sortedPurchases.dropFirst()).map {
                $1.purchaseDate.timeIntervalSince($0.purchaseDate)
            }
            let avgInterval = intervals.reduce(0, +) / Double(intervals.count)

            // Predict next purchase
            let lastPurchase = sortedPurchases.last!
            let predictedNext = lastPurchase.purchaseDate.addingTimeInterval(avgInterval)

            let data = PurchasePredictionTrainingData(
                itemName: itemName,
                category: lastPurchase.groceryItem.category,
                lastPurchaseDate: lastPurchase.purchaseDate,
                purchaseHistory: sortedPurchases.map { $0.purchaseDate },
                averageQuantity: sortedPurchases.map { $0.quantity.doubleValue }
                    .reduce(0, +) / Double(sortedPurchases.count),
                householdSize: 3, // Would come from user settings
                seasonalFactor: calculateSeasonalFactor(month: Calendar.current
                    .component(.month, from: lastPurchase.purchaseDate)),
                nextPurchaseDate: predictedNext,
                confidence: calculateConfidence(intervals: intervals)
            )

            trainingData.append(data)
        }

        return trainingData
    }

    static func calculateSeasonalFactor(month: Int) -> Double {
        // Summer months might have different patterns
        return [0.9, 0.9, 1.0, 1.0, 1.1, 1.2, 1.2, 1.1, 1.0, 1.0, 0.9, 0.9][month - 1]
    }

    static func calculateConfidence(intervals: [TimeInterval]) -> Double {
        guard !intervals.isEmpty else { return 0 }
        let mean = intervals.reduce(0, +) / Double(intervals.count)
        let variance = intervals.map { pow($0 - mean, 2) }.reduce(0, +) / Double(intervals.count)
        let stdDev = sqrt(variance)

        // Lower std dev = higher confidence
        return max(0, min(1, 1 - (stdDev / mean)))
    }
}
```

### Training Model

```swift
// In Create ML Playground
import CreateML
import Foundation

let purchaseData = /* Load from Core Data or CSV */

// Create Time Series model
let timeSeries = try MLTimeSeriesForecaster(
    trainingData: purchaseData,
    targetColumn: "nextPurchaseDate",
    featureColumns: [
        "purchaseHistory",
        "averageQuantity",
        "householdSize",
        "seasonalFactor"
    ]
)

let evaluation = timeSeries.evaluation(on: testData)
print("RMSE: \(evaluation.rootMeanSquaredError)")

try timeSeries.write(to: URL(fileURLWithPath: "PurchasePredictor.mlmodel"))
```

### Service Implementation

```swift
class PurchasePredictionService {
    private var model: PurchasePredictor?

    init() {
        loadModel()
    }

    private func loadModel() {
        do {
            model = try PurchasePredictor(configuration: MLModelConfiguration())
        } catch {
            print("Failed to load Purchase Predictor: \(error)")
        }
    }

    func predictNextPurchase(
        for item: GroceryItem,
        history: [Purchase]
    ) -> Result<PurchasePrediction, MLError> {
        guard let model = model else {
            return .failure(.modelNotLoaded)
        }

        guard history.count >= 2 else {
            return .failure(.invalidInput)
        }

        do {
            let preparedData = PurchasePredictionDataPreparation
                .preparePurchaseHistory(purchases: history)

            guard let data = preparedData.first else {
                return .failure(.invalidInput)
            }

            let input = PurchasePredictorInput(
                itemName: data.itemName,
                category: data.category,
                purchaseHistory: data.purchaseHistory.map { $0.timeIntervalSince1970 },
                averageQuantity: data.averageQuantity,
                householdSize: Int64(data.householdSize),
                seasonalFactor: data.seasonalFactor
            )

            let output = try model.prediction(input: input)

            let prediction = PurchasePrediction(
                item: item,
                predictedDate: Date(timeIntervalSince1970: output.nextPurchaseDate),
                confidence: output.confidence,
                recommendedQuantity: Decimal(output.recommendedQuantity)
            )

            return .success(prediction)

        } catch {
            return .failure(.predictionFailed(error))
        }
    }
}

struct PurchasePrediction {
    let item: GroceryItem
    let predictedDate: Date
    let confidence: Double
    let recommendedQuantity: Decimal

    var daysUntilPurchase: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: predictedDate).day ?? 0
    }
}
```

---

## 💰 Model 3: Price Optimization

### Purpose
Analyze historical prices and recommend optimal purchase timing.

### Approach
**Anomaly Detection** + **Time Series Analysis** to identify price patterns and best deals.

### Training Data

```swift
struct PriceOptimizationTrainingData {
    let itemName: String
    let category: String
    let prices: [Double] // Historical prices
    let dates: [Date] // Corresponding dates
    let storeName: String?
    let dayOfWeek: Int
    let weekOfMonth: Int
    let month: Int

    // Labels
    let isGoodPrice: Bool // Below average
    let isBestPrice: Bool // In bottom 20%
    let priceTrend: String // "increasing", "stable", "decreasing"
}
```

### Training Implementation

```swift
// Price analysis logic
class PriceOptimizationDataPreparation {
    static func analyzePriceHistory(item: GroceryItem, priceHistory: [PriceHistory])
        -> PriceOptimizationTrainingData {

        let prices = priceHistory.map { $0.price.doubleValue }
        let sortedPrices = prices.sorted()

        let average = prices.reduce(0, +) / Double(prices.count)
        let median = sortedPrices[sortedPrices.count / 2]
        let percentile20 = sortedPrices[sortedPrices.count / 5]

        let currentPrice = prices.last ?? 0

        return PriceOptimizationTrainingData(
            itemName: item.name,
            category: item.category,
            prices: prices,
            dates: priceHistory.map { $0.recordedAt },
            storeName: priceHistory.last?.storeName,
            dayOfWeek: Calendar.current.component(.weekday, from: Date()),
            weekOfMonth: Calendar.current.component(.weekOfMonth, from: Date()),
            month: Calendar.current.component(.month, from: Date()),
            isGoodPrice: currentPrice < average,
            isBestPrice: currentPrice <= percentile20,
            priceTrend: calculateTrend(prices: prices)
        )
    }

    static func calculateTrend(prices: [Double]) -> String {
        guard prices.count >= 3 else { return "stable" }

        let recent = prices.suffix(5)
        let older = prices.prefix(5)

        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let olderAvg = older.reduce(0, +) / Double(older.count)

        let change = (recentAvg - olderAvg) / olderAvg

        if change > 0.1 {
            return "increasing"
        } else if change < -0.1 {
            return "decreasing"
        } else {
            return "stable"
        }
    }
}
```

### Service Implementation

```swift
class PriceOptimizationService {
    func analyzePrice(
        for item: GroceryItem,
        currentPrice: Decimal,
        history: [PriceHistory]
    ) -> PriceAnalysis {

        let prices = history.map { $0.price.doubleValue }
        guard !prices.isEmpty else {
            return PriceAnalysis(
                currentPrice: currentPrice,
                averagePrice: currentPrice,
                isGoodDeal: false,
                recommendation: "Insufficient price history",
                savingsPercentage: 0
            )
        }

        let average = prices.reduce(0, +) / Double(prices.count)
        let sortedPrices = prices.sorted()
        let percentile20 = sortedPrices[max(0, sortedPrices.count / 5)]

        let currentPriceDouble = currentPrice.doubleValue
        let isGoodDeal = currentPriceDouble <= percentile20
        let savingsPercentage = ((average - currentPriceDouble) / average) * 100

        var recommendation: String
        if isGoodDeal {
            recommendation = "Excellent price! \(Int(savingsPercentage))% below average"
        } else if currentPriceDouble < average {
            recommendation = "Good price, consider buying"
        } else if currentPriceDouble > average * 1.2 {
            recommendation = "Price is high, wait for better deal"
        } else {
            recommendation = "Average price"
        }

        return PriceAnalysis(
            currentPrice: currentPrice,
            averagePrice: Decimal(average),
            isGoodDeal: isGoodDeal,
            recommendation: recommendation,
            savingsPercentage: savingsPercentage
        )
    }

    func predictBestTimeToBuy(item: GroceryItem, history: [PriceHistory])
        -> BestTimePrediction {

        // Analyze patterns by day of week
        let byDayOfWeek = Dictionary(grouping: history) {
            Calendar.current.component(.weekday, from: $0.recordedAt)
        }

        var averagesByDay: [Int: Double] = [:]
        for (day, prices) in byDayOfWeek {
            let avg = prices.map { $0.price.doubleValue }.reduce(0, +) / Double(prices.count)
            averagesByDay[day] = avg
        }

        let bestDay = averagesByDay.min(by: { $0.value < $1.value })?.key ?? 1
        let dayName = Calendar.current.weekdaySymbols[bestDay - 1]

        return BestTimePrediction(
            bestDayOfWeek: bestDay,
            bestDayName: dayName,
            estimatedSavings: 10.0, // Calculate based on data
            confidence: 0.75
        )
    }
}

struct PriceAnalysis {
    let currentPrice: Decimal
    let averagePrice: Decimal
    let isGoodDeal: Bool
    let recommendation: String
    let savingsPercentage: Double
}

struct BestTimePrediction {
    let bestDayOfWeek: Int
    let bestDayName: String
    let estimatedSavings: Double
    let confidence: Double
}
```

---

## 🥗 Model 4: Expiration Prediction

### Purpose
Predict accurate expiration dates and identify items that need to be used soon.

### Approach
**Classification + Regression** to predict shelf life based on item type, storage, and purchase date.

### Training Data

```swift
struct ExpirationTrainingData {
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
```

### Expiration Database

```swift
enum ExpirationDatabase {
    static let standardShelfLife: [String: Int] = [
        // Dairy
        "Milk": 7,
        "Yogurt": 14,
        "Cheese": 21,

        // Produce
        "Lettuce": 7,
        "Tomatoes": 7,
        "Apples": 14,
        "Bananas": 5,
        "Berries": 3,

        // Meat
        "Chicken": 2,
        "Beef": 3,
        "Fish": 2,

        // Pantry
        "Bread": 7,
        "Rice": 730, // 2 years
        "Pasta": 730,
        "Canned Goods": 1095 // 3 years
    ]

    static func getShelfLife(
        for item: String,
        storage: String,
        packageType: String
    ) -> Int {
        var baseDays = standardShelfLife[item] ?? 7

        // Adjust for storage
        switch storage {
        case "Freezer":
            baseDays *= 4
        case "Pantry":
            baseDays = Int(Double(baseDays) * 0.8)
        default:
            break
        }

        return baseDays
    }
}
```

### Service Implementation

```swift
class ExpirationPredictionService {
    func predictExpiration(
        for item: GroceryItem,
        purchaseDate: Date,
        storage: String = "Fridge",
        packageType: String = "Fresh"
    ) -> ExpirationPrediction {

        let baseShelfLife = ExpirationDatabase.getShelfLife(
            for: item.name,
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

        let urgency: ExpirationUrgency
        if daysRemaining <= 0 {
            urgency = .expired
        } else if daysRemaining <= 2 {
            urgency = .useSoon
        } else if daysRemaining <= 5 {
            urgency = .moderate
        } else {
            urgency = .fresh
        }

        return ExpirationPrediction(
            item: item,
            predictedExpirationDate: predictedExpiration,
            daysRemaining: daysRemaining,
            urgency: urgency,
            confidence: 0.85,
            recommendation: getRecommendation(for: urgency, item: item)
        )
    }

    private func getRecommendation(for urgency: ExpirationUrgency, item: GroceryItem)
        -> String {
        switch urgency {
        case .expired:
            return "This item may be expired. Check before consuming."
        case .useSoon:
            return "Use within 2 days to avoid waste"
        case .moderate:
            return "Plan to use within this week"
        case .fresh:
            return "Item is fresh"
        }
    }

    func getExpiringItems(trackers: [ExpirationTracker]) -> [ExpirationTracker] {
        trackers.filter { tracker in
            let daysRemaining = Calendar.current.dateComponents(
                [.day],
                from: Date(),
                to: tracker.estimatedExpirationDate
            ).day ?? 0

            return daysRemaining <= 5 && !tracker.isConsumed && !tracker.isWasted
        }
        .sorted { $0.estimatedExpirationDate < $1.estimatedExpirationDate }
    }
}

struct ExpirationPrediction {
    let item: GroceryItem
    let predictedExpirationDate: Date
    let daysRemaining: Int
    let urgency: ExpirationUrgency
    let confidence: Double
    let recommendation: String
}

enum ExpirationUrgency {
    case expired
    case useSoon
    case moderate
    case fresh

    var color: String {
        switch self {
        case .expired: return "red"
        case .useSoon: return "orange"
        case .moderate: return "yellow"
        case .fresh: return "green"
        }
    }
}
```

---

## 🧪 Model Testing & Validation

### Create Test Suite

```swift
import XCTest
@testable import Grocery_budget_optimizer

final class MLModelsTests: XCTestCase {

    func testShoppingListGenerator() {
        let service = ShoppingListGeneratorService()

        let result = service.generateShoppingList(
            budget: 100,
            householdSize: 2,
            previousPurchases: [],
            preferences: ["Produce": 0.3, "Dairy": 0.2]
        )

        switch result {
        case .success(let recommendations):
            XCTAssertFalse(recommendations.isEmpty)
            let totalCost = recommendations.reduce(Decimal(0)) {
                $0 + ($1.quantity * $1.estimatedPrice)
            }
            XCTAssertLessThanOrEqual(totalCost, 100)

        case .failure(let error):
            XCTFail("Generation failed: \(error)")
        }
    }

    func testPurchasePrediction() {
        let service = PurchasePredictionService()
        let item = GroceryItem(name: "Milk", category: "Dairy", unit: "L")

        // Create mock purchase history
        let history = [
            Purchase(/* ... */),
            Purchase(/* ... */)
        ]

        let result = service.predictNextPurchase(for: item, history: history)

        switch result {
        case .success(let prediction):
            XCTAssertGreaterThan(prediction.daysUntilPurchase, 0)
            XCTAssertLessThan(prediction.daysUntilPurchase, 60)

        case .failure:
            XCTFail("Prediction failed")
        }
    }

    func testPriceOptimization() {
        let service = PriceOptimizationService()
        let item = GroceryItem(name: "Milk", category: "Dairy", unit: "L")

        let history: [PriceHistory] = [
            // Mock price history
        ]

        let analysis = service.analyzePrice(
            for: item,
            currentPrice: 3.50,
            history: history
        )

        XCTAssertNotNil(analysis.recommendation)
        XCTAssertGreaterThanOrEqual(analysis.savingsPercentage, -100)
    }

    func testExpirationPrediction() {
        let service = ExpirationPredictionService()
        let item = GroceryItem(name: "Milk", category: "Dairy", unit: "L")

        let prediction = service.predictExpiration(
            for: item,
            purchaseDate: Date(),
            storage: "Fridge"
        )

        XCTAssertGreaterThan(prediction.daysRemaining, 0)
        XCTAssertNotNil(prediction.recommendation)
    }
}
```

---

## 📝 Acceptance Criteria

### Phase 2 Complete When:

- ✅ All 4 ML models created and trained
- ✅ Models integrated with Core ML
- ✅ Service layer implemented for each model
- ✅ Model accuracy validated (>70% for predictions)
- ✅ Performance tested (inference < 100ms)
- ✅ Error handling implemented
- ✅ Unit tests passing (>80% coverage)
- ✅ Documentation for model usage complete

---

## ⚠️ Potential Challenges

### Challenge 1: Limited Training Data
**Problem**: Not enough real user data initially
**Solution**: Use synthetic data generation; update models as real data accumulates

### Challenge 2: Model Size
**Problem**: Large models impact app size
**Solution**: Optimize models; use quantization; consider on-demand downloads

### Challenge 3: Prediction Accuracy
**Problem**: Models may not be accurate for all users
**Solution**: Allow users to provide feedback; implement online learning strategies

### Challenge 4: Cold Start Problem
**Problem**: New users have no history
**Solution**: Use defaults and category-based recommendations; learn quickly

---

## 🚀 Next Steps

Proceed to:
- **[Phase 3: Core Features](03-PHASE-3-CORE-FEATURES.md)** - Implement budget management, shopping lists, and item tracking

---

## 📚 Resources

- [Create ML Documentation](https://developer.apple.com/documentation/createml)
- [Core ML Documentation](https://developer.apple.com/documentation/coreml)
- [ML Model Optimization](https://developer.apple.com/documentation/coreml/optimizing_core_ml_models)
- [Time Series Forecasting Guide](https://developer.apple.com/documentation/createml/mltimeseriesforecaster)
