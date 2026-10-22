//
//  ColorsView.swift
//  DayByDay
//

import SwiftUI

/// Displays 10 colors as large, tappable cards in a scrollable grid.
/// Adapts between 1 and 2 columns depending on available width.
struct ColorsView: View {
    var body: some View {
        CardGrid(items: LearnColor.allCases) { color in
            ColorCard(learnColor: color)
        }
    }
}

#Preview {
    ColorsView()
}
