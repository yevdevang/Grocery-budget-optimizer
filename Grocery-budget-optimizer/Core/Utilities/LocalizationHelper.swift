//
//  LocalizationHelper.swift
//  Grocery-budget-optimizer
//
//  Created by Claude on 04/10/2025.
//

import Foundation
import SwiftUI

/// Helper class for accessing localized strings throughout the app
enum L10n {
    // MARK: - Common
    enum Common {
        static let cancel = NSLocalizedString("common.cancel", comment: "Cancel button")
        static let save = NSLocalizedString("common.save", comment: "Save button")
        static let create = NSLocalizedString("common.create", comment: "Create button")
        static let add = NSLocalizedString("common.add", comment: "Add button")
        static let delete = NSLocalizedString("common.delete", comment: "Delete button")
        static let edit = NSLocalizedString("common.edit", comment: "Edit button")
        static let done = NSLocalizedString("common.done", comment: "Done button")
        static let close = NSLocalizedString("common.close", comment: "Close button")
        static let ok = NSLocalizedString("common.ok", comment: "OK button")
    }

    // MARK: - Tab Bar
    enum Tab {
        static let home = NSLocalizedString("tab.home", comment: "Home tab")
        static let lists = NSLocalizedString("tab.lists", comment: "Lists tab")
        static let items = NSLocalizedString("tab.items", comment: "Items tab")
        static let budget = NSLocalizedString("tab.budget", comment: "Budget tab")
        static let settings = NSLocalizedString("tab.settings", comment: "Settings tab")
    }

    // MARK: - Home Screen
    enum Home {
        enum Greeting {
            static let morning = NSLocalizedString("home.greeting.morning", comment: "Morning greeting")
            static let afternoon = NSLocalizedString("home.greeting.afternoon", comment: "Afternoon greeting")
            static let evening = NSLocalizedString("home.greeting.evening", comment: "Evening greeting")
        }

        static let quickActions = NSLocalizedString("home.quickActions", comment: "Quick Actions section")
        static let smartList = NSLocalizedString("home.smartList", comment: "Smart List action")
        static let addItem = NSLocalizedString("home.addItem", comment: "Add Item action")
        static let addExpense = NSLocalizedString("home.addExpense", comment: "Add Expense action")
        static let viewStats = NSLocalizedString("home.viewStats", comment: "View Stats action")
        static let expiringItems = NSLocalizedString("home.expiringItems", comment: "Expiring Items section")
        static let predictions = NSLocalizedString("home.predictions", comment: "Predictions section")
        static let recentActivity = NSLocalizedString("home.recentActivity", comment: "Recent Activity section")
        static let noExpiring = NSLocalizedString("home.noExpiring", comment: "No expiring items message")
        static let noPredictions = NSLocalizedString("home.noPredictions", comment: "No predictions message")
        static let noActivity = NSLocalizedString("home.noActivity", comment: "No activity message")
    }

    // MARK: - Add Item
    enum AddItem {
        static let title = NSLocalizedString("addItem.title", comment: "Add Item screen title")
        static let details = NSLocalizedString("addItem.details", comment: "Item Details section")
        static let name = NSLocalizedString("addItem.name", comment: "Item name field")
        static let category = NSLocalizedString("addItem.category", comment: "Category field")
        static let brand = NSLocalizedString("addItem.brand", comment: "Brand field")
        static let unit = NSLocalizedString("addItem.unit", comment: "Unit field")
        static let pricing = NSLocalizedString("addItem.pricing", comment: "Pricing section")
        static let averagePrice = NSLocalizedString("addItem.averagePrice", comment: "Average price field")
        static let additionalInfo = NSLocalizedString("addItem.additionalInfo", comment: "Additional Info section")
        static let notes = NSLocalizedString("addItem.notes", comment: "Notes field")
    }

    // MARK: - Add Expense
    enum AddExpense {
        static let title = NSLocalizedString("addExpense.title", comment: "Add Expense screen title")
        static let item = NSLocalizedString("addExpense.item", comment: "Item section")
        static let selectItem = NSLocalizedString("addExpense.selectItem", comment: "Select Item button")
        static let purchaseDetails = NSLocalizedString("addExpense.purchaseDetails", comment: "Purchase Details section")
        static let quantity = NSLocalizedString("addExpense.quantity", comment: "Quantity field")
        static let pricePerUnit = NSLocalizedString("addExpense.pricePerUnit", comment: "Price per unit field")
        static let totalCost = NSLocalizedString("addExpense.totalCost", comment: "Total Cost label")
        static let purchaseDate = NSLocalizedString("addExpense.purchaseDate", comment: "Purchase Date field")
        static let storeName = NSLocalizedString("addExpense.storeName", comment: "Store Name field")
    }

    // MARK: - Item Picker
    enum ItemPicker {
        static let title = NSLocalizedString("itemPicker.title", comment: "Item Picker title")
        static let search = NSLocalizedString("itemPicker.search", comment: "Search placeholder")
        static let noItems = NSLocalizedString("itemPicker.noItems", comment: "No items title")
        static let noItemsMessage = NSLocalizedString("itemPicker.noItemsMessage", comment: "No items message")
    }

