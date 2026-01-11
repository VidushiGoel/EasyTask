import Foundation
import EventKit
import SwiftUI

/// Manages Apple Calendar integration via EventKit
@MainActor
class CalendarManager: ObservableObject {
    private let eventStore = EKEventStore()

    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var calendars: [EKCalendar] = []
    @Published var events: [CalendarEvent] = []
    @Published var isLoading = false

    private var settings: UserSettings { UserSettings.shared }

    init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func checkAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        if authorizationStatus == .fullAccess || authorizationStatus == .authorized {
            loadCalendars()
        }
    }

    func requestAccess() async -> Bool {
        do {
            // iOS 17+ uses requestFullAccessToEvents
            let granted = try await eventStore.requestFullAccessToEvents()
            await MainActor.run {
                authorizationStatus = granted ? .fullAccess : .denied
                if granted {
                    loadCalendars()
                }
            }
            return granted
        } catch {
            print("Calendar access error: \(error)")
            return false
        }
    }

    // MARK: - Calendar Loading

    func loadCalendars() {
        calendars = eventStore.calendars(for: .event)
    }

    var enabledCalendars: [EKCalendar] {
        let enabledIds = settings.enabledCalendarIds
        if enabledIds.isEmpty {
            return calendars // Show all if none specifically selected
        }
        return calendars.filter { enabledIds.contains($0.calendarIdentifier) }
    }

    // MARK: - Event Loading

    func fetchEvents(for date: Date) async {
        await fetchEvents(from: date, to: date)
    }

    func fetchEvents(from startDate: Date, to endDate: Date) async {
        guard authorizationStatus == .fullAccess || authorizationStatus == .authorized else {
            return
        }

        isLoading = true

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate))!

        let predicate = eventStore.predicateForEvents(
            withStart: start,
            end: end,
            calendars: enabledCalendars.isEmpty ? nil : enabledCalendars
        )

        let ekEvents = eventStore.events(matching: predicate)
        let calendarEvents = ekEvents.map { CalendarEvent(from: $0) }

        await MainActor.run {
            self.events = calendarEvents.sorted { $0.startDate < $1.startDate }
            self.isLoading = false
        }
    }

    func events(for date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        return events.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
    }

    func eventsInDateRange(from startDate: Date, to endDate: Date) -> [CalendarEvent] {
        events.filter { event in
            event.startDate >= startDate && event.startDate <= endDate
        }
    }

    // MARK: - Timeline Items

    func timelineItems(for date: Date, tasks: [TaskItem]) -> [TimelineItem] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        var items: [TimelineItem] = []

        // Add calendar events for this day
        let dayEvents = events.filter { event in
            event.startDate >= dayStart && event.startDate < dayEnd
        }
        items.append(contentsOf: dayEvents.map { .event($0) })

        // Add scheduled tasks for this day
        let dayTasks = tasks.filter { task in
            guard let scheduled = task.scheduledDate else { return false }
            return calendar.isDate(scheduled, inSameDayAs: date)
        }
        items.append(contentsOf: dayTasks.map { .task($0) })

        // Sort by start time
        items.sort { item1, item2 in
            let time1 = item1.startTime ?? Date.distantFuture
            let time2 = item2.startTime ?? Date.distantFuture
            return time1 < time2
        }

        return items
    }
}

// MARK: - Preview Helper
extension CalendarManager {
    static var preview: CalendarManager {
        let manager = CalendarManager()

        // Add sample events for preview
        let calendar = Calendar.current
        let now = Date()

        manager.events = [
            CalendarEvent(
                title: "Team Meeting",
                startDate: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now)!,
                endDate: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: now)!,
                calendarTitle: "Work"
            ),
            CalendarEvent(
                title: "Lunch with Sarah",
                startDate: calendar.date(bySettingHour: 12, minute: 30, second: 0, of: now)!,
                endDate: calendar.date(bySettingHour: 13, minute: 30, second: 0, of: now)!,
                calendarTitle: "Personal"
            ),
            CalendarEvent(
                title: "Project Review",
                startDate: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: now)!,
                endDate: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: now)!,
                calendarTitle: "Work"
            )
        ]

        return manager
    }
}
