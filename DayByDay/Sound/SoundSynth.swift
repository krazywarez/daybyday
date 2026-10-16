//
//  SoundSynth.swift
//  DayByDay
//

import Foundation

nonisolated enum SoundEffect: CaseIterable {
    case success, gentleMiss, tap, roundComplete
}

/// Renders sound effects to mono sample buffers. Notes are sines with soft
/// harmonics and smooth envelopes, so there are no clicks or harsh edges.
nonisolated enum SoundSynth {
    static let sampleRate: Double = 44_100

    private struct Note {
        let frequency: Double
        let start: Double
        let duration: Double
        var harmonics: [Double] = [1, 0.3, 0.1]
    }

    /// Silence at each end so playback never starts or stops mid-wave.
    private static let pad = 0.004

    static func render(_ effect: SoundEffect) -> [Float] {
        switch effect {
        case .success:
            mix([
                Note(frequency: 523.25, start: 0, duration: 0.14),
                Note(frequency: 659.25, start: 0.1, duration: 0.14),
                Note(frequency: 783.99, start: 0.2, duration: 0.22),
            ], peak: 0.6)
        case .gentleMiss:
            mix([
                Note(frequency: 329.63, start: 0, duration: 0.17, harmonics: [1, 0.15]),
                Note(frequency: 261.63, start: 0.15, duration: 0.18, harmonics: [1, 0.15]),
            ], peak: 0.3)
        case .tap:
            mix([Note(frequency: 880, start: 0, duration: 0.05, harmonics: [1, 0.2])], peak: 0.4)
        case .roundComplete:
            mix([
                Note(frequency: 523.25, start: 0, duration: 0.14),
                Note(frequency: 659.25, start: 0.12, duration: 0.14),
                Note(frequency: 783.99, start: 0.24, duration: 0.14),
                Note(frequency: 523.25, start: 0.4, duration: 0.7),
                Note(frequency: 659.25, start: 0.4, duration: 0.7),
                Note(frequency: 783.99, start: 0.4, duration: 0.7),
                Note(frequency: 1046.5, start: 0.4, duration: 0.7),
            ], peak: 0.6)
        }
    }

    private static func mix(_ notes: [Note], peak: Float) -> [Float] {
        let end = notes.map { $0.start + $0.duration }.max()!
        var out = [Float](repeating: 0, count: Int((end + 2 * pad) * sampleRate))
        for note in notes {
            let offset = Int((note.start + pad) * sampleRate)
            let count = Int(note.duration * sampleRate)
            for i in 0..<count {
                let t = Double(i) / sampleRate
                var v = 0.0
                for (n, amp) in note.harmonics.enumerated() {
                    v += amp * sin(2 * .pi * note.frequency * Double(n + 1) * t)
                }
                out[offset + i] += Float(v * envelope(t, duration: note.duration))
            }
        }
        let maxAbs = out.map(abs).max() ?? 1
        return out.map { $0 / maxAbs * peak }
    }

    /// Smooth attack, gentle exponential decay, smooth release to zero.
    private static func envelope(_ t: Double, duration: Double) -> Double {
        let attack = 0.01, release = 0.03
        let rise = t < attack ? pow(sin(.pi / 2 * t / attack), 2) : 1
        let fall = t > duration - release ? pow(sin(.pi / 2 * (duration - t) / release), 2) : 1
        return rise * fall * exp(-3 * t / max(duration, 0.1))
    }
}
