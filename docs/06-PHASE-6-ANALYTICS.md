# Phase 6: Analytics & Insights - Data-Driven Intelligence

## 📋 Overview

Build comprehensive analytics and insights features that help users understand spending patterns, identify savings opportunities, and track progress toward financial goals.

**Duration**: 1 week
**Dependencies**: Phase 3 (Core Features), Phase 5 (UI/UX)

---

## 🎯 Objectives

- ✅ Create analytics data models
- ✅ Implement spending analysis use cases
- ✅ Build savings opportunities detector
- ✅ Create comparative analytics (month-over-month, year-over-year)
- ✅ Implement waste tracking analytics
- ✅ Build custom report generation
- ✅ Create analytics visualizations
- ✅ Add export capabilities

---

## 📊 Analytics Data Models

### Spending Summary

Create `Domain/Entities/Analytics/SpendingSummary.swift`:

```swift
import Foundation

struct SpendingSummary {
    let period: DateInterval
    let totalSpent: Decimal
    let transactionCount: Int
    let averageTransactionValue: Decimal
    let spendingByCategory: [String: CategorySpending]
    let spendingByStore: [String: Decimal]
    let topItems: [ItemSpending]
    let dailyAverage: Decimal
    let weeklyAverage: Decimal
    let comparisonToPrevious: ComparisonMetrics?

    var projectedMonthlySpending: Decimal {
        let daysInPeriod = Calendar.current.dateComponents(
            [.day],
            from: period.start,
            to: period.end
        ).day ?? 30

        let daysInMonth = 30.0
        return (totalSpent / Decimal(daysInPeriod)) * Decimal(daysInMonth)
    }
}

struct CategorySpending {
    let category: String
    let amount: Decimal
    let percentage: Double
    let transactionCount: Int
    let trend: Trend
    let budgetAmount: Decimal?

    var isOverBudget: Bool {
        guard let budget = budgetAmount else { return false }
        return amount > budget
    }

    var budgetUtilization: Double? {
        guard let budget = budgetAmount, budget > 0 else { return nil }
        return (amount / budget).doubleValue * 100
    }
}

struct ItemSpending {
    let item: GroceryItem
    let totalSpent: Decimal
    let quantity: Decimal
    let purchaseCount: Int
    let averagePrice: Decimal
    let priceRange: ClosedRange<Decimal>
}

struct ComparisonMetrics {
    let previousPeriodSpending: Decimal
    let change: Decimal
    let changePercentage: Double
    let trend: Trend

    var isSavings: Bool {
        change < 0
    }
}

enum Trend {
    case increasing
    case decreasing
    case stable

    var icon: String {
        switch self {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "minus"
        }
    }

    var color: String {
        switch self {
        case .increasing: return "red"
        case .decreasing: return "green"
        case .stable: return "gray"
        }
    }
}
```

### Savings Opportunity

Create `Domain/Entities/Analytics/SavingsOpportunity.swift`:

```swift
import Foundation

struct SavingsOpportunity: Identifiable {
    let id: UUID
    let type: OpportunityType
    let title: String
    let description: String
    let potentialSavings: Decimal
    let confidence: Double
    let actionable: Bool
    let relatedItems: [GroceryItem]
    let recommendation: String

    var savingsPerMonth: Decimal {
        potentialSavings * 4 // Assuming weekly
    }
}

enum OpportunityType {
    case priceOptimization
    case wastageReduction
    case bulkBuying
    case brandSwitch
    case seasonalTiming
    case storeComparison
    case substituteItem

    var icon: String {
        switch self {
        case .priceOptimization: return "dollarsign.circle"
        case .wastageReduction: return "trash"
        case .bulkBuying: return "bag.fill"
        case .brandSwitch: return "arrow.left.arrow.right"
        case .seasonalTiming: return "calendar"
        case .storeComparison: return "storefront"
        case .substituteItem: return "arrow.triangle.2.circlepath"
        }
    }

    var color: String {
        switch self {
        case .priceOptimization: return "green"
        case .wastageReduction: return "orange"
        case .bulkBuying: return "blue"
        case .brandSwitch: return "purple"
        case .seasonalTiming: return "cyan"
        case .storeComparison: return "indigo"
        case .substituteItem: return "pink"
        }
    }
}
```

