# Light_Lviv Improvements Work Plan

## TL;DR

> **Quick Summary**: Fix notification bugs, implement comprehensive test suite with XCTest, expand notification system to support pre-event alerts (15-min warnings) and schedule change notifications for all groups, add a Notifications Tab with persistent history (last 5 notifications ring buffer), and migrate from NavigationStack to TabView architecture.
> 
> **Deliverables**:
> - Fixed notification scheduling bug (separate commit)
> - XCTest infrastructure with unit tests for ScheduleParser, NotificationManager
> - NotificationHistory model with ring buffer persistence
> - Pre-event notification scheduling (15 min before ON/OFF)
> - Schedule change notifications for ALL groups (subscribed + unsubscribed)
> - Notifications Tab with 2-tab TabView architecture
> - UI tests for critical user flows
> 
> **Estimated Effort**: Large (8-12 tasks, 2-3 waves)
> **Parallel Execution**: YES - 3 waves
> **Critical Path**: Bug Fix → Test Infra → Core Features → UI Changes

---

## Context

### Original Request
Implement tests, fix notifications system (bug fix + 3 new notification features), and add a Notifications Tab with TabView architecture.

### Interview Summary
**Key Discussions**:
- **Test Framework**: XCTest (built-in, no additional dependencies)
- **Bug Fix Priority**: Fix notification timing bug first as separate commit (<= should be >=)
- **Notification Persistence**: Ring buffer - last 5 notifications only, persist to UserDefaults
- **Notification Content**: Standard info - type, group name, scheduled event time, timestamp
- **Tab Structure**: 2 tabs (Home + Notifications), migrate from NavigationStack
- **Testing Strategy**: Tests alongside features (balanced approach)
- **Unread Marker**: Red dot indicator on GroupCardView (already partially implemented)
- **Groups Display**: Keep current behavior - show only saved groups with unread indicators

### Research Findings
**Codebase Analysis**:
- iOS SwiftUI app using MVVM with @Observable macro (iOS 17+)
- ~2000 lines of Swift code across 18 files
- Current notification bug in `NotificationManager.scheduleEvent()` line 267: `if notifyDate <= Date()` schedules past events
- NotificationManager is Singleton with UserDefaults persistence
- ScheduleParser parses time ranges and calculates power ON gaps
- Current architecture: NavigationStack with ContentView as root
- Red dot marker already exists in GroupCardView (lines 47-52)

---

## Work Objectives

### Core Objective
Transform the notification system from basic schedule change alerts to a comprehensive pre-event warning system with persistent notification history, while establishing a robust test suite and modernizing the navigation architecture.

### Concrete Deliverables
1. **Bug Fix**: Fixed notification timing condition in NotificationManager
2. **Test Infrastructure**: XCTest target configured with example tests passing
3. **NotificationHistory Model**: Ring buffer implementation with Codable support
4. **Pre-Event Scheduling**: 15-minute advance notifications for power ON/OFF events
5. **Expanded Change Notifications**: Schedule changes notify ALL groups (not just subscribed)
6. **Notifications Tab**: New tab with persistent history display
7. **TabView Migration**: Convert NavigationStack to TabView with 2 tabs
8. **Test Coverage**: Unit tests for ScheduleParser, NotificationManager, NotificationHistory

### Definition of Done
- [ ] All 8 concrete deliverables implemented
- [ ] All unit tests pass (`Cmd+U` in Xcode)
- [ ] UI tests pass for critical flows
- [ ] App builds without warnings
- [ ] Notifications Tab shows last 5 notifications with correct data
- [ ] Pre-event notifications fire 15 minutes before events
- [ ] Red dot markers appear on changed schedules
- [ ] Bug fix committed separately before feature work

### Must Have
- [ ] Notification timing bug fixed (<= to >=)
- [ ] XCTest target created and configured
- [ ] Ring buffer notification history (max 5, persists)
- [ ] Pre-event notifications (15 min before ON/OFF)
- [ ] Schedule change notifications for all groups
- [ ] 2-tab TabView working
- [ ] Unit tests for ScheduleParser
- [ ] Unit tests for NotificationManager

