//
//  FoodView.swift
//  DayByDay
//

import SwiftUI

/// Displays all 12 fruits and vegetables as large, tappable cards in a scrollable grid.
struct FoodView: View {
    private let columns = [
        GridItem(.adaptive(minimum: 280), spacing: 24)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(LearnFood.allCases) { food in
                    FoodCard(food: food)
                        .frame(height: 200)
                }
            }
            .padding(32)
        }
    }
}

#Preview {
    FoodView()
}
