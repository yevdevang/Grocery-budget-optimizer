//
//  OpenPricesService.swift
//  Grocery-budget-optimizer
//
//  Created by Yevgeny Levin on 06/10/2025.
//

import Foundation
import Combine

protocol OpenPricesServiceProtocol {
    func fetchPrices(barcode: String) -> AnyPublisher<ProductPriceStats?, Error>
    func fetchPricesByLocation(barcode: String, countryCode: String) -> AnyPublisher<ProductPriceStats?, Error>
}

class OpenPricesService: OpenPricesServiceProtocol {
    private let baseURL = "https://prices.openfoodfacts.org/api/v1"
    private let session: URLSession
    
    // Cache to store prices and reduce API calls
    private var priceCache: [String: (stats: ProductPriceStats, timestamp: Date)] = [:]
    private let cacheValidityDuration: TimeInterval = 3600 // 1 hour
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    /// Fetch prices for a product by barcode
    /// - Parameter barcode: Product barcode/EAN
    /// - Returns: Publisher with price statistics or nil if no prices found
    func fetchPrices(barcode: String) -> AnyPublisher<ProductPriceStats?, Error> {
        // Check cache first
        if let cached = priceCache[barcode],
           Date().timeIntervalSince(cached.timestamp) < cacheValidityDuration {
            print("💰 Using cached price for \(barcode): $\(String(format: "%.2f", NSDecimalNumber(decimal: cached.stats.averagePrice).doubleValue))")
            return Just(cached.stats)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // Build URL with query parameters
        guard var components = URLComponents(string: "\(baseURL)/prices") else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        components.queryItems = [
            URLQueryItem(name: "product_code", value: barcode),
            URLQueryItem(name: "order_by", value: "-date"), // Most recent first
            URLQueryItem(name: "size", value: "50") // Get up to 50 prices for good statistics
        ]
        
        guard let url = components.url else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        print("💰 Fetching prices from Open Prices API: \(barcode)")
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .handleEvents(receiveOutput: { data in
                // Debug: print raw response
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📦 Open Prices API Response (first 500 chars): \(String(jsonString.prefix(500)))")
                }
            })
            .decode(type: OpenPricesResponse.self, decoder: JSONDecoder())
            .map { [weak self] response -> ProductPriceStats? in
                guard !response.items.isEmpty else {
                    print("⚠️ No prices found for barcode: \(barcode)")
                    return nil
                }
                
                let stats = ProductPriceStats(from: response.items, barcode: barcode)
                
                print("✅ Found \(stats.priceCount) prices for \(barcode)")
                print("   Average: \(stats.currency) \(String(format: "%.2f", NSDecimalNumber(decimal: stats.averagePrice).doubleValue))")
                print("   Range: \(String(format: "%.2f", NSDecimalNumber(decimal: stats.minPrice).doubleValue)) - \(String(format: "%.2f", NSDecimalNumber(decimal: stats.maxPrice).doubleValue))")
                
                // Cache the result
                if let self = self {
                    self.priceCache[barcode] = (stats, Date())
                }
                
                return stats
            }
            .catch { error -> AnyPublisher<ProductPriceStats?, Error> in
                print("❌ Error fetching prices for \(barcode): \(error.localizedDescription)")
                // Return nil on error instead of failing the entire pipeline
                return Just(nil)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// Fetch prices for a product filtered by country
    /// - Parameters:
    ///   - barcode: Product barcode/EAN
    ///   - countryCode: Two-letter country code (e.g., "US", "FR", "GB")
    /// - Returns: Publisher with price statistics or nil if no prices found
    func fetchPricesByLocation(barcode: String, countryCode: String) -> AnyPublisher<ProductPriceStats?, Error> {
        guard var components = URLComponents(string: "\(baseURL)/prices") else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        components.queryItems = [
            URLQueryItem(name: "product_code", value: barcode),
            URLQueryItem(name: "location_osm_address_country_code", value: countryCode.uppercased()),
            URLQueryItem(name: "order_by", value: "-date"),
            URLQueryItem(name: "size", value: "50")
        ]
        
        guard let url = components.url else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        print("💰 Fetching prices for \(barcode) in \(countryCode)")
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: OpenPricesResponse.self, decoder: JSONDecoder())
            .map { response -> ProductPriceStats? in
                guard !response.items.isEmpty else {
                    print("⚠️ No prices found for \(barcode) in \(countryCode)")
                    return nil
                }
                
                let stats = ProductPriceStats(from: response.items, barcode: barcode)
                print("✅ Found \(stats.priceCount) prices in \(countryCode)")
                return stats
            }
            .catch { error -> AnyPublisher<ProductPriceStats?, Error> in
                print("❌ Error fetching prices: \(error.localizedDescription)")
                return Just(nil)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// Clear the price cache
    func clearCache() {
        priceCache.removeAll()
        print("🗑️ Price cache cleared")
    }
    
    /// Get cached price if available
    func getCachedPrice(barcode: String) -> ProductPriceStats? {
        guard let cached = priceCache[barcode],
              Date().timeIntervalSince(cached.timestamp) < cacheValidityDuration else {
            return nil
        }
        return cached.stats
    }
}
