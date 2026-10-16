//
//  YearWheelView.swift
//  DayByDay
//

import SwiftUI

extension Season {
    /// Wedge colors on the year wheel; white labels are at least 3:1 on each.
    var wheelColor: Color {
        switch self {
        case .spring: Color(red: 0.18, green: 0.56, blue: 0.28)
        case .summer: Color(red: 0.72, green: 0.48, blue: 0.0)
        case .fall:   Color(red: 0.55, green: 0.22, blue: 0.10)
        case .winter: Color(red: 0.0, green: 0.42, blue: 0.85)
        }
    }
}

/// Spin the wheel of months; it says where it lands and which season that is.
/// Tapping a month says the same for that month.
struct YearWheelView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rotation = 0.0
    @State private var spinning = false
    @State private var speechToken = 0
    /// Bumped when the screen goes away, so a pending landing says nothing.
    @State private var generation = 0

    private static let spinDuration = 2.5

    var body: some View {
        VStack(spacing: 32) {
            Pointer()
                .fill(Color.primary)
                .frame(width: 40, height: 34)
                .padding(.bottom, -40)
                .zIndex(1)
            wheel
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: 520)
            Button(action: spin) {
                Label("Spin!", systemImage: "arrow.clockwise.circle.fill")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 48)
                    .padding(.vertical, 22)
                    .background(Capsule().fill(Category.months.color))
            }
            .buttonStyle(.plain)
            .disabled(spinning)
        }
        .padding(24)
        .onAppear { say("Spin the wheel! Or tap a month.") }
        .onDisappear {
            generation += 1
            speechToken += 1
            SpeechSynthesizer.shared.stop()
        }
    }

    private var wheel: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                ForEach(Array(MonthOfYear.allCases.enumerated()), id: \.offset) { i, month in
                    let center = Double(i) * YearWheel.wedge
                    Wedge(center: center, width: YearWheel.wedge)
                        .fill(month.season.wheelColor)
                        .overlay(Wedge(center: center, width: YearWheel.wedge).stroke(.white, lineWidth: 2))
                        .contentShape(Wedge(center: center, width: YearWheel.wedge))
                        .onTapGesture {
                            guard !spinning else { return }
                            say(YearWheel.line(for: month))
                        }
                        .accessibilityLabel(month.name)
                        .accessibilityAddTraits(.isButton)
                    Text(month.name.prefix(3))
                        .font(.system(size: size * 0.06, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .offset(y: -size * 0.38)
                        .rotationEffect(.degrees(center))
                        .allowsHitTesting(false)
                }
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: size * 0.24)
                    .overlay(Circle().stroke(Color(.systemGray3), lineWidth: 2))
                    .allowsHitTesting(false)
            }
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func spin() {
        guard !spinning else { return }
        let current = YearWheel.month(atRotation: rotation)
        let month = MonthOfYear.allCases.filter { $0 != current }.randomElement()!
        let target = YearWheel.target(from: rotation, landingOn: month, turns: 3)
        spinning = true
        speechToken += 1
        SpeechSynthesizer.shared.stop()
        let duration = reduceMotion ? 0 : Self.spinDuration
        if reduceMotion {
            rotation = target
        } else {
            withAnimation(.timingCurve(0.15, 0.8, 0.3, 1, duration: duration)) { rotation = target }
        }
        let gen = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
            spinning = false
            guard gen == generation else { return }
            say(YearWheel.line(for: month))
        }
    }

    private func say(_ text: String) {
        speechToken += 1
        let token = speechToken, gen = generation
        DispatchQueue.main.async {
            if token == speechToken, gen == generation { SpeechSynthesizer.shared.speak(text) }
        }
    }
}

/// A pie slice centered `center` degrees clockwise from the top.
private struct Wedge: Shape {
    let center: Double
    let width: Double

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        // SwiftUI angles start at 3 o'clock; the top is -90°.
        let start = Angle.degrees(center - width / 2 - 90)
        let end = Angle.degrees(center + width / 2 - 90)
        var p = Path()
        p.move(to: c)
        p.addArc(center: c, radius: r, startAngle: start, endAngle: end, clockwise: false)
        p.closeSubpath()
        return p
    }
}

/// Downward triangle marking the month that is picked.
private struct Pointer: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
