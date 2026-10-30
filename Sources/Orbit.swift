import SwiftUI
import AppKit
import Combine

enum OrbitTheme: String, CaseIterable, Identifiable {
    case stellar = "Stellar", synthwave = "Synthwave", cyberpunk = "Cyberpunk"
    var id: String { rawValue }
    static func hex(_ value: UInt32) -> Color { Color(red: Double((value >> 16) & 255) / 255, green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255) }
    var accent: Color { Self.hex(self == .stellar ? 0xAEF4DC : self == .synthwave ? 0xFF80DA : 0xE4FF59) }
    var secondary: Color { Self.hex(self == .stellar ? 0x5CADD0 : self == .synthwave ? 0xFFB16B : 0x22EBC0) }
    var background: [Color] { switch self {
        case .stellar: [Self.hex(0x172C40), Self.hex(0x0C1726), Self.hex(0x080F19)]
        case .synthwave: [Self.hex(0x492351), Self.hex(0x26183F), Self.hex(0x100F24)]
        case .cyberpunk: [Self.hex(0x183B3B), Self.hex(0x112125), Self.hex(0x0B1118)]
    } }
    var caption: String { switch self { case .stellar: "A little space to focus."; case .synthwave: "Find your frequency."; case .cyberpunk: "Disconnect. Lock in." } }
    var symbol: String { self == .stellar ? "circle.dotted.circle" : self == .synthwave ? "sun.horizon.fill" : "cpu" }
    var label: String { switch self { case .stellar: "DEEP SPACE"; case .synthwave: "AFTER HOURS"; case .cyberpunk: "NEURAL LINK" } }
}

@MainActor final class OrbitModel: ObservableObject {
    @Published var engine = TimerEngine()
    @Published var theme: OrbitTheme { didSet { UserDefaults.standard.set(theme.rawValue, forKey: "theme") } }
    @Published var sound: Bool { didSet { UserDefaults.standard.set(sound, forKey: "sound") } }
    @Published var completion: String?
    @Published var showSettings = false
    @Published var alwaysOnTop = false { didSet { updateWindowLevel() } }
    private var ticker: AnyCancellable?
    init() {
        let defaults = UserDefaults.standard
        theme = OrbitTheme(rawValue: defaults.string(forKey: "theme") ?? "") ?? .stellar
        sound = defaults.object(forKey: "sound") as? Bool ?? true
        for mode in SessionMode.allCases {
            let minutes = defaults.double(forKey: mode.rawValue)
            if minutes > 0 { engine.durations[mode] = min(180, max(1, minutes)) * 60 }
        }
        engine.reset()
        if let saved = defaults.data(forKey: "timer"), let state = try? JSONDecoder().decode(SavedTimer.self, from: saved) {
            engine.select(state.mode); engine.remaining = min(engine.duration, max(0, state.remaining)); engine.completed = state.completed
            if let deadline = state.deadline { engine.deadline = deadline; _ = finishTick() }
        }
        ticker = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect().sink { [weak self] _ in self?.tick() }
    }
    struct SavedTimer: Codable { var mode: SessionMode; var remaining: Double; var deadline: Date?; var completed: Int }
    func save() {
        let state = SavedTimer(mode: engine.mode, remaining: engine.remaining, deadline: engine.deadline, completed: engine.completed)
        UserDefaults.standard.set(try? JSONEncoder().encode(state), forKey: "timer")
    }
    @discardableResult func finishTick() -> Bool {
        if let finished = engine.tick() {
            completion = finished == .focus ? "Session complete. Take a breath." : "Break complete. Ready for another orbit?"
            if sound { NSSound(named: "Glass")?.play() }
            NSApp.requestUserAttention(.informationalRequest)
            save(); return true
        }; return false
    }
    func tick() { if engine.isRunning { _ = finishTick() } }
    func toggle() { completion = nil; if engine.isRunning { engine.pause() } else { engine.start() }; save() }
    func reset() { engine.reset(); completion = nil; save() }
    func select(_ mode: SessionMode) { engine.select(mode); completion = nil; save() }
    func setMinutes(_ minutes: Double, for mode: SessionMode) {
        engine.durations[mode] = min(180, max(1, minutes)) * 60
        UserDefaults.standard.set(minutes, forKey: mode.rawValue)
        if mode == engine.mode { engine.reset() }
        save()
    }
    func demo() { engine.select(.focus); engine.remaining = 10; engine.start(); completion = nil; showSettings = false; save() }
    func updateWindowLevel() { for window in NSApp.windows where window.identifier?.rawValue == "orbit-main" { window.level = alwaysOnTop ? .floating : .normal } }
    func openWindow() { NSApp.activate(ignoringOtherApps: true); if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "orbit-main" }) { window.makeKeyAndOrderFront(nil) } }
}

