# Light_Lviv Battery Calculator Implementation Plan

## Feature Overview
Add a battery/power bank calculator that helps users estimate how long their devices will last during power outages and whether they need to prepare additional power sources.

## Technical Requirements
- iOS Version: 17.0+ (consistent with app)
- Framework: SwiftUI (existing)
- Storage: UserDefaults (for user preferences)
- NO COMMENTS IN CODE WHATSOEVER

## Branch Strategy
MANDATORY: Create and use dedicated branch for this feature

Branch Name: feature/battery-calculator
Base: feature/notifications-improvements (current working branch)

Who Creates Branch: Sisyphus (AI) will automatically create and manage branches

Workflow:
1. Sisyphus creates branch from current base before starting
2. All commits for this feature go to this branch
3. Merge back via PR when complete
4. Never commit directly to main or other feature branches

Automatic Branch Creation:
git checkout -b feature/battery-calculator
git push -u origin feature/battery-calculator

Note: User does NOT need to manually create branches. Sisyphus handles all git branch operations automatically as part of implementation.

## User Flow

### 1. Access Point
4th Tab in main TabView

Tab Structure (4 tabs total):
- Tab 0: Home (house icon) - Current ContentView
- Tab 1: Support (Support icon) - WIP/Placeholder
- Tab 2: Notifications (bell icon) - NotificationsTabView
- Tab 3: Battery (bolt.fill icon) - BatteryCalculatorView

### 2. Input Screen
Simple, intuitive interface:

Section 1: Power Bank
- "What's your power bank capacity?"
- Slider or text field: 1000mAh to 50000mAh
- Preset buttons: 10000mAh, 20000mAh, 30000mAh (common sizes)

Section 2: Devices to Power
- List of common devices with toggles:
  - iPhone (15W consumption)
  - iPad (25W)
  - Laptop (60W)
  - Router/WiFi (10W)
  - Light/LED lamp (5W)
  - Custom device (manual wattage input)

Section 3: Usage Pattern
- "How will you use these devices?"
  - Minimal (emergency only) - 20% duty cycle
  - Normal (moderate use) - 50% duty cycle
  - Heavy (constant use) - 80% duty cycle

### 3. Results Screen
Clear, actionable output:

Your power bank will last

     4 hours 30 minutes

Warning: Tonight's outage is 6 hours
   You'll need additional power!

Recommendations:
   • Charge devices by 18:00 before outage
   • Reduce usage to minimal for 10h duration
   • Consider second power bank (20000mAh)
   • Or: Use only iPhone + Router (extends to 7h)

Comparison with scheduled outages:
- Show next 3 upcoming outages
- Highlight if battery covers them
- Color coding: Green (covered), Red (not enough)

---

## Implementation Tasks

### Task 1: Create Data Models
File: Models/BatteryCalculator.swift

Structures:
struct PowerBank {
    var capacityMah: Int
    var voltage: Double = 3.7
    
    var capacityWh: Double {
        return Double(capacityMah) * voltage / 1000
    }
}

struct Device: Identifiable {
    let id = UUID()
    var name: String
    var powerConsumptionWatts: Double
    var icon: String
    var isSelected: Bool = false
}

enum UsagePattern: Double, CaseIterable {
    case minimal = 0.2
    case normal = 0.5
    case heavy = 0.8
    
    var description: String {
        switch self {
        case .minimal: return "Minimal (emergency only)"
        case .normal: return "Normal (moderate use)"
        case .heavy: return "Heavy (constant use)"
        }
    }
}

struct BatteryCalculation {
    let totalDurationHours: Double
    let totalDurationFormatted: String
    let canHandleOutages: [OutageCheck]
    let recommendations: [String]
}

struct OutageCheck {
    let date: Date
    let durationHours: Double
    let isCovered: Bool
    let shortfall: Double?
}

Commit: feat(battery): add BatteryCalculator data models

---

### Task 2: Create Calculation Service
File: Services/BatteryCalculatorService.swift

Logic:
class BatteryCalculatorService: ObservableObject {
    @Published var powerBank = PowerBank(capacityMah: 20000)
    @Published var selectedDevices: [Device] = []
    @Published var usagePattern: UsagePattern = .normal
    
