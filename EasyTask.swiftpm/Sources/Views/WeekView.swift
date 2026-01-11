import SwiftUI
import SwiftData

struct WeekView: View {
    @ObservedObject var taskManager: TaskManager
    @ObservedObject var calendarManager: CalendarManager
    @Binding var selectedDate: Date

    @State private var weekOffset: Int = 0
    @State private var selectedTask: TaskItem?
    @State private var draggedTask: TaskItem?

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Week header with navigation
                    weekHeader

                    // Day columns
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(weekDays, id: \.self) { date in
                                DayColumn(
                                    date: date,
                                    isToday: calendar.isDateInToday(date),
                                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                    tasks: taskManager.tasks(for: date),
                                    events: calendarManager.events(for: date),
                                    onTap: { selectedDate = date },
                                    onTaskTap: { selectedTask = $0 },
                                    onTaskComplete: { taskManager.toggleTaskCompletion($0) }
                                )
                                .dropDestination(for: String.self) { items, _ in
                                    guard let taskIdString = items.first,
                                          let taskId = UUID(uuidString: taskIdString),
                                          let task = taskManager.tasks.first(where: { $0.id == taskId }) else {
                                        return false
                                    }
                                    taskManager.rescheduleTask(task, to: date, time: task.scheduledTime)
                                    return true
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Floating tasks summary
                    floatingTasksSummary
                }
            }
            .navigationTitle("Week")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Today") {
                        withAnimation {
                            weekOffset = 0
                            selectedDate = Date()
                        }
                    }
                }
            }
            .sheet(item: $selectedTask) { task in
                TaskDetailView(task: task, taskManager: taskManager)
            }
            .task(id: weekOffset) {
                let startDate = weekDays.first ?? Date()
                let endDate = weekDays.last ?? Date()
                await calendarManager.fetchEvents(from: startDate, to: endDate)
            }
        }
    }

    // MARK: - Week Days

    private var weekDays: [Date] {
        let today = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let adjustedStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: startOfWeek)!

        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: adjustedStart)
        }
    }

    // MARK: - Week Header

    private var weekHeader: some View {
        HStack {
            Button(action: { withAnimation { weekOffset -= 1 } }) {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(weekRangeString)
                .font(.headline)

            Spacer()

            Button(action: { withAnimation { weekOffset += 1 } }) {
                Image(systemName: "chevron.right")
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var weekRangeString: String {
        guard let start = weekDays.first, let end = weekDays.last else { return "" }

        let formatter = DateFormatter()

        if calendar.component(.month, from: start) == calendar.component(.month, from: end) {
            formatter.dateFormat = "MMM d"
            let startStr = formatter.string(from: start)
            formatter.dateFormat = "d, yyyy"
            let endStr = formatter.string(from: end)
            return "\(startStr) - \(endStr)"
        } else {
            formatter.dateFormat = "MMM d"
            let startStr = formatter.string(from: start)
            let endStr = formatter.string(from: end)
            formatter.dateFormat = ", yyyy"
            let yearStr = formatter.string(from: end)
            return "\(startStr) - \(endStr)\(yearStr)"
        }
    }

    // MARK: - Floating Tasks Summary

    private var floatingTasksSummary: some View {
        let floating = taskManager.floatingTasks()

        return Group {
            if !floating.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Unscheduled Tasks")
                            .font(.headline)

                        Spacer()

                        Text("\(floating.count)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(.secondary))
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 280))], spacing: 8) {
                        ForEach(floating.prefix(6)) { task in
                            TaskCard(
                                task: task,
                                isCompact: true,
                                onTap: { selectedTask = task },
                                onComplete: { taskManager.toggleTaskCompletion(task) }
                            )
                            .draggable(task.id.uuidString)
                        }
                    }

                    if floating.count > 6 {
                        Text("+ \(floating.count - 6) more")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding()
            }
        }
    }
}

// MARK: - Day Column

struct DayColumn: View {
    let date: Date
    let isToday: Bool
    let isSelected: Bool
    let tasks: [TaskItem]
    let events: [CalendarEvent]
    let onTap: () -> Void
    let onTaskTap: (TaskItem) -> Void
    let onTaskComplete: (TaskItem) -> Void

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 8) {
            // Day header
            dayHeader
                .onTapGesture(perform: onTap)

            // Day content
            VStack(spacing: 6) {
                // Events
                ForEach(events.prefix(3), id: \.id) { event in
                    CompactEventRow(event: event)
                }

                // Tasks
                ForEach(tasks.prefix(5)) { task in
                    CompactTaskRow(
                        task: task,
                        onTap: { onTaskTap(task) },
                        onComplete: { onTaskComplete(task) }
                    )
                    .draggable(task.id.uuidString)
                }

                // Overflow indicator
                let remaining = (events.count - 3) + (tasks.count - 5)
                if remaining > 0 {
                    Text("+\(remaining) more")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 140)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
        )
    }

    private var dayHeader: some View {
        VStack(spacing: 4) {
            Text(dayOfWeek)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(isToday ? .accentColor : .secondary)

            Text(dayNumber)
                .font(.title2.bold())
                .foregroundStyle(isToday ? .white : .primary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isToday ? Color.accentColor : Color.clear)
                )
        }
    }

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

// MARK: - Compact Event Row

struct CompactEventRow: View {
    let event: CalendarEvent

    private var eventColor: Color {
        if let cgColor = event.calendarColor {
            return Color(cgColor: cgColor)
        }
        return .blue
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(eventColor)
                .frame(width: 6, height: 6)

            Text(event.title)
                .font(.caption2)
                .lineLimit(1)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Compact Task Row

struct CompactTaskRow: View {
    let task: TaskItem
    let onTap: () -> Void
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Button(action: onComplete) {
                Circle()
                    .strokeBorder(task.color.swiftUIColor, lineWidth: 1.5)
                    .frame(width: 14, height: 14)
                    .overlay(
                        task.isCompleted ?
                        Circle().fill(task.color.swiftUIColor).frame(width: 14, height: 14) : nil
                    )
            }
            .buttonStyle(.plain)

            Text(task.title)
                .font(.caption2)
                .lineLimit(1)
                .strikethrough(task.isCompleted)
                .foregroundStyle(task.isCompleted ? .secondary : .primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onTapGesture(perform: onTap)
    }
}

#Preview {
    WeekView(
        taskManager: TaskManager.preview,
        calendarManager: CalendarManager.preview,
        selectedDate: .constant(Date())
    )
}