struct Atmosphere: View {
    var theme: OrbitTheme
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: theme.background, startPoint: .topLeading, endPoint: .bottomTrailing)
                RadialGradient(colors: [theme.accent.opacity(0.10), .clear], center: .init(x: 0.85, y: 0.35), startRadius: 0, endRadius: 340)
                Canvas { context, size in
                    if theme == .stellar {
                        for i in 0..<85 {
                            let x = Double((i * 137 + 21) % 997) / 997 * size.width
                            let y = Double((i * 263 + 49) % 991) / 991 * size.height
                            let r: Double = i % 9 == 0 ? 1.3 : 0.65
                            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)), with: .color(.white.opacity(i % 3 == 0 ? 0.38 : 0.13)))
                        }
                    } else if theme == .synthwave {
                        let horizon = size.height * 0.64
                        for i in 0..<13 {
                            var path = Path(); let y = horizon + pow(Double(i) / 12, 2) * size.height * 0.36
                            path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: size.width, y: y))
                            context.stroke(path, with: .color(theme.accent.opacity(0.11)), lineWidth: 0.7)
                        }
                        for i in -8...8 {
                            var path = Path(); path.move(to: CGPoint(x: size.width / 2 + Double(i) * 12, y: horizon)); path.addLine(to: CGPoint(x: size.width / 2 + Double(i) * 110, y: size.height))
                            context.stroke(path, with: .color(theme.accent.opacity(0.12)), lineWidth: 0.7)
                        }
                    } else {
                        for i in 0..<Int(size.height / 5) {
                            var path = Path(); path.move(to: CGPoint(x: 0, y: i * 5)); path.addLine(to: CGPoint(x: size.width, y: Double(i * 5)))
                            context.stroke(path, with: .color(theme.accent.opacity(0.025)), lineWidth: 1)
                        }
                        for i in 0..<16 {
                            let x = Double((i * 139) % 521)
                            let y = Double((i * 97) % 700)
                            var path = Path(); path.move(to: CGPoint(x: x, y: y)); path.addLine(to: CGPoint(x: x + 20, y: y)); path.addLine(to: CGPoint(x: x + 38, y: y + 18))
                            context.stroke(path, with: .color(theme.secondary.opacity(0.13)), lineWidth: 1)
                        }
                    }
                }
                LinearGradient(colors: [.clear, theme.background.last!.opacity(0.7)], startPoint: .center, endPoint: .bottom)
            }.frame(width: geo.size.width, height: geo.size.height)
        }.allowsHitTesting(false)
    }
}

