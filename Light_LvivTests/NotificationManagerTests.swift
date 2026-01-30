import XCTest
@testable import Light_Lviv

final class NotificationManagerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clear UserDefaults before each test
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "SubscribedGroupIDs")
        defaults.removeObject(forKey: "LastKnownSchedules")
        defaults.removeObject(forKey: "PreviousSchedules")
        defaults.removeObject(forKey: "UnreadChangesIDs")
        defaults.removeObject(forKey: "UnreadNewDayIDs")
        defaults.removeObject(forKey: "GroupNicknames")
        defaults.removeObject(forKey: "NotificationHistory")
        
        // Reset singleton state
        NotificationManager.shared.subscribedGroups.removeAll()
        NotificationManager.shared.currentSchedules.removeAll()
        NotificationManager.shared.previousSchedules.removeAll()
        NotificationManager.shared.unreadChanges.removeAll()
        NotificationManager.shared.unreadNewDayChanges.removeAll()
        NotificationManager.shared.groupNicknames.removeAll()
    }
    
    // MARK: - Subscription Tests
    
    func testSubscribeAddsGroupToSet() {
        let group = ScheduleGroup(id: "1.1", subGroupName: "1.1", schedules: [:], lastUpdateTimestamp: nil)
        
        NotificationManager.shared.subscribe(group: group)
        
        XCTAssertTrue(NotificationManager.shared.isSubscribed(group: group))
    }
    
    func testUnsubscribeRemovesGroupFromSet() {
        let group = ScheduleGroup(id: "1.1", subGroupName: "1.1", schedules: [:], lastUpdateTimestamp: nil)
        NotificationManager.shared.subscribe(group: group)
        
        NotificationManager.shared.unsubscribe(group: group)
        
        XCTAssertFalse(NotificationManager.shared.isSubscribed(group: group))
    }
    
    func testSubscriptionPersistsAcrossInstances() {
        let group = ScheduleGroup(id: "1.1", subGroupName: "1.1", schedules: [:], lastUpdateTimestamp: nil)
        NotificationManager.shared.subscribe(group: group)
        
        // Simulate app restart by creating new instance
        // In real scenario, this would be handled by singleton pattern
        // This test verifies persistence mechanism works
        let savedGroups = UserDefaults.standard.array(forKey: "SubscribedGroupIDs") as? [String]
        XCTAssertEqual(savedGroups, ["1.1"])
    }
    
    // MARK: - Nickname Tests
    
    func testSetNickname() {
        let group = ScheduleGroup(id: "1.1", subGroupName: "1.1", schedules: [:], lastUpdateTimestamp: nil)
        
        NotificationManager.shared.setNickname("My Home", for: group)
        
        XCTAssertEqual(NotificationManager.shared.getNickname(for: group), "My Home")
    }
    
    func testRemoveNicknameWithEmptyString() {
        let group = ScheduleGroup(id: "1.1", subGroupName: "1.1", schedules: [:], lastUpdateTimestamp: nil)
        NotificationManager.shared.setNickname("My Home", for: group)
        
        NotificationManager.shared.setNickname("", for: group)
        
        XCTAssertNil(NotificationManager.shared.getNickname(for: group))
    }
    
    // MARK: - Change Detection Tests
    
    func testCheckForChangesDetectsTodayChange() {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        let todayKey = formatter.string(from: Date())
        
        let group = ScheduleGroup(
            id: "1.1",
            subGroupName: "1.1",
            schedules: [todayKey: "10:00 - 12:00"],
            lastUpdateTimestamp: nil
        )
        
        // Set up initial state
        NotificationManager.shared.currentSchedules[group.id] = [todayKey: "08:00 - 10:00"]
        NotificationManager.shared.subscribedGroups.insert(group.id)
        
        // Check for changes
        NotificationManager.shared.checkForChanges(in: [group])
        
        // Verify change was detected
        XCTAssertTrue(NotificationManager.shared.hasUnreadChanges(group: group))
        XCTAssertTrue(NotificationManager.shared.hasPreviousSchedule(group: group))
    }
    
    func testMarkAsReadClearsUnreadChanges() {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        let todayKey = formatter.string(from: Date())
        
        let group = ScheduleGroup(
            id: "1.1",
            subGroupName: "1.1",
            schedules: [todayKey: "10:00 - 12:00"],
            lastUpdateTimestamp: nil
        )
        
        NotificationManager.shared.currentSchedules[group.id] = [todayKey: "08:00 - 10:00"]
        NotificationManager.shared.subscribedGroups.insert(group.id)
        NotificationManager.shared.checkForChanges(in: [group])
        
        NotificationManager.shared.markAsRead(group: group)
        
        XCTAssertFalse(NotificationManager.shared.hasUnreadChanges(group: group))
    }
    
    // MARK: - Notification History Integration Tests
    
    func testScheduleChangeAddsToNotificationHistory() {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        let todayKey = formatter.string(from: Date())
        
        let group = ScheduleGroup(
            id: "1.1",
            subGroupName: "1.1",
            schedules: [todayKey: "10:00 - 12:00"],
            lastUpdateTimestamp: nil
        )
        
        // Clear history first
        NotificationHistoryService.shared.clearHistory()
        
        // Set up initial state
        NotificationManager.shared.currentSchedules[group.id] = [todayKey: "08:00 - 10:00"]
        
        // Check for changes (unsubscribed group)
        NotificationManager.shared.checkForChanges(in: [group])
        
        // Verify notification was added to history even for unsubscribed group
        let history = NotificationHistoryService.shared.getNotifications()
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history[0].groupId, "1.1")
        XCTAssertEqual(history[0].type, .scheduleChanged)
    }
}
