import SwiftUI

struct TaskDetailView: View {
    @Bindable var task: TaskItem
    @ObservedObject var taskManager: TaskManager
    @Environment(\.dismiss) private var dismiss

    @State private var showingDeleteConfirmation = false
    @State private var showingDatePicker = false
    @State private var showingTimePicker = false
    @State private var showingRecurrenceEditor = false

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            Form {
                // Title section
                Section {
                    TextField("Task title", text: $task.title)
                        .font(.headline)
                }

                // Notes section
                Section("Notes") {
                    TextEditor(text: $task.notes)
                        .frame(minHeight: 80)
                }

                // Schedule section
                Section("Schedule") {
                    // Date
                    Button(action: { showingDatePicker = true }) {
                        HStack {
                            Label("Date", systemImage: "calendar")
                            Spacer()
                            if let date = task.scheduledDate {
                                Text(formatDate(date))
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Not set")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .foregroundStyle(.primary)

                    // Time
                    Button(action: { showingTimePicker = true }) {
                        HStack {
                            Label("Time", systemImage: "clock")
                            Spacer()
                            if let time = task.scheduledTime {
                                Text(formatTime(time))
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Not set")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .foregroundStyle(.primary)

                    // Duration
                    HStack {
                        Label("Duration", systemImage: "hourglass")
                        Spacer()
                        Picker("", selection: Binding(
                            get: { Int(task.duration / 60) },
                            set: { task.duration = TimeInterval($0 * 60) }
                        )) {
                            ForEach([15, 30, 45, 60, 90, 120, 180], id: \.self) { minutes in
                                Text(formatDuration(minutes)).tag(minutes)
                            }
                        }
                        .labelsHidden()
                    }

                    // Floating toggle
                    Toggle(isOn: $task.isFloating) {
                        Label("Anytime", systemImage: "cloud")
                    }
                    .onChange(of: task.isFloating) { _, isFloating in
                        if isFloating {
                            task.scheduledDate = nil
                            task.scheduledTime = nil
                        }
                    }
                }

                // Recurrence section
                if task.isRecurring || task.parentTaskId == nil {
                    Section("Recurrence") {
                        Toggle(isOn: $task.isRecurring) {
                            Label("Repeat", systemImage: "repeat")
                        }

                        if task.isRecurring {
                            Button(action: { showingRecurrenceEditor = true }) {
                                HStack {
                                    Text("Pattern")
                                    Spacer()
                                    Text(recurrenceDescription)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }

                // Appearance section
                Section("Appearance") {
                    // Color
                    HStack {
                        Label("Color", systemImage: "paintpalette")
                        Spacer()
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(TaskColor.allCases, id: \.self) { color in
                                    Circle()
                                        .fill(color.swiftUIColor)
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(.white, lineWidth: task.color == color ? 2 : 0)
                                        )
                                        .shadow(color: color.swiftUIColor.opacity(0.4), radius: task.color == color ? 3 : 0)
                                        .onTapGesture {
                                            task.color = color
                                        }
                                }
                            }
                        }
                    }

                    // Priority
                    Picker(selection: $task.priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Label(priority.label, systemImage: priority.iconName)
                                .tag(priority)
                        }
                    } label: {
                        Label("Priority", systemImage: "flag")
                    }
                }

                // Status section
                Section("Status") {
                    Toggle(isOn: $task.isCompleted) {
                        Label(
                            task.isCompleted ? "Completed" : "Mark as complete",
                            systemImage: task.isCompleted ? "checkmark.circle.fill" : "circle"
                        )
                    }
                    .tint(.green)
                    .onChange(of: task.isCompleted) { _, isCompleted in
                        task.completedAt = isCompleted ? Date() : nil
                    }

                    if task.isCompleted, let completedAt = task.completedAt {
                        HStack {
                            Text("Completed on")
                            Spacer()
                            Text(formatDate(completedAt) + " at " + formatTime(completedAt))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Info section
                Section("Info") {
                    HStack {
                        Text("Created")
                        Spacer()
                        Text(formatDate(task.createdAt))
                            .foregroundStyle(.secondary)
                    }

                    if task.parentTaskId != nil {
                        HStack {
                            Label("Part of recurring series", systemImage: "repeat")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Delete section
                Section {
                    Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                        HStack {
                            Spacer()
                            Label("Delete Task", systemImage: "trash")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        taskManager.updateTask(task)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerSheet(
                    selectedDate: Binding(
                        get: { task.scheduledDate ?? Date() },
                        set: {
                            task.scheduledDate = $0
                            task.isFloating = false
                        }
                    )
                )
            }
            .sheet(isPresented: $showingTimePicker) {
                TimePickerSheet(
                    selectedTime: Binding(
                        get: { task.scheduledTime ?? Date() },
                        set: { task.scheduledTime = $0 }
                    )
                )
            }
            .sheet(isPresented: $showingRecurrenceEditor) {
                RecurrenceEditorView(task: task)
            }
            .confirmationDialog(
                "Delete Task",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                if task.parentTaskId != nil {
                    Button("Delete Only This Instance", role: .destructive) {
                        taskManager.deleteTaskInstance(task)
                        dismiss()
                    }
                    Button("Delete All Future Instances", role: .destructive) {
                        // Find parent and delete it
                        if let parentId = task.parentTaskId,
                           let parent = taskManager.tasks.first(where: { $0.id == parentId }) {
                            taskManager.deleteTask(parent)
                        }
                        dismiss()
                    }
                } else {
                    Button("Delete", role: .destructive) {
                        taskManager.deleteTask(task)
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if task.parentTaskId != nil {
                    Text("This task is part of a recurring series.")
                } else if task.isRecurring {
                    Text("This will also delete all instances of this recurring task.")
                } else {
                    Text("Are you sure you want to delete this task?")
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(mins)m"
        }
        return "\(minutes)m"
    }

    private var recurrenceDescription: String {
        guard let pattern = task.recurrencePattern else { return "None" }

        switch pattern.frequency {
        case .daily:
            return pattern.interval == 1 ? "Daily" : "Every \(pattern.interval) days"
        case .weekly:
            if pattern.daysOfWeek.isEmpty {
                return pattern.interval == 1 ? "Weekly" : "Every \(pattern.interval) weeks"
            }
            let dayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            let days = pattern.daysOfWeek.map { dayNames[$0] }.joined(separator: ", ")
            return "Every \(days)"
        case .monthly:
            if let day = pattern.dayOfMonth {
                return "Monthly on \(day)\(daySuffix(day))"
            }
            return pattern.interval == 1 ? "Monthly" : "Every \(pattern.interval) months"
        case .yearly:
            return pattern.interval == 1 ? "Yearly" : "Every \(pattern.interval) years"
        case .custom:
            return "Every \(pattern.interval) days"
        }
    }

    private func daySuffix(_ day: Int) -> String {
        switch day {
        case 1, 21, 31: return "st"
        case 2, 22: return "nd"
        case 3, 23: return "rd"
        default: return "th"
        }
    }
}

// MARK: - Time Picker Sheet

struct TimePickerSheet: View {
    @Binding var selectedTime: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            DatePicker(
                "Select Time",
                selection: $selectedTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .padding()
            .navigationTitle("Select Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Recurrence Editor View

struct RecurrenceEditorView: View {
    @Bindable var task: TaskItem
    @Environment(\.dismiss) private var dismiss

    @State private var frequency: RecurrenceFrequency = .daily
    @State private var interval: Int = 1
    @State private var selectedDays: Set<Int> = []
    @State private var dayOfMonth: Int = 1
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Date().addingTimeInterval(86400 * 30)

    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        NavigationStack {
            Form {
                // Frequency
                Section("Repeat") {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(RecurrenceFrequency.allCases, id: \.self) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }

                    if frequency != .daily || interval > 1 {
                        Stepper("Every \(interval) \(intervalUnit)", value: $interval, in: 1...99)
                    }
                }

                // Weekly options
                if frequency == .weekly {
                    Section("Days") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                            ForEach(0..<7, id: \.self) { index in
                                let dayNumber = index + 1
                                Button(action: {
                                    if selectedDays.contains(dayNumber) {
                                        selectedDays.remove(dayNumber)
                                    } else {
                                        selectedDays.insert(dayNumber)
                                    }
                                }) {
                                    Text(dayNames[index])
                                        .font(.caption.bold())
                                        .frame(width: 36, height: 36)
                                        .background(
                                            Circle()
                                                .fill(selectedDays.contains(dayNumber) ? Color.accentColor : Color(.secondarySystemBackground))
                                        )
                                        .foregroundStyle(selectedDays.contains(dayNumber) ? .white : .primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Monthly options
                if frequency == .monthly {
                    Section("Day of Month") {
                        Picker("Day", selection: $dayOfMonth) {
                            ForEach(1...31, id: \.self) { day in
                                Text("\(day)").tag(day)
                            }
                        }
                    }
                }

                // End date
                Section("End") {
                    Toggle("End Date", isOn: $hasEndDate)

                    if hasEndDate {
                        DatePicker("End on", selection: $endDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Recurrence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRecurrence()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadExistingPattern()
            }
        }
    }

    private var intervalUnit: String {
        switch frequency {
        case .daily: return interval == 1 ? "day" : "days"
        case .weekly: return interval == 1 ? "week" : "weeks"
        case .monthly: return interval == 1 ? "month" : "months"
        case .yearly: return interval == 1 ? "year" : "years"
        case .custom: return interval == 1 ? "day" : "days"
        }
    }

    private func loadExistingPattern() {
        guard let pattern = task.recurrencePattern else { return }

        frequency = pattern.frequency
        interval = pattern.interval
        selectedDays = Set(pattern.daysOfWeek)
        dayOfMonth = pattern.dayOfMonth ?? 1
        hasEndDate = pattern.endDate != nil
        endDate = pattern.endDate ?? Date().addingTimeInterval(86400 * 30)
    }

    private func saveRecurrence() {
        let pattern = RecurrencePattern(
            frequency: frequency,
            interval: interval,
            daysOfWeek: frequency == .weekly ? Array(selectedDays).sorted() : [],
            dayOfMonth: frequency == .monthly ? dayOfMonth : nil,
            startDate: task.scheduledDate ?? Date(),
            endDate: hasEndDate ? endDate : nil
        )

        task.recurrencePattern = pattern
        task.isRecurring = true
    }
}

#Preview {
    TaskDetailView(
        task: TaskItem(title: "Sample Task", scheduledDate: Date(), duration: 3600),
        taskManager: TaskManager.preview
    )
}
