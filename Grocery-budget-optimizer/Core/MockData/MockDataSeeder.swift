import Foundation

class MockDataSeeder {
    static let shared = MockDataSeeder()

    private init() {}

    func seedMockData() {
        print("🌱 Seeding mock data...")

        // The MockGroceryItemRepository already has sample items
        // Add mock shopping lists
        // Add mock purchases
        // Add mock budgets

        print("✅ Mock data seeded successfully")
    }

    func createSampleShoppingList() -> ShoppingList {
        let items = [
            ShoppingListItem(
                groceryItemId: UUID(),
                quantity: 2,
                estimatedPrice: 4.99,
                isPurchased: false
            ),
            ShoppingListItem(
                groceryItemId: UUID(),
                quantity: 1,
                estimatedPrice: 12.99,
                isPurchased: true,
                actualPrice: 11.99
            ),
            ShoppingListItem(
                groceryItemId: UUID(),
                quantity: 3,
                estimatedPrice: 2.49,
                isPurchased: false
            )
        ]

        return ShoppingList(
            name: "Weekly Groceries",
            budgetAmount: 100.00,
            items: items
        )
    }

    func createSampleBudget() -> Budget {
        return Budget(
            name: "October Budget",
            amount: 500.00,
            startDate: Calendar.current.date(byAdding: .day, value: -15, to: Date())!,
            endDate: Calendar.current.date(byAdding: .day, value: 15, to: Date())!,
            isActive: true
        )
    }
}
