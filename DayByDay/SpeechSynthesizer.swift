//
//  SpeechSynthesizer.swift
//  DayByDay
//

import AVFoundation

/// Wrapper around AVSpeechSynthesizer that selects the highest-quality
/// en-US neural voice available on the device. Falls back gracefully if
/// premium/enhanced voices haven't been downloaded yet.
final class SpeechSynthesizer {
    static let shared = SpeechSynthesizer()

    private let synthesizer = AVSpeechSynthesizer()
    private let voice: AVSpeechSynthesisVoice?

    private init() {
        self.voice = Self.bestAvailableVoice()
    }

    func speak(_ text: String) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = 0.4
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0
        synthesizer.speak(utterance)
    }

    /// Picks the best en-US voice on the device.
    /// Preference order: premium > enhanced > default quality.
    /// Skips novelty voices so the child always hears a natural-sounding voice.
    private static func bestAvailableVoice() -> AVSpeechSynthesisVoice? {
        let candidates = AVSpeechSynthesisVoice.speechVoices().filter { voice in
            voice.language.hasPrefix("en-US")
            && !voice.voiceTraits.contains(.isNoveltyVoice)
        }

        if let premium = candidates.first(where: { $0.quality == .premium }) {
            return premium
        }
        if let enhanced = candidates.first(where: { $0.quality == .enhanced }) {
            return enhanced
        }
        // Fall back to the best default-quality voice.
        return candidates.first ?? AVSpeechSynthesisVoice(language: "en-US")
    }
}
