//
//  SortView.swift
//  DayByDay
//

import SwiftUI

enum SortStyle {
    /// Differs from the dark food card and stands out on black.
    static let binFill = Category.food.color
}

/// "Fruit or vegetable?": tap a bin, or drag the food into it.
struct SortView: View {
    @Environment(ProfileSession.self) private var session
    @State private var round: SortRound
    @State private var praise = PraisePhrases()
    @State private var celebrating = false
    @State private var shaking = false
    @State private var speechToken = 0
    /// Bumped when the screen goes away, so pending work does nothing.
    @State private var generation = 0
    /// Counts feedback lines, so a backstop from an earlier one does nothing.
    @State private var feedback = 0
    @State private var finished = false

    init() {
        var rng = SystemRandomNumberGenerator()
        _round = State(initialValue: SortRound(using: &rng))
    }

    var body: some View {
        ZStack {
            if finished {
                FinishedView {
                    var rng = SystemRandomNumberGenerator()
                    round = SortRound(using: &rng)
                    finished = false
                    say(round.prompt, after: 0.3)
                }
            } else {
                board
            }
        }
        .onAppear { say(round.prompt, after: 0) }
        .onDisappear {
            generation += 1
            speechToken += 1
            SpeechSynthesizer.shared.stop()
        }
    }

    private var board: some View {
        ScrollView {
            VStack(spacing: 28) {
                Button { say(round.prompt, after: 0) } label: {
                    Label("Hear it again", systemImage: "speaker.wave.2.fill")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .padding(.horizontal, 28)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(Color(.systemGray6)))
                }
                .buttonStyle(.plain)

                if let food = round.current {
                    let item = Category.food.item(food)
                    ChoiceTile(item: item)
                        .frame(width: 180, height: 180)
                        .offset(x: shaking ? -10 : 0)
                        .draggable(item.id) { ChoiceTile(item: item).frame(width: 140, height: 140) }
                        .accessibilityLabel(food.name)
                }

                HStack(spacing: 20) {
                    bin(isFruit: true)
                    bin(isFruit: false)
                }
            }
            .padding(24)
        }
        .overlay { CelebrationOverlay(isActive: celebrating) }
    }

    private func bin(isFruit: Bool) -> some View {
        let contents = isFruit ? round.fruitBin : round.vegetableBin
        return Button { place(isFruit: isFruit) } label: {
            VStack(spacing: 8) {
                Text(isFruit ? "🍎🍌" : "🥕🥦").font(.system(size: 44))
                Text(isFruit ? "Fruit" : "Vegetables")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(contents.map(\.emoji).joined())
                    .font(.system(size: 30))
                    .frame(height: 40)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(SortStyle.binFill))
        }
        .buttonStyle(.plain)
        .dropDestination(for: String.self) { _, _ in
            place(isFruit: isFruit)
            return true
        }
        .accessibilityLabel(isFruit ? "Fruit" : "Vegetables")
    }

    private func place(isFruit: Bool) {
        guard let food = round.current else { return }
        let outcome = round.place(isFruit: isFruit)
        guard outcome != .ignored else { return }
        if let profile = session.current {
            session.store.record(Category.food.item(food), game: .sortFood, correct: outcome == .correct, for: profile)
        }
        feedback += 1
        let gen = generation, line = feedback
        switch outcome {
        case .correct:
            SoundEngine.shared.play(.success)
            celebrating = true
            var rng = SystemRandomNumberGenerator()
            let text = "\(praise.next(using: &rng)) \(SortRound.fact(for: food)) \(round.prompt ?? "")"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                if gen == generation { celebrating = false }
            }
            guard round.isDone else {
                say(text, after: RoundStyle.speechDelay)
                break
            }
            // Finish once the last food's line has been said.
            let finish = {
                guard gen == generation, line == feedback, round.isDone else { return }
                finished = true
            }
            say(text, after: RoundStyle.speechDelay, then: finish)
            DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: finish)
        case .incorrect:
            SoundEngine.shared.play(.gentleMiss)
            withAnimation(.default.repeatCount(3)) { shaking = true }
            // Taps stay ignored until the correction has been said.
            let resume = {
                guard gen == generation, line == feedback, round.isShowingCorrection else { return }
                shaking = false
                round.resume()
            }
            say(round.correction(), after: RoundStyle.speechDelay, then: resume)
            DispatchQueue.main.asyncAfter(deadline: .now() + 6, execute: resume)
        case .ignored:
            break
        }
    }

    private func say(_ text: String?, after delay: TimeInterval, then completion: (() -> Void)? = nil) {
        guard let text, !text.isEmpty else { return }
        speechToken += 1
        let token = speechToken, gen = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if token == speechToken, gen == generation { SpeechSynthesizer.shared.speak(text, completion: completion) }
        }
    }
}
