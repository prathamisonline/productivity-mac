import SwiftUI

public struct LongTermStageView: View {
    @Bindable var store: LifesaverStore

    public init(store: LifesaverStore) {
        self.store = store
    }

    private var goals: [GoalItem] {
        store.allLongTermGoals
    }

    public var body: some View {
        let _ = store.revision
        ScrollView {
            VStack(spacing: 20) {
                // Stage Header Banner
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("STAGE 1")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(ThemeTokens.structuredCoral)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(ThemeTokens.structuredCoral.opacity(0.12))
                                .clipShape(Capsule())

                            Text("MACRO VISION & NORTH STAR")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.secondary)
                                .tracking(0.5)
                        }

                        Text("Long-Term Goals")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(Color.primary)

                        Text("Define your overarching vision and the strategic long-term tasks to achieve them.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.secondary)
                    }

                    Spacer()

                    // Add Long-Term Goal Button
                    Button(action: {
                        store.newGoalTargetType = .longTerm
                        store.isNewGoalSheetPresented = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text("New Long-Term Goal")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [ThemeTokens.structuredCoral, ThemeTokens.structuredCoralDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: ThemeTokens.structuredCoral.opacity(0.3), radius: 6, y: 2)
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

                // Stage Glide Footer
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(ThemeTokens.smoothSpring) {
                            store.slideNextTab()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text("Proceed to Short-Term Goals")
                                .font(.system(size: 13, weight: .bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(ThemeTokens.structuredBlue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(ThemeTokens.structuredBlue.opacity(0.10))
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
            Image(systemName: "target")
                .font(.system(size: 40))
                .foregroundStyle(ThemeTokens.structuredCoral.opacity(0.5))

            Text("No Long-Term Goals Set Yet")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.primary)

            Text("Set your 1-to-5 year horizons and define what milestones are needed to get there.")
                .font(.system(size: 13))
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)

            Button("Create First Long-Term Goal") {
                store.newGoalTargetType = .longTerm
                store.isNewGoalSheetPresented = true
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(ThemeTokens.structuredCoral)
            .clipShape(Capsule())
            .buttonStyle(.plain)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color.primary.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

