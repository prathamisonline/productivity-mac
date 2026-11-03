import SwiftUI
import SwiftData
#if os(macOS)
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            if let window = NSApp.windows.first(where: { $0.canBecomeKey }) {
                window.makeKeyAndOrderFront(nil)
            }

            if CommandLine.arguments.contains("--capture-hero") {
                StreakManager.shared.currentStreak = 14
                StreakManager.shared.longestStreak = 28
                StreakManager.shared.isActiveToday = true
                StreakManager.shared.freezesRemaining = 2

                try? await Task.sleep(for: .milliseconds(1200))
                if let window = NSApp.windows.first(where: { $0.canBecomeKey }),
                   let targetView = window.contentView?.superview ?? window.contentView {
                    let bounds = targetView.bounds
                    if let rep = targetView.bitmapImageRepForCachingDisplay(in: bounds) {
                        targetView.cacheDisplay(in: bounds, to: rep)
                        if let pngData = rep.representation(using: .png, properties: [:]) {
                            let url = URL(fileURLWithPath: "/Users/prathamsrivastava/Desktop/apps/lifesaver/assets/hero.png")
                            try? pngData.write(to: url)
                            print("HERO_CAPTURED_SUCCESSFULLY:\(Int(bounds.width))x\(Int(bounds.height))")
                            NSApp.terminate(nil)
                        }
                    }
                }
            }
        }
    }
}
#endif

@main
struct LifesaverApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    var sharedModelContainer: ModelContainer = {
        let isCaptureHero = CommandLine.arguments.contains("--capture-hero")
        let schema = Schema([
            GoalItem.self,
            TaskItem.self,
            PlanDay.self,
            PlanWeek.self,
            PomodoroSession.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isCaptureHero,
            cloudKitDatabase: .none
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            if isCaptureHero {
                Task { @MainActor in
                    Self.populateShowcaseDummyData(context: container.mainContext)
                }
            }
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @MainActor
    private static func populateShowcaseDummyData(context: ModelContext) {
        // 1. Long-Term Goals
        let ltGoal1 = GoalItem(
            title: "Launch Lifesaver macOS 1.0",
            notes: "Ship a minimalist, high-velocity goal execution system for indie builders.",
            goalType: .longTerm,
            targetDateText: "2027 Horizon",
            accentColorHex: "#EE7E75",
            iconName: "target"
        )
        context.insert(ltGoal1)

        let t1 = TaskItem(title: "Architect 3-tier goal hierarchy (Long, Short, Daily)", taskScope: .longTerm, goal: ltGoal1)
        t1.isCompleted = true
        t1.completedAt = Date.now

        let t2 = TaskItem(title: "Build fluid horizontal stage slider navigation", taskScope: .longTerm, goal: ltGoal1)
        t2.isCompleted = true
        t2.completedAt = Date.now

        let t3 = TaskItem(title: "Implement native iCloud Drive backup and sync", taskScope: .longTerm, goal: ltGoal1)
        t3.isCompleted = true
        t3.completedAt = Date.now

        let t4 = TaskItem(title: "Publish release to macOS App Store", taskScope: .longTerm, goal: ltGoal1)
        t4.isCompleted = false

        for t in [t1, t2, t3, t4] {
            context.insert(t)
        }
        ltGoal1.tasks = [t1, t2, t3, t4]

        let ltGoal2 = GoalItem(
            title: "Master High-Performance Systems & Swift 6",
            notes: "Deep dive into low-latency architecture and modern concurrency.",
            goalType: .longTerm,
            targetDateText: "3-Year Vision",
            accentColorHex: "#38BDF8",
            iconName: "bolt.fill"
        )
        context.insert(ltGoal2)

        let t5 = TaskItem(title: "Study Swift 6 strict concurrency model", taskScope: .longTerm, goal: ltGoal2)
        t5.isCompleted = true
        t5.completedAt = Date.now

        let t6 = TaskItem(title: "Build distributed actor benchmark harness", taskScope: .longTerm, goal: ltGoal2)
        t6.isCompleted = false

        for t in [t5, t6] {
            context.insert(t)
        }
        ltGoal2.tasks = [t5, t6]

        // 2. Short-Term Goal
        let stGoal = GoalItem(
            title: "Q4 Core App Polish & Release",
            notes: "Distraction-free interaction design, animations, and stage flow.",
            goalType: .shortTerm,
            targetDateText: "This Month",
            accentColorHex: "#38BDF8",
            iconName: "bolt.fill"
        )
        context.insert(stGoal)

        let st1 = TaskItem(title: "Remove sidebar and clock inspectors", taskScope: .shortTerm, goal: stGoal)
        st1.isCompleted = true
        st1.completedAt = Date.now

        let st2 = TaskItem(title: "Refine dark-mode contrast & typography", taskScope: .shortTerm, goal: stGoal)
        st2.isCompleted = true
        st2.completedAt = Date.now

        let st3 = TaskItem(title: "Design 7-day activity streak tracker", taskScope: .shortTerm, goal: stGoal)
        st3.isCompleted = false

        let stDaily = TaskItem(title: "Add keyboard navigation shortcuts (⌘← and ⌘→)", taskScope: .daily, goal: stGoal)
        stDaily.isCompleted = true
        stDaily.completedAt = Date.now

        for t in [st1, st2, st3, stDaily] {
            context.insert(t)
        }
        stGoal.tasks = [st1, st2, st3, stDaily]

        // 3. Daily Goal
        let dGoal = GoalItem(
            title: "Today's Core Outcomes",
            notes: "Focused outcomes for today's engineering session.",
            goalType: .daily,
            targetDateText: "Today",
            accentColorHex: "#34D399",
            iconName: "calendar"
        )
        context.insert(dGoal)

        let dt1 = TaskItem(title: "Verify SwiftData relationship cascades", taskScope: .daily, goal: dGoal)
        dt1.isCompleted = true
        dt1.completedAt = Date.now

        let dt2 = TaskItem(title: "Add streak freeze protection popover", taskScope: .daily, goal: dGoal)
        dt2.isCompleted = true
        dt2.completedAt = Date.now

        let dt3 = TaskItem(title: "Review pull requests & docs", taskScope: .daily, goal: dGoal)
        dt3.isCompleted = false

        for t in [dt1, dt2, dt3] {
            context.insert(t)
        }
        dGoal.tasks = [dt1, dt2, dt3]

        try? context.save()
    }

    var body: some Scene {
        WindowGroup {
            AppShellView()
        }
        .modelContainer(sharedModelContainer)
        #if os(macOS)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        #endif
    }
}
