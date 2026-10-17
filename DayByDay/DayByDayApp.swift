//
//  DayByDayApp.swift
//  DayByDay
//
//  Created by cmc on 2026-03-09.
//

import AVFoundation
import SwiftData
import SwiftUI

@main
struct DayByDayApp: App {
    #if DEBUG
    private let screenshot = ScreenshotScene.requested
    #endif
    private let container: ModelContainer
    @State private var session: ProfileSession

    init() {
        HeadingFont.register()
        #if DEBUG
        container = ProfileStore.makeContainer(inMemory: screenshot != nil)
        #else
        container = ProfileStore.makeContainer(inMemory: false)
        #endif
        let session = ProfileSession(store: ProfileStore(context: container.mainContext))
        #if DEBUG
        if screenshot != nil { ScreenshotScene.seed(session) }
        #endif
        _session = State(initialValue: session)

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
            root
                .environment(session)
                .modelContainer(container)
        }
    }

    @ViewBuilder @MainActor
    private var root: some View {
        #if DEBUG
        if let screenshot {
            screenshot.view(session)
        } else {
            ContentView()
        }
        #else
        ContentView()
        #endif
    }
}
