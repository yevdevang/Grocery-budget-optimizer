import SwiftUI
import Combine

struct ShoppingListDetailView: View {
    let list: ShoppingList
    @StateObject private var viewModel: ShoppingListDetailViewModel
    @ObservedObject private var currencyManager = CurrencyManager.shared
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
                    ForEach(viewModel.priceRecommendations.prefix(3), id: \.item.id) { recommendation in
                        PriceRecommendationRow(recommendation: recommendation)
                    }
                }
            }

            // Items
            Section("Items") {
                ForEach(viewModel.itemsWithDetails) { itemWithDetails in
                    ShoppingListItemRowWithDetails(
                        itemWithDetails: itemWithDetails,
                        onToggle: { viewModel.toggleItem(itemWithDetails.item) },
                        onPriceEdit: { price in
                            viewModel.updatePrice(for: itemWithDetails.item, price: price)
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
            AddItemToListView(viewModel: viewModel)
        }
        .task {
            await viewModel.loadRecommendations()
        }
    }

    private var budgetSummary: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Budget")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    CurrencyText(value: list.budgetAmount)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .center, spacing: 4) {
                    Text("Spent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    CurrencyText(value: viewModel.totalSpent)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(viewModel.isOverBudget ? .red : .primary)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    CurrencyText(value: viewModel.remaining)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(viewModel.remaining < 0 ? .red : .green)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
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

struct ShoppingListItemRowWithDetails: View {
    let itemWithDetails: ShoppingListItemWithDetails
    let onToggle: () -> Void
    let onPriceEdit: (Decimal) -> Void

    @State private var showingPriceEditor = false

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: itemWithDetails.isPurchased ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(itemWithDetails.isPurchased ? .green : .gray)
                    .font(.title2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(itemWithDetails.groceryItem.name)
                    .strikethrough(itemWithDetails.isPurchased)

                Text("Qty: \(itemWithDetails.quantity, format: .number)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let actualPrice = itemWithDetails.actualPrice {
                    CurrencyText(value: actualPrice)
                        .font(.subheadline)
                        .fontWeight(.medium)
                } else {
                    CurrencyText(value: itemWithDetails.estimatedPrice)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if itemWithDetails.isPurchased {
                    Button("Edit Price") {
                        showingPriceEditor = true
                    }
                    .font(.caption2)
                }
            }
        }
        .sheet(isPresented: $showingPriceEditor) {
            PriceEditorView(currentPrice: itemWithDetails.actualPrice ?? itemWithDetails.estimatedPrice) { newPrice in
                onPriceEdit(newPrice)
            }
        }
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
                Text("Item \(item.groceryItemId.uuidString.prefix(8))")
                    .strikethrough(item.isPurchased)

                Text("Qty: \(item.quantity, format: .number)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let actualPrice = item.actualPrice {
                    CurrencyText(value: actualPrice)
                        .font(.subheadline)
                        .fontWeight(.medium)
                } else {
                    CurrencyText(value: item.estimatedPrice)
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

struct PriceRecommendationRow: View {
    let recommendation: ItemPriceRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recommendation.item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Image(systemName: recommendation.shouldBuyNow ? "checkmark.circle.fill" : "clock.fill")
                    .foregroundStyle(recommendation.shouldBuyNow ? .green : .orange)
            }

            Text(recommendation.recommendation)
                .font(.caption)
                .foregroundStyle(.secondary)

            if recommendation.potentialSavings > 0 {
                HStack(spacing: 4) {
                    Text("Potential savings:")
                    CurrencyText(value: recommendation.potentialSavings)
                }
                .font(.caption)
                .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

// Add Item to List View
struct AddItemToListView: View {
    @ObservedObject var viewModel: ShoppingListDetailViewModel
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var selectedItem: GroceryItem?
    @State private var quantity: String = "1"
    @State private var estimatedPrice: String = ""
    @State private var groceryItems: [GroceryItem] = []
    @State private var cancellables = Set<AnyCancellable>()

    private let groceryItemRepository = DIContainer.shared.groceryItemRepository

    var body: some View {
        NavigationStack {
            Form {
                Section("Search Item") {
                    TextField("Search grocery items...", text: $searchText)
                        .autocorrectionDisabled()

                    if !searchText.isEmpty {
                        ForEach(filteredItems) { item in
                            Button {
                                selectedItem = item
                                estimatedPrice = "\(item.averagePrice)"
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(item.name)
                                            .foregroundStyle(.primary)
                                        Text(item.category)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if selectedItem?.id == item.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                    }
                }

                if let item = selectedItem {
                    Section("Selected Item") {
                        HStack {
                            Text("Item")
                            Spacer()
                            Text(item.name)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Category")
                            Spacer()
                            Text(item.category)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section("Details") {
                        HStack {
                            Text("Quantity")
                            Spacer()
                            TextField("Qty", text: $quantity)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }

                        HStack {
                            Text("Estimated Price")
                            Spacer()
                            HStack(spacing: 4) {
                                Text("$")
                                    .foregroundStyle(.secondary)
                                TextField("0.00", text: $estimatedPrice)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                            }
                        }
                    }
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
                    .disabled(selectedItem == nil || quantity.isEmpty || estimatedPrice.isEmpty)
                }
            }
            .task {
                loadGroceryItems()
            }
        }
    }

    private var filteredItems: [GroceryItem] {
        if searchText.isEmpty {
            return []
        }
        return groceryItems.filter { item in
            item.name.localizedCaseInsensitiveContains(searchText) ||
            item.category.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func loadGroceryItems() {
        groceryItemRepository.fetchAllItems()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { items in
                    self.groceryItems = items
                }
            )
            .store(in: &cancellables)
    }

    private func addItem() {
        guard let item = selectedItem,
              let qty = Decimal(string: quantity),
              let price = Decimal(string: estimatedPrice) else {
            return
        }

        viewModel.addItem(groceryItemId: item.id, quantity: qty, estimatedPrice: price)
        dismiss()
    }
}

struct PriceEditorView: View {
    let currentPrice: Decimal
    let onSave: (Decimal) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var priceText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Price") {
                    TextField("Enter price", text: $priceText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Edit Price")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let price = Decimal(string: priceText) {
                            onSave(price)
                        }
                        dismiss()
                    }
                }
            }
            .onAppear {
                priceText = "\(currentPrice)"
            }
        }
    }
}

#Preview {
    NavigationStack {
        ShoppingListDetailView(list: ShoppingList(
            id: UUID(),
            name: "Weekly Groceries",
            budgetAmount: 150.00,
            items: [],
            createdAt: Date(),
            updatedAt: Date(),
            isCompleted: false,
            completedAt: nil
        ))
    }
}
