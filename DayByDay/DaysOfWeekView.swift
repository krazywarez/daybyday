//
//  DaysOfWeekView.swift
//  DayByDay
//

import SwiftUI

/// Displays all seven days of the week as large, tappable cards in a scrollable grid.
/// Adapts between 1 and 2 columns depending on available width.
struct DaysOfWeekView: View {
    private let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 500), spacing: 24)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(DayOfWeek.allCases) { day in
                    DayCard(day: day, isHighlighted: day == .current)
                        .frame(height: 200)
                }
            }
            .padding(32)
        }
    }
}

#Preview {
    DaysOfWeekView()
}
