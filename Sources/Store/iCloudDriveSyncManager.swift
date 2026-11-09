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
    public let deletedJournalDates: [Date]?

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
        public let loggedMinutes: Int?
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
    public var hasLinkedFile: Bool = false

    private let bookmarkKey = "Lifesaver_iCloudDrive_Bookmark"

    #if os(macOS)
    private let bookmarkCreationOpts: URL.BookmarkCreationOptions = [.withSecurityScope]
    private let bookmarkResolutionOpts: URL.BookmarkResolutionOptions = [.withSecurityScope]
    #else
    private let bookmarkCreationOpts: URL.BookmarkCreationOptions = []
    private let bookmarkResolutionOpts: URL.BookmarkResolutionOptions = []
    #endif

    private init() {
        checkLinkedStatus()
    }

    public func checkLinkedStatus() {
        if UserDefaults.standard.data(forKey: bookmarkKey) != nil {
            hasLinkedFile = true
        } else if FileManager.default.url(forUbiquityContainerIdentifier: nil) != nil {
            hasLinkedFile = true
        } else {
            #if os(macOS)
            hasLinkedFile = true
            #else
            hasLinkedFile = false
            #endif
        }
    }

    // MARK: - Save Security-Scoped Bookmark (For iPad & iOS)
    public func saveBookmark(for url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let data = try url.bookmarkData(
                options: bookmarkCreationOpts,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(data, forKey: bookmarkKey)
            hasLinkedFile = true
            syncStatusMessage = "Linked to iCloud Drive successfully"
        } catch {
            syncStatusMessage = "Failed to bookmark iCloud file: \(error.localizedDescription)"
        }
    }

    public func clearBookmark() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        checkLinkedStatus()
        syncStatusMessage = "iCloud link cleared"
    }

    // MARK: - URL Resolution
    public struct ResolvedLocation {
        public let fileURL: URL
        public let isSecurityScoped: Bool
        public let isUbiquitous: Bool
        public let description: String
    }

    public func resolveSyncLocation() -> ResolvedLocation? {
        // 1. Check official Apple Ubiquity Container (CloudDocuments)
        if let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) {
            let docsURL = containerURL.appendingPathComponent("Documents", isDirectory: true)
            try? FileManager.default.createDirectory(at: docsURL, withIntermediateDirectories: true)
            let syncFile = docsURL.appendingPathComponent("LifesaverSync.json")
            return ResolvedLocation(
                fileURL: syncFile,
                isSecurityScoped: false,
                isUbiquitous: true,
                description: "iCloud Ubiquity Container"
            )
        }

        // 2. Check user-selected security-scoped bookmark (crucial for iPad Files app access!)
        if let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) {
            var isStale = false
            if let bookmarkedURL = try? URL(resolvingBookmarkData: bookmarkData, options: bookmarkResolutionOpts, relativeTo: nil, bookmarkDataIsStale: &isStale) {
                if isStale {
                    _ = bookmarkedURL.startAccessingSecurityScopedResource()
                    if let freshData = try? bookmarkedURL.bookmarkData(options: bookmarkCreationOpts, includingResourceValuesForKeys: nil, relativeTo: nil) {
                        UserDefaults.standard.set(freshData, forKey: bookmarkKey)
                    }
                    bookmarkedURL.stopAccessingSecurityScopedResource()
                }

                let finalFile: URL
                if bookmarkedURL.hasDirectoryPath {
                    finalFile = bookmarkedURL.appendingPathComponent("LifesaverSync.json")
                } else {
                    finalFile = bookmarkedURL
                }

                return ResolvedLocation(
                    fileURL: finalFile,
                    isSecurityScoped: true,
                    isUbiquitous: true,
                    description: "Linked iCloud Drive File"
                )
            }
        }

        // 3. On macOS: local iCloud Drive directory in user library
        #if os(macOS)
        let home = FileManager.default.homeDirectoryForCurrentUser
        let cloudDocs = home.appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs/Lifesaver", isDirectory: true)
        try? FileManager.default.createDirectory(at: cloudDocs, withIntermediateDirectories: true)
        let syncFile = cloudDocs.appendingPathComponent("LifesaverSync.json")
        return ResolvedLocation(
            fileURL: syncFile,
            isSecurityScoped: false,
            isUbiquitous: true,
            description: "macOS iCloud Drive"
        )
        #else
        // 4. On iOS/iPadOS fallback to app sandbox Documents
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let syncFile = docs.appendingPathComponent("LifesaverSync.json")
            return ResolvedLocation(
                fileURL: syncFile,
                isSecurityScoped: false,
                isUbiquitous: false,
                description: "Local iPad Storage (Link to iCloud Drive in Settings)"
            )
        }
        return nil
        #endif
    }

    // MARK: - Universal Sync (macOS, iPadOS, iOS)
    @discardableResult
    public func syncNow(store: LifesaverStore) -> Bool {
        return autoSync(store: store, pullFirst: true)
    }

    @discardableResult
    public func autoSync(store: LifesaverStore, pullFirst: Bool = false) -> Bool {
        guard !isSyncing else { return false }
        isSyncing = true

        guard let location = resolveSyncLocation() else {
            isSyncing = false
            syncStatusMessage = "No sync location available"
            return false
        }

        let fileURL = location.fileURL
        let isScoped = location.isSecurityScoped

        if isScoped {
            guard fileURL.startAccessingSecurityScopedResource() else {
                isSyncing = false
                syncStatusMessage = "Could not access linked iCloud file (permission denied)"
                return false
            }
        }

        defer {
            if isScoped {
                fileURL.stopAccessingSecurityScopedResource()
            }
            isSyncing = false
        }

        var coordinatorError: NSError?
        let coordinator = NSFileCoordinator(filePresenter: nil)

        // 1. Coordinate Read (Only when explicitly pulling remote changes first)
        if pullFirst && FileManager.default.fileExists(atPath: fileURL.path) {
            coordinator.coordinate(readingItemAt: fileURL, options: [], error: &coordinatorError) { readURL in
                if let data = try? Data(contentsOf: readURL) {
                    importJSONData(data, into: store)
                }
            }
        }

        // 2. Coordinate Write (Push latest state to iCloud)
        guard let exportData = exportJSONData(store: store) else {
            syncStatusMessage = "Failed to encode sync data"
            return false
        }

        var writeSuccess = false
        coordinator.coordinate(writingItemAt: fileURL, options: .forReplacing, error: &coordinatorError) { writeURL in
            do {
                try exportData.write(to: writeURL, options: .atomic)
                writeSuccess = true
            } catch {
                print("iCloud write error: \(error)")
            }
        }

        if writeSuccess {
            lastSyncDate = Date.now
            let timeStr = Date.now.formatted(date: .omitted, time: .shortened)
            syncStatusMessage = "Synced with \(location.description) at \(timeStr)"
            return true
        } else {
            syncStatusMessage = "Sync failed: \(coordinatorError?.localizedDescription ?? "Write error")"
            return false
        }
    }

    // MARK: - Legacy Compatibility wrapper
    #if os(macOS)
    @discardableResult
    public func autoSyncLocalMacCloudDocs(store: LifesaverStore) -> Bool {
        autoSync(store: store)
    }
    #endif

    // MARK: - Payload Generation
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
                loggedMinutes: task.loggedMinutes,
                createdAt: task.createdAt,
                completedAt: task.completedAt,
                orderIndex: task.orderIndex,
                taskScopeRaw: task.taskScopeRaw,
                goalId: task.goal?.id,
                dayDate: task.planDay?.date
            )
        }

        let syncDays = allDays
            .filter { !$0.reflectionNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !($0.tasks ?? []).isEmpty }
            .map { day in
                SyncPayload.SyncDay(
                    date: day.date,
                    reflectionNotes: day.reflectionNotes
                )
            }

        return SyncPayload(
            version: 3,
            exportedAt: Date.now,
            goals: syncGoals,
            tasks: syncTasks,
            days: syncDays,
            weeklyGoals: currentWeekGoals,
            deletedJournalDates: Array(store.deletedJournalDates)
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

        // Apply explicitly deleted journal dates (tombstones)
        if let deletedDates = payload.deletedJournalDates {
            for d in deletedDates {
                let norm = Calendar.current.startOfDay(for: d)
                store.deletedJournalDates.insert(norm)
                if let existing = dayMap[norm] {
                    existing.reflectionNotes = ""
                    if (existing.tasks ?? []).isEmpty {
                        context.delete(existing)
                        dayMap.removeValue(forKey: norm)
                    }
                }
            }
        }

        for syncDay in payload.days {
            let normalizedDate = Calendar.current.startOfDay(for: syncDay.date)
            // Never resurrect a date that was marked deleted
            if store.deletedJournalDates.contains(normalizedDate) {
                continue
            }
            if let existing = dayMap[normalizedDate] {
                if existing.reflectionNotes.isEmpty && !syncDay.reflectionNotes.isEmpty {
                    existing.reflectionNotes = syncDay.reflectionNotes
                }
            } else if !syncDay.reflectionNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
                if let logged = st.loggedMinutes, logged > existing.loggedMinutes {
                    existing.loggedMinutes = logged
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
                newTask.loggedMinutes = st.loggedMinutes ?? 0
                context.insert(newTask)
                targetGoal?.tasks?.append(newTask)
                targetDay?.tasks?.append(newTask)
            }
        }

        // 4. Merge Weekly Goals
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
}
