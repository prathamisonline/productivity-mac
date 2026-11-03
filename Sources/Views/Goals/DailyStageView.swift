import SwiftUI

public struct DailyStageView: View {
    @Bindable var store: LifesaverStore
    @State private var quickDailyTaskTitle: String = ""

    public init(store: LifesaverStore) {
        self.store = store
    }

    private var goals: [GoalItem] {
        store.allDailyGoals
    }

    private var linkedDailyTasks: [TaskItem] {
        store.dailyTasksFromShortTermGoals
    }

    private var standaloneDailyTasks: [TaskItem] {
        store.standaloneDailyTasks
    }

    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        return formatter.string(from: Date.now)
    }

    public var body: some View {
        let _ = store.revision
        ScrollView {
            VStack(spacing: 20) {
                // Stage Header Banner
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("STAGE 3")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(ThemeTokens.structuredGreen)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(ThemeTokens.structuredGreen.opacity(0.12))
                                .clipShape(Capsule())

                            Text(todayDateString.uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.secondary)
                                .tracking(0.5)
                        }

                        Text("Daily Goals & Actions")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(Color.primary)

                        Text("What you need to achieve today. Add daily goals and specific daily tasks to achieve them.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.secondary)
                    }

                    Spacer()

                    // Add Daily Goal Button
                    Button(action: {
                        store.newGoalTargetType = .daily
                        store.isNewGoalSheetPresented = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text("New Daily Goal")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [ThemeTokens.structuredGreen, Color(red: 0.15, green: 0.70, blue: 0.45)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: ThemeTokens.structuredGreen.opacity(0.3), radius: 6, y: 2)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)

                // Quick Add Daily Task Bar
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(ThemeTokens.structuredGreen)

                    TextField("Quick add a daily task for today (Press Enter)...", text: $quickDailyTaskTitle)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .onSubmit {
                            addQuickTask()
                        }

                    if !quickDailyTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                        Button("Add Task") {
                            addQuickTask()
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(ThemeTokens.structuredGreen)
                        .clipShape(Capsule())
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(ThemeTokens.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                )

                // Daily Goals Cards
                if !goals.isEmpty {
                    LazyVStack(spacing: 16) {
                        ForEach(goals) { goal in
                            GoalCardView(store: store, goal: goal)
                        }
                    }
                }

                // Linked Daily Tasks from Short-Term Goals (if any exist)
                if !linkedDailyTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "link")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(ThemeTokens.structuredBlue)

                            Text("DAILY TASKS CONNECTED TO SHORT-TERM GOALS")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(ThemeTokens.structuredBlue)
                                .tracking(0.5)

                            Spacer()

                            Text("\(linkedDailyTasks.count) tasks")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.secondary)
                        }

                        VStack(spacing: 6) {
                            ForEach(linkedDailyTasks) { task in
                                GoalTaskRowView(store: store, task: task)
                            }
                        }
                    }
                    .padding(18)
                    .background(ThemeTokens.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(ThemeTokens.structuredBlue.opacity(0.2), lineWidth: 1)
                    )
                }

                // Standalone Quick Daily Tasks (if any)
                if !standaloneDailyTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(ThemeTokens.structuredGreen)

                            Text("STANDALONE DAILY TASKS")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(ThemeTokens.structuredGreen)
                                .tracking(0.5)

                            Spacer()

                            Text("\(standaloneDailyTasks.count) tasks")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.secondary)
                        }

                        VStack(spacing: 6) {
                            ForEach(standaloneDailyTasks) { task in
                                GoalTaskRowView(store: store, task: task)
                            }
                        }
                    }
                    .padding(18)
                    .background(ThemeTokens.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }

                // Stage Glide Footer
                HStack {
                    Button(action: {
                        withAnimation(ThemeTokens.smoothSpring) {
                            store.slidePrevTab()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 11, weight: .bold))
                            Text("Back to Short-Term Goals")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundStyle(ThemeTokens.structuredBlue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(ThemeTokens.structuredBlue.opacity(0.10))
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

    private func addQuickTask() {
        guard !quickDailyTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        withAnimation(ThemeTokens.bouncySpring) {
            // If there's a daily goal, add to first daily goal; otherwise standalone
            let targetGoal = goals.first
            store.addTask(title: quickDailyTaskTitle, to: targetGoal, scope: .daily)
            quickDailyTaskTitle = ""
        }
    }

}
