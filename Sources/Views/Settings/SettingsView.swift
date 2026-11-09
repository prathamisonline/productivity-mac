import SwiftUI
import SwiftData
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#endif

public struct SyncJSONDocument: FileDocument {
    public static var readableContentTypes: [UTType] { [.json] }
    public var data: Data

    public init(data: Data = Data()) {
        self.data = data
    }

    public init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: LifesaverStore
    @State private var syncManager = iCloudDriveSyncManager.shared
    @AppStorage("autoSyncOnLaunch") private var autoSyncOnLaunch: Bool = true
    @AppStorage("defaultStartingPage") private var defaultStartingPage: String = LifesaverStore.StartingPage.daily.rawValue
    @State private var showResetConfirmation: Bool = false
    @State private var toastMessage: String? = nil

    // Cross-platform File Exporter / Importer States
    @State private var showLinkFilePicker: Bool = false
    @State private var showRestorePicker: Bool = false
    @State private var showFileExporter: Bool = false
    @State private var exportDocument: SyncJSONDocument? = nil

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
        #if os(macOS)
        .frame(width: 580, height: 620)
        #endif
        .background(ThemeTokens.canvasBackground)
        .onAppear {
            syncManager.checkLinkedStatus()
        }
        .fileImporter(
            isPresented: $showLinkFilePicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                syncManager.saveBookmark(for: url)
                let success = syncManager.autoSync(store: store)
                showToast(success ? "iCloud Drive Linked & Synced!" : "Linked to iCloud Drive")
            case .failure(let error):
                showToast("File selection failed: \(error.localizedDescription)")
            }
        }
        .fileImporter(
            isPresented: $showRestorePicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                guard url.startAccessingSecurityScopedResource() else {
                    showToast("Permission denied to read file")
                    return
                }
                defer { url.stopAccessingSecurityScopedResource() }
                if let data = try? Data(contentsOf: url) {
                    syncManager.importJSONData(data, into: store)
                    showToast("Backup restored successfully!")
                } else {
                    showToast("Could not read backup file")
                }
            case .failure(let error):
                showToast("Restore cancelled: \(error.localizedDescription)")
            }
        }
        .fileExporter(
            isPresented: $showFileExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "LifesaverSync.json"
        ) { result in
            switch result {
            case .success:
                showToast("Backup exported successfully!")
            case .failure(let error):
                showToast("Export failed: \(error.localizedDescription)")
            }
        }
        .confirmationDialog(
            "Reset Database to Blank?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Erase All Data & Reset", role: .destructive) {
                resetToBlank()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove all goals, tasks, journal notes, and timer sessions. The app will be completely blank and nothing will be seeded.")
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
                    Text("Seamlessly synchronize your goals, tasks, and streaks across Mac and iPad.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                }
            }

            // Status Card
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(syncManager.isSyncing ? Color.orange : (syncManager.hasLinkedFile ? Color.green : Color.secondary))
                            .frame(width: 8, height: 8)

                        Text(syncManager.isSyncing ? "Syncing..." : (syncManager.hasLinkedFile ? "iCloud Drive Connected" : "Local Database"))
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

                // iPad Specific: Link iCloud Drive file card if not yet connected
                #if !os(macOS)
                if !syncManager.hasLinkedFile {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "ipad.and.arrow.forward")
                                .font(.system(size: 12))
                                .foregroundStyle(ThemeTokens.structuredBlue)
                            Text("Connect iPad to iCloud Drive")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(ThemeTokens.structuredBlue)
                        }

                        Text("Select your 'LifesaverSync.json' in iCloud Drive (Files App) to enable continuous, automatic background sync with your Mac.")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.secondary)

                        Button(action: { showLinkFilePicker = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "folder.badge.gearshape")
                                    .font(.system(size: 11))
                                Text("Choose LifesaverSync.json from iCloud Drive...")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(ThemeTokens.structuredBlue)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                    .background(ThemeTokens.structuredBlue.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    HStack {
                        Text("Linked to iCloud Drive")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.secondary)
                        Spacer()
                        Button("Relink or Change File...") {
                            showLinkFilePicker = true
                        }
                        .font(.system(size: 11))
                        .foregroundStyle(ThemeTokens.structuredBlue)
                        .buttonStyle(.plain)
                    }
                }
                #endif

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

                HStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.secondary)
                    Text("Manual Sync: data syncs between Mac and iPad only when you tap 'Sync Now'.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                }
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

            VStack(spacing: 12) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Default Starting Page")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.primary)
                        Text("View opened automatically when Lifesaver launches")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.secondary)
                    }

                    Spacer()

                    Picker("", selection: $defaultStartingPage) {
                        ForEach(LifesaverStore.StartingPage.allCases) { page in
                            Label(page.title, systemImage: page.icon)
                                .tag(page.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(minWidth: 170, alignment: .trailing)
                    .onChange(of: defaultStartingPage) { _, newRaw in
                        if let page = LifesaverStore.StartingPage(rawValue: newRaw) {
                            store.applyStartingPage(page)
                        }
                    }
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
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }

    // MARK: - Data Overview Section
    private var dataOverviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("LOCAL STORAGE & RESET")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.secondary)
                .tracking(0.5)

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Active Goal Database")
                            .font(.system(size: 13, weight: .medium))
                        Text("\(store.allLongTermGoals.count) long-term, \(store.allShortTermGoals.count) short-term goals")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.secondary)
                    }
                    Spacer()
                }

                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reset Database")
                            .font(.system(size: 13, weight: .medium))
                        Text("Erase all goals, tasks, and journal entries. Starts fresh with a blank database.")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.secondary)
                    }

                    Spacer()

                    Button(role: .destructive, action: {
                        showResetConfirmation = true
                    }) {
                        Text("Reset to Blank...")
                            .font(.system(size: 12, weight: .semibold))
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

    // MARK: - About Section
    private var aboutSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "lifepreserver.fill")
                .font(.system(size: 28))
                .foregroundStyle(ThemeTokens.structuredCoral)

            Text("Lifesaver for macOS & iPadOS")
                .font(.system(size: 14, weight: .bold))

            Text("Version 1.0 • Built with Swift 6, SwiftUI & SwiftData")
                .font(.system(size: 11))
                .foregroundStyle(Color.secondary)

            Text("Designed for deep focus, strategic horizons, and high-velocity daily execution.")
                .font(.system(size: 11))
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Link("Made with Lifesaver", destination: URL(string: "https://github.com")!)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(ThemeTokens.structuredCoral)
                .padding(.top, 4)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(ThemeTokens.structuredCoral.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Actions
    private func triggerManualSync() {
        let success = syncManager.syncNow(store: store)
        showToast(success ? "Manual Sync Complete!" : "Sync status: \(syncManager.syncStatusMessage)")
    }

    private func exportBackupFile() {
        #if os(macOS)
        guard let data = syncManager.exportJSONData(store: store) else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.json]
        panel.nameFieldStringValue = "LifesaverSync.json"
        panel.prompt = "Export Backup"

        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url, options: .atomic)
            showToast("Backup exported successfully!")
        }
        #else
        if let data = syncManager.exportJSONData(store: store) {
            exportDocument = SyncJSONDocument(data: data)
            showFileExporter = true
        } else {
            showToast("Failed to prepare backup")
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
        #else
        showRestorePicker = true
        #endif
    }

    private func resetToBlank() {
        store.resetAllData()
        showToast("All data cleared. Database is now blank.")
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
