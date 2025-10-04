import SwiftUI

struct SettingsView: View {
    @AppStorage("householdSize") private var householdSize = 1
    @AppStorage("notifications") private var notificationsEnabled = true
    @AppStorage("darkMode") private var darkModeEnabled = false

    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    Stepper("Household Size: \(householdSize)", value: $householdSize, in: 1...10)

                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                }

                Section("Appearance") {
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                }

                Section("ML Models") {
                    NavigationLink {
                        MLModelSettingsView()
                    } label: {
                        Label("ML Settings", systemImage: "brain")
                    }

                    Button {
                        warmupModels()
                    } label: {
                        Label("Warmup Models", systemImage: "flame")
                    }
                }

                Section("Data") {
                    NavigationLink {
                        DataManagementView()
                    } label: {
                        Label("Data Management", systemImage: "externaldrive")
                    }

                    Button(role: .destructive) {
                        clearCache()
                    } label: {
                        Label("Clear Cache", systemImage: "trash")
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Build", value: "100")

                    Link(destination: URL(string: "https://github.com")!) {
                        Label("GitHub Repository", systemImage: "link")
                    }
                }
            }
            .navigationTitle("Settings")
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
            Section("Prediction Settings") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confidence Threshold")
                        .font(.headline)
                    Text("Minimum confidence level for predictions")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Slider(value: $confidenceThreshold, in: 0.5...0.95, step: 0.05)

                    Text("\(Int(confidenceThreshold * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Models") {
                LabeledContent("Shopping List Generator", value: "Active")
                LabeledContent("Purchase Predictor", value: "Active")
                LabeledContent("Price Optimizer", value: "Active")
                LabeledContent("Expiration Predictor", value: "Active")
            }
        }
        .navigationTitle("ML Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataManagementView: View {
    var body: some View {
        Form {
            Section("Export") {
                Button {
                    exportData()
                } label: {
                    Label("Export All Data", systemImage: "square.and.arrow.up")
                }
            }

            Section("Import") {
                Button {
                    importData()
                } label: {
                    Label("Import Data", systemImage: "square.and.arrow.down")
                }
            }

            Section(header: Text("Danger Zone"), footer: Text("This action cannot be undone")) {
                Button(role: .destructive) {
                    deleteAllData()
                } label: {
                    Label("Delete All Data", systemImage: "trash.fill")
                }
            }
        }
        .navigationTitle("Data Management")
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

#Preview {
    SettingsView()
}
