//
//  SequencePuzzleView.swift
//  DayByDay
//

import SwiftUI

/// Week train and yesterday/today/tomorrow: slots on top, cards below.
/// Tap a card to place it, or drag it anywhere onto the slots.
struct SequencePuzzleView: View {
    let game: Game
    let make: () -> SequencePuzzle

    @Environment(ProfileSession.self) private var session
    @State private var puzzle: SequencePuzzle
    @State private var praise = PraisePhrases()
    @State private var dimmed: QuizItem?
    @State private var mascot = MascotState()
    @State private var celebrating = false
    @State private var finished = false
    @State private var speechToken = 0
    /// Bumped when the screen goes away, so pending work does nothing.
    @State private var generation = 0
    /// Counts finished games, so a timer from an earlier game is ignored.
    @State private var solves = 0

    private let columns = [GridItem(.adaptive(minimum: 130, maximum: 220), spacing: 16)]

    init(game: Game, make: @escaping () -> SequencePuzzle) {
        self.game = game
        self.make = make
        _puzzle = State(initialValue: make())
    }

    var body: some View {
        ZStack {
            if finished {
                FinishedView {
                    puzzle = make()
                    finished = false
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

    private var board: some View {
        ScrollView {
            VStack(spacing: 28) {
                HStack(spacing: 12) {
                    GameMascot(state: $mascot)
                    Button { ask(after: 0) } label: {
                        Label("Hear it again", systemImage: "speaker.wave.2.fill")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .padding(.horizontal, 28)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(Color(.systemGray6)))
                    }
                    .buttonStyle(.plain)
                }

                slots
                    .dropDestination(for: String.self) { ids, _ in
                        guard let id = ids.first, let item = puzzle.pool.first(where: { $0.id == id }) else { return false }
                        place(item)
                        return true
                    }

                LazyVGrid(columns: columns, spacing: 16) {
                    // Placed cards keep their spot, hidden, so the rest don't move.
                    ForEach(puzzle.pool) { item in
                        let isPlaced = puzzle.placed.contains(item)
                        Button { place(item) } label: {
                            ChoiceTile(item: item)
                                .frame(height: 130)
                                .opacity(isPlaced ? 0 : dimmed == item ? 0.4 : 1)
                        }
                        .buttonStyle(.plain)
                        .disabled(isPlaced)
                        .accessibilityHidden(isPlaced)
                        .draggable(item.id) {
                            ChoiceTile(item: item).frame(width: 130, height: 130)
                        }
                        .accessibilityLabel(item.name)
                    }
                }
            }
            .padding(24)
        }
        .overlay { CelebrationOverlay(isActive: celebrating) }
    }

    @ViewBuilder
    private var slots: some View {
        if let labels = puzzle.slotLabels {
            HStack(alignment: .top, spacing: 12) {
                ForEach(Array(labels.enumerated()), id: \.offset) { i, label in
                    VStack(spacing: 8) {
                        Text(label)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        slot(i).frame(height: 130)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        } else {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 6) {
                        TrainEngine()
                            .frame(width: 130, height: 150)
                        ForEach(puzzle.steps.indices, id: \.self) { i in
                            TrainCar { slot(i) }
                                .frame(width: 130, height: 150)
                                .id(i)
                        }
                    }
                    .padding(.vertical, 4)
                }
                // Run edge to edge instead of clipping cars at the page margin.
                .contentMargins(.horizontal, 24, for: .scrollContent)
                .padding(.horizontal, -24)
                .onAppear { proxy.scrollTo(nextCar, anchor: .center) }
                .onChange(of: puzzle.placed.count) {
                    withAnimation { proxy.scrollTo(nextCar, anchor: .center) }
                }
            }
        }
    }

    private var nextCar: Int { min(puzzle.placed.count, puzzle.steps.count - 1) }

    /// A placed card, the outlined next slot, or a faint empty slot.
    @ViewBuilder
    private func slot(_ i: Int) -> some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        if i < puzzle.placed.count {
            ChoiceTile(item: puzzle.placed[i])
        } else {
            shape
                .fill(Color(.systemGray6))
                .overlay {
                    shape.strokeBorder(i == puzzle.placed.count ? Category.days.color : Color(.systemGray3),
                                       style: StrokeStyle(lineWidth: i == puzzle.placed.count ? 5 : 2, dash: [10, 8]))
                }
        }
    }

    private func place(_ item: QuizItem) {
        guard let step = puzzle.current else { return }
        let outcome = puzzle.place(item)
        guard outcome != .ignored else { return }
        if let profile = session.current {
            session.store.record(step.answer, chosen: item, game: game, correct: outcome == .correct, for: profile)
        }
        switch outcome {
        case .correct where puzzle.isSolved:
            let sound: SoundEffect = game == .weekTrain ? .whistle : .success
            SoundEngine.shared.play(sound)
            mascot.handle(.correct)
            celebrating = true
            speechToken += 1
            solves += 1
            let token = speechToken, gen = generation, solve = solves
            let finish = {
                guard gen == generation, solve == solves, !finished else { return }
                celebrating = false
                finished = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + SoundEngine.shared.remaining(sound) + 0.2) {
                guard gen == generation, token == speechToken else { return }
                // Move on when the whole summary has been said.
                SpeechSynthesizer.shared.speak(puzzle.summary, completion: finish)
            }
            // In case the summary is cut off and never finishes.
            DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: finish)
        case .correct:
            SoundEngine.shared.play(.success)
            mascot.handle(.correct)
            var rng = SystemRandomNumberGenerator()
            // One utterance: a second speak() would cut the praise off.
            say("\(praise.next(using: &rng)) \(puzzle.current?.prompt ?? "")", after: RoundStyle.speechDelay)
            askAfterCheer()
        case .incorrect:
            SoundEngine.shared.play(.gentleMiss)
            mascot.handle(.wrong)
            say(puzzle.correction(), after: RoundStyle.speechDelay)
            withAnimation(.easeOut(duration: 0.2)) { dimmed = item }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation { if dimmed == item { dimmed = nil } }
                puzzle.resume()
            }
        case .ignored:
            break
        }
    }

