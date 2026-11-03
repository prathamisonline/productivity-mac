import SwiftUI

public struct GoalCardView: View {
    @Bindable var store: LifesaverStore
    @Bindable public var goal: GoalItem

    @State private var newLongTermTaskTitle: String = ""
    @State private var newShortTermTaskTitle: String = ""
    @State private var newDailyTaskTitle: String = ""
    @State private var isExpanded: Bool = true
    @State private var isEditingGoal: Bool = false

    public init(store: LifesaverStore, goal: GoalItem) {
        self.store = store
        self.goal = goal
    }

    private var accentColor: Color {
        Color(hex: goal.accentColorHex) ?? defaultAccentColor
    }

    private var defaultAccentColor: Color {
        switch goal.goalType {
        case .longTerm: return ThemeTokens.structuredCoral
        case .shortTerm: return ThemeTokens.structuredBlue
        case .daily: return ThemeTokens.structuredGreen
        }
    }

    public var body: some View {
        let _ = store.revision

        VStack(alignment: .leading, spacing: 14) {
            // MARK: - Goal Header
            HStack(alignment: .top, spacing: 12) {
                // Goal Icon & Completion Button
                Button(action: {
                    withAnimation(ThemeTokens.bouncySpring) {
                        store.toggleGoal(goal)
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(goal.isCompleted ? accentColor : accentColor.opacity(0.12))
                            .frame(width: 38, height: 38)

                        if goal.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color.white)
                        } else {
                            Image(systemName: goal.iconName.isEmpty ? goal.goalType.icon : goal.iconName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(accentColor)
                        }
                    }
                }
                .buttonStyle(.plain)
                .help(goal.isCompleted ? "Mark Goal Incomplete" : "Mark Goal Completed")

                // Goal Title & Horizon
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(goal.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(goal.isCompleted ? Color.secondary : Color.primary)
                            .strikethrough(goal.isCompleted, color: Color.secondary.opacity(0.6))

                        if let targetText = goal.targetDateText, !targetText.isEmpty {
                            Text(targetText)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(accentColor)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(accentColor.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }

                    if let notes = goal.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                // Progress Badge & Actions Menu
                HStack(spacing: 8) {
                    if goal.totalTasksCount > 0 {
                        Text("\(goal.completedTasksCount)/\(goal.totalTasksCount) (\(goal.progressPercentageString))")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(goal.isCompleted ? Color.green : Color.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.primary.opacity(0.04))
                            .clipShape(Capsule())
                    }

                    // Edit Goal Button
                    Button(action: {
                        isEditingGoal = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.secondary)
                            .frame(width: 24, height: 24)
                            .background(Color.primary.opacity(0.04))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Edit Goal")

                    Menu {
                        Button("Edit Goal", systemImage: "pencil") {
                            isEditingGoal = true
                        }

                        Button(goal.isCompleted ? "Mark Incomplete" : "Mark Complete", systemImage: goal.isCompleted ? "arrow.uturn.backward" : "checkmark") {
                            withAnimation(ThemeTokens.bouncySpring) {
                                store.toggleGoal(goal)
                            }
                        }

                        Divider()

                        Button(role: .destructive) {
                            withAnimation(ThemeTokens.quickSpring) {
                                store.deleteGoal(goal)
                            }
                        } label: {
                            Label("Delete Goal", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.secondary)
                            .frame(width: 24, height: 24)
                            .background(Color.primary.opacity(0.04))
                            .clipShape(Circle())
                    }
                    .menuStyle(.borderlessButton)
                }
            }

            // MARK: - Progress Bar
            if goal.totalTasksCount > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.primary.opacity(0.06))
                            .frame(height: 5)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [accentColor, accentColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(5, geo.size.width * CGFloat(goal.progress)), height: 5)
                            .animation(ThemeTokens.smoothSpring, value: goal.progress)
                    }
                }
                .frame(height: 5)
            }

            Divider()
                .opacity(0.6)

            // MARK: - Nested Task Sections based on Goal Type
            switch goal.goalType {
            case .longTerm:
                longTermTasksSection

            case .shortTerm:
                shortTermAndDailyTasksSection

            case .daily:
                dailyTasksSection
            }
        }
        .padding(18)
        .background(ThemeTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    goal.isCompleted
                    ? Color.green.opacity(0.3)
                    : (Color.primary.opacity(0.08)),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 3)
        .sheet(isPresented: $isEditingGoal) {
            EditGoalSheetView(store: store, goal: goal)
        }
    }

