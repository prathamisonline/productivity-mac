import Foundation
import SwiftData
import SwiftUI

extension LifesaverStore {
    // MARK: - Goals Management

    public func fetchGoals(for type: GoalItem.GoalType) -> [GoalItem] {
        _ = revision
        let typeRaw = type.rawValue
        let descriptor = FetchDescriptor<GoalItem>(
            predicate: #Predicate<GoalItem> { $0.goalTypeRaw == typeRaw },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        let results = (try? modelContext.fetch(descriptor)) ?? []
        return results.sorted {
            if $0.isCompleted != $1.isCompleted {
                return !$0.isCompleted // Incomplete goals first
            }
            return $0.createdAt < $1.createdAt
        }
    }

    public var allLongTermGoals: [GoalItem] {
        fetchGoals(for: .longTerm)
    }

    public var allShortTermGoals: [GoalItem] {
        fetchGoals(for: .shortTerm)
    }

    public var allDailyGoals: [GoalItem] {
        fetchGoals(for: .daily)
    }

    @discardableResult
    public func createGoal(
        title: String,
        notes: String? = nil,
        type: GoalItem.GoalType,
        targetDate: Date? = nil,
        targetDateText: String? = nil,
        accentColorHex: String = "#EE7E75",
        iconName: String = "target"
    ) -> GoalItem {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let goal = GoalItem(
            title: trimmedTitle.isEmpty ? "Untitled Goal" : trimmedTitle,
            notes: notes,
            goalType: type,
            targetDate: targetDate,
            targetDateText: targetDateText,
            accentColorHex: accentColorHex,
            iconName: iconName
        )
        modelContext.insert(goal)
        notifyChange()
        return goal
    }

    public func updateGoal(
        _ goal: GoalItem,
        title: String,
        notes: String?,
        type: GoalItem.GoalType,
        targetDate: Date? = nil,
        targetDateText: String?,
        accentColorHex: String,
        iconName: String
    ) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        goal.title = trimmedTitle.isEmpty ? "Untitled Goal" : trimmedTitle
        goal.notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true ? nil : notes
        goal.goalType = type
        goal.targetDate = targetDate
        goal.targetDateText = targetDateText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true ? nil : targetDateText
        goal.accentColorHex = accentColorHex
        goal.iconName = iconName
        notifyChange()
    }

    public func deleteGoal(_ goal: GoalItem) {
        modelContext.delete(goal)
        notifyChange()
    }

    public func toggleGoal(_ goal: GoalItem) {
        goal.isCompleted.toggle()
        goal.completedAt = goal.isCompleted ? Date.now : nil
        notifyChange()
        StreakManager.shared.recalculate(store: self)
    }

    // MARK: - Tasks Management for Goals

    @discardableResult
    public func addTask(
        title: String,
        to goal: GoalItem?,
        scope: TaskItem.TaskScope
    ) -> TaskItem {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let task = TaskItem(
            title: trimmedTitle.isEmpty ? "Untitled Task" : trimmedTitle,
            taskScope: scope,
            goal: goal,
            planDay: currentDay
        )
        modelContext.insert(task)
        if let goal {
            if goal.tasks == nil {
                goal.tasks = []
            }
            goal.tasks?.append(task)
        }
        notifyChange()
        return task
    }

    public func toggleTask(_ task: TaskItem) {
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? Date.now : nil
        notifyChange()
        StreakManager.shared.recalculate(store: self)
    }



    // MARK: - Daily Tasks Aggregation

    public func allDailyTasks() -> [TaskItem] {
        _ = revision
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { $0.taskScopeRaw == "daily" },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        let results = (try? modelContext.fetch(descriptor)) ?? []
        return results.sorted {
            if $0.isCompleted != $1.isCompleted {
                return !$0.isCompleted
            }
            return $0.createdAt < $1.createdAt
        }
    }

    public var dailyTasksFromShortTermGoals: [TaskItem] {
        _ = revision
        let shortTermGoals = allShortTermGoals
        return shortTermGoals.flatMap { $0.dailyTasks }
    }

