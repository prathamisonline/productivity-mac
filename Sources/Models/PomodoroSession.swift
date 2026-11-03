import Foundation
import SwiftData

@Model
public final class PomodoroSession {
    public var id: UUID = UUID()
    public var startedAt: Date = Date.now
    public var endedAt: Date?
    public var durationSeconds: Int = 1500
    public var wasCompleted: Bool = false
    public var modeRaw: String = "work"

    public var task: TaskItem?

    public init(
        durationSeconds: Int = 1500,
        modeRaw: String = "work",
        wasCompleted: Bool = false,
        task: TaskItem? = nil
    ) {
        self.id = UUID()
        self.startedAt = Date.now
        self.endedAt = nil
        self.durationSeconds = durationSeconds
        self.modeRaw = modeRaw
        self.wasCompleted = wasCompleted
        self.task = task
    }
}
