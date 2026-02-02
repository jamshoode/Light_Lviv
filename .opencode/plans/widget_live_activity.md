# Light_Lviv Widget + Live Activity Implementation Plan

## Feature Overview
Add iOS Home Screen Widgets (Small/Medium/Large) and Live Activity support for real-time power outage tracking.

## Technical Requirements
- iOS Version: 17.0+ (dropping iOS 16 support)
- Frameworks: WidgetKit, ActivityKit, SwiftUI
- Architecture: Widget Extension + Live Activity
- NO COMMENTS IN CODE WHATSOEVER

## Branch Strategy
MANDATORY: Create and use dedicated branch for this feature

Branch Name: feature/widgets-live-activity
Base: feature/notifications-improvements (current working branch)

Who Creates Branch: Sisyphus (AI) will automatically create and manage branches

Workflow:
1. Sisyphus creates branch from current base before starting
2. All commits for this feature go to this branch
3. Merge back via PR when complete
4. Never commit directly to main or other feature branches

Automatic Branch Creation:
git checkout -b feature/widgets-live-activity
git push -u origin feature/widgets-live-activity

Note: User does NOT need to manually create branches. Sisyphus handles all git branch operations automatically as part of implementation.

## Widget Specifications

### Small Widget (1x1)
Content:
- Current power status icon (bolt.fill ON / poweroutlet.type.b.fill OFF)
- Countdown to next change (e.g., "12 min")
- Background: Dark theme matching app

Size: 169×169 pt (compact) / 155×155 pt (accessory)

### Medium Widget (2x1)
Content:
- Current power status with color indicator
- Group name (nickname if set)
- All schedules for TODAY
  - Visual timeline or list
  - Time ranges with ON/OFF status
- Last updated timestamp

Size: 348×169 pt

### Large Widget (2x2)
Content:
- Current power status with color indicator
- Group name (nickname if set)
- Today schedules (full list)
- Tomorrow schedules preview (next 3-4 events)
- "Updated: 2 min ago" timestamp

Size: 348×348 pt

Note: Need to verify if large widget can fit all content nicely. May need to:
- Use compact time format (10:00 instead of 10:00 AM)
- Show only 2-3 tomorrow events if space constrained

## Live Activity Specifications

### Display Content
1. Countdown Timer
   - "Power OFF in 12 min" or "Power ON in 8 min"
   - Updates every minute
   - Large, readable font

2. Progress Bar
   - Fills up as time approaches event
   - Color: Red (approaching OFF), Green (approaching ON)
   - Linear progress from 15 min to 0 min

3. Different Appearances:
   - OFF to ON Transition: Green theme, charging icon
   - ON to OFF Transition: Red/Orange theme, warning icon
   - Steady State (no imminent change): Minimal info, just current status

### Supported Views
- Dynamic Island (compact & expanded)
- Lock Screen (full width)
- StandBy mode (iOS 17)

## Data Flow Architecture

Main App (Light_Lviv)
    |
Shared App Groups Container (UserDefaults/App Groups)
    |
Widget Extension (WidgetKit) <-> Live Activity (ActivityKit)

### Data Sharing Strategy
1. App Groups: Create group.com.shoode.Light-Lviv
2. Shared Defaults: Store current schedule, next event time, last update
3. Timeline Updates: WidgetKit timeline reloads every 15 min
4. Live Activity: Started/stopped via ActivityKit from main app

## Implementation Tasks

### Task 1: Setup Widget Extension
What: Create new Widget Extension target
Files:
- Create Light_LvivWidget/ directory
- Light_LvivWidgetExtension.swift (main widget configuration)
- Light_LvivWidgetBundle.swift (widget bundle)
- Info.plist for extension

