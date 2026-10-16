import Foundation
import Testing
@testable import DayByDay

struct SoundSynthTests {
    func seconds(_ samples: [Float]) -> Double { Double(samples.count) / SoundSynth.sampleRate }
    func rms(_ s: [Float]) -> Float { (s.reduce(0) { $0 + $1 * $1 } / Float(s.count)).squareRoot() }

    @Test(arguments: SoundEffect.allCases) func noClipping(_ e: SoundEffect) {
        #expect(SoundSynth.render(e).map(abs).max()! <= 0.9)
    }

    @Test(arguments: SoundEffect.allCases) func noClicks(_ e: SoundEffect) {
        let s = SoundSynth.render(e)
        #expect(s.prefix(64).allSatisfy { abs($0) < 0.01 })
        #expect(s.suffix(64).allSatisfy { abs($0) < 0.01 })
    }

    @Test(arguments: SoundEffect.allCases) func notSilent(_ e: SoundEffect) {
        #expect(rms(SoundSynth.render(e)) > 0.02)
    }

    @Test func durations() {
        #expect((0.3...0.6).contains(seconds(SoundSynth.render(.success))))
        #expect((0.25...0.5).contains(seconds(SoundSynth.render(.gentleMiss))))
        #expect((0.9...1.6).contains(seconds(SoundSynth.render(.roundComplete))))
    }

    @Test func missIsQuieterThanSuccess() {
        #expect(rms(SoundSynth.render(.gentleMiss)) < rms(SoundSynth.render(.success)))
    }

    func zeroCrossingRate(_ s: [Float]) -> Double {
        let crossings = zip(s, s.dropFirst()).filter { ($0 < 0) != ($1 < 0) }.count
        return Double(crossings) / Double(s.count)
    }

    /// Number of 10 ms windows whose level rises above 0.1 after falling below 0.02.
    func onsets(_ s: [Float]) -> Int {
        let window = Int(SoundSynth.sampleRate / 100)
        var count = 0, quiet = true
        for start in stride(from: 0, to: s.count - window, by: window) {
            let level = rms(Array(s[start..<start + window]))
            if quiet, level > 0.1 { count += 1; quiet = false }
            if level < 0.02 { quiet = true }
        }
        return count
    }

    @Test(arguments: SoundEffect.allCases) func noDCOffset(_ e: SoundEffect) {
        let s = SoundSynth.render(e)
        #expect(abs(s.reduce(0, +) / Float(s.count)) < 0.01)
    }

    @Test func cueDurations() {
        for e in [SoundEffect.moo, .quack, .baa, .oink, .meow, .woof, .tweet] {
            #expect((0.35...1.6).contains(seconds(SoundSynth.render(e))), "\(e)")
        }
        for e in [SoundEffect.rain, .wind, .thunder] {
            #expect((1.5...2.6).contains(seconds(SoundSynth.render(e))), "\(e)")
        }
        for n in 1...5 {
            #expect(abs(seconds(SoundSynth.render(.beeps(n))) - (0.42 * Double(n - 1) + 0.12)) < 0.02)
        }
        #expect((0.6...1.2).contains(seconds(SoundSynth.render(.whistle))))
        #expect(SoundSynth.duration(.moo) == seconds(SoundSynth.render(.moo)))
    }

    @Test(arguments: 1...5) func beepCountMatches(_ n: Int) {
        #expect(onsets(SoundSynth.render(.beeps(n))) == n)
    }

    @Test func allCasesListsFiveBeeps() {
        #expect(SoundEffect.allCases.filter { if case .beeps = $0 { true } else { false } }.count == 5)
    }

    @Test func brightAndDarkCues() {
        #expect(zeroCrossingRate(SoundSynth.render(.tweet)) > 5 * zeroCrossingRate(SoundSynth.render(.moo)))
        #expect(zeroCrossingRate(SoundSynth.render(.thunder)) < zeroCrossingRate(SoundSynth.render(.rain)) / 5)
    }

    @Test func arpeggioNotDrownedByChord() {
        let s = SoundSynth.render(.roundComplete)
        let split = Int(0.38 * SoundSynth.sampleRate)
        let first = s[..<split].map(abs).max()!, rest = s[split...].map(abs).max()!
        #expect(first >= 0.5 * rest)
    }

    @Test func thunderIsGentle() {
        let s = SoundSynth.render(.thunder)
        #expect(s.prefix(Int(0.05 * SoundSynth.sampleRate)).allSatisfy { abs($0) <= 0.2 })
        #expect(s.map(abs).max()! <= 0.6)
    }

    /// Level above ~300 Hz, roughly what a phone speaker reproduces.
    func speakerLevel(_ s: [Float]) -> Float {
        var low: Float = 0
        return rms(s.map { x in low += 0.042 * (x - low); return x - low })
    }

    @Test func thunderAudibleOnSpeakers() {
        #expect(speakerLevel(SoundSynth.render(.thunder)) >= 0.5 * speakerLevel(SoundSynth.render(.wind)))
    }
}
