import Foundation

func check(_ condition: @autoclosure () -> Bool, _ message: String) { if !condition() { fatalError(message) } }
let now = Date(timeIntervalSince1970: 1000)
var timer = TimerEngine()
timer.start(now: now)
_ = timer.tick(now: now.addingTimeInterval(65))
check(timer.display == "23:55", "Clock should use elapsed time")
timer.pause(now: now.addingTimeInterval(70))
check(timer.remaining == 1430 && !timer.isRunning, "Pause preserves remaining time")
timer.start(now: now.addingTimeInterval(200))
check(timer.tick(now: now.addingTimeInterval(1630)) == .focus, "Resume completes at the correct deadline")
check(timer.mode == .shortBreak && timer.completed == 1 && !timer.isRunning, "Focus completion prepares short break")
check(timer.tick(now: now.addingTimeInterval(9999)) == nil && timer.completed == 1, "Completion must not repeat")
for count in 2...4 {
    timer.select(.focus); timer.start(now: now)
    _ = timer.tick(now: now.addingTimeInterval(2000))
    check(timer.completed == count, "Counts completed focus sessions")
}
check(timer.mode == .longBreak && timer.remaining == 900, "Fourth session earns long break")
timer.start(now: now)
check(timer.tick(now: now.addingTimeInterval(900)) == .longBreak && timer.mode == .focus && timer.completed == 4, "Break completion returns to focus without counting it")
timer.start(now: now); timer.reset()
check(!timer.isRunning && timer.remaining == 1500, "Reset stops and restores duration")
timer.durations[.focus] = 60; timer.reset(); timer.start(now: now)
check(timer.tick(now: now.addingTimeInterval(5000)) == .focus, "Timer handles waking after deadline")
check(timer.progress == 0 && timer.display == "05:00", "New break starts with correct progress and time")
print("PASS: elapsed time, pause/resume, single completion, four-session cycle, breaks, reset, custom duration, wake after deadline")
