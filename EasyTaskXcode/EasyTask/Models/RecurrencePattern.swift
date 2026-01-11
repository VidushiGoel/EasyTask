import Foundation
import SwiftData

/// Represents recurrence rules for recurring tasks
@Model
final class RecurrencePattern {
    var id: UUID
    var frequency: RecurrenceFrequency
    var interval: Int // Every X days/weeks/months
    var daysOfWeek: [Int] // 1 = Sunday, 7 = Saturday (for weekly)
    var dayOfMonth: Int? // For monthly
    var startDate: Date
    var endDate: Date? // Optional end date
    var occurrenceCount: Int? // Optional max occurrences

    @Relationship(inverse: \TaskItem.recurrencePattern) var task: TaskItem?

    init(
        id: UUID = UUID(),
        frequency: RecurrenceFrequency,
        interval: Int = 1,
        daysOfWeek: [Int] = [],
        dayOfMonth: Int? = nil,
        startDate: Date = Date(),
        endDate: Date? = nil,
        occurrenceCount: Int? = nil
    ) {
        self.id = id
        self.frequency = frequency
        self.interval = interval
        self.daysOfWeek = daysOfWeek
        self.dayOfMonth = dayOfMonth
        self.startDate = startDate
        self.endDate = endDate
        self.occurrenceCount = occurrenceCount
    }

    /// Get the next occurrence date after a given date
    func nextOccurrence(after date: Date) -> Date? {
        let calendar = Calendar.current

        // Check if we've passed the end date
        if let endDate = endDate, date >= endDate {
            return nil
        }

        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: interval, to: date)

        case .weekly:
            if daysOfWeek.isEmpty {
                return calendar.date(byAdding: .weekOfYear, value: interval, to: date)
            }

            // Find next matching day of week
            var nextDate = calendar.date(byAdding: .day, value: 1, to: date)!
            var attempts = 0
            while attempts < 365 { // Safety limit
                let weekday = calendar.component(.weekday, from: nextDate)
                if daysOfWeek.contains(weekday) {
                    return nextDate
                }
                nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate)!
                attempts += 1
            }
            return nil

        case .monthly:
            if let day = dayOfMonth {
                var components = calendar.dateComponents([.year, .month], from: date)
                components.month! += interval
                components.day = day
                return calendar.date(from: components)
            }
            return calendar.date(byAdding: .month, value: interval, to: date)

        case .yearly:
            return calendar.date(byAdding: .year, value: interval, to: date)

        case .custom:
            return calendar.date(byAdding: .day, value: interval, to: date)
        }
    }

    /// Generate occurrences for a date range
    func occurrences(from startDate: Date, to endDate: Date) -> [Date] {
        var occurrences: [Date] = []
        var currentDate = self.startDate

        // If pattern start is before range start, advance to range
        while currentDate < startDate {
            guard let next = nextOccurrence(after: currentDate) else { break }
            currentDate = next
        }

        // Generate occurrences within range
        while currentDate <= endDate {
            if currentDate >= startDate {
                occurrences.append(currentDate)
            }
            guard let next = nextOccurrence(after: currentDate) else { break }
            currentDate = next
        }

        // Apply occurrence count limit if set
        if let count = occurrenceCount {
            return Array(occurrences.prefix(count))
        }

        return occurrences
    }
}

// MARK: - Recurrence Frequency
enum RecurrenceFrequency: String, Codable, CaseIterable {
    case daily
    case weekly
    case monthly
    case yearly
    case custom

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .custom: return "Custom"
        }
    }
}