### Waste Analytics

Create `Domain/Entities/Analytics/WasteAnalytics.swift`:

```swift
import Foundation

struct WasteAnalytics {
    let period: DateInterval
    let totalWasted: Decimal
    let itemsWasted: Int
    let wasteByCategory: [String: WasteCategoryData]
    let topWastedItems: [WastedItem]
    let wastePercentage: Double
    let estimatedCost: Decimal
    let comparisonToPrevious: ComparisonMetrics?

    var wasteReductionPotential: Decimal {
        estimatedCost * 0.7 // 70% is typically preventable
    }
}

struct WasteCategoryData {
    let category: String
    let itemsWasted: Int
    let totalQuantity: Decimal
    let estimatedCost: Decimal
    let commonReasons: [WasteReason]
}

struct WastedItem {
    let item: GroceryItem
    let quantityWasted: Decimal
    let estimatedCost: Decimal
    let wasteCount: Int
    let averageDaysToWaste: Int
    let reason: WasteReason
}

enum WasteReason: String, CaseIterable {
    case expired = "Expired"
    case spoiled = "Spoiled"
    case overPurchased = "Bought Too Much"
    case forgotten = "Forgotten"
    case disliked = "Didn't Like"
    case other = "Other"

    var icon: String {
        switch self {
        case .expired: return "clock"
        case .spoiled: return "exclamationmark.triangle"
        case .overPurchased: return "cart.fill.badge.plus"
        case .forgotten: return "questionmark.circle"
        case .disliked: return "hand.thumbsdown"
        case .other: return "ellipsis.circle"
        }
    }
}
```

---

## 📈 Analytics Use Cases

### Get Spending Summary Use Case

Create `Domain/UseCases/Analytics/GetSpendingSummaryUseCase.swift`:

```swift
import Foundation
import Combine

protocol GetSpendingSummaryUseCaseProtocol {
    func execute(for period: DateInterval) -> AnyPublisher<SpendingSummary, Error>
}

class GetSpendingSummaryUseCase: GetSpendingSummaryUseCaseProtocol {
    private let purchaseRepository: PurchaseRepositoryProtocol
    private let groceryItemRepository: GroceryItemRepositoryProtocol
    private let budgetRepository: BudgetRepositoryProtocol

    init(
        purchaseRepository: PurchaseRepositoryProtocol,
        groceryItemRepository: GroceryItemRepositoryProtocol,
        budgetRepository: BudgetRepositoryProtocol
    ) {
        self.purchaseRepository = purchaseRepository
        self.groceryItemRepository = groceryItemRepository
        self.budgetRepository = budgetRepository
    }

    func execute(for period: DateInterval) -> AnyPublisher<SpendingSummary, Error> {
        return purchaseRepository.fetchPurchases(from: period.start, to: period.end)
            .flatMap { [weak self] purchases -> AnyPublisher<SpendingSummary, Error> in
                guard let self = self else {
                    return Fail(error: AnalyticsError.unknown).eraseToAnyPublisher()
                }

                return self.buildSummary(purchases: purchases, period: period)
            }
            .eraseToAnyPublisher()
    }

    private func buildSummary(
        purchases: [Purchase],
        period: DateInterval
    ) -> AnyPublisher<SpendingSummary, Error> {

        // Calculate totals
        let totalSpent = purchases.reduce(Decimal(0)) { $0 + $1.totalCost }
        let transactionCount = purchases.count
        let averageTransactionValue = transactionCount > 0 ?
            totalSpent / Decimal(transactionCount) : 0

        // Group by category
        let byCategory = Dictionary(grouping: purchases) {
            $0.groceryItem.category
        }

        return budgetRepository.fetchActiveBudgets()
            .map { [weak self] budgets -> SpendingSummary in
                guard let self = self else {
                    return self?.createEmptySummary(period: period) ?? SpendingSummary(
                        period: period,
                        totalSpent: 0,
                        transactionCount: 0,
                        averageTransactionValue: 0,
                        spendingByCategory: [:],
                        spendingByStore: [:],
                        topItems: [],
                        dailyAverage: 0,
                        weeklyAverage: 0,
                        comparisonToPrevious: nil
                    )
                }

                let activeBudget = budgets.first
                let categoryBudgets = activeBudget?.categoryBudgets ?? [:]

                // Calculate category spending
                var spendingByCategory: [String: CategorySpending] = [:]
                for (category, categoryPurchases) in byCategory {
                    let amount = categoryPurchases.reduce(Decimal(0)) { $0 + $1.totalCost }
                    let percentage = (amount / totalSpent).doubleValue * 100

                    spendingByCategory[category] = CategorySpending(
                        category: category,
                        amount: amount,
                        percentage: percentage,
                        transactionCount: categoryPurchases.count,
                        trend: self.calculateTrend(for: category, purchases: categoryPurchases),
                        budgetAmount: categoryBudgets[category]
                    )
                }

                // Calculate store spending
                let spendingByStore = self.calculateStoreSpending(purchases: purchases)

                // Calculate top items
                let topItems = self.calculateTopItems(purchases: purchases)

                // Calculate averages
                let days = Calendar.current.dateComponents(
                    [.day],
                    from: period.start,
                    to: period.end
                ).day ?? 1
                let dailyAverage = totalSpent / Decimal(max(1, days))
                let weeklyAverage = dailyAverage * 7

                // Compare to previous period
                let comparison = self.calculateComparison(
                    currentSpending: totalSpent,
                    currentPeriod: period
                )

                return SpendingSummary(
                    period: period,
                    totalSpent: totalSpent,
                    transactionCount: transactionCount,
                    averageTransactionValue: averageTransactionValue,
                    spendingByCategory: spendingByCategory,
                    spendingByStore: spendingByStore,
                    topItems: topItems,
                    dailyAverage: dailyAverage,
                    weeklyAverage: weeklyAverage,
                    comparisonToPrevious: comparison
                )
            }
            .eraseToAnyPublisher()
    }

    private func calculateStoreSpending(purchases: [Purchase]) -> [String: Decimal] {
        var storeSpending: [String: Decimal] = [:]
        for purchase in purchases {
            let store = purchase.storeName ?? "Unknown"
            storeSpending[store, default: 0] += purchase.totalCost
        }
        return storeSpending
    }

    private func calculateTopItems(purchases: [Purchase]) -> [ItemSpending] {
        let grouped = Dictionary(grouping: purchases) { $0.groceryItem.id }

        return grouped.compactMap { itemId, itemPurchases in
            guard let firstPurchase = itemPurchases.first else { return nil }

            let totalSpent = itemPurchases.reduce(Decimal(0)) { $0 + $1.totalCost }
            let totalQuantity = itemPurchases.reduce(Decimal(0)) { $0 + $1.quantity }
            let prices = itemPurchases.map { $0.price }
            let avgPrice = totalSpent / totalQuantity

            return ItemSpending(
                item: firstPurchase.groceryItem,
                totalSpent: totalSpent,
                quantity: totalQuantity,
                purchaseCount: itemPurchases.count,
                averagePrice: avgPrice,
                priceRange: (prices.min() ?? 0)...(prices.max() ?? 0)
            )
        }
        .sorted { $0.totalSpent > $1.totalSpent }
    }

    private func calculateTrend(for category: String, purchases: [Purchase]) -> Trend {
        // Compare first half vs second half of period
        let sorted = purchases.sorted { $0.purchaseDate < $1.purchaseDate }
        let midpoint = sorted.count / 2

        let firstHalf = sorted.prefix(midpoint)
        let secondHalf = sorted.suffix(sorted.count - midpoint)

        let firstTotal = firstHalf.reduce(Decimal(0)) { $0 + $1.totalCost }
        let secondTotal = secondHalf.reduce(Decimal(0)) { $0 + $1.totalCost }

        if secondTotal > firstTotal * 1.1 {
            return .increasing
        } else if secondTotal < firstTotal * 0.9 {
            return .decreasing
        } else {
            return .stable
        }
    }

    private func calculateComparison(
        currentSpending: Decimal,
        currentPeriod: DateInterval
    ) -> ComparisonMetrics? {
        // Would fetch previous period data
        // Simplified for now
        return nil
    }

    private func createEmptySummary(period: DateInterval) -> SpendingSummary {
        SpendingSummary(
            period: period,
            totalSpent: 0,
            transactionCount: 0,
            averageTransactionValue: 0,
            spendingByCategory: [:],
            spendingByStore: [:],
            topItems: [],
            dailyAverage: 0,
            weeklyAverage: 0,
            comparisonToPrevious: nil
        )
    }
}

enum AnalyticsError: Error {
    case unknown
    case insufficientData
}
```

