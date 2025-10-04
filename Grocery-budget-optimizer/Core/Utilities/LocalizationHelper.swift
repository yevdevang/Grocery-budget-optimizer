//
//  LocalizationHelper.swift
//  Grocery-budget-optimizer
//
//  Created by Claude on 04/10/2025.
//

import Foundation
import SwiftUI

/// Helper function to get localized string using LanguageManager
private func localized(_ key: String, comment: String = "") -> String {
    LanguageManager.shared.localizedString(key, comment: comment)
}

/// Helper class for accessing localized strings throughout the app
enum L10n {
    // MARK: - Common
    enum Common {
        static var cancel: String { localized("common.cancel", comment: "Cancel button") }
        static var save: String { localized("common.save", comment: "Save button") }
        static var create: String { localized("common.create", comment: "Create button") }
        static var add: String { localized("common.add", comment: "Add button") }
        static var delete: String { localized("common.delete", comment: "Delete button") }
        static var edit: String { localized("common.edit", comment: "Edit button") }
        static var done: String { localized("common.done", comment: "Done button") }
        static var close: String { localized("common.close", comment: "Close button") }
        static var ok: String { localized("common.ok", comment: "OK button") }
    }

    // MARK: - Tab Bar
    enum Tab {
        static var home: String { localized("tab.home", comment: "Home tab") }
        static var lists: String { localized("tab.lists", comment: "Lists tab") }
        static var items: String { localized("tab.items", comment: "Items tab") }
        static var budget: String { localized("tab.budget", comment: "Budget tab") }
        static var settings: String { localized("tab.settings", comment: "Settings tab") }
    }

    // MARK: - Home Screen
    enum Home {
        static var title: String { localized("home.title", comment: "App title") }
        static var subtitle: String { localized("home.subtitle", comment: "App subtitle") }
        
        enum Greeting {
            static var morning: String { localized("home.greeting.morning", comment: "Morning greeting") }
            static var afternoon: String { localized("home.greeting.afternoon", comment: "Afternoon greeting") }
            static var evening: String { localized("home.greeting.evening", comment: "Evening greeting") }
        }

        static var quickActions: String { localized("home.quickActions", comment: "Quick Actions section") }
        static var smartList: String { localized("home.smartList", comment: "Smart List action") }
        static var addItem: String { localized("home.addItem", comment: "Add Item action") }
        static var addExpense: String { localized("home.addExpense", comment: "Add Expense action") }
        static var viewStats: String { localized("home.viewStats", comment: "View Stats action") }
        static var expiringItems: String { localized("home.expiringItems", comment: "Expiring Items section") }
        static var predictions: String { localized("home.predictions", comment: "Predictions section") }
        static var recentActivity: String { localized("home.recentActivity", comment: "Recent Activity section") }
        static var noExpiring: String { localized("home.noExpiring", comment: "No expiring items message") }
        static var noPredictions: String { localized("home.noPredictions", comment: "No predictions message") }
        static var noActivity: String { localized("home.noActivity", comment: "No activity message") }
    }

    // MARK: - Add Item
    enum AddItem {
        static var title: String { localized("addItem.title", comment: "Add Item screen title") }
        static var details: String { localized("addItem.details", comment: "Item Details section") }
        static var name: String { localized("addItem.name", comment: "Item name field") }
        static var category: String { localized("addItem.category", comment: "Category field") }
        static var brand: String { localized("addItem.brand", comment: "Brand field") }
        static var unit: String { localized("addItem.unit", comment: "Unit field") }
        static var pricing: String { localized("addItem.pricing", comment: "Pricing section") }
        static var averagePrice: String { localized("addItem.averagePrice", comment: "Average price field") }
        static var additionalInfo: String { localized("addItem.additionalInfo", comment: "Additional Info section") }
        static var notes: String { localized("addItem.notes", comment: "Notes field") }
    }

