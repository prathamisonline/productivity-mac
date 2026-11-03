import SwiftUI

public enum ThemeTokens {
    // MARK: - Lifesaver Official Color Palette
    public static let structuredCoral = Color(red: 0.93, green: 0.49, blue: 0.46)       // #EE7E75 / Peach Coral
    public static let structuredCoralLight = Color(red: 0.96, green: 0.65, blue: 0.62)  // Soft Peach
    public static let structuredCoralDark = Color(red: 0.88, green: 0.38, blue: 0.35)   // Deep Coral
    
    // Task Node & Category Colors
    public static let structuredNavy = Color(red: 0.17, green: 0.24, blue: 0.31)        // #2C3E50 Night/Moon
    public static let structuredBlue = Color(red: 0.22, green: 0.74, blue: 0.97)        // #38BDF8 Deep Work/Laptop
    public static let structuredGreen = Color(red: 0.20, green: 0.83, blue: 0.60)       // #34D399 Health/Gym
    public static let structuredPurple = Color(red: 0.51, green: 0.55, blue: 0.97)      // #818CF8 Learning/Book
    public static let structuredAmber = Color(red: 0.98, green: 0.75, blue: 0.14)       // #FBBF24 Goals/Target

    // Adaptive Semantic Colors (Automatic Light & Dark Mode)
    #if os(macOS)
    public static var cardBackground: Color {
        Color(nsColor: .controlBackgroundColor)
    }
    public static var secondaryCardBackground: Color {
        Color(nsColor: .underPageBackgroundColor)
    }
    public static var canvasBackground: Color {
        Color(nsColor: .windowBackgroundColor)
    }
    public static var sidebarBackground: Color {
        Color(nsColor: .windowBackgroundColor)
    }
    #else
    public static var cardBackground: Color {
        Color(uiColor: .secondarySystemBackground)
    }
    public static var secondaryCardBackground: Color {
        Color(uiColor: .tertiarySystemBackground)
    }
    public static var canvasBackground: Color {
        Color(uiColor: .systemBackground)
    }
    public static var sidebarBackground: Color {
        Color(uiColor: .secondarySystemBackground)
    }
    #endif

    // Backward-compatible tokens
    public static var structuredCanvas: Color { canvasBackground }
    public static var structuredCard: Color { cardBackground }
    public static let timelineSpineColor = Color.primary.opacity(0.14)

    // Gradients for Focus Mode
    public static let focusGradient = LinearGradient(
        colors: [structuredCoral, structuredCoralDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let breakGradient = LinearGradient(
        colors: [structuredAmber, structuredCoral],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let longBreakGradient = LinearGradient(
        colors: [structuredPurple, structuredNavy],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Heatmap Scale (0 - 4 Structured Coral scale)
    public static func heatmapColor(tier: Int) -> Color {
        switch tier {
        case 1:
            return structuredCoral.opacity(0.25)
        case 2:
            return structuredCoral.opacity(0.55)
        case 3:
            return structuredCoral
        case 4:
            return structuredCoralDark
        default:
            return Color.primary.opacity(0.08)
        }
    }

    // Geometry & Radii
    public static let cardCornerRadius: CGFloat = 16
    public static let pillCornerRadius: CGFloat = 20
    public static let buttonCornerRadius: CGFloat = 12

    // Springs & Physics
    public static let bouncySpring = Animation.spring(response: 0.34, dampingFraction: 0.65)
    public static let smoothSpring = Animation.spring(response: 0.40, dampingFraction: 0.85)
    public static let quickSpring = Animation.spring(response: 0.22, dampingFraction: 0.75)

    // Helpers to derive Icon and Color for each Task
    public static func taskColor(for priorityRaw: Int, orderIndex: Int) -> Color {
        if priorityRaw >= 3 {
            return structuredCoral
        }
        let colors = [structuredCoral, structuredBlue, structuredGreen, structuredPurple, structuredAmber, structuredNavy]
        return colors[abs(orderIndex) % colors.count]
    }

    public static func taskIcon(for title: String, orderIndex: Int) -> String {
        let lower = title.lowercased()
        if lower.contains("wake") || lower.contains("morning") || lower.contains("sun") {
            return "sun.max.fill"
        } else if lower.contains("bed") || lower.contains("sleep") || lower.contains("night") {
            return "moon.stars.fill"
        } else if lower.contains("meet") || lower.contains("call") || lower.contains("sync") {
            return "video.fill"
        } else if lower.contains("code") || lower.contains("dev") || lower.contains("build") || lower.contains("app") {
            return "laptopcomputer"
        } else if lower.contains("gym") || lower.contains("run") || lower.contains("workout") || lower.contains("fitness") {
            return "figure.run"
        } else if lower.contains("eat") || lower.contains("lunch") || lower.contains("dinner") || lower.contains("coffee") {
            return "cup.and.saucer.fill"
        } else if lower.contains("read") || lower.contains("study") || lower.contains("book") {
            return "book.fill"
        } else {
            let icons = ["sun.max.fill", "laptopcomputer", "book.fill", "cup.and.saucer.fill", "figure.run", "moon.stars.fill"]
            return icons[abs(orderIndex) % icons.count]
        }
    }
}
