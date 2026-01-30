import Foundation

enum NotificationType: String, Codable {
    case prePowerOff      // 15 min before power goes OFF
    case prePowerOn       // 15 min before power comes ON
    case scheduleChanged  // Schedule changed after rescraping
}

struct NotificationItem: Codable, Identifiable {
    let id: UUID
    let type: NotificationType
    let groupId: String
    let groupName: String
    let scheduledTime: Date?  // For pre-event notifications
    let timestamp: Date       // When notification was created
    let message: String
    
    init(
        id: UUID = UUID(),
        type: NotificationType,
        groupId: String,
        groupName: String,
        scheduledTime: Date? = nil,
        timestamp: Date = Date(),
        message: String
    ) {
        self.id = id
        self.type = type
        self.groupId = groupId
        self.groupName = groupName
        self.scheduledTime = scheduledTime
        self.timestamp = timestamp
        self.message = message
    }
}

extension NotificationItem {
    static var example: NotificationItem {
        NotificationItem(
            type: .scheduleChanged,
            groupId: "1.1",
            groupName: "1.1",
            message: "Schedule has been updated"
        )
    }
    
    static var examplePrePowerOff: NotificationItem {
        NotificationItem(
            type: .prePowerOff,
            groupId: "2.1",
            groupName: "2.1",
            scheduledTime: Date().addingTimeInterval(15 * 60),
            message: "Power will be OFF in 15 minutes"
        )
    }
}