### Detect Savings Opportunities Use Case

Create `Domain/UseCases/Analytics/DetectSavingsOpportunitiesUseCase.swift`:

```swift
import Foundation
import Combine

protocol DetectSavingsOpportunitiesUseCaseProtocol {
    func execute() -> AnyPublisher<[SavingsOpportunity], Error>
}

class DetectSavingsOpportunitiesUseCase: DetectSavingsOpportunitiesUseCaseProtocol {
    private let purchaseRepository: PurchaseRepositoryProtocol
    private let groceryItemRepository: GroceryItemRepositoryProtocol
    private let priceHistoryRepository: PriceHistoryRepositoryProtocol
    private let expirationRepository: ExpirationTrackerRepositoryProtocol
    private let priceOptimizer: PriceOptimizationService

    init(
        purchaseRepository: PurchaseRepositoryProtocol,
        groceryItemRepository: GroceryItemRepositoryProtocol,
        priceHistoryRepository: PriceHistoryRepositoryProtocol,
        expirationRepository: ExpirationTrackerRepositoryProtocol,
        priceOptimizer: PriceOptimizationService
    ) {
        self.purchaseRepository = purchaseRepository
        self.groceryItemRepository = groceryItemRepository
        self.priceHistoryRepository = priceHistoryRepository
        self.expirationRepository = expirationRepository
        self.priceOptimizer = priceOptimizer
    }

    func execute() -> AnyPublisher<[SavingsOpportunity], Error> {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .month, value: -3, to: endDate) ?? endDate

        return purchaseRepository.fetchPurchases(from: startDate, to: endDate)
            .flatMap { [weak self] purchases -> AnyPublisher<[SavingsOpportunity], Error> in
                guard let self = self else {
                    return Fail(error: AnalyticsError.unknown).eraseToAnyPublisher()
                }

                return self.analyzeOpportunities(purchases: purchases)
            }
            .eraseToAnyPublisher()
    }

    private func analyzeOpportunities(purchases: [Purchase])
        -> AnyPublisher<[SavingsOpportunity], Error> {

        var opportunities: [SavingsOpportunity] = []

        // 1. Price Optimization Opportunities
        let priceOpps = detectPriceOptimizationOpportunities(purchases: purchases)
        opportunities.append(contentsOf: priceOpps)

        // 2. Waste Reduction Opportunities
        return expirationRepository.fetchWastedTrackers()
            .map { [weak self] wastedTrackers in
                guard let self = self else { return opportunities }

                let wasteOpps = self.detectWasteReductionOpportunities(
                    wastedTrackers: wastedTrackers
                )
                opportunities.append(contentsOf: wasteOpps)

                // 3. Bulk Buying Opportunities
                let bulkOpps = self.detectBulkBuyingOpportunities(purchases: purchases)
                opportunities.append(contentsOf: bulkOpps)

                // Sort by potential savings
                return opportunities.sorted { $0.potentialSavings > $1.potentialSavings }
            }
            .eraseToAnyPublisher()
    }

    private func detectPriceOptimizationOpportunities(purchases: [Purchase])
        -> [SavingsOpportunity] {

        var opportunities: [SavingsOpportunity] = []

        let groupedByItem = Dictionary(grouping: purchases) { $0.groceryItem.id }

        for (_, itemPurchases) in groupedByItem {
            guard let item = itemPurchases.first?.groceryItem,
                  itemPurchases.count >= 3 else { continue }

            let prices = itemPurchases.map { $0.price }
            let avgPrice = prices.reduce(Decimal(0), +) / Decimal(prices.count)
            let minPrice = prices.min() ?? 0
            let maxPrice = prices.max() ?? 0

            // If there's significant price variation
            if maxPrice > minPrice * 1.2 {
                let potentialSavings = (avgPrice - minPrice) * 4 // Monthly

                let opportunity = SavingsOpportunity(
                    id: UUID(),
                    type: .priceOptimization,
                    title: "Better timing for \(item.name)",
                    description: "Prices vary by \((((maxPrice - minPrice) / avgPrice) * 100).formatted())%. Buy when prices are lower.",
                    potentialSavings: potentialSavings,
                    confidence: 0.8,
                    actionable: true,
                    relatedItems: [item],
                    recommendation: "Track prices and buy when below \(minPrice.formatted(as: "USD"))"
                )

                opportunities.append(opportunity)
            }
        }

        return opportunities
    }

    private func detectWasteReductionOpportunities(wastedTrackers: [ExpirationTracker])
        -> [SavingsOpportunity] {

        var opportunities: [SavingsOpportunity] = []

        let groupedByItem = Dictionary(grouping: wastedTrackers) { $0.groceryItemId }

        for (itemId, trackers) in groupedByItem where trackers.count >= 2 {
            // Frequently wasted item
            let totalWasted = trackers.reduce(Decimal(0)) { $0 + $1.quantity }
            let estimatedCost = totalWasted * 5 // Rough estimate

            let opportunity = SavingsOpportunity(
                id: UUID(),
                type: .wastageReduction,
                title: "Reduce waste",
                description: "This item is frequently wasted. Consider buying smaller quantities.",
                potentialSavings: estimatedCost,
                confidence: 0.85,
                actionable: true,
                relatedItems: [], // Would load item
                recommendation: "Buy 50% less quantity or freeze portions"
            )

            opportunities.append(opportunity)
        }

        return opportunities
    }

    private func detectBulkBuyingOpportunities(purchases: [Purchase])
        -> [SavingsOpportunity] {

        var opportunities: [SavingsOpportunity] = []

        let groupedByItem = Dictionary(grouping: purchases) { $0.groceryItem.id }

        for (_, itemPurchases) in groupedByItem {
            guard let item = itemPurchases.first?.groceryItem,
                  itemPurchases.count >= 4 else { continue }

            // Frequently purchased item - good candidate for bulk buying
            let avgQuantity = itemPurchases.map { $0.quantity }
                .reduce(Decimal(0), +) / Decimal(itemPurchases.count)

            let potentialSavings = avgQuantity * item.averagePrice * 0.15 * 4 // 15% savings

            let opportunity = SavingsOpportunity(
                id: UUID(),
                type: .bulkBuying,
                title: "Buy \(item.name) in bulk",
                description: "Frequently purchased item. Bulk buying could save 10-15%.",
                potentialSavings: potentialSavings,
                confidence: 0.75,
                actionable: true,
                relatedItems: [item],
                recommendation: "Look for larger package sizes or warehouse stores"
            )

            opportunities.append(opportunity)
        }

        return opportunities
    }
}
```