struct OrbitDial: View {
    @ObservedObject var model: OrbitModel
    var theme: OrbitTheme { model.theme }
    var body: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [theme.accent.opacity(0.065), .clear], center: .center, startRadius: 15, endRadius: 172)).padding(14)
            Circle().stroke(.white.opacity(0.04), style: StrokeStyle(lineWidth: 1, dash: [1, 7])).padding(6)
            ForEach(0..<60, id: \.self) { i in
                Rectangle().fill(theme.accent.opacity(i % 5 == 0 ? 0.32 : 0.12)).frame(width: 1, height: i % 5 == 0 ? 7 : 3).offset(y: -163).rotationEffect(.degrees(Double(i) * 6))
            }
            Circle().stroke(theme.accent.opacity(0.11), lineWidth: 2).padding(24)
            Circle().trim(from: 0, to: max(0.003, 1 - model.engine.progress))
                .stroke(AngularGradient(colors: [theme.secondary.opacity(0.55), theme.accent, theme.accent], center: .center, startAngle: .degrees(0), endAngle: .degrees(360)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90)).padding(24).shadow(color: theme.accent.opacity(0.5), radius: 9)
            Ellipse().stroke(theme.secondary.opacity(0.20), lineWidth: 0.7).frame(width: 366, height: 115).rotationEffect(.degrees(-27))
            Circle().fill(LinearGradient(colors: [.white, theme.accent], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 11, height: 11).shadow(color: theme.accent, radius: 9).offset(y: -156).rotationEffect(.degrees(360 * (1 - model.engine.progress)))
            Circle().fill(LinearGradient(colors: [theme.secondary, theme.background[0]], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 14, height: 14).offset(x: -153, y: 64)
            VStack(spacing: 17) {
                Text(model.engine.display).font(.system(size: 76, weight: .ultraLight, design: .monospaced)).tracking(-5).foregroundStyle(LinearGradient(colors: [.white, theme.accent.opacity(0.85)], startPoint: .top, endPoint: .bottom)).contentTransition(.numericText(countsDown: true)).monospacedDigit().accessibilityLabel("Time remaining \(model.engine.display)")
                Rectangle().fill(theme.accent.opacity(0.6)).frame(width: 24, height: 1)
                Text(model.engine.isRunning ? "IN YOUR ORBIT" : model.engine.mode == .focus ? "TIME TO FOCUS" : "ROOM TO BREATHE").font(.system(size: 9, weight: .medium, design: .monospaced)).tracking(3).foregroundStyle(theme.accent.opacity(0.72))
            }
        }.frame(width: 360, height: 360)
    }
}

struct OrbitButtonStyle: ButtonStyle {
    var accent: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.97 : 1).brightness(configuration.isPressed ? -0.08 : 0).animation(.easeOut(duration: 0.13), value: configuration.isPressed)
    }
}

