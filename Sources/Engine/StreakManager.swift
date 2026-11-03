import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
public final class StreakManager {
    public static let shared = StreakManager()

    // Persistent settings
    @ObservationIgnored
    @AppStorage("streakFrozenDatesData") private var frozenDatesData: String = ""

    @ObservationIgnored
    @AppStorage("streakFreezesRemaining") public var freezesRemaining: Int = 2

    @ObservationIgnored
    @AppStorage("streakLastFreezeMonth") private var lastFreezeMonth: Int = -1

    public var currentStreak: Int = 0
    public var longestStreak: Int = 0
    public var isActiveToday: Bool = false
    public var recentDays: [DayActivity] = []

    public struct DayActivity: Identifiable {
        public var id: Date { date }
        public let date: Date
        public let dayLetter: String
        public let isActive: Bool
        public let isFrozen: Bool
        public let isToday: Bool
    }

    private init() {
        checkMonthlyFreezeReplenishment()
    }

    // MARK: - Freeze Dates Storage
    public var frozenDates: Set<Date> {
        get {
            let strings = frozenDatesData.components(separatedBy: ",").filter { !$0.isEmpty }
            let formatter = ISO8601DateFormatter()
            let dates = strings.compactMap { formatter.date(from: $0) }
            return Set(dates.map { Calendar.current.startOfDay(for: $0) })
        }
        set {
            let formatter = ISO8601DateFormatter()
            let strings = newValue.map { formatter.string(from: $0) }
            frozenDatesData = strings.joined(separator: ",")
        }
    }

    private func checkMonthlyFreezeReplenishment() {
        let currentMonth = Calendar.current.component(.month, from: Date.now)
        if lastFreezeMonth != currentMonth {
            lastFreezeMonth = currentMonth
            freezesRemaining = 2
        }
    }

    // MARK: - Calculation
    public func recalculate(store: LifesaverStore) {
        checkMonthlyFreezeReplenishment()

        let context = store.modelContext
        let tasks = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []
        let goals = (try? context.fetch(FetchDescriptor<GoalItem>())) ?? []

        var activeDateSet = Set<Date>()

        for task in tasks where task.isCompleted {
            let d = task.completedAt ?? task.createdAt
            activeDateSet.insert(Calendar.current.startOfDay(for: d))
        }

        for goal in goals where goal.isCompleted {
            let d = goal.completedAt ?? goal.createdAt
            activeDateSet.insert(Calendar.current.startOfDay(for: d))
        }

        let allActiveOrFrozen = activeDateSet.union(frozenDates)

        let today = Calendar.current.startOfDay(for: Date.now)
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) else { return }

        self.isActiveToday = allActiveOrFrozen.contains(today)

        // Calculate current streak
        let startDate: Date?
        if isActiveToday {
            startDate = today
        } else if allActiveOrFrozen.contains(yesterday) {
            startDate = yesterday
        } else {
            startDate = nil
        }

        var count = 0
        if var cursor = startDate {
            while allActiveOrFrozen.contains(cursor) {
                count += 1
                guard let prev = Calendar.current.date(byAdding: .day, value: -1, to: cursor) else { break }
                cursor = prev
            }
        }
        self.currentStreak = count

        // Calculate longest streak historically
        self.longestStreak = calculateLongestStreak(from: allActiveOrFrozen)

        // Generate rolling 7-day activity (last 6 days + today)
        var daysList: [DayActivity] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE" // Single letter (M, T, W, T, F, S, S)

        for offset in (-6...0) {
            if let date = Calendar.current.date(byAdding: .day, value: offset, to: today) {
                let norm = Calendar.current.startOfDay(for: date)
                let letter = formatter.string(from: norm)
                let isAct = activeDateSet.contains(norm)
                let isFroz = frozenDates.contains(norm)
                let isTod = norm == today

                daysList.append(DayActivity(
                    date: norm,
                    dayLetter: letter,
                    isActive: isAct,
                    isFrozen: isFroz,
                    isToday: isTod
                ))
            }
        }
        self.recentDays = daysList
    }

    private func calculateLongestStreak(from dates: Set<Date>) -> Int {
        guard !dates.isEmpty else { return 0 }
        let sorted = dates.sorted()
        var maxStreak = 0
        var currentRun = 0
        var prevDate: Date? = nil

        for date in sorted {
            if let prev = prevDate {
                if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: prev), nextDay == date {
                    currentRun += 1
                } else {
                    currentRun = 1
                }
            } else {
                currentRun = 1
            }
            prevDate = date
            maxStreak = max(maxStreak, currentRun)
        }
        return maxStreak
    }

    // MARK: - Actions
    public func freezeYesterday(store: LifesaverStore) -> Bool {
        guard freezesRemaining > 0 else { return false }
        let today = Calendar.current.startOfDay(for: Date.now)
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) else { return false }

        var currentFrozen = frozenDates
        guard !currentFrozen.contains(yesterday) else { return false }

        currentFrozen.insert(yesterday)
        self.frozenDates = currentFrozen
        self.freezesRemaining -= 1
        recalculate(store: store)
        return true
    }
}