### Must NOT Have (Guardrails)
- [ ] NO changes to scraping logic (PowerOffScraper stays as-is)
- [ ] NO changes to address search feature
- [ ] NO changes to visual schedule display
- [ ] NO new external dependencies (use only XCTest)
- [ ] NO modification of localization strings (unless necessary)
- [ ] NO changes to model structure (ScheduleGroup stays same)
- [ ] NO support for more than 5 notifications in history
- [ ] NO push notification changes for unsubscribed groups (only in-app history)

---

## Verification Strategy

### Test Decision
- **Infrastructure exists**: NO - must create XCTest target
- **User wants tests**: YES (Tests alongside features)
- **Framework**: XCTest (built-in)

### Test Setup Task (Task 0)
- [ ] 0. Setup Test Infrastructure
  - Create: Test target in Xcode project
  - Config: Add test files to project.pbxproj
  - Verify: `Cmd+U` runs tests (0 tests pass initially)
  - Example: Create `Light_LvivTests/ScheduleParserTests.swift` with one passing test
  - Verify: Build succeeds, test target appears in Test Navigator

### TDD Workflow for Feature Tasks
Each TODO follows RED-GREEN pattern:
1. **RED**: Write failing test first (test file exists, tests fail)
2. **GREEN**: Implement minimum code to pass (tests pass)

### Automated Verification (Agent-Executable)

**For Test Infrastructure (Task 0):**
```bash
# Agent verifies:
xcodebuild -project Light_Lviv.xcodeproj -scheme Light_Lviv -destination 'platform=iOS Simulator,name=iPhone 15' build
# Assert: Build succeeds (exit code 0)

xcodebuild -project Light_Lviv.xcodeproj -scheme Light_LvivTests -destination 'platform=iOS Simulator,name=iPhone 15' test
# Assert: Tests run (may have 0 tests initially)
```

**For Unit Tests (Tasks 1, 4, 6):**
```bash
# After implementing tests:
xcodebuild -project Light_Lviv.xcodeproj -scheme Light_LvivTests -destination 'platform=iOS Simulator,name=iPhone 15' test
# Assert: Specific test classes pass (ScheduleParserTests, NotificationManagerTests, etc.)
```

**For Swift Code Changes (Tasks 2, 3, 5, 7):**
```bash
# Verify code compiles:
xcodebuild -project Light_Lviv.xcodeproj -scheme Light_Lviv -destination 'platform=iOS Simulator,name=iPhone 15' build
# Assert: Build succeeds with no errors

# Verify no regressions in existing code:
swift -typecheck Services/NotificationManager.swift Models/ScheduleGroup.swift
# Assert: No syntax errors
```

**For UI Changes (Task 7 - TabView):**
```bash
# Build and verify:
xcodebuild -project Light_Lviv.xcodeproj -scheme Light_Lviv -destination 'platform=iOS Simulator,name=iPhone 15' build
# Assert: Build succeeds

# Manual verification steps (documented for user):
# 1. Launch app in simulator
# 2. Verify 2 tabs appear at bottom (Home, Notifications)
# 3. Tap Notifications tab - empty state or list appears
# 4. Return to Home tab - schedule list appears
```

**Evidence to Capture:**
- [ ] Build logs showing successful compilation
- [ ] Test output showing passed tests
- [ ] Screenshots of Notifications Tab UI

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately):
├── Task 0: Setup Test Infrastructure (independent)
└── Task 1: Fix Notification Bug (independent)

Wave 2 (After Wave 1 completes):
├── Task 2: Create NotificationHistory Model (depends on: 0)
├── Task 3: Implement Ring Buffer Persistence (depends on: 2)
└── Task 4: Write Unit Tests - ScheduleParser (depends on: 0)

Wave 3 (After Wave 2 completes):
├── Task 5: Implement Pre-Event Notifications (depends on: 1, 3)
├── Task 6: Write Unit Tests - NotificationManager (depends on: 0, 5)
└── Task 7: Expand Change Notifications to ALL Groups (depends on: 3)

Wave 4 (After Wave 3 completes):
├── Task 8: Create NotificationsTabView (depends on: 2, 3)
└── Task 9: Migrate to TabView Architecture (depends on: 8)