    let availableDevices = [
        Device(name: "iPhone", powerConsumptionWatts: 15, icon: "iphone"),
        Device(name: "iPad", powerConsumptionWatts: 25, icon: "ipad"),
        Device(name: "Laptop", powerConsumptionWatts: 60, icon: "laptopcomputer"),
        Device(name: "Router/WiFi", powerConsumptionWatts: 10, icon: "wifi"),
        Device(name: "LED Light", powerConsumptionWatts: 5, icon: "lightbulb"),
        Device(name: "Refrigerator", powerConsumptionWatts: 100, icon: "refrigerator"),
        Device(name: "Custom", powerConsumptionWatts: 0, icon: "slider.horizontal.3")
    ]
    
    func calculate() -> BatteryCalculation {
        let totalPowerWatts = selectedDevices.reduce(0) { $0 + $1.powerConsumptionWatts }
        let effectivePower = totalPowerWatts * usagePattern.rawValue
        
        let durationHours = powerBank.capacityWh / effectivePower
        
        let outageChecks = checkAgainstOutages(duration: durationHours)
        
        let recommendations = generateRecommendations(
            duration: durationHours,
            outages: outageChecks,
            totalPower: totalPowerWatts
        )
        
        return BatteryCalculation(
            totalDurationHours: durationHours,
            totalDurationFormatted: formatDuration(durationHours),
            canHandleOutages: outageChecks,
            recommendations: recommendations
        )
    }
    
    private func checkAgainstOutages(duration: Double) -> [OutageCheck] {
        // Get next 3 scheduled outages from NotificationManager
        // Check if battery duration covers each
        // Return array of OutageCheck
    }
    
    private func generateRecommendations(duration: Double, outages: [OutageCheck], totalPower: Double) -> [String] {
        // Generate contextual recommendations based on calculation
    }
    
    private func formatDuration(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return "\(h)h \(m)m"
    }
}

Commit: feat(battery): add BatteryCalculatorService with calculation logic

---

### Task 3: Create Input View
File: Views/Battery/BatteryCalculatorView.swift

Structure:
struct BatteryCalculatorView: View {
    @StateObject private var calculator = BatteryCalculatorService()
    @State private var showingResults = false
    @State private var calculation: BatteryCalculation?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    PowerBankSection(calculator: calculator)
                    DevicesSection(calculator: calculator)
                    UsagePatternSection(calculator: calculator)
                    
                    Button {
                        calculation = calculator.calculate()
                        showingResults = true
                    } label: {
                        Label("Calculate Duration", systemImage: "bolt.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Battery Calculator")
            .background(Color.black.ignoresSafeArea())
            .sheet(isPresented: $showingResults) {
                if let calc = calculation {
                    BatteryResultsView(calculation: calc)
                }
            }
        }
    }
}

Subviews:

PowerBankSection:
- Header: "Your Power Bank"
- Slider: 1000mAh to 50000mAh
- Current value display: "20,000 mAh"
- Quick select buttons: 10K, 20K, 30K
- Info: "≈ 74 Wh total energy"

DevicesSection:
- Header: "Devices to Power"
- Grid of device cards (2 columns)
- Each card: Icon, name, wattage, toggle/checkmark
- Selected devices highlighted with green border
- Custom device option with manual wattage input

UsagePatternSection:
- Header: "Usage Pattern"
- Segmented picker: Minimal | Normal | Heavy
- Description text below explaining each

Commit: feat(battery): add BatteryCalculatorView with inputs

---

### Task 4: Create Results View
File: Views/Battery/BatteryResultsView.swift

Design:
struct BatteryResultsView: View {
    let calculation: BatteryCalculation
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ResultCard(calculation: calculation)
                    OutageComparisonSection(calculation: calculation)
                    RecommendationsSection(calculation: calculation)
                    
