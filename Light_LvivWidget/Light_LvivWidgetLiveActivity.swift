import ActivityKit
import WidgetKit
import SwiftUI

struct Light_LvivWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PowerOutageAttributes.self) { context in
            LiveActivityLockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.8))
                .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    LiveActivityCompactView(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    EmptyView()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    LiveActivityExpandedView(context: context)
                }
            } compactLeading: {
                Image(systemName: context.state.isPowerOn ? "bolt.fill" : "poweroutlet.type.b.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(context.attributes.eventType == .powerOff ? Color(red: 1, green: 0.231, blue: 0.188) : Color(red: 0.204, green: 0.78, blue: 0.349))
            } compactTrailing: {
                if context.state.minutesUntilChange > 0 {
                    Text("\(context.state.minutesUntilChange)m")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
            } minimal: {
                Image(systemName: context.state.isPowerOn ? "bolt.fill" : "poweroutlet.type.b.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(context.attributes.eventType == .powerOff ? Color(red: 1, green: 0.231, blue: 0.188) : Color(red: 0.204, green: 0.78, blue: 0.349))
            }
        }
    }
}