    // MARK: - Add Expense
    enum AddExpense {
        static var title: String { localized("addExpense.title", comment: "Add Expense screen title") }
        static var item: String { localized("addExpense.item", comment: "Item section") }
        static var selectItem: String { localized("addExpense.selectItem", comment: "Select Item button") }
        static var purchaseDetails: String { localized("addExpense.purchaseDetails", comment: "Purchase Details section") }
        static var quantity: String { localized("addExpense.quantity", comment: "Quantity field") }
        static var pricePerUnit: String { localized("addExpense.pricePerUnit", comment: "Price per unit field") }
        static var totalCost: String { localized("addExpense.totalCost", comment: "Total Cost label") }
        static var purchaseDate: String { localized("addExpense.purchaseDate", comment: "Purchase Date field") }
        static var storeName: String { localized("addExpense.storeName", comment: "Store Name field") }
        static var storeNameOptional: String { localized("addExpense.storeNameOptional", comment: "Store Name optional field") }
    }

    // MARK: - Item Picker
    enum ItemPicker {
        static var title: String { localized("itemPicker.title", comment: "Item Picker title") }
        static var search: String { localized("itemPicker.search", comment: "Search placeholder") }
        static var noItems: String { localized("itemPicker.noItems", comment: "No items title") }
        static var noItemsMessage: String { localized("itemPicker.noItemsMessage", comment: "No items message") }
    }

    // MARK: - Budget
    enum Budget {
        static var title: String { localized("budget.title", comment: "Budget screen title") }
        static var overview: String { localized("budget.overview", comment: "Budget overview") }
        static var amount: String { localized("budget.amount", comment: "Budget amount") }
        static var spent: String { localized("budget.spent", comment: "Spent amount") }
        static var remaining: String { localized("budget.remaining", comment: "Remaining amount") }
        static var used: String { localized("budget.used", comment: "Used percentage") }
        static var daysLeft: String { localized("budget.daysLeft", comment: "Days left") }
        static var spendingByCategory: String { localized("budget.spendingByCategory", comment: "Spending by Category") }
        static var dailySpending: String { localized("budget.dailySpending", comment: "Daily Spending") }
        static var categoryBreakdown: String { localized("budget.categoryBreakdown", comment: "Category Breakdown") }
        static var noData: String { localized("budget.noData", comment: "No data message") }
        static var noCategoryData: String { localized("budget.noCategoryData", comment: "No category data") }
        static var addExpensesMessage: String { localized("budget.addExpensesMessage", comment: "Add expenses message") }
        static var addExpensesTrends: String { localized("budget.addExpensesTrends", comment: "Add expenses trends") }
        static var noBudget: String { localized("budget.noBudget", comment: "No budget") }
        static var createButton: String { localized("budget.createButton", comment: "Create Budget button") }
        static var exceedWarning: String { localized("budget.exceedWarning", comment: "Exceed warning") }
        static var createTitle: String { localized("budget.createTitle", comment: "Create Budget title") }
        static var information: String { localized("budget.information", comment: "Budget Information") }
        static var name: String { localized("budget.name", comment: "Budget name") }
        static var totalAmount: String { localized("budget.totalAmount", comment: "Total amount") }
        static var duration: String { localized("budget.duration", comment: "Duration") }
        static var startDate: String { localized("budget.startDate", comment: "Start date") }
        static var endDate: String { localized("budget.endDate", comment: "End date") }
        static var durationDays: String { localized("budget.durationDays", comment: "Duration days") }
        static var categoryNote: String { localized("budget.categoryNote", comment: "Category note") }
    }

