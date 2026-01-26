import Foundation

enum ScheduleType {
    case powerOff
    case powerOn
}

struct TimeRange: Hashable, Identifiable {
    let id = UUID()
    let start: DateComponents
    let end: DateComponents
    let type: ScheduleType
    
    var timeString: String {
        return "\(format(time: start)) - \(format(time: end))"
    }
    
    private func format(time: DateComponents) -> String {
        String(format: "%02d:%02d", time.hour ?? 0, time.minute ?? 0)
    }
}

class ScheduleParser {
    static let shared = ScheduleParser()
    
    private init() {}
    
    func parse(text: String) -> [TimeRange] {
        var ranges: [TimeRange] = []
        
        let pattern = "(\\d{1,2}:\\d{2})\\s*(?:до|-)\\s*(\\d{1,2}:\\d{2})"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsString = text as NSString
        let matches = regex?.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        
        for match in matches {
            let startString = nsString.substring(with: match.range(at: 1))
            let endString = nsString.substring(with: match.range(at: 2))
            
            if let start = parseTime(startString), let end = parseTime(endString) {
                ranges.append(TimeRange(start: start, end: end, type: .powerOff))
            }
        }
        
        return ranges.sorted {
            let h1 = $0.start.hour ?? 0
            let h2 = $1.start.hour ?? 0
            if h1 != h2 { return h1 < h2 }
            return ($0.start.minute ?? 0) < ($1.start.minute ?? 0)
        }
    }
    
    /// Infers "Power ON" times (gaps between Power OFF times)
    func calculateGaps(in ranges: [TimeRange]) -> [TimeRange] {
        // Assume day is 00:00 to 24:00 (which is 00:00 next day)
        var gaps: [TimeRange] = []
        var currentHour = 0
        var currentMinute = 0
        
        let sorted = ranges.sorted {
            let h1 = $0.start.hour ?? 0
            let h2 = $1.start.hour ?? 0
            if h1 != h2 { return h1 < h2 }
            return ($0.start.minute ?? 0) < ($1.start.minute ?? 0)
        }
        
        for range in sorted {
            let startH = range.start.hour ?? 0
            let startM = range.start.minute ?? 0
            
            // Check if there is a gap before this range
            if currentHour < startH || (currentHour == startH && currentMinute < startM) {
                // There is a gap
                let gapStart = DateComponents(hour: currentHour, minute: currentMinute)
                let gapEnd = range.start
                gaps.append(TimeRange(start: gapStart, end: gapEnd, type: .powerOn))
            }
            
            // Move current pointer to end of this range
            currentHour = range.end.hour ?? 0
            currentMinute = range.end.minute ?? 0
        }
        
        // Check for remaining gap at end of day (up to 24:00)
        if currentHour < 24 {
             let gapStart = DateComponents(hour: currentHour, minute: currentMinute)
             let gapEnd = DateComponents(hour: 24, minute: 0) // Treat 24:00 as end of day
             gaps.append(TimeRange(start: gapStart, end: gapEnd, type: .powerOn))
        }
        
        return gaps
    }
    
    private func parseTime(_ timeString: String) -> DateComponents? {
        let parts = timeString.split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else { return nil }
        return DateComponents(hour: hour, minute: minute)
    }
    
    /// Checks the current status based on the schedule text
    func getCurrentStatus(schedule: String) -> ScheduleType {
        let ranges = parse(text: schedule)
        
        let now = Date()
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.hour, .minute], from: now)
        let currentHour = currentComponents.hour ?? 0
        let currentMinute = currentComponents.minute ?? 0
        let currentTotal = currentHour * 60 + currentMinute
        
        for range in ranges {
            // Check if current time is within this OFF range
            let startH = range.start.hour ?? 0
            let startM = range.start.minute ?? 0
            let startTotal = startH * 60 + startM
            
            let endH = range.end.hour ?? 0
            let endM = range.end.minute ?? 0
            let endTotal = endH * 60 + endM
            
            // Handle cross-midnight if needed, but usually schedule is 00-24
            if currentTotal >= startTotal && currentTotal < endTotal {
                return .powerOff
            }
        }
        
        return .powerOn
    }
}
