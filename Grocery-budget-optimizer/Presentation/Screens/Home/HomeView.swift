import SwiftUI
import Combine

struct HomeView: View {
    @Binding var selectedTab: Int
    @StateObject private var viewModel = HomeViewModel(
        getBudgetSummary: DIContainer.shared.getBudgetSummaryUseCase,
        getExpiringItems: DIContainer.shared.getExpiringItemsUseCase,
        getPredictions: DIContainer.shared.getPurchasePredictionsUseCase,
        purchaseRepository: DIContainer.shared.purchaseRepository,
        scanProductUseCase: DIContainer.shared.scanProductUseCase
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
            .navigationTitle(L10n.Home.title)
            .navigationBarTitleDisplayMode(.inline)
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
            .sheet(isPresented: $viewModel.showingScanner) {
                BarcodeScannerView(
                    onBarcodeScanned: { barcode in
                        viewModel.handleScannedBarcode(barcode)
                    },
                    onTestProductSelected: { name, barcode in
                        viewModel.handleTestProduct(name: name, barcode: barcode)
                    }
                )
            }
            .sheet(item: $viewModel.scannedProduct) { productInfo in
                ScannedProductDetailView(productInfo: productInfo)
            }
        }
    }

    private var greetingSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.greeting)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(L10n.Home.subtitle)
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
            Text(L10n.Home.quickActions)
                .font(.headline)
                .padding(.horizontal)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(
                    icon: "sparkles",
                    title: L10n.Home.smartList,
                    color: .blue
                ) {
                    viewModel.createSmartList()
                }

                QuickActionButton(
                    icon: "barcode.viewfinder",
                    title: L10n.Home.scanProduct,
                    color: .cyan
                ) {
                    viewModel.showScanner()
                }

                QuickActionButton(
                    icon: "plus.circle",
                    title: L10n.Home.addItem,
                    color: .green
                ) {
                    viewModel.showAddItem()
                }

                QuickActionButton(
                    icon: "dollarsign.circle",
                    title: L10n.Home.addExpense,
                    color: .orange
                ) {
                    viewModel.showAddExpense()
                }

                QuickActionButton(
                    icon: "chart.bar",
                    title: L10n.Home.viewStats,
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
                Text(L10n.Home.expiringItems)
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
                Text(L10n.Home.predictions)
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
            Text(L10n.Home.recentActivity)
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
    @ObservedObject private var currencyManager = CurrencyManager.shared
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
                Section(L10n.SmartList.budget) {
                    HStack {
                        Text(currencyManager.currentCurrency.symbol)
                            .foregroundStyle(.secondary)
                        TextField(L10n.SmartList.enterBudget, text: $budgetAmount)
                            .keyboardType(.decimalPad)
                    }
                }

                Section(L10n.SmartList.duration) {
                    Picker(L10n.SmartList.numberOfDays, selection: $numberOfDays) {
                        Text(L10n.SmartList.threeDays).tag(3)
                        Text(L10n.SmartList.sevenDays).tag(7)
                        Text(L10n.SmartList.fourteenDays).tag(14)
                        Text(L10n.SmartList.thirtyDays).tag(30)
                    }
                    .pickerStyle(.segmented)
                }

                Section(L10n.SmartList.household) {
                    Stepper("\(L10n.SmartList.householdSize): \(householdSize)", value: $householdSize, in: 1...10)
                }

                Section(L10n.SmartList.dietaryPreferences) {
                    Toggle(L10n.SmartList.preferVegetarian, isOn: $preferVegetarian)
                    Toggle(L10n.SmartList.preferOrganic, isOn: $preferOrganic)
                    Toggle(L10n.SmartList.avoidDairy, isOn: $avoidDairy)
                }

                Section {
                    Button(action: generateList) {
                        HStack {
                            Spacer()
                            if isGenerating {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(isGenerating ? L10n.SmartList.generating : L10n.SmartList.generateButton)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(budgetAmount.isEmpty || isGenerating)
                }
            }
            .navigationTitle(L10n.SmartList.createTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                }
            }
            .alert(L10n.SmartList.error, isPresented: $showingError) {
                Button(L10n.Common.ok, role: .cancel) { }
            } message: {
                Text(errorMessage ?? L10n.SmartList.errorMessage)
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
    @ObservedObject private var currencyManager = CurrencyManager.shared
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
                Section(L10n.AddItem.details) {
                    TextField(L10n.AddItem.name, text: $name)

                    Picker(L10n.AddItem.category, selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(L10n.Category.localizedName(category)).tag(category)
                        }
                    }

                    TextField(L10n.AddItem.brand, text: $brand)

                    TextField(L10n.AddItem.unit, text: $unit)
                }

                Section(L10n.AddItem.pricing) {
                    HStack {
                        Text(currencyManager.currentCurrency.symbol)
                            .foregroundStyle(.secondary)
                        TextField(L10n.AddItem.averagePrice, text: $price)
                            .keyboardType(.decimalPad)
                    }
                }

                Section(L10n.AddItem.additionalInfo) {
                    TextField(L10n.AddItem.notes, text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(L10n.AddItem.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.add) {
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
    @ObservedObject private var currencyManager = CurrencyManager.shared
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
                Section(L10n.AddExpense.item) {
                    Button(action: { showingItemPicker = true }) {
                        HStack {
                            Text(L10n.AddExpense.selectItem)
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

                Section(L10n.AddExpense.purchaseDetails) {
                    HStack {
                        Text(L10n.AddExpense.quantity)
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
                        Text(L10n.AddExpense.pricePerUnit)
                        Spacer()
                        Text(currencyManager.currentCurrency.symbol)
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $price)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }

                    HStack {
                        Text(L10n.AddExpense.totalCost)
                            .fontWeight(.medium)
                        Spacer()
                        CurrencyText(value: totalCost)
                            .fontWeight(.semibold)
                    }

                    DatePicker(L10n.AddExpense.purchaseDate, selection: $purchaseDate, displayedComponents: .date)

                    TextField(L10n.AddExpense.storeNameOptional, text: $storeName)
                }
            }
            .navigationTitle(L10n.AddItem.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.save) {
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
                        Text(L10n.ItemPicker.noItems)
                            .font(.headline)
                        Text(L10n.ItemPicker.noItemsMessage)
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
                    .searchable(text: $searchText, prompt: L10n.ItemPicker.search)
                }
            }
            .navigationTitle(L10n.ItemPicker.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedTab = 0
    HomeView(selectedTab: $selectedTab)
}
