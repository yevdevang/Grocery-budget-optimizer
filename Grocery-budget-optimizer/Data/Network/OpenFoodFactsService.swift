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
}

class OpenFoodFactsService: OpenFoodFactsServiceProtocol {
    private let baseURL = "https://world.openfoodfacts.org/api/v2/product"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchProduct(barcode: String) -> AnyPublisher<ScannedProductInfo?, Error> {
        guard let url = URL(string: "\(baseURL)/\(barcode).json") else {
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
                    nutritionalInfo: self.formatNutritionalInfo(product.nutriments)
                )
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
