import Foundation
import Combine

class MLCoordinator {
    static let shared = MLCoordinator()

    private let shoppingListGenerator: ShoppingListGeneratorService
    private let purchasePredictor: PurchasePredictionService
    private let priceOptimizer: PriceOptimizationService
    private let expirationPredictor: ExpirationPredictionService

    private init() {
        self.shoppingListGenerator = ShoppingListGeneratorService()
        self.purchasePredictor = PurchasePredictionService()
        self.priceOptimizer = PriceOptimizationService()
        self.expirationPredictor = ExpirationPredictionService()
    }

    // Provide access to services
    func getShoppingListGenerator() -> ShoppingListGeneratorService {
        return shoppingListGenerator
    }

    func getPurchasePredictor() -> PurchasePredictionService {
        return purchasePredictor
    }

    func getPriceOptimizer() -> PriceOptimizationService {
        return priceOptimizer
    }

    func getExpirationPredictor() -> ExpirationPredictionService {
        return expirationPredictor
    }

    // Warmup models on app launch
    func warmupModels() {
        print("Warming up ML models...")
        // Perform dummy predictions to load models into memory
        // This improves first-use performance
    }
}
