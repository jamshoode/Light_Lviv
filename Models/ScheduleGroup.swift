import Foundation

struct ScheduleGroup: Hashable, Identifiable, Codable {
    let id: String
    let subGroupName: String
    let schedules: [String: String]
    let lastUpdateTimestamp: String?
    var customName: String?
    
    var scheduleText: String {
        schedules.values.first ?? ""
    }
    
    static var example: ScheduleGroup {
        ScheduleGroup(id: "1.1", subGroupName: "1.1", schedules: ["26.01.2026": "00:00 - 04:00\n12:00 - 16:00"], lastUpdateTimestamp: "12:00 26.01.2026")
    }
}