### Get Waste Analytics Use Case

Create `Domain/UseCases/Analytics/GetWasteAnalyticsUseCase.swift`:

```swift
import Foundation
import Combine

protocol GetWasteAnalyticsUseCaseProtocol {
    func execute(for period: DateInterval) -> AnyPublisher<WasteAnalytics, Error>
}

class GetWasteAnalyticsUseCase: GetWasteAnalyticsUseCaseProtocol {
    private let expirationRepository: ExpirationTrackerRepositoryProtocol
    private let groceryItemRepository: GroceryItemRepositoryProtocol

    init(
        expirationRepository: ExpirationTrackerRepositoryProtocol,
        groceryItemRepository: GroceryItemRepositoryProtocol
    ) {
        self.expirationRepository = expirationRepository
        self.groceryItemRepository = groceryItemRepository
    }

    func execute(for period: DateInterval) -> AnyPublisher<WasteAnalytics, Error> {
        return expirationRepository.fetchWastedTrackers(from: period.start, to: period.end)
            .flatMap { [weak self] trackers -> AnyPublisher<WasteAnalytics, Error> in
                guard let self = self else {
                    return Fail(error: AnalyticsError.unknown).eraseToAnyPublisher()
                }

                return self.buildWasteAnalytics(trackers: trackers, period: period)
            }
            .eraseToAnyPublisher()
    }

    private func buildWasteAnalytics(
        trackers: [ExpirationTracker],
        period: DateInterval
    ) -> AnyPublisher<WasteAnalytics, Error> {

        let totalWasted = trackers.reduce(Decimal(0)) { $0 + $1.quantity }
        let itemsWasted = trackers.count

        // Group by category
        let groupedByCategory = Dictionary(grouping: trackers) {
            $0.groceryItem.category
        }

        var wasteByCategory: [String: WasteCategoryData] = [:]
        for (category, categoryTrackers) in groupedByCategory {
            let quantity = categoryTrackers.reduce(Decimal(0)) { $0 + $1.quantity }
            let cost = categoryTrackers.reduce(Decimal(0)) {
                $0 + ($1.quantity * $1.groceryItem.averagePrice)
            }

            wasteByCategory[category] = WasteCategoryData(
                category: category,
                itemsWasted: categoryTrackers.count,
                totalQuantity: quantity,
                estimatedCost: cost,
                commonReasons: [.expired, .spoiled] // Would analyze actual reasons
            )
        }

        // Calculate top wasted items
        let topWasted = calculateTopWastedItems(trackers: trackers)

        let estimatedCost = trackers.reduce(Decimal(0)) {
            $0 + ($1.quantity * $1.groceryItem.averagePrice)
        }

        // Calculate waste percentage (of total purchases)
        let wastePercentage = 0.15 // Would calculate actual

        let analytics = WasteAnalytics(
            period: period,
            totalWasted: totalWasted,
            itemsWasted: itemsWasted,
            wasteByCategory: wasteByCategory,
            topWastedItems: topWasted,
            wastePercentage: wastePercentage,
            estimatedCost: estimatedCost,
            comparisonToPrevious: nil
        )

        return Just(analytics)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    private func calculateTopWastedItems(trackers: [ExpirationTracker]) -> [WastedItem] {
        let grouped = Dictionary(grouping: trackers) { $0.groceryItemId }

        return grouped.compactMap { itemId, itemTrackers in
            guard let firstTracker = itemTrackers.first else { return nil }

            let totalQuantity = itemTrackers.reduce(Decimal(0)) { $0 + $1.quantity }
            let estimatedCost = totalQuantity * firstTracker.groceryItem.averagePrice

            let avgDays = itemTrackers.compactMap { tracker -> Int? in
                Calendar.current.dateComponents(
                    [.day],
                    from: tracker.purchaseDate,
                    to: tracker.wastedAt ?? Date()
                ).day
            }.reduce(0, +) / max(1, itemTrackers.count)

            return WastedItem(
                item: firstTracker.groceryItem,
                quantityWasted: totalQuantity,
                estimatedCost: estimatedCost,
                wasteCount: itemTrackers.count,
                averageDaysToWaste: avgDays,
                reason: .expired // Would determine actual reason
            )
        }
        .sorted { $0.estimatedCost > $1.estimatedCost }
    }
}
```

