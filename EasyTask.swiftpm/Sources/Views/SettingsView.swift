import SwiftUI
import EventKit

struct SettingsView: View {
    @EnvironmentObject private var settings: UserSettings
    @StateObject private var calendarManager = CalendarManager()

    var body: some View {
        #if os(iOS)
        NavigationStack {
            settingsForm
                .navigationTitle("Settings")
        }
        #else
        settingsForm
            .frame(width: 450)
            .padding()
        #endif
    }

    private var settingsForm: some View {
        Form {
            // Appearance
            Section("Appearance") {
                Picker("Theme", selection: $settings.colorScheme) {
                    ForEach(AppColorScheme.allCases, id: \.self) { scheme in
                        Text(scheme.displayName).tag(scheme)
                    }
                }

                Toggle("Week Starts on Monday", isOn: $settings.weekStartsOnMonday)
            }

            // Work Hours
            Section("Work Hours") {
                Picker("Start Time", selection: $settings.workStartHour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(formatHour(hour)).tag(hour)
                    }
                }

                Picker("End Time", selection: $settings.workEndHour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(formatHour(hour)).tag(hour)
                    }
                }
            }

            // Default Task Settings
            Section("Default Task Settings") {
                Picker("Duration", selection: $settings.defaultTaskDuration) {
                    ForEach([15, 30, 45, 60, 90, 120], id: \.self) { minutes in
                        Text(formatDuration(minutes)).tag(minutes)
                    }
                }

                Picker("Reminder", selection: $settings.defaultReminderOffset) {
                    ForEach([0, 5, 10, 15, 30, 60], id: \.self) { minutes in
                        if minutes == 0 {
                            Text("None").tag(minutes)
                        } else {
                            Text("\(minutes) min before").tag(minutes)
                        }
                    }
                }
            }

            // Task Behavior
            Section("Task Behavior") {
                Toggle("Roll Over Missed Tasks", isOn: $settings.rolloverMissedTasks)

                Toggle("Show Completed Tasks", isOn: $settings.showCompletedTasks)
            }

            // Notifications
            Section("Notifications") {
                Toggle("Enable Notifications", isOn: $settings.enableNotifications)

                if settings.enableNotifications {
                    Toggle("Notification Sound", isOn: $settings.notificationSound)
                }
            }

            // Calendar Integration
            Section("Calendars") {
                calendarsList
            }

            // About
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }

                if let privacyURL = URL(string: "https://example.com/privacy") {
                    Link(destination: privacyURL) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }

                if let termsURL = URL(string: "https://example.com/terms") {
                    Link(destination: termsURL) {
                        HStack {
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }

            // Data Management
            Section("Data") {
                Button("Export Tasks") {
                    // TODO: Implement export
                }

                Button("Import Tasks") {
                    // TODO: Implement import
                }

                Button(role: .destructive) {
                    // TODO: Implement clear completed
                } label: {
                    Text("Clear Completed Tasks")
                }
            }
        }
        .task {
            await calendarManager.requestAccess()
        }
    }

    // MARK: - Calendars List

    @ViewBuilder
    private var calendarsList: some View {
        if calendarManager.authorizationStatus == .fullAccess ||
           calendarManager.authorizationStatus == .authorized {
            ForEach(calendarManager.calendars, id: \.calendarIdentifier) { calendar in
                CalendarToggleRow(
                    calendar: calendar,
                    isEnabled: settings.enabledCalendarIds.isEmpty ||
                               settings.enabledCalendarIds.contains(calendar.calendarIdentifier)
                ) { isEnabled in
                    var ids = settings.enabledCalendarIds
                    if isEnabled {
                        ids.insert(calendar.calendarIdentifier)
                    } else {
                        ids.remove(calendar.calendarIdentifier)
                    }
                    settings.enabledCalendarIds = ids
                }
            }
        } else {
            Button("Grant Calendar Access") {
                Task {
                    await calendarManager.requestAccess()
                }
            }

            Text("Calendar access is required to show your events alongside tasks.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"

        var components = DateComponents()
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? Date()

        return formatter.string(from: date)
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours) hour\(hours > 1 ? "s" : "")"
            }
            return "\(hours)h \(mins)m"
        }
        return "\(minutes) min"
    }
}

// MARK: - Calendar Toggle Row

struct CalendarToggleRow: View {
    let calendar: EKCalendar
    let isEnabled: Bool
    let onToggle: (Bool) -> Void

    @State private var localEnabled: Bool

    init(calendar: EKCalendar, isEnabled: Bool, onToggle: @escaping (Bool) -> Void) {
        self.calendar = calendar
        self.isEnabled = isEnabled
        self.onToggle = onToggle
        _localEnabled = State(initialValue: isEnabled)
    }

    var body: some View {
        Toggle(isOn: $localEnabled) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(cgColor: calendar.cgColor))
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(calendar.title)
                        .font(.body)

                    if let source = calendar.source {
                        Text(source.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onChange(of: localEnabled) { _, newValue in
            onToggle(newValue)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(UserSettings.shared)
}
