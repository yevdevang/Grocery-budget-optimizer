//
//  RamiLevyResponse.swift
//  Grocery-budget-optimizer
//
//  Created by Claude on 07/10/2025.
//

import Foundation

// MARK: - API Response Models
// The API returns a wrapper object with a products array
struct RamiLevyResponse: Codable {
    let products: [RamiLevyProduct]
    let success: Bool?
    let total: Int?
    let count: Int?
    let source: String?
    let cached: Bool?
    let timestamp: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Debug logging
        print("🔍 Available keys in response: \(container.allKeys)")
        
        // Try to decode products, throw descriptive error if missing
        if !container.contains(.products) {
            print("❌ No 'products' key found in response")
            throw DecodingError.keyNotFound(CodingKeys.products, 
                DecodingError.Context(codingPath: decoder.codingPath, 
                    debugDescription: "Missing 'products' key in API response"))
        }
        
        products = try container.decode([RamiLevyProduct].self, forKey: .products)
        success = try container.decodeIfPresent(Bool.self, forKey: .success)
        total = try container.decodeIfPresent(Int.self, forKey: .total)
        count = try container.decodeIfPresent(Int.self, forKey: .count)
        source = try container.decodeIfPresent(String.self, forKey: .source)
        cached = try container.decodeIfPresent(Bool.self, forKey: .cached)
        timestamp = try container.decodeIfPresent(String.self, forKey: .timestamp)
    }
    
    enum CodingKeys: String, CodingKey {
        case products
        case success
        case total
        case count
        case source
        case cached
        case timestamp
    }
}

struct RamiLevyProduct: Codable, Identifiable {
    let id: String
    let name: String
    let brand: String?
    let category: String
    let price: Decimal
    let currency: String
    let unit: String
    let weight: String?
    let volume: String?
    let barcode: String?
    let imageURL: String?
    let inStock: Bool
    let lastUpdated: String?
    let storeLocation: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case brand
        case category
        case price
        case unit
        case weight
        case volume
        case barcode
        case imageURL = "image_url"
        case inStock = "in_stock"
        case lastUpdated = "scraped_at"
        case storeLocation = "store"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        brand = try container.decodeIfPresent(String.self, forKey: .brand)
        category = try container.decode(String.self, forKey: .category)
        price = try container.decode(Decimal.self, forKey: .price)
        unit = "piece" // Default unit since it's not in API
        weight = try container.decodeIfPresent(String.self, forKey: .weight)
        volume = try container.decodeIfPresent(String.self, forKey: .volume)
        barcode = try container.decodeIfPresent(String.self, forKey: .barcode)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        inStock = try container.decode(Bool.self, forKey: .inStock)
        lastUpdated = try container.decodeIfPresent(String.self, forKey: .lastUpdated)
        storeLocation = try container.decode(String.self, forKey: .storeLocation)
        
        // Set currency to ILS for Israeli products
        currency = "ILS"
    }
}

// MARK: - Helper Extensions
extension RamiLevyProduct {
    var displayPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.currencySymbol = currency == "ILS" ? "₪" : currency
        
        return formatter.string(from: NSDecimalNumber(decimal: price)) ?? "\(price) \(currency)"
    }
    
    var isValidProduct: Bool {
        return !name.isEmpty && price > 0
    }
    
    var weightInfo: String? {
        if let weight = weight, !weight.isEmpty {
            return weight
        }
        if let volume = volume, !volume.isEmpty {
            return volume
        }
        return nil
    }
}