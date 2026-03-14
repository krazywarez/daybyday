//
//  ColorsView.swift
//  DayByDay
//

import SwiftUI

/// Displays 10 colors as large, tappable cards in a scrollable grid.
/// Adapts between 1 and 2 columns depending on available width.
struct ColorsView: View {
    private let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 500), spacing: 24)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(LearnColor.allCases) { color in
                    ColorCard(learnColor: color)
                        .frame(height: 200)
                }
            }
            .padding(32)
        }
    }
}

#Preview {
    ColorsView()
}
