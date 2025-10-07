//
//  OpenPricesResponse.swift
//  Grocery-budget-optimizer
//
//  Created by Yevgeny Levin on 06/10/2025.
//

import Foundation

// MARK: - Open Prices API Response Models

struct OpenPricesResponse: Codable {
    let items: [PriceItem]
    let total: Int?
    let page: Int?
    let size: Int?
    let pages: Int?
    
    struct PriceItem: Codable {
        let id: Int
        let productId: Int?
        let locationId: Int?
        let proofId: Int?
        let price: Double
        let priceIsDiscounted: Bool?
        let priceWithoutDiscount: Double?
        let pricePer: String?
        let currency: String
        let date: String
        let owner: String?
        let product: ProductInfo?
        let location: LocationInfo?
        
        enum CodingKeys: String, CodingKey {
            case id
            case productId = "product_id"
            case locationId = "location_id"
            case proofId = "proof_id"
            case price
            case priceIsDiscounted = "price_is_discounted"
            case priceWithoutDiscount = "price_without_discount"
            case pricePer = "price_per"
            case currency
            case date
            case owner
            case product
            case location
        }
        
        struct ProductInfo: Codable {
            let id: Int
            let code: String
            let productName: String?
            let imageUrl: String?
            let productQuantity: Int?
            let productQuantityUnit: String?
            let brands: String?
            let priceCount: Int?
            
            enum CodingKeys: String, CodingKey {
                case id
                case code
                case productName = "product_name"
                case imageUrl = "image_url"
                case productQuantity = "product_quantity"
                case productQuantityUnit = "product_quantity_unit"
                case brands
                case priceCount = "price_count"
            }
        }
        
        struct LocationInfo: Codable {
            let id: Int
            let osmName: String?
            let osmAddressCity: String?
            let osmAddressCountry: String?
            let osmAddressCountryCode: String?
            
            enum CodingKeys: String, CodingKey {
                case id
                case osmName = "osm_name"
                case osmAddressCity = "osm_address_city"
                case osmAddressCountry = "osm_address_country"
                case osmAddressCountryCode = "osm_address_country_code"
            }
        }
    }
}

// MARK: - Price Statistics

struct ProductPriceStats {
    let barcode: String
    let averagePrice: Decimal
    let minPrice: Decimal
    let maxPrice: Decimal
    let currency: String
    let priceCount: Int
    let lastUpdated: Date?
    let locationCountry: String?
    
    init(from priceItems: [OpenPricesResponse.PriceItem], barcode: String) {
        self.barcode = barcode
        self.priceCount = priceItems.count
        
        let prices = priceItems.map { Decimal($0.price) }
        self.averagePrice = prices.isEmpty ? 0 : prices.reduce(0, +) / Decimal(prices.count)
        self.minPrice = prices.min() ?? 0
        self.maxPrice = prices.max() ?? 0
        
        // Use the most common currency
        self.currency = priceItems.first?.currency ?? "USD"
        
        // Most recent location
        self.locationCountry = priceItems.first?.location?.osmAddressCountryCode
        
        // Parse the most recent date
        if let dateString = priceItems.first?.date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            self.lastUpdated = formatter.date(from: dateString)
        } else {
            self.lastUpdated = nil
        }
    }
}
