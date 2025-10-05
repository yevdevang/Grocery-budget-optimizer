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
        print("📱 ShoppingListsViewModel.loadLists() called")
        isLoading = true
        
        do {
            let lists = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[ShoppingList], Error>) in
                var cancellable: AnyCancellable?
                cancellable = shoppingListRepository.fetchAllShoppingLists()
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                break
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                            cancellable?.cancel()
                        },
                        receiveValue: { lists in
                            continuation.resume(returning: lists)
                        }
                    )
            }
            
            self.shoppingLists = lists
            self.isLoading = false
            print("✅ Loaded \(lists.count) shopping lists")
        } catch {
            print("❌ Error loading shopping lists: \(error)")
            self.shoppingLists = []
            self.isLoading = false
        }
    }

    func createSmartList() {
        showingSmartListSheet = true
    }

    func deleteLists(at indexSet: IndexSet, from lists: [ShoppingList]) async {
        for index in indexSet {
            let list = lists[index]
            do {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    var cancellable: AnyCancellable?
                    cancellable = shoppingListRepository.deleteShoppingList(byId: list.id)
                        .receive(on: DispatchQueue.main)
                        .sink(
                            receiveCompletion: { completion in
                                switch completion {
                                case .finished:
                                    break
                                case .failure(let error):
                                    continuation.resume(throwing: error)
                                }
                                cancellable?.cancel()
                            },
                            receiveValue: { _ in
                                continuation.resume(returning: ())
                            }
                        )
                }
                print("✅ Deleted shopping list: \(list.name)")
            } catch {
                print("❌ Error deleting shopping list: \(error)")
            }
        }
        
        // Reload the lists after deletion
        await loadLists()
    }
}
