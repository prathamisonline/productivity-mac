import SwiftUI

public struct StreakDetailPopover: View {
    @Bindable var store: LifesaverStore
    @State private var streakManager = StreakManager.shared

    @State private var showFreezeConfirmation: Bool = false
    @State private var showResetConfirmation: Bool = false

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

            // MARK: - Freeze / Unfreeze Management Section
            if isYesterdayFrozen {
                // Yesterday is already frozen -> Offer Unfreeze
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.blue)
                        Text("Yesterday is Protected (Frozen)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.blue)
                    }

                    Button(action: {
                        withAnimation(ThemeTokens.quickSpring) {
                            _ = streakManager.unfreezeYesterday(store: store)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 10, weight: .bold))
                            Text("Unfreeze Yesterday (Restores 1 Freeze)")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(Color.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(Color.blue.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            } else if canFreezeYesterday {
                // Yesterday is eligible for freeze -> Require confirmation
                if showFreezeConfirmation {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Streak Freeze?")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.primary)

                        Text("Use 1 freeze to protect your streak for yesterday's rest day. You will have \(streakManager.freezesRemaining - 1) left.")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.secondary)

                        HStack(spacing: 8) {
                            Button(action: {
                                withAnimation(ThemeTokens.quickSpring) {
                                    _ = streakManager.freezeYesterday(store: store)
                                    showFreezeConfirmation = false
                                }
                            }) {
                                Text("Confirm Freeze")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(Color.blue)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                withAnimation(ThemeTokens.quickSpring) {
                                    showFreezeConfirmation = false
                                }
                            }) {
                                Text("Cancel")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.primary.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(10)
                    .background(Color.blue.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Button(action: {
                        withAnimation(ThemeTokens.quickSpring) {
                            showFreezeConfirmation = true
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

            // MARK: - Reset All Freezes Option
            if hasModifiedFreezes {
                Divider()
                    .padding(.vertical, 2)

                if showResetConfirmation {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Reset All Freezes?")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.primary)

                        Text("This clears all frozen dates and restores your 2 available monthly freezes.")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.secondary)

                        HStack(spacing: 8) {
                            Button("Reset to 2/2") {
                                withAnimation(ThemeTokens.quickSpring) {
                                    streakManager.resetAllFreezes(store: store)
                                    showResetConfirmation = false
                                }
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .buttonStyle(.plain)

                            Button("Cancel") {
                                withAnimation(ThemeTokens.quickSpring) {
                                    showResetConfirmation = false
                                }
                            }
                            .font(.system(size: 11))
                            .foregroundStyle(Color.secondary)
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation(ThemeTokens.quickSpring) {
                                showResetConfirmation = true
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 9))
                                Text("Reset Freezes (2/2)")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundStyle(Color.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 320)
        .background(ThemeTokens.cardBackground)
        .onAppear {
            streakManager.recalculate(store: store)
        }
    }

    private var isYesterdayFrozen: Bool {
        let today = Calendar.current.startOfDay(for: Date.now)
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) else { return false }
        return streakManager.frozenDates.contains(yesterday)
    }

    private var canFreezeYesterday: Bool {
        guard streakManager.freezesRemaining > 0 else { return false }
        let today = Calendar.current.startOfDay(for: Date.now)
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) else { return false }
        return !streakManager.frozenDates.contains(yesterday)
    }

    private var hasModifiedFreezes: Bool {
        streakManager.freezesRemaining < 2 || !streakManager.frozenDates.isEmpty
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
