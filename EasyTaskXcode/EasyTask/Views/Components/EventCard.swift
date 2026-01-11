import SwiftUI

struct EventCard: View {
    let event: CalendarEvent

    private var eventColor: Color {
        if let cgColor = event.calendarColor {
            return Color(cgColor: cgColor)
        }
        return .blue
    }

    var body: some View {
        HStack(spacing: 12) {
            // Calendar icon
            Image(systemName: "calendar")
                .font(.body)
                .foregroundStyle(eventColor)

            // Event content
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    // Time range
                    Text(timeRangeString)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Location
                    if let location = event.location, !location.isEmpty {
                        Label(location, systemImage: "location")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    // Calendar name
                    Text(event.calendarTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(eventColor.opacity(0.2))
                        )
                }
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(eventColor.opacity(0.05))
                )
                .overlay(
                    // Left color accent bar
                    HStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(eventColor)
                            .frame(width: 4)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                )
        )
    }

    // MARK: - Helpers

    private var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        if event.isAllDay {
            return "All day"
        }

        let start = formatter.string(from: event.startDate)
        let end = formatter.string(from: event.endDate)
        return "\(start) - \(end)"
    }
}

#Preview("Event Card") {
    VStack(spacing: 16) {
        EventCard(
            event: CalendarEvent(
                title: "Team Meeting",
                startDate: Date(),
                endDate: Date().addingTimeInterval(3600),
                location: "Conference Room A",
                calendarTitle: "Work"
            )
        )

        EventCard(
            event: CalendarEvent(
                title: "Lunch with Sarah",
                startDate: Date(),
                endDate: Date().addingTimeInterval(5400),
                calendarTitle: "Personal"
            )
        )

        EventCard(
            event: CalendarEvent(
                title: "Company Holiday",
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400),
                isAllDay: true,
                calendarTitle: "Holidays"
            )
        )
    }
    .padding()
}
