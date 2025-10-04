//
//  LanguageManager.swift
//  Grocery-budget-optimizer
//
//  Created by Claude on 04/10/2025.
//

import Foundation
import SwiftUI
import Combine

/// Supported languages in the app
enum Language: String, CaseIterable, Identifiable {
    case english = "en"
    case russian = "ru"
    case ukrainian = "uk"
    case hebrew = "he"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .russian: return "Русский"
        case .ukrainian: return "Українська"
        case .hebrew: return "עברית"
        }
    }

    var flag: String {
        switch self {
        case .english: return "🇬🇧"
        case .russian: return "🇷🇺"
        case .ukrainian: return "🇺🇦"
        case .hebrew: return "🇮🇱"
        }
    }

    /// Is this a right-to-left language?
    var isRTL: Bool {
        self == .hebrew
    }
}

/// Manages app language selection and persistence
@MainActor
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published var currentLanguage: Language {
        didSet {
            saveLanguage()
            updateAppLanguage()
            // Force UI update
            objectWillChange.send()
        }
    }

    private let languageKey = "app_language"

    private init() {
        // Load saved language or use system default
        if let savedLanguageCode = UserDefaults.standard.string(forKey: languageKey),
           let savedLanguage = Language(rawValue: savedLanguageCode) {
            self.currentLanguage = savedLanguage
        } else {
            // Try to match system language
            let systemLanguageCode = Locale.current.language.languageCode?.identifier ?? "en"
            self.currentLanguage = Language(rawValue: systemLanguageCode) ?? .english
        }

        updateAppLanguage()
    }

    private func saveLanguage() {
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: languageKey)
    }

    private func updateAppLanguage() {
        UserDefaults.standard.set([currentLanguage.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()

        // Update layout direction for RTL languages
        if currentLanguage.isRTL {
            UIView.appearance().semanticContentAttribute = .forceRightToLeft
        } else {
            UIView.appearance().semanticContentAttribute = .forceLeftToRight
        }
    }

    /// Get localized string for the current language
    func localizedString(_ key: String, comment: String = "") -> String {
        guard let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            print("⚠️ Could not load bundle for language: \(currentLanguage.rawValue)")
            return NSLocalizedString(key, comment: comment)
        }
        let localizedString = bundle.localizedString(forKey: key, value: nil, table: nil)
        print("🌍 Localized '\(key)' to '\(localizedString)' for \(currentLanguage.rawValue)")
        return localizedString
    }
}

// Extension to use LanguageManager with Environment
extension EnvironmentValues {
    var languageManager: LanguageManager {
        get { LanguageManager.shared }
        set { }
    }
}

extension View {
    func environmentLanguage() -> some View {
        self.environment(\.layoutDirection, LanguageManager.shared.currentLanguage.isRTL ? .rightToLeft : .leftToRight)
    }
}
