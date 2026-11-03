import SwiftUI

public struct GoalTaskRowView: View {
    @Bindable var store: LifesaverStore
    @Bindable var task: TaskItem

    @State private var isHovering: Bool = false

    public init(store: LifesaverStore, task: TaskItem) {
        self.store = store
        self.task = task
    }

    public var body: some View {
        let _ = store.revision

        HStack(spacing: 10) {
            // Checkbox Button with generous, solid hit area
            Button(action: {
                withAnimation(ThemeTokens.bouncySpring) {
                    store.toggleTask(task)
                }
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(task.isCompleted ? Color.green : Color.primary.opacity(0.04))
                        .frame(width: 20, height: 20)

                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(task.isCompleted ? Color.green : Color.secondary.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 20, height: 20)

                    if task.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.white)
                    }
                }
                .contentShape(Rectangle())
                .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help(task.isCompleted ? "Mark Incomplete" : "Mark Complete")

            // Task Title (Clicking also toggles)
            Button(action: {
                withAnimation(ThemeTokens.bouncySpring) {
                    store.toggleTask(task)
                }
            }) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.system(size: 13, weight: task.isCompleted ? .regular : .medium))
                        .foregroundStyle(task.isCompleted ? Color.secondary : Color.primary)
                        .strikethrough(task.isCompleted, color: Color.secondary.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())

                    if let parentGoal = task.goal, task.taskScope == .daily {
                        HStack(spacing: 4) {
                            Image(systemName: parentGoal.iconName)
                                .font(.system(size: 9))
                            Text(parentGoal.title)
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(ThemeTokens.structuredBlue)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // Delete Task Button
            Button(action: {
                withAnimation(ThemeTokens.quickSpring) {
                    store.deleteTask(task)
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.secondary.opacity(isHovering ? 0.9 : 0.4))
                    .padding(5)
                    .background(Color.primary.opacity(isHovering ? 0.08 : 0.03))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Delete Task")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(task.isCompleted ? Color.primary.opacity(0.015) : Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

