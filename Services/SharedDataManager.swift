import Foundation
import WidgetKit

enum PowerStatus: String, Codable {
    case on
    case off
}

struct WidgetPowerData: Codable {
    let status: PowerStatus
    let nextEventDate: Date?
    let groupName: String
    let groupId: String
    let todaySchedules: [ScheduleEntry]
    let tomorrowSchedules: [ScheduleEntry]
    let lastUpdated: Date
}

struct ScheduleEntry: Codable, Identifiable {
    let id = UUID()
    let startTime: String
    let endTime: String
    let isPowerOn: Bool
}

class SharedDataManager {
    static let shared = SharedDataManager()
    private let defaults = UserDefaults(suiteName: "group.com.shoode.Light-Lviv")
    private let widgetDataKey = "widgetPowerData"
    private let selectedGroupIdKey = "selectedWidgetGroupId"
    
    func savePowerData(status: PowerStatus, nextEvent: Date?, groupName: String, groupId: String, todaySchedules: [ScheduleEntry], tomorrowSchedules: [ScheduleEntry]) {
        let data = WidgetPowerData(
            status: status,
            nextEventDate: nextEvent,
            groupName: groupName,
            groupId: groupId,
            todaySchedules: todaySchedules,
            tomorrowSchedules: tomorrowSchedules,
            lastUpdated: Date()
        )
        
        if let encoded = try? JSONEncoder().encode(data) {
            defaults?.set(encoded, forKey: widgetDataKey)
        }
    }
    
    func loadPowerData() -> WidgetPowerData? {
        guard let data = defaults?.data(forKey: widgetDataKey),
              let decoded = try? JSONDecoder().decode(WidgetPowerData.self, from: data) else {
            return nil
        }
        return decoded
    }
    
    func saveSelectedGroupId(_ groupId: String) {
        defaults?.set(groupId, forKey: selectedGroupIdKey)
    }
    
    func loadSelectedGroupId() -> String? {
        return defaults?.string(forKey: selectedGroupIdKey)
    }
    
    func reloadWidgetTimelines() {
        WidgetCenter.shared.reloadTimelines(ofKind: "Light_LvivWidget")
    }
}