    // MARK: - Long-Term Tasks Section
    private var longTermTasksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("TASKS TO ACHIEVE THIS LONG-TERM GOAL")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.secondary)
                    .tracking(0.5)

                Spacer()

                Text("\(goal.longTermTasks.count) tasks")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.secondary.opacity(0.8))
            }

            // Task List
            VStack(spacing: 4) {
                ForEach(goal.longTermTasks) { task in
                    GoalTaskRowView(store: store, task: task)
                }
            }

            // Inline Add Long-Term Task Input
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(accentColor)

                TextField("Add a long-term task / milestone to achieve this goal...", text: $newLongTermTaskTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .onSubmit {
                        addLongTermTask()
                    }

                if !newLongTermTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button("Add") {
                        addLongTermTask()
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(accentColor)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func addLongTermTask() {
        guard !newLongTermTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        withAnimation(ThemeTokens.bouncySpring) {
            store.addTask(title: newLongTermTaskTitle, to: goal, scope: .longTerm)
            newLongTermTaskTitle = ""
        }
    }

    // MARK: - Short-Term Tasks Section (Holds Short-Term & Daily Tasks)
    private var shortTermAndDailyTasksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Group 1: Short-Term Tasks
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(ThemeTokens.structuredBlue)

                    Text("SHORT-TERM TASKS / MILESTONES")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(ThemeTokens.structuredBlue)
                        .tracking(0.5)

                    Spacer()

                    Text("\(goal.shortTermTasks.count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.secondary)
                }

                VStack(spacing: 4) {
                    ForEach(goal.shortTermTasks) { task in
                        GoalTaskRowView(store: store, task: task)
                    }
                }

                // Inline Add Short-Term Task
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(ThemeTokens.structuredBlue)

                    TextField("Add short-term milestone task for this goal...", text: $newShortTermTaskTitle)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .onSubmit {
                            addShortTermTask()
                        }

                    if !newShortTermTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                        Button("Add") {
                            addShortTermTask()
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(ThemeTokens.structuredBlue)
                        .clipShape(Capsule())
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Group 2: Daily Action Tasks (Directly connected to this Short-Term Goal)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(ThemeTokens.structuredGreen)

                    Text("DAILY TASKS FOR THIS GOAL")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(ThemeTokens.structuredGreen)
                        .tracking(0.5)

                    Spacer()

                    Text("\(goal.dailyTasks.count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.secondary)
                }

                VStack(spacing: 4) {
                    ForEach(goal.dailyTasks) { task in
                        GoalTaskRowView(store: store, task: task)
                    }
                }

                // Inline Add Daily Task for this Goal
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(ThemeTokens.structuredGreen)

                    TextField("Add daily action task feeding into this goal...", text: $newDailyTaskTitle)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .onSubmit {
                            addDailyTask()
                        }

                    if !newDailyTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                        Button("Add") {
                            addDailyTask()
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(ThemeTokens.structuredGreen)
                        .clipShape(Capsule())
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private func addShortTermTask() {
        guard !newShortTermTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        withAnimation(ThemeTokens.bouncySpring) {
            store.addTask(title: newShortTermTaskTitle, to: goal, scope: .shortTerm)
            newShortTermTaskTitle = ""
        }
    }

    private func addDailyTask() {
        guard !newDailyTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        withAnimation(ThemeTokens.bouncySpring) {
            store.addTask(title: newDailyTaskTitle, to: goal, scope: .daily)
            newDailyTaskTitle = ""
        }
    }

    // MARK: - Daily Tasks Section
    private var dailyTasksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("DAILY TASKS TO ACHIEVE THIS GOAL")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.secondary)
                    .tracking(0.5)

                Spacer()

                Text("\(goal.dailyTasks.count) tasks")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.secondary.opacity(0.8))
            }

            VStack(spacing: 4) {
                ForEach(goal.dailyTasks) { task in
                    GoalTaskRowView(store: store, task: task)
                }
            }

            // Inline Add Daily Task
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(accentColor)

                TextField("Add a daily task to achieve today's goal...", text: $newDailyTaskTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .onSubmit {
                        addDailyTask()
                    }

                if !newDailyTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button("Add") {
                        addDailyTask()
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(accentColor)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// Color hex helper
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
