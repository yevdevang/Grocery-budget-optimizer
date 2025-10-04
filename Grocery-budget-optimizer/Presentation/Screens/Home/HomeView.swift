import SwiftUI
import Combine

struct HomeView: View {
    @Binding var selectedTab: Int
    @StateObject private var viewModel = HomeViewModel(
        getBudgetSummary: DIContainer.shared.getBudgetSummaryUseCase,
        getExpiringItems: DIContainer.shared.getExpiringItemsUseCase,
        getPredictions: DIContainer.shared.getPurchasePredictionsUseCase,
        purchaseRepository: DIContainer.shared.purchaseRepository
    )

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
                    if !viewModel.recentPurchases.isEmpty {
                        recentActivitySection
                    }
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
            .sheet(isPresented: $viewModel.showingSmartList) {
                SmartListCreationSheet()
            }
            .sheet(isPresented: $viewModel.showingAddItem) {
                QuickAddItemSheet()
            }
            .sheet(isPresented: $viewModel.showingAddExpense) {
                QuickAddExpenseSheet(onSaved: {
                    Task {
                        await viewModel.refresh()
                    }
                })
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
                    selectedTab = 3  // Navigate to Budget tab
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

// MARK: - Placeholder Sheets

struct SmartListCreationSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var budgetAmount = ""
    @State private var numberOfDays = 7
    @State private var householdSize = 1
    @State private var preferVegetarian = false
    @State private var preferOrganic = false
    @State private var avoidDairy = false
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showingError = false

    private let generateUseCase = DIContainer.shared.generateSmartShoppingListUseCase
    private var cancellables = Set<AnyCancellable>()

    var body: some View {
        NavigationStack {
            Form {
                Section("Budget") {
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("Enter budget amount", text: $budgetAmount)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Duration") {
                    Picker("Number of Days", selection: $numberOfDays) {
                        Text("3 days").tag(3)
                        Text("7 days").tag(7)
                        Text("14 days").tag(14)
                        Text("30 days").tag(30)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Household") {
                    Stepper("Household Size: \(householdSize)", value: $householdSize, in: 1...10)
                }

                Section("Dietary Preferences") {
                    Toggle("Prefer Vegetarian", isOn: $preferVegetarian)
                    Toggle("Prefer Organic", isOn: $preferOrganic)
                    Toggle("Avoid Dairy", isOn: $avoidDairy)
                }

                Section {
                    Button(action: generateList) {
                        HStack {
                            Spacer()
                            if isGenerating {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(isGenerating ? "Generating..." : "Generate Smart List")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(budgetAmount.isEmpty || isGenerating)
                }
            }
            .navigationTitle("Create Smart List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An error occurred while generating the list")
            }
        }
    }

    private func generateList() {
        guard let budget = Decimal(string: budgetAmount) else { return }

        isGenerating = true

        // Save household size to UserDefaults for the use case
        UserDefaults.standard.set(householdSize, forKey: "householdSize")

        print("🤖 Generating smart list with:")
        print("  Budget: $\(budget)")
        print("  Days: \(numberOfDays)")
        print("  Household: \(householdSize)")
        print("  Preferences: Vegetarian=\(preferVegetarian), Organic=\(preferOrganic), No Dairy=\(avoidDairy)")

        // Build preferences dictionary
        var preferences: [String: Double] = [:]
        if preferVegetarian {
            preferences["vegetarian"] = 1.0
        }
        if preferOrganic {
            preferences["organic"] = 1.0
        }
        if avoidDairy {
            preferences["noDairy"] = 1.0
        }

        // Call the use case
        var cancellable: AnyCancellable?
        cancellable = generateUseCase.execute(
            budget: budget,
            preferences: preferences,
            days: numberOfDays
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [self] completion in
                isGenerating = false
                if case .failure(let error) = completion {
                    print("❌ Error generating list: \(error)")
                    errorMessage = error.localizedDescription
                    showingError = true
                }
                cancellable?.cancel()
            },
            receiveValue: { [self] shoppingList in
                print("✅ Successfully generated shopping list:")
                print("  Name: \(shoppingList.name)")
                print("  Items: \(shoppingList.items.count)")
                print("  Estimated cost: $\(shoppingList.totalEstimatedCost)")
                dismiss()
            }
        )
    }
}

struct QuickAddItemSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var category = "Produce"
    @State private var brand = ""
    @State private var unit = ""
    @State private var notes = ""
    @State private var price = ""
    @State private var isLoading = false
    @State private var cancellable: AnyCancellable?

    private let categories = ["Produce", "Dairy", "Meat & Seafood", "Pantry", "Beverages", "Frozen", "Bakery", "Other"]
    private let repository = DIContainer.shared.groceryItemRepository

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !unit.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Item name", text: $name)

                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }

                    TextField("Brand (optional)", text: $brand)

                    TextField("Unit (e.g., 1 lb, 12 oz)", text: $unit)
                }

