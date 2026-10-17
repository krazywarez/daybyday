//
//  TraceView.swift
//  DayByDay
//

import SwiftUI

/// Trace five shapes or letters with a finger.
struct TraceView: View {
    static let length = 5

    let category: Category

    @Environment(ProfileSession.self) private var session
    @State private var items: [QuizItem]
    @State private var index = 0
    @State private var strokes: [[CGPoint]] = []
    @State private var celebrating = false
    @State private var mascot = MascotState()
    @State private var busy = false
    @State private var speechToken = 0
    /// Bumped when the screen goes away, so pending work does nothing.
    @State private var generation = 0
    /// Counts passes, so a backstop from an earlier pass does nothing.
    @State private var passes = 0

    init(category: Category) {
        self.category = category
        _items = State(initialValue: Self.pick(category))
    }

    private static func pick(_ category: Category) -> [QuizItem] {
        Array(category.quizItems.shuffled().prefix(length))
    }

    private var item: QuizItem? { index < items.count ? items[index] : nil }

    private func label(_ item: QuizItem) -> String {
        category == .alphabet ? "the letter \(item.name)" : "the \(item.name.lowercased())"
    }

    var body: some View {
        ZStack {
            if let item {
                board(item)
            } else {
                FinishedView {
                    items = Self.pick(category)
                    index = 0
                    strokes = []
                    prompt()
                }
            }
        }
        .onAppear { prompt() }
        .onDisappear {
            generation += 1
            speechToken += 1
            SpeechSynthesizer.shared.stop()
        }
    }

    private func board(_ item: QuizItem) -> some View {
        VStack(spacing: 20) {
            // Own row: beside both pills it would squeeze their labels on a phone.
            GameMascot(state: $mascot)
            HStack(spacing: 16) {
                pill("Hear it again", "speaker.wave.2.fill", action: prompt)
                pill("Start over", "eraser.fill") { strokes = [] }
            }
            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                let region = Path(TraceGuide.region(for: item, size: size))
                ZStack {
                    region.fill(category.color.opacity(0.4))
                    region.stroke(category.color, style: StrokeStyle(lineWidth: 3, dash: [10, 8]))
                    ForEach(Array(strokes.enumerated()), id: \.offset) { _, stroke in
                        Path { p in p.addLines(stroke) }
                            // Primary, not the topic color, so the ink shows on the guide in both modes.
                            .stroke(Color.primary, style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round, lineJoin: .round))
                    }
                }
                .frame(width: size, height: size)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard !busy else { return }
                            if value.translation == .zero || strokes.isEmpty { strokes.append([]) }
                            strokes[strokes.count - 1].append(value.location)
                        }
                        .onEnded { _ in check(item, size: size) }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel("Trace \(label(item))")
            }
            .frame(maxWidth: 520)
        }
        .padding(24)
        .overlay { CelebrationOverlay(isActive: celebrating) }
    }

    private func pill(_ title: String, _ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Capsule().fill(Color(.systemGray6)))
        }
        .buttonStyle(.plain)
    }

    private func check(_ item: QuizItem, size: CGFloat) {
        guard !busy else { return }
        let checker = TraceChecker(region: TraceGuide.region(for: item, size: size), size: size)
        let drawn = strokes.flatMap { $0 }
        let score = checker.score(drawn)
        if checker.passes(drawn) {
            record(item, correct: true)
            busy = true
            celebrating = true
            SoundEngine.shared.play(.success)
            mascot.handle(.correct)
            passes += 1
            let gen = generation, pass = passes
            let advance = {
                guard gen == generation, pass == passes, busy else { return }
                busy = false
                celebrating = false
                strokes = []
                index += 1
                if self.item != nil { prompt() }
            }
            say("You traced \(label(item))!", after: RoundStyle.speechDelay, then: advance)
            DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: advance)
        } else if score.accuracy < 0.5 && score.coverage > 0.4 {
            record(item, correct: false)
            SoundEngine.shared.play(.gentleMiss)
            mascot.handle(.wrong)
            strokes = []
            say("Stay on \(label(item)). Let's try again.", after: RoundStyle.speechDelay)
        }
    }

    private func record(_ item: QuizItem, correct: Bool) {
        if let profile = session.current {
            session.store.record(item, game: .trace, correct: correct, for: profile)
        }
    }

    private func prompt() {
        guard let item else { return }
        let text = category == .alphabet ? "Trace the letter \(item.name) with your finger."
                                         : "Trace the \(item.name.lowercased()) with your finger."
        mascot.handle(.prompt(text))
        say(text, after: 0)
    }

    private func say(_ text: String, after delay: TimeInterval, then completion: (() -> Void)? = nil) {
        speechToken += 1
        let token = speechToken, gen = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard token == speechToken, gen == generation else { return }
            SpeechSynthesizer.shared.speak(text, completion: completion)
        }
    }
}
