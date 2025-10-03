# Core Data Entities Setup Guide

## Overview
This guide provides step-by-step instructions for adding the required Core Data entities to support Phase 3 features.

## Instructions

### 1. Open Core Data Model in Xcode
1. Open `Grocery-budget-optimizer.xcodeproj` in Xcode
2. Navigate to `Data/CoreData/GroceryBudgetOptimizer.xcdatamodeld`
3. Click to open the visual Core Data editor

---

## Entity Definitions

### Entity 1: BudgetEntity

**Attributes:**
- `id` - UUID (NOT Optional)
- `name` - String (NOT Optional)
- `amount` - Decimal (NOT Optional)
- `startDate` - Date (NOT Optional)
- `endDate` - Date (NOT Optional)
- `isActive` - Boolean (NOT Optional, Default: true)
- `categoryBudgets` - Transformable (Optional, Custom Class: NSDictionary)

**Relationships:** None

**Setup Steps:**
1. Click "Add Entity" button at bottom
2. Rename "Entity" to "BudgetEntity"
3. Add each attribute with the specified type
4. For `categoryBudgets`, set Type to "Transformable", Custom Class to "NSDictionary"

---

### Entity 2: PurchaseEntity

**Attributes:**
- `id` - UUID (NOT Optional)
- `quantity` - Decimal (NOT Optional)
- `price` - Decimal (NOT Optional)
- `totalCost` - Decimal (NOT Optional)
- `purchaseDate` - Date (NOT Optional)
- `storeName` - String (Optional)
- `receiptImage` - Binary Data (Optional, Allows External Storage: YES)

**Relationships:**
- `groceryItem` - To One -> GroceryItemEntity (Delete Rule: Nullify, Inverse: purchases)
- `expirationTracker` - To One -> ExpirationTrackerEntity (Optional, Delete Rule: Nullify)

**Setup Steps:**
1. Add entity named "PurchaseEntity"
2. Add all attributes
3. Add relationships (after creating GroceryItemEntity and ExpirationTrackerEntity)

---

### Entity 3: PriceHistoryEntity

**Attributes:**
- `id` - UUID (NOT Optional)
- `price` - Decimal (NOT Optional)
- `recordedAt` - Date (NOT Optional)
- `storeName` - String (Optional)
- `source` - String (NOT Optional, Default: "manual")

**Relationships:**
- `groceryItem` - To One -> GroceryItemEntity (Delete Rule: Cascade, Inverse: priceHistory)

**Setup Steps:**
1. Add entity named "PriceHistoryEntity"
2. Add all attributes
3. Set default value for `source` to "manual"
4. Add relationship to GroceryItemEntity

---

### Entity 4: ExpirationTrackerEntity

**Attributes:**
- `id` - UUID (NOT Optional)
- `groceryItemId` - UUID (NOT Optional)
- `purchaseId` - UUID (Optional)
- `purchaseDate` - Date (NOT Optional)
- `expirationDate` - Date (NOT Optional)
- `estimatedExpirationDate` - Date (NOT Optional)
- `quantity` - Decimal (NOT Optional)
- `remainingQuantity` - Decimal (NOT Optional)
- `storageLocation` - String (Optional)
- `isConsumed` - Boolean (NOT Optional, Default: false)
- `consumedAt` - Date (Optional)
- `isWasted` - Boolean (NOT Optional, Default: false)
- `wastedAt` - Date (Optional)

**Relationships:**
- `groceryItem` - To One -> GroceryItemEntity (Delete Rule: Cascade, Inverse: expirationTrackers)
- `purchase` - To One -> PurchaseEntity (Optional, Delete Rule: Nullify)

**Setup Steps:**
1. Add entity named "ExpirationTrackerEntity"
2. Add all attributes with correct types and defaults
3. Add relationships

---

### Entity 5: ShoppingListItemEntity

**Attributes:**
- `id` - UUID (NOT Optional)
- `quantity` - Decimal (NOT Optional)
- `estimatedPrice` - Decimal (NOT Optional)
- `isPurchased` - Boolean (NOT Optional, Default: false)
- `purchasedAt` - Date (Optional)
- `actualPrice` - Decimal (Optional)

**Relationships:**
- `shoppingList` - To One -> ShoppingListEntity (Delete Rule: Cascade, Inverse: items)
- `groceryItem` - To One -> GroceryItemEntity (Delete Rule: Nullify, Inverse: shoppingListItems)

