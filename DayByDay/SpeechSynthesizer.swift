//
//  SpeechSynthesizer.swift
//  DayByDay
//

import AVFoundation
import UIKit

/// Speaks a line from pre-rendered voice clips, one per sentence, played back
/// to back. A line with any sentence missing from the clips is spoken whole by
/// AVSpeechSynthesizer with the best installed en-US voice, so a line never
/// mixes two voices.
final class SpeechSynthesizer: NSObject, AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
    static let shared = SpeechSynthesizer()

    private let synthesizer = AVSpeechSynthesizer()
    private let voice: AVSpeechSynthesisVoice?
    private let haptics = UIImpactFeedbackGenerator(style: .rigid)
    /// Run when the matching utterance finishes; dropped if it is cut off.
    private var completions: [ObjectIdentifier: () -> Void] = [:]

    /// Clips to play from; nil means always use the synthesizer.
    var library: ClipLibrary? = ClipLibrary.bundled
    /// Gap between the sentences of a clip line. Each clip already starts with
    /// ~90 ms of encoder lead-in and ends with ~40 ms of quiet, so the pause
    /// a child hears is about 0.2 s.
    static let sentenceGap = 0.05
    /// Extra time past a clip's known length before a stalled clip is skipped.
    static let clipGrace = 1.5
    private var player: AVAudioPlayer?
    /// Counts players, so a watchdog only acts on the clip it was set for.
    private var playerID = 0
    private var queue: [ClipLibrary.Clip] = []
    private var clipCompletion: (() -> Void)?
    /// Bumped by every speak and stop, so a stale gap or finish does nothing.
    private var clipToken = 0

    var isPlayingClips: Bool { player != nil }

    private override init() {
        self.voice = Self.bestAvailableVoice()
        super.init()
        synthesizer.delegate = self
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil,
                                               queue: .main) { [weak self] note in
            let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            MainActor.assumeIsolated { self?.handleInterruption(raw.flatMap(AVAudioSession.InterruptionType.init)) }
        }
    }

    /// A call, Siri or an alarm pauses the clip; it resumes when that ends.
    /// The watchdog in `playNextClip` ends the line if it never does.
    private func handleInterruption(_ type: AVAudioSession.InterruptionType?) {
        switch type {
        case .began: player?.pause()
        case .ended: player?.play()
        default: break
        }
    }

    /// Speaks a pre-configured utterance directly. Used for warmup at launch.
    func speakUtterance(_ utterance: AVSpeechUtterance) {
        synthesizer.speak(utterance)
    }

    func speak(_ text: String, completion: (() -> Void)? = nil) {
        // Every speak() call is a card tap, so give a gentle tactile bump
        // alongside the audio. Prepared just before firing for lowest latency.
        haptics.prepare()
        haptics.impactOccurred()

        // Ensure speech plays through the speaker even when the silent switch is on.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        stop()

        if let clips = library?.clips(for: text) {
            queue = clips
            clipCompletion = completion
            playNextClip(token: clipToken)
            return
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = 0.4
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0
        if let completion { completions[ObjectIdentifier(utterance)] = completion }
        synthesizer.speak(utterance)
    }

    /// Stops clips and speech; neither calls its completion.
    func stop() {
        clipToken += 1
        player?.delegate = nil
        player?.stop()
        player = nil
        queue = []
        clipCompletion = nil
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    private func playNextClip(token: Int) {
        guard token == clipToken else { return }
        guard !queue.isEmpty else {
            player = nil
            let completion = clipCompletion
            clipCompletion = nil
            completion?()
            return
        }
        let clip = queue.removeFirst()
        guard let next = try? AVAudioPlayer(contentsOf: clip.url) else {
            // An unreadable clip ends the line rather than stalling it.
            queue = []
            playNextClip(token: token)
            return
        }
        next.delegate = self
        player = next
        playerID += 1
        let id = playerID
        if !next.play() {
            advance(from: id, token: token)
            return
        }
        // If the clip never reports finishing (interrupted, backgrounded,
        // a decode error), move on once its length plus a grace period passes.
        DispatchQueue.main.asyncAfter(deadline: .now() + clip.seconds + Self.clipGrace) { [self] in
            advance(from: id, token: token)
        }
    }

    /// Ends clip `id` and goes to the next sentence, if that clip is still current.
    private func advance(from id: Int, token: Int) {
        guard token == clipToken, id == playerID, let current = player else { return }
        current.delegate = nil
        current.stop()
        if queue.isEmpty {
            playNextClip(token: token)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.sentenceGap) { [self] in
                playNextClip(token: token)
            }
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ finished: AVAudioPlayer, successfully flag: Bool) {
        playerEnded(finished)
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ failed: AVAudioPlayer, error: Error?) {
        playerEnded(failed)
    }

    /// Holding the player keeps its identity unique until the check runs.
    private nonisolated func playerEnded(_ ended: AVAudioPlayer) {
        nonisolated(unsafe) let ended = ended
        Task { @MainActor in
            guard let player, player === ended else { return }
            advance(from: playerID, token: clipToken)
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in completions.removeValue(forKey: id)?() }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in _ = completions.removeValue(forKey: id) }
    }

    /// Picks the best en-US voice on the device.
    /// Filters for en-US, excludes novelty voices, then sorts by quality
    /// descending so premium (3) > enhanced (2) > default (1).
    private static func bestAvailableVoice() -> AVSpeechSynthesisVoice? {
        let best = AVSpeechSynthesisVoice.speechVoices()
            .filter { voice in
                voice.language.hasPrefix("en-US")
                && !voice.voiceTraits.contains(.isNoveltyVoice)
            }
            .sorted { $0.quality.rawValue > $1.quality.rawValue }
            .first

        let selected = best ?? AVSpeechSynthesisVoice(language: "en-US")
        print("[DayByDay] Selected voice: \(selected?.name ?? "nil"), quality: \(selected?.quality.rawValue ?? -1)")
        return selected
    }
}