struct WindowReader: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.identifier = NSUserInterfaceItemIdentifier("orbit-main")
            window.titlebarAppearsTransparent = true
            window.backgroundColor = .clear
            window.isMovableByWindowBackground = true
            window.titleVisibility = .hidden
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct ContentView: View {
    @ObservedObject var model: OrbitModel
    var theme: OrbitTheme { model.theme }
    var body: some View {
        ZStack {
            Atmosphere(theme: theme)
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: theme.symbol).font(.system(size: 24, weight: .ultraLight)).rotationEffect(.degrees(-25)).foregroundStyle(theme.accent)
                    Text("O R B I T").font(.system(size: 13, weight: .medium))
                    Spacer()
                    HStack(spacing: 5) { Circle().fill(theme.accent).frame(width: 4, height: 4); Text(theme.label).font(.system(size: 8, design: .monospaced)).tracking(1.4) }.foregroundStyle(theme.accent.opacity(0.7))
                }.padding(.top, 16)
                HStack(spacing: 4) {
                    ForEach(SessionMode.allCases, id: \.self) { mode in
                        Button { model.select(mode) } label: {
                            Text(mode.title).font(.system(size: 11, weight: model.engine.mode == mode ? .semibold : .regular)).frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background { if model.engine.mode == mode { ThemePanel(theme: theme).fill(LinearGradient(colors: [theme.accent.opacity(0.23), theme.secondary.opacity(0.14)], startPoint: .topLeading, endPoint: .bottomTrailing)).overlay(ThemePanel(theme: theme).stroke(theme.accent.opacity(0.25), lineWidth: 0.7)) } }
                        }.buttonStyle(.plain).foregroundStyle(model.engine.mode == mode ? .white : .white.opacity(0.48))
                    }
                }.padding(4).background(.black.opacity(0.17), in: ThemePanel(theme: theme)).overlay(ThemePanel(theme: theme).stroke(.white.opacity(0.08), lineWidth: 1)).padding(.top, 30)
                Group {
                    switch theme {
                    case .stellar: OrbitDial(model: model)
                    case .synthwave: SynthwaveDial(model: model)
                    case .cyberpunk: CyberpunkDial(model: model)
                    }
                }.padding(.top, 15)
                Text(theme.caption).font(.system(size: 12)).foregroundStyle(.white.opacity(0.42)).padding(.top, 0)
                HStack(spacing: 12) {
                    Button { model.toggle() } label: {
                        HStack(spacing: 12) { Image(systemName: model.engine.isRunning ? "pause.fill" : "play.fill").font(.system(size: 12)); Text(model.engine.isRunning ? "Pause session" : model.engine.remaining < model.engine.duration ? "Resume session" : "Start session").font(.system(size: 14, weight: .medium)).tracking(1) }
                            .foregroundStyle(theme.background.last!).frame(width: 258, height: 52)
                            .background(LinearGradient(colors: [theme.accent, theme.secondary], startPoint: .topLeading, endPoint: .bottomTrailing), in: ThemePanel(theme: theme)).overlay(ThemePanel(theme: theme).stroke(.white.opacity(0.3), lineWidth: 1)).shadow(color: theme.accent.opacity(0.12), radius: 18, y: 6)
                    }.buttonStyle(OrbitButtonStyle(accent: theme.accent)).keyboardShortcut(.space, modifiers: []).help("Start or pause · Space")
                    Button { model.reset() } label: { Image(systemName: "arrow.counterclockwise").font(.system(size: 16, weight: .light)).frame(width: 50, height: 50).background(.white.opacity(0.035), in: Circle()).overlay(Circle().stroke(.white.opacity(0.12), lineWidth: 1)) }.buttonStyle(.plain).help("Reset timer · ⌘R").keyboardShortcut("r", modifiers: .command)
                }.padding(.top, 25)
                VStack(spacing: 10) {
                    HStack(spacing: 16) { ForEach(0..<4) { index in Circle().fill(index < (model.engine.completed % 4 == 0 && model.engine.completed > 0 ? 4 : model.engine.completed % 4) ? theme.accent : .clear).frame(width: 9, height: 9).overlay(Circle().stroke(theme.accent.opacity(0.45), lineWidth: 1)) } }
                    Text("\(model.engine.completed) completed · cycle \(model.engine.completed / 4 + 1)").font(.system(size: 9, design: .monospaced)).tracking(1).foregroundStyle(.white.opacity(0.4))
                }.padding(.top, 26)
                Spacer(minLength: 16)
                if let completion = model.completion {
                    HStack { Image(systemName: "checkmark.circle.fill"); Text(completion).font(.system(size: 11)); Button { model.completion = nil } label: { Image(systemName: "xmark") }.buttonStyle(.plain) }.foregroundStyle(theme.accent).padding(10).background(theme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 10)).padding(.bottom, 10)
                }
                Rectangle().fill(.white.opacity(0.09)).frame(height: 1)
                HStack {
                    Menu {
                        ForEach(OrbitTheme.allCases) { option in Button { withAnimation(.easeInOut(duration: 0.4)) { model.theme = option } } label: { if option == theme { Label(option.rawValue, systemImage: "checkmark") } else { Text(option.rawValue) } } }
                    } label: { HStack(spacing: 7) { Circle().fill(LinearGradient(colors: [theme.accent, theme.secondary], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 10, height: 10); Text(theme.rawValue).font(.system(size: 10)); Image(systemName: "chevron.down").font(.system(size: 7)) } }.menuStyle(.borderlessButton).fixedSize().help("Choose theme")
                    Spacer()
                    Text("\(Int(model.engine.durations[.focus]! / 60)) / \(Int(model.engine.durations[.shortBreak]! / 60)) / \(Int(model.engine.durations[.longBreak]! / 60)) MIN").font(.system(size: 8, design: .monospaced)).tracking(1).foregroundStyle(.white.opacity(0.35))
                    Button { model.showSettings = true } label: { Image(systemName: "slider.horizontal.3").font(.system(size: 13)).padding(6) }.buttonStyle(.plain).padding(.leading, 10).help("Settings · ⌘,").keyboardShortcut(",", modifiers: .command)
                }.foregroundStyle(.white.opacity(0.7)).padding(.vertical, 17)
            }.padding(.horizontal, 36)
        }.frame(width: 500, height: 720).preferredColorScheme(.dark).background(WindowReader()).sheet(isPresented: $model.showSettings) { SettingsView(model: model) }
    }
}

