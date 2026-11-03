import SwiftUI
import SwiftData

public struct AppShellView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var store: LifesaverStore?

    public init() {}

    public var body: some View {
        Group {
            if let store {
                MainGoalAppView(store: store)
            } else {
                ProgressView("Loading Lifesaver...")
            }
        }
        .tint(ThemeTokens.structuredCoral)
        .onAppear {
            if store == nil {
                store = LifesaverStore(modelContext: modelContext)
            }
        }
        #if os(macOS)
        .frame(minWidth: 800, minHeight: 600)
        #endif
    }
}

public struct MainGoalAppView: View {
    @Bindable var store: LifesaverStore
    @State private var isSettingsPresented: Bool = false

    public init(store: LifesaverStore) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Unified Top Bar with Top-Center Navigation
            HStack(alignment: .center) {
                // Left: Lifesaver Brand Pill
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [ThemeTokens.structuredCoral, ThemeTokens.structuredCoralDark],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 24, height: 24)

                        Image(systemName: "lifepreserver.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.white)
                    }

                    Text("Lifesaver")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.primary)
                }
                .frame(minWidth: 160, alignment: .leading)

                Spacer()

                // Top Center Navigation: The Sliding Capsule
                TopCenterSliderBar(store: store)

                Spacer()

                // Right: Quick + Goal Action Button & Settings
                HStack(spacing: 8) {
                    StreakPillView(store: store)

                    Button(action: {
                        store.newGoalTargetType = store.selectedGoalTab
                        store.isNewGoalSheetPresented = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                            Text("Goal")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(Color.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .help("Add New Goal")

                    // Settings Button
                    Button(action: {
                        isSettingsPresented = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.secondary)
                            .frame(width: 28, height: 28)
                            .background(Color.primary.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Settings & iCloud Sync (⌘,)")
                    .keyboardShortcut(",", modifiers: .command)
                }
                .frame(minWidth: 160, alignment: .trailing)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(ThemeTokens.cardBackground)
            .overlay(Divider(), alignment: .bottom)

            // Master Left-to-Right Slider (Long-Term ⟷ Short-Term ⟷ Daily)
            GoalFlowContainerView(store: store)
        }
        .sheet(isPresented: $store.isNewGoalSheetPresented) {
            NewGoalSheetView(store: store)
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(store: store)
        }
    }
}
