//
//  GameDestination.swift
//  DayByDay
//

import SwiftUI

/// The screen a hub button opens for one game.
struct GameDestination: View {
    let category: Category
    let game: Game

    @Environment(ProfileSession.self) private var session

    var body: some View {
        content.navigationTitle(game.title)
    }

    /// Weights as of this render: the open round keeps its first question,
    /// and the next round uses the latest answers.
    private var source: any QuestionSource {
        let weights = session.current.map { session.store.reviewWeights(for: $0, category: category) } ?? [:]
        return category.questionSource(for: game, weights: weights)
    }

    @ViewBuilder
    private var content: some View {
        switch game {
        case .most:
            RoundView(source: source, game: game) { PileTile(item: $0) }
        case .dressUp:
            RoundView(source: source, game: game) { ClothingTile(item: $0) }
        case .findIt, .oddOneOut, .listen, .comesNext, .whichSeason, .mixColors:
            RoundView(source: source, game: game) { ChoiceTile(item: $0) }
        case .weekTrain:
            SequencePuzzleView(game: game) {
                var rng = SystemRandomNumberGenerator()
                return .weekTrain(using: &rng)
            }
        case .yesterdayTomorrow:
            SequencePuzzleView(game: game) {
                var rng = SystemRandomNumberGenerator()
                return .yesterdayTomorrow(today: .current, using: &rng)
            }
        case .yearWheel:
            YearWheelView()
        case .counting:
            CountingView()
        case .trace:
            TraceView(category: category)
        case .sortFood:
            SortView()
        case .moves:
            MovesView()
        }
    }
}
