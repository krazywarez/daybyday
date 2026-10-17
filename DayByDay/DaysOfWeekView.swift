//
//  DaysOfWeekView.swift
//  DayByDay
//

import SwiftData
import SwiftUI

/// Displays all seven days of the week as large, tappable cards in a scrollable grid.
/// Adapts between 1 and 2 columns depending on available width.
struct DaysOfWeekView: View {
    @Environment(ProfileSession.self) private var session

    private let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 500), spacing: 24)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(DayOfWeek.allCases) { day in
                    DayCard(day: day, isHighlighted: day == .current, picture: picture(on: day))
                        .frame(height: 200)
                }
            }
            .padding(32)
        }
        .onDisappear { CardVoice.shared.cancel() }
    }

    private func picture(on day: DayOfWeek) -> DayPictureKind? {
        session.current.flatMap { session.store.picture(on: day, for: $0) }
    }
}

#Preview {
    DaysOfWeekView()
        .environment(ProfileSession(store: ProfileStore(context: ProfileStore.makeContainer(inMemory: true).mainContext)))
}