    // MARK: - Budget
    enum Budget {
        static let title = NSLocalizedString("budget.title", comment: "Budget screen title")
        static let overview = NSLocalizedString("budget.overview", comment: "Budget overview")
        static let amount = NSLocalizedString("budget.amount", comment: "Budget amount")
        static let spent = NSLocalizedString("budget.spent", comment: "Spent amount")
        static let remaining = NSLocalizedString("budget.remaining", comment: "Remaining amount")
        static let used = NSLocalizedString("budget.used", comment: "Used percentage")
        static let daysLeft = NSLocalizedString("budget.daysLeft", comment: "Days left")
        static let spendingByCategory = NSLocalizedString("budget.spendingByCategory", comment: "Spending by Category")
        static let dailySpending = NSLocalizedString("budget.dailySpending", comment: "Daily Spending")
        static let categoryBreakdown = NSLocalizedString("budget.categoryBreakdown", comment: "Category Breakdown")
        static let noData = NSLocalizedString("budget.noData", comment: "No data message")
        static let noCategoryData = NSLocalizedString("budget.noCategoryData", comment: "No category data")
        static let addExpensesMessage = NSLocalizedString("budget.addExpensesMessage", comment: "Add expenses message")
        static let addExpensesTrends = NSLocalizedString("budget.addExpensesTrends", comment: "Add expenses trends")
        static let noBudget = NSLocalizedString("budget.noBudget", comment: "No budget")
        static let createButton = NSLocalizedString("budget.createButton", comment: "Create Budget button")
        static let exceedWarning = NSLocalizedString("budget.exceedWarning", comment: "Exceed warning")
        static let createTitle = NSLocalizedString("budget.createTitle", comment: "Create Budget title")
        static let information = NSLocalizedString("budget.information", comment: "Budget Information")
        static let name = NSLocalizedString("budget.name", comment: "Budget name")
        static let totalAmount = NSLocalizedString("budget.totalAmount", comment: "Total amount")
        static let duration = NSLocalizedString("budget.duration", comment: "Duration")
        static let startDate = NSLocalizedString("budget.startDate", comment: "Start date")
        static let endDate = NSLocalizedString("budget.endDate", comment: "End date")
        static let durationDays = NSLocalizedString("budget.durationDays", comment: "Duration days")
        static let categoryNote = NSLocalizedString("budget.categoryNote", comment: "Category note")
    }

    // MARK: - Shopping Lists
    enum Lists {
        static let title = NSLocalizedString("lists.title", comment: "Shopping Lists title")
        static let smartList = NSLocalizedString("lists.smartList", comment: "Smart List")
        static let manualList = NSLocalizedString("lists.manualList", comment: "Manual List")
        static let active = NSLocalizedString("lists.active", comment: "Active Lists")
        static let completed = NSLocalizedString("lists.completed", comment: "Completed")
        static let noLists = NSLocalizedString("lists.noLists", comment: "No Lists")
        static let createMessage = NSLocalizedString("lists.createMessage", comment: "Create message")
        static let createSmartButton = NSLocalizedString("lists.createSmartButton", comment: "Create Smart button")
        static let items = NSLocalizedString("lists.items", comment: "Items")
        static let newList = NSLocalizedString("lists.newList", comment: "New List")
        static let listDetails = NSLocalizedString("lists.listDetails", comment: "List Details")
        static let listName = NSLocalizedString("lists.listName", comment: "List Name")
        static let budgetAmount = NSLocalizedString("lists.budgetAmount", comment: "Budget Amount")
        static let addItemsNote = NSLocalizedString("lists.addItemsNote", comment: "Add items note")
        static let smartTitle = NSLocalizedString("lists.smartTitle", comment: "Smart List title")
        static let aiPowered = NSLocalizedString("lists.aiPowered", comment: "AI Powered")
        static let aiDescription = NSLocalizedString("lists.aiDescription", comment: "AI Description")
        static let generating = NSLocalizedString("lists.generating", comment: "Generating")
        static let generate = NSLocalizedString("lists.generate", comment: "Generate")
    }

    // MARK: - Items
    enum Items {
        static let title = NSLocalizedString("items.title", comment: "Items title")
        static let search = NSLocalizedString("items.search", comment: "Search")
        static let all = NSLocalizedString("items.all", comment: "All")
        static let noItems = NSLocalizedString("items.noItems", comment: "No Items")
        static let addItemsMessage = NSLocalizedString("items.addItemsMessage", comment: "Add items message")
        static let addButton = NSLocalizedString("items.addButton", comment: "Add button")
    }

    // MARK: - Settings
    enum Settings {
        static let title = NSLocalizedString("settings.title", comment: "Settings title")
        static let account = NSLocalizedString("settings.account", comment: "Account")
        static let profile = NSLocalizedString("settings.profile", comment: "Profile")
        static let preferences = NSLocalizedString("settings.preferences", comment: "Preferences")
        static let language = NSLocalizedString("settings.language", comment: "Language")
        static let currency = NSLocalizedString("settings.currency", comment: "Currency")
        static let notifications = NSLocalizedString("settings.notifications", comment: "Notifications")
        static let about = NSLocalizedString("settings.about", comment: "About")
        static let version = NSLocalizedString("settings.version", comment: "Version")
        static let privacy = NSLocalizedString("settings.privacy", comment: "Privacy")
        static let terms = NSLocalizedString("settings.terms", comment: "Terms")
    }

    // MARK: - Categories
    enum Category {
        static let produce = NSLocalizedString("category.produce", comment: "Produce")
        static let dairy = NSLocalizedString("category.dairy", comment: "Dairy")
        static let meatSeafood = NSLocalizedString("category.meatSeafood", comment: "Meat & Seafood")
        static let pantry = NSLocalizedString("category.pantry", comment: "Pantry")
        static let beverages = NSLocalizedString("category.beverages", comment: "Beverages")
        static let frozen = NSLocalizedString("category.frozen", comment: "Frozen")
        static let bakery = NSLocalizedString("category.bakery", comment: "Bakery")
        static let other = NSLocalizedString("category.other", comment: "Other")
    }
}
