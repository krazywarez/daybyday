//
//  CardGrid.swift
//  DayByDay
//

import SwiftUI

/// Large, tappable cards in a scrollable adaptive grid.
struct CardGrid<Item: Identifiable, Card: View, Header: View>: View {
    let items: [Item]
    var column = GridItem(.adaptive(minimum: 300, maximum: 500), spacing: 24)
    var spacing: CGFloat = 24
    var minHeight: CGFloat = 200
    @ViewBuilder var header: () -> Header
    @ViewBuilder let card: (Item) -> Card

    var body: some View {
        ScrollView {
            header()
            LazyVGrid(columns: [column], spacing: spacing) {
                ForEach(items) { item in
                    card(item)
                        .frame(minHeight: minHeight)
                }
            }
            .padding(32)
        }
    }
}

extension CardGrid where Header == EmptyView {
    init(
        items: [Item],
        column: GridItem = GridItem(.adaptive(minimum: 300, maximum: 500), spacing: 24),
        spacing: CGFloat = 24,
        minHeight: CGFloat = 200,
        @ViewBuilder card: @escaping (Item) -> Card
    ) {
        self.init(items: items, column: column, spacing: spacing, minHeight: minHeight, header: { EmptyView() }, card: card)
    }
}

extension GridItem {
    /// Columns for cards with longer names, which need a narrower minimum to fit two across.
    static let narrowCards = GridItem(.adaptive(minimum: 280), spacing: 24)
}
