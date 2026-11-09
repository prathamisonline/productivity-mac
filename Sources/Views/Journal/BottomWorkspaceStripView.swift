import SwiftUI

public struct BottomWorkspaceStripView: View {
    @Bindable var store: LifesaverStore

    public init(store: LifesaverStore) {
        self.store = store
    }

    public var body: some View {
        HStack {
            Spacer()

            // Center: Minimalist Workspace Switcher (Goals vs. Journal)
            HStack(spacing: 4) {
                workspaceButton(
                    mode: .goals,
                    label: "Goals",
                    icon: "target",
                    shortcut: "⌘1"
                )

                workspaceButton(
                    mode: .journal,
                    label: "Journal",
                    icon: "book.closed.fill",
                    shortcut: "⌘2"
                )
            }
            .padding(3)
            .background(Color.primary.opacity(0.05))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            )

            Spacer()
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 16)
        .background(ThemeTokens.cardBackground)
        .overlay(Divider(), alignment: .top)
    }

    @ViewBuilder
    private func workspaceButton(
        mode: LifesaverStore.WorkspaceMode,
        label: String,
        icon: String,
        shortcut: String
    ) -> some View {
        let isSelected = store.activeWorkspaceMode == mode

        Button(action: {
            withAnimation(ThemeTokens.smoothSpring) {
                store.activeWorkspaceMode = mode
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))

                Text(label)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
            }
            .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .background(
                isSelected
                ? Color.primary.opacity(0.10)
                : Color.clear
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(mode == .goals ? "1" : "2", modifiers: .command)
    }
}

