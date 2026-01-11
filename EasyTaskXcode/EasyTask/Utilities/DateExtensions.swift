import Foundation

extension Date {
    /// Start of the current day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// End of the current day
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    /// Start of the current week
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    /// End of the current week
    var endOfWeek: Date {
        var components = DateComponents()
        components.weekOfYear = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfWeek) ?? self
    }

    /// Start of the current month
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }

    /// End of the current month
    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth) ?? self
    }

    /// Check if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Check if date is tomorrow
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    /// Check if date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// Check if date is in the past (before today)
    var isPast: Bool {
        self < Date().startOfDay
    }

    /// Check if date is in the future (after today)
    var isFuture: Bool {
        self > Date().endOfDay
    }

    /// Check if date is in current week
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    /// Check if date is in current month
    var isThisMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }

    /// Add hours to date
    func adding(hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }

    /// Add minutes to date
    func adding(minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }

    /// Add days to date
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// Add weeks to date
    func adding(weeks: Int) -> Date {
        Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: self) ?? self
    }

    /// Format as relative string (e.g., "Today", "Tomorrow", "Monday")
    var relativeFormatted: String {
        if isToday { return "Today" }
        if isTomorrow { return "Tomorrow" }
        if isYesterday { return "Yesterday" }

        let calendar = Calendar.current
        let now = Date()

        // If within this week, show day name
        if calendar.isDate(self, equalTo: now, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: self)
        }

        // If within next week, show "Next Monday" etc.
        if let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: now),
           calendar.isDate(self, equalTo: nextWeek, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return "Next \(formatter.string(from: self))"
        }

        // Otherwise show date
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }

    /// Format as short time (e.g., "9:00 AM")
    var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// Format as short date (e.g., "Jan 5")
    var shortDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }
}

// MARK: - TimeInterval Extensions

extension TimeInterval {
    /// Convert to minutes
    var minutes: Int {
        Int(self / 60)
    }

    /// Convert to hours
    var hours: Double {
        self / 3600
    }

    /// Format as duration string (e.g., "1h 30m")
    var durationFormatted: String {
        let totalMinutes = Int(self / 60)

        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            if minutes == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(minutes)m"
        }

        return "\(totalMinutes)m"
    }

    /// Create from minutes
    static func minutes(_ count: Int) -> TimeInterval {
        TimeInterval(count * 60)
    }

    /// Create from hours
    static func hours(_ count: Int) -> TimeInterval {
        TimeInterval(count * 3600)
    }
}
