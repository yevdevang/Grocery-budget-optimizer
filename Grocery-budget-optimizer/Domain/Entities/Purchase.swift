import Foundation

struct Purchase: Identifiable, Codable {
    let id: UUID
    var groceryItemId: UUID
    var groceryItem: GroceryItem
    var quantity: Decimal
    var price: Decimal
    var totalCost: Decimal
    var purchaseDate: Date
    var storeName: String?
    var receiptImage: Data?

    init(
        id: UUID = UUID(),
        groceryItemId: UUID,
        groceryItem: GroceryItem,
        quantity: Decimal,
        price: Decimal,
        totalCost: Decimal,
        purchaseDate: Date = Date(),
        storeName: String? = nil,
        receiptImage: Data? = nil
    ) {
        self.id = id
        self.groceryItemId = groceryItemId
        self.groceryItem = groceryItem
        self.quantity = quantity
        self.price = price
        self.totalCost = totalCost
        self.purchaseDate = purchaseDate
        self.storeName = storeName
        self.receiptImage = receiptImage
    }
}
