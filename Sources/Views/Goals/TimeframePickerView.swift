import SwiftUI

public struct TimeframePickerView: View {
    public let goalType: GoalItem.GoalType
    public let accentColor: Color
    @Binding public var targetTimeframe: String
    @Binding public var targetDate: Date?

    @State private var selectionMode: SelectionMode = .presets
    @State private var internalDate: Date = Date.now

    public enum SelectionMode: String, CaseIterable, Identifiable {
        case presets = "Presets"
        case exactDate = "Exact Date"
        case custom = "Custom"

        public var id: String { rawValue }

        public var icon: String {
            switch self {
            case .presets: return "slider.horizontal.3"
            case .exactDate: return "calendar"
            case .custom: return "pencil"
            }
        }
    }

    public init(
        goalType: GoalItem.GoalType,
        accentColor: Color,
        targetTimeframe: Binding<String>,
        targetDate: Binding<Date?>
    ) {
        self.goalType = goalType
        self.accentColor = accentColor
        self._targetTimeframe = targetTimeframe
        self._targetDate = targetDate

        if let existing = targetDate.wrappedValue {
            _internalDate = State(initialValue: existing)
            _selectionMode = State(initialValue: .exactDate)
        } else if !targetTimeframe.wrappedValue.isEmpty {
            _selectionMode = State(initialValue: .presets)
        }
    }

    private var presets: [TimeframePreset] {
        switch goalType {
        case .longTerm:
            let year = Calendar.current.component(.year, from: Date.now)
            return [
                TimeframePreset(title: "1 Year (\(year + 1))", monthsOffset: 12),
                TimeframePreset(title: "2 Years (\(year + 2))", monthsOffset: 24),
                TimeframePreset(title: "3-Year Horizon", monthsOffset: 36),
                TimeframePreset(title: "5-Year Vision", monthsOffset: 60),
                TimeframePreset(title: "10-Year Macro", monthsOffset: 120),
                TimeframePreset(title: "Ongoing / North Star", monthsOffset: nil)
            ]

        case .shortTerm:
            let quarter = (Calendar.current.component(.month, from: Date.now) - 1) / 3 + 1
            return [
                TimeframePreset(title: "This Week", daysOffset: 7),
                TimeframePreset(title: "Next 2 Weeks (Sprint)", daysOffset: 14),
                TimeframePreset(title: "This Month", monthsOffset: 1),
                TimeframePreset(title: "Next Month", monthsOffset: 2),
                TimeframePreset(title: "This Quarter (Q\(quarter))", monthsOffset: 3),
                TimeframePreset(title: "Next Quarter (Q\(quarter == 4 ? 1 : quarter + 1))", monthsOffset: 6)
            ]

        case .daily:
            return [
                TimeframePreset(title: "Today", daysOffset: 0),
                TimeframePreset(title: "Tomorrow", daysOffset: 1),
                TimeframePreset(title: "This Weekend", daysOffset: daysUntilWeekend()),
                TimeframePreset(title: "End of Week", daysOffset: daysUntilEndOfWeek())
            ]
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with Active Timeframe Preview
            HStack {
                Text("TIMEFRAME & HORIZON")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.secondary)

                Spacer()

                if !targetTimeframe.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 10, weight: .bold))
                        Text(targetTimeframe)
                            .font(.system(size: 11, weight: .bold))

