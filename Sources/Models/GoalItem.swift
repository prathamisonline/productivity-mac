import Foundation
import SwiftData

@Model
public final class GoalItem: Identifiable {
    public var id: UUID = UUID()
    public var title: String = ""
    public var notes: String?
    public var goalTypeRaw: String = "longTerm" // "longTerm", "shortTerm", "daily"
    public var isCompleted: Bool = false
    public var targetDate: Date?
    public var targetDateText: String? // e.g. "2027", "Next 2 Weeks", "Today"
    public var createdAt: Date = Date.now
    public var completedAt: Date?
    public var orderIndex: Int = 0
    public var accentColorHex: String = "#EE7E75"
    public var iconName: String = "target"

    @Relationship(deleteRule: .cascade, inverse: \TaskItem.goal)
    public var tasks: [TaskItem]? = []

    public enum GoalType: String, CaseIterable, Identifiable {
        case longTerm = "longTerm"
        case shortTerm = "shortTerm"
        case daily = "daily"

        public var id: String { rawValue }

        public var displayName: String {
            switch self {
            case .longTerm: return "Long-Term Goals"
            case .shortTerm: return "Short-Term Goals"
            case .daily: return "Daily Goals"
            }
        }

        public var shortName: String {
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
            case .daily: return "calendar"
            }
        }

        public var subtitle: String {
            switch self {
            case .longTerm: return "Macro vision & long-term tasks to achieve them"
            case .shortTerm: return "Tactical goals with short-term and daily tasks"
            case .daily: return "Today's focal outcomes & actionable tasks"
            }
        }
    }

    public var goalType: GoalType {
        get { GoalType(rawValue: goalTypeRaw) ?? .longTerm }
        set { goalTypeRaw = newValue.rawValue }
    }

    public init(
        title: String,
        notes: String? = nil,
        goalType: GoalType = .longTerm,
        targetDate: Date? = nil,
        targetDateText: String? = nil,
        accentColorHex: String = "#EE7E75",
        iconName: String = "target",
        orderIndex: Int = 0
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.goalTypeRaw = goalType.rawValue
        self.isCompleted = false
        self.targetDate = targetDate
        self.targetDateText = targetDateText
        self.createdAt = Date.now
        self.completedAt = nil
        self.accentColorHex = accentColorHex
        self.iconName = iconName
        self.orderIndex = orderIndex
        self.tasks = []
    }

    public var sortedTasks: [TaskItem] {
        tasks?.sorted(by: {
            if $0.isCompleted != $1.isCompleted {
                return !$0.isCompleted // Incomplete tasks first
            }
            return $0.createdAt < $1.createdAt
        }) ?? []
    }

    public var longTermTasks: [TaskItem] {
        sortedTasks.filter { $0.taskScope == .longTerm }
    }

    public var shortTermTasks: [TaskItem] {
        sortedTasks.filter { $0.taskScope == .shortTerm }
    }

    public var dailyTasks: [TaskItem] {
        sortedTasks.filter { $0.taskScope == .daily }
    }

    public var totalTasksCount: Int {
        tasks?.count ?? 0
    }

    public var completedTasksCount: Int {
        tasks?.filter { $0.isCompleted }.count ?? 0
    }

    public var progress: Double {
        guard totalTasksCount > 0 else {
            return isCompleted ? 1.0 : 0.0
        }
        return Double(completedTasksCount) / Double(totalTasksCount)
    }

    public var progressPercentageString: String {
        "\(Int(progress * 100))%"
    }
}

