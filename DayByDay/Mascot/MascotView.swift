//
//  MascotView.swift
//  DayByDay
//

import SwiftUI

/// Placeholder mascot: a round green face. Replaced in part 6.
struct MascotView: View {
    enum Mood { case idle, cheering }

    let mood: Mood

    init(mood: Mood) {
        self.mood = mood
    }

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                Circle().fill(Color(red: 0.35, green: 0.76, blue: 0.56).gradient)
                HStack(spacing: s * 0.2) {
                    eye(s)
                    eye(s)
                }
                .offset(y: -s * 0.1)
                smile(s)
                    .stroke(.black.opacity(0.8), style: StrokeStyle(lineWidth: s * 0.05, lineCap: .round))
                    .frame(width: s * (mood == .cheering ? 0.5 : 0.36), height: s * 0.2)
                    .offset(y: s * 0.17)
            }
            .frame(width: s, height: s)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private func eye(_ s: CGFloat) -> some View {
        Capsule().fill(.black.opacity(0.85)).frame(width: s * 0.09, height: s * 0.14)
    }

    private func smile(_ s: CGFloat) -> Path {
        Path { p in
            p.move(to: CGPoint(x: 0, y: 0))
            p.addQuadCurve(to: CGPoint(x: 1, y: 0), control: CGPoint(x: 0.5, y: 1.4))
        }
        .applying(CGAffineTransform(scaleX: s * (mood == .cheering ? 0.5 : 0.36), y: s * 0.2))
    }
}

#Preview {
    HStack {
        MascotView(mood: .idle).frame(width: 120)
        MascotView(mood: .cheering).frame(width: 120)
    }
}
