//
//  RamiLevyService.swift
//  Grocery-budget-optimizer
//
//  Created by Claude on 07/10/2025.
//

import Foundation
import Combine

protocol RamiLevyServiceProtocol {
    func fetchProducts() -> AnyPublisher<[RamiLevyProduct], Error>
    func searchProducts(query: String) -> AnyPublisher<[RamiLevyProduct], Error>
    func fetchGroceryItems() -> AnyPublisher<[GroceryItem], Error>
    func searchGroceryItems(query: String) -> AnyPublisher<[GroceryItem], Error>
}

class RamiLevyService: ObservableObject, RamiLevyServiceProtocol {
    private let baseURL = "http://192.168.1.228:3000"
    private let session: URLSession
    
    // Cache to store products and reduce API calls
    private var productCache: [RamiLevyProduct] = []
    private var lastCacheUpdate: Date?
    private let cacheValidityDuration: TimeInterval = 1800 // 30 minutes
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    /// Fetch all products from Rami Levy API
    /// - Returns: Publisher with array of Rami Levy products
    func fetchProducts() -> AnyPublisher<[RamiLevyProduct], Error> {
        // Check cache first
        if let lastUpdate = lastCacheUpdate,
           Date().timeIntervalSince(lastUpdate) < cacheValidityDuration,
           !productCache.isEmpty {
            print("🛒 Using cached Rami Levy products (\(productCache.count) items)")
            return Just(productCache)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        guard let url = URL(string: "\(baseURL)/api/stores/rami-levy/products") else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        print("🌐 Fetching Rami Levy products from: \(url.absoluteString)")
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .handleEvents(receiveOutput: { data in
                // Debug logging - print raw JSON response
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("🔍 Raw API Response: \(String(jsonString.prefix(500)))...")
                } else {
                    print("❌ Could not decode response data as UTF-8")
                }
            })
            .decode(type: RamiLevyResponse.self, decoder: JSONDecoder())
            .map { [weak self] response in
                // Extract products from the wrapper response
                let products = response.products
                
                // Update cache
                self?.productCache = products
                self?.lastCacheUpdate = Date()
                
                print("✅ Fetched \(products.count) products from Rami Levy API")
                return products
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// Search products by query string
    /// - Parameter query: Search query
    /// - Returns: Publisher with filtered array of Rami Levy products
    func searchProducts(query: String) -> AnyPublisher<[RamiLevyProduct], Error> {
        return fetchProducts()
            .map { products in
                let lowercaseQuery = query.lowercased()
                return products.filter { product in
                    product.name.lowercased().contains(lowercaseQuery) ||
                    product.brand?.lowercased().contains(lowercaseQuery) == true ||
                    product.category.lowercased().contains(lowercaseQuery) ||
                    product.barcode?.contains(query) == true
                }
            }
            .eraseToAnyPublisher()
    }
    
    /// Clear the cache (useful for manual refresh)
    func clearCache() {
        productCache.removeAll()
        lastCacheUpdate = nil
        print("🗑️ Rami Levy product cache cleared")
    }
    
    /// Fetch all products and convert to GroceryItems
    /// - Returns: Publisher with array of GroceryItems converted from Rami Levy products
    func fetchGroceryItems() -> AnyPublisher<[GroceryItem], Error> {
        return fetchProducts()
            .map { products in
                return products.map { self.convertToGroceryItem($0) }
            }
            .eraseToAnyPublisher()
    }
    
    /// Search products and convert to GroceryItems
    /// - Parameter query: Search query
    /// - Returns: Publisher with filtered array of GroceryItems converted from Rami Levy products
    func searchGroceryItems(query: String) -> AnyPublisher<[GroceryItem], Error> {
        return searchProducts(query: query)
            .map { products in
                return products.map { self.convertToGroceryItem($0) }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Helper Methods
    
    /// Convert Rami Levy product to domain GroceryItem
    private func convertToGroceryItem(_ ramiLevyProduct: RamiLevyProduct) -> GroceryItem {
        return GroceryItem(
            id: UUID(), // Generate new UUID for domain entity
            name: ramiLevyProduct.name,
            category: mapCategory(ramiLevyProduct.category),
            brand: ramiLevyProduct.brand,
            unit: ramiLevyProduct.unit,
            notes: buildNotes(for: ramiLevyProduct),
            imageData: nil, // Will be loaded separately if needed
            imageURL: ramiLevyProduct.imageURL,
            barcode: ramiLevyProduct.barcode,
            averagePrice: ramiLevyProduct.price,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    /// Build notes string from Rami Levy product data
    private func buildNotes(for product: RamiLevyProduct) -> String? {
        var notes: [String] = []
        
        // Add store location if available
        if let storeLocation = product.storeLocation, !storeLocation.isEmpty {
            notes.append("Available at: \(storeLocation)")
        }
        
        // Add weight/volume info if available
        if let weight = product.weight, !weight.isEmpty {
            notes.append("Weight: \(weight)")
        } else if let volume = product.volume, !volume.isEmpty {
            notes.append("Volume: \(volume)")
        }
        
        // Add stock status
        if !product.inStock {
            notes.append("Currently out of stock")
        }
        
        // Add source
        notes.append("Source: Rami Levy API")
        
        return notes.isEmpty ? nil : notes.joined(separator: " • ")
    }
    
    /// Map Rami Levy categories to app categories
    private func mapCategory(_ ramiLevyCategory: String) -> String {
        let categoryMapping: [String: String] = [
            // Hebrew categories
            "פירות וירקות": "Produce",
            "פירות": "Produce",
            "ירקות": "Produce",
            "חלב וביצים": "Dairy",
            "חלב": "Dairy",
            "ביצים": "Dairy",
            "גבינות": "Dairy",
            "יוגורט": "Dairy",
            "בשר ועוף": "Meat & Seafood",
            "בשר": "Meat & Seafood",
            "עוף": "Meat & Seafood",
            "בקר": "Meat & Seafood",
            "דגים": "Meat & Seafood",
            "לחם ומאפים": "Bakery",
            "לחם": "Bakery",
            "מאפים": "Bakery",
            "עוגות": "Bakery",
            "קפואים": "Frozen",
            "משקאות": "Beverages",
            "מים": "Beverages",
            "מיצים": "Beverages",
            "קפה": "Beverages",
            "תה": "Beverages",
            "חטיפים": "Snacks",
            "ממתקים": "Snacks",
            "שוקולד": "Snacks",
            "ביסקוויטים": "Snacks",
            "ניקיון": "Household",
            "כביסה": "Household",
            "קוסמטיקה": "Personal Care",
            "היגיינה": "Personal Care",
            "תינוקות": "Personal Care",
            "דגנים": "Pantry",
            "אורז": "Pantry",
            "פסטה": "Pantry",
            "שימורים": "Pantry",
            "תבלינים": "Pantry",
            "רטבים": "Pantry",
            "שמן": "Pantry",
            "אורגני": "Produce",
            "כשר לפסח": "Other",
            "חד פעמי": "Household",
            
            // English fallbacks
            "fruits": "Produce",
            "vegetables": "Produce",
            "produce": "Produce",
            "dairy": "Dairy",
            "milk": "Dairy",
            "cheese": "Dairy",
            "yogurt": "Dairy",
            "meat": "Meat & Seafood",
            "seafood": "Meat & Seafood",
            "fish": "Meat & Seafood",
            "chicken": "Meat & Seafood",
            "beef": "Meat & Seafood",
            "bakery": "Bakery",
            "bread": "Bakery",
            "pastry": "Bakery",
            "frozen": "Frozen",
            "beverages": "Beverages",
            "drinks": "Beverages",
            "juice": "Beverages",
            "coffee": "Beverages",
            "tea": "Beverages",
            "snacks": "Snacks",
            "candy": "Snacks",
            "chocolate": "Snacks",
            "cookies": "Snacks",
            "household": "Household",
            "cleaning": "Household",
            "personal care": "Personal Care",
            "cosmetics": "Personal Care",
            "baby": "Personal Care",
            "pantry": "Pantry",
            "grains": "Pantry",
            "rice": "Pantry",
            "pasta": "Pantry",
            "canned": "Pantry",
            "spices": "Pantry",
            "sauces": "Pantry",
            "oil": "Pantry",
            "organic": "Produce"
        ]
        
        let lowercaseCategory = ramiLevyCategory.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try exact match first
        if let mappedCategory = categoryMapping[lowercaseCategory] {
            return mappedCategory
        }
        
        // Try partial matches
        for (key, value) in categoryMapping {
            if lowercaseCategory.contains(key) {
                return value
            }
        }
        
        // Default fallback
        return "Other"
    }
}