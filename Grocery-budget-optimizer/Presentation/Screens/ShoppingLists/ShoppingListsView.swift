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

                Text(list.budgetAmount, format: .currency(code: "USD"))
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

// Placeholder view for creating a shopping list
struct CreateShoppingListView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("List Details") {
                    Text("Create Shopping List Form")
                }
            }
            .navigationTitle("New Shopping List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ShoppingListsView()
}
