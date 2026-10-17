import Foundation
import SwiftUI
import UIKit
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

    /// Every mood's still pose at two sizes, then frames from its motion.
    @Test func mascotPoses() throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let frames: [(MascotMood, Double)] = [(.idle, 3.75), (.asking, 0.11), (.cheering, 0.2), (.waving, 0.175), (.waving, 0.525)]
        for scheme in [ColorScheme.light, .dark] {
            let sheet = VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 16) {
                    ForEach(MascotMood.allCases, id: \.self) { OwlCanvas(mood: $0, pose: MascotMotion.still($0)).frame(width: 180, height: 180) }
                }
                HStack(spacing: 16) {
                    ForEach(MascotMood.allCases, id: \.self) { OwlCanvas(mood: $0, pose: MascotMotion.still($0)).frame(width: 64, height: 64) }
                }
                HStack(spacing: 16) {
                    ForEach(Array(frames.enumerated()), id: \.offset) { _, f in
                        OwlCanvas(mood: f.0, pose: MascotMotion.pose(f.0, at: f.1)).frame(width: 180, height: 180)
                    }
                }
            }
            .padding(32)
            .background(Color(.systemBackground))
            .environment(\.colorScheme, scheme)
            try png(sheet).write(to: dir.appendingPathComponent("mascot-\(scheme).png"))
        }
    }

    @Test func games() async throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let container = ProfileStore.makeContainer(inMemory: true)
        let session = ProfileSession(store: ProfileStore(context: container.mainContext))
        if let maya = try? session.store.create(name: "Maya", avatar: .cat, color: .pink, birthday: (month: 10, day: 30)) {
            session.store.setPicture(.swim, on: .friday, for: maya)
            session.store.setPicture(.school, on: .monday, for: maya)
            for (d, w) in [(1, LearnWeather.sunny), (2, .cloudy), (5, .rainy), (9, .windy), (12, .snowy), (15, .sunny)] {
                session.store.addSticker(for: maya, on: DateComponents(year: 2026, month: 10, day: d), weather: w)
            }
            let days = DayByDay.Category.days.quizItems, months = DayByDay.Category.months.quizItems
            let t = Date(timeIntervalSince1970: 1_800_000_000)
            for (i, day) in days.enumerated() {
                session.store.record(day, correct: true, for: maya, at: t + Double(i) * 300)
                session.store.record(day, correct: true, for: maya, at: t + 5000 + Double(i) * 300)
            }
            for (i, month) in months.enumerated() where i < 5 {
                session.store.record(month, correct: true, for: maya, at: t + Double(i) * 300)
                session.store.record(month, correct: true, for: maya, at: t + 5000 + Double(i) * 300)
            }
            for month in months[5...7] { session.store.record(month, correct: false, for: maya, at: t + 9000) }
            session.store.record(DayByDay.Category.alphabet.quizItems[1], correct: false, for: maya, at: t)
            session.profilesChanged()
        }
        var rng = SeededGenerator(seed: 1)
        var train = SequencePuzzle.weekTrain(using: &rng)
        for d in [DayOfWeek.sunday, .monday, .tuesday] { _ = train.place(DayByDay.Category.days.item(d)) }
        var slots = SequencePuzzle.yesterdayTomorrow(today: .friday, using: &rng)
        _ = slots.place(DayByDay.Category.days.item(DayOfWeek.thursday))
        let screens: [(String, AnyView)] = [
            ("train-start", AnyView(SequencePuzzleView(game: .weekTrain) { .weekTrain(using: &rng) })),
            ("train", AnyView(SequencePuzzleView(game: .weekTrain) { train })),
            ("slots", AnyView(SequencePuzzleView(game: .yesterdayTomorrow) { slots })),
            ("wheel", AnyView(YearWheelView())),
            ("mix", AnyView(RoundView(source: MixColors(), game: .mixColors) { ChoiceTile(item: $0) })),
            ("trace-shape", AnyView(TraceView(category: .shapes))),
            ("trace-letter", AnyView(TraceView(category: .alphabet))),
            ("dress", AnyView(RoundView(source: DressUp(), game: .dressUp) { ClothingTile(item: $0) })),
            ("sort", AnyView(SortView())),
            ("moves", AnyView(MovesView())),
            ("weather", AnyView(WeatherView())),
            ("rain", AnyView(RainOverlay(isActive: true).background(Color(.systemBackground)))),
            ("days", AnyView(DaysOfWeekView())),
            ("routine", AnyView(TodayRoutineView())),
            ("calendar", AnyView(StickerCalendarView(profile: session.current, now: DateComponents(calendar: .current, year: 2026, month: 10, day: 16).date!))),
            ("banner", AnyView(TodayBanner().padding())),
            ("picker", AnyView(ProfilePickerView())),
            ("parent-progress", AnyView(NavigationStack { ChildProgressView(profile: session.profiles[0]) })),
            ("welcome", AnyView(ProfileSetupView())),
            ("finished", AnyView(FinishedView {})),
            ("find-days", AnyView(RoundView(source: DayByDay.Category.days.questionSource(for: .findIt), game: .findIt) { ChoiceTile(item: $0) })),
            ("animals", AnyView(AnimalsView())),
            ("alphabet", AnyView(AlphabetView())),
            ("counting", AnyView(CountingView())),
            ("piles", AnyView(HStack(spacing: 20) {
                ForEach([3, 7, 10], id: \.self) { n in
                    PileTile(item: DayByDay.Category.numbers.item(LearnNumber(rawValue: n)!)).frame(width: 170, height: 160)
                }
            })),
        ]
        for (name, view) in screens {
            for scheme in [ColorScheme.light, .dark] {
                let page = view
                    .background(Color(.systemBackground))
                    .environment(session)
                    .environment(\.colorScheme, scheme)
                try await windowPNG(page).write(to: dir.appendingPathComponent("game-\(name)-\(scheme).png"))
            }
        }
    }

    /// Renders through a real window, which draws scroll views (ImageRenderer does not).
    private func windowPNG(_ view: some View, size: CGSize = CGSize(width: 402, height: 874)) async throws -> Data {
        let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(origin: .zero, size: size)
        window.rootViewController = UIHostingController(rootView: view)
        window.makeKeyAndVisible()
        try await Task.sleep(for: .milliseconds(600))
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        window.isHidden = true
        return try #require(image.pngData())
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
