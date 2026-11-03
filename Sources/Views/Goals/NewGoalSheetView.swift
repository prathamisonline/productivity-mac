import SwiftUI

public struct NewGoalSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: LifesaverStore

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var targetTimeframe: String = ""
    @State private var targetDate: Date? = nil
    @State private var selectedType: GoalItem.GoalType = .longTerm
    @State private var selectedColorHex: String = "#EE7E75"
    @State private var selectedIcon: String = "target"

    private let availableColors: [(name: String, hex: String)] = [
        ("Coral", "#EE7E75"),
        ("Blue", "#38BDF8"),
        ("Green", "#34D399"),
        ("Purple", "#818CF8"),
        ("Amber", "#FBBF24"),
        ("Pink", "#F472B6")
    ]

    private let availableIcons: [String] = [
        "target", "bolt.fill", "calendar", "star.fill",
        "flag.fill", "flame.fill", "laptopcomputer", "figure.run",
        "book.fill", "trophy.fill", "heart.fill", "checkmark.circle.fill"
    ]

    public init(store: LifesaverStore) {
        self.store = store
        _selectedType = State(initialValue: store.newGoalTargetType)
        _selectedColorHex = State(initialValue: Self.defaultHex(for: store.newGoalTargetType))
        _selectedIcon = State(initialValue: Self.defaultIcon(for: store.newGoalTargetType))
        _targetTimeframe = State(initialValue: Self.defaultTimeframe(for: store.newGoalTargetType))
    }

    private static func defaultHex(for type: GoalItem.GoalType) -> String {
        switch type {
        case .longTerm: return "#EE7E75"
        case .shortTerm: return "#38BDF8"
        case .daily: return "#34D399"
        }
    }

    private static func defaultIcon(for type: GoalItem.GoalType) -> String {
        switch type {
        case .longTerm: return "target"
        case .shortTerm: return "bolt.fill"
        case .daily: return "calendar"
        }
    }

    private static func defaultTimeframe(for type: GoalItem.GoalType) -> String {
        switch type {
        case .longTerm: return "3-Year Horizon"
        case .shortTerm: return "This Month"
        case .daily: return "Today"
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("New Goal")
                        .font(.system(size: 18, weight: .bold))
                    Text("Define what you want to achieve and set your target horizon.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                }

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .font(.system(size: 13))
                .buttonStyle(.plain)
            }
            .padding(20)
            .overlay(Divider(), alignment: .bottom)

            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Goal Tier Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("GOAL TIER")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.secondary)

                        HStack(spacing: 8) {
                            ForEach(GoalItem.GoalType.allCases) { type in
                                let isSelected = selectedType == type
                                Button(action: {
                                    withAnimation(ThemeTokens.quickSpring) {
                                        selectedType = type
                                        selectedColorHex = Self.defaultHex(for: type)
                                        selectedIcon = Self.defaultIcon(for: type)
                                        targetTimeframe = Self.defaultTimeframe(for: type)
                                        targetDate = nil
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 11, weight: .bold))
                                        Text(type.shortName)
                                            .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                    }
                                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(isSelected ? Color(hex: selectedColorHex) ?? ThemeTokens.structuredCoral : Color.primary.opacity(0.04))
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("GOAL TITLE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.secondary)

                        TextField("e.g. Master iOS System Architecture, Launch SaaS MVP...", text: $title)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14, weight: .medium))
                            .padding(12)
                            .background(Color.primary.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Flexible Timeframe Selection System
                    TimeframePickerView(
                        goalType: selectedType,
                        accentColor: Color(hex: selectedColorHex) ?? ThemeTokens.structuredCoral,
                        targetTimeframe: $targetTimeframe,
                        targetDate: $targetDate
                    )

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTES / DESCRIPTION (OPTIONAL)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.secondary)

                        TextField("Why this goal matters and core strategy...", text: $notes)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .padding(12)
                            .background(Color.primary.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Icon & Color Selection
                    HStack(alignment: .top, spacing: 20) {
                        // Icons
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ICON")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.secondary)

                            LazyVGrid(columns: Array(repeating: GridItem(.fixed(32), spacing: 6), count: 4), spacing: 6) {
                                ForEach(availableIcons, id: \.self) { icon in
                                    let isSelected = selectedIcon == icon
                                    Button(action: { selectedIcon = icon }) {
                                        Image(systemName: icon)
                                            .font(.system(size: 13))
                                            .foregroundStyle(isSelected ? Color.white : Color.primary)
                                            .frame(width: 30, height: 30)
                                            .background(isSelected ? (Color(hex: selectedColorHex) ?? ThemeTokens.structuredCoral) : Color.primary.opacity(0.04))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Colors
                        VStack(alignment: .leading, spacing: 8) {
                            Text("COLOR")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.secondary)

                            LazyVGrid(columns: Array(repeating: GridItem(.fixed(32), spacing: 6), count: 3), spacing: 6) {
                                ForEach(availableColors, id: \.hex) { col in
                                    let isSelected = selectedColorHex == col.hex
                                    Button(action: { selectedColorHex = col.hex }) {
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: col.hex) ?? ThemeTokens.structuredCoral)
                                                .frame(width: 24, height: 24)

                                            if isSelected {
                                                Circle()
                                                    .strokeBorder(Color.white, lineWidth: 2)
                                                    .frame(width: 28, height: 28)
                                            }
                                        }
                                        .frame(width: 30, height: 30)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }

            // Footer
            HStack {
                Spacer()

                Button(action: createGoal) {
                    Text("Create Goal")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 9)
                        .background(
                            Color(hex: selectedColorHex) ?? ThemeTokens.structuredCoral
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(16)
            .background(Color.primary.opacity(0.02))
            .overlay(Divider(), alignment: .top)
        }
        .frame(width: 520, height: 600)
        .background(ThemeTokens.cardBackground)
    }

    private func createGoal() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        store.createGoal(
            title: title,
            notes: notes.isEmpty ? nil : notes,
            type: selectedType,
            targetDate: targetDate,
            targetDateText: targetTimeframe.isEmpty ? nil : targetTimeframe,
            accentColorHex: selectedColorHex,
            iconName: selectedIcon
        )
        // Set active slider tab to the created goal's type
        store.selectedGoalTab = GoalItem.AppStageTab(rawValue: selectedType.rawValue) ?? .longTerm
        dismiss()
    }
}
