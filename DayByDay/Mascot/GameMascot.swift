//
//  GameMascot.swift
//  DayByDay
//

import SwiftUI

/// A game's mascot, small enough to sit beside "Hear it again". Puts the
/// mood back to idle once it has held.
struct GameMascot: View {
    @Binding var state: MascotState

    /// Bumped when the mascot goes away, so a pending settle does nothing.
    @State private var generation = 0

    var body: some View {
        MascotView(mood: state.mood)
            .frame(width: 64, height: 64)
            .onAppear(perform: scheduleSettle)
            .onChange(of: state.ticket, scheduleSettle)
            .onDisappear { generation += 1 }
    }

    private func scheduleSettle() {
        let ticket = state.ticket, gen = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + state.hold) {
            if gen == generation { state.settle(ticket) }
        }
    }
}
