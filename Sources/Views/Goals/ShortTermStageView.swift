import SwiftUI

public struct ShortTermStageView: View {
    @Bindable var store: LifesaverStore

    public init(store: LifesaverStore) {
        self.store = store
    }

    private var goals: [GoalItem] {
        store.allShortTermGoals
    }

    public var body: some View {
        let _ = store.revision
        ScrollView {
            VStack(spacing: 20) {
                // Stage Header Banner
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("STAGE 2")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(ThemeTokens.structuredBlue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(ThemeTokens.structuredBlue.opacity(0.12))
                                .clipShape(Capsule())

                            Text("TACTICAL EXECUTION & SPRINTS")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.secondary)
                                .tracking(0.5)
                        }

                        Text("Short-Term Goals")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(Color.primary)

                        Text("Monthly and sprint objectives. Add short-term milestones and daily tasks to reach them.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.secondary)
                    }

                    Spacer()

                    // Add Short-Term Goal Button
                    Button(action: {
                        store.newGoalTargetType = .shortTerm
                        store.isNewGoalSheetPresented = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text("New Short-Term Goal")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [ThemeTokens.structuredBlue, Color(red: 0.12, green: 0.55, blue: 0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: ThemeTokens.structuredBlue.opacity(0.3), radius: 6, y: 2)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)

                // Goals List or Empty State
                if goals.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(goals) { goal in
                            GoalCardView(store: store, goal: goal)
                        }
                    }
                }

                // Stage Glide Footer: Both Left & Right Navigation
                HStack {
                    Button(action: {
                        withAnimation(ThemeTokens.smoothSpring) {
                            store.slidePrevTab()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 11, weight: .bold))
                            Text("Back to Long-Term")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundStyle(ThemeTokens.structuredCoral)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(ThemeTokens.structuredCoral.opacity(0.10))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(action: {
                        withAnimation(ThemeTokens.smoothSpring) {
                            store.slideNextTab()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text("Proceed to Daily Goals")
                                .font(.system(size: 13, weight: .bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(ThemeTokens.structuredGreen)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(ThemeTokens.structuredGreen.opacity(0.10))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 12)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
        .background(ThemeTokens.canvasBackground)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 40))
                .foregroundStyle(ThemeTokens.structuredBlue.opacity(0.5))

            Text("No Short-Term Goals Set Yet")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.primary)

            Text("Add sprint outcomes for this month or quarter. You can add both short-term tasks and daily action tasks.")
                .font(.system(size: 13))
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)

            Button("Create First Short-Term Goal") {
                store.newGoalTargetType = .shortTerm
                store.isNewGoalSheetPresented = true
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(ThemeTokens.structuredBlue)
            .clipShape(Capsule())
            .buttonStyle(.plain)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color.primary.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

