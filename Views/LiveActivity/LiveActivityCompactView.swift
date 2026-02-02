import SwiftUI
import ActivityKit

struct LiveActivityCompactView: View {
    let context: ActivityViewContext<PowerOutageAttributes>
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: context.state.isPowerOn ? "bolt.fill" : "poweroutlet.type.b.fill")
                .font(.system(size: 20))
                .foregroundStyle(context.attributes.eventType == .powerOff ? Color(red: 1, green: 0.231, blue: 0.188) : Color(red: 0.204, green: 0.78, blue: 0.349))
            
            if context.state.minutesUntilChange > 0 {
                Text("\(context.state.minutesUntilChange)m")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                Text(context.state.isPowerOn ? "ON" : "OFF")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(context.state.isPowerOn ? Color(red: 0.204, green: 0.78, blue: 0.349) : Color(red: 1, green: 0.231, blue: 0.188))
            }
        }
        .activityBackgroundTint(Color.black.opacity(0.8))
    }
}
