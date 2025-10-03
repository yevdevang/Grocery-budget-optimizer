# Core Data Entity Relationship Diagram

## Entity Overview

```
┌─────────────────────┐
│   BudgetEntity      │
│─────────────────────│
│ id: UUID           │
│ name: String       │
│ amount: Decimal    │
│ startDate: Date    │
│ endDate: Date      │
│ isActive: Bool     │
│ categoryBudgets    │
└─────────────────────┘

┌──────────────────────────┐
│  GroceryItemEntity      │
│──────────────────────────│
│ id: UUID                │
│ name: String            │
│ categoryName: String    │
│ brand: String?          │
│ unit: String            │
│ notes: String?          │
│ imageData: Data?        │
│ averagePrice: Decimal   │
│ createdAt: Date         │
│ updatedAt: Date         │
└──────────────────────────┘
         │
         │ 1
         ├──────────────────────┐
         │                      │
    many │                 many │
         │                      │
┌────────▼─────────┐   ┌────────▼──────────────┐
│ PurchaseEntity   │   │ PriceHistoryEntity   │
│──────────────────│   │──────────────────────│
│ id: UUID        │   │ id: UUID             │
│ quantity        │   │ price: Decimal       │
│ price           │   │ recordedAt: Date     │
│ totalCost       │   │ storeName: String?   │
│ purchaseDate    │   │ source: String       │
│ storeName       │   └──────────────────────┘
│ receiptImage    │
└─────────┬────────┘
          │
          │ 1 (optional)
          │
┌─────────▼──────────────────┐
│ ExpirationTrackerEntity   │
│────────────────────────────│
│ id: UUID                  │
│ groceryItemId: UUID       │
│ purchaseId: UUID?         │
│ purchaseDate: Date        │
│ expirationDate: Date      │
│ estimatedExpirationDate   │
│ quantity: Decimal         │
│ remainingQuantity         │
│ storageLocation: String?  │
│ isConsumed: Bool          │
│ consumedAt: Date?         │
│ isWasted: Bool            │
│ wastedAt: Date?           │
└────────────────────────────┘

┌──────────────────────────┐
│  ShoppingListEntity     │
│──────────────────────────│
│ id: UUID                │
│ name: String            │
│ budgetAmount: Decimal   │
│ createdAt: Date         │
│ updatedAt: Date         │
│ isCompleted: Bool       │
│ completedAt: Date?      │
└──────────────────────────┘
         │
         │ 1
         │
    many │
         │
┌────────▼──────────────────┐
│ ShoppingListItemEntity   │
│──────────────────────────│
│ id: UUID                 │
│ quantity: Decimal        │
│ estimatedPrice: Decimal  │
│ isPurchased: Bool        │
│ purchasedAt: Date?       │
│ actualPrice: Decimal?    │
└──────────────────────────┘
         │
         │ many
         │
         ▼ 1
   GroceryItemEntity
```

## Relationship Details

### GroceryItemEntity Relationships

1. **purchases** (To Many → PurchaseEntity)
   - Inverse: `groceryItem`
   - Delete Rule: Cascade
   - Purpose: Track all purchases of this item

2. **priceHistory** (To Many → PriceHistoryEntity)
   - Inverse: `groceryItem`
   - Delete Rule: Cascade
   - Purpose: Track price changes over time

3. **expirationTrackers** (To Many → ExpirationTrackerEntity)
   - Inverse: `groceryItem`
   - Delete Rule: Cascade
   - Purpose: Track expiration for purchased items

4. **shoppingListItems** (To Many → ShoppingListItemEntity)
   - Inverse: `groceryItem`
   - Delete Rule: Cascade
   - Purpose: Track which shopping lists include this item

### ShoppingListEntity Relationships

1. **items** (To Many → ShoppingListItemEntity)
   - Inverse: `shoppingList`
   - Delete Rule: Cascade
   - Purpose: All items in this shopping list

### ShoppingListItemEntity Relationships

