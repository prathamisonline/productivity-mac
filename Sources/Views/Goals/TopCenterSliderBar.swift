import SwiftUI

public struct TopCenterSliderBar: View {
    @Bindable var store: LifesaverStore
    @Namespace private var sliderNamespace

    public init(store: LifesaverStore) {
        self.store = store
    }

    private var currentIndex: Int {
        switch store.selectedGoalTab {
        case .longTerm: return 0
        case .shortTerm: return 1
        case .daily: return 2
        case .matrices: return 3
        }
    }

    public var body: some View {
        HStack(spacing: 8) {
            // Previous Stage Button
            Button(action: {
                withAnimation(ThemeTokens.smoothSpring) {
                    store.slidePrevTab()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(currentIndex > 0 ? Color.primary : Color.secondary.opacity(0.3))
                    .frame(width: 28, height: 28)
                    .background(Color.primary.opacity(currentIndex > 0 ? 0.06 : 0.02))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(currentIndex == 0)
            .help("Slide to Previous Stage (⌘←)")
            .keyboardShortcut(.leftArrow, modifiers: .command)

            // Center Sliding Capsule
            HStack(spacing: 4) {
                ForEach(GoalItem.AppStageTab.allCases) { type in
                    let isSelected = store.selectedGoalTab == type
                    let labelCount = tabCount(for: type)

                    Button(action: {
                        withAnimation(ThemeTokens.smoothSpring) {
                            store.selectedGoalTab = type
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: type.icon)
                                .font(.system(size: 11, weight: .semibold))

                            Text(type.shortName)
                                .font(.system(size: 12, weight: isSelected ? .bold : .medium))

                            // Counter pill
                            Text(labelCount)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    isSelected
                                    ? Color.white.opacity(0.25)
                                    : Color.primary.opacity(0.06)
                                )
                                .clipShape(Capsule())
                        }
                        .foregroundStyle(isSelected ? Color.white : Color.primary.opacity(0.85))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(accentGradient(for: type))
                                    .matchedGeometryEffect(id: "activePill", in: sliderNamespace)
                                    .shadow(color: Color.black.opacity(0.12), radius: 2, y: 1)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(Color.primary.opacity(0.06))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )

            // Next Stage Button
            Button(action: {
                withAnimation(ThemeTokens.smoothSpring) {
                    store.slideNextTab()
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(currentIndex < 3 ? Color.primary : Color.secondary.opacity(0.3))
                    .frame(width: 28, height: 28)
                    .background(Color.primary.opacity(currentIndex < 3 ? 0.06 : 0.02))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(currentIndex == 3)
            .help("Slide to Next Stage (⌘→)")
            .keyboardShortcut(.rightArrow, modifiers: .command)
        }
    }

    private func tabCount(for type: GoalItem.AppStageTab) -> String {
        switch type {
        case .longTerm:
            return "\(store.fetchGoals(for: .longTerm).count)"
        case .shortTerm:
            return "\(store.fetchGoals(for: .shortTerm).count)"
        case .daily:
            return "\(store.allDailyTasks().count)"
        case .matrices:
            let mins = store.totalLoggedMinutesThisWeek()
            let h = mins / 60
            return h > 0 ? "\(h)h" : "\(mins)m"
        }
    }

    private func accentColor(for type: GoalItem.AppStageTab) -> Color {
        switch type {
        case .longTerm: return ThemeTokens.structuredCoral
        case .shortTerm: return ThemeTokens.structuredBlue
        case .daily: return ThemeTokens.structuredGreen
        case .matrices: return ThemeTokens.structuredPurple
        }
    }

    private func accentGradient(for type: GoalItem.AppStageTab) -> LinearGradient {
        switch type {
        case .longTerm:
            return LinearGradient(
                colors: [ThemeTokens.structuredCoral, ThemeTokens.structuredCoralDark],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .shortTerm:
            return LinearGradient(
                colors: [ThemeTokens.structuredBlue, Color(red: 0.12, green: 0.55, blue: 0.85)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .daily:
            return LinearGradient(
                colors: [ThemeTokens.structuredGreen, Color(red: 0.15, green: 0.70, blue: 0.45)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .matrices:
            return LinearGradient(
                colors: [ThemeTokens.structuredPurple, Color(red: 0.40, green: 0.45, blue: 0.90)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