    /// Praise and the next prompt are one line; the owl asks once the cheer is over.
    private func askAfterCheer() {
        let ticket = mascot.ticket, gen = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + mascot.hold) {
            guard gen == generation, ticket == mascot.ticket, let prompt = puzzle.current?.prompt else { return }
            mascot.handle(.prompt(prompt))
        }
    }

    /// Says the current step's prompt, with the mascot asking.
    private func ask(after delay: TimeInterval) {
        let prompt = puzzle.current?.prompt ?? ""
        mascot.handle(.prompt(prompt, after: delay))
        say(prompt, after: delay)
    }

    /// Speaks after `delay` unless something newer was said first.
    private func say(_ text: String, after delay: TimeInterval) {
        guard !text.isEmpty else { return }
        speechToken += 1
        let token = speechToken, gen = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if token == speechToken, gen == generation { SpeechSynthesizer.shared.speak(text) }
        }
    }
}

enum TrainStyle {
    /// Visible on both light and dark backgrounds.
    static let tire = Color(white: 0.45)
    static let hub = Color(white: 0.75)
}

/// A toy engine facing left, so its cab sits next to the first car.
private struct TrainEngine: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let color = Category.days.color
            ZStack(alignment: .topLeading) {
                // Chimney, cab, boiler.
                RoundedRectangle(cornerRadius: 4).fill(color)
                    .frame(width: w * 0.16, height: h * 0.22)
                    .offset(x: w * 0.62, y: h * 0.12)
                RoundedRectangle(cornerRadius: 10).fill(color)
                    .frame(width: w * 0.42, height: h * 0.72)
                    .offset(x: w * 0.02, y: h * 0.08)
                RoundedRectangle(cornerRadius: 6).fill(.white.opacity(0.85))
                    .frame(width: w * 0.24, height: h * 0.2)
                    .offset(x: w * 0.11, y: h * 0.16)
                RoundedRectangle(cornerRadius: 14).fill(color)
                    .frame(width: w * 0.62, height: h * 0.4)
                    .offset(x: w * 0.36, y: h * 0.4)
                RoundedRectangle(cornerRadius: 3).fill(Color(.systemGray))
                    .frame(width: w, height: 6)
                    .offset(y: h * 0.82)
                wheels(w: w, h: h, at: [0.2, 0.5, 0.8])
            }
            .scaleEffect(x: -1)
        }
        .accessibilityHidden(true)
    }
}

/// A flat car with the slot on top and two wheels.
private struct TrainCar<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack(alignment: .topLeading) {
                content()
                    .frame(width: w, height: h * 0.8)
                RoundedRectangle(cornerRadius: 3).fill(Color(.systemGray))
                    .frame(width: w + 6, height: 6)
                    .offset(x: -3, y: h * 0.82)
                wheels(w: w, h: h, at: [0.25, 0.75])
            }
        }
    }
}

private func wheels(w: CGFloat, h: CGFloat, at positions: [CGFloat]) -> some View {
    let d = h * 0.2
    return ForEach(positions, id: \.self) { x in
        Circle()
            .fill(TrainStyle.tire)
            .overlay(Circle().fill(TrainStyle.hub).padding(d * 0.3))
            .frame(width: d, height: d)
            .offset(x: w * x - d / 2, y: h - d)
    }
}
