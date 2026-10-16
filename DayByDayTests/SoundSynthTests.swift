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
        #expect(seconds(SoundSynth.render(.tap)) < 0.08)
        #expect((0.3...0.6).contains(seconds(SoundSynth.render(.success))))
        #expect((0.25...0.5).contains(seconds(SoundSynth.render(.gentleMiss))))
        #expect((0.9...1.6).contains(seconds(SoundSynth.render(.roundComplete))))
    }

    @Test func missIsQuieterThanSuccess() {
        #expect(rms(SoundSynth.render(.gentleMiss)) < rms(SoundSynth.render(.success)))
    }
}
