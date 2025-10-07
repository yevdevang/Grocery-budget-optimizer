# Open Prices API Integration Guide

## Overview
This document describes the integration of the Open Prices API (Open Food Facts' price crowdsourcing project) into the Grocery Budget Optimizer app.

## What is Open Prices?
Open Prices is a separate crowdsourced database maintained by Open Food Facts that collects real-world food prices from users around the world. Users contribute prices by uploading photos of price tags or receipts.

- Website: https://prices.openfoodfacts.org/
- API Docs: https://prices.openfoodfacts.org/api/docs
- API Base URL: https://prices.openfoodfacts.org/api/v1

## Implementation Summary

### New Files Created

1. **OpenPricesResponse.swift** (`Data/Network/Models/`)
   - Defines the response models for the Open Prices API
   - `OpenPricesResponse`: Main response structure with array of price items
   - `PriceItem`: Individual price entry with product, location, and proof
   - `ProductPriceStats`: Calculated statistics (average, min, max prices)

2. **OpenPricesService.swift** (`Data/Network/`)
   - Service class to interact with the Open Prices API
   - `fetchPrices(barcode:)`: Get all prices for a product by barcode
   - `fetchPricesByLocation(barcode:countryCode:)`: Get prices filtered by country
   - Includes 1-hour caching to reduce API calls
   - Handles errors gracefully, returning nil when prices aren't available

### Updated Files

1. **OpenFoodFactsService.swift**
   - Added `OpenPricesService` as a dependency
   - New method: `fetchProductPrice(barcode:)` - Fetch real price or nil
   - New method: `fetchPriceWithFallback(barcode:category:)` - Real price or estimated fallback
   - Keeps existing `generateEstimatedPrice(for:)` as fallback

## How It Works

### Price Fetching Flow

```
1. User scans/searches for a product
   ↓
2. OpenFoodFactsService fetches product data (name, brand, nutrients, etc.)
   ↓
3. If barcode exists, OpenPricesService.fetchPrices(barcode) is called
   ↓
4a. Real prices found → Calculate average price from crowdsourced data
    - Returns ProductPriceStats with average, min, max prices
    - Price is cached for 1 hour
   ↓
4b. No real prices → Falls back to estimated price by category
    - Uses existing generateEstimatedPrice(for:) method
```

### API Response Example

```json
{
  "items": [
    {
      "id": 2207,
      "price": 3.21,
      "price_is_discounted": false,
      "currency": "EUR",
      "date": "2024-01-11",
      "product": {
        "code": "3017620422003",
        "product_name": "Nutella",
        "brands": "Ferrero"
      },
      "location": {
        "osm_name": "Carrefour Villeurbanne",
        "osm_address_country_code": "FR"
      }
    }
  ]
}
```

### Price Statistics Calculation

When multiple prices exist for a product:
- **Average Price**: Mean of all reported prices
- **Min Price**: Lowest price found
- **Max Price**: Highest price found
- **Currency**: Most common currency (usually from first item)
- **Location**: Country code of most recent price

## Installation Steps

### Step 1: Add Files to Xcode Project

1. Open Xcode
2. Right-click on `Data/Network/Models/` folder
3. Select "Add Files to Grocery-budget-optimizer..."
4. Navigate to and select: `OpenPricesResponse.swift`
5. Ensure "Copy items if needed" is **unchecked** (file is already in folder)
6. Ensure "Grocery-budget-optimizer" target is **checked**
7. Click "Add"

8. Right-click on `Data/Network/` folder
9. Select "Add Files to Grocery-budget-optimizer..."
10. Navigate to and select: `OpenPricesService.swift`
11. Ensure "Copy items if needed" is **unchecked**
12. Ensure "Grocery-budget-optimizer" target is **checked**
13. Click "Add"

### Step 2: Build the Project

```bash
cd /Users/yevgenylevin/Documents/Develop/iOS/Grocery-budget-optimizer
xcodebuild -project Grocery-budget-optimizer.xcodeproj \
  -scheme Grocery-budget-optimizer \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  clean build
```

Or in Xcode: **Product → Build** (⌘B)

### Step 3: Verify Integration

Check the console logs when scanning or searching for products:
- `💰 Fetching prices from Open Prices API: [barcode]` - Price fetch started
- `✅ Found X prices for [barcode]` - Real prices retrieved
- `⚠️ No prices found for barcode: [barcode]` - Falling back to estimates

## Usage Examples

### Example 1: Fetch Price for Scanned Product

```swift
let service = OpenFoodFactsService()

// Fetch product with price
service.fetchProduct(barcode: "3017620422003")
    .flatMap { productInfo in
        // Then fetch real price
        service.fetchProductPrice(barcode: productInfo.barcode)
    }
    .sink(
        receiveCompletion: { completion in
            if case .failure(let error) = completion {
                print("Error: \(error)")
            }
        },
        receiveValue: { price in
            if let avgPrice = price {
                print("Real average price: $\(avgPrice)")
            } else {
                print("No real price available, using estimate")
            }
        }
    )
```

### Example 2: Fetch Price with Fallback

```swift
let service = OpenFoodFactsService()

service.fetchPriceWithFallback(barcode: "3017620422003", category: "Pantry")
    .sink(
        receiveCompletion: { _ in },
        receiveValue: { price in
            print("Price (real or estimated): $\(price)")
        }
    )
```

### Example 3: Direct Price Service Usage

```swift
let pricesService = OpenPricesService()

pricesService.fetchPrices(barcode: "3017620422003")
    .sink(
        receiveCompletion: { _ in },
        receiveValue: { stats in
            if let stats = stats {
                print("Average: \(stats.currency) \(stats.averagePrice)")
                print("Range: \(stats.minPrice) - \(stats.maxPrice)")
                print("Based on \(stats.priceCount) price reports")
                print("Country: \(stats.locationCountry ?? "N/A")")
            }
        }
    )
```

## Benefits

### ✅ Advantages of Real Prices
1. **Accuracy**: Real crowdsourced prices from actual stores
2. **Location-aware**: Can filter by country/region
3. **Historical data**: Track price changes over time
4. **Community-driven**: Prices improve as more users contribute
5. **Verified**: Requires proof (photo) for each price entry

### ⚠️ Limitations
1. **Coverage**: Not all products have price data
2. **Geographic bias**: More data from some countries than others
3. **Currency conversion**: Prices are in original currency (EUR, USD, etc.)
4. **Freshness**: Prices may be outdated in fast-changing markets
5. **Variation**: Wide price ranges depending on location and store

## Fallback Strategy

The implementation uses a smart fallback approach:

```
1. Try to fetch real price from Open Prices API
   ↓
2. If real price exists → Use average price
   ↓
3. If no real price → Use category-based estimate
   ↓
4. Always return a valid price (never fails)
```

This ensures the app always has a price to display, whether real or estimated.

## Future Enhancements

### Potential Improvements
1. **Currency Conversion**: Convert all prices to user's local currency
2. **Location Filtering**: Automatically filter by user's country
3. **Price Contribution**: Allow users to submit prices to Open Prices
4. **Price Alerts**: Notify when prices drop below threshold
5. **Store Comparison**: Show prices from different stores
6. **Price Trends**: Display historical price charts
7. **Smart Caching**: Longer cache for stable products, shorter for volatile ones

### Integration Points
- **Budget Tracking**: Use real prices for more accurate budget calculations
- **Smart Lists**: Optimize shopping lists based on real store prices
- **Recipe Costing**: Calculate accurate recipe costs
- **Savings Analytics**: Show actual vs. budgeted price differences

## API Limits & Best Practices

### Rate Limits
- The Open Prices API doesn't specify strict rate limits (as of Oct 2025)
- Our implementation includes 1-hour caching to be respectful
- Batch requests when possible

### Best Practices
1. **Cache aggressively**: Prices don't change minute-to-minute
2. **Handle failures gracefully**: Always have a fallback
3. **Log appropriately**: Help debug price fetching issues
4. **User feedback**: Show when using real vs. estimated prices
5. **Contribute back**: Encourage users to submit prices

## Testing

### Manual Testing Steps

1. **Test with known barcode**:
   ```bash
   curl "https://prices.openfoodfacts.org/api/v1/prices?product_code=3017620422003&size=10" | jq '.'
   ```

2. **Test with barcode that has no prices**:
   - Scan a local/new product
   - Verify fallback to estimated price

3. **Test caching**:
   - Fetch same barcode twice
   - Verify second fetch uses cache (check logs)

4. **Test error handling**:
   - Disable network
   - Verify app doesn't crash, uses estimates

## Troubleshooting

### Common Issues

**Issue**: "Cannot find type 'OpenPricesService' in scope"
- **Solution**: Add `OpenPricesService.swift` to Xcode project target

**Issue**: "Cannot find type 'ProductPriceStats' in scope"  
- **Solution**: Add `OpenPricesResponse.swift` to Xcode project target

**Issue**: No real prices returned for any products
- **Solution**: Normal! Many products don't have price data yet. Fallback works.

**Issue**: Prices in wrong currency
- **Solution**: Future enhancement - need currency conversion

## Resources

- Open Prices Website: https://prices.openfoodfacts.org/
- Open Prices API Docs: https://prices.openfoodfacts.org/api/docs
- Open Food Facts API: https://openfoodfacts.github.io/openfoodfacts-server/api/
- Price Tutorial: https://openfoodfacts.github.io/openfoodfacts-server/api/tutorials/product-prices/

## Credits

- **Open Food Facts**: Product database and API
- **Open Prices**: Crowdsourced price database
- **Contributors**: Thousands of volunteers worldwide submitting price data

---

**Last Updated**: October 6, 2025
**Version**: 1.0
**Status**: ✅ Ready for Implementation
