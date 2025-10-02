# Phase 5: UI/UX - SwiftUI Interface & User Experience

## 📋 Overview

Build beautiful, intuitive SwiftUI screens leveraging iOS 17+ features. Create a delightful user experience with smooth animations, clear navigation, and accessible design.

**Duration**: 1.5 weeks
**Dependencies**: Phase 3 (Core Features), Phase 4 (ML Integration)

---

## 🎯 Objectives

- ✅ Create navigation structure with TabView
- ✅ Build Home/Dashboard screen
- ✅ Implement Shopping Lists screens
- ✅ Create Item management screens
- ✅ Build Budget tracking screens
- ✅ Implement Analytics/Insights screen
- ✅ Create Settings screen
- ✅ Add reusable SwiftUI components
- ✅ Implement animations and transitions
- ✅ Ensure accessibility

---

## 🏗️ Navigation Structure

### Main Tab View

Create `Presentation/Navigation/MainTabView.swift`:

```swift
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            ShoppingListsView()
                .tabItem {
                    Label("Lists", systemImage: "cart.fill")
                }
                .tag(1)

            ItemsView()
                .tabItem {
                    Label("Items", systemImage: "cube.box.fill")
                }
                .tag(2)

            BudgetView()
                .tabItem {
                    Label("Budget", systemImage: "chart.pie.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(Color("AccentColor"))
    }
}
```

---

## 🏠 Screen 1: Home/Dashboard

### Home View

Create `Presentation/Screens/Home/HomeView.swift`:

```swift
import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Greeting
                    greetingSection

                    // Quick Actions
                    quickActionsSection

                    // Current Budget Summary
                    if let budgetSummary = viewModel.currentBudget {
                        BudgetSummaryCard(summary: budgetSummary)
                    }

                    // Expiring Soon
                    if !viewModel.expiringItems.isEmpty {
                        expiringSoonSection
                    }

                    // Purchase Predictions
                    if !viewModel.predictedPurchases.isEmpty {
                        predictedPurchasesSection
                    }

                    // Recent Activity
                    recentActivitySection
                }
                .padding()
            }
            .navigationTitle("Grocery Optimizer")
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadData()
            }
        }
    }

    private var greetingSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.greeting)
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Let's optimize your groceries")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "cart.fill")
                .font(.largeTitle)
                .foregroundStyle(.green.gradient)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5)
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(
                    icon: "sparkles",
                    title: "Smart List",
                    color: .blue
                ) {
                    viewModel.createSmartList()
                }

                QuickActionButton(
                    icon: "plus.circle",
                    title: "Add Item",
                    color: .green
                ) {
                    viewModel.showAddItem()
                }

                QuickActionButton(
                    icon: "dollarsign.circle",
                    title: "Add Expense",
                    color: .orange
                ) {
                    viewModel.showAddExpense()
                }

                QuickActionButton(
                    icon: "chart.bar",
                    title: "View Stats",
                    color: .purple
                ) {
                    viewModel.showAnalytics()
                }
            }
        }
    }

    private var expiringSoonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Expiring Soon")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.expiringItems) { item in
                        ExpiringItemCard(item: item)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var predictedPurchasesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(.blue)
                Text("You Might Need")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)

            ForEach(viewModel.predictedPurchases.prefix(3)) { prediction in
                PredictionRow(prediction: prediction)
                    .padding(.horizontal)
            }
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .padding(.horizontal)

            ForEach(viewModel.recentPurchases.prefix(5)) { purchase in
                PurchaseRow(purchase: purchase)
                    .padding(.horizontal)
            }
        }
    }
}
```

### Home ViewModel

Create `Presentation/Screens/Home/HomeViewModel.swift`:

```swift
import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var currentBudget: BudgetSummary?
    @Published var expiringItems: [ExpiringItemInfo] = []
    @Published var predictedPurchases: [ItemPurchasePrediction] = []
    @Published var recentPurchases: [Purchase] = []

    private let getBudgetSummary: GetBudgetSummaryUseCaseProtocol
    private let getExpiringItems: GetExpiringItemsUseCaseProtocol
    private let getPredictions: GetPurchasePredictionsUseCaseProtocol
    private let purchaseRepository: PurchaseRepositoryProtocol

    private var cancellables = Set<AnyCancellable>()

    init(
        getBudgetSummary: GetBudgetSummaryUseCaseProtocol,
        getExpiringItems: GetExpiringItemsUseCaseProtocol,
        getPredictions: GetPurchasePredictionsUseCaseProtocol,
        purchaseRepository: PurchaseRepositoryProtocol
    ) {
        self.getBudgetSummary = getBudgetSummary
        self.getExpiringItems = getExpiringItems
        self.getPredictions = getPredictions
        self.purchaseRepository = purchaseRepository
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }

    func loadData() async {
        await loadBudgetSummary()
        await loadExpiringItems()
        await loadPredictions()
        await loadRecentPurchases()
    }

    func refresh() async {
        await loadData()
    }

    private func loadBudgetSummary() async {
        // Load active budget
        // ...
    }

    private func loadExpiringItems() async {
        getExpiringItems.execute(daysThreshold: 7)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] items in
                    self?.expiringItems = items
                }
            )
            .store(in: &cancellables)
    }

    private func loadPredictions() async {
        getPredictions.execute()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] predictions in
                    self?.predictedPurchases = predictions
                }
            )
            .store(in: &cancellables)
    }

    private func loadRecentPurchases() async {
        // Load recent purchases
        // ...
    }

    func createSmartList() {
        // Navigate to smart list creation
    }

    func showAddItem() {
        // Show add item sheet
    }

    func showAddExpense() {
        // Show add expense sheet
    }

    func showAnalytics() {
        // Navigate to analytics
    }
}
```

---

## 🛒 Screen 2: Shopping Lists

### Shopping Lists View

Create `Presentation/Screens/ShoppingLists/ShoppingListsView.swift`:

```swift
import SwiftUI

struct ShoppingListsView: View {
    @StateObject private var viewModel = ShoppingListsViewModel()
    @State private var showingCreateSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.shoppingLists.isEmpty {
                    emptyStateView
                } else {
                    listContent
                }
            }
            .navigationTitle("Shopping Lists")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            viewModel.createSmartList()
                        } label: {
                            Label("Smart List (AI)", systemImage: "sparkles")
                        }

                        Button {
                            showingCreateSheet = true
                        } label: {
                            Label("Manual List", systemImage: "plus")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateShoppingListView()
            }
            .task {
                await viewModel.loadLists()
            }
        }
    }

    private var listContent: some View {
        List {
            Section("Active Lists") {
                ForEach(viewModel.activeLists) { list in
                    NavigationLink {
                        ShoppingListDetailView(list: list)
                    } label: {
                        ShoppingListRow(list: list)
                    }
                }
                .onDelete { indexSet in
                    viewModel.deleteLists(at: indexSet, from: viewModel.activeLists)
                }
            }

            if !viewModel.completedLists.isEmpty {
                Section("Completed") {
                    ForEach(viewModel.completedLists) { list in
                        NavigationLink {
                            ShoppingListDetailView(list: list)
                        } label: {
                            ShoppingListRow(list: list)
                        }
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart")
                .font(.system(size: 80))
                .foregroundStyle(.gray.gradient)

            Text("No Shopping Lists")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create a smart list powered by AI or start from scratch")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                viewModel.createSmartList()
            } label: {
                Label("Create Smart List", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.blue.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }
}

struct ShoppingListRow: View {
    let list: ShoppingList

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(list.name)
                    .font(.headline)

                Spacer()

                if list.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            HStack {
                Label("\(list.items.count) items", systemImage: "list.bullet")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(list.budgetAmount.formatted(as: "USD"))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            // Progress bar
            ProgressView(value: list.completionPercentage)
                .tint(list.completionPercentage == 1.0 ? .green : .blue)
        }
        .padding(.vertical, 4)
    }
}
```

### Shopping List Detail View

Create `Presentation/Screens/ShoppingLists/ShoppingListDetailView.swift`:

