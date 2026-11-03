import SwiftUI
import SwiftData

public struct MatricesStageView: View {
    @Bindable var store: LifesaverStore
    @State private var selectedTimeframe: TimeframeOption = .thisWeek

    public enum TimeframeOption: String, CaseIterable, Identifiable {
        case thisWeek = "This Week"
        case thisMonth = "This Month"

        public var id: String { rawValue }
    }

    public init(store: LifesaverStore) {
        self.store = store
    }

    public var body: some View {
        let _ = store.revision

        ScrollView {
            VStack(spacing: 22) {
                // MARK: - Header Banner
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("STAGE 4")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(ThemeTokens.structuredPurple)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(ThemeTokens.structuredPurple.opacity(0.12))
                                .clipShape(Capsule())

                            Text("TIME & EXECUTION MATRIX")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.secondary)
                                .tracking(0.5)
                        }

                        Text("Performance & Time Matrices")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(Color.primary)

                        Text("Track daily hours logged, weekly consistency patterns, and time invested into goals.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.secondary)
                    }

                    Spacer()

                    // Timeframe Picker
                    Picker("", selection: $selectedTimeframe) {
                        ForEach(TimeframeOption.allCases) { opt in
                            Text(opt.rawValue).tag(opt)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
                .padding(.horizontal, 4)

                // MARK: - Summary KPI Cards Row
                summaryKPIsRow

                // MARK: - Weekly Mon-Sun Time Distribution Matrix
                weeklyDistributionMatrix

                // MARK: - LeetCode-Style Yearly Activity Matrix
                LeetCodeYearlyActivityMatrixView(store: store)

                // MARK: - Goal Time Investment Matrix
                goalInvestmentMatrix

                // MARK: - Task Time Ledger Table
                taskTimeLedgerSection

                // MARK: - Stage Glide Footer
                HStack {
                    Button(action: {
                        withAnimation(ThemeTokens.smoothSpring) {
                            store.slidePrevTab()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 11, weight: .bold))
                            Text("Back to Daily Actions")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundStyle(ThemeTokens.structuredGreen)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(ThemeTokens.structuredGreen.opacity(0.10))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.top, 12)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
        .background(ThemeTokens.canvasBackground)
    }

    // MARK: - 1. Summary KPI Cards
    private var summaryKPIsRow: some View {
        let totalMins = selectedTimeframe == .thisWeek
            ? store.totalLoggedMinutesThisWeek()
            : store.totalLoggedMinutesThisMonth()

        let divisor = selectedTimeframe == .thisWeek ? 7 : 30
        let avgMins = totalMins / divisor

        let allTasks = store.allLoggedTasks()
        let completedCount = allTasks.filter { $0.isCompleted }.count
        let totalCount = allTasks.count
        let completionRate = totalCount > 0 ? Int((Double(completedCount) / Double(totalCount)) * 100) : 0

        return HStack(spacing: 12) {
            kpiCard(
                title: selectedTimeframe == .thisWeek ? "Weekly Logged" : "Monthly Logged",
                value: formatMinutes(totalMins),
                subtitle: "\(totalMins) total minutes",
                icon: "clock.fill",
                accent: ThemeTokens.structuredBlue
            )

            kpiCard(
                title: "Daily Average",
                value: formatMinutes(avgMins),
                subtitle: "across \(divisor) days",
                icon: "chart.line.uptrend.xyaxis",
                accent: ThemeTokens.structuredPurple
            )

            kpiCard(
                title: "Tasks Completed",
                value: "\(completedCount)/\(totalCount)",
                subtitle: "\(completionRate)% completion rate",
                icon: "checkmark.circle.fill",
                accent: ThemeTokens.structuredGreen
            )

            kpiCard(
                title: "Streak Status",
                value: "\(StreakManager.shared.currentStreak)d",
                subtitle: StreakManager.shared.isActiveToday ? "Active today" : "Pending today",
                icon: "flame.fill",
                accent: ThemeTokens.structuredCoral
            )
        }
    }

    private func kpiCard(title: String, value: String, subtitle: String, icon: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.secondary)
                    .tracking(0.5)

                Spacer()

                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(accent)
            }

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.primary)

            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(Color.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ThemeTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - 2. Weekly Distribution Matrix (Mon-Sun Bar Chart)
    private var weeklyDistributionMatrix: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DAILY TIME DISTRIBUTION (THIS WEEK)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.secondary)
                        .tracking(0.5)

                    Text("Hours logged per day vs daily baseline")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(ThemeTokens.structuredBlue)
                        .frame(width: 8, height: 8)
                    Text("Logged Hours")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                }
            }

            let days = weekDayData()

            HStack(alignment: .bottom, spacing: 12) {
                ForEach(days) { d in
                    VStack(spacing: 8) {
                        // Value label above bar
                        Text(d.loggedMins > 0 ? formatMinutes(d.loggedMins) : "—")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(d.isToday ? ThemeTokens.structuredBlue : Color.secondary)

                        // Vertical Bar Container
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.primary.opacity(0.04))
                                .frame(height: 120)

                            let maxTargetMins = 360.0 // 6 hours scale
                            let barHeight = min(120.0, max(4.0, (Double(d.loggedMins) / maxTargetMins) * 120.0))

                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    d.isToday
                                    ? LinearGradient(colors: [ThemeTokens.structuredBlue, ThemeTokens.structuredPurple], startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(colors: [ThemeTokens.structuredBlue.opacity(0.85), ThemeTokens.structuredBlue.opacity(0.65)], startPoint: .top, endPoint: .bottom)
                                )
                                .frame(height: d.loggedMins > 0 ? barHeight : 0)
                        }

                        // Day label & task count
                        VStack(spacing: 2) {
                            Text(d.dayName)
                                .font(.system(size: 11, weight: d.isToday ? .bold : .medium))
                                .foregroundStyle(d.isToday ? ThemeTokens.structuredBlue : Color.primary)

                            Text("\(d.completedTasks) done")
                                .font(.system(size: 9))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 8)
        }
        .padding(18)
        .background(ThemeTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - 3. Goal Time Investment Matrix
    private var goalInvestmentMatrix: some View {
        let goals = store.allLongTermGoals + store.allShortTermGoals

        return VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("GOAL TIME ALLOCATION")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.secondary)
                    .tracking(0.5)

                Text("Where your focused hours are being directed across strategic and tactical goals")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondary)
            }

            if goals.isEmpty {
                Text("No goals created yet.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondary)
                    .padding(.vertical, 8)
            } else {
                let totalLoggedAcrossGoals = max(1, goals.reduce(0) { sum, g in
                    sum + (g.tasks?.reduce(0) { $0 + $1.loggedMinutes } ?? 0)
                })

                VStack(spacing: 10) {
                    ForEach(goals) { goal in
                        let goalMins = goal.tasks?.reduce(0) { $0 + $1.loggedMinutes } ?? 0
                        let percent = Int((Double(goalMins) / Double(totalLoggedAcrossGoals)) * 100)
                        let goalColor = Color(hex: goal.accentColorHex) ?? ThemeTokens.structuredBlue
                        let completedTasks = goal.tasks?.filter { $0.isCompleted }.count ?? 0
                        let totalTasks = goal.tasks?.count ?? 0

                        VStack(spacing: 6) {
                            HStack {
                                Image(systemName: goal.iconName)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(goalColor)

                                Text(goal.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.primary)

                                Text("(\(goal.goalType.shortName))")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Color.secondary)

                                Spacer()

                                Text("\(completedTasks)/\(totalTasks) tasks")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.secondary)

                                Text(formatMinutes(goalMins))
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color.primary)
                                    .frame(minWidth: 55, alignment: .trailing)

                                Text("\(percent)%")
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(Color.secondary)
                                    .frame(width: 36, alignment: .trailing)
                            }

                            // Progress ratio bar
                            GeometryReader { g in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.primary.opacity(0.04))
                                        .frame(height: 6)

                                    Capsule()
                                        .fill(goalColor)
                                        .frame(width: max(4, g.size.width * CGFloat(min(1.0, Double(goalMins) / Double(totalLoggedAcrossGoals)))), height: 6)
                                }
                            }
                            .frame(height: 6)
                        }
                        .padding(10)
                        .background(Color.primary.opacity(0.02))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(18)
        .background(ThemeTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - 4. Task Time Ledger
    private var taskTimeLedgerSection: some View {
        let allTasks = store.allLoggedTasks()
        let loggedTasks = allTasks.filter { $0.loggedMinutes > 0 }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TASK TIME LEDGER")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.secondary)
                        .tracking(0.5)

                    Text("All tasks with logged focus sessions")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                }

                Spacer()

                Text("\(loggedTasks.count) recorded tasks")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.secondary)
            }

            if loggedTasks.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.secondary)
                    Text("No tasks with logged time yet. Use the '+Time' button on any daily task row to log hours.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                }
                .padding(.vertical, 10)
            } else {
                VStack(spacing: 6) {
                    ForEach(loggedTasks) { task in
                        HStack(spacing: 10) {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(task.isCompleted ? ThemeTokens.structuredGreen : Color.secondary)

                            Text(task.title)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.primary)
                                .lineLimit(1)

                            if let goal = task.goal {
                                Text(goal.title)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(Color(hex: goal.accentColorHex) ?? ThemeTokens.structuredBlue)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background((Color(hex: goal.accentColorHex) ?? ThemeTokens.structuredBlue).opacity(0.12))
                                    .clipShape(Capsule())
                            }

                            Spacer()

                            Text(task.taskScope.badgeName)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color.secondary)

                            Text(task.formattedLoggedTime)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(ThemeTokens.structuredBlue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(ThemeTokens.structuredBlue.opacity(0.10))
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.primary.opacity(0.02))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(18)
        .background(ThemeTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Helpers & Data Calculation
    private struct DayBarItem: Identifiable {
        let id = UUID()
        let dayName: String
        let date: Date
        let loggedMins: Int
        let completedTasks: Int
        let isToday: Bool
    }

    private func weekDayData() -> [DayBarItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else { return [] }

        var list: [DayBarItem] = []
        let dayLetters = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

        for i in 0..<7 {
            if let dayDate = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                let mins = store.loggedMinutes(for: dayDate)
                let tasksCount = store.completedTasksCount(for: dayDate)
                list.append(DayBarItem(
                    dayName: dayLetters[i],
                    date: dayDate,
                    loggedMins: mins,
                    completedTasks: tasksCount,
                    isToday: dayDate == today
                ))
            }
        }
        return list
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

