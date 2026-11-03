import Foundation
import SwiftData
import SwiftUI

public struct HeatmapDayData: Identifiable {
    public var id: Date { date }
    public let date: Date
    public let completedTasksCount: Int
    public let completedPomodoros: Int
    public let focusMinutes: Int
    public let taskTitles: [String]
    public let tier: Int
}

@Observable
@MainActor
public final class LifesaverStore {
    public let modelContext: ModelContext
    public var selectedDate: Date = Calendar.current.startOfDay(for: Date.now)
    public var selectedWeekStart: Date = Calendar.current.startOfDay(for: Date.now)
    public var activeTask: TaskItem?
    public var isInspectorPresented: Bool = true
    public var taskFilter: TaskFilter = .all
    public var showCelebration: Bool = false
    public var isBacklogPresented: Bool = true
    public var isRescueModePresented: Bool = false
    public var isDoneLogPresented: Bool = false
    public var isWeeklyReviewPresented: Bool = false
    public var rescueTargetTask: TaskItem?
    public var revision: Int = 0

    // MARK: - 3-Tier Goal Slider State
    public var selectedGoalTab: GoalItem.GoalType = .longTerm
    public var isNewGoalSheetPresented: Bool = false
    public var newGoalTargetType: GoalItem.GoalType = .longTerm

    public func notifyChange() {
        revision &+= 1
        try? modelContext.save()
    }

    public enum TaskFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case active = "Active"
        case completed = "Done"

