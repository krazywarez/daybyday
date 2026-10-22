//
//  NumbersView.swift
//  DayByDay
//

import SwiftUI

/// Displays numbers 1–10 as large, tappable cards in a scrollable grid.
/// Adapts between 1 and 2 columns depending on available width.
struct NumbersView: View {
    var body: some View {
        CardGrid(items: LearnNumber.allCases) { number in
            NumberCard(number: number, isHighlighted: number == .current)
        }
    }
}

#Preview {
    NumbersView()
}
