import Foundation

struct PriceHistory: Identifiable, Codable {
    let id: UUID
    var groceryItemId: UUID
    var price: Decimal
    var recordedAt: Date
    var storeName: String?
    var source: String // "manual", "receipt_scan", "purchase"

    init(
        id: UUID = UUID(),
        groceryItemId: UUID,
        price: Decimal,
        recordedAt: Date = Date(),
        storeName: String? = nil,
        source: String = "manual"
    ) {
        self.id = id
        self.groceryItemId = groceryItemId
        self.price = price
        self.recordedAt = recordedAt
        self.storeName = storeName
        self.source = source
    }
}
