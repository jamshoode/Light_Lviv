import SwiftUI
import WidgetKit

struct PowerStatusEntry: TimelineEntry {
    let date: Date
    let isPowerOn: Bool
    let nextEvent: Date?
    let groupName: String
    let todaySchedules: [ScheduleEntry]
    let tomorrowSchedules: [ScheduleEntry]
    let lastUpdated: Date
}

struct SmallWidgetView: View {
    var entry: PowerStatusEntry
    
    private var minutesRemaining: Int? {
        guard let nextEvent = entry.nextEvent else { return nil }
        let diff = nextEvent.timeIntervalSince(entry.date)
        return max(0, Int(diff / 60))
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: entry.isPowerOn ? "bolt.fill" : "poweroutlet.type.b.fill")
                .font(.system(size: 40))
                .foregroundStyle(entry.isPowerOn ? Color(red: 0.204, green: 0.78, blue: 0.349) : Color(red: 1, green: 0.231, blue: 0.188))
            
            if let minutes = minutesRemaining, minutes > 0 {
                Text(entry.isPowerOn ? "OFF in \(minutes)m" : "ON in \(minutes)m")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            } else {
                Text(entry.isPowerOn ? "ON" : "OFF")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color(red: 0.553, green: 0.553, blue: 0.576))
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color.black, Color.black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

#Preview(as: .systemSmall) {
    SmallWidgetView(entry: PowerStatusEntry(
        date: Date(),
        isPowerOn: true,
        nextEvent: Date().addingTimeInterval(720),
        groupName: "1.1",
        todaySchedules: [],
        tomorrowSchedules: [],
        lastUpdated: Date()
    ))
}
