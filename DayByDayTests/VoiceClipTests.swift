import AVFoundation
import Foundation
import Testing
@testable import DayByDay

/// The bundled clips match the spoken-line catalog exactly.
struct VoiceClipTests {
    struct Entry: Decodable {
        let text: String
        let file: String
        let seconds: Double
    }

    static let manifestURL = Bundle(for: SpeechSynthesizer.self).url(forResource: "voice-manifest", withExtension: "json")
    static let entries: [Entry] = manifestURL
        .flatMap { try? Data(contentsOf: $0) }
        .flatMap { try? JSONDecoder().decode([Entry].self, from: $0) } ?? []

    @Test func manifestIsBundled() {
        #expect(Self.manifestURL != nil)
        #expect(ClipLibrary.bundled != nil)
    }

    @Test func catalogMatchesManifest() {
        let texts = Set(Self.entries.map(\.text))
        let missing = SpokenLines.all.subtracting(texts)
        let stale = texts.subtracting(SpokenLines.all)
        #expect(missing.isEmpty, "no clip for: \(missing.sorted().prefix(10))")
        #expect(stale.isEmpty, "not in catalog: \(stale.sorted().prefix(10))")
        #expect(Self.entries.count == texts.count)
    }

    @Test func bundleHasEveryClip() throws {
        let dir = try #require(Self.manifestURL).deletingLastPathComponent()
        let missing = Self.entries.filter { !FileManager.default.fileExists(atPath: dir.appendingPathComponent($0.file).path) }
        #expect(missing.isEmpty, "\(missing.prefix(5).map(\.file))")
    }

    @Test func manifestDurations() throws {
        let dir = try #require(Self.manifestURL).deletingLastPathComponent()
        var off: [String] = []
        for e in Self.entries {
            let file = try AVAudioFile(forReading: dir.appendingPathComponent(e.file))
            let seconds = Double(file.length) / file.fileFormat.sampleRate
            if abs(seconds - e.seconds) > 0.05 { off.append("\(e.text) \(e.seconds) vs \(seconds)") }
        }
        #expect(off.isEmpty, "\(off.prefix(5))")
    }

    @Test func onlyListedNamesHaveGreetings() {
        #expect(Set(Self.entries.map(\.text).filter { $0.hasPrefix("Hi, ") })
                == Set(Lines.spokenNames.map { "Hi, \($0)!" }))
    }
}
