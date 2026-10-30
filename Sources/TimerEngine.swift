import Foundation

enum SessionMode: String, CaseIterable, Codable {
    case focus, shortBreak, longBreak
    var title: String { switch self { case .focus: "Focus"; case .shortBreak: "Short break"; case .longBreak: "Long break" } }
}

struct TimerEngine {
    var mode: SessionMode = .focus
    var durations: [SessionMode: TimeInterval] = [.focus: 1500, .shortBreak: 300, .longBreak: 900]
    var remaining: TimeInterval = 1500
    var deadline: Date?
    var completed = 0
    var isRunning: Bool { deadline != nil }
    var duration: TimeInterval { durations[mode] ?? 1500 }
    var progress: Double { min(1, max(0, 1 - remaining / duration)) }
    var display: String {
        let seconds = max(0, Int(ceil(remaining)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
    mutating func start(now: Date = Date()) { guard !isRunning else { return }; deadline = now.addingTimeInterval(remaining) }
    mutating func pause(now: Date = Date()) { if let deadline { remaining = max(0, deadline.timeIntervalSince(now)) }; deadline = nil }
    mutating func select(_ mode: SessionMode) { deadline = nil; self.mode = mode; remaining = duration }
    mutating func reset() { select(mode) }
    /// Returns the completed mode once. Each following session waits for an explicit start.
    mutating func tick(now: Date = Date()) -> SessionMode? {
        guard let deadline else { return nil }
        remaining = max(0, deadline.timeIntervalSince(now))
        guard remaining <= 0 else { return nil }
        let finished = mode
        if finished == .focus { completed += 1; select(completed % 4 == 0 ? .longBreak : .shortBreak) }
        else { select(.focus) }
        return finished
    }
}
