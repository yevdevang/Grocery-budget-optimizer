# Debug Logging Guide - Shopping List Persistence Issue

## What I Added

I've added comprehensive logging throughout the shopping list flow to diagnose why lists don't persist after app restart.

## Expected Console Output Flow

### When App Starts
```
🎬 ShoppingListsView appeared - loading lists
📱 ShoppingListsViewModel.loadLists() called
🔍 ShoppingListRepository.fetchAllShoppingLists() called
📋 ShoppingListRepository: Fetched X shopping lists from CoreData
  - 'List Name' (ID: xxx, Items: Y, Budget: Z)
```

### When Creating a Smart List
```
🎯 GenerateSmartShoppingListUseCase.execute() called with budget: 111
🚀 ShoppingListRepository.createShoppingList() called for list: 'Smart List - Oct 5, 2024' with X items
🔄 Mapping list 'Smart List - Oct 5, 2024' with X items
  ✓ Linked item to grocery: Item Name 1
  ✓ Linked item to grocery: Item Name 2
  ⚠️ Warning: Grocery item not found for ID: xxx (if any items missing)
✅ ShoppingListRepository: Saved list 'Smart List - Oct 5, 2024' with X items to CoreData
✅ ShoppingListRepository: Verified - list exists in CoreData with ID: xxx-xxx-xxx
```

### After Creating - View Reloads
```
📱 ShoppingListsViewModel.loadLists() called
🔍 ShoppingListRepository.fetchAllShoppingLists() called
📋 ShoppingListRepository: Fetched X shopping lists from CoreData
  - 'Smart List - Oct 5, 2024' (ID: xxx, Items: Y, Budget: 111)
```

### After App Restart (CRITICAL TO CHECK)
```
🎬 ShoppingListsView appeared - loading lists
📱 ShoppingListsViewModel.loadLists() called
🔍 ShoppingListRepository.fetchAllShoppingLists() called
📋 ShoppingListRepository: Fetched X shopping lists from CoreData  <-- Should be > 0
  - 'Smart List - Oct 5, 2024' (ID: xxx, Items: Y, Budget: 111)  <-- Should see your list
```

## How to Test

1. **Build and Run** the app in Xcode
2. **Open Xcode Console** (⌘+Shift+Y)
3. **Clear Console** (🗑️ icon or ⌘+K)
4. **Navigate to Shopping Lists tab**
   - Watch for: `🎬 ShoppingListsView appeared`
   - Watch for: `📋 Fetched X shopping lists` (should be 0 first time)

5. **Create a Smart List** with budget 111
   - Watch for: `🎯 GenerateSmartShoppingListUseCase.execute()`
   - Watch for: `🚀 createShoppingList() called`
   - Watch for: `✅ Saved list` and `✅ Verified`
   - Watch for reload: `📋 Fetched X shopping lists` (should be 1)

6. **Stop the App** (⌘+.)
7. **Clear Console Again**
8. **Restart the App**
9. **Navigate to Shopping Lists tab**
   - **CRITICAL**: Watch for `📋 Fetched X shopping lists`
   - **If X = 0**: CoreData is NOT persisting to disk
   - **If X > 0**: CoreData IS persisting, but view might not be displaying

## Diagnostic Scenarios

### Scenario A: Fetch Returns 0 After Restart
**Problem**: CoreData save is not persisting to disk
**Possible Causes**:
- Using in-memory store instead of SQLite
- Store location is being deleted on app restart
- Container initialization failing

### Scenario B: Fetch Returns > 0 But View Shows Empty
**Problem**: View/ViewModel binding issue
**Possible Causes**:
- @Published property not triggering update
- Computed properties (activeLists/completedLists) filtering incorrectly
- View state not observing ViewModel changes

### Scenario C: No Logging Appears At All
**Problem**: Code is not being executed
**Possible Causes**:
- Build didn't include latest changes (clean build needed)
- Wrong scheme/target selected
- Logging filtered in console

## Console Filtering

Make sure your Xcode console is not filtering out logs:
- Check the filter box at the bottom of console (should be empty or show "All")
- Check the log level buttons (should show all levels)

## Next Steps Based on Results

Please run the test above and share:
1. The console output when creating a list
2. The console output when restarting the app
3. Whether you see the list in the UI after restart

This will tell us exactly where the problem is!
