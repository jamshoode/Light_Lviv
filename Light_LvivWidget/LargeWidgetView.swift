import SwiftUI
import WidgetKit

struct LargeWidgetView: View {
    var entry: PowerStatusEntry
    
    private var minutesRemaining: Int? {
        guard let nextEvent = entry.nextEvent else { return nil }
        let diff = nextEvent.timeIntervalSince(entry.date)
        return max(0, Int(diff / 60))
    }
    
    private var formattedLastUpdated: String {
        let diff = Date().timeIntervalSince(entry.lastUpdated)
        let minutes = Int(diff / 60)
        if minutes < 1 {
            return "Updated: just now"
        } else if minutes < 60 {
            return "Updated: \(minutes)m ago"
        } else {
            let hours = minutes / 60
            return "Updated: \(hours)h ago"
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: entry.isPowerOn ? "bolt.fill" : "poweroutlet.type.b.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(entry.isPowerOn ? Color(red: 0.204, green: 0.78, blue: 0.349) : Color(red: 1, green: 0.231, blue: 0.188))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.isPowerOn ? "Power ON" : "Power OFF")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(entry.isPowerOn ? Color(red: 0.204, green: 0.78, blue: 0.349) : Color(red: 1, green: 0.231, blue: 0.188))
                        
                        Text(entry.groupName)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                }
                
                Spacer()
                
                if let minutes = minutesRemaining, minutes > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(entry.isPowerOn ? "OFF in" : "ON in")
                            .font(.caption)
                            .foregroundStyle(Color(red: 0.553, green: 0.553, blue: 0.576))
                        Text("\(minutes)m")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(entry.isPowerOn ? Color(red: 1, green: 0.231, blue: 0.188) : Color(red: 0.204, green: 0.78, blue: 0.349))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            Divider()
                .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                .padding(.horizontal, 16)
            
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("TODAY")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(red: 0.553, green: 0.553, blue: 0.576))
                    
                    if entry.todaySchedules.isEmpty {
                        Text("No outages scheduled")
                            .font(.caption)
                            .foregroundStyle(Color(red: 0.553, green: 0.553, blue: 0.576))
                            .italic()
                    } else {
                        ForEach(entry.todaySchedules) { schedule in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(schedule.isPowerOn ? Color(red: 0.204, green: 0.78, blue: 0.349) : Color(red: 1, green: 0.231, blue: 0.188))
                                    .frame(width: 8, height: 8)
                                
                                Text("\(schedule.startTime) - \(schedule.endTime)")
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("TOMORROW")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(red: 0.553, green: 0.553, blue: 0.576))
                    
                    if entry.tomorrowSchedules.isEmpty {
                        Text("No schedule yet")
                            .font(.caption)
                            .foregroundStyle(Color(red: 0.553, green: 0.553, blue: 0.576))
                            .italic()
                    } else {
                        ForEach(entry.tomorrowSchedules.prefix(4)) { schedule in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(schedule.isPowerOn ? Color(red: 0.204, green: 0.78, blue: 0.349) : Color(red: 1, green: 0.231, blue: 0.188))
                                    .frame(width: 8, height: 8)
                                
                                Text("\(schedule.startTime) - \(schedule.endTime)")
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                            }
                        }
                        
                        if entry.tomorrowSchedules.count > 4 {
                            Text("+\(entry.tomorrowSchedules.count - 4) more")
                                .font(.caption2)
                                .foregroundStyle(Color(red: 0.553, green: 0.553, blue: 0.576))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            
            Spacer()
            
            Text(formattedLastUpdated)
                .font(.caption2)
                .foregroundStyle(Color(red: 0.553, green: 0.553, blue: 0.576))
                .padding(.bottom, 12)
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

#Preview(as: .systemLarge) {
    LargeWidgetView(entry: PowerStatusEntry(
        date: Date(),
        isPowerOn: true,
        nextEvent: Date().addingTimeInterval(720),
        groupName: "1.1",
        todaySchedules: [
            ScheduleEntry(startTime: "00:00", endTime: "04:00", isPowerOn: false),
            ScheduleEntry(startTime: "04:00", endTime: "12:00", isPowerOn: true),
            ScheduleEntry(startTime: "12:00", endTime: "16:00", isPowerOn: false),
            ScheduleEntry(startTime: "16:00", endTime: "24:00", isPowerOn: true)
        ],
        tomorrowSchedules: [
            ScheduleEntry(startTime: "00:00", endTime: "03:00", isPowerOn: false),
            ScheduleEntry(startTime: "03:00", endTime: "11:00", isPowerOn: true),
            ScheduleEntry(startTime: "11:00", endTime: "15:00", isPowerOn: false),
            ScheduleEntry(startTime: "15:00", endTime: "24:00", isPowerOn: true)
        ],
        lastUpdated: Date()
    ))
}