---

## 📊 Analytics View

Create `Presentation/Screens/Analytics/AnalyticsView.swift`:

```swift
import SwiftUI
import Charts

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var selectedPeriod: AnalyticsPeriod = .month

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Period Selector
                    periodSelector

                    // Overview Cards
                    overviewSection

                    // Spending Trends
                    spendingTrendsSection

                    // Savings Opportunities
                    savingsOpportunitiesSection

                    // Waste Analytics
                    wasteAnalyticsSection

                    // Category Breakdown
                    categoryBreakdownSection
                }
                .padding()
            }
            .navigationTitle("Analytics")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.exportReport()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .task {
                await viewModel.loadAnalytics(for: selectedPeriod)
            }
        }
    }

    private var periodSelector: some View {
        Picker("Period", selection: $selectedPeriod) {
            Text("Week").tag(AnalyticsPeriod.week)
            Text("Month").tag(AnalyticsPeriod.month)
            Text("Quarter").tag(AnalyticsPeriod.quarter)
            Text("Year").tag(AnalyticsPeriod.year)
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedPeriod) { _, newValue in
            Task {
                await viewModel.loadAnalytics(for: newValue)
            }
        }
    }

    private var overviewSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                title: "Total Spent",
                value: viewModel.totalSpent.formatted(as: "USD"),
                trend: viewModel.spendingTrend,
                trendValue: "\(viewModel.spendingChange.formatted())%"
            )

            StatCard(
                title: "Avg Transaction",
                value: viewModel.avgTransaction.formatted(as: "USD"),
                trend: .stable,
                trendValue: nil
            )

            StatCard(
                title: "Savings Found",
                value: viewModel.potentialSavings.formatted(as: "USD"),
                trend: .increasing,
                trendValue: nil
            )

            StatCard(
                title: "Waste Cost",
                value: viewModel.wasteCost.formatted(as: "USD"),
                trend: viewModel.wasteTrend,
                trendValue: "\(viewModel.wasteChange.formatted())%"
            )
        }
    }

    private var savingsOpportunitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Savings Opportunities")
                .font(.headline)

            ForEach(viewModel.savingsOpportunities.prefix(3)) { opportunity in
                SavingsOpportunityCard(opportunity: opportunity)
            }

            if viewModel.savingsOpportunities.count > 3 {
                NavigationLink("View All Opportunities") {
                    AllSavingsOpportunitiesView(opportunities: viewModel.savingsOpportunities)
                }
                .font(.subheadline)
            }
        }
    }

    // Additional sections...
}

enum AnalyticsPeriod {
    case week
    case month
    case quarter
    case year

    var dateInterval: DateInterval {
        let now = Date()
        let calendar = Calendar.current

        let start: Date
        switch self {
        case .week:
            start = calendar.date(byAdding: .day, value: -7, to: now)!
        case .month:
            start = calendar.date(byAdding: .month, value: -1, to: now)!
        case .quarter:
            start = calendar.date(byAdding: .month, value: -3, to: now)!
        case .year:
            start = calendar.date(byAdding: .year, value: -1, to: now)!
        }

        return DateInterval(start: start, end: now)
    }
}
```

---

## ✅ Acceptance Criteria

### Phase 6 Complete When:

- ✅ Spending analytics fully functional
- ✅ Savings opportunities detector working
- ✅ Waste analytics implemented
- ✅ Comparative analytics (period-over-period)
- ✅ Charts displaying correctly
- ✅ Export functionality working
- ✅ Performance optimized for large datasets
- ✅ Unit tests for analytics logic (>80% coverage)

---

## 🚀 Next Steps

Proceed to:
- **[Phase 7: Testing](07-PHASE-7-TESTING.md)** - Comprehensive testing strategy

---

## 📚 Resources

- [Charts Framework](https://developer.apple.com/documentation/charts)
- [Data Aggregation Patterns](https://developer.apple.com/documentation/coredata/nsfetchrequest)
