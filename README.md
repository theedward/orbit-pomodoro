# Orbit

A native macOS Pomodoro timer with an orbital dial, luminous gradients, and three distinct moods. Built with Codex as a small showcase of taking a visual concept to a working Mac app.

<img src="Assets/Orbit.png" width="144" alt="Orbit app icon">

## Three themes

- **Stellar:** deep navy gradients, mint light, scattered stars, and a quiet orbital dial.
- **Synthwave:** a striped sunset, pink-to-peach gradients, bold italic clock, equalizer-style progress, and a perspective grid.
- **Cyberpunk:** an angular instrument panel, segmented progress bars, terminal typography, acid-yellow-to-mint gradients, circuitry, and scan lines.

Switch from the lower-left theme menu or Settings. Theme selection is remembered.

## Download

Get the universal DMG from [Releases](https://github.com/theedward/orbit-pomodoro/releases/latest), open it, and drag Orbit into Applications. Requires macOS 14 or later; supports Apple Silicon and Intel.

This independent showcase build is ad-hoc signed and **not Apple notarized**. macOS may require approval in System Settings → Privacy & Security on first launch. Alternatively, review the source and build it locally.

## Features

- Focus, short break, and long break; defaults of 25 / 5 / 15 minutes.
- Editable lengths from 1–180 minutes, persisted locally.
- Start, pause, resume, reset, and completed-session tracking.
- Long break after every fourth focus session; each session starts explicitly.
- Clock-based countdown handles sleep and delayed timer updates.
- Timer state restores on relaunch, including an active deadline.
- Completion sound and in-app completion message.
- Menu bar controls and active countdown.
- **Living themes:** drifting Stellar stars and satellite, a setting Synthwave sun with animated equalizer, and a scanning Cyberpunk panel that powers down as the session progresses.
- **Break atmospheres:** lavender space, cool dawn, and subdued recovery palettes.
- **Mini mode:** a floating compact timer with start/pause, reset, session/theme menu, and expand control. Its window position is remembered, and it shares the full timer state.
- Motion pauses with the timer, stops in the hidden full window during mini mode, respects macOS Reduce Motion, and can be disabled in Settings.
- Keep-on-top option and a ten-second demonstration mode in Settings.
- Space to start/pause, ⌘R to reset, ⌘, for Settings, ⇧⌘M to toggle mini mode.

All processing stays on your Mac. No accounts, analytics, or network access. Session count persists until app preferences are cleared.

## Build and test

Install Xcode or its Command Line Tools, then:

```sh
zsh test.sh
zsh build.sh
open Orbit.app
```

The build script creates a universal macOS app with an embedded icon and an ad-hoc signature, using Apple's Swift compiler. No package manager or external dependencies are needed.

Create the disk image, ZIP, and checksums:

```sh
zsh package.sh
```

Outputs appear under `dist/`. For notarized distribution, sign using your own Developer ID and notarize through Apple before sharing.

## Stack

Swift, SwiftUI, AppKit, Combine, Foundation, and UserDefaults. SwiftUI Canvas draws the theme artwork directly. `TimerEngine.swift` contains the timer state machine; `Tests/main.swift` exercises pause/resume, completion, break cycles, reset, custom durations, and wake-after-deadline behavior. `Sources/MakeIcon.swift` is a standalone AppKit icon generator and is excluded from application compilation.

## License

[MIT](LICENSE) © 2026 João Eduardo Seixas.
