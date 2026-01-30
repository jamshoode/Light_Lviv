import SwiftUI

struct NotificationsTabView: View {
    @State private var notifications: [NotificationItem] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                if notifications.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 60))
                            .foregroundStyle(.gray)
                        
                        Text("No notifications yet")
                            .font(.headline)
                            .foregroundStyle(.gray)
                        
                        Text("Schedule changes and power alerts will appear here")
                            .font(.subheadline)
                            .foregroundStyle(.gray.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    List {
                        ForEach(notifications) { notification in
                            NotificationRowView(notification: notification)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Notifications")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                notifications = NotificationHistoryService.shared.getNotifications()
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
