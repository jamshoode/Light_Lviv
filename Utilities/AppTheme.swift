import SwiftUI

struct AppTheme {
    static let cardGradient = LinearGradient(
        colors: [
            Color(red: 22/255, green: 25/255, blue: 35/255), // #161923
            Color(red: 12/255, green: 13/255, blue: 18/255)  // #0C0D12 (Darker)
        ],
        startPoint: .topLeading,
        endPoint: .bottom
    )
    
    static let cardStroke = Color(white: 0.2)
    static let cardRadius: CGFloat = 24
}
