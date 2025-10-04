import SwiftUI

struct ItemsView: View {
    @StateObject private var viewModel = ItemsViewModel()
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var searchText = ""
    @State private var selectedCategory: String?
    @State private var showingAddItem = false

    var body: some View {
        NavigationStack {
            List {
                // Categories
                Section {
                    categoryPicker
                }

                // Items
                ForEach(viewModel.filteredItems) { item in
                    NavigationLink {
                        ItemDetailView(item: item)
                    } label: {
                        ItemRow(item: item)
                    }
                }
            }
            .searchable(text: $searchText, prompt: L10n.Items.search)
            .onChange(of: searchText) { _, newValue in
                viewModel.search(query: newValue)
            }
            .navigationTitle(L10n.Items.title)
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
                    name: L10n.Items.all,
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                    viewModel.filterByCategory(nil)
                }

                ForEach(viewModel.categories, id: \.self) { category in
                    CategoryChip(
                        name: L10n.Category.localizedName(category),
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                        viewModel.filterByCategory(category)
                    }
                }
            }
            .padding(.vertical, 8)
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
                Text(localizedProductName(item.name))
                    .font(.headline)

                Text(L10n.Category.localizedName(item.category))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(item.averagePrice, format: .currency(code: "USD"))
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

// Placeholder views
struct ItemDetailView: View {
    let item: GroceryItem

    var body: some View {
        List {
            Section(L10n.Items.details) {
                LabeledContent(L10n.Items.name, value: localizedProductName(item.name))
                LabeledContent(L10n.Items.category, value: L10n.Category.localizedName(item.category))
                LabeledContent(L10n.Items.averagePrice, value: item.averagePrice, format: .currency(code: "USD"))
            }

            Section(L10n.Items.priceHistory) {
                Text(L10n.Items.priceHistoryPlaceholder)
            }
        }
        .navigationTitle(localizedProductName(item.name))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AddItemView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.AddItem.details) {
                    Text("Add new item form")
                }
            }
            .navigationTitle(L10n.AddItem.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.add) { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ItemsView()
}
