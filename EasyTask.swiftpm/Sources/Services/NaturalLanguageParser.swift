import Foundation

/// Parses natural language input for quick task creation
struct NaturalLanguageParser {

    struct ParsedTask {
        var title: String
        var scheduledDate: Date?
        var scheduledTime: Date?
        var isRecurring: Bool = false
        var frequency: RecurrenceFrequency?
        var daysOfWeek: [Int] = []
        var dayOfMonth: Int?
    }

    private static let calendar = Calendar.current

    // MARK: - Time Patterns

    private static let timePattern = #"(\d{1,2})(:\d{2})?\s*(am|pm|AM|PM)?"#
    private static let relativeTimePattern = #"(in|after)\s+(\d+)\s*(hour|hr|minute|min)s?"#

    // MARK: - Day Patterns

    private static let dayNames = [
        "sunday": 1, "sun": 1,
        "monday": 2, "mon": 2,
        "tuesday": 3, "tue": 3, "tues": 3,
        "wednesday": 4, "wed": 4,
        "thursday": 5, "thu": 5, "thur": 5, "thurs": 5,
        "friday": 6, "fri": 6,
        "saturday": 7, "sat": 7
    ]

    private static let relativeDay = [
        "today": 0,
        "tomorrow": 1,
        "day after tomorrow": 2
    ]

    // MARK: - Recurrence Patterns

    private static let dailyPattern = #"every\s*day|daily"#
    private static let weekdayPattern = #"every\s*(weekday|work\s*day)"#
    private static let weekendPattern = #"every\s*weekend"#
    private static let weeklyPattern = #"every\s*week|weekly"#
    private static let monthlyPattern = #"every\s*month|monthly"#
    private static let yearlyPattern = #"every\s*year|yearly|annually"#
    private static let specificDaysPattern = #"every\s+((?:(?:mon|tue|wed|thu|fri|sat|sun|monday|tuesday|wednesday|thursday|friday|saturday|sunday)(?:\s*,?\s*(?:and\s+)?)?)+)"#
    private static let dayOfMonthPattern = #"(?:on\s+)?(?:the\s+)?(\d{1,2})(?:st|nd|rd|th)?\s+(?:of\s+)?every\s+month"#
    private static let intervalPattern = #"every\s+(\d+)\s*(day|week|month|year)s?"#

    // MARK: - Main Parse Function

    static func parse(_ input: String) -> ParsedTask {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        var result = ParsedTask(title: text)

        // Parse recurrence first (it helps identify what to extract)
        parseRecurrence(from: &text, into: &result)

        // Parse time
        parseTime(from: &text, into: &result)

        // Parse date
        parseDate(from: &text, into: &result)

        // Clean up title
        result.title = cleanupTitle(text)

        return result
    }

    // MARK: - Recurrence Parsing