    public var standaloneDailyTasks: [TaskItem] {
        _ = revision
        return allDailyTasks().filter { $0.goal == nil }
    }

    // MARK: - Navigation Slider Helpers

    public func slideNextTab() {
        switch selectedGoalTab {
        case .longTerm:
            selectedGoalTab = .shortTerm
        case .shortTerm:
            selectedGoalTab = .daily
        case .daily:
            break
        }
    }

    public func slidePrevTab() {
        switch selectedGoalTab {
        case .daily:
            selectedGoalTab = .shortTerm
        case .shortTerm:
            selectedGoalTab = .longTerm
        case .longTerm:
            break
        }
    }

    // MARK: - Seed Initial Sample Data

    public func seedInitialGoalsIfNeeded() {
        let descriptor = FetchDescriptor<GoalItem>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        // 1. Long Term Goal: Macro Vision
        let ltGoal = GoalItem(
            title: "Build & Scale World-Class Indie Products",
            notes: "Design, build, and ship impactful software used by millions.",
            goalType: .longTerm,
            targetDateText: "3-Year Horizon (2027)",
            accentColorHex: "#EE7E75",
            iconName: "target"
        )
        modelContext.insert(ltGoal)

        let ltTask1 = TaskItem(title: "Architect and ship Lifesaver Goal Execution Engine", taskScope: .longTerm, goal: ltGoal)
        let ltTask2 = TaskItem(title: "Reach $10k monthly recurring revenue across apps", taskScope: .longTerm, goal: ltGoal)
        let ltTask3 = TaskItem(title: "Build community of 10,000+ disciplined daily builders", taskScope: .longTerm, goal: ltGoal)
        modelContext.insert(ltTask1)
        modelContext.insert(ltTask2)
        modelContext.insert(ltTask3)
        ltGoal.tasks = [ltTask1, ltTask2, ltTask3]

        // 2. Short Term Goal: Tactical Sprint
        let stGoal = GoalItem(
            title: "Ship Lifesaver v2 Left-to-Right Flow",
            notes: "Transform UX into a distraction-free 3-tier horizontal slider.",
            goalType: .shortTerm,
            targetDateText: "This Month",
            accentColorHex: "#38BDF8",
            iconName: "bolt.fill"
        )
        modelContext.insert(stGoal)

        let stTask1 = TaskItem(title: "Remove sidebar and right-side timer inspectors", taskScope: .shortTerm, goal: stGoal)
        let stTask2 = TaskItem(title: "Design top-center sliding capsule navigation", taskScope: .shortTerm, goal: stGoal)
        let stDaily1 = TaskItem(title: "Implement smooth horizontal slide container", taskScope: .daily, goal: stGoal)
        let stDaily2 = TaskItem(title: "Add keyboard arrow shortcuts (⌘← and ⌘→)", taskScope: .daily, goal: stGoal)
        modelContext.insert(stTask1)
        modelContext.insert(stTask2)
        modelContext.insert(stDaily1)
        modelContext.insert(stDaily2)
        stGoal.tasks = [stTask1, stTask2, stDaily1, stDaily2]

        // 3. Daily Goal: Today's Action
        let dGoal = GoalItem(
            title: "Execute Today's Deep Focus Objectives",
            notes: "Complete core milestones and verify contrast across all modes.",
            goalType: .daily,
            targetDateText: "Today",
            accentColorHex: "#34D399",
            iconName: "sun.max.fill"
        )
        modelContext.insert(dGoal)

        let dTask1 = TaskItem(title: "Test adding long-term tasks to long-term goals", taskScope: .daily, goal: dGoal)
        let dTask2 = TaskItem(title: "Test adding short-term and daily tasks to short-term goals", taskScope: .daily, goal: dGoal)
        let dTask3 = TaskItem(title: "Confirm zero clipping and ultra-fast fluid sliding", taskScope: .daily, goal: dGoal)
        modelContext.insert(dTask1)
        modelContext.insert(dTask2)
        modelContext.insert(dTask3)
        dGoal.tasks = [dTask1, dTask2, dTask3]

        try? modelContext.save()
    }
}