Configuration:
- Target: Widget Extension
- App Group: group.com.shoode.Light-Lviv
- Supported families: small, medium, large
- Background modes: None (widgets don't run in background)

Commit: feat(widget): add WidgetKit extension target

---

### Task 2: Setup App Groups & Shared Container
What: Configure App Groups for data sharing
Files to modify:
- Light_Lviv.xcodeproj/project.pbxproj (add capability)
- Create Services/SharedDataManager.swift (shared data layer)

Implementation:
class SharedDataManager {
    static let shared = SharedDataManager()
    private let defaults = UserDefaults(suiteName: "group.com.shoode.Light-Lviv")
    
    func saveCurrentStatus(status: PowerStatus, nextEvent: Date, groupName: String)
    func loadCurrentStatus() -> (status: PowerStatus, nextEvent: Date?, groupName: String)
}

Commit: feat(shared): add App Groups configuration and SharedDataManager

---

### Task 3: Implement Small Widget View
What: Create small widget UI
File: Light_LvivWidget/SmallWidgetView.swift

Design:
- Dark background (match app theme)
- Large status icon (centered)
- Countdown below icon
- Color coding: Green (ON), Red (OFF)

Code structure:
struct SmallWidgetView: View {
    var entry: PowerStatusEntry
    
    var body: some View {
        VStack {
            Image(systemName: entry.isPowerOn ? "bolt.fill" : "poweroutlet.type.b.fill")
                .font(.system(size: 40))
                .foregroundStyle(entry.isPowerOn ? .green : .red)
            
            if let nextEvent = entry.nextEvent {
                Text(entry.isPowerOn ? "OFF in \(nextEvent.minutesRemaining)m" : "ON in \(nextEvent.minutesRemaining)m")
                    .font(.caption)
                    .foregroundStyle(.white)
            }
        }
        .containerBackground(for: .widget) {
            Color.black
        }
    }
}

Commit: feat(widget): implement small widget view

---

### Task 4: Implement Medium Widget View
What: Create medium widget UI with today's schedule
File: Light_LvivWidget/MediumWidgetView.swift

Design considerations:
- Left side: Status + group name
- Right side: Today's schedule list
- Compact time format
- Visual separation between ON/OFF periods

Space verification needed:
- Test with actual iOS widget sizes
- Check if 5-6 schedule entries fit
- Fallback: Show only next 3-4 events if crowded

Commit: feat(widget): implement medium widget view

---

### Task 5: Implement Large Widget View
What: Create large widget with today + tomorrow schedules
File: Light_LvivWidget/LargeWidgetView.swift

Layout:
- Top: Status header (same as medium)
- Left column: Today schedules
- Right column: Tomorrow schedules (or below if vertical layout better)
- Bottom: Last updated timestamp

Space verification needed:
- Large widget = 348×348 pt
- Can we fit 2 columns comfortably?
- Alternative: Vertical list with section headers (TODAY / TOMORROW)

Commit: feat(widget): implement large widget view

---

### Task 6: Implement Widget Timeline Provider
What: Create timeline for widget updates
File: Light_LvivWidget/PowerStatusProvider.swift

Logic:
- Reload timeline every 15 minutes
- Update on schedule changes (via push notification or background refresh)
- Handle midnight transitions (today to tomorrow)

Implementation:
struct PowerStatusProvider: TimelineProvider {
    func getTimeline(in context: Context, completion: @escaping (Timeline<PowerStatusEntry>) -> ()) {
        var entries: [PowerStatusEntry] = []
        let currentDate = Date()
        
        for offset in 0..<(24 * 4) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: offset * 15, to: currentDate)!
            let entry = PowerStatusEntry(date: entryDate, ...)
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

Commit: feat(widget): add timeline provider for periodic updates

---

### Task 7: Setup ActivityKit for Live Activity
What: Configure Live Activity attributes and states
Files:
- Models/LiveActivityAttributes.swift (activity attributes struct)
- Add ActivityKit framework to main target

Implementation:
import ActivityKit

struct PowerOutageAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var isPowerOn: Bool
        var minutesUntilChange: Int
        var progress: Double
    }
    
    var groupName: String
    var targetTime: Date
    var eventType: EventType
}

enum EventType: String, Codable {
    case powerOff, powerOn
}

Commit: feat(live-activity): add ActivityKit configuration and attributes

---

### Task 8: Create Live Activity Views
What: Design Live Activity UI for Dynamic Island & Lock Screen
Files:
- Views/LiveActivity/LiveActivityCompactView.swift (Dynamic Island compact)
- Views/LiveActivity/LiveActivityExpandedView.swift (Dynamic Island expanded)
- Views/LiveActivity/LiveActivityLockScreenView.swift (Lock Screen)

