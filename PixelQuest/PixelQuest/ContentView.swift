import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            QuestsView()
                .tabItem {
                    VStack {
                        Image(systemName: "scroll.fill")
                        Text("tab_quests".localized)
                    }
                }
                .tag(0)
            
            MapView()
                .tabItem {
                    VStack {
                        Image(systemName: "map.fill")
                        Text("tab_map".localized)
                    }
                }
                .tag(1)
            
            ItemsView()
                .tabItem {
                    VStack {
                        Image(systemName: "archivebox.fill")
                        Text("tab_items".localized)
                    }
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    VStack {
                        Image(systemName: "gearshape.fill")
                        Text("tab_settings".localized)
                    }
                }
                .tag(3)
        }
        .tint(Color("PixelAccent"))
        .id(localizationManager.currentLanguage) // Force refresh on language change
        .onAppear {
            // Style the tab bar with pixel aesthetic
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(named: "PixelBg")
            
            // Add border effect
            UITabBar.appearance().layer.borderWidth = 2
            UITabBar.appearance().layer.borderColor = UIColor(named: "PixelBorder")?.cgColor
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(QuestStore())
        .environmentObject(ItemStore())
        .environmentObject(LogStore())
}
