import Foundation
import SwiftData
import SwiftUI

/// Manages all task operations including CRUD and recurrence
@MainActor
class TaskManager: ObservableObject {
    private var modelContext: ModelContext

    @Published var tasks: [TaskItem] = []
    @Published var isLoading = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchTasks()
    }

    // MARK: - Fetch Operations

    func fetchTasks() {
        let descriptor = FetchDescriptor<TaskItem>(
            sortBy: [SortDescriptor(\.scheduledDate), SortDescriptor(\.createdAt)]
        )

        do {
            tasks = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch tasks: \(error)")
        }
    }

    func tasks(for date: Date) -> [TaskItem] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return tasks.filter { task in
            guard let scheduled = task.scheduledDate else { return false }
            return scheduled >= startOfDay && scheduled < endOfDay
        }
    }

    func floatingTasks() -> [TaskItem] {
        tasks.filter { $0.isFloating && !$0.isCompleted }
    }

    func incompleteTasks() -> [TaskItem] {
        tasks.filter { !$0.isCompleted }
    }

    func overdueTasks() -> [TaskItem] {
        tasks.filter { $0.isOverdue }
    }

    func tasksInDateRange(from startDate: Date, to endDate: Date) -> [TaskItem] {
        tasks.filter { task in
            guard let scheduled = task.scheduledDate else { return false }
            return scheduled >= startDate && scheduled <= endDate
        }
    }

    // MARK: - Create Operations

    func createTask(
        title: String,
        notes: String = "",
        scheduledDate: Date? = nil,
        scheduledTime: Date? = nil,
        duration: TimeInterval = 1800,
        isFloating: Bool = true,
        priority: TaskPriority = .medium,
        color: TaskColor = .blue
    ) -> TaskItem {
        let task = TaskItem(
            title: title,
            notes: notes,
            scheduledDate: scheduledDate,
            scheduledTime: scheduledTime,
            duration: duration,
            isFloating: isFloating,
            priority: priority,
            color: color
        )

        modelContext.insert(task)
        save()
        fetchTasks()

        return task
    }

    func createRecurringTask(
        title: String,
        notes: String = "",
        scheduledTime: Date? = nil,
        duration: TimeInterval = 1800,
        priority: TaskPriority = .medium,
        color: TaskColor = .blue,
        frequency: RecurrenceFrequency,
        interval: Int = 1,
        daysOfWeek: [Int] = [],
        dayOfMonth: Int? = nil,
        startDate: Date = Date(),
        endDate: Date? = nil
    ) -> TaskItem {
        let pattern = RecurrencePattern(
            frequency: frequency,
            interval: interval,
            daysOfWeek: daysOfWeek,
            dayOfMonth: dayOfMonth,
            startDate: startDate,
            endDate: endDate
        )

        let task = TaskItem(
            title: title,
            notes: notes,
            scheduledTime: scheduledTime,
            duration: duration,
            isFloating: false,
            priority: priority,
            color: color,
            isRecurring: true,
            recurrencePattern: pattern
        )

        modelContext.insert(task)
        save()
        fetchTasks()

        // Generate initial instances
        generateRecurringInstances(for: task, from: startDate, days: 30)

        return task
    }

    /// Generate recurring task instances for a date range
    func generateRecurringInstances(for task: TaskItem, from startDate: Date, days: Int) {
        guard task.isRecurring, let pattern = task.recurrencePattern else { return }

        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .day, value: days, to: startDate)!
        let occurrences = pattern.occurrences(from: startDate, to: endDate)

        for occurrence in occurrences {
            // Check if instance already exists
            let existingInstance = tasks.first { t in
                t.parentTaskId == task.id &&
                calendar.isDate(t.scheduledDate ?? Date.distantPast, inSameDayAs: occurrence)
            }

            if existingInstance == nil {
                let instance = TaskItem(
                    title: task.title,
                    notes: task.notes,
                    scheduledDate: occurrence,
                    scheduledTime: task.scheduledTime,
                    duration: task.duration,
                    isFloating: false,
                    priority: task.priority,
                    color: task.color,
                    parentTaskId: task.id
                )
                modelContext.insert(instance)
            }
        }

        save()
        fetchTasks()
    }

    // MARK: - Update Operations

    func updateTask(_ task: TaskItem) {
        save()
        fetchTasks()
    }

    func completeTask(_ task: TaskItem) {
        task.isCompleted = true
        task.completedAt = Date()
        save()
        fetchTasks()
    }

    func uncompleteTask(_ task: TaskItem) {
        task.isCompleted = false
        task.completedAt = nil
        save()
        fetchTasks()
    }

    func toggleTaskCompletion(_ task: TaskItem) {
        if task.isCompleted {
            uncompleteTask(task)
        } else {
            completeTask(task)
        }
    }

    func rescheduleTask(_ task: TaskItem, to date: Date, time: Date? = nil) {
        task.scheduledDate = date
        task.scheduledTime = time
        task.isFloating = false
        save()
        fetchTasks()
    }

    func makeTaskFloating(_ task: TaskItem) {
        task.scheduledDate = nil
        task.scheduledTime = nil
        task.isFloating = true
        save()
        fetchTasks()
    }

    func updateTaskDuration(_ task: TaskItem, duration: TimeInterval) {
        task.duration = duration
        save()
        fetchTasks()
    }

    // MARK: - Delete Operations

    func deleteTask(_ task: TaskItem) {
        // If it's a recurring task, also delete all instances
        if task.isRecurring {
            let instances = tasks.filter { $0.parentTaskId == task.id }
            for instance in instances {
                modelContext.delete(instance)
            }
        }

        modelContext.delete(task)
        save()
        fetchTasks()
    }

    func deleteTaskInstance(_ task: TaskItem) {
        // Only delete this specific instance, not the pattern
        modelContext.delete(task)
        save()
        fetchTasks()
    }

    // MARK: - Rollover Operations

    func rolloverMissedTasks(to date: Date = Date()) {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: date)

        let missedTasks = tasks.filter { task in
            guard !task.isCompleted,
                  let scheduled = task.scheduledDate,
                  scheduled < startOfToday else { return false }
            return true
        }

        for task in missedTasks {
            task.scheduledDate = startOfToday
        }

        save()
        fetchTasks()
    }

    // MARK: - Private Helpers

    private func save() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}

// MARK: - Preview Helper
extension TaskManager {
    static var preview: TaskManager {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: TaskItem.self, RecurrencePattern.self, configurations: config)
        let manager = TaskManager(modelContext: container.mainContext)

        // Add sample tasks
        let _ = manager.createTask(title: "Morning standup", scheduledDate: Date(), scheduledTime: Date())
        let _ = manager.createTask(title: "Review PR", isFloating: true, priority: .high)
        let _ = manager.createTask(title: "Write documentation", isFloating: true)

        return manager
    }
}
