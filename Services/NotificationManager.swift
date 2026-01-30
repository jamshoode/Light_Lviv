import Foundation
import UserNotifications
import Observation

@Observable
class NotificationManager {
    static let shared = NotificationManager()
    
    private let saveKey = "SubscribedGroupIDs"
    private let scheduleSaveKey = "LastKnownSchedules"
    private let previousScheduleSaveKey = "PreviousSchedules"
    private let unreadSaveKey = "UnreadChangesIDs"
    private let unreadNewDaySaveKey = "UnreadNewDayIDs"
    private let nicknamesSaveKey = "GroupNicknames"
    
    var subscribedGroups: Set<String> = []
    var currentSchedules: [String: [String: String]] = [:]
    var previousSchedules: [String: [String: String]] = [:]
    var unreadChanges: Set<String> = []   // Modified (Diff)
    var unreadNewDayChanges: Set<String> = [] // Only tomorrow added
    var groupNicknames: [String: String] = [:] // GroupID -> Nickname
    
    private init() {
        loadSubscriptions()
    }
    
    // MARK: - Persistence
    
    private func saveSubscriptions() {
        let array = Array(subscribedGroups)
        UserDefaults.standard.set(array, forKey: saveKey)
        UserDefaults.standard.set(currentSchedules, forKey: scheduleSaveKey)
        UserDefaults.standard.set(previousSchedules, forKey: previousScheduleSaveKey)
        UserDefaults.standard.set(Array(unreadChanges), forKey: unreadSaveKey)
        UserDefaults.standard.set(Array(unreadNewDayChanges), forKey: unreadNewDaySaveKey)
        UserDefaults.standard.set(groupNicknames, forKey: nicknamesSaveKey)
    }
    
    private func loadSubscriptions() {
        if let array = UserDefaults.standard.array(forKey: saveKey) as? [String] {
            subscribedGroups = Set(array)
        }
        if let dict = UserDefaults.standard.dictionary(forKey: scheduleSaveKey) as? [String: [String: String]] {
            currentSchedules = dict
        }
        if let dict = UserDefaults.standard.dictionary(forKey: previousScheduleSaveKey) as? [String: [String: String]] {
            previousSchedules = dict
        }
        if let array = UserDefaults.standard.array(forKey: unreadSaveKey) as? [String] {
            unreadChanges = Set(array)
        }
        if let array = UserDefaults.standard.array(forKey: unreadNewDaySaveKey) as? [String] {
            unreadNewDayChanges = Set(array)
        }
        if let dict = UserDefaults.standard.dictionary(forKey: nicknamesSaveKey) as? [String: String] {
            groupNicknames = dict
        }
    }
    
    func getNickname(for group: ScheduleGroup) -> String? {
        return groupNicknames[group.id]
    }
    
    func setNickname(_ name: String, for group: ScheduleGroup) {
        if name.isEmpty {
            groupNicknames.removeValue(forKey: group.id)
        } else {
            groupNicknames[group.id] = name
        }
        saveSubscriptions()
    }
    
    func isSubscribed(group: ScheduleGroup) -> Bool {
        return subscribedGroups.contains(group.id)
    }
    
    func hasUnreadChanges(group: ScheduleGroup) -> Bool {
        return unreadChanges.contains(group.id)
    }
    
    func hasUnreadNewDay(group: ScheduleGroup) -> Bool {
        return unreadNewDayChanges.contains(group.id)
    }
    
    func hasPreviousSchedule(group: ScheduleGroup) -> Bool {
        return previousSchedules[group.id] != nil
    }
    
    func markAsRead(group: ScheduleGroup) {
        if unreadChanges.contains(group.id) {
            unreadChanges.remove(group.id)
            saveSubscriptions()
        }
        if unreadNewDayChanges.contains(group.id) {
            unreadNewDayChanges.remove(group.id)
            saveSubscriptions()
        }
    }
    
    func subscribe(group: ScheduleGroup) {
        subscribedGroups.insert(group.id)
        currentSchedules[group.id] = group.schedules
        saveSubscriptions()
        scheduleNotifications(for: group)
    }
    
    func unsubscribe(group: ScheduleGroup) {
        subscribedGroups.remove(group.id)
        currentSchedules.removeValue(forKey: group.id)
        previousSchedules.removeValue(forKey: group.id)
        unreadChanges.remove(group.id)
        unreadNewDayChanges.remove(group.id)
        saveSubscriptions()
        // Remove pending notifications for this group
        removeNotifications(for: group)
    }
    
