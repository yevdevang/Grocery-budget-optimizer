import SwiftUI

struct SettingsView: View {
    @AppStorage("householdSize") private var householdSize = 1
    @AppStorage("notifications") private var notificationsEnabled = true
    @AppStorage("darkMode") private var darkModeEnabled = false
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var showingLanguagePicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.Settings.general) {
                    Stepper("\(L10n.Settings.householdSize): \(householdSize)", value: $householdSize, in: 1...10)

                    Toggle(L10n.Settings.enableNotifications, isOn: $notificationsEnabled)
                }

                Section(L10n.Settings.preferences) {
                    NavigationLink {
                        LanguagePickerView()
                    } label: {
                        HStack {
                            Label(L10n.Settings.language, systemImage: "globe")
                            Spacer()
                            Text("\(languageManager.currentLanguage.flag) \(languageManager.currentLanguage.displayName)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section(L10n.Settings.appearance) {
                    Toggle(L10n.Settings.darkMode, isOn: $darkModeEnabled)
                }

                Section(L10n.Settings.mlModels) {
                    NavigationLink {
                        MLModelSettingsView()
                    } label: {
                        Label(L10n.Settings.mlSettings, systemImage: "brain")
                    }

                    Button {
                        warmupModels()
                    } label: {
                        Label(L10n.Settings.warmupModels, systemImage: "flame")
                    }
                }

                Section(L10n.Settings.data) {
                    NavigationLink {
                        DataManagementView()
                    } label: {
                        Label(L10n.Settings.dataManagement, systemImage: "externaldrive")
                    }

                    Button(role: .destructive) {
                        clearCache()
                    } label: {
                        Label(L10n.Settings.clearCache, systemImage: "trash")
                    }
                }

                Section(L10n.Settings.about) {
                    LabeledContent(L10n.Settings.version, value: "1.0.0")
                    LabeledContent(L10n.Settings.build, value: "100")

                    Link(destination: URL(string: "https://github.com")!) {
                        Label(L10n.Settings.githubRepo, systemImage: "link")
                    }
                }
            }
            .navigationTitle(L10n.Settings.title)
        }
    }

    private func warmupModels() {
        MLCoordinator.shared.warmupModels()
    }

    private func clearCache() {
        // Clear cache logic
    }
}

struct MLModelSettingsView: View {
    @AppStorage("confidenceThreshold") private var confidenceThreshold = 0.7

    var body: some View {
        Form {
            Section(L10n.Settings.predictionSettings) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.Settings.confidenceThreshold)
                        .font(.headline)
                    Text(L10n.Settings.confidenceDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Slider(value: $confidenceThreshold, in: 0.5...0.95, step: 0.05)

                    Text("\(Int(confidenceThreshold * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section(L10n.Settings.models) {
                LabeledContent(L10n.Settings.shoppingListGenerator, value: L10n.Settings.modelActive)
                LabeledContent(L10n.Settings.purchasePredictor, value: L10n.Settings.modelActive)
                LabeledContent(L10n.Settings.priceOptimizer, value: L10n.Settings.modelActive)
                LabeledContent(L10n.Settings.expirationPredictor, value: L10n.Settings.modelActive)
            }
        }
        .navigationTitle(L10n.Settings.mlSettings)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataManagementView: View {
    var body: some View {
        Form {
            Section(L10n.Settings.export) {
                Button {
                    exportData()
                } label: {
                    Label(L10n.Settings.exportAllData, systemImage: "square.and.arrow.up")
                }
            }

            Section(L10n.Settings.import) {
                Button {
                    importData()
                } label: {
                    Label(L10n.Settings.importData, systemImage: "square.and.arrow.down")
                }
            }

            Section(header: Text(L10n.Settings.dangerZone), footer: Text(L10n.Settings.dangerWarning)) {
                Button(role: .destructive) {
                    deleteAllData()
                } label: {
                    Label(L10n.Settings.deleteAllData, systemImage: "trash.fill")
                }
            }
        }
        .navigationTitle(L10n.Settings.dataManagement)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func exportData() {
        // Export data logic
    }

    private func importData() {
        // Import data logic
    }

    private func deleteAllData() {
        // Delete all data logic
    }
}

struct LanguagePickerView: View {
    @ObservedObject private var languageManager = LanguageManager.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            ForEach(Language.allCases) { language in
                Button(action: {
                    languageManager.currentLanguage = language
                    // Give a moment for the change to register, then dismiss
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        dismiss()
                    }
                }) {
                    HStack {
                        Text(language.flag)
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(language.displayName)
                                .font(.headline)

                            if language.isRTL {
                                Text(L10n.Settings.rightToLeft)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        if languageManager.currentLanguage == language {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                                .fontWeight(.semibold)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle(L10n.Settings.language)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
}
