//
//  RoundView.swift
//  DayByDay
//

import SwiftUI

enum RoundStyle {
    static let playAgainFill = Color(red: 0.18, green: 0.56, blue: 0.28)
    /// Gap between a feedback sound and the speech that follows it.
    static let speechDelay = 0.25
}

/// Runs a round of questions. The caller supplies how each choice looks.
struct RoundView<Choice: View>: View {
    private let source: any QuestionSource
    private let game: Game
    private let choice: (QuizItem) -> Choice

    @Environment(ProfileSession.self) private var session
    @State private var round: Round
    @State private var praise = PraisePhrases()
    @State private var celebrating = false
    @State private var dimmed: QuizItem?
    /// Bumped whenever something new is said, so a delayed prompt that has
    /// been overtaken stays quiet.
    @State private var speechToken = 0

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 320), spacing: 20)]

    init(source: any QuestionSource, game: Game, @ViewBuilder choice: @escaping (QuizItem) -> Choice) {
        self.source = source
        self.game = game
        self.choice = choice
        _round = State(initialValue: Round(source: source))
    }

    var body: some View {
        Group {
            if round.isComplete {
                finished
            } else {
                question
            }
        }
        .onAppear { speakPrompt() }
        .onDisappear {
            speechToken += 1
            SpeechSynthesizer.shared.stop()
        }
        .onChange(of: round.current) { speakPrompt() }
    }

    private var question: some View {
        ScrollView {
            VStack(spacing: 28) {
                Button(action: speakPrompt) {
                    Label("Hear it again", systemImage: "speaker.wave.2.fill")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .padding(.horizontal, 28)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(Color(.systemGray6)))
                }
                .buttonStyle(.plain)

                ProgressDots(filled: round.correctCount, total: Round.length)

                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(round.current.choices) { item in
                        Button { tap(item) } label: {
                            choice(item)
                                .frame(height: 160)
                                .opacity(dimmed == item ? 0.4 : 1)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(item.name)
                    }
                }
            }
            .padding(32)
        }
        .overlay { CelebrationOverlay(isActive: celebrating) }
    }

    private var finished: some View {
        FinishedView {
            round = Round(source: source, after: round.current.answer)
        }
    }

    private func tap(_ item: QuizItem) {
        let outcome = round.answer(item)
        guard outcome != .ignored else { return }
        if let profile = session.current {
            session.store.record(round.current.answer, chosen: item, game: game,
                                 correct: outcome == .correct, for: profile)
        }
        switch outcome {
        case .correct:
            SoundEngine.shared.play(.success)
            var rng = SystemRandomNumberGenerator()
            say(praise.next(using: &rng), after: RoundStyle.speechDelay)
            celebrating = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                celebrating = false
                round.advance()
            }
        case .incorrect:
            SoundEngine.shared.play(.gentleMiss)
            say(round.current.correction(for: item), after: RoundStyle.speechDelay)
            withAnimation(.easeOut(duration: 0.2)) { dimmed = item }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation { if dimmed == item { dimmed = nil } }
                round.resume()
            }
        case .ignored:
            break
        }
    }

    /// Plays the question's sound cue, if any, then speaks the prompt.
    private func speakPrompt() {
        guard !round.isFinished, !round.isAwaitingNext else { return }
        if let sound = round.current.sound {
            speechToken += 1
            SpeechSynthesizer.shared.stop()
            SoundEngine.shared.play(sound)
            say(round.current.prompt, after: SoundEngine.shared.remaining(sound) + 0.2)
        } else {
            say(round.current.prompt, after: 0)
        }
    }

    private func say(_ text: String, after delay: TimeInterval) {
        speechToken += 1
        let token = speechToken
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if token == speechToken { SpeechSynthesizer.shared.speak(text) }
        }
    }
}

/// Filled dots showing how many correct answers are done in this round.
private struct ProgressDots: View {
    let filled: Int
    let total: Int

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i < filled ? Color.yellow : Color(.systemGray5))
                    .frame(width: 22, height: 22)
            }
        }
        .accessibilityHidden(true)
    }
}
