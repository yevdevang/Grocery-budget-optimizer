//
//  OpenFoodFactsSearchResponse.swift
//  Grocery-budget-optimizer
//
//  Created by Yevgeny Levin on 05/10/2025.
//

import Foundation

// Response for search and category queries
struct OpenFoodFactsSearchResponse: Codable {
    let count: Int
    let page: Int
    let pageSize: Int
    let products: [SearchProduct]
    
    enum CodingKeys: String, CodingKey {
        case count
        case page
        case pageSize = "page_size"
        case products
    }
    
    struct SearchProduct: Codable {
        let code: String?
        let productName: String?
        let brands: String?
        let categories: String?
        let quantity: String?
        let imageUrl: String?
        let nutriments: Nutriments?
        
        enum CodingKeys: String, CodingKey {
            case code
            case productName = "product_name"
            case brands
            case categories
            case quantity
            case imageUrl = "image_url"
            case nutriments
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
}

// Categories available from Open Food Facts
struct OpenFoodFactsCategories {
    static let categories = [
        "Dairy products",
        "Plant-based foods and beverages",
        "Fruits and vegetables based foods",
        "Cereals and potatoes",
        "Meats",
        "Fishes",
        "Seafood",
        "Beverages",
        "Frozen foods",
        "Snacks",
        "Composite foods"
    ]
    
    // Mapping to app categories
    static func mapToAppCategory(_ apiCategory: String) -> String {
        let categoryLower = apiCategory.lowercased()
        
        if categoryLower.contains("dairy") {
            return "Dairy"
        } else if categoryLower.contains("fruit") || categoryLower.contains("vegetable") || categoryLower.contains("plant-based") {
            return "Produce"
        } else if categoryLower.contains("meat") {
            return "Meat & Seafood"
        } else if categoryLower.contains("fish") || categoryLower.contains("seafood") {
            return "Meat & Seafood"
        } else if categoryLower.contains("beverage") || categoryLower.contains("drink") {
            return "Beverages"
        } else if categoryLower.contains("frozen") {
            return "Frozen"
        } else if categoryLower.contains("bread") || categoryLower.contains("bakery") || categoryLower.contains("cereal") {
            return "Bakery"
        } else {
            return "Pantry"
        }
    }
}
