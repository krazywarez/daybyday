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

    var body: some View {
        CardGrid(items: DayOfWeek.allCases) { day in
            DayCard(day: day, isHighlighted: day == .current, picture: picture(on: day))
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
