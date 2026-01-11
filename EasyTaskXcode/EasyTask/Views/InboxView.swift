import SwiftUI
import SwiftData

struct InboxView: View {
    @ObservedObject var taskManager: TaskManager

    @State private var selectedFilter: InboxFilter = .all
    @State private var selectedTask: TaskItem?
    @State private var showingQuickAdd = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter tabs
                filterTabs

                // Task list
                if filteredTasks.isEmpty {
                    emptyState
                } else {
                    taskList
                }
            }
            .navigationTitle("Inbox")
            .searchable(text: $searchText, prompt: "Search tasks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingQuickAdd = true }) {
                        Image(systemName: "plus")
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { taskManager.rolloverMissedTasks() }) {
                            Label("Rollover Missed Tasks", systemImage: "arrow.forward.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(item: $selectedTask) { task in
                TaskDetailView(task: task, taskManager: taskManager)
            }
            .sheet(isPresented: $showingQuickAdd) {
                QuickAddView(taskManager: taskManager)
            }
        }
    }

    // MARK: - Filter Tabs

    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(InboxFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.title,
                        count: count(for: filter),
                        isSelected: selectedFilter == filter,
                        color: filter.color
                    ) {
                        withAnimation {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }

    private func count(for filter: InboxFilter) -> Int {
        switch filter {
        case .all:
            return taskManager.incompleteTasks().count
        case .floating:
            return taskManager.floatingTasks().count
        case .scheduled:
            return taskManager.tasks.filter { !$0.isCompleted && !$0.isFloating }.count
        case .overdue:
            return taskManager.overdueTasks().count
        case .recurring:
            return taskManager.tasks.filter { $0.isRecurring || $0.parentTaskId != nil }.count
        case .completed:
            return taskManager.tasks.filter { $0.isCompleted }.count
        }
    }

    // MARK: - Filtered Tasks

    private var filteredTasks: [TaskItem] {
        var tasks: [TaskItem]

        switch selectedFilter {
        case .all:
            tasks = taskManager.incompleteTasks()
        case .floating:
            tasks = taskManager.floatingTasks()
        case .scheduled:
            tasks = taskManager.tasks.filter { !$0.isCompleted && !$0.isFloating }
        case .overdue:
            tasks = taskManager.overdueTasks()
        case .recurring:
            tasks = taskManager.tasks.filter { $0.isRecurring || $0.parentTaskId != nil }
        case .completed:
            tasks = taskManager.tasks.filter { $0.isCompleted }
        }

        if !searchText.isEmpty {
            tasks = tasks.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }

        return tasks.sorted { t1, t2 in
            // Sort by priority, then by date
            if t1.priority != t2.priority {
                return t1.priority.rawValue > t2.priority.rawValue
            }
            let d1 = t1.scheduledDate ?? Date.distantFuture
            let d2 = t2.scheduledDate ?? Date.distantFuture
            return d1 < d2
        }
    }

    // MARK: - Task List

    private var taskList: some View {
        List {
            ForEach(filteredTasks) { task in
                TaskCard(
                    task: task,
                    isCompact: false,
                    onTap: { selectedTask = task },
                    onComplete: { taskManager.toggleTaskCompletion(task) }
                )
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        withAnimation {
                            taskManager.deleteTask(task)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        taskManager.toggleTaskCompletion(task)
                    } label: {
                        Label(
                            task.isCompleted ? "Uncomplete" : "Complete",
                            systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark"
                        )
                    }
                    .tint(.green)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedFilter.emptyIcon)
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text(selectedFilter.emptyTitle)
                .font(.title2.bold())

            Text(selectedFilter.emptyMessage)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if selectedFilter == .all {
                Button(action: { showingQuickAdd = true }) {
                    Label("Add Task", systemImage: "plus")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Inbox Filter

enum InboxFilter: CaseIterable {
    case all
    case floating
    case scheduled
    case overdue
    case recurring
    case completed

    var title: String {
        switch self {
        case .all: return "All"
        case .floating: return "Anytime"
        case .scheduled: return "Scheduled"
        case .overdue: return "Overdue"
        case .recurring: return "Recurring"
        case .completed: return "Completed"
        }
    }

    var color: Color {
        switch self {
        case .all: return .blue
        case .floating: return .purple
        case .scheduled: return .green
        case .overdue: return .red
        case .recurring: return .orange
        case .completed: return .gray
        }
    }

    var emptyIcon: String {
        switch self {
        case .all: return "tray"
        case .floating: return "cloud"
        case .scheduled: return "calendar"
        case .overdue: return "clock.badge.checkmark"
        case .recurring: return "repeat"
        case .completed: return "checkmark.circle"
        }
    }

    var emptyTitle: String {
        switch self {
        case .all: return "No Tasks"
        case .floating: return "No Floating Tasks"
        case .scheduled: return "Nothing Scheduled"
        case .overdue: return "All Caught Up!"
        case .recurring: return "No Recurring Tasks"
        case .completed: return "No Completed Tasks"
        }
    }

    var emptyMessage: String {
        switch self {
        case .all: return "Add your first task to get started with planning your day."
        case .floating: return "All your tasks have been scheduled. Nice work!"
        case .scheduled: return "Drag tasks from Anytime to schedule them."
        case .overdue: return "You have no overdue tasks. Keep up the great work!"
        case .recurring: return "Create recurring tasks for habits and regular activities."
        case .completed: return "Complete some tasks to see them here."
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                if count > 0 {
                    Text("\(count)")
                        .font(.caption.bold())
                        .foregroundStyle(isSelected ? .white : color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? color.opacity(0.3) : color.opacity(0.15))
                        )
                }
            }
            .foregroundStyle(isSelected ? color : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color.opacity(0.15) : Color(.secondarySystemBackground))
            )
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? color : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    InboxView(taskManager: TaskManager.preview)
}
