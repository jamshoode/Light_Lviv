import ActivityKit
import Foundation

struct PowerOutageAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var isPowerOn: Bool
        var minutesUntilChange: Int
        var progress: Double
        
        init(isPowerOn: Bool, minutesUntilChange: Int, progress: Double) {
            self.isPowerOn = isPowerOn
            self.minutesUntilChange = minutesUntilChange
            self.progress = progress
        }
    }
    
    var groupName: String
    var targetTime: Date
    var eventType: EventType
}

enum EventType: String, Codable {
    case powerOff
    case powerOn
}
