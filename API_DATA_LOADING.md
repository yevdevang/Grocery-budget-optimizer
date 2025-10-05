# API Data Loading Implementation

## Overview
This document describes the implementation of loading grocery items and categories from the Open Food Facts API instead of using hardcoded mock data.

## Changes Made

### 1. New Response Models (`OpenFoodFactsSearchResponse.swift`)
Created new data models to handle search and category queries from the Open Food Facts API:
- `OpenFoodFactsSearchResponse`: Main response structure for search queries
- `SearchProduct`: Product structure within search results
- `OpenFoodFactsCategories`: Helper class for mapping API categories to app categories

### 2. Enhanced OpenFoodFactsService
Extended the `OpenFoodFactsService` with new methods:

#### New Methods:
- `searchProducts(query:page:pageSize:)` - Search for products by text query
- `fetchProductsByCategory(category:page:pageSize:)` - Fetch products from a specific category

#### Helper Methods:
- `mapSearchProductToGroceryItem()` - Converts API products to GroceryItem domain objects
- `formatNutritionalInfoFromSearch()` - Formats nutritional information from search results
- `generateEstimatedPrice()` - Generates realistic price estimates based on category

### 3. Updated GroceryItemRepository
Modified the repository to load data from the API:

#### Modified Methods:
- `seedInitialItemsIfNeeded()` - Now checks if database is empty and triggers API seeding
- `seedInitialItemsFromAPI()` - NEW: Fetches products from multiple categories via API
- `seedFallbackItems()` - NEW: Provides fallback hardcoded data if API fails

#### New Public Methods:
- `refreshItemsFromAPI(category:)` - Manually refresh items from API for a category
- `searchAndSaveProducts(query:saveResults:)` - Search API and optionally save results to database

### 4. Updated Protocol
Enhanced `GroceryItemRepositoryProtocol` with new methods:
- `refreshItemsFromAPI(category:)` - For manual API refreshes
- `searchAndSaveProducts(query:saveResults:)` - For API search functionality

## How It Works

### Initial Seeding
1. On first launch, the repository checks if the database is empty
2. If empty, it calls `seedInitialItemsFromAPI()`
3. The method fetches products from 7 different categories:
   - dairy-products
   - fruits
   - vegetables
   - meats
   - beverages
   - cereals-and-potatoes
   - snacks
4. Each category fetches 10 products (total ~70 products)
5. All products are saved to Core Data
6. If API fails, fallback hardcoded data is used

### Category Mapping
API categories are mapped to app-friendly categories:
- API "dairy-products" → App "Dairy"
- API "fruits", "vegetables" → App "Produce"
- API "meats", "fishes", "seafood" → App "Meat & Seafood"
- API "beverages" → App "Beverages"
- API "frozen" → App "Frozen"
- API "cereals", "bread", "bakery" → App "Bakery"
- Everything else → App "Pantry"

### Price Estimation
Since Open Food Facts doesn't always provide pricing data, the system generates realistic price estimates based on category:
- Dairy: $2.99 - $6.99
- Produce: $1.49 - $4.99
- Meat & Seafood: $5.99 - $14.99
- Beverages: $1.99 - $8.99
- Frozen: $3.99 - $9.99
- Bakery: $2.49 - $5.99
- Pantry: $1.99 - $6.99

## Benefits

1. **Real Product Data**: Uses actual products from Open Food Facts database
2. **Rich Information**: Includes brand names, nutritional info, and product images
3. **Scalable**: Can fetch any number of products from various categories
4. **Fallback Safety**: If API is unavailable, falls back to hardcoded data
5. **Barcode Support**: Products include barcodes for scanning functionality
6. **User Search**: Users can search for specific products and add them to their database

## Usage Examples

### Refresh Items from API
```swift
repository.refreshItemsFromAPI(category: "dairy-products")
    .sink(
        receiveCompletion: { completion in
            if case .failure(let error) = completion {
                print("Error: \(error)")
            }
        },
        receiveValue: { items in
            print("Fetched \(items.count) items")
        }
    )
    .store(in: &cancellables)
```

### Search and Save Products
```swift
repository.searchAndSaveProducts(query: "organic milk", saveResults: true)
    .sink(
        receiveCompletion: { _ in },
        receiveValue: { items in
            print("Found and saved \(items.count) items")
        }
    )
    .store(in: &cancellables)
```

## Future Enhancements

1. **Image Caching**: Download and cache product images from URLs
2. **Price Integration**: Integrate with pricing APIs for real-time prices
3. **User Preferences**: Allow users to choose which categories to load
4. **Pagination**: Implement infinite scroll for large category results
5. **Offline Mode**: Cache API responses for offline access
6. **Product Updates**: Periodic refresh of product information
7. **Localization**: Fetch products based on user's country/region

## Testing

To test the API integration:
1. Delete the app and reinstall (or clear app data)
2. Launch the app
3. Check console logs for API fetch messages
4. Verify products appear in the Items list
5. Try searching for specific products

## Troubleshooting

**If products don't load:**
- Check internet connection
- Verify Open Food Facts API is accessible
- Check console logs for error messages
- Fallback data should still be available

**If duplicate products appear:**
- The repository prevents duplicates by barcode when available
- Manual deduplication may be needed for products without barcodes

## API Documentation

Open Food Facts API Documentation: https://wiki.openfoodfacts.org/API

Example API calls used:
- Product by barcode: `https://world.openfoodfacts.org/api/v2/product/{barcode}.json`
- Search: `https://world.openfoodfacts.org/api/v2/search?search_terms={query}`
- Category: `https://world.openfoodfacts.org/api/v2/search?categories_tags={category}`
