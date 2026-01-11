import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        MainContentView()
            .environment(\.modelContext, modelContext)
    }
}

struct MainContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: UserSettings

    @State private var taskManager: TaskManager?
    @StateObject private var calendarManager = CalendarManager()

    @State private var selectedTab: AppTab = .today
    @State private var showingQuickAdd = false
    @State private var selectedDate = Date()

    var body: some View {
        Group {
            if let taskManager = taskManager {
                mainContent(taskManager: taskManager)
            } else {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if taskManager == nil {
                taskManager = TaskManager(modelContext: modelContext)
            }
        }
    }

    @ViewBuilder
    private func mainContent(taskManager: TaskManager) -> some View {
        Group {
            #if os(iOS)
            iOSTabView(taskManager: taskManager)
            #else
            macOSNavigationView(taskManager: taskManager)
            #endif
        }
        .sheet(isPresented: $showingQuickAdd) {
            QuickAddView(taskManager: taskManager)
        }
        .task {
            await calendarManager.requestAccess()
            await calendarManager.fetchEvents(from: Date(), to: Calendar.current.date(byAdding: .day, value: 7, to: Date())!)
        }
    }

    // MARK: - iOS Tab View

    #if os(iOS)
    private func iOSTabView(taskManager: TaskManager) -> some View {
        ZStack {
            TabView(selection: $selectedTab) {
                TodayView(
                    taskManager: taskManager,
                    calendarManager: calendarManager,
                    selectedDate: $selectedDate
                )
                .tabItem {
                    Label("Today", systemImage: "sun.max.fill")
                }
                .tag(AppTab.today)

                WeekView(
                    taskManager: taskManager,
                    calendarManager: calendarManager,
                    selectedDate: $selectedDate
                )
                .tabItem {
                    Label("Week", systemImage: "calendar")
                }
                .tag(AppTab.week)

                InboxView(taskManager: taskManager)
                    .tabItem {
                        Label("Inbox", systemImage: "tray.fill")
                    }
                    .tag(AppTab.inbox)

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(AppTab.settings)
            }

            // Floating action button
            VStack {
                Spacer()
                quickAddButton
                    .padding(.bottom, 70)
            }
        }
    }
    #endif

    // MARK: - macOS Navigation View

    #if os(macOS)
    private func macOSNavigationView(taskManager: TaskManager) -> some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                NavigationLink(value: AppTab.today) {
                    Label("Today", systemImage: "sun.max.fill")
                }

                NavigationLink(value: AppTab.week) {
                    Label("Week", systemImage: "calendar")
                }

                NavigationLink(value: AppTab.inbox) {
                    Label("Inbox", systemImage: "tray.fill")
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("EasyTask")
            .toolbar {
                ToolbarItem {
                    Button(action: { showingQuickAdd = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        } detail: {
            switch selectedTab {
            case .today:
                TodayView(
                    taskManager: taskManager,
                    calendarManager: calendarManager,
                    selectedDate: $selectedDate
                )
            case .week:
                WeekView(
                    taskManager: taskManager,
                    calendarManager: calendarManager,
                    selectedDate: $selectedDate
                )
            case .inbox:
                InboxView(taskManager: taskManager)
            case .settings:
                SettingsView()
            }
        }
    }
    #endif

    // MARK: - Quick Add Button

    private var quickAddButton: some View {
        Button(action: { showingQuickAdd = true }) {
            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(Color.accentColor)
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - App Tab

enum AppTab: Hashable {
    case today
    case week
    case inbox
    case settings
}

#Preview {
    ContentView()
        .environmentObject(UserSettings.shared)
        .environmentObject(NotificationManager.shared)
        .modelContainer(for: [TaskItem.self, RecurrencePattern.self], inMemory: true)
}
