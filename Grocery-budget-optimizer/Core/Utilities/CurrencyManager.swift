//
//  CurrencyManager.swift
//  Grocery-budget-optimizer
//
//  Created by Yevgeny Levin on 04/10/2025.
//

import Foundation
import SwiftUI
import Combine

/// Supported currencies in the app
enum Currency: String, CaseIterable, Identifiable {
    case usd = "USD"
    case rub = "RUB"
    case uah = "UAH"
    case ils = "ILS"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .usd: return "US Dollar"
        case .rub: return "Russian Ruble"
        case .uah: return "Ukrainian Hryvnia"
        case .ils: return "Israeli Shekel"
        }
    }
    
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .rub: return "₽"
        case .uah: return "₴"
        case .ils: return "₪"
        }
    }
    
    var code: String {
        rawValue
    }
    
    var flag: String {
        switch self {
        case .usd: return "🇺🇸"
        case .rub: return "🇷🇺"
        case .uah: return "🇺🇦"
        case .ils: return "🇮🇱"
        }
    }
    
    /// Get default currency for a language
    static func defaultCurrency(for language: Language) -> Currency {
        switch language {
        case .english: return .usd
        case .russian: return .rub
        case .ukrainian: return .uah
        case .hebrew: return .ils
        }
    }
}

/// Manages app currency selection and persistence
@MainActor
class CurrencyManager: ObservableObject {
    static let shared = CurrencyManager()
    
    @Published var currentCurrency: Currency {
        didSet {
            saveCurrency()
            objectWillChange.send()
        }
    }
    
    private let currencyKey = "app_currency"
    
    private init() {
        // Load saved currency or use language-based default
        if let savedCurrencyCode = UserDefaults.standard.string(forKey: currencyKey),
           let savedCurrency = Currency(rawValue: savedCurrencyCode) {
            self.currentCurrency = savedCurrency
        } else {
            // Use default currency based on current language
            self.currentCurrency = Currency.defaultCurrency(for: LanguageManager.shared.currentLanguage)
        }
    }
    
    private func saveCurrency() {
        UserDefaults.standard.set(currentCurrency.rawValue, forKey: currencyKey)
    }
    
    /// Update currency when language changes (optional, can be called manually)
    func updateCurrencyForLanguage(_ language: Language) {
        currentCurrency = Currency.defaultCurrency(for: language)
    }
}
