//
//  MonthsOfYearView.swift
//  DayByDay
//

import SwiftUI

/// Displays all twelve months as large, tappable cards in a scrollable grid.
/// Adapts between 1 and 2 columns depending on available width.
struct MonthsOfYearView: View {
    var body: some View {
        CardGrid(items: MonthOfYear.allCases) { month in
            MonthCard(month: month, isHighlighted: month == .current)
        }
    }
}

#Preview {
    MonthsOfYearView()
}
