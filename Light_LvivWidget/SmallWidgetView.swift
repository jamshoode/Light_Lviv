import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    var entry: PowerStatusEntry
    
    private var minutesRemaining: Int? {
        guard let nextEvent = entry.nextEvent else { return nil }
        let diff = nextEvent.timeIntervalSince(entry.date)
        return max(0, Int(diff / 60))
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
        VStack(spacing: 8) {
            Image(systemName: entry.isPowerOn ? "bolt.fill" : "poweroutlet.type.b.fill")
                .font(.system(size: 40))
                .foregroundStyle(entry.isPowerOn ? Color(red: 0.204, green: 0.78, blue: 0.349) : Color(red: 1, green: 0.231, blue: 0.188))
            
            if let minutes = minutesRemaining, minutes > 0 {
                let key = entry.isPowerOn ? "widgetPowerOffIn" : "widgetPowerOnIn"
                Text(String(format: Localization.get(key), "\(minutes)"))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            } else {
                Text(entry.isPowerOn ? Localization.get("widgetStatusOn") : Localization.get("widgetStatusOff"))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color(red: 0.553, green: 0.553, blue: 0.576))
            }
        }
        .containerBackground(for: .widget) {
            Self.cardGradient
        }
    }
}