struct SettingsView: View {
    @ObservedObject var model: OrbitModel
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack { Text("Make it your orbit.").font(.system(size: 23, weight: .light)); Spacer(); Button("Done") { model.showSettings = false }.keyboardShortcut(.defaultAction) }
            Text("APPEARANCE").font(.system(size: 9, design: .monospaced)).tracking(2).foregroundStyle(.secondary)
            HStack(spacing: 10) { ForEach(OrbitTheme.allCases) { option in
                Button { model.theme = option } label: {
                    VStack(spacing: 8) { Image(systemName: option.symbol).font(.system(size: 25, weight: .light)).foregroundStyle(LinearGradient(colors: [option.accent, option.secondary], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 30, height: 30); Text(option.rawValue).font(.system(size: 11)) }.frame(maxWidth: .infinity).padding(.vertical, 14).background(LinearGradient(colors: option.background, startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(model.theme == option ? option.accent : .white.opacity(0.1), lineWidth: 1))
                }.buttonStyle(.plain)
            } }
            Text("SESSION LENGTHS").font(.system(size: 9, design: .monospaced)).tracking(2).foregroundStyle(.secondary)
            ForEach(SessionMode.allCases, id: \.self) { mode in
                HStack { Text(mode.title); Spacer(); Stepper(value: Binding(get: { Int(model.engine.durations[mode]! / 60) }, set: { model.setMinutes(Double($0), for: mode) }), in: 1...180) { Text("\(Int(model.engine.durations[mode]! / 60)) min").monospacedDigit().frame(width: 65, alignment: .trailing) }.fixedSize() }
            }
            Text("Changing the current session length resets its timer. Sessions wait for you to start; every fourth focus session earns a long break.").font(.system(size: 11)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Divider()
            Toggle("Completion sound", isOn: $model.sound).tint(model.theme.accent)
            Toggle("Keep window on top", isOn: $model.alwaysOnTop).tint(model.theme.accent)
            HStack { Button("Try a 10-second demo") { model.demo() }; Spacer(); Text("SPACE  start / pause").font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary) }
        }.padding(28).frame(width: 450).background(LinearGradient(colors: model.theme.background, startPoint: .topLeading, endPoint: .bottomTrailing)).preferredColorScheme(.dark)
    }
}

@main struct OrbitApp: App {
    @StateObject private var model = OrbitModel()
    var body: some Scene {
        Window("Orbit", id: "main") { ContentView(model: model) }.windowStyle(.hiddenTitleBar).windowResizability(.contentSize).defaultPosition(.center)
        MenuBarExtra { Button("Open Orbit") { model.openWindow() }; Divider(); Text(model.engine.mode.title + " · " + model.engine.display); Button(model.engine.isRunning ? "Pause" : "Start") { model.toggle() }; Button("Reset") { model.reset() }; Divider(); Button("Quit Orbit") { model.save(); NSApp.terminate(nil) } } label: { Image(systemName: "circle.dotted.circle"); if model.engine.isRunning { Text(model.engine.display).monospacedDigit() } }
    }
}
