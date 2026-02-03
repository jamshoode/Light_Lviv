import Foundation

/// Thread-safe wrapper for UserDefaults operations
/// Prevents race conditions when multiple services access shared preferences
actor UserDefaultsManager {
    static let shared = UserDefaultsManager()

    private let defaults = UserDefaults.standard

    // MARK: - Keys

    enum Key: String {
        case savedGroupIDs = "SavedGroupIDs"
        case cachedGroups = "CachedGroups"
        case subscribedGroupIDs = "SubscribedGroupIDs"
        case lastKnownSchedules = "LastKnownSchedules"
        case previousSchedules = "PreviousSchedules"
        case unreadChangesIDs = "UnreadChangesIDs"
        case unreadNewDayIDs = "UnreadNewDayIDs"
        case groupNicknames = "GroupNicknames"
    }

    // MARK: - String Array Operations

    func getStringArray(for key: Key) -> [String] {
        return defaults.array(forKey: key.rawValue) as? [String] ?? []
    }

    func setStringArray(_ array: [String], for key: Key) {
        defaults.set(array, forKey: key.rawValue)
    }

    // MARK: - Set Operations

    func getStringSet(for key: Key) -> Set<String> {
        let array = defaults.array(forKey: key.rawValue) as? [String] ?? []
        return Set(array)
    }

    func setStringSet(_ set: Set<String>, for key: Key) {
        defaults.set(Array(set), forKey: key.rawValue)
    }

    // MARK: - Dictionary Operations

    func getDictionary(for key: Key) -> [String: [String: String]] {
        return defaults.dictionary(forKey: key.rawValue) as? [String: [String: String]] ?? [:]
    }

    func setDictionary(_ dict: [String: [String: String]], for key: Key) {
        defaults.set(dict, forKey: key.rawValue)
    }

    // MARK: - String Dictionary Operations

    func getStringDictionary(for key: Key) -> [String: String] {
        return defaults.dictionary(forKey: key.rawValue) as? [String: String] ?? [:]
    }

    func setStringDictionary(_ dict: [String: String], for key: Key) {
        defaults.set(dict, forKey: key.rawValue)
    }

    // MARK: - Data Operations

    func getData(for key: Key) -> Data? {
        return defaults.data(forKey: key.rawValue)
    }

    func setData(_ data: Data, for key: Key) {
        defaults.set(data, forKey: key.rawValue)
    }

    // MARK: - Remove Operations

    func removeValue(for key: Key) {
        defaults.removeObject(forKey: key.rawValue)
    }

    // MARK: - Batch Operations

    /// Perform multiple operations atomically
    func performBatch(operations: () -> Void) {
        operations()
        defaults.synchronize()
    }
}
