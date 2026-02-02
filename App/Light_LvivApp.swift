import SwiftUI
import ActivityKit
import UserNotifications

@main
struct Light_LvivApp: App {
    init() {
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        NotificationManager.shared.processDeliveredNotifications()
        NotificationManager.shared.removePendingNotificationsForUnsubscribedGroups()
        configureLiveActivities()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func configureLiveActivities() {
        if #available(iOS 16.1, *) {
            let info = ActivityAuthorizationInfo()
            print("Live Activities enabled: \(info.areActivitiesEnabled)")
        }
    }
}
