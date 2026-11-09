import SwiftUI
import SwiftData

public struct AppShellView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
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
    @State private var isSyncingAnim: Bool = false

    public init(store: LifesaverStore) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Unified Top Bar with Top-Center Navigation
            HStack(alignment: .center) {
                // Left: Lifesaver Brand Pill + Workspace Switcher
                HStack(spacing: 12) {
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

                    // Workspace Switcher (Goals vs. Journal)
                    HStack(spacing: 2) {
                        workspaceTabButton(mode: .goals, label: "Goals", icon: "target", shortcut: "1")
                        workspaceTabButton(mode: .journal, label: "Journal", icon: "book.closed.fill", shortcut: "2")
                    }
                    .padding(3)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                }

                Spacer()

                // Top Center Navigation
                if store.activeWorkspaceMode == .goals {
                    TopCenterSliderBar(store: store)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(ThemeTokens.structuredBlue)
                        Text("Daily Journal")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.primary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(Capsule())
                }

                Spacer()

                // Right: Quick + Goal Action Button & Settings
                HStack(spacing: 8) {
                    StreakPillView(store: store)

                    if store.activeWorkspaceMode == .goals {
                        Button(action: {
                            store.newGoalTargetType = store.selectedGoalTab.goalType ?? .daily
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
                    }

                    // Manual Sync Button
                    Button(action: {
                        performManualSync()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 11, weight: .bold))
                                .rotationEffect(.degrees(isSyncingAnim ? 360 : 0))
                                .animation(isSyncingAnim ? .linear(duration: 0.85).repeatForever(autoreverses: false) : .default, value: isSyncingAnim)

                            if let lastSync = iCloudDriveSyncManager.shared.lastSyncDate {
                                Text(lastSync.formatted(date: .omitted, time: .shortened))
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundStyle(Color.secondary)
                            } else {
                                Text("Sync")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .help("Manual iCloud Sync (pull remote & push local)")

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

            // Main Workspace View (Goals vs. Journal)
            Group {
                if store.activeWorkspaceMode == .goals {
                    GoalFlowContainerView(store: store)
                } else {
                    JournalStudioView(store: store)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $store.isNewGoalSheetPresented) {
            NewGoalSheetView(store: store)
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(store: store)
        }
    }

    @ViewBuilder
    private func workspaceTabButton(
        mode: LifesaverStore.WorkspaceMode,
        label: String,
        icon: String,
        shortcut: KeyEquivalent
    ) -> some View {
        let isSelected = store.activeWorkspaceMode == mode

        Button(action: {
            withAnimation(ThemeTokens.smoothSpring) {
                store.activeWorkspaceMode = mode
            }
        }) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                Text(label)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
            }
            .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                isSelected
                ? Color.primary.opacity(0.10)
                : Color.clear
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(shortcut, modifiers: .command)
    }

    private func performManualSync() {
        withAnimation { isSyncingAnim = true }
        Task { @MainActor in
            _ = iCloudDriveSyncManager.shared.syncNow(store: store)
            try? await Task.sleep(for: .milliseconds(700))
            withAnimation { isSyncingAnim = false }
        }
    }
}
