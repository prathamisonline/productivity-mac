import SwiftUI

public struct EditGoalSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: LifesaverStore
    public let goal: GoalItem

    @State private var title: String
    @State private var notes: String
    @State private var targetTimeframe: String
    @State private var targetDate: Date?
    @State private var selectedType: GoalItem.GoalType
    @State private var selectedColorHex: String
    @State private var selectedIcon: String
    @State private var showDeleteConfirmation: Bool = false

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

    public init(store: LifesaverStore, goal: GoalItem) {
        self.store = store
        self.goal = goal
        _title = State(initialValue: goal.title)
        _notes = State(initialValue: goal.notes ?? "")
        _targetTimeframe = State(initialValue: goal.targetDateText ?? "")
        _targetDate = State(initialValue: goal.targetDate)
        _selectedType = State(initialValue: goal.goalType)
        _selectedColorHex = State(initialValue: goal.accentColorHex)
        _selectedIcon = State(initialValue: goal.iconName)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Edit Goal")
                        .font(.system(size: 18, weight: .bold))
                    Text("Update title, target timeframe, tier, or visual styling.")
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

            // Form Content
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

                        TextField("Goal title...", text: $title)
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
                Button(role: .destructive, action: {
                    showDeleteConfirmation = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("Delete Goal")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.red)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: saveChanges) {
                    Text("Save Changes")
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
        .confirmationDialog("Are you sure you want to delete this goal?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete Goal", role: .destructive) {
                withAnimation(ThemeTokens.quickSpring) {
                    store.deleteGoal(goal)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete this goal and its associated tasks.")
        }
    }

    private func saveChanges() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        withAnimation(ThemeTokens.smoothSpring) {
            store.updateGoal(
                goal,
                title: title,
                notes: notes,
                type: selectedType,
                targetDate: targetDate,
                targetDateText: targetTimeframe,
                accentColorHex: selectedColorHex,
                iconName: selectedIcon
            )
            // If the user changed the tier, switch the view to that stage
            store.selectedGoalTab = GoalItem.AppStageTab(rawValue: selectedType.rawValue) ?? .longTerm
            dismiss()
        }
    }
}
