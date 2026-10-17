//
//  CardVoice.swift
//  DayByDay
//

import Foundation

/// Tokens for spoken lines; only the latest one may still be said.
nonisolated struct LineQueue {
    private var latest = 0

    mutating func next() -> Int {
        latest += 1
        return latest
    }

    func isCurrent(_ token: Int) -> Bool { token == latest }

    mutating func cancel() { latest += 1 }
}

/// Speaks a card's line, after its sound if it has one. A newer card, or
/// leaving the screen, cancels a line that has not started yet.
final class CardVoice {
    static let shared = CardVoice()

    private var queue = LineQueue()
    /// The last card sound, which may still be playing under a new card's line.
    private var lastSound: SoundEffect?

    /// Wait for whichever sound is still playing, then a short gap.
    nonisolated static func delay(newSound: Double, earlierSound: Double) -> Double {
        let longest = max(newSound, earlierSound)
        return longest > 0 ? longest + 0.2 : 0
    }

    func say(_ line: String, after sound: SoundEffect?) {
        let token = queue.next()
        SpeechSynthesizer.shared.stop()
        if let sound { SoundEngine.shared.play(sound) }
        let delay = Self.delay(newSound: sound.map(SoundEngine.shared.remaining) ?? 0,
                               earlierSound: lastSound.map(SoundEngine.shared.remaining) ?? 0)
        if sound != nil { lastSound = sound }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [self] in
            if queue.isCurrent(token) { SpeechSynthesizer.shared.speak(line) }
        }
    }

    func cancel() {
        queue.cancel()
        SpeechSynthesizer.shared.stop()
    }
}
