//
//  AlphabetView.swift
//  DayByDay
//

import SwiftUI

/// Displays all 26 letters A–Z as large, tappable cards in a scrollable grid.
/// Uses a smaller minimum size to fit more letters across the screen.
struct AlphabetView: View {
    private let columns = [
        GridItem(.adaptive(minimum: 140, maximum: 300), spacing: 20)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(LearnLetter.allCases) { letter in
                    LetterCard(letter: letter)
                        .frame(height: 160)
                }
            }
            .padding(32)
        }
    }
}

#Preview {
    AlphabetView()
}
