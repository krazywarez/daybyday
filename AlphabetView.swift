//
//  AlphabetView.swift
//  DayByDay
//

import SwiftUI

/// Displays all 26 letters A–Z as large, tappable cards in a scrollable grid.
/// Uses a smaller minimum size to fit more letters across the screen.
struct AlphabetView: View {
    var body: some View {
        CardGrid(items: LearnLetter.allCases, column: GridItem(.adaptive(minimum: 140, maximum: 300), spacing: 20), spacing: 20, minHeight: 160) { letter in
            LetterCard(letter: letter)
        }
        .onDisappear { CardVoice.shared.cancel() }
    }
}

#Preview {
    AlphabetView()
}
