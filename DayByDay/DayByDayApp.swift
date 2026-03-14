//
//  DayByDayApp.swift
//  DayByDay
//
//  Created by cmc on 2026-03-09.
//

import AVFoundation
import SwiftUI

@main
struct DayByDayApp: App {
    init() {
        Task.detached(priority: .background) {
            // Activate the audio session early so the first real tap doesn't block.
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try? AVAudioSession.sharedInstance().setActive(true)

            // Force singleton init (voice selection) and prime the TTS engine
            // with a silent utterance so subsequent speaks are instant.
            await MainActor.run {
                let warmup = AVSpeechUtterance(string: "")
                warmup.volume = 0
                SpeechSynthesizer.shared.speakUtterance(warmup)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
