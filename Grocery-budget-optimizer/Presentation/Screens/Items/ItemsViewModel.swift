import Foundation
import Combine

@MainActor
class ItemsViewModel: ObservableObject {
    @Published var items: [GroceryItem] = []
    @Published var filteredItems: [GroceryItem] = []
    @Published var categories: [String] = []
    @Published var isLoading = false

    private let groceryItemRepository: GroceryItemRepositoryProtocol
    private let searchItems: SearchGroceryItemsUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()

    init(
        groceryItemRepository: GroceryItemRepositoryProtocol = DIContainer.shared.groceryItemRepository,
        searchItems: SearchGroceryItemsUseCaseProtocol = DIContainer.shared.searchGroceryItemsUseCase
    ) {
        self.groceryItemRepository = groceryItemRepository
        self.searchItems = searchItems
    }

    func loadItems() async {
        isLoading = true
        groceryItemRepository.fetchAllItems()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] items in
                    self?.items = items
                    self?.filteredItems = items
                    self?.categories = Array(Set(items.map { $0.category })).sorted()
                    self?.isLoading = false
                }
            )
            .store(in: &cancellables)
    }

    func search(query: String) {
        if query.isEmpty {
            filteredItems = items
        } else {
            searchItems.execute(query: query)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { [weak self] results in
                        self?.filteredItems = results
                    }
                )
                .store(in: &cancellables)
        }
    }

    func filterByCategory(_ category: String?) {
        if let category = category {
            filteredItems = items.filter { $0.category == category }
        } else {
            filteredItems = items
        }
    }
}
