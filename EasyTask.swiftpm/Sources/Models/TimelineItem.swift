import Foundation
import SwiftUI

/// Unified item for timeline display - can be either a task or calendar event
enum TimelineItem: Identifiable {
    case task(TaskItem)
    case event(CalendarEvent)

    var id: String {
        switch self {
        case .task(let task):
            return "task-\(task.id.uuidString)"
        case .event(let event):
            return "event-\(event.id)"
        }
    }

    var title: String {
        switch self {
        case .task(let task):
            return task.title
        case .event(let event):
            return event.title
        }
    }

    var startTime: Date? {
        switch self {
        case .task(let task):
            return task.scheduledTime ?? task.scheduledDate
        case .event(let event):
            return event.startDate
        }
    }

    var endTime: Date? {
        switch self {
        case .task(let task):
            guard let start = startTime else { return nil }
            return start.addingTimeInterval(task.duration)
        case .event(let event):
            return event.endDate
        }
    }

    var duration: TimeInterval {
        switch self {
        case .task(let task):
            return task.duration
        case .event(let event):
            return event.duration
        }
    }

    var isTask: Bool {
        if case .task = self { return true }
        return false
    }

    var isEvent: Bool {
        if case .event = self { return true }
        return false
    }

    var isAllDay: Bool {
        switch self {
        case .task:
            return false
        case .event(let event):
            return event.isAllDay
        }
    }

    var color: Color {
        switch self {
        case .task(let task):
            return task.color.swiftUIColor
        case .event(let event):
            if let cgColor = event.calendarColor {
                return Color(cgColor: cgColor)
            }
            return .blue
        }
    }
}

// MARK: - TaskColor Extension for SwiftUI Color
extension TaskColor {
    var swiftUIColor: Color {
        switch self {
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .teal: return .teal
        case .gray: return .gray
        }
    }
}
