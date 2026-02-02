import WidgetKit
import SwiftUI

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
    
    init(status: PowerStatus, nextEventDate: Date?, groupName: String, groupId: String, todaySchedules: [ScheduleEntry], tomorrowSchedules: [ScheduleEntry], lastUpdated: Date) {
        self.status = status
        self.nextEventDate = nextEventDate
        self.groupName = groupName
        self.groupId = groupId
        self.todaySchedules = todaySchedules
        self.tomorrowSchedules = tomorrowSchedules
        self.lastUpdated = lastUpdated
    }
}

struct PowerStatusEntry: TimelineEntry {
    let date: Date
    let isPowerOn: Bool
    let nextEvent: Date?
    let groupName: String
    let todaySchedules: [ScheduleEntry]
    let tomorrowSchedules: [ScheduleEntry]
    let lastUpdated: Date
    
    init(date: Date, isPowerOn: Bool, nextEvent: Date?, groupName: String, todaySchedules: [ScheduleEntry], tomorrowSchedules: [ScheduleEntry], lastUpdated: Date) {
        self.date = date
        self.isPowerOn = isPowerOn
        self.nextEvent = nextEvent
        self.groupName = groupName
        self.todaySchedules = todaySchedules
        self.tomorrowSchedules = tomorrowSchedules
        self.lastUpdated = lastUpdated
    }
}

struct ScheduleEntry: Codable, Identifiable {
    let id: UUID
    let startTime: String
    let endTime: String
    let isPowerOn: Bool
    
    init(startTime: String, endTime: String, isPowerOn: Bool) {
        self.id = UUID()
        self.startTime = startTime
        self.endTime = endTime
        self.isPowerOn = isPowerOn
    }
}