    func checkForChanges(in newGroups: [ScheduleGroup]) {
        for group in newGroups {
            guard subscribedGroups.contains(group.id) else { continue }
            
            let oldSchedules = currentSchedules[group.id] ?? [:]
            let newSchedules = group.schedules
            
            // Check if changed
            if oldSchedules != newSchedules {
                print("Schedule changed for group \(group.id)")
                
                // Determine change type
                let formatter = DateFormatter()
                formatter.dateFormat = "dd.MM.yyyy"
                let todayKey = formatter.string(from: Date())
                // Calculate tomorrow key more safely
                let tomorrowKey = formatter.string(from: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
                
                let todayChanged = (oldSchedules[todayKey] != newSchedules[todayKey])
                let tomorrowAdded = (oldSchedules[tomorrowKey] == nil && newSchedules[tomorrowKey] != nil)
                
                // Prioritize "Today Changed" as it's more critical and requires Diff UI
                if todayChanged {
                    previousSchedules[group.id] = oldSchedules
                    unreadChanges.insert(group.id)
                    // Clear new day flag if it was set, today change overrides it UI wise (or we keep both? let's stick to diff priority)
                    unreadNewDayChanges.remove(group.id)
                    sendChangeNotification(for: group, type: .modified)
                } else if tomorrowAdded {
                    // Just tomorrow added
                    unreadNewDayChanges.insert(group.id)
                    sendChangeNotification(for: group, type: .newDay)
                } else {
                    // Some other change (maybe yesterday removed or distant future)
                    // Treat as diff fallback
                    previousSchedules[group.id] = oldSchedules
                    unreadChanges.insert(group.id)
                    sendChangeNotification(for: group, type: .modified)
                }
                
                // Update current
                currentSchedules[group.id] = newSchedules
                
                // Save
                saveSubscriptions()
                
                // Re-schedule alarms
                removeNotifications(for: group)
                scheduleNotifications(for: group)
            }
        }
    }
    
    enum ChangeNotificationType {
        case modified
        case newDay
    }
    
    private func sendChangeNotification(for group: ScheduleGroup, type: ChangeNotificationType) {
        let content = UNMutableNotificationContent()
        
        switch type {
        case .modified:
            content.title = Localization.get("scheduleChangedTitle")
            content.body = String(format: Localization.get("scheduleChangedBody"), group.subGroupName)
        case .newDay:
            content.title = Localization.get("scheduleTomorrowTitle")
            content.body = String(format: Localization.get("scheduleTomorrowBody"), group.subGroupName)
        }
        
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Scheduling
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    /// Schedules notifications for a specific group based on its text
    private func scheduleNotifications(for group: ScheduleGroup) {
        for (dateStr, text) in group.schedules {
            // Use ScheduleParser
            let ranges = ScheduleParser.shared.parse(text: text)
            
            // Parse dateStr "dd.MM.yyyy"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy"
            guard let date = dateFormatter.date(from: dateStr) else { continue }
            
            let calendar = Calendar.current
            let dayComponents = calendar.dateComponents([.year, .month, .day], from: date)
            
            for range in ranges {
                scheduleEvent(groupName: group.subGroupName, time: range.start, dayComponents: dayComponents, type: .powerOff)
                scheduleEvent(groupName: group.subGroupName, time: range.end, dayComponents: dayComponents, type: .powerOn)
            }
        }
    }
    
    private func removeNotifications(for group: ScheduleGroup) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let idsToRemove = requests.filter { $0.identifier.starts(with: "Group_\(group.subGroupName)_") }.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: idsToRemove)
        }
    }
    
    enum EventType {
        case powerOff
        case powerOn
        
        var title: String {
            switch self {
            case .powerOff: return Localization.get("powerOff_title")
            case .powerOn: return Localization.get("powerOn_title")
            }
        }
        
        var bodyTemplate: String {
            switch self {
            case .powerOff: return Localization.get("powerOff_body")
            case .powerOn: return Localization.get("powerOn_body")
            }
        }
    }
    
    private func scheduleEvent(groupName: String, time: DateComponents, dayComponents: DateComponents, type: EventType) {
        let calendar = Calendar.current
        var components = dayComponents
        components.hour = time.hour
        components.minute = time.minute
        
        guard let eventDate = calendar.date(from: components) else { return }
        
        // Subtract 15 minutes
        guard let notifyDate = calendar.date(byAdding: .minute, value: -15, to: eventDate) else { return }
        
        // Only schedule future notifications (notifyDate must be >= current date)
        if notifyDate >= Date() {
            let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notifyDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            
            let content = UNMutableNotificationContent()
            content.title = type.title
            content.body = String(format: type.bodyTemplate, groupName)
            content.sound = .default
            
            let id = "Group_\(groupName)_\(type)_\(dayComponents.year!)-\(dayComponents.month!)-\(dayComponents.day!)_\(time.hour!)_\(time.minute!)"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                } else {
                     // Helpful debug
                    // print("Scheduled \(type) for Group \(groupName) at \(triggerComponents.hour!):\(triggerComponents.minute!)")
                }
            }
        }
    }
}
