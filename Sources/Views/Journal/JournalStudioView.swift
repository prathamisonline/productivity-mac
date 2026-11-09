import SwiftUI
import SwiftData

public struct JournalStudioView: View {
    @Bindable var store: LifesaverStore

    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date.now)
    @State private var editorTitle: String = ""
    @State private var editorBody: String = ""
    @State private var searchText: String = ""
    @State private var showDatePickerPopover: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var isSuppressingAutoSave: Bool = false

    public init(store: LifesaverStore) {
        self.store = store
    }

    private var hasCurrentEntryText: Bool {
        !editorTitle.trimmingCharacters(in: .whitespaces).isEmpty ||
        !editorBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var body: some View {
        let _ = store.revision
        let allDays = store.allJournalDays()
        let groupedMonths = groupDaysByMonth(days: allDays)

        HStack(spacing: 0) {
            // MARK: - Left Pane: Timeline Archive Feed
            VStack(spacing: 0) {
                // Top Toolbar (Search, + Entry)
                sidebarHeader

                Divider()

                // Entry List Feed
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        // If today has no entry yet, provide an anchor card at top
                        if !hasEntryForToday(allDays: allDays) && searchText.isEmpty {
                            todayStarterSection
                        }

                        if groupedMonths.isEmpty && !searchText.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 24))
                                    .foregroundStyle(Color.secondary)
                                Text("No thoughts matching '\(searchText)'")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                        } else {
                            ForEach(groupedMonths) { group in
                                VStack(alignment: .leading, spacing: 8) {
                                    // Month Header (e.g. "November 2026")
                                    Text(group.monthTitle)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(Color.primary)
                                        .padding(.horizontal, 4)

                                    VStack(spacing: 8) {
                                        ForEach(group.days) { day in
                                            let isSelected = Calendar.current.isDate(day.date, inSameDayAs: selectedDate)
                                            JournalEntryCardView(
                                                day: day,
                                                isSelected: isSelected,
                                                onSelect: {
                                                    selectDay(day.date)
                                                },
                                                onDelete: {
                                                    deleteEntry(for: day)
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(14)
                }
            }
            .frame(width: 320)
            .background(ThemeTokens.cardBackground.opacity(0.6))
            .overlay(Divider(), alignment: .trailing)

            // MARK: - Right Pane: Expansive Day Writing Canvas
            VStack(spacing: 0) {
                // Top Canvas Bar
                canvasHeader

                Divider()

                // Writing Area
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Title Input
                        TextField("Title your thought or reflection...", text: $editorTitle)
                            .font(.system(size: 24, weight: .bold))
                            .textFieldStyle(.plain)
                            .foregroundStyle(Color.primary)
                            .onChange(of: editorTitle) { _, _ in
                                autoSaveCurrentEntry()
                            }

                        // Body TextEditor
                        ZStack(alignment: .topLeading) {
                            if editorBody.isEmpty {
                                Text("Write freely about your day, lessons learned, breakthrough ideas, or personal reflections...")
                                    .font(.system(size: 15))
                                    .lineSpacing(6)
                                    .foregroundStyle(Color.secondary.opacity(0.6))
                                    .padding(.top, 2)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }

                            TextEditor(text: $editorBody)
                                .font(.system(size: 15))
                                .lineSpacing(6)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .frame(minHeight: 460)
                                .onChange(of: editorBody) { _, _ in
                                    autoSaveCurrentEntry()
                                }
                        }
                    }
                    .padding(28)
                }

                Divider()

                // Canvas Footer Status
                canvasFooter
            }
            .background(ThemeTokens.canvasBackground)
        }
        .onAppear {
            loadDay(selectedDate)
        }
        .confirmationDialog(
            "Delete Journal Entry?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Entry", role: .destructive) {
                performDeleteCurrentEntry()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete all thoughts written for \(formattedSelectedDate)? This cannot be undone.")
        }
    }

    // MARK: - 1. Sidebar Header
    private var sidebarHeader: some View {
        HStack(spacing: 8) {
            // Search Field (Full Width)
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.secondary)

                TextField("Search notes...", text: $searchText)
                    .font(.system(size: 12))
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(12)
    }

    // MARK: - 2. Today Starter Section
    private var todayStarterSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TODAY")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.secondary)
                .tracking(0.5)

            let today = store.fetchOrCreateDay(for: Date.now)
            JournalEntryCardView(
                day: today,
                isSelected: Calendar.current.isDate(selectedDate, inSameDayAs: Date.now),
                onSelect: {
                    selectDay(Date.now)
                }
            )
        }
    }

    // MARK: - 3. Canvas Header
    private var canvasHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            // Day Navigation: [ < ] [ > ] Date [ Today ]
            HStack(spacing: 8) {
                // Previous Day
                Button(action: { stepDay(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.secondary)
                        .frame(width: 26, height: 26)
                        .background(Color.primary.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .help("Previous Day")

                // Next Day
                Button(action: { stepDay(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.secondary)
                        .frame(width: 26, height: 26)
                        .background(Color.primary.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .help("Next Day")

                // Full Formatted Date
                Text(formattedSelectedDate)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.primary)

                // Quick Today pill if looking at another date
                if !Calendar.current.isDateInToday(selectedDate) {
                    Button("Today") {
                        withAnimation(ThemeTokens.quickSpring) {
                            selectDay(Date.now)
                        }
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ThemeTokens.structuredBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(ThemeTokens.structuredBlue.opacity(0.12))
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            // Actions: [ Calendar Popover ] [ Trash Button ] [ ... Menu ]
            HStack(spacing: 8) {
                // Sleek Custom Calendar Popover Button
                Button(action: { showDatePickerPopover.toggle() }) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(showDatePickerPopover ? ThemeTokens.structuredBlue : Color.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .help("Calendar Picker")
                .popover(isPresented: $showDatePickerPopover, arrowEdge: .top) {
                    let entryDates = Set(store.allJournalDays().map { Calendar.current.startOfDay(for: $0.date) })
                    JournalCalendarPickerView(
                        selectedDate: $selectedDate,
                        datesWithEntries: entryDates,
                        onSelect: { chosenDate in
                            selectDay(chosenDate)
                            showDatePickerPopover = false
                        }
                    )
                }

                // Delete Entry Button (Prominent & Safe)
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(hasCurrentEntryText ? Color.red.opacity(0.9) : Color.secondary.opacity(0.35))
                        .frame(width: 28, height: 28)
                        .background(hasCurrentEntryText ? Color.red.opacity(0.08) : Color.primary.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .disabled(!hasCurrentEntryText)
                .help(hasCurrentEntryText ? "Delete this entry" : "No content to delete")

                // More Options Menu
                Menu {
                    Button("Copy All Text") {
                        copyToClipboard()
                    }
                    if hasCurrentEntryText {
                        Divider()
                        Button("Delete Entry", role: .destructive) {
                            showDeleteConfirmation = true
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .menuStyle(.borderlessButton)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(ThemeTokens.cardBackground)
    }

    // MARK: - 4. Canvas Footer
    private var canvasFooter: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "book.closed")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.secondary)

                Text("Journal")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.secondary)

                Text("•")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.secondary.opacity(0.6))

                Text("\(currentWordCount) words")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.primary)
            }

            Spacer()

            HStack(spacing: 5) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)

                Text("Auto-saved to iCloud")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.secondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(ThemeTokens.cardBackground)
    }

    // MARK: - Helpers & Data Logic
    private struct MonthGroup: Identifiable {
        let id: String
        let monthTitle: String
        let days: [PlanDay]
    }

    private func groupDaysByMonth(days: [PlanDay]) -> [MonthGroup] {
        let filtered = days.filter { day in
            if searchText.isEmpty { return true }
            let lower = searchText.lowercased()
            return day.reflectionNotes.lowercased().contains(lower) || day.fullFormattedDate.lowercased().contains(lower)
        }

        var groups: [String: [PlanDay]] = [:]
        var keysOrder: [String] = []

        for d in filtered {
            let key = d.monthYearString
            if groups[key] == nil {
                keysOrder.append(key)
                groups[key] = []
            }
            groups[key]?.append(d)
        }

        return keysOrder.compactMap { key in
            guard let items = groups[key] else { return nil }
            return MonthGroup(id: key, monthTitle: key, days: items)
        }
    }

    private func hasEntryForToday(allDays: [PlanDay]) -> Bool {
        let today = Calendar.current.startOfDay(for: Date.now)
        return allDays.contains { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    private var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: selectedDate)
    }

    private var currentWordCount: Int {
        let combined = "\(editorTitle) \(editorBody)"
        return combined.split { $0.isWhitespace || $0.isNewline }.count
    }

    private func stepDay(by offset: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: offset, to: selectedDate) {
            selectDay(newDate)
        }
    }

    private func selectDay(_ date: Date) {
        let normalized = Calendar.current.startOfDay(for: date)
        if normalized != selectedDate {
            autoSaveCurrentEntry()
            selectedDate = normalized
            loadDay(normalized)
        }
    }

    private func loadDay(_ date: Date) {
        isSuppressingAutoSave = true
        let day = store.fetchOrCreateDay(for: date)
        let raw = day.reflectionNotes

        let lines = raw.components(separatedBy: .newlines)
        if let first = lines.first, first.hasPrefix("# ") {
            editorTitle = String(first.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            let rest = lines.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            editorBody = rest
        } else if let first = lines.first, !first.isEmpty && lines.count > 1 {
            editorTitle = first.trimmingCharacters(in: .whitespaces)
            let rest = lines.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            editorBody = rest
        } else {
            editorTitle = ""
            editorBody = raw
        }

        DispatchQueue.main.async {
            self.isSuppressingAutoSave = false
        }
    }

    private func autoSaveCurrentEntry() {
        guard !isSuppressingAutoSave else { return }

        let cleanTitle = editorTitle.trimmingCharacters(in: .whitespaces)
        let cleanBody = editorBody.trimmingCharacters(in: .whitespacesAndNewlines)

        let fullText: String
        if !cleanTitle.isEmpty && !cleanBody.isEmpty {
            fullText = "# \(cleanTitle)\n\n\(cleanBody)"
        } else if !cleanTitle.isEmpty {
            fullText = "# \(cleanTitle)"
        } else {
            fullText = cleanBody
        }

        store.saveJournalText(for: selectedDate, fullText: fullText)
    }

    private func performDeleteCurrentEntry() {
        isSuppressingAutoSave = true
        let dateToDelete = selectedDate

        editorTitle = ""
        editorBody = ""
        store.deleteJournal(for: dateToDelete)

        // Find next remaining day in timeline or fall back to today
        let remainingDays = store.allJournalDays()
        if let nextEntry = remainingDays.first(where: { !Calendar.current.isDate($0.date, inSameDayAs: dateToDelete) }) {
            selectedDate = Calendar.current.startOfDay(for: nextEntry.date)
        } else {
            selectedDate = Calendar.current.startOfDay(for: Date.now)
        }
        loadDay(selectedDate)
    }

    private func deleteEntry(for day: PlanDay) {
        if Calendar.current.isDate(day.date, inSameDayAs: selectedDate) {
            performDeleteCurrentEntry()
        } else {
            store.deleteJournalText(for: day)
        }
    }

    private func copyToClipboard() {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let combined = editorTitle.isEmpty ? editorBody : "# \(editorTitle)\n\n\(editorBody)"
        pasteboard.setString(combined, forType: .string)
        #endif
    }
}
