//
//  FoodView.swift
//  DayByDay
//

import SwiftUI

/// Displays all 12 fruits and vegetables as large, tappable cards in a scrollable grid.
struct FoodView: View {
    var body: some View {
        CardGrid(items: LearnFood.allCases, column: .narrowCards) { food in
            FoodCard(food: food)
        }
    }
}

#Preview {
    FoodView()
}
