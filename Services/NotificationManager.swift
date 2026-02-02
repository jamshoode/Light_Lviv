import Foundation
import UserNotifications
import Observation
import ActivityKit
import WidgetKit

@Observable
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
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
    var unreadChanges: Set<String> = []
    var unreadNewDayChanges: Set<String> = []
    var groupNicknames: [String: String] = [:]
    
    private override init() {
        super.init()
        loadSubscriptions()
    }
    
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
        updateSharedDataAndWidgets(for: group)
    }
    
    private func updateSharedDataAndWidgets(for group: ScheduleGroup) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        let todayKey = dateFormatter.string(from: Date())
        let tomorrowKey = dateFormatter.string(from: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
        
        let todayScheduleText = group.schedules[todayKey] ?? ""
        let tomorrowScheduleText = group.schedules[tomorrowKey] ?? ""
        
        let todaySchedules = parseScheduleToEntries(text: todayScheduleText)
        let tomorrowSchedules = parseScheduleToEntries(text: tomorrowScheduleText)
        
        let currentStatus = determineCurrentPowerStatus(from: todaySchedules)
        let nextEvent = calculateNextEvent(from: todaySchedules, currentStatus: currentStatus)
        
        SharedDataManager.shared.savePowerData(
            status: currentStatus,
            nextEvent: nextEvent,
            groupName: groupNicknames[group.id] ?? group.subGroupName,
            groupId: group.id,
            todaySchedules: todaySchedules,
            tomorrowSchedules: tomorrowSchedules
        )
        
        SharedDataManager.shared.reloadWidgetTimelines()
    }
    
    private func parseScheduleToEntries(text: String) -> [ScheduleEntry] {
        let ranges = ScheduleParser.shared.parse(text: text)
        var entries: [ScheduleEntry] = []
        
        for range in ranges {
            let startTime = String(format: "%02d:%02d", range.start.hour ?? 0, range.start.minute ?? 0)
            let endTime = String(format: "%02d:%02d", range.end.hour ?? 0, range.end.minute ?? 0)
            entries.append(ScheduleEntry(startTime: startTime, endTime: endTime, isPowerOn: false))
        }
        
        return entries
    }
    
    private func determineCurrentPowerStatus(from entries: [ScheduleEntry]) -> PowerStatus {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTimeValue = currentHour * 60 + currentMinute
        
        var isInOutage = false
        for entry in entries {
            let startComponents = entry.startTime.split(separator: ":").compactMap { Int($0) }
            let endComponents = entry.endTime.split(separator: ":").compactMap { Int($0) }
            
            guard startComponents.count == 2, endComponents.count == 2 else { continue }
            
            let startValue = startComponents[0] * 60 + startComponents[1]
            let endValue = endComponents[0] * 60 + endComponents[1]
            
            if currentTimeValue >= startValue && currentTimeValue < endValue {
                isInOutage = true
                break
            }
        }
        
        return isInOutage ? .off : .on
    }
    
    private func calculateNextEvent(from entries: [ScheduleEntry], currentStatus: PowerStatus) -> Date? {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTimeValue = currentHour * 60 + currentMinute
        
        for entry in entries {
            let startComponents = entry.startTime.split(separator: ":").compactMap { Int($0) }
            let endComponents = entry.endTime.split(separator: ":").compactMap { Int($0) }
            
            guard startComponents.count == 2, endComponents.count == 2 else { continue }
            
            let startValue = startComponents[0] * 60 + startComponents[1]
            let endValue = endComponents[0] * 60 + endComponents[1]
            
            if currentStatus == .on && currentTimeValue < startValue {
                return calendar.date(bySettingHour: startComponents[0], minute: startComponents[1], second: 0, of: now)
            } else if currentStatus == .off && currentTimeValue < endValue {
                return calendar.date(bySettingHour: endComponents[0], minute: endComponents[1], second: 0, of: now)
            }
        }
        
        return nil
    }
    
    func unsubscribe(group: ScheduleGroup) {
        subscribedGroups.remove(group.id)
        currentSchedules.removeValue(forKey: group.id)
        previousSchedules.removeValue(forKey: group.id)
        unreadChanges.remove(group.id)
        unreadNewDayChanges.remove(group.id)
        saveSubscriptions()
        
        removeNotifications(for: group)
        removePendingNotificationsForUnsubscribedGroups()
    }
    
    func checkForChanges(in newGroups: [ScheduleGroup]) {
        for group in newGroups {
            let oldSchedules = currentSchedules[group.id] ?? [:]
            let newSchedules = group.schedules
            
            if oldSchedules != newSchedules {
                let formatter = DateFormatter()
                formatter.dateFormat = "dd.MM.yyyy"
                let todayKey = formatter.string(from: Date())
                let tomorrowKey = formatter.string(from: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
                
                let todayChanged = (oldSchedules[todayKey] != newSchedules[todayKey])
                let tomorrowAdded = (oldSchedules[tomorrowKey] == nil && newSchedules[tomorrowKey] != nil)
                
                if todayChanged {
                    previousSchedules[group.id] = oldSchedules
                    unreadChanges.insert(group.id)
                    unreadNewDayChanges.remove(group.id)
                } else if tomorrowAdded {
                    unreadNewDayChanges.insert(group.id)
                } else {
                    previousSchedules[group.id] = oldSchedules
                    unreadChanges.insert(group.id)
                }
                
                if subscribedGroups.contains(group.id) {
                    if todayChanged || (!tomorrowAdded && !todayChanged) {
                        sendChangeNotification(for: group, type: .modified)
                    } else if tomorrowAdded {
                        sendChangeNotification(for: group, type: .newDay)
                    }
                    removeNotifications(for: group)
                    scheduleNotifications(for: group)
                }
                
                currentSchedules[group.id] = newSchedules
                saveSubscriptions()
            }
        }
    }
    
    enum ChangeNotificationType {
        case modified
        case newDay
    }
    
    private func sendChangeNotification(for group: ScheduleGroup, type: ChangeNotificationType) {
        let content = UNMutableNotificationContent()
        let notificationType: String

        switch type {
        case .modified:
            notificationType = "scheduleChanged"
            content.title = Localization.get("scheduleChangedTitle")
            content.body = String(format: Localization.get("scheduleChangedBody"), group.subGroupName)
        case .newDay:
            notificationType = "newDay"
            content.title = Localization.get("scheduleTomorrowTitle")
            content.body = String(format: Localization.get("scheduleTomorrowBody"), group.subGroupName)
        }
        
        content.sound = .default
        content.userInfo = [
            "groupId": group.id,
            "groupName": group.subGroupName,
            "notificationType": notificationType
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                return
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    private func scheduleNotifications(for group: ScheduleGroup) {
        for (dateStr, text) in group.schedules {
            let ranges = ScheduleParser.shared.parse(text: text)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy"
            guard let date = dateFormatter.date(from: dateStr) else { continue }
            
            let calendar = Calendar.current
            let dayComponents = calendar.dateComponents([.year, .month, .day], from: date)
            
            for range in ranges {
                scheduleEvent(group: group, time: range.start, dayComponents: dayComponents, type: .powerOff)
                scheduleEvent(group: group, time: range.end, dayComponents: dayComponents, type: .powerOn)
            }
        }
    }
    
    private func removeNotifications(for group: ScheduleGroup) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let idsToRemove = requests.filter { $0.identifier.starts(with: "Group_\(group.subGroupName)_") }.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: idsToRemove)
        }
    }
    
    func removePendingNotificationsForUnsubscribedGroups() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] requests in
            guard let self = self else { return }
            
            let idsToRemove = requests.compactMap { request -> String? in
                if let groupName = request.content.userInfo["groupName"] as? String {
                    let groupId = self.groupNicknames.first(where: { $0.value == groupName })?.key ?? groupName
                    if !self.subscribedGroups.contains(groupId) {
                        return request.identifier
                    }
                }
                return nil
            }
            
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
    
    private func scheduleEvent(group: ScheduleGroup, time: DateComponents, dayComponents: DateComponents, type: EventType) {
        let calendar = Calendar.current
        var components = dayComponents
        components.hour = time.hour
        components.minute = time.minute
        
        guard let eventDate = calendar.date(from: components) else { return }
        let now = Date()
        
        if let notifyDate = calendar.date(byAdding: .minute, value: -15, to: eventDate), notifyDate >= now {
            let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notifyDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            
            let content = UNMutableNotificationContent()
            content.title = type.title
            content.body = String(format: type.bodyTemplate, group.subGroupName)
            content.sound = .default
            content.userInfo = [
                "groupId": group.id,
                "groupName": group.subGroupName,
                "notificationType": "preEvent",
                "isPowerOff": type == .powerOff,
                "eventDate": eventDate.timeIntervalSince1970
            ]
            
            let id = "Group_\(group.subGroupName)_\(type)_\(dayComponents.year!)-\(dayComponents.month!)-\(dayComponents.day!)_\(time.hour!)_\(time.minute!)"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                }
            }
        } else if eventDate > now {
            let content = UNMutableNotificationContent()
            content.title = type.title
            content.body = String(format: type.bodyTemplate, group.subGroupName)
            content.sound = .default
            content.userInfo = [
                "groupId": group.id,
                "groupName": group.subGroupName,
                "notificationType": "preEvent",
                "isPowerOff": type == .powerOff,
                "eventDate": eventDate.timeIntervalSince1970
            ]
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        let groupId = userInfo["groupId"] as? String ?? "unknown"
        let groupName = userInfo["groupName"] as? String ?? "unknown"
        let notificationType = userInfo["notificationType"] as? String ?? "preEvent"
        
        let type: NotificationType
        switch notificationType {
        case "scheduleChanged":
            type = .scheduleChanged
        case "newDay":
            type = .tomorrowAdded
        case "preEvent":
            let isPowerOff = userInfo["isPowerOff"] as? Bool ?? true
            type = isPowerOff ? .prePowerOff : .prePowerOn
        default:
            type = .prePowerOff
        }
        
        if self.subscribedGroups.contains(groupId) {
            let item = NotificationItem(
                type: type,
                groupId: groupId,
                groupName: groupName,
                scheduledTime: Date(),
                message: notification.request.content.body
            )
            
            NotificationHistoryService.shared.addNotification(item)
        }
        
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let groupId = userInfo["groupId"] as? String ?? "unknown"
        let groupName = userInfo["groupName"] as? String ?? "unknown"
        let notificationType = userInfo["notificationType"] as? String ?? "preEvent"
        
        let type: NotificationType
        switch notificationType {
        case "scheduleChanged":
            type = .scheduleChanged
        case "newDay":
            type = .tomorrowAdded
        case "preEvent":
            let isPowerOff = userInfo["isPowerOff"] as? Bool ?? true
            type = isPowerOff ? .prePowerOff : .prePowerOn
        default:
            type = .prePowerOff
        }
        
        if self.subscribedGroups.contains(groupId) {
            let item = NotificationItem(
                type: type,
                groupId: groupId,
                groupName: groupName,
                message: response.notification.request.content.body
            )
            
            NotificationHistoryService.shared.addNotification(item)
        }
        
        completionHandler()
    }
    
    func sendNotificationTest() {
        let notificationContent = UNMutableNotificationContent()
        
        let testGroupId = "1.1"
        let testGroupName = "1.1"
        
        notificationContent.title = "Test Notification"
        notificationContent.body = String(format: Localization.get("scheduleTomorrowBody"), testGroupName)
        notificationContent.userInfo = [
            "groupId": testGroupId,
            "groupName": testGroupName,
            "notificationType": "newDay"
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: notificationContent, trigger: trigger)
        
        UNUserNotificationCenter.current().add(req)
    }
    
    @MainActor
    func processDeliveredNotifications() {
        UNUserNotificationCenter.current().getDeliveredNotifications { [weak self] notifications in
            guard let self = self else { return }
            
            let existingIds = Set(NotificationHistoryService.shared.notifications.map { $0.id })
            
            for notification in notifications {
                let userInfo = notification.request.content.userInfo
                let groupId = userInfo["groupId"] as? String ?? "unknown"
                let groupName = userInfo["groupName"] as? String ?? "unknown"
                let notificationType = userInfo["notificationType"] as? String ?? "preEvent"
                
                let type: NotificationType
                switch notificationType {
                case "scheduleChanged":
                    type = .scheduleChanged
                case "newDay":
                    type = .tomorrowAdded
                case "preEvent":
                    let isPowerOff = userInfo["isPowerOff"] as? Bool ?? true
                    type = isPowerOff ? .prePowerOff : .prePowerOn
                default:
                    type = .prePowerOff
                }
                
                if self.subscribedGroups.contains(groupId) {
                    let item = NotificationItem(
                        type: type,
                        groupId: groupId,
                        groupName: groupName,
                        message: notification.request.content.body
                    )
                    
                    if !existingIds.contains(item.id) {
                        Task { @MainActor in
                            NotificationHistoryService.shared.addNotification(item)
                        }
                    }
                }
            }
            
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        }
    }
}

