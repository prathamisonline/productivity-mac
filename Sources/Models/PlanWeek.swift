import Foundation
import SwiftData

@Model
public final class PlanWeek: Identifiable {
    public var id: UUID = UUID()
    public var weekStartDate: Date = Date.now
    public var weeklyGoals: [String] = []
    
    // Physical Week Planner Board Features (Image 1)
    public var dontForgetNotes: String = ""
    public var mustDoItems: [String] = []
    public var mustDoDone: [String] = []
    public var nextWeekItems: [String] = []

    // Part 4: Sunday Weekly Review Ritual
    public var reviewWinsNote: String = ""
    public var reviewDrainersNote: String = ""
    public var reviewNextFocusNote: String = ""
    public var isReviewCompleted: Bool = false

    @Relationship(deleteRule: .nullify, inverse: \PlanDay.planWeek) public var days: [PlanDay]? = []
    @Relationship(deleteRule: .nullify, inverse: \TaskItem.planWeek) public var backlogTasks: [TaskItem]? = []

    public init(
        weekStartDate: Date = Date.now,
        weeklyGoals: [String] = [],
        dontForgetNotes: String = "",
        mustDoItems: [String] = [],
        mustDoDone: [String] = [],
        nextWeekItems: [String] = []
    ) {
        self.id = UUID()
        self.weekStartDate = Calendar.current.startOfDay(for: weekStartDate)
        self.weeklyGoals = weeklyGoals
        self.dontForgetNotes = dontForgetNotes
        self.mustDoItems = mustDoItems
        self.mustDoDone = mustDoDone
        self.nextWeekItems = nextWeekItems
        self.days = []
        self.backlogTasks = []
    }
}