        public var id: String { rawValue }
    }

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
        let today = Calendar.current.startOfDay(for: Date.now)
        self.selectedDate = today
        self.selectedWeekStart = Self.startOfWeek(for: today)
        let currentDay = fetchOrCreateDay(for: today)
        self.activeTask = currentDay.tasks?.first(where: { !$0.isCompleted })
        self.seedInitialGoalsIfNeeded()
    }

    public static func startOfWeek(for date: Date) -> Date {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday start
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let start = cal.date(from: comps) ?? date
        return Calendar.current.startOfDay(for: start)
    }

    public var currentDay: PlanDay {
        _ = revision
        return fetchOrCreateDay(for: selectedDate)
    }

    public var todayPlan: PlanDay {
        _ = revision
        return fetchOrCreateDay(for: Date.now)
    }

    public var currentWeek: PlanWeek {
        _ = revision
        return fetchOrCreateWeek(for: selectedWeekStart)
    }

    public var isSelectedDayToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    public var weekDays: [PlanDay] {
        _ = revision
        var days: [PlanDay] = []
        for i in 0..<7 {
            if let date = Calendar.current.date(byAdding: .day, value: i, to: selectedWeekStart) {
                days.append(fetchOrCreateDay(for: date))
            }
        }
        return days
    }

    public func fetchOrCreateDay(for date: Date) -> PlanDay {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        var descriptor = FetchDescriptor<PlanDay>(
            predicate: #Predicate<PlanDay> { day in
                day.date == normalizedDate
            }
        )
        descriptor.fetchLimit = 1

        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }

        let newDay = PlanDay(date: normalizedDate)
        modelContext.insert(newDay)
        try? modelContext.save()
        return newDay
    }

    public func fetchOrCreateWeek(for date: Date) -> PlanWeek {
        let weekStart = Self.startOfWeek(for: date)
        var descriptor = FetchDescriptor<PlanWeek>(
            predicate: #Predicate<PlanWeek> { week in
                week.weekStartDate == weekStart
            }
        )
        descriptor.fetchLimit = 1

        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }

        let newWeek = PlanWeek(weekStartDate: weekStart)
        modelContext.insert(newWeek)
        try? modelContext.save()
        return newWeek
    }

    public func goToNextWeek() {
        if let next = Calendar.current.date(byAdding: .day, value: 7, to: selectedWeekStart) {
            selectedWeekStart = Self.startOfWeek(for: next)
        }
    }

    public func goToPreviousWeek() {
        if let prev = Calendar.current.date(byAdding: .day, value: -7, to: selectedWeekStart) {
            selectedWeekStart = Self.startOfWeek(for: prev)
        }
    }

    public func goToCurrentWeek() {
        selectedWeekStart = Self.startOfWeek(for: Date.now)
    }

    public func addWeeklyGoal(goal: String) {
        let clean = goal.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        currentWeek.weeklyGoals.append(clean)
        notifyChange()
    }

    public func removeWeeklyGoal(at index: Int) {
        guard index >= 0 && index < currentWeek.weeklyGoals.count else { return }
        currentWeek.weeklyGoals.remove(at: index)
        notifyChange()
    }

    public func updateDontForgetNotes(_ notes: String) {
        currentWeek.dontForgetNotes = notes
        notifyChange()
    }

    public func addMustDoItem(_ title: String) {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        currentWeek.mustDoItems.append(clean)
        notifyChange()
    }

    public func toggleMustDoItem(_ title: String) {
        if currentWeek.mustDoDone.contains(title) {
            currentWeek.mustDoDone.removeAll(where: { item in item == title })
        } else {
            currentWeek.mustDoDone.append(title)
        }
        notifyChange()
    }

    public func removeMustDoItem(at index: Int) {
        guard index >= 0 && index < currentWeek.mustDoItems.count else { return }
        let title = currentWeek.mustDoItems[index]
        currentWeek.mustDoItems.remove(at: index)
        currentWeek.mustDoDone.removeAll(where: { item in item == title })
        notifyChange()
    }

    public func addNextWeekItem(_ title: String) {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        currentWeek.nextWeekItems.append(clean)
        notifyChange()
    }

    public func removeNextWeekItem(at index: Int) {
        guard index >= 0 && index < currentWeek.nextWeekItems.count else { return }
        currentWeek.nextWeekItems.remove(at: index)
        notifyChange()
    }

    public func addBacklogTask(title: String) {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        let week = currentWeek
        let task = TaskItem(title: clean, planWeek: week)
        modelContext.insert(task)
        if week.backlogTasks == nil {
            week.backlogTasks = []
        }
        week.backlogTasks?.append(task)
        notifyChange()
    }

    public func assignBacklogTask(_ task: TaskItem, to day: PlanDay) {
        currentWeek.backlogTasks?.removeAll(where: { $0.id == task.id })
        task.planWeek = nil
        task.planDay = day
        if day.tasks == nil {
            day.tasks = []
        }
        day.tasks?.append(task)
        notifyChange()
    }

    public func moveTaskToBacklog(_ task: TaskItem) {
        task.planDay?.tasks?.removeAll(where: { $0.id == task.id })
        task.planDay = nil
        task.planWeek = currentWeek
        if currentWeek.backlogTasks == nil {
            currentWeek.backlogTasks = []
        }
        currentWeek.backlogTasks?.append(task)
        notifyChange()
    }

    public func goToNextDay() {
        if let next = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
            selectedDate = Calendar.current.startOfDay(for: next)
        }
    }

    public func goToPreviousDay() {
        if let prev = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
            selectedDate = Calendar.current.startOfDay(for: prev)
        }
    }

    public func goToToday() {
        selectedDate = Calendar.current.startOfDay(for: Date.now)
    }

    public func addTask(
        title: String,
        to day: PlanDay? = nil,
        priority: Int = 1,
        estimatedPomodoros: Int = 1,
        scheduledTime: Date? = nil,
        durationMinutes: Int = 30,
        recurrenceRule: TaskItem.RecurrenceRule = .never
    ) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }

        let targetDay = day ?? currentDay
        let nextOrder = (targetDay.tasks?.map(\.orderIndex).max() ?? 0) + 1

        let initialTime: Date
        if let explicit = scheduledTime {
            initialTime = explicit
        } else {
            let cal = Calendar.current
            let nowComps = cal.dateComponents([.hour, .minute, .second], from: Date.now)
            var targetComps = cal.dateComponents([.year, .month, .day], from: targetDay.date)
            targetComps.hour = nowComps.hour
            targetComps.minute = nowComps.minute
            targetComps.second = 0
            initialTime = cal.date(from: targetComps) ?? Date.now
        }

        let task = TaskItem(
            title: cleanTitle,
            priorityRaw: priority,
            estimatedPomodoros: estimatedPomodoros,
            scheduledTime: initialTime,
            durationMinutes: durationMinutes,
            orderIndex: nextOrder,
            recurrenceRaw: recurrenceRule.rawValue,
            planDay: targetDay
        )
        modelContext.insert(task)
        if targetDay.tasks == nil {
            targetDay.tasks = []
        }
        targetDay.tasks?.append(task)
        NotificationManager.shared.scheduleTaskReminder(for: task)
        if activeTask == nil {
            activeTask = task
        }

        // Structured Pro: Propagate across upcoming days if set to repeat
        if recurrenceRule != .never {
            propagateRecurrence(for: task, rule: recurrenceRule, from: targetDay.date)
        }

        notifyChange()
    }

    public func updateTaskTiming(
        _ task: TaskItem,
        newStartTime: Date,
        newDurationMinutes: Int,
        recurrenceRule: TaskItem.RecurrenceRule? = nil
    ) {
        task.scheduledTime = newStartTime
        task.durationMinutes = max(5, newDurationMinutes)
        if let newRule = recurrenceRule {
            task.recurrenceRule = newRule
            if newRule != .never {
                propagateRecurrence(for: task, rule: newRule, from: task.effectiveStartTime)
            }
        }
        NotificationManager.shared.scheduleTaskReminder(for: task)
        notifyChange()
    }

    public func propagateRecurrence(for task: TaskItem, rule: TaskItem.RecurrenceRule, from startDate: Date, daysAhead: Int = 28) {
        task.recurrenceRule = rule
        let parentId = task.recurrenceParentId ?? task.id
        task.recurrenceParentId = parentId

        guard rule != .never else { return }

        let cal = Calendar.current
        let hour = cal.component(.hour, from: task.effectiveStartTime)
        let minute = cal.component(.minute, from: task.effectiveStartTime)
        let baseWeekday = cal.component(.weekday, from: task.effectiveStartTime)

        for dayOffset in 1...daysAhead {
            guard let nextDate = cal.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
            let weekday = cal.component(.weekday, from: nextDate)

            let shouldInclude: Bool
            switch rule {
            case .never:
                shouldInclude = false
            case .daily:
                shouldInclude = true
            case .weekdays:
                shouldInclude = (weekday >= 2 && weekday <= 6)
            case .weekends:
                shouldInclude = (weekday == 1 || weekday == 7)
            case .weekly:
                shouldInclude = (weekday == baseWeekday)
            }

            guard shouldInclude else { continue }

            let futureDay = fetchOrCreateDay(for: nextDate)
            let existingTasks = futureDay.tasks ?? []
            if !existingTasks.contains(where: { item in item.recurrenceParentId == parentId }) {
                var targetComps = cal.dateComponents([.year, .month, .day], from: nextDate)
                targetComps.hour = hour
                targetComps.minute = minute
                targetComps.second = 0
                let scheduledForDay = cal.date(from: targetComps) ?? nextDate

                let copy = TaskItem(
                    title: task.title,
                    notes: task.notes,
                    priorityRaw: task.priorityRaw,
                    estimatedPomodoros: task.estimatedPomodoros,
                    scheduledTime: scheduledForDay,
                    durationMinutes: task.durationMinutes,
                    orderIndex: (futureDay.tasks?.map(\.orderIndex).max() ?? 0) + 1,
                    recurrenceRaw: rule.rawValue,
                    recurrenceParentId: parentId,
                    planDay: futureDay
                )
                modelContext.insert(copy)
                if futureDay.tasks == nil {
                    futureDay.tasks = []
                }
                futureDay.tasks?.append(copy)
            }
        }
    }

    public func toggleTaskCompletion(_ task: TaskItem) {
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? Date.now : nil
        if task.isCompleted {
            NotificationManager.shared.cancelTaskReminder(for: task)
            NotificationManager.shared.showToast(
                title: "Task Done",
                message: task.title,
                icon: "checkmark.circle.fill",
                color: Color.green
            )
        } else {
            NotificationManager.shared.scheduleTaskReminder(for: task)
        }
        notifyChange()
        StreakManager.shared.recalculate(store: self)

        let dayTasks = currentDay.tasks ?? []
        if !dayTasks.isEmpty && dayTasks.allSatisfy({ $0.isCompleted }) {
            triggerMilestoneCelebration()
        }
    }

    public func triggerMilestoneCelebration() {
        showCelebration = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            showCelebration = false
        }
    }

    public func deleteTask(_ task: TaskItem) {
        if activeTask?.id == task.id {
            activeTask = nil
        }
        task.planDay?.tasks?.removeAll(where: { $0.id == task.id })
        task.planWeek?.backlogTasks?.removeAll(where: { $0.id == task.id })
        task.goal?.tasks?.removeAll(where: { $0.id == task.id })
        NotificationManager.shared.cancelTaskReminder(for: task)
        modelContext.delete(task)
        notifyChange()
    }

    public func postponeTaskToTomorrow(_ task: TaskItem) {
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) else { return }
        let nextDay = fetchOrCreateDay(for: tomorrow)
        task.planDay = nextDay
        if nextDay.tasks == nil {
            nextDay.tasks = []
        }
        nextDay.tasks?.append(task)
        currentDay.tasks?.removeAll(where: { $0.id == task.id })
        notifyChange()
    }

    public func updateTaskPriority(_ task: TaskItem, priority: Int) {
        task.priorityRaw = priority
        notifyChange()
    }

    public func updateTaskPomodoros(_ task: TaskItem, estimated: Int) {
        task.estimatedPomodoros = max(1, min(8, estimated))
        notifyChange()
    }

    public func selectTaskForTimer(_ task: TaskItem) {
        activeTask = task
        if !isInspectorPresented {
            isInspectorPresented = true
        }
    }

    public func logPomodoroSession(seconds: Int, mode: String, completed: Bool) {
        let session = PomodoroSession(
            durationSeconds: seconds,
            modeRaw: mode,
            wasCompleted: completed,
            task: activeTask
        )
        session.endedAt = Date.now
        modelContext.insert(session)

        if completed, mode == "work", let task = activeTask {
            task.completedPomodoros += 1
        }
        notifyChange()
    }

    public func saveReflectionNotes(for day: PlanDay, notes: String) {
        day.reflectionNotes = notes
        notifyChange()
    }

    
    // MARK: - Part 1: Anti-Drop-Off & Habit Anchor Methods
    public var yesterdayUnfinishedTasks: [TaskItem] {
        _ = revision
        guard isSelectedDayToday, !currentDay.hasHandledRollover else { return [] }
        guard let yesterdayDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) else { return [] }
        let normYesterday = Calendar.current.startOfDay(for: yesterdayDate)
        let allDays = (try? modelContext.fetch(FetchDescriptor<PlanDay>())) ?? []
        guard let yDay = allDays.first(where: { d in Calendar.current.isDate(d.date, inSameDayAs: normYesterday) }) else { return [] }
        return (yDay.tasks ?? []).filter { t in !t.isCompleted }
    }

    public func setMustWinTask(_ task: TaskItem?) {
        currentDay.mustWinTaskId = task?.id
        notifyChange()
        if let task {
            NotificationManager.shared.showToast(
                title: "Anchor Set! 🎯",
                message: "'\(task.title)' is your #1 priority today.",
                icon: "target",
                color: Color.orange
            )
        }
    }

    public func rolloverYesterdayTasks(action: RolloverAction) {
        let tasks = yesterdayUnfinishedTasks
        currentDay.hasHandledRollover = true

        switch action {
        case .moveToToday:
            for task in tasks {
                task.planDay?.tasks?.removeAll(where: { t in t.id == task.id })
                task.planDay = currentDay
                task.scheduledTime = Date.now
                if currentDay.tasks == nil { currentDay.tasks = [] }
                currentDay.tasks?.append(task)
            }
            NotificationManager.shared.showToast(
                title: "Rolled Over ☀️",
                message: "Moved \(tasks.count) unfinished task\(tasks.count > 1 ? "s" : "") to Today.",
                icon: "arrow.right.circle.fill",
                color: Color.accentColor
            )

        case .moveToInbox:
            for task in tasks {
                moveTaskToBacklog(task)
            }
            NotificationManager.shared.showToast(
                title: "Saved to Inbox 📥",
                message: "Moved \(tasks.count) task\(tasks.count > 1 ? "s" : "") to your backlog. Clean slate today!",
                icon: "tray.and.arrow.down.fill",
                color: Color.blue
            )

        case .discard:
            NotificationManager.shared.showToast(
                title: "Fresh Start ✨",
                message: "Yesterday is in the past. Focus on today!",
                icon: "sparkles",
                color: Color.green
            )
        }

        notifyChange()
    }

    
    
    // MARK: - Part 3: "I Did This" Spontaneous Accomplishment Done Log
    public func logAccomplishment(
        title: String,
        durationMinutes: Int = 30,
        priorityRaw: Int = 1,
        finishedAt: Date = Date.now,
        notes: String? = nil
    ) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }

        let targetDay = currentDay
        let nextOrder = (targetDay.tasks?.map(\.orderIndex).max() ?? 0) + 1
        let startTime = Calendar.current.date(byAdding: .minute, value: -max(5, durationMinutes), to: finishedAt) ?? finishedAt

        let task = TaskItem(
            title: cleanTitle,
            notes: notes,
            priorityRaw: priorityRaw,
            estimatedPomodoros: max(1, durationMinutes / 25),
            scheduledTime: startTime,
            durationMinutes: durationMinutes,
            orderIndex: nextOrder,
            planDay: targetDay
        )
        task.isCompleted = true
        task.isLoggedWin = true
        task.completedAt = finishedAt
        task.completedPomodoros = max(1, durationMinutes / 25)

        modelContext.insert(task)
        if targetDay.tasks == nil {
            targetDay.tasks = []
        }
        targetDay.tasks?.append(task)

        let session = PomodoroSession(
            durationSeconds: durationMinutes * 60,
            modeRaw: "work",
            wasCompleted: true,
            task: task
        )
        session.startedAt = startTime
        session.endedAt = finishedAt
        modelContext.insert(session)

        try? modelContext.save()
        notifyChange()

        NotificationManager.shared.showToast(
            title: "Win Logged! 🏆",
            message: "'\(cleanTitle)' (\(durationMinutes)m) credited to today's wins.",
            icon: "sparkles",
            color: Color.green
        )
    }

    // MARK: - Part 2: Rescue Mode & Low-Energy Demotivation Lifelines
    public var isLowEnergyMode: Bool {
        get { currentDay.isLowEnergyMode }
        set {
            currentDay.isLowEnergyMode = newValue
            notifyChange()
        }
    }

    public func toggleLowEnergyMode() {
        isLowEnergyMode.toggle()
        if isLowEnergyMode {
            NotificationManager.shared.showToast(
                title: "Gentle Day Active 🔋",
                message: "Non-essential tasks deferred. Focus on just ONE priority with zero guilt.",
                icon: "leaf.fill",
                color: Color.teal
            )
        } else {
            NotificationManager.shared.showToast(
                title: "Normal Mode Resumed ☀️",
                message: "Full day schedule restored.",
                icon: "sun.max.fill",
                color: Color.orange
            )
        }
    }

    public func launchRescueMode(for task: TaskItem? = nil) {
        self.rescueTargetTask = task ?? currentDay.mustWinTask ?? (currentDay.tasks ?? []).first(where: { !$0.isCompleted })
        self.isRescueModePresented = true
    }

    public func logRescueSession(task: TaskItem?, durationSeconds: Int = 300) {
        let session = PomodoroSession(
            durationSeconds: durationSeconds,
            modeRaw: "rescue",
            wasCompleted: true,
            task: task
        )
        modelContext.insert(session)
        try? modelContext.save()

        NotificationManager.shared.showToast(
            title: "Freeze Broken! ⚡️",
            message: "5 minutes completed despite the resistance. That takes real courage!",
            icon: "sparkles",
            color: Color.orange
        )
        notifyChange()
    }

    public enum RolloverAction {
        case moveToToday
        case moveToInbox
        case discard
    }

    // MARK: - Heatmap & Analytics Queries
    public func fetchHeatmapData(weeksCount: Int = 24) -> [[HeatmapDayData]] {
        _ = revision
        let today = Calendar.current.startOfDay(for: Date.now)
        let currentWeekMonday = Self.startOfWeek(for: today)
        guard let startMonday = Calendar.current.date(byAdding: .day, value: -(weeksCount - 1) * 7, to: currentWeekMonday) else {
            return []
        }

        let allDays = (try? modelContext.fetch(FetchDescriptor<PlanDay>())) ?? []
        let dayLookup = Dictionary(uniqueKeysWithValues: allDays.map { ($0.date, $0) })

        var grid: [[HeatmapDayData]] = []
        for weekIdx in 0..<weeksCount {
            var weekCols: [HeatmapDayData] = []
            guard let weekStart = Calendar.current.date(byAdding: .day, value: weekIdx * 7, to: startMonday) else { continue }
            for dayIdx in 0..<7 {
                guard let cellDate = Calendar.current.date(byAdding: .day, value: dayIdx, to: weekStart) else { continue }
                let normalized = Calendar.current.startOfDay(for: cellDate)
                let day = dayLookup[normalized]
                let completedTasks = day?.tasks?.filter { $0.isCompleted } ?? []
                let completedCount = completedTasks.count
                let pomodoroCount = completedTasks.reduce(0) { $0 + $1.completedPomodoros }
                let focusMins = pomodoroCount * 25
                let score = (completedCount * 2) + pomodoroCount

                let tier: Int
                switch score {
                case 1...2: tier = 1
                case 3...5: tier = 2
                case 6...9: tier = 3
                case 10...: tier = 4
                default: tier = 0
                }

                weekCols.append(
                    HeatmapDayData(
                        date: normalized,
                        completedTasksCount: completedCount,
                        completedPomodoros: pomodoroCount,
                        focusMinutes: focusMins,
                        taskTitles: completedTasks.map(\.title),
                        tier: tier
                    )
                )
            }
            grid.append(weekCols)
        }
        return grid
    }

    public var totalTasksCompletedAllTime: Int {
        _ = revision
        let allTasks = (try? modelContext.fetch(FetchDescriptor<TaskItem>())) ?? []
        return allTasks.filter { $0.isCompleted }.count
    }

    public var totalFocusMinutesAllTime: Int {
        _ = revision
        let allSessions = (try? modelContext.fetch(FetchDescriptor<PomodoroSession>())) ?? []
        let completedWorkSessions = allSessions.filter { $0.wasCompleted && $0.modeRaw == "work" }
        return completedWorkSessions.reduce(0) { $0 + ($1.durationSeconds / 60) }
    }

    public var currentStreakDays: Int {
        _ = revision
        let today = Calendar.current.startOfDay(for: Date.now)
        var streak = 0
        var checkDate = today

        let allDays = (try? modelContext.fetch(FetchDescriptor<PlanDay>())) ?? []
        let dayLookup = Dictionary(uniqueKeysWithValues: allDays.map { ($0.date, $0) })

        while true {
            guard let day = dayLookup[checkDate] else { break }
            let completedCount = day.tasks?.filter { $0.isCompleted }.count ?? 0
            if completedCount > 0 {
                streak += 1
                guard let prev = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = Calendar.current.startOfDay(for: prev)
            } else {
                // If checking today and nothing done yet, give grace and check yesterday
                if checkDate == today {
                    guard let prev = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) else { break }
                    checkDate = Calendar.current.startOfDay(for: prev)
                    continue
                }
                break
            }
        }
        return streak
    }

    
    // MARK: - Part 4: Weekly Review & Monthly Trajectory
    public var currentWeekCompletedTasksCount: Int {
        _ = revision
        return weekDays.flatMap { $0.tasks ?? [] }.filter { $0.isCompleted }.count
    }

    public var currentWeekTotalTasksCount: Int {
        _ = revision
        return weekDays.flatMap { $0.tasks ?? [] }.count
    }

    public var currentWeekFocusMinutes: Int {
        _ = revision
        let allSessions = (try? modelContext.fetch(FetchDescriptor<PomodoroSession>())) ?? []
        let cal = Calendar.current
        let start = selectedWeekStart
        let end = cal.date(byAdding: .day, value: 7, to: start) ?? start
        return allSessions.filter {
            $0.wasCompleted &&
            $0.startedAt >= start &&
            $0.startedAt < end
        }.reduce(0) { $0 + ($1.durationSeconds / 60) }
    }

    public var currentWeekMostProductiveDay: (name: String, minutes: Int) {
        _ = revision
        var bestName = "None"
        var bestMins = 0
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"

        for day in weekDays {
            let daySessions = (day.tasks ?? []).flatMap { $0.sessions ?? [] }
            let mins = daySessions.filter { $0.wasCompleted }.reduce(0) { $0 + ($1.durationSeconds / 60) }
            if mins >= bestMins && mins > 0 {
                bestMins = mins
                bestName = formatter.string(from: day.date)
            }
        }
        if bestMins == 0, let firstActive = weekDays.first(where: { ($0.tasks?.filter { $0.isCompleted }.count ?? 0) > 0 }) {
            bestName = formatter.string(from: firstActive.date)
            bestMins = (firstActive.tasks?.filter { $0.isCompleted }.count ?? 0) * 25
        }
        return (bestName, max(bestMins, 25))
    }

    public func saveWeeklyReview(
        wins: String,
        drainers: String,
        nextFocus: String
    ) {
        let week = currentWeek
        week.reviewWinsNote = wins
        week.reviewDrainersNote = drainers
        week.reviewNextFocusNote = nextFocus
        week.isReviewCompleted = true

        if !nextFocus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if !week.nextWeekItems.contains(nextFocus) {
                week.nextWeekItems.append(nextFocus)
            }
        }

        try? modelContext.save()
        notifyChange()

        NotificationManager.shared.showToast(
            title: "Weekly Review Saved! 🌟",
            message: "Reflections logged. Next week focus is primed!",
            icon: "trophy.fill",
            color: Color.orange
        )
    }

    public var pastWeeklyReviews: [PlanWeek] {
        _ = revision
        let allWeeks = (try? modelContext.fetch(FetchDescriptor<PlanWeek>())) ?? []
        return allWeeks
            .filter { $0.isReviewCompleted || !$0.reviewWinsNote.isEmpty || !$0.dontForgetNotes.isEmpty }
            .sorted(by: { $0.weekStartDate > $1.weekStartDate })
    }

    public var currentMonthFocusMinutes: Int {
        _ = revision
        let allSessions = (try? modelContext.fetch(FetchDescriptor<PomodoroSession>())) ?? []
        let cal = Calendar.current
        let now = Date.now
        return allSessions.filter {
            $0.wasCompleted &&
            cal.isDate($0.startedAt, equalTo: now, toGranularity: .month)
        }.reduce(0) { $0 + ($1.durationSeconds / 60) }
    }

    public var previousMonthFocusMinutes: Int {
        _ = revision
        let allSessions = (try? modelContext.fetch(FetchDescriptor<PomodoroSession>())) ?? []
        let cal = Calendar.current
        guard let lastMonth = cal.date(byAdding: .month, value: -1, to: Date.now) else { return 0 }
        return allSessions.filter {
            $0.wasCompleted &&
            cal.isDate($0.startedAt, equalTo: lastMonth, toGranularity: .month)
        }.reduce(0) { $0 + ($1.durationSeconds / 60) }
    }

    public static func makePreviewContainer() -> ModelContainer {
        let schema = Schema([
            TaskItem.self,
            PlanDay.self,
            PlanWeek.self,
            PomodoroSession.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = container.mainContext

            let today = PlanDay(date: Date.now)
            context.insert(today)

            let sample1 = TaskItem(
                title: "Architect SwiftData models for CloudKit sync",
                priorityRaw: 2,
                estimatedPomodoros: 2,
                orderIndex: 1,
                planDay: today
            )
            sample1.isCompleted = true
            sample1.completedPomodoros = 2

            let sample2 = TaskItem(
                title: "Build fluid NavigationSplitView app shell",
                priorityRaw: 2,
                estimatedPomodoros: 2,
                orderIndex: 2,
                planDay: today
            )
            sample2.completedPomodoros = 1

            let sample3 = TaskItem(
                title: "Design tactile spring micro-interactions",
                priorityRaw: 1,
                estimatedPomodoros: 3,
                orderIndex: 3,
                planDay: today
            )

            context.insert(sample1)
            context.insert(sample2)
            context.insert(sample3)
            today.tasks = [sample1, sample2, sample3]
            try? context.save()
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
}
