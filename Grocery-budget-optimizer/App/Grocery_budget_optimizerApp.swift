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
        print("📁 App Container: \(FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.path ?? "unknown")")

        // Initialize language manager (will load saved language)
        _ = LanguageManager.shared

        // Initialize CoreData stack early to ensure it's ready
        print("💾 Initializing CoreData...")
        _ = CoreDataStack.shared.viewContext
        print("💾 CoreData initialized")

        // Seed mock data
        MockDataSeeder.shared.seedMockData()

        // Warmup ML models
        MLCoordinator.shared.warmupModels()

        print("✅ App initialized successfully")
        print("🌍 Language: \(LanguageManager.shared.currentLanguage.displayName)")
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