                        Button(action: {
                            withAnimation(ThemeTokens.quickSpring) {
                                targetTimeframe = ""
                                targetDate = nil
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(accentColor.opacity(0.12))
                    .clipShape(Capsule())
                }
            }

            // Mode Selector Pill Bar
            HStack(spacing: 2) {
                ForEach(SelectionMode.allCases) { mode in
                    let isSelected = selectionMode == mode
                    Button(action: {
                        withAnimation(ThemeTokens.quickSpring) {
                            selectionMode = mode
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 10, weight: .bold))
                            Text(mode.rawValue)
                                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                        }
                        .foregroundStyle(isSelected ? Color.white : Color.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(isSelected ? accentColor : Color.clear)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(2)
            .background(Color.primary.opacity(0.04))
            .clipShape(Capsule())

            // Mode Specific Content
            switch selectionMode {
            case .presets:
                presetsGrid

            case .exactDate:
                exactDatePicker

            case .custom:
                customInputField
            }
        }
    }

    // MARK: - Presets Grid
    private var presetsGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
            ForEach(presets) { preset in
                let isSelected = targetTimeframe == preset.title
                Button(action: {
                    withAnimation(ThemeTokens.quickSpring) {
                        targetTimeframe = preset.title
                        if let days = preset.daysOffset {
                            targetDate = Calendar.current.date(byAdding: .day, value: days, to: Date.now)
                        } else if let months = preset.monthsOffset {
                            targetDate = Calendar.current.date(byAdding: .month, value: months, to: Date.now)
                        } else {
                            targetDate = nil
                        }
                    }
                }) {
                    Text(preset.title)
                        .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity)
                        .background(isSelected ? accentColor : Color.primary.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(isSelected ? Color.clear : Color.primary.opacity(0.06), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Exact Date Picker
    private var exactDatePicker: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                DatePicker(
                    "Target Date",
                    selection: $internalDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .onChange(of: internalDate) { _, newDate in
                    applyDate(newDate)
                }

                // Days relative counter
                let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date.now), to: Calendar.current.startOfDay(for: internalDate)).day ?? 0
                Text(daysString(for: days))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(days < 0 ? Color.red : accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(Capsule())

                Spacer()
            }

            // Quick Date Jump Buttons
            HStack(spacing: 6) {
                quickJumpButton(label: "+1 Week", days: 7)
                quickJumpButton(label: "+1 Month", months: 1)
                quickJumpButton(label: "+3 Months", months: 3)
                quickJumpButton(label: "+1 Year", months: 12)
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .onAppear {
            if let existing = targetDate {
                internalDate = existing
            } else {
                applyDate(internalDate)
            }
        }
    }

    private func quickJumpButton(label: String, days: Int? = nil, months: Int? = nil) -> some View {
        Button(action: {
            withAnimation(ThemeTokens.quickSpring) {
                if let days {
                    if let newDate = Calendar.current.date(byAdding: .day, value: days, to: internalDate) {
                        internalDate = newDate
                        applyDate(newDate)
                    }
                } else if let months {
                    if let newDate = Calendar.current.date(byAdding: .month, value: months, to: internalDate) {
                        internalDate = newDate
                        applyDate(newDate)
                    }
                }
            }
        }) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.04))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func applyDate(_ date: Date) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        targetTimeframe = formatter.string(from: date)
        targetDate = date
    }

    private func daysString(for days: Int) -> String {
        if days == 0 {
            return "Due Today"
        } else if days == 1 {
            return "Due Tomorrow"
        } else if days > 1 {
            return "in \(days) days"
        } else {
            return "\(abs(days))d overdue"
        }
    }

    // MARK: - Custom Freeform Input
    private var customInputField: some View {
        HStack(spacing: 8) {
            Image(systemName: "pencil")
                .font(.system(size: 12))
                .foregroundStyle(Color.secondary)

            TextField("e.g. Q4 2027, Before Graduation, Post-Launch...", text: $targetTimeframe)
                .textFieldStyle(.plain)
                .font(.system(size: 13))

            if !targetTimeframe.isEmpty {
                Button(action: { targetTimeframe = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // Helpers
    private func daysUntilWeekend() -> Int {
        let weekday = Calendar.current.component(.weekday, from: Date.now)
        let saturday = 7
        return (saturday - weekday + 7) % 7
    }

    private func daysUntilEndOfWeek() -> Int {
        let weekday = Calendar.current.component(.weekday, from: Date.now)
        let sunday = 1
        return (sunday - weekday + 7) % 7
    }
}

public struct TimeframePreset: Identifiable {
    public var id: String { title }
    public let title: String
    public var daysOffset: Int? = nil
    public var monthsOffset: Int? = nil

    public init(title: String, daysOffset: Int? = nil, monthsOffset: Int? = nil) {
        self.title = title
        self.daysOffset = daysOffset
        self.monthsOffset = monthsOffset
    }
}

