import Foundation
import SwiftData
import SwiftUI

public struct SyncPayload: Codable {
    public let version: Int
    public let exportedAt: Date
    public let goals: [SyncGoal]?
    public let tasks: [SyncTask]
    public let days: [SyncDay]
    public let weeklyGoals: [String]?

    public struct SyncGoal: Codable, Identifiable {
        public let id: UUID
        public let title: String
        public let notes: String?
        public let goalTypeRaw: String
        public let isCompleted: Bool
        public let targetDate: Date?
        public let targetDateText: String?
        public let accentColorHex: String
        public let iconName: String
        public let orderIndex: Int
        public let createdAt: Date
        public let completedAt: Date?
    }

    public struct SyncTask: Codable, Identifiable {
        public let id: UUID
        public let title: String
        public let notes: String?
        public let isCompleted: Bool
        public let priorityRaw: Int
        public let estimatedPomodoros: Int
        public let completedPomodoros: Int
        public let createdAt: Date
        public let completedAt: Date?
        public let orderIndex: Int
        public let taskScopeRaw: String?
        public let goalId: UUID?
        public let dayDate: Date?
    }

    public struct SyncDay: Codable, Identifiable {
        public var id: Date { date }
        public let date: Date
        public let reflectionNotes: String
    }
}

@Observable
@MainActor
public final class iCloudDriveSyncManager {
    public static let shared = iCloudDriveSyncManager()
    public var lastSyncDate: Date?
    public var syncStatusMessage: String = "Ready to sync"
    public var isSyncing: Bool = false

    private init() {}

    public func generatePayload(store: LifesaverStore) -> SyncPayload {
        let allGoals = (try? store.modelContext.fetch(FetchDescriptor<GoalItem>())) ?? []
        let allTasks = (try? store.modelContext.fetch(FetchDescriptor<TaskItem>())) ?? []
        let allDays = (try? store.modelContext.fetch(FetchDescriptor<PlanDay>())) ?? []
        let currentWeekGoals = store.currentWeek.weeklyGoals

        let syncGoals = allGoals.map { goal in
            SyncPayload.SyncGoal(
                id: goal.id,
                title: goal.title,
                notes: goal.notes,
                goalTypeRaw: goal.goalTypeRaw,
                isCompleted: goal.isCompleted,
                targetDate: goal.targetDate,
                targetDateText: goal.targetDateText,
                accentColorHex: goal.accentColorHex,
                iconName: goal.iconName,
                orderIndex: goal.orderIndex,
                createdAt: goal.createdAt,
                completedAt: goal.completedAt
            )
        }

        let syncTasks = allTasks.map { task in
            SyncPayload.SyncTask(
                id: task.id,
                title: task.title,
                notes: task.notes,
                isCompleted: task.isCompleted,
                priorityRaw: task.priorityRaw,
                estimatedPomodoros: task.estimatedPomodoros,
                completedPomodoros: task.completedPomodoros,
                createdAt: task.createdAt,
                completedAt: task.completedAt,
                orderIndex: task.orderIndex,
                taskScopeRaw: task.taskScopeRaw,
                goalId: task.goal?.id,
                dayDate: task.planDay?.date
            )
        }

        let syncDays = allDays.map { day in
            SyncPayload.SyncDay(
                date: day.date,
                reflectionNotes: day.reflectionNotes
            )
        }

        return SyncPayload(
            version: 2,
            exportedAt: Date.now,
            goals: syncGoals,
            tasks: syncTasks,
            days: syncDays,
            weeklyGoals: currentWeekGoals
        )
    }

    public func exportJSONData(store: LifesaverStore) -> Data? {
        let payload = generatePayload(store: store)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(payload)
    }

    public func importJSONData(_ data: Data, into store: LifesaverStore) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let payload = try? decoder.decode(SyncPayload.self, from: data) else {
            syncStatusMessage = "Invalid backup file format"
            return
        }

        isSyncing = true
        let context = store.modelContext

        // 1. Merge Goals
        let existingGoals = (try? context.fetch(FetchDescriptor<GoalItem>())) ?? []
        var goalMap: [UUID: GoalItem] = Dictionary(uniqueKeysWithValues: existingGoals.map { ($0.id, $0) })

