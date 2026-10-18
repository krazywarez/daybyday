//
//  MovesView.swift
//  DayByDay
//

import SwiftUI

/// "Touch your nose!": the app says a move, waits while the child does it,
/// then cheers.
struct MovesView: View {
    static let wait = 3.0

    @State private var round: MovesRound
    @State private var praise = PraisePhrases()
    @State private var celebrating = false
    @State private var mascot = MascotState()
    /// Bumped by each new move and when the screen goes away.
    @State private var generation = 0

    init() {
        var rng = SystemRandomNumberGenerator()
        _round = State(initialValue: MovesRound(using: &rng))
    }

    var body: some View {
        ZStack {
            if let part = round.current {
                CenteredScrollView {
                    VStack(spacing: 32) {
                        PromptBar(mascot: $mascot) { start() }
                        Image(systemName: part.symbol)
                            .font(.system(size: 140))
                            .foregroundStyle(.white)
                            .frame(width: 240, height: 240)
                            .background(RoundedRectangle(cornerRadius: 40, style: .continuous).fill(Category.bodyParts.color))
                            .accessibilityLabel(part.name)
                        Text(part.command)
                            .font(.heading(30, weight: .heavy))
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                }
                .overlay { CelebrationOverlay(isActive: celebrating) }
            } else {
                FinishedView {
                    var rng = SystemRandomNumberGenerator()
                    round = MovesRound(using: &rng)
                    start()
                }
            }
        }
        .onAppear { start() }
        .onDisappear {
            generation += 1
            SpeechSynthesizer.shared.stop()
        }
    }

    /// Says the move, waits, cheers, then goes on to the next move.
    private func start() {
        guard let part = round.current else { return }
        generation += 1
        let gen = generation
        celebrating = false
        mascot.handle(.prompt(part.command))
        SpeechSynthesizer.shared.speak(part.command) {
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.wait) {
                guard gen == generation else { return }
                SoundEngine.shared.play(.success)
                mascot.handle(.correct)
                celebrating = true
                var rng = SystemRandomNumberGenerator()
                DispatchQueue.main.asyncAfter(deadline: .now() + RoundStyle.speechDelay) {
                    guard gen == generation else { return }
                    SpeechSynthesizer.shared.speak(praise.next(using: &rng)) {
                        guard gen == generation else { return }
                        round.next()
                        start()
                    }
                }
            }
        }
    }
}
