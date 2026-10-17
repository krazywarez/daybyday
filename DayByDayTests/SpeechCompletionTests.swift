import AVFoundation
import Foundation
import Testing
@testable import DayByDay

/// One serialized suite, since every test drives the shared speech engine.
@MainActor
@Suite(.serialized, .timeLimit(.minutes(1)))
struct SpeechCompletionTests {
    let speech = SpeechSynthesizer.shared

    /// A library with "Alpha." and "Beta." as 0.3 s tones; "Gamma." has no clip.
    static let library: ClipLibrary = {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("clips-\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        var entries: [[String: Any]] = []
        for (i, text) in ["Alpha.", "Beta."].enumerated() {
            let file = "tone\(i).wav"
            let format = AVAudioFormat(standardFormatWithSampleRate: 24_000, channels: 1)!
            let out = try! AVAudioFile(forWriting: dir.appendingPathComponent(file), settings: format.settings)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 7_200)!
            buffer.frameLength = 7_200
            for n in 0..<7_200 { buffer.floatChannelData![0][n] = 0.2 * sin(Float(n) * 0.1) }
            try! out.write(from: buffer)
            entries.append(["text": text, "file": file, "seconds": 0.3])
        }
        let manifest = dir.appendingPathComponent("voice-manifest.json")
        try! JSONSerialization.data(withJSONObject: entries).write(to: manifest)
        return ClipLibrary(manifest: manifest, directory: dir)!
    }()

    func say(_ text: String) async {
        await withCheckedContinuation { cont in speech.speak(text) { cont.resume() } }
    }

    @Test func completionFiresWhenSpeechEnds() async {
        speech.library = nil
        await say("One.")
    }

    @Test func interruptedSpeechDoesNotComplete() async throws {
        speech.library = nil
        var first = false
        speech.speak("Sunday, Monday, Tuesday, Wednesday.") { first = true }
        try await Task.sleep(for: .milliseconds(300))
        await say("Two.")
        #expect(!first)
    }

    @Test func clipLineCompletes() async {
        speech.library = Self.library
        speech.speak("Alpha. Beta.")
        #expect(speech.isPlayingClips)
        await say("Alpha. Beta.")
        #expect(!speech.isPlayingClips)
    }

    @Test func missingSentenceFallsBackForWholeLine() async {
        speech.library = Self.library
        speech.speak("Alpha. Gamma.")
        #expect(!speech.isPlayingClips)
        await say("Alpha. Gamma.")
    }

    @Test func clipCutOffByTTSCompletesOnlySecond() async throws {
        speech.library = Self.library
        var first = false
        speech.speak("Alpha. Beta.") { first = true }
        try await Task.sleep(for: .milliseconds(100))
        await say("Gamma.")
        try await Task.sleep(for: .milliseconds(800))
        #expect(!first)
    }

    @Test func ttsCutOffByClipCompletesOnlySecond() async throws {
        speech.library = Self.library
        var first = false
        speech.speak("Gamma. Sunday, Monday, Tuesday, Wednesday.") { first = true }
        try await Task.sleep(for: .milliseconds(300))
        await say("Alpha.")
        try await Task.sleep(for: .milliseconds(300))
        #expect(!first)
    }

    func interrupt(_ type: AVAudioSession.InterruptionType) {
        NotificationCenter.default.post(name: AVAudioSession.interruptionNotification, object: nil,
                                        userInfo: [AVAudioSessionInterruptionTypeKey: type.rawValue])
    }

    /// An interruption pauses the clip; when it ends, the clip resumes and the line finishes.
    @Test func interruptionPausesAndResumes() async throws {
        speech.library = Self.library
        var fired = false
        speech.speak("Alpha.") { fired = true }
        try await Task.sleep(for: .milliseconds(50))
        interrupt(.began)
        try await Task.sleep(for: .milliseconds(700))
        #expect(!fired)
        interrupt(.ended)
        try await Task.sleep(for: .milliseconds(600))
        #expect(fired)
    }

    /// An interruption that never ends must not freeze a game waiting on the line:
    /// it ends once its known length plus a grace period has passed.
    @Test func stalledClipLineStillCompletes() async throws {
        speech.library = Self.library
        var fired = false
        speech.speak("Alpha.") { fired = true }
        try await Task.sleep(for: .milliseconds(50))
        interrupt(.began)
        try await Task.sleep(for: .milliseconds(700))
        #expect(!fired)
        try await Task.sleep(for: .milliseconds(SpeechSynthesizer.clipGrace * 1_000 + 500))
        #expect(fired)
        #expect(!speech.isPlayingClips)
        speech.library = ClipLibrary.bundled
    }

    /// A line the bundled clips lack would play in the system voice.
    @Test func uncatalogedLineIsFlagged() {
        speech.library = ClipLibrary.bundled
        #expect(speech.missingClipWarning(for: "Super!") == nil)
        #expect(speech.missingClipWarning(for: "Super! Not in the catalog.")?.contains("Not in the catalog.") == true)
        #expect(speech.missingClipWarning(for: "") == nil)
        speech.library = Self.library
        #expect(speech.missingClipWarning(for: "Gamma.") == nil)
        speech.library = ClipLibrary.bundled
    }

    @Test func stopDropsClipCompletion() async throws {
        speech.library = Self.library
        var fired = false
        speech.speak("Alpha. Beta.") { fired = true }
        try await Task.sleep(for: .milliseconds(100))
        speech.stop()
        try await Task.sleep(for: .milliseconds(1_000))
        #expect(!fired)
        #expect(!speech.isPlayingClips)
        speech.library = ClipLibrary.bundled
    }
}
