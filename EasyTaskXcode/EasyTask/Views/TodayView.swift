import SwiftUI
import SwiftData

struct TodayView: View {
    @ObservedObject var taskManager: TaskManager
    @ObservedObject var calendarManager: CalendarManager
    @Binding var selectedDate: Date

    @State private var showingDatePicker = false
    @State private var selectedTask: TaskItem?
    @State private var draggedTask: TaskItem?

    private let hourHeight: CGFloat = 60
    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        // Floating tasks section
                        floatingTasksSection

                        // Timeline
                        timelineView
                    }
                }
                .onAppear {
                    // Scroll to current hour
                    let currentHour = calendar.component(.hour, from: Date())
                    withAnimation {
                        proxy.scrollTo("hour-\(currentHour)", anchor: .top)
                    }
                }
            }
            .navigationTitle(dateTitle)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingDatePicker = true }) {
                        Image(systemName: "calendar")
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Today") {
                        withAnimation {
                            selectedDate = Date()
                        }
                    }
                    .disabled(calendar.isDateInToday(selectedDate))
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerSheet(selectedDate: $selectedDate)
            }
            .sheet(item: $selectedTask) { task in
                TaskDetailView(task: task, taskManager: taskManager)
            }
        }
    }

    // MARK: - Date Title

    private var dateTitle: String {
        if calendar.isDateInToday(selectedDate) {
            return "Today"
        } else if calendar.isDateInTomorrow(selectedDate) {
            return "Tomorrow"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: selectedDate)
        }
    }

    // MARK: - Floating Tasks Section

    private var floatingTasksSection: some View {
        let floatingTasks = taskManager.floatingTasks()

        return Group {
            if !floatingTasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Anytime")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("\(floatingTasks.count)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(.secondary))
                    }
                    .padding(.horizontal)

                    ForEach(floatingTasks) { task in
                        TaskCard(
                            task: task,
                            isCompact: true,
                            onTap: { selectedTask = task },
                            onComplete: { taskManager.toggleTaskCompletion(task) }
                        )
                        .draggable(task.id.uuidString) {
                            TaskCard(task: task, isCompact: true, onTap: {}, onComplete: {})
                                .frame(width: 300)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color(.systemBackground))

                Divider()
            }
        }
    }

    // MARK: - Timeline View

    private var timelineView: some View {
        let dayStart = calendar.startOfDay(for: selectedDate)
        let items = calendarManager.timelineItems(for: selectedDate, tasks: taskManager.tasks(for: selectedDate))

        return ZStack(alignment: .topLeading) {
            // Hour lines
            VStack(spacing: 0) {
                ForEach(0..<24, id: \.self) { hour in
                    HourRow(hour: hour)
                        .frame(height: hourHeight)
                        .id("hour-\(hour)")
                }
            }

            // Current time indicator
            if calendar.isDateInToday(selectedDate) {
                CurrentTimeIndicator()
                    .offset(y: currentTimeOffset)
            }

            // Timeline items
            ForEach(items) { item in
                timelineItemView(item, dayStart: dayStart)
            }
        }
        .padding(.leading, 60)
        .dropDestination(for: String.self) { items, location in
            guard let taskIdString = items.first,
                  let taskId = UUID(uuidString: taskIdString),
                  let task = taskManager.tasks.first(where: { $0.id == taskId }) else {
                return false
            }

            // Calculate the hour from drop location
            let hour = Int(location.y / hourHeight)
            let minute = Int((location.y.truncatingRemainder(dividingBy: hourHeight) / hourHeight) * 60)

            var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
            components.hour = hour
            components.minute = (minute / 15) * 15 // Round to nearest 15 min

            if let newDate = calendar.date(from: components) {
                taskManager.rescheduleTask(task, to: selectedDate, time: newDate)
            }

            return true
        }
    }

    // MARK: - Timeline Item View

    @ViewBuilder
    private func timelineItemView(_ item: TimelineItem, dayStart: Date) -> some View {
        if let startTime = item.startTime {
            let offset = startTime.timeIntervalSince(dayStart) / 3600 * hourHeight
            let height = max(item.duration / 3600 * hourHeight, 44)

            Group {
                switch item {
                case .task(let task):
                    TaskCard(
                        task: task,
                        isCompact: false,
                        onTap: { selectedTask = task },
                        onComplete: { taskManager.toggleTaskCompletion(task) }
                    )
                    .draggable(task.id.uuidString) {
                        TaskCard(task: task, isCompact: false, onTap: {}, onComplete: {})
                            .frame(width: 280)
                    }

                case .event(let event):
                    EventCard(event: event)
                }
            }
            .frame(height: height)
            .padding(.trailing)
            .offset(y: offset)
        }
    }

    // MARK: - Current Time Offset

    private var currentTimeOffset: CGFloat {
        let now = Date()
        let dayStart = calendar.startOfDay(for: now)
        let secondsSinceStart = now.timeIntervalSince(dayStart)
        return secondsSinceStart / 3600 * hourHeight
    }
}

// MARK: - Hour Row

struct HourRow: View {
    let hour: Int

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"

        var components = DateComponents()
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? Date()

        return formatter.string(from: date).lowercased()
    }

    var body: some View {
        HStack(alignment: .top) {
            Text(timeString)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .trailing)
                .offset(y: -6)

            VStack {
                Divider()
                Spacer()
            }
        }
    }
}

// MARK: - Current Time Indicator

struct CurrentTimeIndicator: View {
    var body: some View {
        HStack(spacing: 0) {
            Circle()
                .fill(.red)
                .frame(width: 12, height: 12)
                .offset(x: -6)

            Rectangle()
                .fill(.red)
                .frame(height: 2)
        }
    }
}

// MARK: - Date Picker Sheet

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()
            .navigationTitle("Select Date")
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

#Preview {
    TodayView(
        taskManager: TaskManager.preview,
        calendarManager: CalendarManager.preview,
        selectedDate: .constant(Date())
    )
}