```swift
import SwiftUI

struct ShoppingListDetailView: View {
    let list: ShoppingList
    @StateObject private var viewModel: ShoppingListDetailViewModel
    @State private var showingAddItem = false

    init(list: ShoppingList) {
        self.list = list
        _viewModel = StateObject(wrappedValue: ShoppingListDetailViewModel(list: list))
    }

    var body: some View {
        List {
            // Budget Section
            Section {
                budgetSummary
            }

            // Price Recommendations
            if !viewModel.priceRecommendations.isEmpty {
                Section("Price Insights") {
                    ForEach(viewModel.priceRecommendations.prefix(3)) { recommendation in
                        PriceRecommendationRow(recommendation: recommendation)
                    }
                }
            }

            // Items
            Section("Items") {
                ForEach(viewModel.items) { item in
                    ShoppingListItemRow(
                        item: item,
                        onToggle: { viewModel.toggleItem(item) },
                        onPriceEdit: { price in
                            viewModel.updatePrice(for: item, price: price)
                        }
                    )
                }
                .onDelete { indexSet in
                    viewModel.deleteItems(at: indexSet)
                }
            }
        }
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddItem = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                Button {
                    viewModel.completeList()
                } label: {
                    Label("Complete", systemImage: "checkmark.circle")
                }
                .disabled(list.isCompleted)
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddItemToListView(listId: list.id)
        }
        .task {
            await viewModel.loadRecommendations()
        }
    }

    private var budgetSummary: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Budget")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(list.budgetAmount.formatted(as: "USD"))
                        .font(.title3)
                        .fontWeight(.bold)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Spent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.totalSpent.formatted(as: "USD"))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(viewModel.isOverBudget ? .red : .primary)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.remaining.formatted(as: "USD"))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(viewModel.remaining < 0 ? .red : .green)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .clipShape(Capsule())

                    Rectangle()
                        .fill(viewModel.isOverBudget ? Color.red.gradient : Color.green.gradient)
                        .frame(
                            width: min(
                                geometry.size.width * CGFloat(viewModel.budgetPercentage),
                                geometry.size.width
                            ),
                            height: 8
                        )
                        .clipShape(Capsule())
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ShoppingListItemRow: View {
    let item: ShoppingListItem
    let onToggle: () -> Void
    let onPriceEdit: (Decimal) -> Void

    @State private var showingPriceEditor = false

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isPurchased ? .green : .gray)
                    .font(.title2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.groceryItemId.uuidString) // Would show item name
                    .strikethrough(item.isPurchased)

                Text("Qty: \(item.quantity.formatted())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let actualPrice = item.actualPrice {
                    Text(actualPrice.formatted(as: "USD"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                } else {
                    Text(item.estimatedPrice.formatted(as: "USD"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if item.isPurchased {
                    Button("Edit Price") {
                        showingPriceEditor = true
                    }
                    .font(.caption2)
                }
            }
        }
        .sheet(isPresented: $showingPriceEditor) {
            PriceEditorView(currentPrice: item.actualPrice ?? item.estimatedPrice) { newPrice in
                onPriceEdit(newPrice)
            }
        }
    }
}
```

---

## 📦 Screen 3: Items Catalog

### Items View

Create `Presentation/Screens/Items/ItemsView.swift`:

```swift
import SwiftUI

struct ItemsView: View {
    @StateObject private var viewModel = ItemsViewModel()
    @State private var searchText = ""
    @State private var selectedCategory: String?
    @State private var showingAddItem = false

    var body: some View {
        NavigationStack {
            List {
                // Categories
                categoryPicker

                // Items
                ForEach(viewModel.filteredItems) { item in
                    NavigationLink {
                        ItemDetailView(item: item)
                    } label: {
                        ItemRow(item: item)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search items")
            .onChange(of: searchText) { _, newValue in
                viewModel.search(query: newValue)
            }
            .navigationTitle("Items")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddItem = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemView()
            }
            .task {
                await viewModel.loadItems()
            }
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryChip(
                    name: "All",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                    viewModel.filterByCategory(nil)
                }

                ForEach(viewModel.categories, id: \.self) { category in
                    CategoryChip(
                        name: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                        viewModel.filterByCategory(category)
                    }
                }
            }
            .padding()
        }
    }
}

struct ItemRow: View {
    let item: GroceryItem

    var body: some View {
        HStack {
            // Image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "cube.box")
                        .foregroundStyle(.gray)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)

                Text(item.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(item.averagePrice.formatted(as: "USD"))
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct CategoryChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}
```

---

## 💰 Screen 4: Budget View

Create `Presentation/Screens/Budget/BudgetView.swift`:

