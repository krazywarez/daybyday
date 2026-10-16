//
//  SoundSynth.swift
//  DayByDay
//

import Foundation

nonisolated enum SoundEffect: Hashable, CaseIterable, Sendable {
    case success, gentleMiss, roundComplete
    case moo, quack, baa, oink, meow, woof, tweet
    case rain, wind, thunder
    /// That many short beeps, for counting.
    case beeps(Int)

    static let allCases: [SoundEffect] =
        [.success, .gentleMiss, .roundComplete, .moo, .quack, .baa, .oink, .meow, .woof, .tweet,
         .rain, .wind, .thunder] + (1...5).map(SoundEffect.beeps)
}

/// Renders sound effects to mono sample buffers. Every sound fades in and out
/// smoothly and starts and ends on silence, so there are no clicks.
nonisolated enum SoundSynth {
    static let sampleRate: Double = 44_100

    /// Silence at each end so playback never starts or stops mid-wave.
    private static let pad = 0.004

    static func duration(_ effect: SoundEffect) -> Double {
        Double(render(effect).count) / sampleRate
    }

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
            ], peak: 0.45)
        case .roundComplete:
            mix([
                Note(frequency: 523.25, start: 0, duration: 0.14, gain: 2.2),
                Note(frequency: 659.25, start: 0.12, duration: 0.14, gain: 2.2),
                Note(frequency: 783.99, start: 0.24, duration: 0.14, gain: 2.2),
                Note(frequency: 523.25, start: 0.4, duration: 0.7),
                Note(frequency: 659.25, start: 0.4, duration: 0.7),
                Note(frequency: 783.99, start: 0.4, duration: 0.7),
                Note(frequency: 1046.5, start: 0.4, duration: 0.7),
            ], peak: 0.6)
        case .beeps(let count):
            mix((0..<count).map {
                Note(frequency: 660, start: 0.42 * Double($0), duration: 0.12, harmonics: [1, 0.2])
            }, peak: 0.5)
        case .moo:
            voice(Voice(duration: 1.2,
                        pitch: [(0, 105), (0.25, 135), (0.7, 125), (1, 95)],
                        vowels: [(0, [260, 600, 2200]), (0.3, [480, 850, 2300]),
                                 (0.75, [380, 700, 2200]), (1, [260, 550, 2200])],
                        bandwidth: 110, rolloff: 1.3, vibrato: (5, 0.01),
                        attack: 0.12, release: 0.25),
                  peak: 0.75)
        case .meow:
            voice(Voice(duration: 0.7,
                        pitch: [(0, 480), (0.4, 720), (1, 430)],
                        vowels: [(0, [300, 2300, 3000]), (0.35, [850, 1600, 2800]), (1, [400, 900, 2600])],
                        bandwidth: 300, rolloff: 0.6, attack: 0.04, release: 0.15),
                  peak: 0.35)
        case .baa:
            voice(Voice(duration: 0.8,
                        pitch: [(0, 360), (0.15, 330), (1, 300)],
                        vowels: [(0, [350, 1200, 2500]), (0.12, [750, 1650, 2600]), (1, [700, 1500, 2500])],
                        bandwidth: 250, rolloff: 0.5, vibrato: (7, 0.04), tremolo: (7, 0.5),
                        attack: 0.03, release: 0.2),
                  peak: 0.55)
        case .quack:
            repeated(at: [0, 0.28], Voice(duration: 0.18,
                        pitch: [(0, 240), (1, 190)],
                        vowels: [(0, [1000, 2500, 3200]), (1, [850, 2000, 3000])],
                        bandwidth: 200, rolloff: 0.2, attack: 0.012, release: 0.05, noise: 0.1),
                     peak: 0.5)
        case .oink:
            repeated(at: [0, 0.3], Voice(duration: 0.2,
                        pitch: [(0, 150), (1, 110)],
                        vowels: [(0, [400, 1100, 2400]), (1, [350, 900, 2300])],
                        bandwidth: 150, rolloff: 0.4, tremolo: (30, 0.6),
                        attack: 0.015, release: 0.06, noise: 0.3),
                     peak: 0.75)
        case .woof:
            repeated(at: [0, 0.32], Voice(duration: 0.18,
                        pitch: [(0, 320), (0.3, 260), (1, 170)],
                        vowels: [(0, [350, 800, 2300]), (0.25, [650, 1100, 2500]), (1, [500, 900, 2400])],
                        bandwidth: 220, rolloff: 0.4, attack: 0.01, release: 0.07, noise: 0.25),
                     peak: 0.55)
        case .tweet:
            tweet()
        case .rain:
            rain()
        case .wind:
            wind()
        case .thunder:
            thunder()
        }
    }

    // MARK: - Notes

    private struct Note {
        let frequency: Double
        let start: Double
        let duration: Double
        var harmonics: [Double] = [1, 0.3, 0.1]
        var gain: Double = 1
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
                out[offset + i] += Float(note.gain * v * envelope(t, duration: note.duration))
            }
        }
        return normalized(out, peak: peak)
    }

    /// Smooth attack, gentle exponential decay, smooth release to zero.
    private static func envelope(_ t: Double, duration: Double) -> Double {
        let attack = 0.01, release = 0.03
        return fade(t, duration: duration, attack: attack, release: release) * exp(-3 * t / max(duration, 0.1))
    }

    // MARK: - Voices

    /// A pitched source whose harmonics are shaped by moving formant peaks,
    /// the way a mouth shapes a vowel.
    private struct Voice {
        var duration: Double
        /// (fraction of duration, Hz) breakpoints.
        var pitch: [(Double, Double)]
        /// (fraction of duration, formant Hz) breakpoints. Empty means no shaping.
        var vowels: [(Double, [Double])] = []
        var bandwidth: Double = 150
        /// Harmonic n is weighted by 1 / n^rolloff.
        var rolloff: Double = 0.5
        var maxHarmonics = 60
        /// (rate Hz, depth as a fraction of pitch).
        var vibrato: (Double, Double) = (0, 0)
        /// (rate Hz, depth as a fraction of level).
        var tremolo: (Double, Double) = (0, 0)
        var attack = 0.03
        var release = 0.08
        var noise = 0.0
    }

    private static func voice(_ v: Voice, peak: Float) -> [Float] {
        normalized(padded(voiceSamples(v, seed: 1)), peak: peak)
    }

    private static func repeated(at starts: [Double], _ v: Voice, peak: Float) -> [Float] {
        let one = voiceSamples(v, seed: 1)
        let end = starts.max()! + v.duration
        var out = [Float](repeating: 0, count: Int(end * sampleRate) + 1)
        for start in starts {
            let offset = Int(start * sampleRate)
            for (i, s) in one.enumerated() where offset + i < out.count { out[offset + i] += s }
        }
        return normalized(padded(out), peak: peak)
    }

    private static func voiceSamples(_ v: Voice, seed: UInt64) -> [Float] {
        let count = Int(v.duration * sampleRate)
        var out = [Float](repeating: 0, count: count)
        var noise = Noise(seed: seed)
        var phase = 0.0
        var gains = [Double]()
        var smoothNoise = 0.0
        let nyquistGuard = 7_000.0
        for i in 0..<count {
            let t = Double(i) / sampleRate
            let u = t / v.duration
            let f0 = interpolate(v.pitch, u) * (1 + v.vibrato.1 * sin(2 * .pi * v.vibrato.0 * t))
            phase += 2 * .pi * f0 / sampleRate
            let harmonics = min(v.maxHarmonics, Int(nyquistGuard / f0))
            if i % 32 == 0 {
                let formants = v.vowels.isEmpty ? [] : interpolate(v.vowels, u)
                gains = (1...max(harmonics, 1)).map { n in
                    let f = Double(n) * f0
                    var g = formants.isEmpty ? 1 : 0.02
                    for (k, formant) in formants.enumerated() {
                        let d = (f - formant) / v.bandwidth
                        g += pow(0.55, Double(k)) * exp(-d * d)
                    }
                    return g / pow(Double(n), v.rolloff)
                }
            }
            var s = 0.0
            for n in 0..<min(harmonics, gains.count) {
                s += gains[n] * sin(Double(n + 1) * phase)
            }
            smoothNoise += 0.3 * (noise.next() - smoothNoise)
            s += v.noise * 4 * smoothNoise
            let level = 1 - v.tremolo.1 * (0.5 + 0.5 * sin(2 * .pi * v.tremolo.0 * t))
            out[i] = Float(s * level * fade(t, duration: v.duration, attack: v.attack, release: v.release))
        }
        return out
    }

    /// Three rising chirps, then a short warble.
    private static func tweet() -> [Float] {
        let chirp = Voice(duration: 0.09, pitch: [(0, 2500), (1, 4200)], rolloff: 2,
                          maxHarmonics: 2, attack: 0.01, release: 0.03)
        let warble = Voice(duration: 0.25, pitch: [(0, 3800), (0.5, 3200), (1, 3600)], rolloff: 2,
                           maxHarmonics: 2, vibrato: (25, 0.05), attack: 0.02, release: 0.06)
        var out = [Float](repeating: 0, count: Int(0.68 * sampleRate))
        for (start, v) in [(0.0, chirp), (0.13, chirp), (0.26, chirp), (0.42, warble)] {
            let offset = Int(start * sampleRate)
            for (i, s) in voiceSamples(v, seed: 1).enumerated() where offset + i < out.count {
                out[offset + i] += s
            }
        }
        return normalized(padded(out), peak: 0.3)
    }

    // MARK: - Weather

    /// Soft high hiss with scattered droplets.
    private static func rain() -> [Float] {
        let duration = 2.0
        let count = Int(duration * sampleRate)
        var noise = Noise(seed: 7)
        var out = [Float](repeating: 0, count: count)
        var low = 0.0, body = 0.0
        for i in 0..<count {
            low += 0.3 * (noise.next() - low)   // soften the top end
            body += 0.2 * (low - body)          // what is left below ~1.4 kHz
            out[i] = Float(0.5 * (low - body))
        }
        for _ in 0..<70 {
            let start = Int(noise.unit() * (duration - 0.05) * sampleRate)
            let frequency = 1500 + noise.unit() * 3000
            let amplitude = 0.15 + noise.unit() * 0.3
            let length = Int(0.018 * sampleRate)
            for j in 0..<length where start + j < count {
                let t = Double(j) / sampleRate
                let shape = fade(t, duration: 0.018, attack: 0.002, release: 0.006) * exp(-t / 0.005)
                out[start + j] += Float(amplitude * shape * sin(2 * .pi * frequency * t))
            }
        }
        return finish(out, duration: duration, attack: 0.3, release: 0.4, peak: 0.45)
    }

    /// Band-passed noise whose center drifts, with a slow swell.
    private static func wind() -> [Float] {
        let duration = 2.2
        let count = Int(duration * sampleRate)
        var noise = Noise(seed: 11)
        var out = [Float](repeating: 0, count: count)
        var y1 = 0.0, y2 = 0.0
        for i in 0..<count {
            let t = Double(i) / sampleRate
            let u = t / duration
            let center = interpolate([(0, 250), (0.45, 700), (1, 350)], u)
            let r = 0.995
            let theta = 2 * .pi * center / sampleRate
            let y = noise.next() * (1 - r) + 2 * r * cos(theta) * y1 - r * r * y2
            y2 = y1
            y1 = y
            let swell = pow(sin(.pi * u), 1.5) * (1 + 0.3 * sin(2 * .pi * 0.8 * t))
            out[i] = Float(y * swell)
        }
        return finish(out, duration: duration, attack: 0.2, release: 0.4, peak: 0.45)
    }

    /// Low rolling rumble with a soft start and two swells. No sharp crack.
    private static func thunder() -> [Float] {
        let duration = 2.4
        let count = Int(duration * sampleRate)
        var noise = Noise(seed: 13)
        var out = [Float](repeating: 0, count: count)
        var a = 0.0, b = 0.0
        for i in 0..<count {
            let t = Double(i) / sampleRate
            a += 0.06 * (noise.next() - a)
            b += 0.06 * (a - b)
            let swells = exp(-pow((t - 0.35) / 0.3, 2)) + 0.7 * exp(-pow((t - 1.2) / 0.45, 2))
            out[i] = Float(b * swells)
        }
        return finish(dcBlocked(out), duration: duration, attack: 0.15, release: 0.5, peak: 0.55)
    }

    // MARK: - Helpers

    /// Seeded white noise in -1...1 (SplitMix64), so sounds render the same every time.
    private struct Noise {
        var state: UInt64
        init(seed: UInt64) { state = seed }
        mutating func unit() -> Double {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return Double((z ^ (z >> 31)) >> 11) / Double(1 << 53)
        }
        mutating func next() -> Double { 2 * unit() - 1 }
    }

    /// sin² fade-in over `attack` and fade-out over `release`.
    private static func fade(_ t: Double, duration: Double, attack: Double, release: Double) -> Double {
        let rise = t < attack ? pow(sin(.pi / 2 * t / attack), 2) : 1
        let fall = t > duration - release ? pow(sin(.pi / 2 * max(0, duration - t) / release), 2) : 1
        return rise * fall
    }

    private static func interpolate(_ points: [(Double, Double)], _ u: Double) -> Double {
        guard let upper = points.firstIndex(where: { $0.0 >= u }), upper > 0 else {
            return u <= points[0].0 ? points[0].1 : points[points.count - 1].1
        }
        let (u0, v0) = points[upper - 1], (u1, v1) = points[upper]
        return v0 + (v1 - v0) * (u - u0) / (u1 - u0)
    }

    private static func interpolate(_ points: [(Double, [Double])], _ u: Double) -> [Double] {
        (0..<points[0].1.count).map { k in interpolate(points.map { ($0.0, $0.1[k]) }, u) }
    }

    private static func dcBlocked(_ s: [Float]) -> [Float] {
        var out = s
        var previousIn: Float = 0, previousOut: Float = 0
        for i in s.indices {
            previousOut = s[i] - previousIn + 0.999 * previousOut
            previousIn = s[i]
            out[i] = previousOut
        }
        return out
    }

    /// Fades, removes any remaining offset, pads, and normalizes.
    private static func finish(_ s: [Float], duration: Double, attack: Double, release: Double, peak: Float) -> [Float] {
        let mean = s.reduce(0, +) / Float(s.count)
        let shaped = s.enumerated().map { i, x in
            (x - mean) * Float(fade(Double(i) / sampleRate, duration: duration, attack: attack, release: release))
        }
        return normalized(padded(shaped), peak: peak)
    }

    private static func padded(_ s: [Float]) -> [Float] {
        let silence = [Float](repeating: 0, count: Int(pad * sampleRate))
        return silence + s + silence
    }

    private static func normalized(_ s: [Float], peak: Float) -> [Float] {
        let maxAbs = s.map(abs).max() ?? 1
        guard maxAbs > 0 else { return s }
        return s.map { $0 / maxAbs * peak }
    }
}
