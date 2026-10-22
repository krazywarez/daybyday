//
//  ShapesView.swift
//  DayByDay
//

import SwiftUI

/// Displays 8 shapes as large, tappable cards in a scrollable grid.
/// Adapts between 1 and 2 columns depending on available width.
struct ShapesView: View {
    var body: some View {
        CardGrid(items: LearnShape.allCases) { shape in
            ShapeCard(shape: shape)
        }
    }
}

#Preview {
    ShapesView()
}
