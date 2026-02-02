import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
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
    
    static let cardGradient: LinearGradient = {
        let angleDegrees: Double = -83
        let angleRadians = angleDegrees * .pi / 180
        
        let centerX: Double = 0.2
        let centerY: Double = 0.2
        let length: Double = 0.8
        
        let startX = centerX - length * cos(angleRadians)
        let startY = centerY + length * sin(angleRadians)
        let endX = centerX + length * cos(angleRadians)
        let endY = centerY - length * sin(angleRadians)
        
        return LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color("Dark gradient"), location: 0.0),
                .init(color: Color("Dark gradient"), location: 0.0),
                .init(color: Color("Dark blue gradient"), location: 1.0),
                .init(color: Color("Dark blue gradient"), location: 1.0)
            ]),
            startPoint: UnitPoint(x: max(0, min(1, startX)), y: max(0, min(1, startY))),
            endPoint: UnitPoint(x: max(0, min(1, endX)), y: max(0, min(1, endY)))
        )
    }()

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: entry.isPowerOn ? "bolt.fill" : "poweroutlet.type.b.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(entry.isPowerOn ? Color(red: 0.204, green: 0.78, blue: 0.349) : Color(red: 1, green: 0.231, blue: 0.188))
                    
                    Text(entry.isPowerOn ? "ON" : "OFF")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(entry.isPowerOn ? Color(red: 0.204, green: 0.78, blue: 0.349) : Color(red: 1, green: 0.231, blue: 0.188))
                }
                
                Text(entry.groupName)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                if let minutes = minutesRemaining, minutes > 0 {
                    Text(entry.isPowerOn ? "OFF in \(minutes)m" : "ON in \(minutes)m")
                        .font(.subheadline)
                        .foregroundStyle(Color(red: 0.553, green: 0.553, blue: 0.576))
                }
                
                Spacer()
                
                Text(formattedLastUpdated)
                    .font(.caption2)
                    .foregroundStyle(Color(red: 0.553, green: 0.553, blue: 0.576))
            }
            .frame(width: 100)
            
            Divider()
                .background(Color(red: 0.2, green: 0.2, blue: 0.2))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Today")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(red: 0.553, green: 0.553, blue: 0.576))
                    .padding(.bottom, 2)
                
                if entry.todaySchedules.isEmpty {
                    Text("No outages")
                        .font(.caption)
                        .foregroundStyle(Color(red: 0.553, green: 0.553, blue: 0.576))
                        .italic()
                } else {
                    ForEach(entry.todaySchedules.prefix(4)) { schedule in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(schedule.isPowerOn ? Color(red: 0.204, green: 0.78, blue: 0.349) : Color(red: 1, green: 0.231, blue: 0.188))
                                .frame(width: 6, height: 6)
                            
                            Text("\(schedule.startTime) - \(schedule.endTime)")
                                .font(.caption)
                                .foregroundStyle(.white)
                                .lineLimit(1)
                        }
                    }
                    
                    if entry.todaySchedules.count > 4 {
                        Text("+\(entry.todaySchedules.count - 4) more")
                            .font(.caption2)
                            .foregroundStyle(Color(red: 0.553, green: 0.553, blue: 0.576))
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .containerBackground(for: .widget) {
            Self.cardGradient
        }
    }
}


