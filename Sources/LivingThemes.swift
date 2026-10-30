import SwiftUI
import AppKit

struct SessionPalette {
    var theme: OrbitTheme
    var isBreak: Bool
    var accent: Color {
        guard isBreak else { return theme.accent }
        switch theme { case .stellar: return OrbitTheme.hex(0xC0C9FF); case .synthwave: return OrbitTheme.hex(0x8BECEB); case .cyberpunk: return OrbitTheme.hex(0x75DACE) }
    }
    var secondary: Color {
        guard isBreak else { return theme.secondary }
        switch theme { case .stellar: return OrbitTheme.hex(0x9C8DCE); case .synthwave: return OrbitTheme.hex(0x8296EF); case .cyberpunk: return OrbitTheme.hex(0x8B9FC9) }
    }
    var background: [Color] {
        guard isBreak else { return theme.background }
        switch theme {
        case .stellar: return [OrbitTheme.hex(0x282C49), OrbitTheme.hex(0x171B33), OrbitTheme.hex(0x0C1224)]
        case .synthwave: return [OrbitTheme.hex(0x203F58), OrbitTheme.hex(0x242743), OrbitTheme.hex(0x101B2C)]
        case .cyberpunk: return [OrbitTheme.hex(0x1D343E), OrbitTheme.hex(0x192A34), OrbitTheme.hex(0x101B27)]
        }
    }
}

@MainActor final class MiniWindowController: NSObject, NSWindowDelegate {
    private weak var model: OrbitModel?
    private let panel: NSPanel
    init(model: OrbitModel) {
        self.model = model
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 336, height: 156), styleMask: [.titled, .closable, .fullSizeContentView, .utilityWindow], backing: .buffered, defer: false)
        super.init()
        panel.title = "Orbit Mini"
        panel.identifier = NSUserInterfaceItemIdentifier("orbit-mini")
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(rootView: MiniTimerView(model: model))
        panel.delegate = self
        panel.setFrameAutosaveName("OrbitMiniPosition")
        if !panel.setFrameUsingName("OrbitMiniPosition"), let screen = NSScreen.main {
            let frame = screen.visibleFrame
            panel.setFrameTopLeftPoint(NSPoint(x: frame.maxX - 360, y: frame.maxY - 24))
        }
    }
    func show() { panel.makeKeyAndOrderFront(nil) }
    func hide() { panel.orderOut(nil) }
    func windowWillClose(_ notification: Notification) { model?.leaveMini() }
}

struct MiniTimerView: View {
    @ObservedObject var model: OrbitModel
    private var palette: SessionPalette { model.palette }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: model.theme.symbol).foregroundStyle(palette.accent)
                Text("ORBIT").tracking(2)
                Spacer()
                Menu {
                    ForEach(SessionMode.allCases, id: \.self) { mode in Button(mode.title) { model.select(mode) } }
                    Divider()
                    ForEach(OrbitTheme.allCases) { theme in Button(theme.rawValue) { model.theme = theme } }
                } label: { Text(model.engine.mode.title).font(.system(size: 10)).foregroundStyle(palette.accent) }.menuStyle(.borderlessButton).fixedSize().help("Session and theme")
                Button { model.leaveMini() } label: { Image(systemName: "arrow.up.left.and.arrow.down.right").padding(4) }.buttonStyle(.plain).help("Expand timer · ⇧⌘M").accessibilityLabel("Expand timer").keyboardShortcut("m", modifiers: [.command, .shift])
            }.font(.system(size: 9, weight: .medium)).foregroundStyle(.white.opacity(0.6))
            HStack(spacing: 12) {
                Text(model.engine.display).font(.system(size: 43, weight: model.theme == .stellar ? .light : .semibold, design: .monospaced)).tracking(-2).monospacedDigit().foregroundStyle(LinearGradient(colors: [.white, palette.accent], startPoint: .top, endPoint: .bottom)).accessibilityLabel("Time remaining \(model.engine.display)")
                Spacer(minLength: 0)
                Button { model.toggle() } label: { Image(systemName: model.engine.isRunning ? "pause.fill" : "play.fill").font(.system(size: 13)).foregroundStyle(palette.background.last!).frame(width: 38, height: 38).background(LinearGradient(colors: [palette.accent, palette.secondary], startPoint: .topLeading, endPoint: .bottomTrailing), in: ThemePanel(theme: model.theme)) }.buttonStyle(.plain).accessibilityLabel(model.engine.isRunning ? "Pause session" : "Start session").keyboardShortcut(.space, modifiers: [])
                Button { model.reset() } label: { Image(systemName: "arrow.counterclockwise").font(.system(size: 13)).frame(width: 25, height: 32) }.buttonStyle(.plain).accessibilityLabel("Reset timer").keyboardShortcut("r", modifiers: .command)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.08))
                    Capsule().fill(LinearGradient(colors: [palette.accent, palette.secondary], startPoint: .leading, endPoint: .trailing)).frame(width: max(2, geo.size.width * (1 - model.engine.progress)))
                }
            }.frame(height: 3)
            Text(model.completion ?? "\(model.engine.completed) completed · \(model.theme.rawValue)").font(.system(size: 9, design: .monospaced)).foregroundStyle(model.completion == nil ? .white.opacity(0.4) : palette.accent).lineLimit(1)
        }.padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 14).frame(width: 336, height: 156).background(LinearGradient(colors: palette.background, startPoint: .topLeading, endPoint: .bottomTrailing)).preferredColorScheme(.dark)
    }
}
