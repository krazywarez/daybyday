//
//  GameDestination.swift
//  DayByDay
//

import SwiftUI

/// The screen a hub button opens for one game.
struct GameDestination: View {
    let category: Category
    let game: Game

    var body: some View {
        content.navigationTitle(game.title)
    }

    @ViewBuilder
    private var content: some View {
        switch game {
        case .most:
            RoundView(source: category.questionSource(for: game), game: game) { PileTile(item: $0) }
        case .dressUp:
            RoundView(source: category.questionSource(for: game), game: game) { ClothingTile(item: $0) }
        case .findIt, .oddOneOut, .listen, .comesNext, .whichSeason, .mixColors:
            RoundView(source: category.questionSource(for: game), game: game) { ChoiceTile(item: $0) }
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
