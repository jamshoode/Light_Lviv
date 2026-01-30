import SwiftUI

@main
struct Light_LvivApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                
                NotificationsTabView()
                    .tabItem {
                        Label("Notifications", systemImage: "bell.fill")
                    }
            }
        }
    }
}