extension NotificationManager {
    func startLiveActivity(for group: ScheduleGroup, nextEvent: Date, isPowerOn: Bool) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let eventType: EventType = isPowerOn ? .powerOff : .powerOn
        let attributes = PowerOutageAttributes(
            groupName: groupNicknames[group.id] ?? group.subGroupName,
            targetTime: nextEvent,
            eventType: eventType
        )
        
        let initialState = PowerOutageAttributes.ContentState(
            isPowerOn: isPowerOn,
            minutesUntilChange: 15,
            progress: 0.0
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                contentState: initialState,
                pushType: nil
            )
            print("Started Live Activity: \(activity.id)")
        } catch {
            print("Error starting Live Activity: \(error)")
        }
    }
    
    func updateLiveActivity(minutesRemaining: Int, progress: Double) {
        Task {
            for activity in Activity<PowerOutageAttributes>.activities {
                let isPowerOn = activity.attributes.eventType == .powerOn
                let newState = PowerOutageAttributes.ContentState(
                    isPowerOn: isPowerOn,
                    minutesUntilChange: minutesRemaining,
                    progress: progress
                )
                await activity.update(using: newState)
            }
        }
    }
    
    func endLiveActivity() {
        Task {
            for activity in Activity<PowerOutageAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
    }
    
    func endLiveActivity(for groupId: String) {
        Task {
            for activity in Activity<PowerOutageAttributes>.activities {
                let groupName = groupNicknames[groupId] ?? groupId
                if activity.attributes.groupName == groupName {
                    await activity.end(dismissalPolicy: .immediate)
                }
            }
        }
    }
}
