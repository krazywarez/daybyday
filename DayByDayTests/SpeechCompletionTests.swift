import Foundation
import Testing
@testable import DayByDay

@MainActor
@Suite(.serialized, .timeLimit(.minutes(1)))
struct SpeechCompletionTests {
    @Test func completionFiresWhenSpeechEnds() async {
        let fired: Bool = await withCheckedContinuation { cont in
            SpeechSynthesizer.shared.speak("One.") { cont.resume(returning: true) }
        }
        #expect(fired)
    }

    @Test func interruptedSpeechDoesNotComplete() async throws {
        var first = false
        SpeechSynthesizer.shared.speak("Sunday, Monday, Tuesday, Wednesday.") { first = true }
        try await Task.sleep(for: .milliseconds(300))
        await withCheckedContinuation { cont in
            SpeechSynthesizer.shared.speak("Two.") { cont.resume() }
        }
        #expect(!first)
    }
}
