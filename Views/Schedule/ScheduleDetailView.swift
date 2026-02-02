import SwiftUI

struct ScheduleDetailView: View {
    let group: ScheduleGroup
    @State private var isSubscribed = false
    @State private var isWidgetGroup = false
    @State private var displayedName: String?
    @State private var selectedDateKey: String = ""
    
    var sortedDates: [String] {
        group.schedules.keys.sorted { d1, d2 in
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yyyy"
            let date1 = formatter.date(from: d1) ?? Date.distantPast
            let date2 = formatter.date(from: d2) ?? Date.distantPast
            return date1 < date2
        }
    }
    
    var todayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: Date())
    }
    
    var tomorrowKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
    }
    
    var displayText: String {
        if let text = group.schedules[selectedDateKey] {
            var cleaned = text.replacingOccurrences(of: "Група \(group.subGroupName). ", with: "")
            cleaned = cleaned.replacingOccurrences(of: "Група \(group.subGroupName) ", with: "")
            return cleaned
        } else if selectedDateKey == tomorrowKey {
            return Localization.get("noScheduleTomorrow")
        }
        return "No schedule"
    }
    
    @State private var showingRename = false
    @State private var showingDiff = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if NotificationManager.shared.hasUnreadChanges(group: group) {
                     HStack(spacing: 0) {
                        Button(action: {
                            showingDiff = true
                        }) {
                            HStack {
                                Image(systemName: "exclamationmark.arrow.circlepath")
                                Text(Localization.get("scheduleChangedTitle"))
                                Spacer()
                                Text(Localization.get("viewChanges"))
                                    .fontWeight(.bold)
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .foregroundStyle(.yellow)
                        }
                        
                        Divider()
                            .frame(width: 1)
                            .overlay(Color.yellow.opacity(0.3))
                        
                        Button(action: {
                            NotificationManager.shared.markAsRead(group: group)
                        }) {
                            Image(systemName: "xmark")
                                .font(.headline)
                                .foregroundStyle(.yellow.opacity(0.8))
                                .padding()
                        }
                    }
                    .background(Color.yellow.opacity(0.15))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                    )
                } else if NotificationManager.shared.hasUnreadNewDay(group: group) {
                     HStack(spacing: 0) {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                            Text(Localization.get("scheduleTomorrowTitle"))
                            Spacer()
                        }
                        .padding()
                        .foregroundStyle(.yellow)
                        
                        Divider()
                            .frame(width: 1)
                            .overlay(Color.yellow.opacity(0.3))
                        
                        Button(action: {
                            NotificationManager.shared.markAsRead(group: group)
                        }) {
                            Image(systemName: "xmark")
                                .font(.headline)
                                .foregroundStyle(.yellow.opacity(0.8))
                                .padding()
                        }
                    }
                    .background(Color.yellow.opacity(0.15))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                    )
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(displayedName ?? group.subGroupName)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.white)
                            
                            Button(action: {
                                showingRename = true
                            }) {
                                Image(systemName: "pencil")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                            }
                        }
                        
                        Text(Localization.get("scheduleForGroup"))
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                    HStack(spacing: 12) {
                        Button(action: {
                            isSubscribed.toggle()
                            if isSubscribed {
                                NotificationManager.shared.subscribe(group: group)
                            } else {
                                NotificationManager.shared.unsubscribe(group: group)
                            }
                        }) {
                            Image(systemName: isSubscribed ? "bell.fill" : "bell")
                                .font(.title2)
                                .foregroundStyle(isSubscribed ? .yellow : .gray)
                                .padding()
                                .background(Color(white: 0.1))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color(white: 0.2), lineWidth: 1))
                        }
                        
                        Button(action: {
                            if isWidgetGroup {
                                SharedDataManager.shared.saveSelectedGroupId("")
                                isWidgetGroup = false
                            } else {
                                SharedDataManager.shared.saveSelectedGroupId(group.id)
                                isWidgetGroup = true
                            }
                            SharedDataManager.shared.reloadWidgetTimelines()
                        }) {
                            Image(systemName: isWidgetGroup ? "square.grid.2x2.fill" : "square.grid.2x2")
                                .font(.title3)
                                .foregroundStyle(isWidgetGroup ? .green : .gray)
                                .padding()
                                .background(Color(white: 0.1))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color(white: 0.2), lineWidth: 1))
                        }
                    }
                }
                
                Divider()
                    .background(Color(white: 0.2))
                
                HStack(spacing: 0) {
                    TabButton(title: Localization.get("today"), isSelected: selectedDateKey == todayKey) {
                        selectedDateKey = todayKey
                    }
                    
                    TabButton(title: Localization.get("tomorrow"), isSelected: selectedDateKey == tomorrowKey) {
                        selectedDateKey = tomorrowKey
                    }
                }
                .background(Color(white: 0.1))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 0.2), lineWidth: 1))
                
                Text(selectedDateKey)
                    .font(.headline)
                    .foregroundStyle(.gray)
                
                if displayText == Localization.get("noScheduleTomorrow") || displayText == "No schedule" {
                     Text(displayText)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.gray)
                } else {
                    VisualScheduleView(text: displayText)
                    
                    if !NotificationManager.shared.hasUnreadChanges(group: group) && NotificationManager.shared.hasPreviousSchedule(group: group) {
                        Button(action: {
                            showingDiff = true
                        }) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                Text(Localization.get("viewChanges"))
                            }
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .padding(.top, 8)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("")
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            displayedName = NotificationManager.shared.getNickname(for: group) ?? group.customName
            isSubscribed = NotificationManager.shared.isSubscribed(group: group)
            isWidgetGroup = SharedDataManager.shared.isWidgetGroup(group.id)
            if selectedDateKey.isEmpty {
                 selectedDateKey = todayKey
            }
        }
        .sheet(isPresented: $showingDiff) {
            let prevSchedules = NotificationManager.shared.previousSchedules[group.id] ?? [:]
            let oldText = prevSchedules[selectedDateKey] ?? ""
            let newText = group.schedules[selectedDateKey] ?? ""
            
            DiffView(oldSchedule: oldText, newSchedule: newText, timestamp: group.lastUpdateTimestamp)
                .onDisappear {
                    NotificationManager.shared.markAsRead(group: group)
                }
        }
        .sheet(isPresented: $showingRename) {
             RenameGroupView(group: group) {
                 displayedName = NotificationManager.shared.getNickname(for: group)
                 NotificationCenter.default.post(name: NSNotification.Name("GroupRenamed"), object: nil)
             }
        }
    }
}
