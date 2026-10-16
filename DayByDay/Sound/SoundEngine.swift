//
//  SoundEngine.swift
//  DayByDay
//

import AVFoundation

/// Plays synthesized sound effects. Each effect is rendered and given its
/// own player node the first time it plays. Separate players let effects
/// overlap instead of cutting each other off mid-wave (which clicks). A
/// repeat of an effect that is still playing is skipped for the same reason.
final class SoundEngine {
    static let shared = SoundEngine()

    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: SoundSynth.sampleRate, channels: 1)!
    private var buffers: [SoundEffect: AVAudioPCMBuffer] = [:]
    private var players: [SoundEffect: AVAudioPlayerNode] = [:]
    private var busyUntil: [SoundEffect: Date] = [:]

    private init() {}

    func play(_ effect: SoundEffect) {
        let buffer = buffer(for: effect)
        let player = player(for: effect)
        let now = Date()
        if let busy = busyUntil[effect], busy > now { return }
        if !engine.isRunning {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try? AVAudioSession.sharedInstance().setActive(true)
            try? engine.start()
        }
        busyUntil[effect] = now.addingTimeInterval(duration(effect))
        player.scheduleBuffer(buffer, at: nil)
        if !player.isPlaying { player.play() }
    }

    /// Time until `effect` finishes playing; zero when it is not playing.
    func remaining(_ effect: SoundEffect) -> TimeInterval {
        max(0, busyUntil[effect]?.timeIntervalSinceNow ?? 0)
    }

    func duration(_ effect: SoundEffect) -> TimeInterval {
        Double(buffer(for: effect).frameLength) / SoundSynth.sampleRate
    }

    private func buffer(for effect: SoundEffect) -> AVAudioPCMBuffer {
        if let buffer = buffers[effect] { return buffer }
        let samples = SoundSynth.render(effect)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))!
        buffer.frameLength = buffer.frameCapacity
        samples.withUnsafeBufferPointer { src in
            buffer.floatChannelData![0].update(from: src.baseAddress!, count: samples.count)
        }
        buffers[effect] = buffer
        return buffer
    }

    private func player(for effect: SoundEffect) -> AVAudioPlayerNode {
        if let player = players[effect] { return player }
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        players[effect] = player
        return player
    }
}
