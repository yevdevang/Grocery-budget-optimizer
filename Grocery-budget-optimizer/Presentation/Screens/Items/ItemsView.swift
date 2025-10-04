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
                Text(item.name)
                    .font(.headline)

                Text(item.category)
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
            Section("Details") {
                LabeledContent("Name", value: item.name)
                LabeledContent("Category", value: item.category)
                LabeledContent("Average Price", value: item.averagePrice, format: .currency(code: "USD"))
            }

            Section("Price History") {
                Text("Price history chart would go here")
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AddItemView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    Text("Add new item form")
                }
            }
            .navigationTitle("New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ItemsView()
}
