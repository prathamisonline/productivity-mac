import SwiftUI
import SwiftData

public typealias GitHubYearlyActivityMatrixView = LeetCodeYearlyActivityMatrixView

public struct LeetCodeYearlyActivityMatrixView: View {
    @Bindable var store: LifesaverStore
    @State private var streakManager = StreakManager.shared
    @State private var selectedYearOption: String = "Current"
    @State private var hoveredDay: HoveredDayInfo? = nil

    private struct HoveredDayInfo: Identifiable {
        let id = UUID()
        let date: Date
        let dateString: String
        let tasksCompleted: Int
        let loggedMinutes: Int
        let isFrozen: Bool
        let isToday: Bool
        let isFuture: Bool
    }

    private struct DayCellData: Identifiable {
        let id: String
        let date: Date
        let dayOfMonth: Int
        let formattedDate: String
        let tasksCompleted: Int
        let loggedMinutes: Int
        let isFrozen: Bool
        let isToday: Bool
        let isFuture: Bool
        let level: Int
    }

    private struct MonthBlockData: Identifiable {
        let id: String
        let monthName: String
        let year: Int
        let columns: [[DayCellData?]] // each column has exactly 7 rows (Sun=0..Sat=6)
    }

    public init(store: LifesaverStore) {
        self.store = store
    }