Design specs:

Compact (Dynamic Island minimal):
- Left: Status icon (bolt/poweroutlet)
- Right: Countdown (e.g., "12m")

Expanded (Dynamic Island tapped):
- Top: Group name + status
- Middle: Large countdown "Power OFF in 12 minutes"
- Bottom: Progress bar filling up
- Background: Red gradient (OFF coming) or Green gradient (ON coming)

Lock Screen:
- Full width card
- Current status prominently displayed
- Countdown with large font
- Progress bar

Commit: feat(live-activity): implement Live Activity views for all contexts

---

### Task 9: Integrate Live Activity with NotificationManager
What: Start/stop Live Activities based on schedule
File: Services/NotificationManager.swift (add methods)

Logic:
- Start Live Activity when scheduling notifications (if within 15 min window)
- Update Live Activity every minute (via background task or push)
- End Live Activity when event occurs or user unsubscribes

Implementation:
extension NotificationManager {
    func startLiveActivity(for group: ScheduleGroup, nextEvent: Date, isPowerOn: Bool) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = PowerOutageAttributes(
            groupName: group.subGroupName,
            targetTime: nextEvent,
            eventType: isPowerOn ? .powerOff : .powerOn
        )
        
        let initialState = PowerOutageAttributes.ContentState(
            isPowerOn: isPowerOn,
            minutesUntilChange: 15,
            progress: 0.0
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                contentState: initialState,
                pushType: nil
            )
            print("Started Live Activity: \(activity.id)")
        } catch {
            print("Error starting Live Activity: \(error)")
        }
    }
    
    func updateLiveActivity(minutesRemaining: Int, progress: Double) {
        Task {
            for activity in Activity<PowerOutageAttributes>.activities {
                let newState = PowerOutageAttributes.ContentState(
                    isPowerOn: activity.attributes.eventType == .powerOn,
                    minutesUntilChange: minutesRemaining,
                    progress: progress
                )
                await activity.update(using: newState)
            }
        }
    }
    
    func endLiveActivity() {
        Task {
            for activity in Activity<PowerOutageAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
    }
}

Commit: feat(live-activity): integrate Live Activity with NotificationManager

---

### Task 10: Update App Entry Point for Live Activities
What: Configure main app for ActivityKit
File: App/Light_LvivApp.swift

Current 4-tab structure:
Tab 0: Home (house)
Tab 1: Support (WIP - Support icon)
Tab 2: Notifications (bell)
Tab 3: Battery (bolt.fill) - from battery plan

Changes for Live Activities:
- Add ActivityKit import
- Register activity attributes
- Handle activity state restoration on app launch

Implementation:
import ActivityKit
import UserNotifications

@main
struct Light_LvivApp: App {
    init() {
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        NotificationManager.shared.processDeliveredNotifications()
        NotificationManager.shared.removePendingNotificationsForUnsubscribedGroups()
        configureLiveActivities()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    static func configureLiveActivities() {
        if #available(iOS 16.1, *) {
            let info = ActivityAuthorizationInfo()
            print("Live Activities enabled: \(info.areActivitiesEnabled)")
        }
    }
}

Commit: feat(live-activity): configure main app for ActivityKit support

---

### Task 11: Update Shared Data on Schedule Changes
What: Ensure widgets get updated when schedule changes
File: Services/NotificationManager.swift (modify existing methods)

Changes:
- Update SharedDataManager when subscribe(), unsubscribe(), or checkForChanges() is called
- Trigger widget timeline reload via WidgetCenter.shared.reloadTimelines(ofKind:)

Implementation:
func subscribe(group: ScheduleGroup) {
    subscribedGroups.insert(group.id)
    currentSchedules[group.id] = group.schedules
    saveSubscriptions()
    scheduleNotifications(for: group)
    
    SharedDataManager.shared.saveCurrentStatus(
        status: currentStatus,
        nextEvent: nextEvent,
        groupName: group.subGroupName
    )
    
    WidgetCenter.shared.reloadTimelines(ofKind: "Light_LvivWidget")
}

Commit: feat(widget): trigger widget updates on schedule changes

---

### Task 12: Add Widget Configuration UI
What: Let users choose which group to display in widget
File: Views/Settings/WidgetSettingsView.swift (new)

