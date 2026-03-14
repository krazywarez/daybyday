//
//  BodyPartsView.swift
//  DayByDay
//

import SwiftUI

/// Displays all 12 body parts as large, tappable cards in a scrollable grid.
struct BodyPartsView: View {
    private let columns = [
        GridItem(.adaptive(minimum: 280), spacing: 24)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(LearnBodyPart.allCases) { part in
                    BodyPartCard(bodyPart: part)
                        .frame(height: 200)
                }
            }
            .padding(32)
        }
    }
}

#Preview {
    BodyPartsView()
}
