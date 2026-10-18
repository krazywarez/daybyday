//
//  CountingView.swift
//  DayByDay
//

import SwiftUI

/// Tap each object to count it aloud; the total is shown and said at the end.
struct CountingView: View {
    @State private var round: CountingRound
    @State private var showTotal = false
    @State private var celebrating = false
    @State private var mascot = MascotState()
    @State private var speechToken = 0
    /// Bumped when the screen goes away, so pending work says nothing.
    @State private var generation = 0
    @ScaledMetric(relativeTo: .largeTitle) private var totalHeight = 110
    @ScaledMetric(relativeTo: .largeTitle) private var objectHeight = 104

    private let columns = [GridItem(.adaptive(minimum: 96, maximum: 140), spacing: 16)]
    private let color = Category.numbers.color

    init() {
        var rng = SystemRandomNumberGenerator()
        _round = State(initialValue: CountingRound(using: &rng))
    }

    var body: some View {
        ZStack {
            if round.isComplete {
                FinishedView {
                    var rng = SystemRandomNumberGenerator()
                    round = CountingRound(using: &rng)
                    ask(after: 0.3)
                }
            } else {
                board
            }
        }
        .onAppear { ask(after: 0) }
        .onDisappear {
            generation += 1
            speechToken += 1
            SpeechSynthesizer.shared.stop()
        }
    }

    private var prompt: String { Lines.countPrompt(round.thing) }

    private var board: some View {
        ScrollView {
            VStack(spacing: 28) {
                PromptBar(mascot: $mascot, prompt: prompt) { ask(after: 0) }

                Text(showTotal ? "\(round.target)" : " ")
                    .font(.heading(96, weight: .heavy))
                    .foregroundStyle(color)
                    .frame(height: totalHeight)
                    .accessibilityHidden(!showTotal)

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(0..<round.target, id: \.self) { i in
                        Button { tap(i) } label: { object(i) }
                            .buttonStyle(.plain)
                            .accessibilityLabel(round.thing.singular)
                            .accessibilityValue(round.counted.firstIndex(of: i).map { "\($0 + 1)" } ?? "")
                    }
                }
            }
            .padding(24)
        }
        .overlay { CelebrationOverlay(isActive: celebrating) }
    }

    /// Uncounted: the symbol in the numbers color. Counted: white symbol and
    /// its count on a numbers-colored tile.
    private func object(_ i: Int) -> some View {
        let order = round.counted.firstIndex(of: i).map { $0 + 1 }
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        return ZStack {
            shape.fill(order == nil ? Color.clear : color)
            if let order {
                VStack(spacing: 2) {
                    Image(systemName: round.thing.symbol).font(.system(size: 30))
                    Text("\(order)").font(.heading(34, weight: .heavy))
                }
                .foregroundStyle(.white)
            } else {
                Image(systemName: round.thing.symbol)
                    .font(.system(size: 60))
                    .foregroundStyle(color)
            }
        }
        .frame(height: objectHeight)
        .contentShape(shape)
    }

    private func tap(_ i: Int) {
        guard let count = round.tap(i) else { return }
        guard round.isSetDone else {
            say(LearnNumber(rawValue: count)!.name, after: 0)
            return
        }
        let summary = round.summary()
        SoundEngine.shared.play(.success)
        mascot.handle(.correct)
        showTotal = true
        celebrating = true
        say(summary, after: RoundStyle.speechDelay)
        let words = summary.split(separator: " ").count
        let gen = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5 + 0.45 * Double(words)) {
            guard gen == generation else { return }
            celebrating = false
            showTotal = false
            var rng = SystemRandomNumberGenerator()
            round.nextSet(using: &rng)
            if !round.isComplete { ask(after: 0) }
        }
    }

    /// Says the prompt, with the mascot asking.
    private func ask(after delay: TimeInterval) {
        mascot.handle(.prompt(prompt, after: delay))
        say(prompt, after: delay)
    }

    private func say(_ text: String, after delay: TimeInterval) {
        speechToken += 1
        let token = speechToken, gen = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if token == speechToken, gen == generation { SpeechSynthesizer.shared.speak(text) }
        }
    }
}
