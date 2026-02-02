import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
class ScheduleViewModel {
    var groups: [ScheduleGroup] = []
    private var savedGroupIDs: Set<String> = []
    
    var isEmptyState: Bool {
        return savedGroupIDs.isEmpty
    }
    
    var displayedGroups: [ScheduleGroup] {
        return groups.filter { savedGroupIDs.contains($0.id) }
    }
    
    var isLoading = false
    var errorMessage: String?
    var lastUpdated: Date?
    
    private let scraper = PowerOffScraper()
    private let urlString = "https://poweron.loe.lviv.ua"
    private let saveKey = "SavedGroupIDs"
    private let groupsCacheKey = "CachedGroups"
    
    init() {
        loadSelection()
        loadCachedGroups()
    }
    
    func saveSelection() {
        let array = Array(savedGroupIDs)
        UserDefaults.standard.set(array, forKey: saveKey)
    }
    
    private func saveGroups() {
        if let data = try? JSONEncoder().encode(groups) {
            UserDefaults.standard.set(data, forKey: groupsCacheKey)
        }
    }
    
    func loadSelection() {
        if let array = UserDefaults.standard.array(forKey: saveKey) as? [String] {
            savedGroupIDs = Set(array)
        }
    }
    
    private func loadCachedGroups() {
        if let data = UserDefaults.standard.data(forKey: groupsCacheKey),
           let cached = try? JSONDecoder().decode([ScheduleGroup].self, from: data) {
            self.groups = cached
        }
    }
    
    func addGroup(_ group: ScheduleGroup) {
        savedGroupIDs.insert(group.id)
        saveSelection()
    }
    
    func removeGroup(_ group: ScheduleGroup) {
        savedGroupIDs.remove(group.id)
        saveSelection()
    }
    
    func isGroupAdded(_ group: ScheduleGroup) -> Bool {
        return savedGroupIDs.contains(group.id)
    }
    
    func startAutoRefresh() async {
        await fetchSchedule()
        
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 300 * 1_000_000_000)
            if Task.isCancelled { break }
            await fetchSchedule()
        }
    }
    
    func fetchSchedule() async {
        if groups.isEmpty {
            isLoading = true
        }
        
        errorMessage = nil
        
        do {
            let fetchedGroups = try await scraper.scrapeSchedule(url: urlString)
            
            await MainActor.run {
                if !fetchedGroups.isEmpty {
                    var processedGroups: [ScheduleGroup] = []
                    for var group in fetchedGroups {
                        group.customName = NotificationManager.shared.getNickname(for: group)
                        processedGroups.append(group)
                    }
                    
                    self.groups = processedGroups
                    self.lastUpdated = Date()
                    self.saveGroups()
                    
                    NotificationManager.shared.checkForChanges(in: self.groups)
                } else if groups.isEmpty {
                     errorMessage = Localization.get("noData")
                }
            }
        } catch {
            print("Error fetching: \(error)")
            
            if let urlError = error as? URLError, urlError.code == .cancelled {
                return
            }
            
            if groups.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
}
