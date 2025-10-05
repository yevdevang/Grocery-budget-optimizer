import SwiftUI
import Combine

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
            .navigationTitle(L10n.Lists.title)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            viewModel.createSmartList()
                        } label: {
                            Label(L10n.Lists.smartList, systemImage: "sparkles")
                        }

                        Button {
                            showingCreateSheet = true
                        } label: {
                            Label(L10n.Lists.manualList, systemImage: "plus")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateShoppingListView(onCreated: {
                    Task {
                        await viewModel.loadLists()
                    }
                })
            }
            .sheet(isPresented: $viewModel.showingSmartListSheet) {
                CreateSmartListView(onCreated: {
                    Task {
                        await viewModel.loadLists()
                    }
                })
            }
            .onAppear {
                print("🎬 ShoppingListsView appeared - loading lists")
                Task {
                    await viewModel.loadLists()
                }
            }
        }
    }

    private var listContent: some View {
        List {
            Section(L10n.Lists.active) {
                ForEach(viewModel.activeLists) { list in
                    NavigationLink {
                        ShoppingListDetailView(list: list)
                    } label: {
                        ShoppingListRow(list: list)
                    }
                }
                .onDelete { indexSet in
                    Task {
                        await viewModel.deleteLists(at: indexSet, from: viewModel.activeLists)
                    }
                }
            }

            if !viewModel.completedLists.isEmpty {
                Section(L10n.Lists.completed) {
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

            Text(L10n.Lists.noLists)
                .font(.title2)
                .fontWeight(.semibold)

            Text(L10n.Lists.createMessage)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                viewModel.createSmartList()
            } label: {
                Label(L10n.Lists.createSmartButton, systemImage: "sparkles")
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
    @ObservedObject private var currencyManager = CurrencyManager.shared

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
                Label("\(list.items.count) \(L10n.Lists.items)", systemImage: "list.bullet")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                CurrencyText(value: list.budgetAmount)
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

struct CreateShoppingListView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @State private var listName = ""
    @State private var budgetAmount = ""
    @State private var isLoading = false
    @State private var cancellables = Set<AnyCancellable>()

    let onCreated: (() -> Void)?

    private let repository = DIContainer.shared.shoppingListRepository

    init(onCreated: (() -> Void)? = nil) {
        self.onCreated = onCreated
    }

    private var isFormValid: Bool {
        !listName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !budgetAmount.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("List Details") {
                    TextField("List Name", text: $listName)
                        .textInputAutocapitalization(.words)

                    HStack {
                        Text(currencyManager.currentCurrency.symbol)
                            .foregroundStyle(.secondary)
                        TextField("Budget Amount", text: $budgetAmount)
                            .keyboardType(.decimalPad)
                    }
                }

                Section {
                    Text("You can add items to this list after creating it")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                        createList()
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
        }
    }

    private func createList() {
        guard let budget = Decimal(string: budgetAmount) else { return }
        isLoading = true

        let list = ShoppingList(
            name: listName.trimmingCharacters(in: .whitespaces),
            budgetAmount: budget
        )

        repository.createShoppingList(list)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [self] completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ Error creating list: \(error)")
                    }
                },
                receiveValue: { [self] _ in
                    print("✅ Shopping list created successfully")
                    onCreated?()
                    dismiss()
                }
            )
            .store(in: &cancellables)
    }
}

struct CreateSmartListView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @State private var listName = "Smart Shopping List"
    @State private var budgetAmount = ""
    @State private var isLoading = false
    @State private var cancellables = Set<AnyCancellable>()

    let onCreated: (() -> Void)?

    private let generateSmartList = DIContainer.shared.generateSmartShoppingListUseCase
    private let repository = DIContainer.shared.shoppingListRepository

    init(onCreated: (() -> Void)? = nil) {
        self.onCreated = onCreated
    }

    private var isFormValid: Bool {
        !budgetAmount.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("List Details") {
                    TextField("List Name", text: $listName)
                        .textInputAutocapitalization(.words)

                    HStack {
                        Text(currencyManager.currentCurrency.symbol)
                            .foregroundStyle(.secondary)
                        TextField("Budget Amount", text: $budgetAmount)
                            .keyboardType(.decimalPad)
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.blue)
                            Text("AI-Powered Recommendations")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        Text("Our AI will analyze your purchase history and predict what you need to buy, optimizing for your budget")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if isLoading {
                    Section {
                        HStack {
                            ProgressView()
                            Text(L10n.Lists.generating)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(L10n.Lists.smartTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Lists.generate) {
                        generateList()
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
        }
    }

    private func generateList() {
        guard let budget = Decimal(string: budgetAmount) else { return }
        isLoading = true

        print("🚀 CreateSmartListView: Starting list generation with budget \(budget)")

        // Use default preferences and 7 days prediction
        let preferences: [String: Double] = [:]  // Empty means balanced across all categories
        let days = 7  // Generate list for one week

        generateSmartList.execute(budget: budget, preferences: preferences, days: days)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [self] completion in
                    print("🔄 CreateSmartListView: Received completion: \(completion)")
                    isLoading = false
                    switch completion {
                    case .finished:
                        print("✅ CreateSmartListView: Smart shopping list generated successfully")
                        onCreated?()
                        dismiss()
                    case .failure(let error):
                        print("❌ CreateSmartListView: Error generating smart list: \(error)")
                        print("❌ CreateSmartListView: Error details: \(String(describing: error))")
                        // Still dismiss on error for now
                        dismiss()
                    }
                },
                receiveValue: { list in
                    print("📦 CreateSmartListView: Received list value: \(list.name) with \(list.items.count) items")
                }
            )
            .store(in: &cancellables)
    }
}

#Preview {
    ShoppingListsView()
}
