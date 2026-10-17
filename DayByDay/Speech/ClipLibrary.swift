//
//  ClipLibrary.swift
//  DayByDay
//

import Foundation

/// Pre-rendered voice clips, one per sentence, listed in `voice-manifest.json`.
final class ClipLibrary {
    struct Entry: Decodable {
        let text: String
        let file: String
        let seconds: Double
    }

    private let entries: [String: Entry]
    private let directory: URL

    init?(manifest: URL, directory: URL) {
        guard let data = try? Data(contentsOf: manifest),
              let list = try? JSONDecoder().decode([Entry].self, from: data) else { return nil }
        entries = Dictionary(list.map { ($0.text, $0) }, uniquingKeysWith: { a, _ in a })
        self.directory = directory
    }

    /// The clips that ship in the app bundle, if any.
    static let bundled: ClipLibrary? = Bundle.main.url(forResource: "voice-manifest", withExtension: "json")
        .flatMap { ClipLibrary(manifest: $0, directory: $0.deletingLastPathComponent()) }

    struct Clip {
        let url: URL
        /// Playback length, used to skip a clip that never reports finishing.
        let seconds: Double
    }

    func clip(for sentence: String) -> Clip? {
        entries[sentence].map { Clip(url: directory.appendingPathComponent($0.file), seconds: $0.seconds) }
    }

    /// One clip per sentence of `text`, or nil if any sentence has none.
    func clips(for text: String) -> [Clip]? {
        let sentences = SpokenText.sentences(text)
        guard !sentences.isEmpty else { return nil }
        var result: [Clip] = []
        for sentence in sentences {
            guard let clip = clip(for: sentence) else { return nil }
            result.append(clip)
        }
        return result
    }
}
