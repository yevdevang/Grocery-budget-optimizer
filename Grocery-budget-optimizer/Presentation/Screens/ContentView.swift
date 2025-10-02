//
//  ContentView.swift
//  Grocery-budget-optimizer
//
//  Created by Yevgeny Levin on 02/10/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GroceryItemsViewModel()
    @State private var showingAddItemSheet = false
    @State private var newItemName = ""
    @State private var newItemCategory = "Produce"
    @State private var newItemUnit = "kg"
    @State private var newItemPrice = ""
    
    let categories = ["Produce", "Dairy", "Meat & Seafood", "Bakery", "Frozen", "Pantry", "Beverages", "Snacks", "Personal Care", "Household", "Other"]
    let units = ["kg", "g", "lbs", "oz", "L", "ml", "pieces", "packs", "boxes"]
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                SearchBar(text: $viewModel.searchText)
                    .padding(.horizontal)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading items...")
                    Spacer()
                } else if viewModel.groceryItems.isEmpty {
                    Spacer()
                    VStack {
                        Image(systemName: "cart")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No grocery items yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Tap + to add your first item")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.groceryItems) { item in
                            GroceryItemRow(item: item)
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Grocery Items")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddItemSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddItemSheet) {
                AddItemSheet(
                    itemName: $newItemName,
                    itemCategory: $newItemCategory,
                    itemUnit: $newItemUnit,
                    itemPrice: $newItemPrice,
                    categories: categories,
                    units: units,
                    onSave: addNewItem,
                    onCancel: {
                        showingAddItemSheet = false
                        resetForm()
                    }
                )
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            let item = viewModel.groceryItems[index]
            viewModel.deleteItem(item)
        }
    }
    
    private func addNewItem() {
        guard !newItemName.isEmpty,
              let price = Decimal(string: newItemPrice) else {
            return
        }
        
        viewModel.addItem(
            name: newItemName,
            category: newItemCategory,
            unit: newItemUnit,
            price: price
        )
        
        showingAddItemSheet = false
        resetForm()
    }
    
    private func resetForm() {
        newItemName = ""
        newItemCategory = "Produce"
        newItemUnit = "kg"
        newItemPrice = ""
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search items...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct GroceryItemRow: View {
    let item: GroceryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.displayName)
                    .font(.headline)
                Spacer()
                Text(item.formattedPrice)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text(item.category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
                
                Text(item.unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding(.vertical, 2)
    }
}

struct AddItemSheet: View {
    @Binding var itemName: String
    @Binding var itemCategory: String
    @Binding var itemUnit: String
    @Binding var itemPrice: String
    
    let categories: [String]
    let units: [String]
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Details")) {
                    TextField("Item name", text: $itemName)
                    
                    Picker("Category", selection: $itemCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    
                    Picker("Unit", selection: $itemUnit) {
                        ForEach(units, id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                    
                    TextField("Price", text: $itemPrice)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: onSave)
                        .disabled(itemName.isEmpty || itemPrice.isEmpty)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
