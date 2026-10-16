import Foundation
import SwiftUI
import Testing
@testable import DayByDay

/// Writes every sound as WAV and every choice tile as PNG for art and sound
/// review. Runs only when EXPORT_DIR is set, e.g.
/// `TEST_RUNNER_EXPORT_DIR=/tmp/review xcodebuild test ... -only-testing:DayByDayTests/ReviewExport`.
@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.environment["EXPORT_DIR"] != nil))
struct ReviewExport {
    let dir = URL(fileURLWithPath: ProcessInfo.processInfo.environment["EXPORT_DIR"] ?? NSTemporaryDirectory())

    @Test func sounds() throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for effect in SoundEffect.allCases {
            try wav(SoundSynth.render(effect)).write(to: dir.appendingPathComponent("\(effect).wav"))
        }
    }

    @Test func tiles() throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for category in DayByDay.Category.gridCases {
            for scheme in [ColorScheme.light, .dark] {
                let rows = stride(from: 0, to: category.quizItems.count, by: 4).map {
                    Array(category.quizItems[$0..<min($0 + 4, category.quizItems.count)])
                }
                let sheet = VStack(alignment: .leading, spacing: 20) {
                    ForEach(rows, id: \.self) { row in
                        HStack(spacing: 20) {
                            ForEach(row) { ChoiceTile(item: $0).frame(width: 170, height: 160) }
                        }
                    }
                }
                .padding(32)
                .background(Color(.systemBackground))
                .environment(\.colorScheme, scheme)
                try png(sheet).write(to: dir.appendingPathComponent("tiles-\(category.key)-\(scheme).png"))
            }
        }
        let drawn = HStack(spacing: 24) {
            ForEach([LearnAnimal.cow, .duck, .sheep, .pig, .cat]) { animal in
                AnimalIcon(animal: animal)
                    .font(.system(size: 200))
                    .frame(width: 260, height: 260)
                    .foregroundStyle(.white)
                    .padding(20)
                    .background(RoundedRectangle(cornerRadius: 32).fill(DayByDay.Category.animals.color))
            }
        }
        .padding(32)
        try png(drawn).write(to: dir.appendingPathComponent("animals-large.png"))
    }

    private func png(_ view: some View) throws -> Data {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        return try #require(renderer.uiImage?.pngData())
    }

    /// 16-bit mono PCM.
    private func wav(_ samples: [Float]) -> Data {
        let rate = UInt32(SoundSynth.sampleRate)
        var data = Data()
        func append<T: FixedWidthInteger>(_ v: T) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
        let bytes = UInt32(samples.count * 2)
        data.append(contentsOf: Array("RIFF".utf8)); append(36 + bytes)
        data.append(contentsOf: Array("WAVEfmt ".utf8)); append(UInt32(16)); append(UInt16(1)); append(UInt16(1))
        append(rate); append(rate * 2); append(UInt16(2)); append(UInt16(16))
        data.append(contentsOf: Array("data".utf8)); append(bytes)
        for s in samples { append(Int16(max(-1, min(1, s)) * Float(Int16.max))) }
        return data
    }
}
