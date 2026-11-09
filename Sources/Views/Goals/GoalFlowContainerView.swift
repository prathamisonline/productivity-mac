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
            }
        }
    }

}


