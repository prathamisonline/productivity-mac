import SwiftUI

public struct GoalFlowContainerView: View {
    @Bindable var store: LifesaverStore
    @GestureState private var dragOffset: CGFloat = 0

    public init(store: LifesaverStore) {
        self.store = store
    }

    private var activeIndex: Int {
        switch store.selectedGoalTab {
        case .longTerm: return 0
        case .shortTerm: return 1
        case .daily: return 2
        case .matrices: return 3
        }
    }

    public var body: some View {
        GeometryReader { geo in
            let width = geo.size.width

            VStack(spacing: 0) {
                // The Horizontal Slider
                HStack(spacing: 0) {
                    LongTermStageView(store: store)
                        .frame(width: width)

                    ShortTermStageView(store: store)
                        .frame(width: width)

                    DailyStageView(store: store)
                        .frame(width: width)

                    MatricesStageView(store: store)
                        .frame(width: width)
                }
                .offset(x: -CGFloat(activeIndex) * width + dragOffset)
                .animation(ThemeTokens.smoothSpring, value: activeIndex)
                .gesture(
                    DragGesture(minimumDistance: 25)
                        .updating($dragOffset) { value, state, _ in
                            // Resistance on bounds
                            let translation = value.translation.width
                            if (activeIndex == 0 && translation > 0) || (activeIndex == 3 && translation < 0) {
                                state = translation * 0.3
                            } else {
                                state = translation
                            }
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 80
                            let velocity = value.predictedEndTranslation.width - value.translation.width

                            if value.translation.width < -threshold || velocity < -200 {
                                withAnimation(ThemeTokens.smoothSpring) {
                                    store.slideNextTab()
                                }
                            } else if value.translation.width > threshold || velocity > 200 {
                                withAnimation(ThemeTokens.smoothSpring) {
                                    store.slidePrevTab()
                                }
                            }
                        }
                )

                // Bottom Stage Progression Track
                bottomStageProgressionBar
            }
        }
    }

    // MARK: - Bottom Stage Progression Track
    private var bottomStageProgressionBar: some View {
        HStack(spacing: 14) {
            stageNode(
                index: 0,
                type: .longTerm,
                number: "1",
                label: "Long-Term Vision",
                color: ThemeTokens.structuredCoral
            )

            stageConnector(isActive: activeIndex >= 1, color: ThemeTokens.structuredBlue)

            stageNode(
                index: 1,
                type: .shortTerm,
                number: "2",
                label: "Short-Term Execution",
                color: ThemeTokens.structuredBlue
            )

            stageConnector(isActive: activeIndex >= 2, color: ThemeTokens.structuredGreen)

            stageNode(
                index: 2,
                type: .daily,
                number: "3",
                label: "Daily Action",
                color: ThemeTokens.structuredGreen
            )

            stageConnector(isActive: activeIndex >= 3, color: ThemeTokens.structuredPurple)

            stageNode(
                index: 3,
                type: .matrices,
                number: "4",
                label: "Matrices & Analytics",
                color: ThemeTokens.structuredPurple
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(ThemeTokens.cardBackground.opacity(0.85))
        .overlay(Divider(), alignment: .top)
    }

    @ViewBuilder
    private func stageNode(index: Int, type: GoalItem.AppStageTab, number: String, label: String, color: Color) -> some View {
        let isCurrent = activeIndex == index

        Button(action: {
            withAnimation(ThemeTokens.smoothSpring) {
                store.selectedGoalTab = type
            }
        }) {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isCurrent ? color : Color.primary.opacity(0.06))
                        .frame(width: 20, height: 20)

                    Text(number)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(isCurrent ? Color.white : Color.secondary)
                }

                Text(label)
                    .font(.system(size: 12, weight: isCurrent ? .bold : .medium))
                    .foregroundStyle(isCurrent ? Color.primary : Color.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isCurrent ? color.opacity(0.08) : Color.clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func stageConnector(isActive: Bool, color: Color) -> some View {
        HStack(spacing: 3) {
            Rectangle()
                .fill(isActive ? color.opacity(0.6) : Color.primary.opacity(0.12))
                .frame(width: 24, height: 2)

            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(isActive ? color : Color.primary.opacity(0.2))
        }
    }
}

