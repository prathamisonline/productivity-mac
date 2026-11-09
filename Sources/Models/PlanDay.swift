import Foundation
import SwiftData

@Model
public final class PlanDay: Identifiable {
    public var id: UUID = UUID()
    public var date: Date = Date.now
    public var reflectionNotes: String = ""
    public var mustWinTaskId: UUID?
    public var hasHandledRollover: Bool = false
    public var isLowEnergyMode: Bool = false

    @Relationship(deleteRule: .nullify, inverse: \TaskItem.planDay) public var tasks: [TaskItem]? = []
    public var planWeek: PlanWeek?

    public init(date: Date = Date.now, reflectionNotes: String = "", mustWinTaskId: UUID? = nil) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.reflectionNotes = reflectionNotes
        self.mustWinTaskId = mustWinTaskId
        self.hasHandledRollover = false
        self.tasks = []
        self.planWeek = nil
    }

    public var completedTasksCount: Int {
        tasks?.filter { $0.isCompleted }.count ?? 0
    }

    public var totalTasksCount: Int {
        tasks?.count ?? 0
    }

    public var completionPercentage: Double {
        guard totalTasksCount > 0 else { return 0 }
        return Double(completedTasksCount) / Double(totalTasksCount)
    }

    public var mustWinTask: TaskItem? {
        guard let mustWinTaskId else { return nil }
        return tasks?.first(where: { $0.id == mustWinTaskId })
    }

    // MARK: - Journal Helpers
    public var weekdayShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    public var dayNumberString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    public var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    public var fullFormattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }

    public var journalTitle: String {
        let lines = reflectionNotes.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard let first = lines.first else { return "Daily Thoughts" }
        if first.hasPrefix("# ") {
            let stripped = String(first.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            return stripped.isEmpty ? "Daily Thoughts" : stripped
        }
        return first
    }

    public var journalBody: String {
        let lines = reflectionNotes.components(separatedBy: .newlines)
        guard let firstIndex = lines.firstIndex(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) else {
            return ""
        }
        let rest = lines[(firstIndex + 1)...]
        return rest.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var journalSnippet: String {
        let body = journalBody
        if !body.isEmpty {
            let singleLine = body.replacingOccurrences(of: "\n", with: " ")
            return singleLine.count > 110 ? String(singleLine.prefix(110)) + "..." : singleLine
        }
        let lines = reflectionNotes.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        if lines.count > 1 {
            let joined = lines.dropFirst().joined(separator: " ")
            return joined.count > 110 ? String(joined.prefix(110)) + "..." : joined
        }
        return "Tap to write today's reflection, learnings, or thoughts..."
    }

    public var wordCount: Int {
        reflectionNotes.split { $0.isWhitespace || $0.isNewline }.count
    }
}
