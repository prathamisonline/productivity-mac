import SwiftUI

public struct TaskTimeLogPopover: View {
    @Bindable var store: LifesaverStore
    @Bindable var task: TaskItem
    @Environment(\.dismiss) private var dismiss

    @State private var customMinutesText: String = ""

    public init(store: LifesaverStore, task: TaskItem) {
        self.store = store
        self.task = task
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Time Log")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.secondary)

                    Text(task.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)
                }

                Spacer()

                if task.loggedMinutes > 0 {
                    Button("Reset") {
                        withAnimation(ThemeTokens.quickSpring) {
                            task.loggedMinutes = 0
                            store.notifyChange()
                        }
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(Color.secondary)
                    .buttonStyle(.plain)
                }
            }

            // Current Logged Total Banner
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(ThemeTokens.structuredBlue)

                Text("Logged:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.secondary)

                Spacer()

                Text(task.formattedLoggedTime)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.primary)
            }
            .padding(10)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Quick Add Increments
            VStack(alignment: .leading, spacing: 6) {
                Text("Add Time")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.secondary)

                HStack(spacing: 6) {
                    incrementButton("+15m", minutes: 15)
                    incrementButton("+25m", minutes: 25)
                    incrementButton("+30m", minutes: 30)
                    incrementButton("+45m", minutes: 45)
                    incrementButton("+1h", minutes: 60)
                }
            }

            // Custom Direct Set
            HStack(spacing: 8) {
                TextField("Custom mins (e.g. 90)", text: $customMinutesText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
                    .onSubmit {
                        applyCustomMinutes()
                    }

                Button("Set") {
                    applyCustomMinutes()
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(ThemeTokens.structuredBlue)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .frame(width: 280)
        .background(ThemeTokens.cardBackground)
    }

    private func incrementButton(_ label: String, minutes: Int) -> some View {
        Button(action: {
            withAnimation(ThemeTokens.quickSpring) {
                task.loggedMinutes += minutes
                store.notifyChange()
            }
        }) {
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    private func applyCustomMinutes() {
        guard let mins = Int(customMinutesText.trimmingCharacters(in: .whitespacesAndNewlines)), mins >= 0 else { return }
        withAnimation(ThemeTokens.quickSpring) {
            task.loggedMinutes = mins
            store.notifyChange()
            customMinutesText = ""
        }
    }
}