    // MARK: - Shopping Lists
    enum Lists {
        static var title: String { localized("lists.title", comment: "Shopping Lists title") }
        static var smartList: String { localized("lists.smartList", comment: "Smart List") }
        static var manualList: String { localized("lists.manualList", comment: "Manual List") }
        static var active: String { localized("lists.active", comment: "Active Lists") }
        static var completed: String { localized("lists.completed", comment: "Completed") }
        static var noLists: String { localized("lists.noLists", comment: "No Lists") }
        static var createMessage: String { localized("lists.createMessage", comment: "Create message") }
        static var createSmartButton: String { localized("lists.createSmartButton", comment: "Create Smart button") }
        static var items: String { localized("lists.items", comment: "Items") }
        static var newList: String { localized("lists.newList", comment: "New List") }
        static var listDetails: String { localized("lists.listDetails", comment: "List Details") }
        static var listName: String { localized("lists.listName", comment: "List Name") }
        static var budgetAmount: String { localized("lists.budgetAmount", comment: "Budget Amount") }
        static var addItemsNote: String { localized("lists.addItemsNote", comment: "Add items note") }
        static var smartTitle: String { localized("lists.smartTitle", comment: "Smart List title") }
        static var aiPowered: String { localized("lists.aiPowered", comment: "AI Powered") }
        static var aiDescription: String { localized("lists.aiDescription", comment: "AI Description") }
        static var generating: String { localized("lists.generating", comment: "Generating") }
        static var generate: String { localized("lists.generate", comment: "Generate") }
    }

    // MARK: - Items
    enum Items {
        static var title: String { localized("items.title", comment: "Items title") }
        static var search: String { localized("items.search", comment: "Search") }
        static var all: String { localized("items.all", comment: "All") }
        static var noItems: String { localized("items.noItems", comment: "No Items") }
        static var addItemsMessage: String { localized("items.addItemsMessage", comment: "Add items message") }
        static var addButton: String { localized("items.addButton", comment: "Add button") }
        
        // Item Detail
        static var details: String { localized("items.details", comment: "Details section") }
        static var name: String { localized("items.name", comment: "Name field") }
        static var category: String { localized("items.category", comment: "Category field") }
        static var averagePrice: String { localized("items.averagePrice", comment: "Average Price field") }
        static var priceHistory: String { localized("items.priceHistory", comment: "Price History section") }
        static var priceHistoryPlaceholder: String { localized("items.priceHistoryPlaceholder", comment: "Price history placeholder") }
    }

    // MARK: - Settings
    enum Settings {
        static var title: String { localized("settings.title", comment: "Settings title") }
        static var account: String { localized("settings.account", comment: "Account") }
        static var profile: String { localized("settings.profile", comment: "Profile") }
        static var preferences: String { localized("settings.preferences", comment: "Preferences") }
        static var language: String { localized("settings.language", comment: "Language") }
        static var currency: String { localized("settings.currency", comment: "Currency") }
        static var notifications: String { localized("settings.notifications", comment: "Notifications") }
        static var about: String { localized("settings.about", comment: "About") }
        static var version: String { localized("settings.version", comment: "Version") }
        static var privacy: String { localized("settings.privacy", comment: "Privacy") }
        static var terms: String { localized("settings.terms", comment: "Terms") }
    }

    // MARK: - Categories
    enum Category {
        static var produce: String { localized("category.produce", comment: "Produce") }
        static var dairy: String { localized("category.dairy", comment: "Dairy") }
        static var meatSeafood: String { localized("category.meatSeafood", comment: "Meat & Seafood") }
        static var pantry: String { localized("category.pantry", comment: "Pantry") }
        static var beverages: String { localized("category.beverages", comment: "Beverages") }
        static var frozen: String { localized("category.frozen", comment: "Frozen") }
        static var bakery: String { localized("category.bakery", comment: "Bakery") }
        static var other: String { localized("category.other", comment: "Other") }
    }
}

// Extension to get localized category name
extension L10n.Category {
    /// Get localized category name for any category string
    static func localizedName(_ categoryName: String) -> String {
        switch categoryName {
        case "Produce": return produce
        case "Dairy": return dairy
        case "Meat & Seafood": return meatSeafood
        case "Pantry": return pantry
        case "Beverages": return beverages
        case "Frozen": return frozen
        case "Bakery": return bakery
        case "Other": return other
        default: return categoryName
        }
    }
}

// Helper function to get localized product name
func localizedProductName(_ productName: String) -> String {
    let key = "product.\(productName.lowercased())"
    let translated = LanguageManager.shared.localizedString(key)
    // If translation is the same as key, return original name
    return translated == key ? productName : translated
}
