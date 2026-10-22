//
//  BodyPartsView.swift
//  DayByDay
//

import SwiftUI

/// Displays all 12 body parts as large, tappable cards in a scrollable grid.
struct BodyPartsView: View {
    var body: some View {
        CardGrid(items: LearnBodyPart.allCases, column: .narrowCards) { part in
            BodyPartCard(bodyPart: part)
        }
    }
}

#Preview {
    BodyPartsView()
}
