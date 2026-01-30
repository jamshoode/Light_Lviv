import SwiftUI

struct NotificationsTabView: View {
    @State private var notifications = NotificationHistoryService()
    @State var badgeCount: Int = 0
    let notificationCenter = UNUserNotificationCenter.current()
    
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                if notifications.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 60))
                            .foregroundStyle(.gray)
                        Text(Localization.get("noNotifHead"))
                            .font(.headline)
                            .foregroundStyle(.gray)
                    }
                } else {
                    List {
                        ForEach(notifications.displayNotifications) { notification in
                            NotificationRowView(notification: notification)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(Localization.get("notifTitle"))
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    Button(action: {
                        notifications.clearHistory()
                    }) {
                        Image(systemName: "trash")
                    }
                    .glassEffect()
                }
            }

        }
        .preferredColorScheme(.dark)
    }
    
}

struct NotificationRowView: View {
    let notification: NotificationItem
    
    var iconName: String {
        switch notification.type {
        case .prePowerOff:
            return "bell.fill"
        case .prePowerOn:
            return "bell.fill"
        case .scheduleChanged:
            return "exclamationmark.triangle.fill"
        }
    }
    
    var iconColor: Color {
        switch notification.type {
        case .prePowerOff:
            return .red
        case .prePowerOn:
            return .green
        case .scheduleChanged:
            return .yellow
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.groupName)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .lineLimit(2)
                
                Text(timeAgo(from: notification.timestamp))
                    .font(.caption)
                    .foregroundStyle(.gray.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NotificationsTabView()
}
