//
//  PriceOptimizationService.swift
//  Grocery-budget-optimizer
//
//  Created on 10/3/25.
//

import Foundation
import CoreML
import Combine

/// Price analysis result
struct PriceAnalysis {
    let currentPrice: Decimal
    let averagePrice: Decimal
    let medianPrice: Decimal
    let lowestPrice: Decimal
    let highestPrice: Decimal
    let isGoodDeal: Bool
    let isBestPrice: Bool
    let recommendation: String
    let savingsPercentage: Double
    let priceScore: Double // 0-1, where 1 is excellent price
    
    var savingsAmount: Decimal {
        averagePrice - currentPrice
    }
}

/// Best time to buy prediction
struct BestTimePrediction {
    let itemName: String
    let bestTimeFrame: TimeFrame
    let expectedPrice: Decimal
    let currentPrice: Decimal
    let savings: Decimal
    let confidence: Double
    
    var savingsPercentage: Double {
        guard currentPrice > 0 else { return 0.0 }
        return Double(truncating: ((currentPrice - expectedPrice) / currentPrice * 100) as NSDecimalNumber)
    }
}

/// Time frames for predictions
enum TimeFrame: String, CaseIterable {
    case nextWeek = "Next Week"
    case twoWeeks = "2 Weeks"
    case nextMonth = "Next Month"
    case twoMonths = "2 Months"
    case seasonal = "Seasonal"
    
    var daysFromNow: Int {
        switch self {
        case .nextWeek: return 7
        case .twoWeeks: return 14
        case .nextMonth: return 30
        case .twoMonths: return 60
        case .seasonal: return 90
        }
    }
}

/// Mock price history for testing
struct MockPriceHistory {
    let itemName: String
    let price: Decimal
    let recordedAt: Date
    let storeName: String?
    let location: String?
}

/// Service for analyzing prices and optimizing purchase timing
class PriceOptimizationService: ObservableObject {
    
    init() {
        // Initialize service
    }
    
    /// Analyze current price against historical data
    func analyzePrice(
        for itemName: String,
        currentPrice: Decimal,
        history: [MockPriceHistory]
    ) -> PriceAnalysis {
        
        let prices = history.map { Double(truncating: $0.price as NSNumber) }
        
        guard !prices.isEmpty else {
            return PriceAnalysis(
                currentPrice: currentPrice,
                averagePrice: currentPrice,
                medianPrice: currentPrice,
                lowestPrice: currentPrice,
                highestPrice: currentPrice,
                isGoodDeal: false,
                isBestPrice: false,
                recommendation: "Insufficient price history",
                savingsPercentage: 0,
                priceScore: 0.5
            )
        }
        
        let sortedPrices = prices.sorted()
        let average = prices.reduce(0, +) / Double(prices.count)
        let median = sortedPrices[sortedPrices.count / 2]
        let lowest = sortedPrices.first ?? 0
        let highest = sortedPrices.last ?? 0
        let percentile20 = sortedPrices[max(0, sortedPrices.count / 5)]
        
        let currentPriceDouble = Double(truncating: currentPrice as NSNumber)
        let isGoodDeal = currentPriceDouble <= percentile20
        let isBestPrice = currentPriceDouble <= lowest * 1.05 // Within 5% of lowest
        let savingsPercentage = ((average - currentPriceDouble) / average) * 100
        let priceScore = calculatePriceScore(currentPrice: currentPriceDouble, prices: sortedPrices)
        
        let recommendation = generateRecommendation(
            currentPrice: currentPriceDouble,
            average: average,
            isGoodDeal: isGoodDeal,
            isBestPrice: isBestPrice,
            savingsPercentage: savingsPercentage
        )
        
        return PriceAnalysis(
            currentPrice: currentPrice,
            averagePrice: Decimal(average),
            medianPrice: Decimal(median),
            lowestPrice: Decimal(lowest),
            highestPrice: Decimal(highest),
            isGoodDeal: isGoodDeal,
            isBestPrice: isBestPrice,
            recommendation: recommendation,
            savingsPercentage: savingsPercentage,
            priceScore: priceScore
        )
    }
    
