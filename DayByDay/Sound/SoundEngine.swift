//
//  SoundEngine.swift
//  DayByDay
//

import AVFoundation

/// Plays pre-rendered sound effects. Buffers are rendered once at startup.
/// Each effect has its own player node so effects overlap instead of cutting
/// each other off mid-wave (which clicks). A repeat of an effect that is
/// still playing is skipped for the same reason.
final class SoundEngine {
    static let shared = SoundEngine()

    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: SoundSynth.sampleRate, channels: 1)!
    private var buffers: [SoundEffect: AVAudioPCMBuffer] = [:]
    private var players: [SoundEffect: AVAudioPlayerNode] = [:]
    private var busyUntil: [SoundEffect: Date] = [:]

    private init() {
        for effect in SoundEffect.allCases {
            let samples = SoundSynth.render(effect)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))!
            buffer.frameLength = buffer.frameCapacity
            samples.withUnsafeBufferPointer { src in
                buffer.floatChannelData![0].update(from: src.baseAddress!, count: samples.count)
            }
            buffers[effect] = buffer

            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            players[effect] = player
        }
    }

    func play(_ effect: SoundEffect) {
        guard let buffer = buffers[effect], let player = players[effect] else { return }
        let now = Date()
        if let busy = busyUntil[effect], busy > now { return }
        if !engine.isRunning {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try? AVAudioSession.sharedInstance().setActive(true)
            try? engine.start()
        }
        busyUntil[effect] = now.addingTimeInterval(Double(buffer.frameLength) / SoundSynth.sampleRate)
        player.scheduleBuffer(buffer, at: nil)
        if !player.isPlaying { player.play() }
    }
}
