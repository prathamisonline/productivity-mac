import Foundation
import SwiftData

@Model
public final class TaskItem {
    public var id: UUID = UUID()
    public var title: String = ""
    public var notes: String?
    public var isCompleted: Bool = false
    public var priorityRaw: Int = 1 // 0: low, 1: medium, 2: high, 3: urgent
    public var estimatedPomodoros: Int = 1
    public var completedPomodoros: Int = 0
    public var createdAt: Date = Date.now
    public var scheduledTime: Date?
    public var durationMinutes: Int = 30
    public var loggedMinutes: Int = 0
    public var completedAt: Date?
    public var orderIndex: Int = 0
    public var isLoggedWin: Bool = false

    // Scope & Goal Linkage
    public var taskScopeRaw: String = "daily" // "longTerm", "shortTerm", "daily"
    public var goal: GoalItem?

    // Continues for upcoming days (Recurrence)
    public var recurrenceRaw: String = "never"
    public var recurrenceParentId: UUID?

    public var planDay: PlanDay?
    public var planWeek: PlanWeek?
    @Relationship(deleteRule: .cascade) public var sessions: [PomodoroSession]? = []

    public enum TaskScope: String, CaseIterable, Identifiable {
        case longTerm = "longTerm"
        case shortTerm = "shortTerm"
        case daily = "daily"

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .longTerm: return "Long-Term Task"
            case .shortTerm: return "Short-Term Task"
            case .daily: return "Daily Task"
            }
        }

        public var badgeName: String {
            switch self {
            case .longTerm: return "Long-Term"
            case .shortTerm: return "Short-Term"
            case .daily: return "Daily"
            }
        }

        public var icon: String {
            switch self {
            case .longTerm: return "target"
            case .shortTerm: return "bolt.fill"
            case .daily: return "sun.max.fill"
            }
        }
    }

    public var taskScope: TaskScope {
        get { TaskScope(rawValue: taskScopeRaw) ?? .daily }
        set { taskScopeRaw = newValue.rawValue }
    }

    public enum RecurrenceRule: String, CaseIterable, Identifiable {
        case never = "One-Time"
        case daily = "Every Day"
        case weekdays = "Weekdays (Mon–Fri)"
        case weekends = "Weekends (Sat–Sun)"
        case weekly = "Every Week"

        public var id: String { rawValue }

        public var icon: String {
            switch self {
            case .never: return "calendar"
            case .daily: return "repeat"
            case .weekdays: return "briefcase.fill"
            case .weekends: return "cup.and.saucer.fill"
            case .weekly: return "calendar.badge.clock"
            }
        }

        public var shortTitle: String {
            switch self {
            case .never: return ""
            case .daily: return "Daily"
            case .weekdays: return "Weekdays"
            case .weekends: return "Weekends"
            case .weekly: return "Weekly"
            }
        }
    }

    public var recurrenceRule: RecurrenceRule {
        get { RecurrenceRule(rawValue: recurrenceRaw) ?? .never }
        set { recurrenceRaw = newValue.rawValue }
    }

    public init(
        title: String,
        notes: String? = nil,
        priorityRaw: Int = 1,
        estimatedPomodoros: Int = 1,
        scheduledTime: Date? = nil,
        durationMinutes: Int = 30,
        orderIndex: Int = 0,
        taskScope: TaskScope = .daily,
        goal: GoalItem? = nil,
        recurrenceRaw: String = "never",
        recurrenceParentId: UUID? = nil,
        planDay: PlanDay? = nil,
        planWeek: PlanWeek? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.isCompleted = false
        self.priorityRaw = priorityRaw
        self.estimatedPomodoros = estimatedPomodoros
        self.completedPomodoros = 0
        self.createdAt = Date.now
        self.scheduledTime = scheduledTime ?? Date.now
        self.durationMinutes = durationMinutes
        self.orderIndex = orderIndex
        self.taskScopeRaw = taskScope.rawValue
        self.goal = goal
        self.recurrenceRaw = recurrenceRaw
        self.recurrenceParentId = recurrenceParentId
        self.completedAt = nil
        self.planDay = planDay
        self.planWeek = planWeek
        self.sessions = []
    }

    public var effectiveStartTime: Date {
        scheduledTime ?? createdAt
    }

    public var effectiveEndTime: Date {
        Calendar.current.date(byAdding: .minute, value: max(5, durationMinutes), to: effectiveStartTime) ?? effectiveStartTime
    }

    public var formattedLoggedTime: String {
        guard loggedMinutes > 0 else { return "0m" }
        let h = loggedMinutes / 60
        let m = loggedMinutes % 60
        if h > 0 && m > 0 {
            return "\(h)h \(m)m"
        } else if h > 0 {
            return "\(h)h"
        } else {
            return "\(m)m"
        }
    }
}
