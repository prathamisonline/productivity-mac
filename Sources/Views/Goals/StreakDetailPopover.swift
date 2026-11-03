import SwiftUI

public struct StreakDetailPopover: View {
    @Bindable var store: LifesaverStore
    @State private var streakManager = StreakManager.shared

    public init(store: LifesaverStore) {
        self.store = store
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Streak")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(streakManager.currentStreak)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.primary)

                        Text(streakManager.currentStreak == 1 ? "day" : "days")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.secondary)
                    }
                }

                Spacer()

                HStack(spacing: 5) {
                    Circle()
                        .fill(streakManager.isActiveToday ? Color.green : Color.orange)
                        .frame(width: 7, height: 7)

                    Text(streakManager.isActiveToday ? "Active today" : "Pending today")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.04))
                .clipShape(Capsule())
            }

            // 7-Day Activity Strip
            VStack(alignment: .leading, spacing: 8) {
                Text("Last 7 Days")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.secondary)

                HStack(spacing: 8) {
                    ForEach(streakManager.recentDays) { day in
                        VStack(spacing: 6) {
                            Text(day.dayLetter)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(day.isToday ? Color.primary : Color.secondary)

                            ZStack {
                                Circle()
                                    .fill(
                                        day.isActive
                                        ? Color(red: 0.95, green: 0.45, blue: 0.35)
                                        : (day.isFrozen ? Color.blue.opacity(0.2) : Color.primary.opacity(0.04))
                                    )
                                    .frame(width: 26, height: 26)

                                if day.isActive {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Color.white)
                                } else if day.isFrozen {
                                    Image(systemName: "shield.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Color.blue)
                                } else if day.isToday {
                                    Circle()
                                        .strokeBorder(Color.primary.opacity(0.3), lineWidth: 1.5)
                                        .frame(width: 24, height: 24)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(10)
                .background(Color.primary.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Summary Stats Row
            HStack(spacing: 12) {
                statCell(
                    title: "Best Streak",
                    value: "\(streakManager.longestStreak)d"
                )

                statCell(
                    title: "Freezes Left",
                    value: "\(streakManager.freezesRemaining) / 2"
                )
            }

            // Freeze Action (Rest Day Protection)
            if canFreezeYesterday {
                Button(action: {
                    withAnimation(ThemeTokens.quickSpring) {
                        _ = streakManager.freezeYesterday(store: store)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 11))
                        Text("Freeze Yesterday to Protect Streak")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Color.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color.blue.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(width: 310)
        .background(ThemeTokens.cardBackground)
        .onAppear {
            streakManager.recalculate(store: store)
        }
    }

    private var canFreezeYesterday: Bool {
        guard streakManager.freezesRemaining > 0 else { return false }
        let today = Calendar.current.startOfDay(for: Date.now)
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) else { return false }
        return !streakManager.frozenDates.contains(yesterday)
    }

    private func statCell(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.secondary)

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

