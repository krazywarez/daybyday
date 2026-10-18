//
//  MascotView.swift
//  DayByDay
//

import SwiftUI

enum MascotStyle {
    /// Shows on white and on black.
    static let body = Color(red: 0.55, green: 0.36, blue: 0.85)
    static let belly = Color(red: 0.93, green: 0.89, blue: 1.0)
    static let ink = Color(red: 0.12, green: 0.08, blue: 0.25)
    static let beak = Color(red: 1.0, green: 0.88, blue: 0.45)
    static let eyeWhite = Color.white
}

/// The owl. Moves gently unless Reduce Motion is on, then holds the mood's
/// still pose.
struct MascotView: View {
    let mood: MascotMood

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var moodStart = Date.now

    var body: some View {
        Group {
            if reduceMotion {
                OwlCanvas(mood: mood, pose: MascotMotion.still(mood))
            } else {
                TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
                    OwlCanvas(mood: mood, pose: MascotMotion.pose(mood, at: timeline.date.timeIntervalSince(moodStart)))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onChange(of: mood) { moodStart = .now }
        .accessibilityHidden(true)
    }
}

/// The owl in one pose.
struct OwlCanvas: View {
    let mood: MascotMood
    let pose: MascotPose

    var body: some View {
        Canvas { context, size in
            // 110 wide, so the raised wings stay inside the frame.
            let scale = min(size.width, size.height) / 110
            context.translateBy(x: (size.width - 100 * scale) / 2, y: (size.height - 100 * scale) / 2)
            context.scaleBy(x: scale, y: scale)
            OwlDrawing(mood: mood, pose: pose).draw(in: &context)
        }
    }
}

/// The owl in a 100×100 space.
private struct OwlDrawing {
    let mood: MascotMood
    let pose: MascotPose

    private let body = GraphicsContext.Shading.color(MascotStyle.body)
    private let ink = GraphicsContext.Shading.color(MascotStyle.ink)
    private let beak = GraphicsContext.Shading.color(MascotStyle.beak)
    private let white = GraphicsContext.Shading.color(MascotStyle.eyeWhite)

    func draw(in context: inout GraphicsContext) {
        context.translateBy(x: 0, y: (pose.bob + pose.hop) * 100)
        // Lean from the feet.
        context.translateBy(x: 50, y: 89)
        context.rotate(by: .degrees(pose.tilt))
        context.translateBy(x: -50, y: -89)

        wing(&context, left: true, lift: mood == .cheering ? pose.wing : 0)
        wing(&context, left: false, lift: pose.wing)

        context.fill(Path(ellipseIn: CGRect(x: 20, y: 23, width: 60, height: 66)), with: body)
        context.fill(tuft(left: true), with: body)
        context.fill(tuft(left: false), with: body)

        context.fill(Path(ellipseIn: CGRect(x: 31, y: 64, width: 38, height: 24)), with: .color(MascotStyle.belly))
        for (x, y) in [(43.0, 70.0), (57.0, 70.0), (50.0, 77.0)] {
            var chevron = Path()
            chevron.move(to: CGPoint(x: x - 3, y: y))
            chevron.addLine(to: CGPoint(x: x, y: y + 2.5))
            chevron.addLine(to: CGPoint(x: x + 3, y: y))
            context.stroke(chevron, with: ink, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
        }
        for x in [38.0, 62.0] {
            for dx in [-4.0, 0, 4] {
                context.fill(Path(ellipseIn: CGRect(x: x + dx - 2.2, y: 85, width: 4.4, height: 6)), with: beak)
            }
        }

        eye(&context, x: 37)
        eye(&context, x: 63)
        brows(&context)
        beakShape(&context)

        if mood == .puzzled {
            let mark = context.resolve(Text("?").font(.custom(HeadingFont.extraBold, fixedSize: 24))
                .foregroundStyle(MascotStyle.body))
            context.draw(mark, at: CGPoint(x: 89, y: 22))
        }
    }

    private func tuft(left: Bool) -> Path {
        let f: (Double) -> Double = { left ? $0 : 100 - $0 }
        var p = Path()
        p.move(to: CGPoint(x: f(25), y: 42))
        p.addQuadCurve(to: CGPoint(x: f(27), y: 13), control: CGPoint(x: f(20), y: 22))
        p.addQuadCurve(to: CGPoint(x: f(44), y: 27), control: CGPoint(x: f(36), y: 18))
        p.closeSubpath()
        return p
    }

    /// Hangs from the shoulder; `lift` raises it outward.
    private func wing(_ context: inout GraphicsContext, left: Bool, lift: Double) {
        var c = context
        c.translateBy(x: left ? 24 : 76, y: 52)
        c.rotate(by: .degrees(left ? 12 + lift : -12 - lift))
        let shape = Path(ellipseIn: CGRect(x: -7, y: -2, width: 14, height: 32))
        c.fill(shape, with: body)
        c.stroke(shape, with: ink, lineWidth: 1.6)
    }

    private func eye(_ context: inout GraphicsContext, x: Double) {
        let center = CGPoint(x: x, y: 45)
        if mood == .cheering {
            context.fill(Path(ellipseIn: CGRect(x: x - 12, y: 33, width: 24, height: 24)), with: white)
            var arc = Path()
            arc.move(to: CGPoint(x: x - 7, y: 48))
            arc.addQuadCurve(to: CGPoint(x: x + 7, y: 48), control: CGPoint(x: x, y: 36))
            context.stroke(arc, with: ink, style: StrokeStyle(lineWidth: 3.6, lineCap: .round))
            return
        }
        if pose.eyeOpen < 0.5 {
            var lid = Path()
            lid.move(to: CGPoint(x: x - 9, y: 46))
            lid.addQuadCurve(to: CGPoint(x: x + 9, y: 46), control: CGPoint(x: x, y: 50))
            context.stroke(lid, with: white, style: StrokeStyle(lineWidth: 3.6, lineCap: .round))
            return
        }
        var c = context
        c.translateBy(x: center.x, y: center.y)
        c.scaleBy(x: 1, y: pose.eyeOpen)
        c.fill(Path(ellipseIn: CGRect(x: -12, y: -12, width: 24, height: 24)), with: white)
        // Pupils look a little toward the middle.
        let dx: Double = x < 50 ? 1.5 : -1.5
        c.fill(Path(ellipseIn: CGRect(x: dx - 6.5, y: -5.5, width: 13, height: 13)), with: ink)
        c.fill(Path(ellipseIn: CGRect(x: dx - 3.5, y: -3.5, width: 4, height: 4)), with: white)
    }

    private func brows(_ context: inout GraphicsContext) {
        let lines: [(CGPoint, CGPoint, CGPoint)]
        switch mood {
        case .asking:
            lines = [(CGPoint(x: 28, y: 30), CGPoint(x: 37, y: 25), CGPoint(x: 45, y: 29)),
                     (CGPoint(x: 55, y: 29), CGPoint(x: 63, y: 25), CGPoint(x: 72, y: 30))]
        case .puzzled:
            lines = [(CGPoint(x: 28, y: 28), CGPoint(x: 36, y: 21), CGPoint(x: 45, y: 26)),
                     (CGPoint(x: 55, y: 30), CGPoint(x: 63, y: 27), CGPoint(x: 71, y: 29))]
        default:
            return
        }
        for (a, control, b) in lines {
            var p = Path()
            p.move(to: a)
            p.addQuadCurve(to: b, control: control)
            context.stroke(p, with: ink, style: StrokeStyle(lineWidth: 3.6, lineCap: .round))
        }
    }

    private func beakShape(_ context: inout GraphicsContext) {
        let gap = 4 * pose.beakOpen
        if gap > 0.2 {
            context.fill(Path(ellipseIn: CGRect(x: 45.5, y: 54, width: 9, height: 4 + gap)), with: ink)
        }
        var upper = Path()
        upper.move(to: CGPoint(x: 44, y: 52))
        upper.addLine(to: CGPoint(x: 56, y: 52))
        upper.addLine(to: CGPoint(x: 50, y: 60))
        upper.closeSubpath()
        context.fill(upper, with: beak)
        if gap > 0.2 {
            var lower = Path()
            lower.move(to: CGPoint(x: 46.5, y: 57 + gap))
            lower.addLine(to: CGPoint(x: 53.5, y: 57 + gap))
            lower.addLine(to: CGPoint(x: 50, y: 61 + gap))
            lower.closeSubpath()
            context.fill(lower, with: beak)
        }
    }
}

#Preview {
    HStack {
        ForEach(MascotMood.allCases, id: \.self) { MascotView(mood: $0).frame(width: 120) }
    }
}
