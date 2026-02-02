import WidgetKit
import SwiftUI

struct PowerStatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> PowerStatusEntry {
        PowerStatusEntry(
            date: Date(),
            isPowerOn: true,
            nextEvent: Date().addingTimeInterval(900),
            groupName: "1.1",
            todaySchedules: [],
            tomorrowSchedules: [],
            lastUpdated: Date()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PowerStatusEntry) -> ()) {
        let entry = loadEntryFromSharedData() ?? placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PowerStatusEntry>) -> ()) {
        var entries: [PowerStatusEntry] = []
        let currentDate = Date()
        
        let baseEntry = loadEntryFromSharedData() ?? placeholder(in: context)
        
        for offset in 0..<24 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: offset * 15, to: currentDate)!
            
            var entry = baseEntry
            entry.date = entryDate
            
            if let nextEvent = entry.nextEvent {
                let minutesUntil = Int(nextEvent.timeIntervalSince(entryDate) / 60)
                if minutesUntil <= 0 {
                    entry.isPowerOn.toggle()
                    entry.nextEvent = calculateNextEvent(from: entryDate, isPowerOn: entry.isPowerOn, schedules: entry.todaySchedules)
                }
            }
            
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    private func loadEntryFromSharedData() -> PowerStatusEntry? {
        guard let data = SharedDataManager.shared.loadPowerData() else { return nil }
        
        return PowerStatusEntry(
            date: Date(),
            isPowerOn: data.status == .on,
            nextEvent: data.nextEventDate,
            groupName: data.groupName,
            todaySchedules: data.todaySchedules,
            tomorrowSchedules: data.tomorrowSchedules,
            lastUpdated: data.lastUpdated
        )
    }
    
    private func calculateNextEvent(from date: Date, isPowerOn: Bool, schedules: [ScheduleEntry]) -> Date? {
        return nil
    }
}
