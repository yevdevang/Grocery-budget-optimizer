import Foundation
import Combine
import SwiftUI

// Helper model to display item with its details
struct ShoppingListItemWithDetails: Identifiable {
    let id: UUID
    let item: ShoppingListItem
    let groceryItem: GroceryItem

    var isPurchased: Bool { item.isPurchased }
    var quantity: Decimal { item.quantity }
    var estimatedPrice: Decimal { item.estimatedPrice }
    var actualPrice: Decimal? { item.actualPrice }
}

@MainActor
class ShoppingListDetailViewModel: ObservableObject {
    @Published var items: [ShoppingListItem] = []
    @Published var itemsWithDetails: [ShoppingListItemWithDetails] = []
    @Published var priceRecommendations: [ItemPriceRecommendation] = []
    @Published var totalSpent: Decimal = 0
    @Published var isLoading = false

    let list: ShoppingList
    private let getPriceRecommendations: GetPriceRecommendationsUseCaseProtocol
    private let shoppingListRepository: ShoppingListRepositoryProtocol
    private let groceryItemRepository: GroceryItemRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    init(
        list: ShoppingList,
        getPriceRecommendations: GetPriceRecommendationsUseCaseProtocol = DIContainer.shared.getPriceRecommendationsUseCase,
        shoppingListRepository: ShoppingListRepositoryProtocol = DIContainer.shared.shoppingListRepository,
        groceryItemRepository: GroceryItemRepositoryProtocol = DIContainer.shared.groceryItemRepository
    ) {
        self.list = list
        self.getPriceRecommendations = getPriceRecommendations
        self.shoppingListRepository = shoppingListRepository
        self.groceryItemRepository = groceryItemRepository
        self.items = list.items
        calculateTotalSpent()
        loadItemDetails()
    }

    var remaining: Decimal {
        list.budgetAmount - totalSpent
    }

    var budgetPercentage: Double {
        guard list.budgetAmount > 0 else { return 0 }
        return Double(truncating: (totalSpent / list.budgetAmount) as NSDecimalNumber)
    }

    var isOverBudget: Bool {
        totalSpent > list.budgetAmount
    }

    func loadRecommendations() async {
        isLoading = true
        getPriceRecommendations.execute(for: list.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] recommendations in
                    self?.priceRecommendations = recommendations
                    self?.isLoading = false
                }
            )
            .store(in: &cancellables)
    }

    func toggleItem(_ item: ShoppingListItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isPurchased.toggle()

        // If marking as purchased and no actual price set, use estimated price
        if items[index].isPurchased && items[index].actualPrice == nil {
            items[index].actualPrice = items[index].estimatedPrice
        }

        // Update itemsWithDetails
        if let detailsIndex = itemsWithDetails.firstIndex(where: { $0.id == item.id }) {
            itemsWithDetails[detailsIndex] = ShoppingListItemWithDetails(
                id: items[index].id,
                item: items[index],
                groceryItem: itemsWithDetails[detailsIndex].groceryItem
            )
        }

        calculateTotalSpent()
        // Update in repository
    }

    func updatePrice(for item: ShoppingListItem, price: Decimal) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].actualPrice = price
        calculateTotalSpent()
        // Update in repository
    }

    func deleteItems(at indexSet: IndexSet) {
        items.remove(atOffsets: indexSet)
        calculateTotalSpent()
        // Update in repository
    }

    func addItem(groceryItemId: UUID, quantity: Decimal, estimatedPrice: Decimal) {
        let newItem = ShoppingListItem(
            groceryItemId: groceryItemId,
            quantity: quantity,
            estimatedPrice: estimatedPrice
        )
        items.append(newItem)

        // Fetch the grocery item details and add to itemsWithDetails
        groceryItemRepository.fetchItem(byId: groceryItemId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] groceryItem in
                    guard let self = self, let groceryItem = groceryItem else { return }
                    let itemWithDetails = ShoppingListItemWithDetails(
                        id: newItem.id,
                        item: newItem,
                        groceryItem: groceryItem
                    )
                    self.itemsWithDetails.append(itemWithDetails)
                }
            )
            .store(in: &cancellables)

        calculateTotalSpent()
        // Update in repository
    }

    func completeList() {
        // Mark list as completed
        // Update in repository
    }

    private func calculateTotalSpent() {
        totalSpent = items.reduce(Decimal(0)) { total, item in
            if item.isPurchased, let actualPrice = item.actualPrice {
                return total + (actualPrice * item.quantity)
            }
            return total
        }
    }

    private func loadItemDetails() {
        // Fetch grocery item details for each shopping list item
        let publishers = items.map { item in
            groceryItemRepository.fetchItem(byId: item.groceryItemId)
                .map { groceryItem -> ShoppingListItemWithDetails? in
                    guard let groceryItem = groceryItem else { return nil }
                    return ShoppingListItemWithDetails(
                        id: item.id,
                        item: item,
                        groceryItem: groceryItem
                    )
                }
                .replaceError(with: nil)
        }

        Publishers.MergeMany(publishers)
            .collect()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.itemsWithDetails = items.compactMap { $0 }
            }
            .store(in: &cancellables)
    }
}
