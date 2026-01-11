import Foundation
import SwiftUI

/// User preferences stored in UserDefaults
class UserSettings: ObservableObject {
    static let shared = UserSettings()

    // MARK: - Work Hours
    @AppStorage("workStartHour") var workStartHour: Int = 9
    @AppStorage("workEndHour") var workEndHour: Int = 17

    // MARK: - Default Task Settings
    @AppStorage("defaultTaskDuration") var defaultTaskDuration: Int = 30 // minutes
    @AppStorage("defaultReminderOffset") var defaultReminderOffset: Int = 10 // minutes before

    // MARK: - Behavior Settings
    @AppStorage("rolloverMissedTasks") var rolloverMissedTasks: Bool = true
    @AppStorage("showCompletedTasks") var showCompletedTasks: Bool = true
    @AppStorage("weekStartsOnMonday") var weekStartsOnMonday: Bool = true

    // MARK: - Notification Settings
    @AppStorage("enableNotifications") var enableNotifications: Bool = true
    @AppStorage("notificationSound") var notificationSound: Bool = true

    // MARK: - Appearance
    @AppStorage("colorScheme") var colorScheme: AppColorScheme = .system
    @AppStorage("accentColorName") var accentColorName: String = "indigo"

    // MARK: - Calendar Integration
    @AppStorage("enabledCalendarIds") private var enabledCalendarIdsData: Data = Data()

    var enabledCalendarIds: Set<String> {
        get {
            (try? JSONDecoder().decode(Set<String>.self, from: enabledCalendarIdsData)) ?? []
        }
        set {
            enabledCalendarIdsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    // MARK: - Computed Properties
    var defaultTaskDurationSeconds: TimeInterval {
        TimeInterval(defaultTaskDuration * 60)
    }

    var firstWeekday: Int {
        weekStartsOnMonday ? 2 : 1 // 1 = Sunday, 2 = Monday
    }

    private init() {}
}

// MARK: - App Color Scheme
enum AppColorScheme: String, CaseIterable {
    case system
    case light
    case dark

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
