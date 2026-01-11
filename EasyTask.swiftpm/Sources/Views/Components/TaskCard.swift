import SwiftUI

struct TaskCard: View {
    let task: TaskItem
    var isCompact: Bool = false
    var onTap: () -> Void
    var onComplete: () -> Void

    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 12) {
            // Completion checkbox
            Button(action: onComplete) {
                ZStack {
                    Circle()
                        .strokeBorder(task.color.swiftUIColor, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if task.isCompleted {
                        Circle()
                            .fill(task.color.swiftUIColor)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            // Task content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(isCompact ? .subheadline : .body)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .lineLimit(isCompact ? 1 : 2)

                if !isCompact {
                    HStack(spacing: 8) {
                        // Time
                        if let time = task.scheduledTime {
                            Label(timeString(from: time), systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // Duration
                        Label(durationString, systemImage: "hourglass")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        // Recurring indicator
                        if task.isRecurring || task.parentTaskId != nil {
                            Image(systemName: "repeat")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // Priority indicator
                        if task.priority == .high || task.priority == .urgent {
                            Image(systemName: task.priority.iconName)
                                .font(.caption)
                                .foregroundStyle(task.priority == .urgent ? .red : .orange)
                        }
                    }
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(isCompact ? 12 : 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(task.color.swiftUIColor.opacity(0.1))
                )
                .overlay(
                    // Left color accent bar
                    HStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(task.color.swiftUIColor)
                            .frame(width: 4)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                onTap()
            }
        }
        .opacity(task.isCompleted ? 0.6 : 1)
    }

    // MARK: - Helpers

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private var durationString: String {
        let minutes = Int(task.duration / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(remainingMinutes)m"
        }
        return "\(minutes)m"
    }
}

#Preview("Task Card") {
    VStack(spacing: 16) {
        TaskCard(
            task: TaskItem(title: "Morning standup", scheduledTime: Date(), duration: 1800, color: .blue),
            isCompact: false,
            onTap: {},
            onComplete: {}
        )

        TaskCard(
            task: TaskItem(title: "Review pull request", duration: 3600, priority: .high, color: .purple),
            isCompact: true,
            onTap: {},
            onComplete: {}
        )

        TaskCard(
            task: {
                let t = TaskItem(title: "Completed task", color: .green)
                t.isCompleted = true
                return t
            }(),
            isCompact: false,
            onTap: {},
            onComplete: {}
        )
    }
    .padding()
}
