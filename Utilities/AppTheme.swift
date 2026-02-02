import SwiftUI
import Foundation

struct AppTheme {
    static let cardGradient: LinearGradient = {
        let angleDegrees: Double = -83
        let angleRadians = angleDegrees * .pi / 180
        
        let centerX: Double = 0.2
        let centerY: Double = 0.2
        let length: Double = 0.8
        
        let startX = centerX - length * cos(angleRadians)
        let startY = centerY + length * sin(angleRadians)
        let endX = centerX + length * cos(angleRadians)
        let endY = centerY - length * sin(angleRadians)
        
        return LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color("Dark gradient"), location: 0.0),
                .init(color: Color("Dark gradient"), location: 0.0),
                .init(color: Color("Dark blue gradient"), location: 1.0),
                .init(color: Color("Dark blue gradient"), location: 1.0)
            ]),
            startPoint: UnitPoint(x: max(0, min(1, startX)), y: max(0, min(1, startY))),
            endPoint: UnitPoint(x: max(0, min(1, endX)), y: max(0, min(1, endY)))
        )
    }()
    
    static let cardStroke = Color("Card border")
    static let cardRadius: CGFloat = 24
}
