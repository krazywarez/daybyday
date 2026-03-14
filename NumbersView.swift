//
//  NumbersView.swift
//  DayByDay
//

import SwiftUI

/// Displays numbers 1–10 as large, tappable cards in a scrollable grid.
/// Adapts between 1 and 2 columns depending on available width.
struct NumbersView: View {
    private let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 500), spacing: 24)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(LearnNumber.allCases) { number in
                    NumberCard(
                        number: number,
                        isHighlighted: number == .current
                    )
                    .frame(height: 200)
                }
            }
            .padding(32)
        }
    }
}

#Preview {
    NumbersView()
}
