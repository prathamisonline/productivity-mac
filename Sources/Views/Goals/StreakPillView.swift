import SwiftUI

public struct StreakPillView: View {
    @Bindable var store: LifesaverStore
    @State private var streakManager = StreakManager.shared
    @State private var showDetailPopover: Bool = false

    public init(store: LifesaverStore) {
        self.store = store
    }

    public var body: some View {
        let _ = store.revision

        Button(action: {
            showDetailPopover.toggle()
        }) {
            HStack(spacing: 5) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(
                        streakManager.isActiveToday
                        ? Color(red: 0.95, green: 0.50, blue: 0.35)
                        : Color.secondary.opacity(0.7)
                    )

                HStack(spacing: 1) {
                    Text("\(streakManager.currentStreak)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                    Text("d")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.secondary)
                }
                .foregroundStyle(Color.primary)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Color.primary.opacity(0.05))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        streakManager.isActiveToday
                        ? Color(red: 0.95, green: 0.50, blue: 0.35).opacity(0.3)
                        : Color.primary.opacity(0.06),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .help("Daily Streak Tracker")
        .popover(isPresented: $showDetailPopover, arrowEdge: .top) {
            StreakDetailPopover(store: store)
                .presentationCompactAdaptation(.popover)
        }
        .onAppear {
            streakManager.recalculate(store: store)
        }
    }
}