                    Button {
                        shareResults()
                    } label: {
                        Label("Share Results", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle("Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

ResultCard Component:
- Large, prominent display
- Icon: Battery with charge level visual
- Main text: "4h 30m"
- Subtext: "estimated duration"
- Background: Gradient (green if >8h, yellow if 4-8h, red if <4h)

OutageComparisonSection:
- "Upcoming Outages" header
- List of next 3 outages
- Each row: Date, duration, status icon
  - Green checkmark: Covered
  - Yellow warning: Partially covered
  - Red X: Not covered
- Tap to see details

RecommendationsSection:
- "Recommendations" header
- Bulleted list of actionable tips
- Smart suggestions based on calculation:
  - Charge timing recommendations
  - Device usage optimization
  - Additional power bank suggestions
  - Alternative device combinations

Commit: feat(battery): add BatteryResultsView with detailed output

---

### Task 5: Add Tab to Main Navigation
File: App/Light_LvivApp.swift

Implementation (4 tabs total, no comments):
TabView(selection: $selection) {
    Text("WIP")
        .font(.largeTitle)
        .bold()
        .tabItem {
            Image("Support icon")
            Text("Support")
        }
        .tag(1)

    NavigationStack {
        Home
    }
        .tabItem {
            Image(systemName: "house")
            Text("Home")
        }
        .tag(0)

    NavigationStack {
        NotificationsTabView()
    }
        .tabItem {
            Image(systemName: "bell")
            Text("Notifications")
        }
        .tag(2)
    
    BatteryCalculatorView()
        .tabItem {
            Image(systemName: "bolt.fill")
            Text("Battery")
        }
        .tag(3)
}

Tab Structure:
- Tag 0: Home (house icon)
- Tag 1: Support (WIP - Support icon) 
- Tag 2: Notifications (bell icon)
- Tag 3: Battery (bolt.fill icon) - NEW

Commit: feat(battery): add battery calculator as 4th tab

---

### Task 6: Persistence & User Preferences
File: Services/BatteryCalculatorService.swift (add persistence)

Implementation:
extension BatteryCalculatorService {
    private let defaults = UserDefaults.standard
    
    func savePreferences() {
        defaults.set(powerBank.capacityMah, forKey: "battery_capacity")
        defaults.set(usagePattern.rawValue, forKey: "battery_usage_pattern")
        
        let selectedIds = selectedDevices.map { $0.id.uuidString }
        defaults.set(selectedIds, forKey: "battery_selected_devices")
    }
    
    func loadPreferences() {
        powerBank.capacityMah = defaults.integer(forKey: "battery_capacity")
        if powerBank.capacityMah == 0 { powerBank.capacityMah = 20000 }
        
        if let patternRaw = defaults.value(forKey: "battery_usage_pattern") as? Double,
           let pattern = UsagePattern(rawValue: patternRaw) {
            usagePattern = pattern
        }
        
        if let savedIds = defaults.stringArray(forKey: "battery_selected_devices") {
            selectedDevices = availableDevices.filter { device in
                savedIds.contains(device.id.uuidString)
            }
        }
    }
}

Commit: feat(battery): add user preference persistence

---

### Task 7: Visual Design & Polish
File: Views/Battery/ (all views)

Design Elements:

Color Coding:
- Power bank capacity slider: Blue gradient
- Selected devices: Green border + checkmark
- Result duration:
  - ≥ 8 hours: Green (#34C759)
  - 4-8 hours: Yellow (#FFCC00)
  - < 4 hours: Red (#FF3B30)

Animations:
- Smooth transitions between sections
- Calculate button pulse animation
- Results card slide-in animation
- Number counting animation for duration

Icons:
- Battery icon with fill level
- Device-specific SF Symbols
- Status indicators

Accessibility:
- VoiceOver labels for all interactive elements
- Dynamic Type support
- High contrast mode support

Commit: feat(battery): add visual polish and accessibility

---

### Task 8: Testing
File: Light_LvivTests/BatteryCalculatorTests.swift

Test Cases:
final class BatteryCalculatorTests: XCTestCase {
    var calculator: BatteryCalculatorService!
    
    override func setUp() {
        calculator = BatteryCalculatorService()
    }
    
    func testBasicCalculation() {
        calculator.powerBank = PowerBank(capacityMah: 20000)
        calculator.selectedDevices = [Device(name: "iPhone", powerConsumptionWatts: 15, icon: "iphone")]
        calculator.usagePattern = .normal
        
        let result = calculator.calculate()
        
        XCTAssertGreaterThan(result.totalDurationHours, 9)
        XCTAssertLessThan(result.totalDurationHours, 11)
    }
    
    func testMultipleDevices() {
        calculator.powerBank = PowerBank(capacityMah: 30000)
        calculator.selectedDevices = [
            Device(name: "iPhone", powerConsumptionWatts: 15, icon: "iphone"),
            Device(name: "Router", powerConsumptionWatts: 10, icon: "wifi")
        ]
        calculator.usagePattern = .heavy
        
        let result = calculator.calculate()
        
        XCTAssertGreaterThan(result.totalDurationHours, 5)
        XCTAssertLessThan(result.totalDurationHours, 6)
    }
    
    func testOutageComparison() {
        // Test that calculation correctly compares against scheduled outages
    }
    
    func testRecommendations() {
        // Verify recommendations are generated appropriately
    }
}

Commit: test(battery): add unit tests for calculator logic

---

## Sample Calculations

| Power Bank | Devices | Usage | Duration | Fits 6h Outage? |
|------------|---------|-------|----------|----------------|
| 10,000mAh | iPhone | Normal | 4.9h | No |
| 10,000mAh | iPhone | Minimal | 12.3h | Yes |
| 20,000mAh | iPhone + Router | Normal | 6.6h | Yes |
| 20,000mAh | iPhone + Laptop | Normal | 1.7h | No |
| 30,000mAh | iPhone + iPad + Router | Heavy | 5.5h | No |
| 30,000mAh | iPhone + iPad + Router | Minimal | 22h | Yes |

---

## User Experience Flow

1. First Launch:
   - Show quick onboarding tooltip
   - "Calculate how long your devices will last during outages"

2. Regular Use:
   - Open Battery tab (4th tab)
   - Adjust power bank capacity (if changed)
   - Toggle devices you need
   - Tap Calculate
   - View results and recommendations

3. Contextual Help:
   - Info buttons explaining wattage
   - Tips: "iPhone consumes ~15W when charging"
   - Link to buy recommended power banks?

---

## Integration with Existing Features

With Schedule Notifications:
- Use actual scheduled outages from NotificationManager
- Real comparison: "Your battery lasts 4h, next outage is 6h"

With Widgets:
- Quick access from widget (iOS 17 interactive widgets)
- Show calculation result in widget?

With Settings:
- Store default power bank capacity
- Remember commonly used devices

---

## Commit Strategy

| Task | Commit Message |
|------|----------------|
| 1 | feat(battery): add BatteryCalculator data models |
| 2 | feat(battery): add BatteryCalculatorService with calculation logic |
| 3 | feat(battery): add BatteryCalculatorView with user inputs |
| 4 | feat(battery): add BatteryResultsView with detailed output |
| 5 | feat(battery): add battery calculator as 4th tab |
| 6 | feat(battery): add user preference persistence |
| 7 | feat(battery): add visual polish and accessibility |
| 8 | test(battery): add unit tests for calculator logic |

---

## Success Criteria

- [ ] User can input power bank capacity (1000-50000mAh)
- [ ] User can select multiple devices with toggle UI
- [ ] Calculation shows accurate duration in hours/minutes
- [ ] Results compare against upcoming scheduled outages
- [ ] Recommendations provide actionable advice
- [ ] User preferences are saved and restored
- [ ] Visual design matches existing app theme
- [ ] Accessible with VoiceOver and Dynamic Type
- [ ] All calculations have unit test coverage
- [ ] No performance issues (calculations < 100ms)
- [ ] NO COMMENTS IN CODE WHATSOEVER

---

## Post-Implementation Ideas

- Power Bank Recommendations: Link to Amazon/retailer APIs
- Usage Tracking: Actually track device usage during outages
- Smart Suggestions: "Based on your history, charge by 17:00"
- Solar Calculator: Add solar panel input for off-grid calculation
- Export: Share calculation via iMessage/WhatsApp

---

## Implementation Notes

- NO COMMENTS IN CODE WHATSOEVER
- Accuracy: Real-world factors (battery efficiency, temperature) not included
- Assumptions: Simplified power consumption values (averages)
- Wattage source: Standard iPhone ~15W when active+charging
- Formula: Duration (h) = (Capacity (mAh) × 3.7V / 1000) / (Power (W) × Duty Cycle)
- Code must be self-explanatory through clear naming