```swift
import SwiftUI
import Charts

struct BudgetView: View {
    @StateObject private var viewModel = BudgetViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let summary = viewModel.currentBudgetSummary {
                        // Budget Overview Card
                        budgetOverviewCard(summary: summary)

                        // Spending by Category Chart
                        spendingByCategoryChart(summary: summary)

                        // Daily Spending Trend
                        dailySpendingChart

                        // Category Breakdown List
                        categoryBreakdownList(summary: summary)
                    } else {
                        emptyStateView
                    }
                }
                .padding()
            }
            .navigationTitle("Budget")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showCreateBudget()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .task {
                await viewModel.loadBudget()
            }
        }
    }

    private func budgetOverviewCard(summary: BudgetSummary) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text(summary.budget.name)
                        .font(.headline)
                    Text("\(summary.budget.startDate.formatted()) - \(summary.budget.endDate.formatted())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack(spacing: 30) {
                budgetStatItem(
                    title: "Budget",
                    value: summary.budget.amount.formatted(as: "USD"),
                    color: .blue
                )

                budgetStatItem(
                    title: "Spent",
                    value: summary.totalSpent.formatted(as: "USD"),
                    color: .orange
                )

                budgetStatItem(
                    title: "Remaining",
                    value: summary.remainingAmount.formatted(as: "USD"),
                    color: summary.remainingAmount > 0 ? .green : .red
                )
            }

            // Progress
            VStack(spacing: 8) {
                HStack {
                    Text("\(Int(summary.percentageUsed))% Used")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text("\(summary.daysRemaining) days left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: summary.percentageUsed / 100)
                    .tint(summary.isOnTrack ? .green : .red)
            }

            if !summary.isOnTrack {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Projected to exceed budget by \((summary.projectedTotal - summary.budget.amount).formatted(as: "USD"))")
                        .font(.subheadline)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func budgetStatItem(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(color)
        }
    }

    private func spendingByCategoryChart(summary: BudgetSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending by Category")
                .font(.headline)

            Chart {
                ForEach(Array(summary.spendingByCategory.sorted(by: { $0.value > $1.value })), id: \.key) { category, amount in
                    SectorMark(
                        angle: .value("Amount", amount.doubleValue),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Category", category))
                }
            }
            .frame(height: 250)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var dailySpendingChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Spending")
                .font(.headline)

            Chart(viewModel.dailySpending) { data in
                LineMark(
                    x: .value("Date", data.date),
                    y: .value("Amount", data.amount.doubleValue)
                )
                .foregroundStyle(.blue.gradient)

                AreaMark(
                    x: .value("Date", data.date),
                    y: .value("Amount", data.amount.doubleValue)
                )
                .foregroundStyle(.blue.opacity(0.1).gradient)
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func categoryBreakdownList(summary: BudgetSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Breakdown")
                .font(.headline)

            ForEach(Array(summary.spendingByCategory.sorted(by: { $0.value > $1.value })), id: \.key) { category, amount in
                HStack {
                    Text(category)
                        .font(.subheadline)

                    Spacer()

                    Text(amount.formatted(as: "USD"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.pie")
                .font(.system(size: 80))
                .foregroundStyle(.gray.gradient)

            Text("No Active Budget")
                .font(.title2)
                .fontWeight(.semibold)

            Button("Create Budget") {
                viewModel.showCreateBudget()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
```

---

## 🎨 Reusable Components

Create `Presentation/Components/QuickActionButton.swift`:

```swift
import SwiftUI

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundStyle(color.gradient)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
```

---

## ✅ Acceptance Criteria

### Phase 5 Complete When:

- ✅ All 5 main screens implemented
- ✅ Navigation working smoothly
- ✅ ViewModels with Combine integration
- ✅ Charts displaying correctly
- ✅ Responsive layouts (all device sizes)
- ✅ Dark mode support
- ✅ Accessibility labels and hints
- ✅ Smooth animations and transitions
- ✅ Empty states for all screens
- ✅ Loading and error states handled

---

## 🚀 Next Steps

Proceed to:
- **[Phase 6: Analytics](06-PHASE-6-ANALYTICS.md)** - Build insights and reporting features

---

## 📚 Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Charts Framework](https://developer.apple.com/documentation/charts)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
