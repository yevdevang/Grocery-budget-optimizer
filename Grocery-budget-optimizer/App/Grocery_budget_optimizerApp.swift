//
//  Grocery_budget_optimizerApp.swift
//  Grocery-budget-optimizer
//
//  Created by Yevgeny Levin on 02/10/2025.
//

import SwiftUI
import CoreData

@main
struct Grocery_budget_optimizerApp: App {

    init() {
        print("🚀 App launching...")
        // Seed mock data
        MockDataSeeder.shared.seedMockData()

        // Warmup ML models
        MLCoordinator.shared.warmupModels()

        print("✅ App initialized successfully")
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    print("📱 MainTabView appeared")
                }
        }
    }
}
