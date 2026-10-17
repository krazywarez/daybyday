//
//  MascotMotion.swift
//  DayByDay
//

import Foundation

/// Where the mascot's parts are at one moment.
nonisolated struct MascotPose: Equatable {
    /// Up and down drift, as a fraction of the size; up is negative.
    var bob: Double
    /// Cheer hop, as a fraction of the size; up is negative.
    var hop: Double
    /// 1 open, 0.1 shut.
    var eyeOpen: Double
    /// Degrees the raised wing is lifted.
    var wing: Double
    /// Degrees the whole owl leans.
    var tilt: Double
    /// 0 closed, 1 wide open.
    var beakOpen: Double
}

/// Subtle motion for each mood: a slow bob, a blink, a hop when cheering, a
/// wave, and a talking beak when asking.
nonisolated enum MascotMotion {
    static let blinkCycle = 3.8
    static let blinkLength = 0.14

    /// The pose `t` seconds after the mood began.
    static func pose(_ mood: MascotMood, at t: TimeInterval) -> MascotPose {
        let t = max(0, t)
        var pose = still(mood)
        pose.bob = -0.012 * (1 - cos(2 * .pi * t / 2.6)) / 2
        if mood != .cheering, t.truncatingRemainder(dividingBy: blinkCycle) >= blinkCycle - blinkLength {
            pose.eyeOpen = 0.1
        }
        switch mood {
        case .cheering:
            if t.truncatingRemainder(dividingBy: 4) < 1.6 { pose.hop = -0.06 * abs(sin(.pi * t / 0.4)) }
        case .waving:
            if t.truncatingRemainder(dividingBy: 5) < 2.1 { pose.wing = 135 + 15 * sin(2 * .pi * t / 0.7) }
        case .asking:
            pose.beakOpen = 0.5 + 0.5 * abs(sin(.pi * t / 0.22))
        case .idle, .puzzled:
            break
        }
        return pose
    }

    /// The mood's pose with no motion, for Reduce Motion.
    static func still(_ mood: MascotMood) -> MascotPose {
        var pose = MascotPose(bob: 0, hop: 0, eyeOpen: 1, wing: 0, tilt: 0, beakOpen: 0)
        switch mood {
        case .idle: break
        case .asking: pose.tilt = 4; pose.beakOpen = 1
        case .cheering: pose.wing = 130
        case .puzzled: pose.tilt = -10
        case .waving: pose.wing = 135
        }
        return pose
    }
}
