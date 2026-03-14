//
//  ShapesView.swift
//  DayByDay
//

import SwiftUI

/// Displays 8 shapes as large, tappable cards in a scrollable grid.
/// Adapts between 1 and 2 columns depending on available width.
struct ShapesView: View {
    private let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 500), spacing: 24)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(LearnShape.allCases) { shape in
                    ShapeCard(shape: shape)
                        .frame(height: 200)
                }
            }
            .padding(32)
        }
    }
}

#Preview {
    ShapesView()
}
