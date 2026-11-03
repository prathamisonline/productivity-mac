import SwiftUI
import SwiftData
#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: LifesaverStore
    @State private var syncManager = iCloudDriveSyncManager.shared
    @AppStorage("autoSyncOnLaunch") private var autoSyncOnLaunch: Bool = true
    @State private var showResetConfirmation: Bool = false
    @State private var toastMessage: String? = nil

    public init(store: LifesaverStore) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Settings")
                        .font(.system(size: 20, weight: .bold))
                    Text("iCloud Sync, Preferences, and Data Management")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                }

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .font(.system(size: 13, weight: .semibold))
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
            }
            .padding(20)
            .overlay(Divider(), alignment: .bottom)

            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - 1. iCloud Sync & Backup Section
                    iCloudSyncSection

                    // MARK: - 2. Navigation & Workflow
                    navigationWorkflowSection

                    // MARK: - 3. Data & Storage Overview
                    dataOverviewSection

                    // MARK: - 4. About Lifesaver
                    aboutSection
                }
                .padding(24)
            }

            // Bottom Toast Notification
            if let toastMessage {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.green)
                    Text(toastMessage)
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.08))
                .clipShape(Capsule())
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(width: 580, height: 620)
        .background(ThemeTokens.canvasBackground)
        .onAppear {
            #if os(macOS)
            if autoSyncOnLaunch && syncManager.lastSyncDate == nil {
                syncManager.autoSyncLocalMacCloudDocs(store: store)
            }
            #endif
        }
        .confirmationDialog(
            "Reset & Reseed Sample Data?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset & Reseed Goals", role: .destructive) {
                resetAndReseed()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all current goals and tasks, and restore the initial 3-tier starter roadmap.")
        }
    }

    // MARK: - iCloud Sync Section
    private var iCloudSyncSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "icloud.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(ThemeTokens.structuredBlue)

                VStack(alignment: .leading, spacing: 1) {
                    Text("iCloud Sync & Cloud Backup")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.primary)
                    Text("Seamlessly backup and synchronize your goals and tasks across your devices.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                }
            }

            // Status Card
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(syncManager.isSyncing ? Color.orange : (syncManager.lastSyncDate != nil ? Color.green : Color.secondary))
                            .frame(width: 8, height: 8)

                        Text(syncManager.isSyncing ? "Syncing..." : (syncManager.lastSyncDate != nil ? "iCloud Drive Connected" : "Local Database"))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.primary)
                    }

                    Spacer()

                    if let lastSync = syncManager.lastSyncDate {
                        Text("Last synced: \(lastSync.formatted(date: .omitted, time: .shortened))")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.secondary)
                    }
                }

                Text(syncManager.syncStatusMessage)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.secondary)

                Divider()

                // Actions Row
                HStack(spacing: 10) {
                    // Sync Now Button
                    Button(action: triggerManualSync) {
                        HStack(spacing: 6) {
                            if syncManager.isSyncing {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            Text("Sync Now")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(ThemeTokens.structuredBlue)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(syncManager.isSyncing)

                    // Export Backup File Button
                    Button(action: exportBackupFile) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.down.doc")
                                .font(.system(size: 11))
                            Text("Export Backup")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(Color.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    // Restore Backup File Button
                    Button(action: importBackupFile) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.up.doc")
                                .font(.system(size: 11))
                            Text("Restore Backup")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(Color.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Toggle("Automatically sync with iCloud on startup", isOn: $autoSyncOnLaunch)
                    .font(.system(size: 12))
                    .padding(.top, 4)
            }
            .padding(16)
            .background(ThemeTokens.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
    }

    // MARK: - Navigation & Workflow Section
    private var navigationWorkflowSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("WORKFLOW & SHORTCUTS")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.secondary)
                .tracking(0.5)

            VStack(spacing: 10) {
                HStack {
                    Text("Default Starting Stage")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Picker("", selection: $store.selectedGoalTab) {
                        ForEach(GoalItem.AppStageTab.allCases) { type in
                            Text(type.shortName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 290)
                }

                Divider()

                // Keyboard Shortcuts Reference
                VStack(spacing: 6) {
                    shortcutRow(keys: "⌘ ←", label: "Slide to Previous Stage")
                    shortcutRow(keys: "⌘ →", label: "Slide to Next Stage")
                    shortcutRow(keys: "⌘ ,", label: "Open Settings & iCloud Sync")
                }
            }
            .padding(16)
            .background(ThemeTokens.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
    }

    private func shortcutRow(keys: String, label: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color.secondary)
            Spacer()
            Text(keys)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.primary)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.primary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    // MARK: - Data Overview Section
    private var dataOverviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("DATA & STORAGE")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.secondary)
                .tracking(0.5)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    statBox(
                        title: "Long-Term",
                        count: store.allLongTermGoals.count,
                        color: ThemeTokens.structuredCoral
                    )
                    statBox(
                        title: "Short-Term",
                        count: store.allShortTermGoals.count,
                        color: ThemeTokens.structuredBlue
                    )
                    statBox(
                        title: "Daily",
                        count: store.allDailyGoals.count,
                        color: ThemeTokens.structuredGreen
                    )
                }

                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reset Starter Data")
                            .font(.system(size: 13, weight: .medium))
                        Text("Restore the default sample roadmap goals & tasks.")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.secondary)
                    }

                    Spacer()

                    Button(role: .destructive, action: {
                        showResetConfirmation = true
                    }) {
                        Text("Reset & Reseed")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.08))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(ThemeTokens.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
    }

    private func statBox(title: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - About Section
    private var aboutSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Lifesaver v2.0")
                    .font(.system(size: 12, weight: .bold))
                Text("Native 3-Tier Goal & Task Execution Engine")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.secondary)
            }
            Spacer()
            Text("Pure SwiftData")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(ThemeTokens.structuredCoral)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(ThemeTokens.structuredCoral.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Actions
    private func triggerManualSync() {
        #if os(macOS)
        let success = syncManager.autoSyncLocalMacCloudDocs(store: store)
        showToast(success ? "iCloud Sync Complete!" : "Sync Failed")
        #endif
    }

    private func exportBackupFile() {
        #if os(macOS)
        guard let data = syncManager.exportJSONData(store: store) else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.json]
        panel.nameFieldStringValue = "LifesaverBackup-\(Date.now.formatted(date: .numeric, time: .omitted)).json"
        panel.prompt = "Export Backup"

        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url, options: .atomic)
            showToast("Backup exported successfully!")
        }
        #endif
    }

    private func importBackupFile() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.json]
        panel.allowsMultipleSelection = false
        panel.prompt = "Restore Backup"

        if panel.runModal() == .OK, let url = panel.url {
            if let data = try? Data(contentsOf: url) {
                syncManager.importJSONData(data, into: store)
                showToast("Backup restored successfully!")
            }
        }
        #endif
    }

    private func resetAndReseed() {
        // Clear all goals and tasks
        let context = store.modelContext
        let goals = (try? context.fetch(FetchDescriptor<GoalItem>())) ?? []
        for g in goals { context.delete(g) }
        let tasks = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []
        for t in tasks { context.delete(t) }
        try? context.save()
        store.seedInitialGoalsIfNeeded()
        showToast("Roadmap reseeded!")
    }

    private func showToast(_ msg: String) {
        withAnimation(ThemeTokens.quickSpring) {
            toastMessage = msg
        }
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(ThemeTokens.quickSpring) {
                if toastMessage == msg {
                    toastMessage = nil
                }
            }
        }
    }
}

