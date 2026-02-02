import SwiftUI
import ActivityKit

struct LiveActivityExpandedView: View {
    let context: ActivityViewContext<PowerOutageAttributes>
    
    private var gradientColors: [Color] {
        if context.attributes.eventType == .powerOff {
            return [Color(red: 0.8, green: 0.2, blue: 0.1), Color(red: 0.5, green: 0.1, blue: 0.05)]
        } else {
            return [Color(red: 0.1, green: 0.6, blue: 0.2), Color(red: 0.05, green: 0.4, blue: 0.1)]
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(context.attributes.groupName)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: context.state.isPowerOn ? "bolt.fill" : "poweroutlet.type.b.fill")
                        .font(.system(size: 16))
                    Text(context.state.isPowerOn ? "Power ON" : "Power OFF")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(context.state.isPowerOn ? Color(red: 0.204, green: 0.78, blue: 0.349) : Color(red: 1, green: 0.231, blue: 0.188))
            }
            
            if context.state.minutesUntilChange > 0 {
                VStack(spacing: 8) {
                    Text(context.attributes.eventType == .powerOff ? "Power OFF in" : "Power ON in")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Text("\(context.state.minutesUntilChange) minutes")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(context.attributes.eventType == .powerOff ? Color(red: 1, green: 0.231, blue: 0.188) : Color(red: 0.204, green: 0.78, blue: 0.349))
                            .frame(width: geometry.size.width * context.state.progress, height: 8)
                    }
                }
                .frame(height: 8)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: context.state.isPowerOn ? "bolt.fill" : "poweroutlet.type.b.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(context.state.isPowerOn ? Color(red: 0.204, green: 0.78, blue: 0.349) : Color(red: 1, green: 0.231, blue: 0.188))
                    
                    Text(context.state.isPowerOn ? "Power is ON" : "Power is OFF")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .activityBackgroundTint(Color.black.opacity(0.9))
    }
}