1. **shoppingList** (To One → ShoppingListEntity)
   - Inverse: `items`
   - Delete Rule: Cascade
   - Purpose: Parent shopping list

2. **groceryItem** (To One → GroceryItemEntity)
   - Inverse: `shoppingListItems`
   - Delete Rule: Nullify
   - Purpose: Reference to the grocery item

### PurchaseEntity Relationships

1. **groceryItem** (To One → GroceryItemEntity)
   - Inverse: `purchases`
   - Delete Rule: Nullify
   - Purpose: The item that was purchased

2. **expirationTracker** (To One → ExpirationTrackerEntity, Optional)
   - Inverse: `purchase`
   - Delete Rule: Nullify
   - Purpose: Link to expiration tracking

### ExpirationTrackerEntity Relationships

1. **groceryItem** (To One → GroceryItemEntity)
   - Inverse: `expirationTrackers`
   - Delete Rule: Cascade
   - Purpose: The item being tracked

2. **purchase** (To One → PurchaseEntity, Optional)
   - Inverse: `expirationTracker`
   - Delete Rule: Nullify
   - Purpose: Optional link to purchase record

### PriceHistoryEntity Relationships

1. **groceryItem** (To One → GroceryItemEntity)
   - Inverse: `priceHistory`
   - Delete Rule: Cascade
   - Purpose: The item this price record belongs to

## Delete Rule Explanations

### Cascade
Used when the child entity should be deleted when the parent is deleted.
- Example: When a GroceryItem is deleted, all its PurchaseEntity records are deleted

### Nullify
Used when the relationship should be set to nil when the related object is deleted.
- Example: When a PurchaseEntity is deleted, the ShoppingListItem's reference is nullified

## Data Flow Examples

### Example 1: Creating a Shopping List
```
1. Create ShoppingListEntity
2. Create ShoppingListItemEntity for each item
3. Link ShoppingListItemEntity to GroceryItemEntity
4. Link ShoppingListItemEntity to ShoppingListEntity
```

### Example 2: Marking Item as Purchased
```
1. Find ShoppingListItemEntity
2. Update isPurchased = true
3. Create PurchaseEntity
4. Link PurchaseEntity to GroceryItemEntity
5. Create PriceHistoryEntity for price tracking
6. Optionally create ExpirationTrackerEntity
```

### Example 3: Budget Tracking
```
1. Fetch active BudgetEntity for date range
2. Fetch all PurchaseEntity in date range
3. Calculate total spent from PurchaseEntity.totalCost
4. Compare with BudgetEntity.amount
```

## Index Recommendations

For optimal query performance, consider adding indexes (compound indexes where applicable):

### GroceryItemEntity
- `name` - for search queries
- `categoryName` - for filtering by category

### PurchaseEntity
- `purchaseDate` - for date range queries
- Compound: (`groceryItem`, `purchaseDate`) - for item history

### ExpirationTrackerEntity
- `expirationDate` - for finding expiring items
- `isConsumed` and `isWasted` - for filtering active items

### ShoppingListEntity
- `isCompleted` - for filtering active lists
- `createdAt` - for sorting

### PriceHistoryEntity
- Compound: (`groceryItem`, `recordedAt`) - for price trends

## Validation Rules

### BudgetEntity
- `amount` > 0
- `startDate` < `endDate`

### PurchaseEntity
- `quantity` > 0
- `price` >= 0
- `totalCost` = `price` × `quantity`

### ExpirationTrackerEntity
- `remainingQuantity` <= `quantity`
- `remainingQuantity` >= 0

### ShoppingListItemEntity
- `quantity` > 0
- `estimatedPrice` >= 0
- If `isPurchased` = true, then `actualPrice` should be set

## Migration Notes

When adding these entities to an existing model:
1. Xcode should handle lightweight migration automatically
2. No data will be lost (only new entities being added)
3. Existing data in other entities remains intact
4. No custom migration code needed