    private static func parseRecurrence(from text: inout String, into result: inout ParsedTask) {
        let lowercased = text.lowercased()

        // Check for specific days pattern: "every Mon Wed Fri"
        if let match = lowercased.range(of: specificDaysPattern, options: .regularExpression) {
            result.isRecurring = true
            result.frequency = .weekly

            let matchedText = String(text[match])
            for (dayName, dayNumber) in dayNames {
                if matchedText.lowercased().contains(dayName) {
                    result.daysOfWeek.append(dayNumber)
                }
            }
            result.daysOfWeek = Array(Set(result.daysOfWeek)).sorted()

            text = text.replacingCharacters(in: match, with: "")
            return
        }

        // Check for day of month pattern
        if let match = lowercased.range(of: dayOfMonthPattern, options: .regularExpression) {
            result.isRecurring = true
            result.frequency = .monthly

            let matchedText = String(text[match])
            if let numMatch = matchedText.range(of: #"\d+"#, options: .regularExpression) {
                result.dayOfMonth = Int(matchedText[numMatch])
            }

            text = text.replacingCharacters(in: match, with: "")
            return
        }

        // Check for interval pattern: "every 2 weeks"
        if let match = lowercased.range(of: intervalPattern, options: .regularExpression) {
            result.isRecurring = true
            let matchedText = String(lowercased[match])

            if matchedText.contains("day") {
                result.frequency = .custom
            } else if matchedText.contains("week") {
                result.frequency = .weekly
            } else if matchedText.contains("month") {
                result.frequency = .monthly
            } else if matchedText.contains("year") {
                result.frequency = .yearly
            }

            text = text.replacingCharacters(in: match, with: "")
            return
        }

        // Simple patterns
        if lowercased.range(of: dailyPattern, options: .regularExpression) != nil {
            result.isRecurring = true
            result.frequency = .daily
            text = text.replacingOccurrences(of: dailyPattern, with: "", options: [.regularExpression, .caseInsensitive])
        } else if lowercased.range(of: weekdayPattern, options: .regularExpression) != nil {
            result.isRecurring = true
            result.frequency = .weekly
            result.daysOfWeek = [2, 3, 4, 5, 6] // Mon-Fri
            text = text.replacingOccurrences(of: weekdayPattern, with: "", options: [.regularExpression, .caseInsensitive])
        } else if lowercased.range(of: weekendPattern, options: .regularExpression) != nil {
            result.isRecurring = true
            result.frequency = .weekly
            result.daysOfWeek = [1, 7] // Sat, Sun
            text = text.replacingOccurrences(of: weekendPattern, with: "", options: [.regularExpression, .caseInsensitive])
        } else if lowercased.range(of: weeklyPattern, options: .regularExpression) != nil {
            result.isRecurring = true
            result.frequency = .weekly
            text = text.replacingOccurrences(of: weeklyPattern, with: "", options: [.regularExpression, .caseInsensitive])
        } else if lowercased.range(of: monthlyPattern, options: .regularExpression) != nil {
            result.isRecurring = true
            result.frequency = .monthly
            text = text.replacingOccurrences(of: monthlyPattern, with: "", options: [.regularExpression, .caseInsensitive])
        } else if lowercased.range(of: yearlyPattern, options: .regularExpression) != nil {
            result.isRecurring = true
            result.frequency = .yearly
            text = text.replacingOccurrences(of: yearlyPattern, with: "", options: [.regularExpression, .caseInsensitive])
        }
    }

    // MARK: - Time Parsing

    private static func parseTime(from text: inout String, into result: inout ParsedTask) {
        let lowercased = text.lowercased()

        // Try relative time first
        if let match = lowercased.range(of: relativeTimePattern, options: .regularExpression) {
            let matchedText = String(lowercased[match])

            if let numMatch = matchedText.range(of: #"\d+"#, options: .regularExpression) {
                let number = Int(matchedText[numMatch]) ?? 0
                var date = Date()

                if matchedText.contains("hour") || matchedText.contains("hr") {
                    date = calendar.date(byAdding: .hour, value: number, to: date) ?? date
                } else if matchedText.contains("min") {
                    date = calendar.date(byAdding: .minute, value: number, to: date) ?? date
                }

                result.scheduledTime = date
                result.scheduledDate = date
                text = text.replacingCharacters(in: match, with: "")
                return
            }
        }

        // Try absolute time pattern
        if let match = text.range(of: timePattern, options: .regularExpression) {
            let matchedText = String(text[match])

            // Parse hour
            var hour: Int = 0
            var minute: Int = 0

            if let colonIndex = matchedText.firstIndex(of: ":") {
                let hourPart = matchedText[..<colonIndex]
                hour = Int(hourPart.filter { $0.isNumber }) ?? 0

                let afterColon = matchedText[matchedText.index(after: colonIndex)...]
                minute = Int(afterColon.prefix(2).filter { $0.isNumber }) ?? 0
            } else {
                hour = Int(matchedText.filter { $0.isNumber }) ?? 0
            }

            // Adjust for AM/PM
            let lowerMatch = matchedText.lowercased()
            if lowerMatch.contains("pm") && hour < 12 {
                hour += 12
            } else if lowerMatch.contains("am") && hour == 12 {
                hour = 0
            }

            // Create time
            var components = calendar.dateComponents([.year, .month, .day], from: result.scheduledDate ?? Date())
            components.hour = hour
            components.minute = minute

            if let time = calendar.date(from: components) {
                result.scheduledTime = time
                if result.scheduledDate == nil {
                    result.scheduledDate = time
                }
            }

            text = text.replacingCharacters(in: match, with: "")
        }

        // Common time keywords
        let timeKeywords: [(String, Int, Int)] = [
            ("morning", 9, 0),
            ("noon", 12, 0),
            ("afternoon", 14, 0),
            ("evening", 18, 0),
            ("night", 20, 0)
        ]

        for (keyword, hour, minute) in timeKeywords {
            if lowercased.contains(keyword) {
                var components = calendar.dateComponents([.year, .month, .day], from: result.scheduledDate ?? Date())
                components.hour = hour
                components.minute = minute

                if let time = calendar.date(from: components) {
                    result.scheduledTime = time
                    if result.scheduledDate == nil {
                        result.scheduledDate = time
                    }
                }

                text = text.replacingOccurrences(of: keyword, with: "", options: .caseInsensitive)
                break
            }
        }
    }