    public var body: some View {
        let _ = store.revision
        let metrics = buildActivityMetrics()
        let months = generateMonthBlocks(metrics: metrics)
        let totalActiveDays = metrics.values.filter { $0.tasksCompleted > 0 || $0.loggedMinutes > 0 }.count
        let totalActivities = metrics.values.reduce(0) { $0 + $1.tasksCompleted + ($1.loggedMinutes > 0 ? 1 : 0) }
        let maxStreak = max(streakManager.longestStreak, streakManager.currentStreak)

        VStack(alignment: .leading, spacing: 16) {
            // MARK: - LeetCode Top Header
            HStack(alignment: .center) {
                // Left: Count & Label
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(totalActivities)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.primary)

                    Text(selectedYearOption == "Current" ? "activities in the past one year" : "activities in \(selectedYearOption)")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.secondary)

                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary.opacity(0.7))
                        .help("Total tasks completed and focus sessions recorded")
                }

                Spacer()

                // Right: Total active days, Max streak, and Year Menu
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Text("Total active days:")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.secondary)
                        Text("\(totalActiveDays)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.primary)
                    }

                    HStack(spacing: 4) {
                        Text("Max streak:")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.secondary)
                        Text("\(maxStreak)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.primary)
                    }

                    // Year Dropdown Menu (LeetCode style)
                    Menu {
                        ForEach(availableYears, id: \.self) { yearOpt in
                            Button(action: {
                                withAnimation(ThemeTokens.quickSpring) {
                                    selectedYearOption = yearOpt
                                }
                            }) {
                                HStack {
                                    Text(yearOpt)
                                    if selectedYearOption == yearOpt {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Text(selectedYearOption)
                                .font(.system(size: 11, weight: .semibold))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(Color.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                    }
                    .menuStyle(.borderlessButton)
                }
            }

            // MARK: - LeetCode Month Clusters Grid
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(months) { month in
                        monthClusterView(month: month)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 2)
            }

            // MARK: - LeetCode Bottom Readout & Legend
            HStack(alignment: .center) {
                if let hovered = hoveredDay {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(hovered.tasksCompleted > 0 || hovered.loggedMinutes > 0 ? Color(hex: "#4ade80") ?? .green : Color.secondary)
                            .frame(width: 7, height: 7)

                        Text(hovered.dateString + ":")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.primary)

                        if hovered.isFuture {
                            Text("Upcoming day")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.secondary)
                        } else if hovered.isFrozen {
                            HStack(spacing: 3) {
                                Image(systemName: "shield.fill")
                                    .font(.system(size: 10))
                                Text("Streak Shielded (Rest Day)")
                            }
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.blue)
                        } else if hovered.tasksCompleted == 0 && hovered.loggedMinutes == 0 {
                            Text("No activity")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.secondary)
                        } else {
                            Text("\(hovered.tasksCompleted) task\(hovered.tasksCompleted == 1 ? "" : "s") completed")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(hex: "#4ade80") ?? .green)

                            if hovered.loggedMinutes > 0 {
                                Text("•")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.secondary)
                                Text("\(formatMinutes(hovered.loggedMinutes)) logged")
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(Color.primary)
                            }
                        }
                    }
                } else {
                    Text("Hover over any square to view daily focus breakdown")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                }

                Spacer()

                // LeetCode Legend: Less [0][1][2][3][4] More
                HStack(spacing: 4) {
                    Text("Less")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.secondary)

                    legendBox(level: 0)
                    legendBox(level: 1)
                    legendBox(level: 2)
                    legendBox(level: 3)
                    legendBox(level: 4)

                    Text("More")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.secondary)
                }
            }
            .padding(.top, 2)
        }
        .padding(18)
        .background(ThemeTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Month Cluster (Column Group + Label)
    @ViewBuilder
    private func monthClusterView(month: MonthBlockData) -> some View {
        VStack(spacing: 8) {
            // Columns of 7 rows
            HStack(spacing: 3) {
                ForEach(0..<month.columns.count, id: \.self) { colIdx in
                    let column = month.columns[colIdx]
                    VStack(spacing: 3) {
                        ForEach(0..<7, id: \.self) { rowIdx in
                            if let day = column[rowIdx] {
                                dayCell(day: day)
                            } else {
                                // Transparent placeholder for calendar alignment
                                Color.clear
                                    .frame(width: 10, height: 10)
                            }
                        }
                    }
                }
            }

            // Month Label (Nov, Dec, Jan...)
            Text(month.monthName)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.secondary)
        }
    }

    // MARK: - Day Cell
    @ViewBuilder
    private func dayCell(day: DayCellData) -> some View {
        let cellColor = dayColor(for: day)

        RoundedRectangle(cornerRadius: 2.5)
            .fill(cellColor)
            .frame(width: 10, height: 10)
            .overlay(
                RoundedRectangle(cornerRadius: 2.5)
                    .strokeBorder(
                        day.isToday
                        ? Color.white.opacity(0.9)
                        : (day.isFrozen ? Color.blue.opacity(0.7) : Color.white.opacity(0.03)),
                        lineWidth: day.isToday ? 1.2 : 0.5
                    )
            )
            .onHover { isHovered in
                if isHovered {
                    hoveredDay = HoveredDayInfo(
                        date: day.date,
                        dateString: day.formattedDate,
                        tasksCompleted: day.tasksCompleted,
                        loggedMinutes: day.loggedMinutes,
                        isFrozen: day.isFrozen,
                        isToday: day.isToday,
                        isFuture: day.isFuture
                    )
                }
            }
    }

    // MARK: - LeetCode Color Palette
    private func dayColor(for day: DayCellData) -> Color {
        if day.isFuture {
            return Color.white.opacity(0.04)
        }
        if day.isFrozen {
            return Color(red: 0.18, green: 0.42, blue: 0.72) // Shield blue
        }

        switch day.level {
        case 0:
            return Color(red: 0.18, green: 0.18, blue: 0.20) // LeetCode dark gray inactive
        case 1:
            return Color(hex: "#15803d") ?? Color(red: 0.08, green: 0.50, blue: 0.24) // Level 1 green
        case 2:
            return Color(hex: "#16a34a") ?? Color(red: 0.09, green: 0.64, blue: 0.29) // Level 2 green
        case 3:
            return Color(hex: "#22c55e") ?? Color(red: 0.13, green: 0.77, blue: 0.36) // Level 3 green
        default:
            return Color(hex: "#4ade80") ?? Color(red: 0.29, green: 0.87, blue: 0.50) // Level 4 electric green
        }
    }

    // MARK: - Legend Square
    @ViewBuilder
    private func legendBox(level: Int) -> some View {
        let color: Color = {
            switch level {
            case 0: return Color(red: 0.18, green: 0.18, blue: 0.20)
            case 1: return Color(hex: "#15803d") ?? Color(red: 0.08, green: 0.50, blue: 0.24)
            case 2: return Color(hex: "#16a34a") ?? Color(red: 0.09, green: 0.64, blue: 0.29)
            case 3: return Color(hex: "#22c55e") ?? Color(red: 0.13, green: 0.77, blue: 0.36)
            default: return Color(hex: "#4ade80") ?? Color(red: 0.29, green: 0.87, blue: 0.50)
            }
        }()

        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 10, height: 10)
    }

    // MARK: - Month Blocks Generation
    private func generateMonthBlocks(metrics: [Date: DailyMetric]) -> [MonthBlockData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)
        let monthsToBuild = targetMonthsList(calendar: calendar, today: today)

        var result: [MonthBlockData] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"

        for (year, monthNum, monthName) in monthsToBuild {
            guard let monthStartDate = calendar.date(from: DateComponents(year: year, month: monthNum, day: 1)),
                  let range = calendar.range(of: .day, in: .month, for: monthStartDate)
            else { continue }

            let totalDaysInMonth = range.count
            // Sunday = 1, Monday = 2 ... Saturday = 7 in Calendar
            let firstDayWeekday = calendar.component(.weekday, from: monthStartDate)
            let startRow = (firstDayWeekday - 1) % 7 // 0 = Sunday, 6 = Saturday

            var columns: [[DayCellData?]] = []
            var currentColumn: [DayCellData?] = Array(repeating: nil, count: startRow)

            for dayNum in 1...totalDaysInMonth {
                guard let cellDate = calendar.date(from: DateComponents(year: year, month: monthNum, day: dayNum)) else { continue }
                let normalized = calendar.startOfDay(for: cellDate)
                let metric = metrics[normalized]

                let tasksDone = metric?.tasksCompleted ?? 0
                let mins = metric?.loggedMinutes ?? 0
                let isFrozen = streakManager.frozenDates.contains(normalized)
                let isToday = normalized == today
                let isFuture = normalized > today

                let level = calculateLevel(tasks: tasksDone, mins: mins)

                let cellData = DayCellData(
                    id: "\(year)-\(monthNum)-\(dayNum)",
                    date: normalized,
                    dayOfMonth: dayNum,
                    formattedDate: dateFormatter.string(from: normalized),
                    tasksCompleted: tasksDone,
                    loggedMinutes: mins,
                    isFrozen: isFrozen,
                    isToday: isToday,
                    isFuture: isFuture,
                    level: level
                )

                currentColumn.append(cellData)

                if currentColumn.count == 7 {
                    columns.append(currentColumn)
                    currentColumn = []
                }
            }

            if !currentColumn.isEmpty {
                while currentColumn.count < 7 {
                    currentColumn.append(nil)
                }
                columns.append(currentColumn)
            }

            result.append(MonthBlockData(
                id: "\(year)-\(monthNum)",
                monthName: monthName,
                year: year,
                columns: columns
            ))
        }

        return result
    }

    private func targetMonthsList(calendar: Calendar, today: Date) -> [(year: Int, month: Int, name: String)] {
        let monthSymbols = calendar.shortMonthSymbols

        if selectedYearOption == "Current" {
            // Past 12 months up to today
            let curYear = calendar.component(.year, from: today)
            let curMonth = calendar.component(.month, from: today) // 1..12

            var list: [(year: Int, month: Int, name: String)] = []
            for offset in (0..<12).reversed() {
                var m = curMonth - offset
                var y = curYear
                while m <= 0 {
                    m += 12
                    y -= 1
                }
                let name = monthSymbols[(m - 1) % 12]
                list.append((year: y, month: m, name: name))
            }
            return list
        } else if let year = Int(selectedYearOption) {
            // Calendar year Jan..Dec
            var list: [(year: Int, month: Int, name: String)] = []
            for m in 1...12 {
                let name = monthSymbols[m - 1]
                list.append((year: year, month: m, name: name))
            }
            return list
        } else {
            return []
        }
    }

    private var availableYears: [String] {
        let curYear = Calendar.current.component(.year, from: Date.now)
        return ["Current", "\(curYear)", "\(curYear - 1)", "\(curYear - 2)", "\(curYear - 3)"]
    }

    // MARK: - Level Calculation (0..4)
    private func calculateLevel(tasks: Int, mins: Int) -> Int {
        if tasks == 0 && mins == 0 { return 0 }
        let score = (tasks * 2) + (mins / 25)
        if score >= 6 { return 4 }
        if score >= 4 { return 3 }
        if score >= 2 { return 2 }
        return 1
    }

    // MARK: - Data Building
    private struct DailyMetric {
        var tasksCompleted: Int = 0
        var loggedMinutes: Int = 0
    }

    private func buildActivityMetrics() -> [Date: DailyMetric] {
        let calendar = Calendar.current
        var map: [Date: DailyMetric] = [:]

        let allTasks = store.allLoggedTasks()
        for task in allTasks {
            if task.isCompleted {
                let completedDate = task.completedAt ?? task.planDay?.date ?? task.createdAt
                let day = calendar.startOfDay(for: completedDate)
                map[day, default: DailyMetric()].tasksCompleted += 1
            }

            if task.loggedMinutes > 0 {
                let targetDate = task.planDay?.date ?? task.completedAt ?? task.createdAt
                let day = calendar.startOfDay(for: targetDate)
                map[day, default: DailyMetric()].loggedMinutes += task.loggedMinutes
            }
        }

        return map
    }

    private func formatMinutes(_ totalMinutes: Int) -> String {
        guard totalMinutes > 0 else { return "0m" }
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h > 0 && m > 0 {
            return "\(h)h \(m)m"
        } else if h > 0 {
            return "\(h)h"
        } else {
            return "\(m)m"
        }
    }
}
