import Foundation
import UserNotifications

/// Manages local notifications for task reminders
@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let notificationCenter = UNUserNotificationCenter.current()
    private var settings: UserSettings { UserSettings.shared }

    private init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func checkAuthorizationStatus() {
        Task {
            let settings = await notificationCenter.notificationSettings()
            await MainActor.run {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.authorizationStatus = granted ? .authorized : .denied
            }
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    // MARK: - Schedule Notifications

    func scheduleTaskReminder(for task: TaskItem) {
        guard settings.enableNotifications else { return }
        guard let scheduledTime = task.scheduledTime ?? task.scheduledDate else { return }

        // Calculate reminder time
        let reminderOffset = TimeInterval(settings.defaultReminderOffset * 60)
        let reminderDate = scheduledTime.addingTimeInterval(-reminderOffset)

        // Don't schedule if the reminder time is in the past
        guard reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = task.title
        content.sound = settings.notificationSound ? .default : nil
        content.categoryIdentifier = "TASK_REMINDER"
        content.userInfo = ["taskId": task.id.uuidString]

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "task-\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    func cancelTaskReminder(for task: TaskItem) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["task-\(task.id.uuidString)"])
    }

    func cancelAllReminders() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    // MARK: - Reschedule All

    func rescheduleAllReminders(for tasks: [TaskItem]) {
        // Cancel all existing
        cancelAllReminders()

        // Schedule new ones
        for task in tasks where !task.isCompleted {
            scheduleTaskReminder(for: task)
        }
    }

    // MARK: - Notification Actions

    func setupNotificationActions() {
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_TASK",
            title: "Complete",
            options: []
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_TASK",
            title: "Snooze 10 min",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: "TASK_REMINDER",
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([category])
    }
}
