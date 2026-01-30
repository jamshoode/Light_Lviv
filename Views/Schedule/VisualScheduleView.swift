import SwiftUI

struct VisualScheduleView: View {
    let text: String
    
    var ranges: [TimeRange] {
        let off = ScheduleParser.shared.parse(text: text)
        let on = ScheduleParser.shared.calculateGaps(in: off)
        return (off + on).sorted {
            let h1 = $0.start.hour ?? 0
            let h2 = $1.start.hour ?? 0
            if h1 != h2 { return h1 < h2 }
            return ($0.start.minute ?? 0) < ($1.start.minute ?? 0)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(ranges) { range in
                HStack {
                    Text(range.timeString)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.white)
                        .frame(width: 180, alignment: .leading)
                    
                    Spacer()
                    
                    Text(range.type == .powerOff ? Localization.get("powerOff_title") : Localization.get("powerOn_title"))
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(range.type == .powerOff ? Color.red.opacity(0.3) : Color.green.opacity(0.3))
                        .foregroundStyle(range.type == .powerOff ? Color.red : Color.green)
                        .cornerRadius(4)
                }
                .padding()
                .padding()
                // No item background, let container show through
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundStyle(Color(white: 0.2)),
                    alignment: .bottom
                )
            }
        }
        .background(AppTheme.cardGradient)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        )
    }
}
