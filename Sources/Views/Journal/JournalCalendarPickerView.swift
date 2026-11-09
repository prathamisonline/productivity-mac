import SwiftUI

public struct JournalCalendarPickerView: View {
    @Binding var selectedDate: Date
    public let datesWithEntries: Set<Date>
    public let onSelect: (Date) -> Void

    @State private var displayedMonth: Date

    private let calendar = Calendar.current

    public init(
        selectedDate: Binding<Date>,
        datesWithEntries: Set<Date>,
        onSelect: @escaping (Date) -> Void
    ) {
        self._selectedDate = selectedDate
        self.datesWithEntries = datesWithEntries
        self.onSelect = onSelect
        let start = Calendar.current.startOfDay(for: selectedDate.wrappedValue)
        self._displayedMonth = State(initialValue: start)
    }

    private var monthYearFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }

    private var weekdaySymbols: [String] {
        ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
    }

    private struct DayCell: Identifiable {
        let id: String
        let date: Date
        let dayNumber: Int
        let isCurrentMonth: Bool
        let isToday: Bool
        let isSelected: Bool
        let hasEntry: Bool
    }

    private var gridDays: [DayCell] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) ?? displayedMonth
        guard let monthInterval = calendar.dateInterval(of: .month, for: startOfMonth) else { return [] }

        let firstWeekday = calendar.component(.weekday, from: monthInterval.start) // 1 = Sunday
        let leadingDays = firstWeekday - 1

        guard let gridStartDate = calendar.date(byAdding: .day, value: -leadingDays, to: monthInterval.start) else { return [] }

        let todayNorm = calendar.startOfDay(for: Date.now)
        let selectedNorm = calendar.startOfDay(for: selectedDate)

        var cells: [DayCell] = []
        for offset in 0..<42 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: gridStartDate) else { continue }
            let norm = calendar.startOfDay(for: date)
            let isCurrentMonth = calendar.isDate(date, equalTo: startOfMonth, toGranularity: .month)
            let isToday = (norm == todayNorm)
            let isSelected = (norm == selectedNorm)
            let hasEntry = datesWithEntries.contains(norm)
            let dayNum = calendar.component(.day, from: date)

            cells.append(DayCell(
                id: "\(offset)-\(norm.timeIntervalSince1970)",
                date: norm,
                dayNumber: dayNum,
                isCurrentMonth: isCurrentMonth,
                isToday: isToday,
                isSelected: isSelected,
                hasEntry: hasEntry
            ))
        }

        // If the 6th row (cells 35-41) belongs entirely to next month, collapse it to 35 cells
        if cells.count == 42 && !cells[35...].contains(where: { $0.isCurrentMonth }) {
            cells.removeSubrange(35...)
        }

        return cells
    }

    public var body: some View {
        VStack(spacing: 12) {
            // MARK: - Header (Month Navigation & Today)
            HStack(spacing: 8) {
                Button(action: { stepMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.secondary)
                        .frame(width: 24, height: 24)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)

                Spacer()

                Text(monthYearFormatter.string(from: displayedMonth))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.primary)

                Spacer()

                Button(action: { stepMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.secondary)
                        .frame(width: 24, height: 24)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)

                // Today Button
                Button("Today") {
                    let today = calendar.startOfDay(for: Date.now)
                    displayedMonth = today
                    onSelect(today)
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(ThemeTokens.structuredBlue)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(ThemeTokens.structuredBlue.opacity(0.12))
                .clipShape(Capsule())
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)

            // MARK: - Weekday Headers
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.secondary.opacity(0.65))
                        .frame(maxWidth: .infinity)
                }
            }

            // MARK: - Days Grid
            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(gridDays) { cell in
                    Button(action: {
                        onSelect(cell.date)
                    }) {
                        VStack(spacing: 2) {
                            Text("\(cell.dayNumber)")
                                .font(.system(size: 12, weight: cell.isSelected || cell.isToday ? .bold : .medium))
                                .foregroundStyle(cellTextColor(cell))

                            // Dot for entry indicator
                            Circle()
                                .fill(cellDotColor(cell))
                                .frame(width: 3.5, height: 3.5)
                                .opacity(cell.hasEntry ? 1.0 : 0.0)
                        }
                        .frame(height: 30)
                        .frame(maxWidth: .infinity)
                        .background(cellBackgroundColor(cell))
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .strokeBorder(
                                    cell.isToday && !cell.isSelected
                                    ? ThemeTokens.structuredBlue
                                    : Color.clear,
                                    lineWidth: 1.2
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .frame(width: 270)
        .background(ThemeTokens.cardBackground)
    }

    private func stepMonth(by offset: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: offset, to: displayedMonth) {
            withAnimation(ThemeTokens.quickSpring) {
                displayedMonth = newMonth
            }
        }
    }

    private func cellTextColor(_ cell: DayCell) -> Color {
        if cell.isSelected {
            return Color.white
        } else if cell.isToday {
            return ThemeTokens.structuredBlue
        } else if cell.isCurrentMonth {
            return Color.primary
        } else {
            return Color.secondary.opacity(0.32)
        }
    }

    private func cellBackgroundColor(_ cell: DayCell) -> Color {
        if cell.isSelected {
            return Color(red: 0.15, green: 0.45, blue: 0.95)
        }
        return Color.clear
    }

    private func cellDotColor(_ cell: DayCell) -> Color {
        if cell.isSelected {
            return Color.white
        } else {
            return ThemeTokens.structuredCoral
        }
    }
}

