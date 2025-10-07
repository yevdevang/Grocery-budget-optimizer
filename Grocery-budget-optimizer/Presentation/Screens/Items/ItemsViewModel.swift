import Foundation
import Combine

@MainActor
class ItemsViewModel: ObservableObject {
    @Published var items: [GroceryItem] = []
    @Published var filteredItems: [GroceryItem] = []
    @Published var categories: [String] = []
    @Published var isLoading = false

    private let groceryItemRepository: GroceryItemRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    init(
        groceryItemRepository: GroceryItemRepositoryProtocol? = nil
    ) {
        self.groceryItemRepository = groceryItemRepository ?? DIContainer.shared.groceryItemRepository
    }

    func loadItems() async {
        isLoading = true
        
        do {
            print("🚀 Starting to load items - will refresh from Rami Levy API first")
            
            // First, refresh items from Rami Levy API and wait for completion
            let freshItems = try await groceryItemRepository.refreshItemsFromAPI(category: nil)
                .values.first(where: { _ in true }) ?? []
            
            print("📱 Received \(freshItems.count) items from API refresh")
            
            // Then load items from local storage to make sure we have the latest
            let items = try await groceryItemRepository.fetchAllItems()
                .values.first(where: { _ in true }) ?? []
            
            print("💾 Loaded \(items.count) items from local storage")
            
            // Sort items by creation date, newest first
            let sortedItems = items.sorted { $0.createdAt > $1.createdAt }
            self.items = sortedItems
            self.filteredItems = sortedItems
            self.categories = Array(Set(items.map { $0.category })).sorted()
            self.isLoading = false
            
            print("✅ Items view updated with \(sortedItems.count) items")
        } catch {
            print("❌ Failed to load items: \(error)")
            // Fall back to loading whatever is in local storage
            groceryItemRepository.fetchAllItems()
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { [weak self] items in
                        let sortedItems = items.sorted { $0.createdAt > $1.createdAt }
                        self?.items = sortedItems
                        self?.filteredItems = sortedItems
                        self?.categories = Array(Set(items.map { $0.category })).sorted()
                        self?.isLoading = false
                    }
                )
                .store(in: &cancellables)
        }
    }

    func search(query: String) {
        if query.isEmpty {
            filteredItems = items
        } else {
            // Search using the repository which now includes Rami Levy API
            groceryItemRepository.searchItems(query: query)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { [weak self] results in
                        // Sort search results by creation date, newest first
                        self?.filteredItems = results.sorted { $0.createdAt > $1.createdAt }
                    }
                )
                .store(in: &cancellables)
        }
    }

    func filterByCategory(_ category: String?) {
        if let category = category {
            // Filter and sort by creation date, newest first
            filteredItems = items.filter { $0.category == category }.sorted { $0.createdAt > $1.createdAt }
        } else {
            filteredItems = items
        }
    }

    func deleteItems(at indexSet: IndexSet) {
        for index in indexSet {
            let item = filteredItems[index]
            groceryItemRepository.deleteItem(byId: item.id)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("❌ Error deleting item: \(error)")
                        }
                    },
                    receiveValue: { [weak self] _ in
                        Task {
                            await self?.loadItems()
                        }
                    }
                )
                .store(in: &cancellables)
        }
    }

    func forceRefreshFromAPI() async {
        isLoading = true
        
        // Clear existing data and fetch fresh from API
        groceryItemRepository.clearAllData()
        
        do {
            // Fetch fresh data from Rami Levy API
            _ = try await groceryItemRepository.refreshItemsFromAPI(category: nil)
                .values.first(where: { _ in true })
            
            // Load the fresh data from local storage
            let items = try await groceryItemRepository.fetchAllItems()
                .values.first(where: { _ in true }) ?? []
            
            // Sort items by creation date, newest first
            let sortedItems = items.sorted { $0.createdAt > $1.createdAt }
            self.items = sortedItems
            self.filteredItems = sortedItems
            self.categories = Array(Set(items.map { $0.category })).sorted()
            self.isLoading = false
        } catch {
            print("❌ Failed to force refresh from API: \(error)")
            self.isLoading = false
        }
    }

    func deleteAllItems() async {
        // Delete all items one by one
        for item in items {
            groceryItemRepository.deleteItem(byId: item.id)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("❌ Error deleting item: \(error)")
                        }
                    },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
        }
        // Reload items after deletion
        await loadItems()
    }
}
