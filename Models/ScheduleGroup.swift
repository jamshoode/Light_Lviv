import Foundation

struct ScheduleGroup: Hashable, Identifiable, Codable {
    let id: String
    let subGroupName: String
    let schedules: [String: String] // Date -> Schedule Text
    let lastUpdateTimestamp: String? // "18:05 25.01.2026"
    var customName: String? // User defined nickname
    
    // Helper to get today's schedule or first available
    var scheduleText: String {
        // This is a fallback/convenience.
        // In the new UI we will select specific date.
        // For grid item (preview), maybe show today's or just "Multi-day"?
        // Let's return the first one sorted by date, or empty.
        // In reality, we probably want "today" if exists.
        
        // Simple logic: return values joined or just one.
        // Let's return the first available for now to keep things compiling if accessed.
        return schedules.values.first ?? ""
    }
    
    static var example: ScheduleGroup {
        ScheduleGroup(id: "1.1", subGroupName: "1.1", schedules: ["26.01.2026": "00:00 - 04:00\n12:00 - 16:00"], lastUpdateTimestamp: "12:00 26.01.2026")
    }
}