Features:
- Select active group for widget
- Preview widget appearance
- Explain how to add widget to Home Screen

Note: This could be integrated into existing settings or shown as onboarding

Commit: feat(widget): add widget configuration settings

---

### Task 13: Testing & Verification
What: Test all widget sizes and Live Activities
Steps:
1. Build and run on iOS 17+ simulator
2. Add all 3 widget sizes to Home Screen
3. Test Live Activity on Lock Screen
4. Test Dynamic Island (if supported in simulator)
5. Verify data updates correctly
6. Check memory usage

Files:
- Add widget testing documentation
- Screenshot different states for reference

Commit: test(widget): add widget testing and verification

---

## Visual Design Guidelines

### Colors
- Background: Black (#000000) - match app
- ON Status: Green (#34C759)
- OFF Status: Red (#FF3B30)
- Text: White (#FFFFFF)
- Secondary Text: Gray (#8E8E93)

### Typography
- Status icon: 40pt (small), 60pt (medium/large)
- Countdown: 24pt bold (small), 32pt bold (medium/large)
- Group name: 16pt medium
- Schedule times: 14pt regular

### Widget Background
.containerBackground(for: .widget) {
    LinearGradient(
        colors: [Color.black, Color.black.opacity(0.8)],
        startPoint: .top,
        endPoint: .bottom
    )
}

---

## Dependencies & Frameworks

### Required Additions
1. WidgetKit (iOS 17+)
2. ActivityKit (iOS 16.1+, but require 17+ for consistency)
3. SwiftUI (already in use)

### No New External Dependencies
- Keep with existing pattern
- Use only Apple frameworks

---

## Commit Strategy

| Task | Commit Message |
|------|----------------|
| 1 | feat(widget): add WidgetKit extension target |
| 2 | feat(shared): add App Groups and SharedDataManager |
| 3 | feat(widget): implement small widget view |
| 4 | feat(widget): implement medium widget view |
| 5 | feat(widget): implement large widget view |
| 6 | feat(widget): add timeline provider |
| 7 | feat(live-activity): add ActivityKit configuration |
| 8 | feat(live-activity): implement Live Activity views |
| 9 | feat(live-activity): integrate with NotificationManager |
| 10 | feat(live-activity): configure main app for ActivityKit |
| 11 | feat(widget): trigger updates on schedule changes |
| 12 | feat(widget): add widget configuration UI |
| 13 | test(widget): add testing and verification |

---

## Risk Analysis

### Technical Risks
1. Widget memory limits: Widgets have strict memory budgets (~16MB)
   - Mitigation: Keep views simple, use lazy loading
   
2. Timeline reload frequency: Too frequent = battery drain
   - Mitigation: 15 min updates, user-initiated refreshes
   
3. Live Activity duration: Max 8 hours per activity
   - Mitigation: Handle expiration gracefully, restart if needed

### User Experience Risks
1. Widget content overflow: Large widget may not fit all schedules
   - Mitigation: Smart truncation, "+3 more" indicator
   
2. Stale data: Widget shows old info if refresh fails
   - Mitigation: Show last updated time, pull-to-refresh

---

## Success Criteria

- [ ] All 3 widget sizes display correctly on Home Screen
- [ ] Widget updates every 15 minutes automatically
- [ ] Live Activity appears on Lock Screen when appropriate
- [ ] Dynamic Island shows compact/expanded views
- [ ] Data syncs between app, widgets, and Live Activity
- [ ] No crashes or memory warnings
- [ ] Works on iOS 17.0+
- [ ] Battery impact minimal (<1% per day)

---

## Post-Implementation Ideas

- Interactive Widgets (iOS 17+): Tap to refresh, toggle subscription
- StandBy Mode: Special layout for iOS 17 StandBy feature
- Watch Complication: Apple Watch app with complications
- Siri Integration: "What's my power status?"

---

## Implementation Notes

- NO COMMENTS IN CODE WHATSOEVER
- Space verification: Need to test actual widget rendering on device/simulator
- iOS 16 support: Officially dropping support
- Accessibility: Ensure all widgets support Dynamic Type and VoiceOver
- Localization: Use existing localization strings where possible
- Code must be self-explanatory through clear naming