**Setup Steps:**
1. Add entity named "ShoppingListItemEntity"
2. Add all attributes
3. Add relationships

---

### Entity 6: Update Existing Entities

#### GroceryItemEntity (if not exists, create it)

**Attributes:**
- `id` - UUID (NOT Optional)
- `name` - String (NOT Optional)
- `categoryName` - String (NOT Optional)
- `brand` - String (Optional)
- `unit` - String (NOT Optional)
- `notes` - String (Optional)
- `imageData` - Binary Data (Optional, Allows External Storage: YES)
- `averagePrice` - Decimal (NOT Optional, Default: 0)
- `createdAt` - Date (NOT Optional)
- `updatedAt` - Date (NOT Optional)

**Relationships:**
- `purchases` - To Many -> PurchaseEntity (Delete Rule: Cascade, Inverse: groceryItem)
- `shoppingListItems` - To Many -> ShoppingListItemEntity (Delete Rule: Cascade, Inverse: groceryItem)
- `expirationTrackers` - To Many -> ExpirationTrackerEntity (Delete Rule: Cascade, Inverse: groceryItem)
- `priceHistory` - To Many -> PriceHistoryEntity (Delete Rule: Cascade, Inverse: groceryItem)

#### ShoppingListEntity (if not exists, create it)

**Attributes:**
- `id` - UUID (NOT Optional)
- `name` - String (NOT Optional)
- `budgetAmount` - Decimal (NOT Optional)
- `createdAt` - Date (NOT Optional)
- `updatedAt` - Date (NOT Optional)
- `isCompleted` - Boolean (NOT Optional, Default: false)
- `completedAt` - Date (Optional)

**Relationships:**
- `items` - To Many -> ShoppingListItemEntity (Delete Rule: Cascade, Inverse: shoppingList)

#### CategoryEntity (if needed)

**Attributes:**
- `id` - UUID (NOT Optional)
- `name` - String (NOT Optional)
- `iconName` - String (NOT Optional)
- `colorHex` - String (NOT Optional)
- `sortOrder` - Integer 16 (NOT Optional, Default: 0)

**Relationships:** None

---

## After Adding All Entities

### 1. Generate NSManagedObject Classes
**IMPORTANT:** Do NOT generate NSManagedObject subclasses. We're using Core Data entities with manual mapping in repositories.

To prevent Xcode from auto-generating classes:
1. Select each entity
2. In Data Model Inspector (right panel), find "Codegen"
3. Set to "Manual/None"

### 2. Verify Relationships
Ensure all relationships have proper inverse relationships set:
- Every "To One" relationship should have a corresponding "To Many" inverse
- Delete rules are set correctly (Cascade for owned children, Nullify for references)

### 3. Build the Project
1. Clean Build Folder: Cmd + Shift + K
2. Build: Cmd + B
3. Fix any remaining compilation errors

---

## Common Issues & Solutions

### Issue: "Cannot find type 'BudgetEntity' in scope"
**Solution:** Make sure you've added all entities in Core Data model and the model file is part of the target.

### Issue: Relationships not working
**Solution:**
- Check inverse relationships are set
- Verify entity names match exactly (case-sensitive)
- Ensure delete rules are appropriate

### Issue: Build fails after adding entities
**Solution:**
1. Clean Build Folder
2. Delete DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData`
3. Rebuild

---

## Migration Considerations

Since this is adding new entities (not modifying existing ones), lightweight migration should work automatically. The `CoreDataStack.swift` is already configured for automatic migrations.

If you need to add sample data or seed the database, create a separate migration script.

---

## Verification Checklist

- [ ] All entities created with correct names
- [ ] All attributes added with correct types
- [ ] All attributes marked Optional/NOT Optional correctly
- [ ] Default values set where specified
- [ ] All relationships added
- [ ] All inverse relationships set
- [ ] Delete rules configured
- [ ] Codegen set to "Manual/None" for all entities
- [ ] Project builds without errors
- [ ] Core Data stack initializes successfully

---

## Next Steps

After completing this setup:
1. Run the app to verify Core Data stack initializes
2. Test creating a Budget through the repository
3. Test creating a Shopping List
4. Verify all CRUD operations work
5. Run unit tests to ensure repositories function correctly

---

## Additional Resources

- [Core Data Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/)
- [Core Data Model Editor Help](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/KeyConcepts.html)
- [Lightweight Migration](https://developer.apple.com/documentation/coredata/using_lightweight_migration)
