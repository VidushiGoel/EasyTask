# EasyTask

A beautiful timeline-based task planner for iOS and macOS. Plan your days and weeks with ease, featuring recurring tasks, natural language input, and seamless iCloud sync.

## Features

### Core Features
- **Today View** - Vertical timeline showing your day at a glance with a "now" indicator
- **Week View** - 7-day horizontal view for week-level planning
- **Task Inbox** - Central hub for all your tasks with filtering and search
- **Quick Add** - Natural language input for fast task creation
- **Drag & Drop** - Easily reschedule tasks by dragging them around

### Task Management
- Create one-off and recurring tasks
- Set priorities and custom colors
- Schedule tasks or leave them floating ("Anytime")
- Complete, skip, or reschedule individual task instances

### Recurring Tasks (Free!)
- Daily, weekly, monthly, and yearly recurrence
- Custom intervals (e.g., every 2 weeks)
- Specific days of week (e.g., Mon, Wed, Fri)
- Day of month (e.g., 1st of every month)

### Calendar Integration
- Read events from Apple Calendar
- Events appear alongside tasks in timeline views
- Choose which calendars to display

### Sync & Storage
- iCloud sync across all your devices
- Offline-first - works without internet
- No account required

## Requirements

- iOS 17.0+ / macOS 14.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

1. Clone the repository
2. Open `EasyTask.swiftpm` in Xcode or Swift Playgrounds
3. Build and run on your device or simulator

## Quick Add Examples

The natural language parser understands various formats:

```
"Standup every weekday 10am"
"Gym Mon Wed Fri 6pm"
"Pay rent on 1st every month"
"Review PR tomorrow morning"
"Call mom in 2 hours"
"Team meeting at 3pm"
"Weekly report every Friday"
```

## Architecture

```
EasyTask/
├── Sources/
│   ├── EasyTaskApp.swift          # App entry point
│   ├── Models/
│   │   ├── TaskItem.swift         # Core task model
│   │   ├── RecurrencePattern.swift # Recurrence rules
│   │   ├── CalendarEvent.swift    # Apple Calendar events
│   │   ├── TimelineItem.swift     # Unified timeline item
│   │   └── UserSettings.swift     # App preferences
│   ├── Views/
│   │   ├── ContentView.swift      # Main navigation
│   │   ├── TodayView.swift        # Today timeline
│   │   ├── WeekView.swift         # Week overview
│   │   ├── InboxView.swift        # Task inbox
│   │   ├── QuickAddView.swift     # Quick add sheet
│   │   ├── TaskDetailView.swift   # Task editing
│   │   ├── SettingsView.swift     # App settings
│   │   └── Components/
│   │       ├── TaskCard.swift     # Task display card
│   │       └── EventCard.swift    # Event display card
│   ├── Services/
│   │   ├── TaskManager.swift      # Task CRUD operations
│   │   ├── CalendarManager.swift  # EventKit integration
│   │   ├── NotificationManager.swift # Reminders
│   │   └── NaturalLanguageParser.swift # Input parsing
│   └── Utilities/
│       ├── DateExtensions.swift   # Date helpers
│       └── ViewExtensions.swift   # SwiftUI helpers
└── Package.swift                  # Swift Package config
```

## Technology Stack

- **SwiftUI** - Declarative UI framework
- **SwiftData** - Modern data persistence
- **EventKit** - Apple Calendar integration
- **CloudKit** - iCloud sync
- **UserNotifications** - Local notifications

## Design Principles

1. **Timeline-first, not list-first** - Visual time blocks over checkboxes
2. **Tasks feel lighter than events** - Easy to create, reschedule, complete
3. **Fast to plan, calming to look at** - Minimal UI, beautiful design
4. **Native Apple experience** - Follows platform conventions
5. **Offline-first, cloud-synced** - Works anywhere, syncs everywhere

## License

MIT License - see LICENSE file for details.
