//
//  ShakeRain.swift
//  DayByDay
//

import SwiftUI
import UIKit

extension Notification.Name {
    static let deviceDidShake = Notification.Name("deviceDidShake")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
        super.motionEnded(motion, with: event)
    }
}

extension View {
    func onShake(_ action: @escaping () -> Void) -> some View {
        onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in action() }
    }
}

/// Rain falling over the screen for a few seconds. With Reduce Motion the
/// drops hold still and fade.
struct RainOverlay: View {
    static let duration = 3.0
    static let dropColor = Color(red: 0.10, green: 0.40, blue: 0.85)

    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()

    private static let drops: [(x: Double, phase: Double, speed: Double)] = {
        var rng = SystemRandomNumberGenerator()
        return (0..<70).map { _ in
            (Double.random(in: 0...1, using: &rng), Double.random(in: 0...1, using: &rng),
             Double.random(in: 0.8...1.3, using: &rng))
        }
    }()

    var body: some View {
        Group {
            if isActive {
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        let t = timeline.date.timeIntervalSince(start)
                        guard t < Self.duration else { return }
                        let fade = min(1, (Self.duration - t) / 0.6)
                        context.opacity = fade
                        for drop in Self.drops {
                            let y = reduceMotion
                                ? drop.phase
                                : (drop.phase + t * drop.speed * 0.9).truncatingRemainder(dividingBy: 1.1) - 0.05
                            let rect = CGRect(x: drop.x * size.width, y: y * size.height, width: 5, height: 22)
                            context.fill(Path(roundedRect: rect, cornerRadius: 2.5), with: .color(Self.dropColor))
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, active in
            if active { start = Date() }
        }
    }
}