    // MARK: - Date Parsing

    private static func parseDate(from text: inout String, into result: inout ParsedTask) {
        let lowercased = text.lowercased()

        // Check relative days
        for (dayText, offset) in relativeDay {
            if lowercased.contains(dayText) {
                result.scheduledDate = calendar.date(byAdding: .day, value: offset, to: Date())
                text = text.replacingOccurrences(of: dayText, with: "", options: .caseInsensitive)

                // Preserve time if already set
                if let time = result.scheduledTime, let date = result.scheduledDate {
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
                    var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                    dateComponents.hour = timeComponents.hour
                    dateComponents.minute = timeComponents.minute
                    result.scheduledDate = calendar.date(from: dateComponents)
                    result.scheduledTime = result.scheduledDate
                }
                return
            }
        }

        // Check day names (next occurrence)
        for (dayName, dayNumber) in dayNames {
            if lowercased.contains(dayName) {
                result.scheduledDate = nextDate(for: dayNumber)
                text = text.replacingOccurrences(of: dayName, with: "", options: .caseInsensitive)
                text = text.replacingOccurrences(of: "next", with: "", options: .caseInsensitive)
                text = text.replacingOccurrences(of: "this", with: "", options: .caseInsensitive)
                text = text.replacingOccurrences(of: "on", with: "", options: .caseInsensitive)

                // Preserve time if already set
                if let time = result.scheduledTime, let date = result.scheduledDate {
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
                    var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                    dateComponents.hour = timeComponents.hour
                    dateComponents.minute = timeComponents.minute
                    result.scheduledDate = calendar.date(from: dateComponents)
                    result.scheduledTime = result.scheduledDate
                }
                return
            }
        }
    }

    // MARK: - Helpers

    private static func nextDate(for weekday: Int) -> Date {
        let today = Date()
        let currentWeekday = calendar.component(.weekday, from: today)

        var daysToAdd = weekday - currentWeekday
        if daysToAdd <= 0 {
            daysToAdd += 7
        }

        return calendar.date(byAdding: .day, value: daysToAdd, to: today) ?? today
    }

    private static func cleanupTitle(_ text: String) -> String {
        var cleaned = text

        // Remove common prepositions that might be left over
        let wordsToRemove = ["at", "on", "for", "the", "a", "an", "in"]
        for word in wordsToRemove {
            cleaned = cleaned.replacingOccurrences(
                of: "\\b\(word)\\b",
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
        }

        // Clean up whitespace
        cleaned = cleaned.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Capitalize first letter
        if let first = cleaned.first {
            cleaned = first.uppercased() + cleaned.dropFirst()
        }

        return cleaned
    }
}
