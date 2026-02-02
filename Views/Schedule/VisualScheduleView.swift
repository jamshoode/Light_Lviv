import SwiftUI

struct VisualScheduleView: View {
    let text: String
    let isCompact: Bool
    
    init(text: String, isCompact: Bool = false) {
        self.text = text
        self.isCompact = isCompact
    }
    
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
                HStack(spacing: isCompact ? 8 : 16) {
                    Text(range.timeString)
                        .font(isCompact ? .system(.caption, design: .monospaced) : .system(.body, design: .monospaced))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Spacer()
                    
                    if isCompact {
                        Circle()
                            .fill(range.type == .powerOff ? Color.red : Color.green)
                            .frame(width: 8, height: 8)
                    } else {
                        Text(range.type == .powerOff ? Localization.get("powerOff_title") : Localization.get("powerOn_title"))
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(range.type == .powerOff ? Color.red.opacity(0.3) : Color.green.opacity(0.3))
                            .foregroundStyle(range.type == .powerOff ? Color.red : Color.green)
                            .cornerRadius(4)
                    }
                }
                .padding(isCompact ? 8 : 16)
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundStyle(Color(white: 0.2)),
                    alignment: .bottom
                )
            }
        }
        .background(AppTheme.cardGradient)
        .cornerRadius(isCompact ? 16 : 24)
        .overlay(
            RoundedRectangle(cornerRadius: isCompact ? 16 : 24)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        )
    }
}
