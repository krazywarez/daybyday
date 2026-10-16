//
//  RoundView.swift
//  DayByDay
//

import SwiftUI

enum RoundStyle {
    static let playAgainFill = Color(red: 0.18, green: 0.56, blue: 0.28)
}

/// Runs a round of questions. The caller supplies how each choice looks.
struct RoundView<Choice: View>: View {
    private let items: [QuizItem]
    private let picker: QuestionPicker
    private let choice: (QuizItem) -> Choice

    @Environment(ProfileSession.self) private var session
    @State private var round: Round
    @State private var praise = PraisePhrases()
    @State private var celebrating = false
    @State private var dimmed: QuizItem?

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 320), spacing: 20)]

    init(items: [QuizItem], picker: QuestionPicker, @ViewBuilder choice: @escaping (QuizItem) -> Choice) {
        self.items = items
        self.picker = picker
        self.choice = choice
        _round = State(initialValue: Round(items: items, picker: picker))
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
        VStack(spacing: 28) {
            MascotView(mood: .cheering)
                .frame(width: 180, height: 180)
            Text("You did it!")
                .font(.system(size: 48, weight: .heavy, design: .rounded))
            Button {
                round = Round(items: items, picker: picker)
            } label: {
                Label("Play again", systemImage: "arrow.clockwise")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .background(Capsule().fill(RoundStyle.playAgainFill))
            }
            .buttonStyle(.plain)
        }
        .padding(32)
        .onAppear {
            SoundEngine.shared.play(.roundComplete)
            SpeechSynthesizer.shared.speak("You did it!")
        }
    }

    private func tap(_ item: QuizItem) {
        let outcome = round.answer(item)
        guard outcome != .ignored else { return }
        if let profile = session.current {
            session.store.record(round.current.answer, correct: outcome == .correct, for: profile)
        }
        switch outcome {
        case .correct:
            SoundEngine.shared.play(.success)
            var rng = SystemRandomNumberGenerator()
            SpeechSynthesizer.shared.speak(praise.next(using: &rng))
            celebrating = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                celebrating = false
                round.advance()
            }
        case .incorrect(let correctName):
            SoundEngine.shared.play(.gentleMiss)
            SpeechSynthesizer.shared.speak(PraisePhrases.correction(for: correctName))
            withAnimation(.easeOut(duration: 0.2)) { dimmed = item }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation { if dimmed == item { dimmed = nil } }
                round.resume()
            }
        case .ignored:
            break
        }
    }

    private func speakPrompt() {
        guard !round.isFinished else { return }
        SpeechSynthesizer.shared.speak(round.current.prompt)
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