                Section("Pricing") {
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("Average price", text: $price)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Additional Info") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addItem()
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
        }
    }

    private func addItem() {
        isLoading = true

        let priceValue = Decimal(string: price) ?? 0
        let item = GroceryItem(
            name: name.trimmingCharacters(in: .whitespaces),
            category: category,
            brand: brand.isEmpty ? nil : brand.trimmingCharacters(in: .whitespaces),
            unit: unit.trimmingCharacters(in: .whitespaces),
            notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces),
            averagePrice: priceValue
        )

        cancellable = repository.createItem(item)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [self] completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ Error adding item: \(error)")
                    }
                    cancellable?.cancel()
                },
                receiveValue: { [self] _ in
                    print("✅ Item added successfully")
                    dismiss()
                }
            )
    }
}

struct QuickAddExpenseSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedItem: GroceryItem?
    @State private var showingItemPicker = false
    @State private var quantity = ""
    @State private var price = ""
    @State private var storeName = ""
    @State private var purchaseDate = Date()
    @State private var isLoading = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var items: [GroceryItem] = []

    let onSaved: () -> Void

    private let purchaseRepository = DIContainer.shared.purchaseRepository
    private let itemRepository = DIContainer.shared.groceryItemRepository

    private var isFormValid: Bool {
        selectedItem != nil &&
        !quantity.trimmingCharacters(in: .whitespaces).isEmpty &&
        !price.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var totalCost: Decimal {
        let qty = Decimal(string: quantity) ?? 0
        let prc = Decimal(string: price) ?? 0
        return qty * prc
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    Button(action: { showingItemPicker = true }) {
                        HStack {
                            Text("Select Item")
                                .foregroundStyle(selectedItem == nil ? .secondary : .primary)
                            Spacer()
                            if let item = selectedItem {
                                Text(item.name)
                                    .foregroundStyle(.secondary)
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }

                Section("Purchase Details") {
                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("0", text: $quantity)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        if let item = selectedItem {
                            Text(item.unit)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack {
                        Text("Price per unit")
                        Spacer()
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $price)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }

                    HStack {
                        Text("Total Cost")
                            .fontWeight(.medium)
                        Spacer()
                        Text(totalCost, format: .currency(code: "USD"))
                            .fontWeight(.semibold)
                    }

                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)

                    TextField("Store Name (optional)", text: $storeName)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePurchase()
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .sheet(isPresented: $showingItemPicker) {
                ItemPickerSheet(items: items, selectedItem: $selectedItem)
            }
            .onAppear {
                loadItems()
            }
        }
    }

    private func loadItems() {
        itemRepository.fetchAllItems()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Error loading items: \(error)")
                    }
                },
                receiveValue: { [self] fetchedItems in
                    items = fetchedItems
                    print("✅ Loaded \(fetchedItems.count) items")
                }
            )
            .store(in: &cancellables)
    }

    private func savePurchase() {
        guard let item = selectedItem else { return }
        isLoading = true

        let quantityValue = Decimal(string: quantity) ?? 0
        let priceValue = Decimal(string: price) ?? 0
        let totalCostValue = quantityValue * priceValue

        let purchase = Purchase(
            groceryItemId: item.id,
            groceryItem: item,
            quantity: quantityValue,
            price: priceValue,
            totalCost: totalCostValue,
            purchaseDate: purchaseDate,
            storeName: storeName.isEmpty ? nil : storeName.trimmingCharacters(in: .whitespaces)
        )

        purchaseRepository.createPurchase(purchase)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [self] completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ Error saving purchase: \(error)")
                    }
                },
                receiveValue: { [self] _ in
                    print("✅ Purchase saved successfully")
                    onSaved()
                    dismiss()
                }
            )
            .store(in: &cancellables)
    }
}

struct ItemPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    let items: [GroceryItem]
    @Binding var selectedItem: GroceryItem?
    @State private var searchText = ""

    private var filteredItems: [GroceryItem] {
        if searchText.isEmpty {
            return items
        }
        return items.filter { item in
            item.name.localizedCaseInsensitiveContains(searchText) ||
            item.category.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "cube.box")
                            .font(.system(size: 60))
                            .foregroundStyle(.gray)
                        Text("No Items Available")
                            .font(.headline)
                        Text("Please add items first using the 'Add Item' button on the Home screen")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredItems) { item in
                        Button(action: {
                            selectedItem = item
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(item.category)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if selectedItem?.id == item.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search items")
                }
            }
            .navigationTitle("Select Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedTab = 0
    HomeView(selectedTab: $selectedTab)
}
