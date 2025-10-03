import Foundation

struct ExpirationTracker: Identifiable, Codable {
    let id: UUID
    var groceryItemId: UUID
    var purchaseId: UUID?
    var purchaseDate: Date
    var expirationDate: Date
    var estimatedExpirationDate: Date // ML prediction
    var quantity: Decimal
    var remainingQuantity: Decimal
    var storageLocation: String? // "Fridge", "Pantry", "Freezer"
    var isConsumed: Bool
    var consumedAt: Date?
    var isWasted: Bool
    var wastedAt: Date?

    var status: ExpirationStatus {
        if isWasted { return .wasted }
        if isConsumed { return .consumed }

        let daysUntilExpiration = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0

        if daysUntilExpiration < 0 {
            return .expired
        } else if daysUntilExpiration <= 2 {
            return .expiringSoon
        } else {
            return .fresh
        }
    }

    init(
        id: UUID = UUID(),
        groceryItemId: UUID,
        purchaseId: UUID? = nil,
        purchaseDate: Date = Date(),
        expirationDate: Date,
        estimatedExpirationDate: Date,
        quantity: Decimal,
        remainingQuantity: Decimal? = nil,
        storageLocation: String? = nil,
        isConsumed: Bool = false,
        consumedAt: Date? = nil,
        isWasted: Bool = false,
        wastedAt: Date? = nil
    ) {
        self.id = id
        self.groceryItemId = groceryItemId
        self.purchaseId = purchaseId
        self.purchaseDate = purchaseDate
        self.expirationDate = expirationDate
        self.estimatedExpirationDate = estimatedExpirationDate
        self.quantity = quantity
        self.remainingQuantity = remainingQuantity ?? quantity
        self.storageLocation = storageLocation
        self.isConsumed = isConsumed
        self.consumedAt = consumedAt
        self.isWasted = isWasted
        self.wastedAt = wastedAt
    }
}

enum ExpirationStatus: String, Codable {
    case fresh
    case expiringSoon
    case expired
    case consumed
    case wasted
}
