//
//  OpenFoodFactsService.swift
//  Grocery-budget-optimizer
//
//  Created by Yevgeny Levin on 05/10/2025.
//

import Foundation
import Combine

protocol OpenFoodFactsServiceProtocol {
    func fetchProduct(barcode: String) -> AnyPublisher<ScannedProductInfo?, Error>
    func searchProducts(query: String, page: Int, pageSize: Int) -> AnyPublisher<[GroceryItem], Error>
    func fetchProductsByCategory(category: String, page: Int, pageSize: Int) -> AnyPublisher<[GroceryItem], Error>
    func fetchProductPrice(barcode: String) -> AnyPublisher<Decimal?, Error>
}

class OpenFoodFactsService: OpenFoodFactsServiceProtocol {
    private let baseURL = "https://world.openfoodfacts.org/api/v2"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchProduct(barcode: String) -> AnyPublisher<ScannedProductInfo?, Error> {
        guard let url = URL(string: "\(baseURL)/product/\(barcode).json") else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }

        print("🌐 Fetching product from: \(url.absoluteString)")

        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: OpenFoodFactsResponse.self, decoder: JSONDecoder())
            .map { [weak self] response -> ScannedProductInfo? in
                guard let self = self else { return nil }

                guard response.isFound,
                      let product = response.product,
                      let productName = product.productName else {
                    print("⚠️ Product not found or incomplete data")
                    return nil
                }

                print("✅ Product found: \(productName)")

                return ScannedProductInfo(
                    barcode: response.code,
                    name: productName,
                    brand: product.brands?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces),
                    category: product.categories?.components(separatedBy: ",").first ?? "Other",
                    unit: product.quantity ?? "1 unit",
                    imageUrl: product.imageUrl,
                    nutritionalInfo: self.formatNutritionalInfo(product.nutriments),
                    averagePrice: nil,
                    priceSource: .unavailable
                )
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func searchProducts(query: String, page: Int = 1, pageSize: Int = 20) -> AnyPublisher<[GroceryItem], Error> {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string: "\(baseURL)/search?search_terms=\(encodedQuery)&page=\(page)&page_size=\(pageSize)&fields=code,product_name,brands,categories,quantity,image_url,nutriments") else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        print("🌐 Searching products: \(url.absoluteString)")
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: OpenFoodFactsSearchResponse.self, decoder: JSONDecoder())
            .map { [weak self] response -> [GroceryItem] in
                guard let self = self else { return [] }
                
                return response.products.compactMap { product in
                    self.mapSearchProductToGroceryItem(product)
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func fetchProductsByCategory(category: String, page: Int = 1, pageSize: Int = 20) -> AnyPublisher<[GroceryItem], Error> {
        let encodedCategory = category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? category
        guard let url = URL(string: "\(baseURL)/search?categories_tags=\(encodedCategory)&page=\(page)&page_size=\(pageSize)&fields=code,product_name,brands,categories,quantity,image_url,nutriments") else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        print("🌐 Fetching products by category: \(url.absoluteString)")
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: OpenFoodFactsSearchResponse.self, decoder: JSONDecoder())
            .map { [weak self] response -> [GroceryItem] in
                guard let self = self else { return [] }
                
                return response.products.compactMap { product in
                    self.mapSearchProductToGroceryItem(product)
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    private func formatNutritionalInfo(_ nutriments: OpenFoodFactsResponse.Product.Nutriments?) -> String? {
        guard let nutriments = nutriments else { return nil }

        var info: [String] = []

        if let calories = nutriments.energyKcal100g {
            info.append("Calories: \(Int(calories)) kcal/100g")
        }
        if let fat = nutriments.fat100g {
            info.append("Fat: \(String(format: "%.1f", fat))g/100g")
        }
        if let carbs = nutriments.carbohydrates100g {
            info.append("Carbs: \(String(format: "%.1f", carbs))g/100g")
        }
        if let protein = nutriments.proteins100g {
            info.append("Protein: \(String(format: "%.1f", protein))g/100g")
        }

        return info.isEmpty ? nil : info.joined(separator: "\n")
    }
    
    private func mapSearchProductToGroceryItem(_ product: OpenFoodFactsSearchResponse.SearchProduct) -> GroceryItem? {
        guard let name = product.productName, !name.isEmpty else {
            return nil
        }
        
        let category = product.categories?.components(separatedBy: ",").first?.trimmingCharacters(in: CharacterSet.whitespaces) ?? "Pantry"
        let appCategory = OpenFoodFactsCategories.mapToAppCategory(category)
        
        return GroceryItem(
            name: name,
            category: appCategory,
            brand: product.brands?.components(separatedBy: ",").first?.trimmingCharacters(in: CharacterSet.whitespaces),
            unit: product.quantity ?? "1 unit",
            notes: formatNutritionalInfoFromSearch(product.nutriments),
            imageData: nil, // Will be loaded separately if needed
            barcode: product.code,
            averagePrice: generateEstimatedPrice(for: appCategory)
        )
    }
    
    private func formatNutritionalInfoFromSearch(_ nutriments: OpenFoodFactsSearchResponse.SearchProduct.Nutriments?) -> String? {
        guard let nutriments = nutriments else { return nil }

        var info: [String] = []

        if let calories = nutriments.energyKcal100g {
            info.append("Calories: \(Int(calories)) kcal/100g")
        }
        if let fat = nutriments.fat100g {
            info.append("Fat: \(String(format: "%.1f", fat))g/100g")
        }
        if let carbs = nutriments.carbohydrates100g {
            info.append("Carbs: \(String(format: "%.1f", carbs))g/100g")
        }
        if let protein = nutriments.proteins100g {
            info.append("Protein: \(String(format: "%.1f", protein))g/100g")
        }

        return info.isEmpty ? nil : info.joined(separator: "\n")
    }
    
    private func generateEstimatedPrice(for category: String) -> Decimal {
        // Generate estimated prices based on category
        switch category {
        case "Dairy":
            return Decimal(Double.random(in: 2.99...6.99))
        case "Produce":
            return Decimal(Double.random(in: 1.49...4.99))
        case "Meat & Seafood":
            return Decimal(Double.random(in: 5.99...14.99))
        case "Beverages":
            return Decimal(Double.random(in: 1.99...8.99))
        case "Frozen":
            return Decimal(Double.random(in: 3.99...9.99))
        case "Bakery":
            return Decimal(Double.random(in: 2.49...5.99))
        default:
            return Decimal(Double.random(in: 1.99...6.99))
        }
    }
    
    func fetchProductPrice(barcode: String) -> AnyPublisher<Decimal?, Error> {
        // Placeholder - returns nil for now
        return Just<Decimal?>(nil)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .productNotFound:
            return "Product not found in database"
        }
    }
}
