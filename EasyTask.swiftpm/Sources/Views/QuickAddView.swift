import SwiftUI

struct QuickAddView: View {
    @ObservedObject var taskManager: TaskManager
    @Environment(\.dismiss) private var dismiss

    @State private var inputText = ""
    @State private var parsedTask: NaturalLanguageParser.ParsedTask?
    @State private var showingAdvanced = false

    // Advanced options
    @State private var selectedColor: TaskColor = .blue
    @State private var selectedPriority: TaskPriority = .medium
    @State private var customDuration: Int = 30

    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Main input
                inputSection

                // Parsed preview
                if let parsed = parsedTask, !inputText.isEmpty {
                    parsedPreview(parsed)
                }

                // Advanced options
                if showingAdvanced {
                    advancedOptions
                }

                Spacer()

                // Examples
                if inputText.isEmpty {
                    examplesSection
                }
            }
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addTask()
                    }
                    .fontWeight(.semibold)
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            isInputFocused = true
        }
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.accentColor)

                TextField("What do you need to do?", text: $inputText)
                    .font(.body)
                    .focused($isInputFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        if !inputText.trimmingCharacters(in: .whitespaces).isEmpty {
                            addTask()
                        }
                    }
                    .onChange(of: inputText) { _, newValue in
                        parsedTask = NaturalLanguageParser.parse(newValue)
                    }

                if !inputText.isEmpty {
                    Button(action: { inputText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
            .padding()

            // Toggle advanced
            Button(action: { withAnimation { showingAdvanced.toggle() } }) {
                HStack {
                    Text(showingAdvanced ? "Hide Options" : "More Options")
                        .font(.subheadline)
                    Image(systemName: showingAdvanced ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Parsed Preview

    private func parsedPreview(_ parsed: NaturalLanguageParser.ParsedTask) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Preview")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(parsed.title.isEmpty ? inputText : parsed.title)
                    .font(.headline)

                // Details
                HStack(spacing: 16) {
                    // Date/Time
                    if let date = parsed.scheduledDate {
                        Label(formatDate(date), systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let time = parsed.scheduledTime {
                        Label(formatTime(time), systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Recurrence
                    if parsed.isRecurring {
                        Label(recurrenceText(parsed), systemImage: "repeat")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedColor.swiftUIColor.opacity(0.1))
                    .overlay(
                        HStack {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(selectedColor.swiftUIColor)
                                .frame(width: 4)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    )
            )
        }
        .padding(.horizontal)
    }

    // MARK: - Advanced Options

    private var advancedOptions: some View {
        VStack(spacing: 16) {
            Divider()

            // Color picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(TaskColor.allCases, id: \.self) { color in
                            Circle()
                                .fill(color.swiftUIColor)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .strokeBorder(.white, lineWidth: selectedColor == color ? 3 : 0)
                                )
                                .shadow(color: color.swiftUIColor.opacity(0.5), radius: selectedColor == color ? 4 : 0)
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                }
            }
            .padding(.horizontal)

            // Priority picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Priority")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    ForEach(TaskPriority.allCases, id: \.self) { priority in
                        Button(action: { selectedPriority = priority }) {
                            HStack(spacing: 4) {
                                Image(systemName: priority.iconName)
                                    .font(.caption)
                                Text(priority.label)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedPriority == priority ? Color.accentColor : Color(.secondarySystemBackground))
                            )
                            .foregroundStyle(selectedPriority == priority ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal)

            // Duration
            VStack(alignment: .leading, spacing: 8) {
                Text("Duration: \(customDuration) min")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Slider(value: Binding(
                    get: { Double(customDuration) },
                    set: { customDuration = Int($0) }
                ), in: 5...180, step: 5)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }

    // MARK: - Examples Section

    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Try saying...")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(examplePhrases, id: \.self) { phrase in
                    Button(action: { inputText = phrase }) {
                        HStack {
                            Text(phrase)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.left")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
    }

    private let examplePhrases = [
        "Standup every weekday 10am",
        "Gym Mon Wed Fri 6pm",
        "Pay rent on 1st every month",
        "Review PR tomorrow morning",
        "Call mom in 2 hours"
    ]

    // MARK: - Actions

    private func addTask() {
        let parsed = parsedTask ?? NaturalLanguageParser.parse(inputText)

        if parsed.isRecurring, let frequency = parsed.frequency {
            let _ = taskManager.createRecurringTask(
                title: parsed.title.isEmpty ? inputText : parsed.title,
                scheduledTime: parsed.scheduledTime,
                duration: TimeInterval(customDuration * 60),
                priority: selectedPriority,
                color: selectedColor,
                frequency: frequency,
                daysOfWeek: parsed.daysOfWeek,
                dayOfMonth: parsed.dayOfMonth,
                startDate: parsed.scheduledDate ?? Date()
            )
        } else {
            let _ = taskManager.createTask(
                title: parsed.title.isEmpty ? inputText : parsed.title,
                scheduledDate: parsed.scheduledDate,
                scheduledTime: parsed.scheduledTime,
                duration: TimeInterval(customDuration * 60),
                isFloating: parsed.scheduledDate == nil && parsed.scheduledTime == nil,
                priority: selectedPriority,
                color: selectedColor
            )
        }

        dismiss()
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, MMM d"
            return formatter.string(from: date)
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func recurrenceText(_ parsed: NaturalLanguageParser.ParsedTask) -> String {
        guard let frequency = parsed.frequency else { return "Recurring" }

        switch frequency {
        case .daily:
            return "Daily"
        case .weekly:
            if parsed.daysOfWeek.isEmpty {
                return "Weekly"
            }
            let dayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            let days = parsed.daysOfWeek.map { dayNames[$0] }.joined(separator: ", ")
            return "Every \(days)"
        case .monthly:
            if let day = parsed.dayOfMonth {
                return "Monthly on \(day)\(daySuffix(day))"
            }
            return "Monthly"
        case .yearly:
            return "Yearly"
        case .custom:
            return "Custom"
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

#Preview {
    QuickAddView(taskManager: TaskManager.preview)
}
