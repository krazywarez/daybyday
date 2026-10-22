//
//  AnimalsView.swift
//  DayByDay
//

import SwiftUI

/// Displays 12 animals as large, tappable cards in a scrollable grid.
/// Adapts between 1 and 2 columns depending on available width.
struct AnimalsView: View {
    var body: some View {
        CardGrid(items: LearnAnimal.allCases) { animal in
            AnimalCard(animal: animal)
        }
        .onDisappear { CardVoice.shared.cancel() }
    }
}

#Preview {
    AnimalsView()
}
