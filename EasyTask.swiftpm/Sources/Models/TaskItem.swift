import Foundation
import SwiftData

/// Represents a task in the app
@Model
final class TaskItem {
    var id: UUID
    var title: String
    var notes: String
    var createdAt: Date
    var scheduledDate: Date?
    var scheduledTime: Date?
    var duration: TimeInterval // in seconds
    var isCompleted: Bool
    var completedAt: Date?
    var isFloating: Bool // Task without specific time
    var priority: TaskPriority
    var color: TaskColor

    // Recurrence
    var isRecurring: Bool
    @Relationship(deleteRule: .cascade) var recurrencePattern: RecurrencePattern?
    var parentTaskId: UUID? // For recurring task instances

    // Computed property for display
    var isOverdue: Bool {
        guard !isCompleted, let scheduled = scheduledDate else { return false }
        return scheduled < Date()
    }

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        scheduledDate: Date? = nil,
        scheduledTime: Date? = nil,
        duration: TimeInterval = 1800, // 30 minutes default
        isFloating: Bool = true,
        priority: TaskPriority = .medium,
        color: TaskColor = .blue,
        isRecurring: Bool = false,
        recurrencePattern: RecurrencePattern? = nil,
        parentTaskId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.createdAt = Date()
        self.scheduledDate = scheduledDate
        self.scheduledTime = scheduledTime
        self.duration = duration
        self.isCompleted = false
        self.completedAt = nil
        self.isFloating = isFloating
        self.priority = priority
        self.color = color
        self.isRecurring = isRecurring
        self.recurrencePattern = recurrencePattern
        self.parentTaskId = parentTaskId
    }
}

// MARK: - Task Priority
enum TaskPriority: Int, Codable, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2
    case urgent = 3

    var label: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }

    var iconName: String {
        switch self {
        case .low: return "arrow.down"
        case .medium: return "minus"
        case .high: return "arrow.up"
        case .urgent: return "exclamationmark.2"
        }
    }
}

// MARK: - Task Color
enum TaskColor: String, Codable, CaseIterable {
    case blue
    case purple
    case pink
    case red
    case orange
    case yellow
    case green
    case teal
    case gray

    var displayName: String {
        rawValue.capitalized
    }
}
