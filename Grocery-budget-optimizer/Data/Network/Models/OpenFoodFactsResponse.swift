//
//  OpenFoodFactsResponse.swift
//  Grocery-budget-optimizer
//
//  Created by Yevgeny Levin on 05/10/2025.
//

import Foundation

struct OpenFoodFactsResponse: Codable {
    let code: String
    let product: Product?
    let status: Int
    let statusVerbose: String

    enum CodingKeys: String, CodingKey {
        case code
        case product
        case status
        case statusVerbose = "status_verbose"
    }

    struct Product: Codable {
        let productName: String?
        let brands: String?
        let categories: String?
        let quantity: String?
        let imageUrl: String?
        let nutriments: Nutriments?
        let stores: String?
        let countries: String?

        enum CodingKeys: String, CodingKey {
            case productName = "product_name"
            case brands
            case categories
            case quantity
            case imageUrl = "image_url"
            case nutriments
            case stores
            case countries
        }

        struct Nutriments: Codable {
            let energyKcal100g: Double?
            let fat100g: Double?
            let carbohydrates100g: Double?
            let proteins100g: Double?

            enum CodingKeys: String, CodingKey {
                case energyKcal100g = "energy-kcal_100g"
                case fat100g = "fat_100g"
                case carbohydrates100g = "carbohydrates_100g"
                case proteins100g = "proteins_100g"
            }
        }
    }

    var isFound: Bool {
        status == 1 && product != nil
    }
}

struct ScannedProductInfo: Identifiable {
    let id = UUID()
    let barcode: String
    let name: String
    let brand: String?
    let category: String
    let unit: String
    let imageUrl: String?
    let nutritionalInfo: String?

    func toGroceryItem() -> GroceryItem {
        GroceryItem(
            name: name,
            category: mapToAppCategory(category),
            brand: brand,
            unit: unit,
            barcode: barcode
        )
    }

    private func mapToAppCategory(_ apiCategory: String) -> String {
        // Map Open Food Facts categories to app categories
        let categoryLower = apiCategory.lowercased()

        if categoryLower.contains("fruit") || categoryLower.contains("vegetable") {
            return "Produce"
        } else if categoryLower.contains("dairy") || categoryLower.contains("milk") || categoryLower.contains("cheese") {
            return "Dairy"
        } else if categoryLower.contains("meat") || categoryLower.contains("fish") || categoryLower.contains("seafood") {
            return "Meat & Seafood"
        } else if categoryLower.contains("beverage") || categoryLower.contains("drink") {
            return "Beverages"
        } else if categoryLower.contains("frozen") {
            return "Frozen"
        } else if categoryLower.contains("bread") || categoryLower.contains("bakery") {
            return "Bakery"
        } else {
            return "Pantry"
        }
    }
}
