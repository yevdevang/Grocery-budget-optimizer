//
//  ScanProductUseCase.swift
//  Grocery-budget-optimizer
//
//  Created by Yevgeny Levin on 05/10/2025.
//

import Foundation
import Combine

protocol ScanProductUseCaseProtocol {
    func execute(barcode: String) -> AnyPublisher<ScannedProductInfo?, Error>
}

class ScanProductUseCase: ScanProductUseCaseProtocol {
    private let openFoodFactsService: OpenFoodFactsServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(openFoodFactsService: OpenFoodFactsServiceProtocol) {
        self.openFoodFactsService = openFoodFactsService
    }

    func execute(barcode: String) -> AnyPublisher<ScannedProductInfo?, Error> {
        print("🔍 Scanning barcode: \(barcode)")

        // First fetch product info, then fetch price
        return openFoodFactsService.fetchProduct(barcode: barcode)
            .flatMap { [weak self] productInfo -> AnyPublisher<ScannedProductInfo?, Error> in
                guard let self = self, let productInfo = productInfo else {
                    print("⚠️ Product not found in Open Food Facts database")
                    return Just(nil)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                
                print("✅ Product found: \(productInfo.name)")
                print("💰 Fetching price for: \(barcode)")
                
                // Fetch price from Open Prices API
                return self.openFoodFactsService.fetchProductPrice(barcode: barcode)
                    .map { price -> ScannedProductInfo? in
                        // Create updated product info with price
                        let priceSource: ScannedProductInfo.PriceSource
                        let finalPrice: Decimal?
                        
                        if let realPrice = price, realPrice > 0 {
                            // Real price from Open Prices
                            priceSource = .real(count: 1, currency: "EUR") // Currency from API
                            finalPrice = realPrice
                            print("✅ Real price found: €\(String(format: "%.2f", NSDecimalNumber(decimal: realPrice).doubleValue))")
                        } else {
                            // No price data available - let user enter manually
                            finalPrice = nil
                            priceSource = .unavailable
                            print("ℹ️ No price data available - User can enter price manually")
                        }
                        
                        return ScannedProductInfo(
                            barcode: productInfo.barcode,
                            name: productInfo.name,
                            brand: productInfo.brand,
                            category: productInfo.category,
                            unit: productInfo.unit,
                            imageUrl: productInfo.imageUrl,
                            nutritionalInfo: productInfo.nutritionalInfo,
                            averagePrice: finalPrice,
                            priceSource: priceSource
                        )
                    }
                    .catch { error -> AnyPublisher<ScannedProductInfo?, Error> in
                        print("⚠️ Error fetching price: \(error.localizedDescription)")
                        // On price fetch error, return product with no price
                        let productWithoutPrice = ScannedProductInfo(
                            barcode: productInfo.barcode,
                            name: productInfo.name,
                            brand: productInfo.brand,
                            category: productInfo.category,
                            unit: productInfo.unit,
                            imageUrl: productInfo.imageUrl,
                            nutritionalInfo: productInfo.nutritionalInfo,
                            averagePrice: nil,
                            priceSource: .unavailable
                        )
                        
                        return Just(productWithoutPrice)
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .handleEvents(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Error scanning product: \(error)")
                    }
                }
            )
            .eraseToAnyPublisher()
    }
}
