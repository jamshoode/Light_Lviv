import Foundation
import Observation

@Observable
class NotificationHistoryService {
    static let shared = NotificationHistoryService()
    
    private let maxCount = 5
    private let saveKey = "NotificationHistory"
    
    var notifications: [NotificationItem] = []
    
    init() {
        loadNotifications()
    }
    
    var isEmpty: Bool {
        return notifications.isEmpty
    }
    
    var displayNotifications: [NotificationItem] {
        return notifications
    }

    func addNotification(_ item: NotificationItem) {
        notifications.insert(item, at: 0)
        
        // Ring buffer: keep only maxCount notifications
        if notifications.count > maxCount {
            notifications = Array(notifications.prefix(maxCount))
        }
        
        saveNotifications()
    }
    
    func getNotifications() -> [NotificationItem] {
        return notifications
    }
    
    func clearHistory() {
        notifications.removeAll()
        UserDefaults.standard.removeObject(forKey: saveKey)
    }
    
    private func saveNotifications() {
        if let data = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }
    
    private func loadNotifications() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let loaded = try? JSONDecoder().decode([NotificationItem].self, from: data) {
            notifications = loaded
        }
    }
}
