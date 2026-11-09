import SwiftUI

public struct JournalEntryCardView: View {
    public let day: PlanDay
    public let isSelected: Bool
    public let onSelect: () -> Void
    public var onDelete: (() -> Void)?

    public init(
        day: PlanDay,
        isSelected: Bool,
        onSelect: @escaping () -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.day = day
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.onDelete = onDelete
    }

    public var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 14) {
                // MARK: - Date Badge (Matches Reference Image)
                VStack(spacing: 2) {
                    Text(day.weekdayShort)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(isSelected ? Color.white.opacity(0.85) : Color.secondary)
                        .tracking(0.5)

                    Text(day.dayNumberString)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                }
                .frame(width: 38)
                .padding(.vertical, 6)
                .background(
                    isSelected
                    ? Color.white.opacity(0.18)
                    : Color.primary.opacity(0.04)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // MARK: - Middle Title & Content Snippet
                VStack(alignment: .leading, spacing: 4) {
                    Text(day.journalTitle)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                        .lineLimit(1)

                    Text(day.journalSnippet)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(isSelected ? Color.white.opacity(0.85) : Color.secondary)
                        .lineLimit(2)
                        .lineSpacing(2)

                    HStack(spacing: 6) {
                        Text("\(day.wordCount) words")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(isSelected ? Color.white.opacity(0.7) : Color.secondary.opacity(0.7))

                        if day.completedTasksCount > 0 {
                            Text("•")
                                .font(.system(size: 9))
                                .foregroundStyle(isSelected ? Color.white.opacity(0.5) : Color.secondary.opacity(0.5))

                            HStack(spacing: 2) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .bold))
                                Text("\(day.completedTasksCount) tasks")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundStyle(isSelected ? Color.white.opacity(0.75) : ThemeTokens.structuredGreen)
                        }
                    }
                    .padding(.top, 2)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected
                ? Color(red: 0.15, green: 0.45, blue: 0.95) // Reference image active blue highlight
                : ThemeTokens.cardBackground
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected
                        ? Color.white.opacity(0.2)
                        : Color.primary.opacity(0.06),
                        lineWidth: 1
                    )
            )
            .shadow(color: isSelected ? Color.blue.opacity(0.25) : Color.clear, radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Open Entry") {
                onSelect()
            }
            if let onDelete {
                Divider()
                Button(role: .destructive, action: onDelete) {
                    Label("Delete Entry", systemImage: "trash")
                }
            }
        }
    }
}

