import SwiftUI

struct ThemePanel: Shape {
    var theme: OrbitTheme
    func path(in rect: CGRect) -> Path {
        if theme != .cyberpunk { return RoundedRectangle(cornerRadius: theme == .stellar ? rect.height / 2 : 10).path(in: rect) }
        let cut: CGFloat = 12
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + cut, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cut))
        p.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cut))
        p.closeSubpath(); return p
    }
}

struct SynthwaveDial: View {
    @ObservedObject var model: OrbitModel
    var phase: Double = 0
    private var palette: SessionPalette { model.palette }
    private var theme: OrbitTheme { .synthwave }
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ZStack {
                    Circle().fill(RadialGradient(colors: [palette.secondary.opacity(0.28), palette.accent.opacity(0.08), .clear], center: .center, startRadius: 15, endRadius: 125)).frame(width: 250, height: 230)
                    Circle().fill(LinearGradient(colors: [model.engine.mode == .focus ? Color(red: 1, green: 0.76, blue: 0.36) : palette.accent, palette.secondary, model.engine.mode == .focus ? Color(red: 1, green: 0.2, blue: 0.6) : palette.secondary.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 168, height: 168)
                        .mask { VStack(spacing: 0) { Rectangle().frame(height: 84); ForEach(0..<7) { i in Color.clear.frame(height: CGFloat(i + 2)); Rectangle().frame(height: CGFloat(10 - i)) }; Spacer(minLength: 0) }.frame(height: 168) }
                        .offset(y: 46 * model.engine.progress)
                        .opacity(1 - model.engine.progress * 0.45)
                        .frame(width: 220, height: 190).clipped()
                    Text(model.engine.mode == .focus ? "FOCUS CLUB" : "SLOW CLUB").font(.system(size: 32, weight: .black, design: .rounded)).italic().tracking(-1).foregroundStyle(LinearGradient(colors: [.white, palette.accent], startPoint: .top, endPoint: .bottom)).rotationEffect(.degrees(-7)).shadow(color: palette.accent.opacity(0.7), radius: 12).offset(y: 52)
                }.frame(height: 215)
                Spacer()
            }
            VStack(spacing: 12) {
                Spacer().frame(height: 200)
                Text(model.engine.display).font(.system(size: 80, weight: .heavy, design: .rounded)).italic().monospacedDigit().tracking(-3)
                    .foregroundStyle(LinearGradient(colors: [.white, model.engine.mode == .focus ? Color(red: 1, green: 0.7, blue: 0.91) : palette.accent, palette.accent], startPoint: .top, endPoint: .bottom)).shadow(color: palette.accent.opacity(0.3), radius: 18).accessibilityLabel("Time remaining \(model.engine.display)")
                HStack(spacing: 3) {
                    ForEach(0..<40, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 1).fill(LinearGradient(colors: [palette.secondary, palette.accent], startPoint: .top, endPoint: .bottom)).opacity(Double(i) / 40 < 1 - model.engine.progress ? 0.85 : 0.12).frame(width: 5, height: (i % 5 == 0 ? 14 : 8) + (model.engine.isRunning && model.livingEffects ? 5 * sin(phase * 24 + Double(i) * 0.8) : 0))
                    }
                }
                Text(model.engine.isRunning ? "ON AIR  /  \(model.engine.mode.title.uppercased())" : "PRESS PLAY. FIND YOUR FLOW.").font(.system(size: 8, weight: .medium, design: .monospaced)).tracking(2.3).foregroundStyle(palette.accent.opacity(0.8))
                Spacer(minLength: 0)
            }
        }.frame(width: 360, height: 360)
    }
}

struct CyberpunkDial: View {
    @ObservedObject var model: OrbitModel
    var phase: Double = 0
    private var palette: SessionPalette { model.palette }
    private var theme: OrbitTheme { .cyberpunk }
    private var status: String { model.engine.isRunning ? (model.engine.mode == .focus ? "SESSION ACTIVE" : "RECOVERY ACTIVE") : "AWAITING INPUT" }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Rectangle().fill(palette.accent).frame(width: 5, height: 18)
                Text(model.engine.mode == .focus ? "FOCUS_PROTOCOL" : "RECOVERY_MODE").font(.system(size: 13, weight: .bold, design: .monospaced)).tracking(1)
                Spacer()
                Text("[\(String(format: "%02d", model.engine.completed + 1))]").font(.system(size: 11, design: .monospaced)).foregroundStyle(palette.secondary)
            }.foregroundStyle(palette.accent).padding(.bottom, 25)
            VStack(alignment: .leading, spacing: 18) {
                HStack { Text("TIME REMAINING"); Spacer(); Image(systemName: model.engine.isRunning ? "waveform.path" : "pause") }.font(.system(size: 8, weight: .medium, design: .monospaced)).tracking(2).foregroundStyle(palette.secondary)
                Text(model.engine.display).font(.system(size: 77, weight: .semibold, design: .monospaced)).monospacedDigit().tracking(-5)
                    .foregroundStyle(LinearGradient(colors: [palette.accent, palette.secondary], startPoint: .topLeading, endPoint: .bottomTrailing)).shadow(color: palette.accent.opacity(0.18), radius: 10).accessibilityLabel("Time remaining \(model.engine.display)")
                HStack(spacing: 4) { ForEach(0..<28, id: \.self) { index in
                    Rectangle().fill(LinearGradient(colors: [palette.accent, palette.secondary], startPoint: .top, endPoint: .bottom)).opacity(Double(index) / 28 < 1 - model.engine.progress ? 0.7 + 0.25 * sin(phase * 12 + Double(index) * 0.35) : 0.1).frame(height: 18)
                } }
                HStack { Text(status); Spacer(); Text("\(Int(ceil((1 - model.engine.progress) * 100)))%") }.font(.system(size: 8, weight: .medium, design: .monospaced)).tracking(1.2).foregroundStyle(palette.accent.opacity(0.8))
            }.padding(22).background(LinearGradient(colors: [.black.opacity(0.30), palette.secondary.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing), in: ThemePanel(theme: .cyberpunk)).overlay(ThemePanel(theme: .cyberpunk).stroke(LinearGradient(colors: [palette.accent.opacity(0.65), palette.secondary.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
            HStack(spacing: 5) {
                Text("//").foregroundStyle(palette.accent)
                Text(model.engine.mode == .focus ? "BLOCK DISTRACTIONS. EXECUTE." : "RECOVERY PROTOCOL.")
                Spacer()
                HStack(spacing: 2) { ForEach(0..<8) { i in Rectangle().fill(palette.secondary.opacity(0.4)).frame(width: i % 3 == 0 ? 3 : 1, height: 12) } }
            }.font(.system(size: 8, design: .monospaced)).tracking(0.8).foregroundStyle(palette.secondary.opacity(0.6)).padding(.top, 18)
            Spacer(minLength: 0)
        }.padding(.top, 35).frame(width: 360, height: 360)
    }
}
