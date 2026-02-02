import SwiftUI
import ActivityKit
import WidgetKit

@available(iOS 16.1, *)
struct LiveActivityLockScreenView: View {
    let context: ActivityViewContext<PowerOutageAttributes>
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: context.state.isPowerOn ? "bolt.fill" : "poweroutlet.type.b.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(context.state.isPowerOn ? Color(red: 0.204, green: 0.78, blue: 0.349) : Color(red: 1, green: 0.231, blue: 0.188))
                    
                    Text(context.attributes.groupName)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                
                if context.state.minutesUntilChange > 0 {
                    Text(context.attributes.eventType == .powerOff ? "OFF in \(context.state.minutesUntilChange) min" : "ON in \(context.state.minutesUntilChange) min")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                } else {
                    Text(context.state.isPowerOn ? "Power is ON" : "Power is OFF")
                        .font(.subheadline)
                        .foregroundStyle(context.state.isPowerOn ? Color(red: 0.204, green: 0.78, blue: 0.349) : Color(red: 1, green: 0.231, blue: 0.188))
                }
            }
            
            Spacer()
            
            if context.state.minutesUntilChange > 0 {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 60, height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(context.attributes.eventType == .powerOff ? Color(red: 1, green: 0.231, blue: 0.188) : Color(red: 0.204, green: 0.78, blue: 0.349))
                        .frame(width: 60 * context.state.progress, height: 6)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .activityBackgroundTint(Color.black.opacity(0.8))
    }
}
