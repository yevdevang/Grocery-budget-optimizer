import Foundation
import Combine

@MainActor
class ShoppingListsViewModel: ObservableObject {
    @Published var shoppingLists: [ShoppingList] = []
    @Published var isLoading = false
    @Published var showingSmartListSheet = false

    private let shoppingListRepository: ShoppingListRepositoryProtocol
    private let generateSmartList: GenerateSmartShoppingListUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()

    init(
        shoppingListRepository: ShoppingListRepositoryProtocol = DIContainer.shared.shoppingListRepository,
        generateSmartList: GenerateSmartShoppingListUseCaseProtocol = DIContainer.shared.generateSmartShoppingListUseCase
    ) {
        self.shoppingListRepository = shoppingListRepository
        self.generateSmartList = generateSmartList
    }

    var activeLists: [ShoppingList] {
        shoppingLists.filter { !$0.isCompleted }
    }

    var completedLists: [ShoppingList] {
        shoppingLists.filter { $0.isCompleted }
    }

    func loadLists() async {
        isLoading = true
        shoppingListRepository.fetchAllShoppingLists()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] lists in
                    self?.shoppingLists = lists
                    self?.isLoading = false
                }
            )
            .store(in: &cancellables)
    }

    func createSmartList() {
        showingSmartListSheet = true
    }

    func deleteLists(at indexSet: IndexSet, from lists: [ShoppingList]) {
        indexSet.forEach { index in
            let list = lists[index]
            shoppingListRepository.deleteShoppingList(byId: list.id)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { [weak self] _ in
                        self?.shoppingLists.removeAll { $0.id == list.id }
                    }
                )
                .store(in: &cancellables)
        }
    }
}