    /// Predict best time to buy based on historical patterns
    func predictBestTimeToBuy(
        itemName: String,
        history: [MockPriceHistory]
    ) -> BestTimePrediction {
        
        // Analyze patterns by day of week
        let byDayOfWeek = Dictionary(grouping: history) {
            Calendar.current.component(.weekday, from: $0.recordedAt)
        }
        
        var averagesByDay: [Int: Double] = [:]
        for (day, priceRecords) in byDayOfWeek {
            let avg = priceRecords.map { Double(truncating: $0.price as NSNumber) }
                .reduce(0, +) / Double(priceRecords.count)
            averagesByDay[day] = avg
        }
        
        let bestDay = averagesByDay.min(by: { $0.value < $1.value })?.key ?? 1
        let worstDay = averagesByDay.max(by: { $0.value < $1.value })?.key ?? 1
        
        let bestPrice = averagesByDay[bestDay] ?? 0
        let worstPrice = averagesByDay[worstDay] ?? 0
        
        return BestTimePrediction(
            itemName: itemName,
            bestTimeFrame: .nextWeek, // Default to next week
            expectedPrice: Decimal(bestPrice),
            currentPrice: Decimal(worstPrice),
            savings: Decimal(worstPrice - bestPrice),
            confidence: min(0.9, Double(history.count) / 20.0) // Higher confidence with more data
        )
    }
    
    /// Calculate price score (0-1, where 1 is best price)
    private func calculatePriceScore(currentPrice: Double, prices: [Double]) -> Double {
        guard !prices.isEmpty else { return 0.5 }
        
        let min = prices.min() ?? currentPrice
        let max = prices.max() ?? currentPrice
        
        guard max > min else { return 1.0 }
        
        // Invert the score so lower prices get higher scores
        return 1.0 - ((currentPrice - min) / (max - min))
    }
    
    /// Generate recommendation text
    private func generateRecommendation(
        currentPrice: Double,
        average: Double,
        isGoodDeal: Bool,
        isBestPrice: Bool,
        savingsPercentage: Double
    ) -> String {
        
        if isBestPrice {
            return "Excellent price! Best deal we've seen"
        } else if isGoodDeal {
            return "Good deal! \(Int(savingsPercentage))% below average"
        } else if currentPrice < average {
            return "Fair price, slightly below average"
        } else if currentPrice > average * 1.2 {
            return "Price is high. Wait for better deal"
        } else {
            return "Average price for this item"
        }
    }
    
    /// Generate mock price history for testing
    func generateMockPriceHistory(for itemName: String, basePrice: Double, days: Int = 30) -> [MockPriceHistory] {
        var history: [MockPriceHistory] = []
        
        for i in 0..<days {
            let date = Date().addingTimeInterval(-Double(days - i) * 24 * 3600)
            
            // Add realistic price variation
            let dayOfWeek = Calendar.current.component(.weekday, from: date)
            let weekMultiplier = (dayOfWeek == 1 || dayOfWeek == 7) ? 1.05 : 0.98 // Weekends slightly more expensive
            
            let seasonalVariation = sin(Double(i) * .pi / 30) * 0.1 + 1.0 // Seasonal variation
            let randomVariation = Double.random(in: 0.9...1.1)
            
            let finalPrice = basePrice * weekMultiplier * seasonalVariation * randomVariation
            
            let priceHistory = MockPriceHistory(
                itemName: itemName,
                price: Decimal(finalPrice),
                recordedAt: date,
                storeName: ["Whole Foods", "Safeway", "Trader Joe's", "Kroger"].randomElement(),
                location: ["Downtown", "Suburb", "Mall"].randomElement()
            )
            
            history.append(priceHistory)
        }
        
        return history
    }
}