        if let syncGoals = payload.goals {
            for sg in syncGoals {
                if let existing = goalMap[sg.id] {
                    if !existing.isCompleted && sg.isCompleted {
                        existing.isCompleted = true
                        existing.completedAt = sg.completedAt ?? Date.now
                    }
                    if existing.title.isEmpty && !sg.title.isEmpty {
                        existing.title = sg.title
                    }
                    if existing.targetDateText == nil && sg.targetDateText != nil {
                        existing.targetDateText = sg.targetDateText
                    }
                } else {
                    let newGoal = GoalItem(
                        title: sg.title,
                        notes: sg.notes,
                        goalType: GoalItem.GoalType(rawValue: sg.goalTypeRaw) ?? .longTerm,
                        targetDate: sg.targetDate,
                        targetDateText: sg.targetDateText,
                        accentColorHex: sg.accentColorHex,
                        iconName: sg.iconName,
                        orderIndex: sg.orderIndex
                    )
                    newGoal.id = sg.id
                    newGoal.isCompleted = sg.isCompleted
                    newGoal.createdAt = sg.createdAt
                    newGoal.completedAt = sg.completedAt
                    context.insert(newGoal)
                    goalMap[sg.id] = newGoal
                }
            }
        }

        // 2. Merge Days
        let existingDays = (try? context.fetch(FetchDescriptor<PlanDay>())) ?? []
        var dayMap: [Date: PlanDay] = Dictionary(uniqueKeysWithValues: existingDays.map { ($0.date, $0) })

        for syncDay in payload.days {
            let normalizedDate = Calendar.current.startOfDay(for: syncDay.date)
            if let existing = dayMap[normalizedDate] {
                if existing.reflectionNotes.isEmpty && !syncDay.reflectionNotes.isEmpty {
                    existing.reflectionNotes = syncDay.reflectionNotes
                }
            } else {
                let newDay = PlanDay(date: normalizedDate, reflectionNotes: syncDay.reflectionNotes)
                context.insert(newDay)
                dayMap[normalizedDate] = newDay
            }
        }

        // 3. Merge Tasks
        let existingTasks = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []
        let taskMap: [UUID: TaskItem] = Dictionary(uniqueKeysWithValues: existingTasks.map { ($0.id, $0) })

        for st in payload.tasks {
            let targetDay = st.dayDate.flatMap { dayMap[Calendar.current.startOfDay(for: $0)] }
            let targetGoal = st.goalId.flatMap { goalMap[$0] }

            if let existing = taskMap[st.id] {
                if !existing.isCompleted && st.isCompleted {
                    existing.isCompleted = true
                    existing.completedAt = st.completedAt ?? Date.now
                }
                if existing.goal == nil && targetGoal != nil {
                    existing.goal = targetGoal
                    targetGoal?.tasks?.append(existing)
                }
                if existing.planDay == nil && targetDay != nil {
                    existing.planDay = targetDay
                    targetDay?.tasks?.append(existing)
                }
            } else {
                let scope = TaskItem.TaskScope(rawValue: st.taskScopeRaw ?? "daily") ?? .daily
                let newTask = TaskItem(
                    title: st.title,
                    notes: st.notes,
                    priorityRaw: st.priorityRaw,
                    estimatedPomodoros: st.estimatedPomodoros,
                    orderIndex: st.orderIndex,
                    taskScope: scope,
                    goal: targetGoal,
                    planDay: targetDay
                )
                newTask.id = st.id
                newTask.isCompleted = st.isCompleted
                newTask.createdAt = st.createdAt
                newTask.completedAt = st.completedAt
                context.insert(newTask)
                targetGoal?.tasks?.append(newTask)
                targetDay?.tasks?.append(newTask)
            }
        }

        // 4. Merge Weekly Goals if present
        if let weeklyGoals = payload.weeklyGoals {
            for goal in weeklyGoals {
                if !store.currentWeek.weeklyGoals.contains(goal) {
                    store.currentWeek.weeklyGoals.append(goal)
                }
            }
        }

        try? context.save()
        store.notifyChange()
        lastSyncDate = Date.now
        isSyncing = false
        syncStatusMessage = "Merged \(payload.goals?.count ?? 0) goals and \(payload.tasks.count) tasks successfully"
    }

    #if os(macOS)
    @discardableResult
    public func autoSyncLocalMacCloudDocs(store: LifesaverStore) -> Bool {
        isSyncing = true
        let home = FileManager.default.homeDirectoryForCurrentUser
        let cloudDocs = home.appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs/Lifesaver", isDirectory: true)

        try? FileManager.default.createDirectory(at: cloudDocs, withIntermediateDirectories: true)
        let syncFile = cloudDocs.appendingPathComponent("LifesaverSync.json")

        // 1. Read existing file from iCloud Drive if newer
        if FileManager.default.fileExists(atPath: syncFile.path) {
            if let data = try? Data(contentsOf: syncFile) {
                importJSONData(data, into: store)
            }
        }

        // 2. Export updated merged data back to iCloud Drive
        if let exportData = exportJSONData(store: store) {
            try? exportData.write(to: syncFile, options: .atomic)
            lastSyncDate = Date.now
            isSyncing = false
            syncStatusMessage = "Synced with iCloud Drive at \(Date.now.formatted(date: .omitted, time: .shortened))"
            return true
        }
        isSyncing = false
        syncStatusMessage = "Sync failed"
        return false
    }
    #endif
}
