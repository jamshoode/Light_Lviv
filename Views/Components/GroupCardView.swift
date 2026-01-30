import SwiftUI
import Combine

struct GroupCardView: View {
    let group: ScheduleGroup
    @State private var status: ScheduleType = .powerOn
    @State private var timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(group.customName ?? group.subGroupName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                
                if group.customName != nil {
                     Text(group.subGroupName)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                
                if status == .powerOn {
                    Text(Localization.get("lightIsOn"))
                        .font(.body)
                        .foregroundStyle(Color(red: 0.2, green: 0.8, blue: 0.2))
                } else {
                    Text(Localization.get("lightIsOff"))
                        .font(.body)
                        .foregroundStyle(.gray)
                }
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .fill(status == .powerOn ? Color(red: 0.2, green: 0.8, blue: 0.2) : Color.red)
                    .frame(width: 40, height: 40)
                    .shadow(color: (status == .powerOn ? Color.green : Color.red).opacity(0.5), radius: 8)
                
                Image(systemName: "bolt.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
            }
            .overlay(
                ZStack {
                     if NotificationManager.shared.hasUnreadChanges(group: group) || NotificationManager.shared.hasUnreadNewDay(group: group) {
                         Circle()
                             .fill(Color.red)
                             .frame(width: 12, height: 12)
                             .offset(x: 24, y: -30)
                     }
                }
            )
        }
        .padding(24)
        .background(AppTheme.cardGradient)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        )
        .onAppear {
            updateStatus()
        }
        .onReceive(timer) { _ in
            updateStatus()
        }
    }
    
    private func updateStatus() {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        let todayKey = formatter.string(from: Date())
        
        if let schedule = group.schedules[todayKey] {
            status = ScheduleParser.shared.getCurrentStatus(schedule: schedule)
        } else {
            status = .powerOn
        }
    }
}