Critical Path: Task 1 → Task 5 (bug fix needed for pre-event notifications)
Parallel Speedup: ~30% faster than sequential
```

### Dependency Matrix

| Task | Depends On | Blocks | Can Parallelize With |
|------|------------|--------|---------------------|
| 0 (Test Infra) | None | 2, 4, 6 | 1 |
| 1 (Bug Fix) | None | 5, 7 | 0 |
| 2 (History Model) | 0 | 3, 8 | None (Wave 2) |
| 3 (Ring Buffer) | 2 | 5, 7, 8 | 4 |
| 4 (Tests Parser) | 0 | None | 2, 3 |
| 5 (Pre-Event) | 1, 3 | 6 | 7 |
| 6 (Tests Manager) | 0, 5 | None | 7 |
| 7 (All Groups) | 3 | None | 5, 6 |
| 8 (Tab View) | 2, 3 | 9 | None (Wave 4) |
| 9 (TabView Arch) | 8 | None | None (final) |

---

## TODOs

### Task 0: Setup Test Infrastructure

**What to do**:
- Add XCTest target to Xcode project
- Create test directory structure
- Add example test that passes
- Configure scheme for testing

**Must NOT do**:
- Don't add third-party test frameworks
- Don't write all tests now (just infrastructure)

**Recommended Agent Profile**:
- **Category**: `unspecified-high` (Xcode project modification)
- **Skills**: None required
- **Skills Evaluated**: git-master might help with project.pbxproj changes

**Parallelization**:
- **Can Run In Parallel**: YES
- **Parallel Group**: Wave 1
- **Blocks**: Tasks 2, 4, 6
- **Blocked By**: None

**References**:
- `Light_Lviv.xcodeproj/project.pbxproj` - Add test target
- `Light_Lviv.xcodeproj/xcshareddata/xcschemes/Light_Lviv.xcscheme` - Configure test scheme
- Apple Docs: https://developer.apple.com/documentation/xctest

**Acceptance Criteria**:
- [ ] Test target "Light_LvivTests" created in project
- [ ] Test directory `Light_LvivTests/` exists with at least one test file
- [ ] Build succeeds: `xcodebuild -scheme Light_Lviv build` returns exit code 0
- [ ] Tests run: `xcodebuild -scheme Light_LvivTests test` executes (may have 0 tests)
- [ ] Example test passes: At least one `XCTestCase` with one passing test method

**Commit**: YES (separate commit)
- Message: `chore(tests): add XCTest target and infrastructure`
- Files: `Light_Lviv.xcodeproj/project.pbxproj`, `Light_LvivTests/*`
- Pre-commit: Build and verify tests run

---

### Task 1: Fix Notification Timing Bug

**What to do**:
- Fix line 267 in NotificationManager.swift: change `<=` to `>=`
- The condition currently schedules notifications in the past
- Should only schedule future notifications

**Must NOT do**:
- Don't change any other notification logic
- Don't add features yet (just the bug fix)
- Don't touch the 15-minute offset calculation

**Recommended Agent Profile**:
- **Category**: `quick` (single line change)
- **Skills**: None required
- **Skills Evaluated**: None needed

**Parallelization**:
- **Can Run In Parallel**: YES
- **Parallel Group**: Wave 1
- **Blocks**: Task 5 (pre-event notifications need correct timing)
- **Blocked By**: None

**References**:
- `Services/NotificationManager.swift:267` - The bug location
```swift
// CURRENT (BUG):
if notifyDate <= Date() {  // Schedules past notifications

// FIXED:
if notifyDate >= Date() {  // Only schedule future notifications
```

**Acceptance Criteria**:
- [ ] Line 267 changed from `<=` to `>=`
- [ ] Build succeeds with no errors
- [ ] Code comment explaining the fix added

**Commit**: YES (separate commit before features)
- Message: `fix(notifications): correct timing condition for future notifications`
- Files: `Services/NotificationManager.swift`
- Pre-commit: Build succeeds

---

### Task 2: Create NotificationHistory Model

**What to do**:
- Create `Models/NotificationHistory.swift`
- Define NotificationItem struct with:
  - id: UUID
  - type: NotificationType enum (preEventOff, preEventOn, scheduleChange)
  - groupId: String
  - groupName: String
  - scheduledTime: Date? (for pre-event notifications)
  - timestamp: Date (when notification was created)
  - message: String
- Make it Codable for UserDefaults persistence
- Add example data for previews

**Must NOT do**:
- Don't implement persistence logic yet (just the model)
- Don't add UI code
- Don't change existing models

**Recommended Agent Profile**:
- **Category**: `quick` (new model file)
- **Skills**: None required

**Parallelization**:
- **Can Run In Parallel**: NO (Wave 2)
- **Parallel Group**: Wave 2
- **Blocks**: Task 3 (ring buffer needs model), Task 8 (tab view needs model)
- **Blocked By**: Task 0 (test infra for model validation)

**References**:
- `Models/ScheduleGroup.swift` - Pattern for models (Codable, example)
- `Services/NotificationManager.swift:171-174` - Notification types (modified, newDay)

**Acceptance Criteria**:
- [ ] File `Models/NotificationHistory.swift` created
- [ ] NotificationItem struct defined with all required properties
- [ ] NotificationType enum with 3 cases: prePowerOff, prePowerOn, scheduleChanged
- [ ] Codable conformance implemented
- [ ] Unit test: Can encode/decode NotificationItem (RED-GREEN)
- [ ] Build succeeds

**Commit**: YES
- Message: `feat(models): add NotificationHistory model with Codable support`
- Files: `Models/NotificationHistory.swift`, `Light_LvivTests/NotificationHistoryTests.swift`
- Pre-commit: Build and tests pass

---

### Task 3: Implement Ring Buffer Persistence

**What to do**:
- Create `Services/NotificationHistoryService.swift`
- Singleton pattern (like NotificationManager)
- Ring buffer: max 5 notifications, remove oldest when adding 6th
- Persist to UserDefaults with key "NotificationHistory"
- Methods:
  - `addNotification(_:)` - adds to buffer, removes oldest if needed
  - `getNotifications()` - returns array of last 5 (newest first)
  - `clearHistory()` - removes all
  - `markAsRead(id:)` - optional: track read status

**Must NOT do**:
- Don't exceed 5 notifications
- Don't implement UI yet
- Don't integrate with NotificationManager yet

**Recommended Agent Profile**:
- **Category**: `unspecified-low` (service logic)
- **Skills**: None required

**Parallelization**:
- **Can Run In Parallel**: NO (Wave 2)
- **Parallel Group**: Wave 2
- **Blocks**: Task 5, 7, 8 (all need history service)
- **Blocked By**: Task 2 (needs model)

**References**:
- `Services/NotificationManager.swift:29-37` - UserDefaults persistence pattern
- `Services/NotificationManager.swift:6-7` - Singleton pattern with @Observable

**Acceptance Criteria**:
- [ ] File `Services/NotificationHistoryService.swift` created
- [ ] Singleton class with @Observable
- [ ] Ring buffer implemented (max 5 items)
- [ ] UserDefaults persistence working
- [ ] Unit tests: Add 6 notifications, verify only last 5 remain (RED-GREEN)
- [ ] Unit tests: Verify persistence across service restarts (RED-GREEN)
- [ ] Build succeeds

**Commit**: YES
- Message: `feat(service): add NotificationHistoryService with ring buffer`
- Files: `Services/NotificationHistoryService.swift`, `Light_LvivTests/NotificationHistoryServiceTests.swift`
- Pre-commit: Build and tests pass

---

### Task 4: Write Unit Tests - ScheduleParser

**What to do**:
- Create `Light_LvivTests/ScheduleParserTests.swift`
- Test `parse(text:)` method:
  - Valid time ranges "10:00-12:00"
  - Multiple ranges in one string
  - Invalid formats (should return empty)
  - Edge cases: midnight, 24:00
- Test `calculateGaps(in:)`:
  - Gap at start of day
  - Gap between OFF periods
  - Gap at end of day
- Test `getCurrentStatus(schedule:)`:
  - During OFF period
  - During ON period

**Must NOT do**:
- Don't test private methods directly
- Don't mock unless necessary (test actual parsing)
- Don't test UI

**Recommended Agent Profile**:
- **Category**: `quick` (unit tests)
- **Skills**: None required

**Parallelization**:
- **Can Run In Parallel**: YES (Wave 2)
- **Parallel Group**: Wave 2
- **Blocks**: None
- **Blocked By**: Task 0 (test infrastructure)

**References**:
- `Services/ScheduleParser.swift` - All public methods to test
- `Models/ScheduleGroup.swift:24` - Example schedule text format

**Acceptance Criteria**:
- [ ] Test file created with test class `ScheduleParserTests`
- [ ] Minimum 5 test methods covering parse(), calculateGaps(), getCurrentStatus()
- [ ] All tests pass (Cmd+U)
- [ ] Tests cover edge cases (empty string, no matches, overlapping times)

**Commit**: YES (can group with Task 2 or separate)
- Message: `test(parser): add unit tests for ScheduleParser`
- Files: `Light_LvivTests/ScheduleParserTests.swift`
- Pre-commit: All tests pass

---

### Task 5: Implement Pre-Event Notifications (15 min before)

**What to do**:
- Modify `NotificationManager.scheduleEvent()` to handle pre-event scheduling
- Calculate "notifyDate" as eventTime minus 15 minutes
- Only schedule if group is subscribed
- Schedule TWO notifications per time range:
  1. 15 min before power OFF starts
  2. 15 min before power OFF ends (power ON)
- Use existing localization strings for titles/body
- When scheduling, also add to NotificationHistoryService

**Must NOT do**:
- Don't change the 15-minute offset (requirement is fixed)
- Don't notify for unsubscribed groups
- Don't schedule if notifyDate is in the past (already fixed in Task 1)

**Recommended Agent Profile**:
- **Category**: `unspecified-high` (complex notification logic)
- **Skills**: None required

**Parallelization**:
- **Can Run In Parallel**: NO (Wave 3)
- **Parallel Group**: Wave 3
- **Blocks**: Task 6 (tests need implementation)
- **Blocked By**: Task 1 (bug fix), Task 3 (history service)

**References**:
- `Services/NotificationManager.swift:255-288` - Current scheduleEvent method
- `Services/NotificationManager.swift:236-253` - EventType enum with powerOff/powerOn
- `Services/NotificationHistoryService.swift` - Add notifications to history
- `Utilities/Localization.swift:34-37` - Title/body templates

**Acceptance Criteria**:
- [ ] scheduleEvent() schedules 15 min before each OFF start
- [ ] scheduleEvent() schedules 15 min before each OFF end (ON notification)
- [ ] Only subscribed groups get notifications
- [ ] Each scheduled notification added to NotificationHistoryService
- [ ] Unit test: Verify notifications scheduled at correct times (RED-GREEN)
- [ ] Build succeeds

**Commit**: YES
- Message: `feat(notifications): add 15-minute pre-event notifications`
- Files: `Services/NotificationManager.swift`
- Pre-commit: Build and tests pass

---

### Task 6: Write Unit Tests - NotificationManager

**What to do**:
- Create `Light_LvivTests/NotificationManagerTests.swift`
- Test subscription management:
  - subscribe/unsubscribe adds/removes from set
  - Persistence across restarts
- Test notification scheduling (mock UNUserNotificationCenter if needed)
- Test change detection:
  - Detects when schedule changes
  - Correctly identifies today vs tomorrow changes
- Test nickname functionality

**Must NOT do**:
- Don't test actual push notification delivery (system responsibility)
- Don't test UI presentation

**Recommended Agent Profile**:
- **Category**: `unspecified-low` (unit tests with mocking)
- **Skills**: None required

**Parallelization**:
- **Can Run In Parallel**: YES (Wave 3)
- **Parallel Group**: Wave 3
- **Blocks**: None
- **Blocked By**: Task 0 (infrastructure), Task 5 (implementation)

**References**:
- `Services/NotificationManager.swift` - All methods to test
- XCTest documentation for mocking: https://developer.apple.com/documentation/xctest

**Acceptance Criteria**:
- [ ] Test file created with `NotificationManagerTests` class
- [ ] Tests for subscribe/unsubscribe persistence
- [ ] Tests for change detection logic
- [ ] Tests for nickname save/load
- [ ] All tests pass
- [ ] Minimum 80% coverage of NotificationManager

**Commit**: YES
- Message: `test(notifications): add unit tests for NotificationManager`
- Files: `Light_LvivTests/NotificationManagerTests.swift`
- Pre-commit: All tests pass

---

### Task 7: Expand Change Notifications to ALL Groups

**What to do**:
- Modify `NotificationManager.checkForChanges()`
- Currently only checks subscribed groups (line 120: `guard subscribedGroups.contains`)
- Change to check ALL groups passed in parameter
- For each changed group:
  - Send push notification (existing behavior for subscribed)
  - ALWAYS add to NotificationHistoryService (new behavior for all)
- Keep unread indicators working (unreadChanges/unreadNewDay sets)

**Must NOT do**:
- Don't remove push notifications for subscribed groups
- Don't change the unread indicator logic
- Don't mark changes as read automatically

**Recommended Agent Profile**:
- **Category**: `unspecified-low` (modify existing method)
- **Skills**: None required

**Parallelization**:
- **Can Run In Parallel**: YES (Wave 3)
- **Parallel Group**: Wave 3
- **Blocks**: None
- **Blocked By**: Task 3 (history service must exist)

**References**:
- `Services/NotificationManager.swift:118-169` - checkForChanges method
- `Services/NotificationManager.swift:120` - Current subscribed-only guard
- `ViewModels/ScheduleViewModel.swift:107-108` - Where checkForChanges is called

**Acceptance Criteria**:
- [ ] checkForChanges processes ALL groups, not just subscribed
- [ ] Push notifications still only sent to subscribed groups
- [ ] All changed groups added to NotificationHistoryService
- [ ] Red dot markers still work correctly (unreadChanges tracking)
- [ ] Unit test: Unsubscribed group change appears in history (RED-GREEN)
- [ ] Build succeeds

**Commit**: YES
- Message: `feat(notifications): notify all groups of schedule changes`
- Files: `Services/NotificationManager.swift`
- Pre-commit: Build and tests pass

---

### Task 8: Create NotificationsTabView

**What to do**:
- Create `Views/Notifications/NotificationsTabView.swift`
- Display list of notifications from NotificationHistoryService
- Each row shows:
  - Icon (bell for pre-event, exclamationmark for change)
  - Group name
  - Message
  - Timestamp (relative: "2 hours ago" or absolute)
- Empty state when no notifications
- Support swipe-to-delete (optional)
- Use dark theme consistent with rest of app

**Must NOT do**:
- Don't implement tab switching yet (just the view)
- Don't change NavigationStack yet
- Don't show more than 5 notifications

**Recommended Agent Profile**:
- **Category**: `visual-engineering` (UI component)
- **Skills**: ["frontend-ui-ux"]
- **Skills Evaluated**: dev-browser not needed (no web), playwright not needed

**Parallelization**:
- **Can Run In Parallel**: NO (Wave 4)
- **Parallel Group**: Wave 4
- **Blocks**: Task 9 (TabView needs this view)
- **Blocked By**: Task 2, 3 (needs model and service)

**References**:
- `Views/Schedule/ScheduleDetailView.swift` - Dark theme patterns
- `Views/Components/GroupCardView.swift` - Card styling
- `Views/ContentView.swift:36-53` - Empty state pattern
- `Utilities/AppTheme.swift` - Theme constants

**Acceptance Criteria**:
- [ ] File `Views/Notifications/NotificationsTabView.swift` created
- [ ] View displays list of notifications from service
- [ ] Each row shows icon, group, message, timestamp
- [ ] Empty state when no notifications
- [ ] Dark theme styling consistent with app
- [ ] Preview provider with example data
- [ ] Build succeeds

**Commit**: YES
- Message: `feat(ui): add NotificationsTabView with notification list`
- Files: `Views/Notifications/NotificationsTabView.swift`
- Pre-commit: Build succeeds, preview renders

---

### Task 9: Migrate to TabView Architecture

**What to do**:
- Modify `App/Light_LvivApp.swift`:
  - Replace WindowGroup ContentView with TabView
  - Two tabs: Home (schedule list), Notifications
- Create `Views/MainTabView.swift` (optional, or do in App.swift):
  - TabView with two Tab items
  - First tab: ContentView (existing)
  - Second tab: NotificationsTabView (new)
- Update `Views/ContentView.swift`:
  - Remove NavigationStack wrapper (or keep for detail navigation)
  - Keep internal navigation working
- Add tab icons: house.fill for Home, bell.fill for Notifications
- Handle badge count on Notifications tab (number of unread)

**Must NOT do**:
- Don't remove ContentView (keep as Home tab content)
- Don't break existing navigation within tabs
- Don't change the visual design significantly

**Recommended Agent Profile**:
- **Category**: `visual-engineering` (architecture change)
- **Skills**: ["frontend-ui-ux"]

**Parallelization**:
- **Can Run In Parallel**: NO (Wave 4 - final task)
- **Parallel Group**: Wave 4
- **Blocks**: None (final task)
- **Blocked By**: Task 8 (needs NotificationsTabView)

**References**:
- `App/Light_LvivApp.swift` - Entry point to modify
- `Views/ContentView.swift` - Current root view
- SwiftUI TabView documentation: https://developer.apple.com/documentation/swiftui/tabview

**Acceptance Criteria**:
- [ ] TabView with 2 tabs appears at bottom of screen
- [ ] Home tab shows schedule list (ContentView)
- [ ] Notifications tab shows notification history
- [ ] Tab switching works smoothly
- [ ] Navigation within tabs preserved (detail views work)
- [ ] Tab icons: house.fill and bell.fill
- [ ] Build succeeds
- [ ] UI test: Can switch between tabs

**Commit**: YES (final commit)
- Message: `feat(ui): migrate to TabView with Home and Notifications tabs`
- Files: `App/Light_LvivApp.swift`, `Views/ContentView.swift` (minor), `Views/MainTabView.swift` (if created)
- Pre-commit: Build succeeds, UI verified

---

## Commit Strategy

| After Task | Message | Files | Verification |
|------------|---------|-------|--------------|
| 0 | `chore(tests): add XCTest target and infrastructure` | Test target, scheme | Build + tests run |
| 1 | `fix(notifications): correct timing condition for future notifications` | NotificationManager.swift | Build |
| 2 | `feat(models): add NotificationHistory model with Codable support` | NotificationHistory.swift, Tests | Tests pass |
| 3 | `feat(service): add NotificationHistoryService with ring buffer` | NotificationHistoryService.swift, Tests | Tests pass |
| 4 | `test(parser): add unit tests for ScheduleParser` | ScheduleParserTests.swift | Tests pass |
| 5 | `feat(notifications): add 15-minute pre-event notifications` | NotificationManager.swift | Tests pass |
| 6 | `test(notifications): add unit tests for NotificationManager` | NotificationManagerTests.swift | Tests pass |
| 7 | `feat(notifications): notify all groups of schedule changes` | NotificationManager.swift | Tests pass |
| 8 | `feat(ui): add NotificationsTabView with notification list` | NotificationsTabView.swift | Build |
| 9 | `feat(ui): migrate to TabView with Home and Notifications tabs` | App.swift, ContentView.swift, MainTabView.swift | Build + UI test |

---

## Success Criteria

### Verification Commands
```bash
# Build project
xcodebuild -project Light_Lviv.xcodeproj -scheme Light_Lviv -destination 'platform=iOS Simulator,name=iPhone 15' build
# Expected: Build succeeds (exit code 0)

# Run all tests
xcodebuild -project Light_Lviv.xcodeproj -scheme Light_LvivTests -destination 'platform=iOS Simulator,name=iPhone 15' test
# Expected: All tests pass

# Verify specific test classes
xcodebuild -project Light_Lviv.xcodeproj -scheme Light_LvivTests -destination 'platform=iOS Simulator,name=iPhone 15' test -only-testing Light_LvivTests/ScheduleParserTests
xcodebuild -project Light_Lviv.xcodeproj -scheme Light_LvivTests -destination 'platform=iOS Simulator,name=iPhone 15' test -only-testing Light_LvivTests/NotificationManagerTests
```

### Final Checklist
- [ ] Bug fix committed separately (Task 1)
- [ ] Test infrastructure exists (Task 0)
- [ ] All unit tests pass (Tasks 4, 6)
- [ ] NotificationHistory model created (Task 2)
- [ ] Ring buffer service working (Task 3)
- [ ] Pre-event notifications implemented (Task 5)
- [ ] All groups notified of changes (Task 7)
- [ ] NotificationsTabView created (Task 8)
- [ ] TabView architecture migrated (Task 9)
- [ ] App builds without warnings
- [ ] Red dot markers still work on GroupCardView

---

## Risk Analysis

### Technical Risks
1. **TabView Migration Complexity**: Current NavigationStack → TabView change could break detail navigation
   - Mitigation: Keep NavigationStack inside each tab
2. **UserDefaults Size**: Storing notification history could exceed limits
   - Mitigation: Ring buffer limits to 5 notifications max
3. **UNUserNotificationCenter Testing**: Hard to test actual notifications in simulator
   - Mitigation: Test scheduling logic, not delivery
4. **Timing Edge Cases**: Pre-event notifications across midnight, timezone issues
   - Mitigation: Use Calendar.current consistently

### Scope Risks
1. **Feature Creep**: User might want more than 5 notifications
   - Guardrail: Explicitly limited to 5 in requirements
2. **Notification Spam**: All groups change notification could be noisy
   - Guardrail: Only when actually changed, ring buffer limits history

---

## Notes for Executor

### Key Implementation Details

**NotificationHistory Model Structure**:
```swift
struct NotificationItem: Codable, Identifiable {
    let id: UUID
    let type: NotificationType
    let groupId: String
    let groupName: String
    let scheduledTime: Date?  // For pre-event notifications
    let timestamp: Date       // When notification created
    let message: String
}

enum NotificationType: String, Codable {
    case prePowerOff      // 15 min before power goes OFF
    case prePowerOn       // 15 min before power comes ON
    case scheduleChanged  // Schedule changed after rescraping
}
```

**Ring Buffer Implementation**:
```swift
class NotificationHistoryService: ObservableObject {
    static let shared = NotificationHistoryService()
    private let maxCount = 5
    private let saveKey = "NotificationHistory"
    
    @Published var notifications: [NotificationItem] = []
    
    func addNotification(_ item: NotificationItem) {
        notifications.insert(item, at: 0)
        if notifications.count > maxCount {
            notifications = Array(notifications.prefix(maxCount))
        }
        save()
    }
    // ...
}
```

**Pre-Event Scheduling Logic**:
```swift
// In scheduleEvent(), for each OFF time range:
// 1. Schedule OFF notification: range.start - 15 minutes
// 2. Schedule ON notification: range.end - 15 minutes
// Only if notifyDate >= Date() (fixed in Task 1)
// Only if group is subscribed
```

**TabView Structure**:
```swift
// In Light_LvivApp.swift:
@main
struct Light_LvivApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                
                NotificationsTabView()
                    .tabItem {
                        Label("Notifications", systemImage: "bell.fill")
                    }
            }
        }
    }
}
```

### Critical Code Locations

1. **Bug Fix**: `Services/NotificationManager.swift:267`
2. **Pre-Event Logic**: `Services/NotificationManager.swift:255-288`
3. **Change Detection**: `Services/NotificationManager.swift:118-169`
4. **Red Dot Marker**: `Views/Components/GroupCardView.swift:47-52`
5. **Entry Point**: `App/Light_LvivApp.swift`

### Testing Priority
1. ScheduleParser tests (pure logic, easy to test)
2. NotificationHistoryService tests (isolated state)
3. NotificationManager tests (requires mocking)

### Common Pitfalls
1. Don't forget to save to UserDefaults after modifying notification history
2. Ensure thread safety when modifying shared state (use @MainActor)
3. Test on real device for actual push notification behavior (simulator limited)
4. Remember to request notification permission in ContentView.task
