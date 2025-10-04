import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label(L10n.Tab.home, systemImage: "house.fill")
                }
                .tag(0)

            ShoppingListsView()
                .tabItem {
                    Label(L10n.Tab.lists, systemImage: "cart.fill")
                }
                .tag(1)

            ItemsView()
                .tabItem {
                    Label(L10n.Tab.items, systemImage: "cube.box.fill")
                }
                .tag(2)

            BudgetView()
                .tabItem {
                    Label(L10n.Tab.budget, systemImage: "chart.pie.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label(L10n.Tab.settings, systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(Color.accentColor)
        .environment(\.layoutDirection, languageManager.currentLanguage.isRTL ? .rightToLeft : .leftToRight)
        .id(languageManager.currentLanguage.rawValue) // Force view refresh when language changes
    }
}

#Preview {
    MainTabView()
}
