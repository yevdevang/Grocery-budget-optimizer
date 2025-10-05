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

    init(openFoodFactsService: OpenFoodFactsServiceProtocol) {
        self.openFoodFactsService = openFoodFactsService
    }

    func execute(barcode: String) -> AnyPublisher<ScannedProductInfo?, Error> {
        print("🔍 Scanning barcode: \(barcode)")

        return openFoodFactsService.fetchProduct(barcode: barcode)
            .handleEvents(
                receiveOutput: { product in
                    if let product = product {
                        print("✅ Product found: \(product.name)")
                    } else {
                        print("⚠️ Product not found in Open Food Facts database")
                    }
                },
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Error scanning product: \(error)")
                    }
                }
            )
            .eraseToAnyPublisher()
    }
}
