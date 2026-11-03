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
}
