//
//  CelebrationOverlay.swift
//  DayByDay
//

import SwiftUI

/// A short confetti burst for a correct answer. With Reduce Motion on,
/// a few sparkles fade in and out instead.
struct CelebrationOverlay: View {
    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startDate = Date()

    static let duration: Double = 1.1

    var body: some View {
        Group {
            if isActive {
                if reduceMotion {
                    sparkles
                } else {
                    confetti
                }
            }
        }
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.25), value: isActive)
        .onChange(of: isActive) { _, active in
            if active { startDate = Date() }
        }
    }

    private var sparkles: some View {
        HStack(spacing: 40) {
            ForEach(0..<3, id: \.self) { _ in
                Image(systemName: "sparkles")
                    .font(.system(size: 56))
                    .foregroundStyle(.yellow)
            }
        }
        .transition(.opacity)
    }

    private var confetti: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSince(startDate)
                guard t < Self.duration else { return }
                let fade = 1 - max(0, (t - Self.duration * 0.6) / (Self.duration * 0.4))
                for p in Self.particles {
                    let x = size.width * (0.5 + p.vx * t)
                    let y = size.height * (0.45 + p.vy * t + 0.9 * t * t)
                    var piece = context
                    piece.opacity = fade
                    piece.translateBy(x: x, y: y)
                    piece.rotate(by: .degrees(p.spin * t))
                    piece.fill(Path(roundedRect: CGRect(x: -6, y: -3, width: 12, height: 6), cornerRadius: 2),
                               with: .color(p.color))
                }
            }
        }
    }

    private struct Particle {
        let vx: Double
        let vy: Double
        let spin: Double
        let color: Color
    }

    private static let particles: [Particle] = {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        var rng = SystemRandomNumberGenerator()
        return (0..<60).map { i in
            Particle(vx: .random(in: -0.6...0.6, using: &rng),
                     vy: .random(in: -1.0 ... -0.3, using: &rng),
                     spin: .random(in: -540...540, using: &rng),
                     color: colors[i % colors.count])
        }
    }()
}
