import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            ShoppingListsView()
                .tabItem {
                    Label("Lists", systemImage: "cart.fill")
                }
                .tag(1)

            ItemsView()
                .tabItem {
                    Label("Items", systemImage: "cube.box.fill")
                }
                .tag(2)

            BudgetView()
                .tabItem {
                    Label("Budget", systemImage: "chart.pie.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(Color.accentColor)
    }
}

#Preview {
    MainTabView()
}
