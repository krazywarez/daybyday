//
//  TapCard.swift
//  DayByDay
//

import SwiftUI

/// The rounded, colored card shared by every learning category.
/// Tapping it plays a bounce animation and runs `onTap`, which speaks the card.
/// A highlighted card (today's day, month, or season) is enlarged, glows, and has a white border.
struct TapCard<Content: View, Badge: View>: View {
    let color: Color
    let label: String
    var isHighlighted = false
    let onTap: () -> Void
    @ViewBuilder let content: () -> Content
    @ViewBuilder var badge: () -> Badge
    @State private var isTapped = false

    private var cardScale: CGFloat {
        if isTapped { return 1.12 }
        if isHighlighted { return 1.04 }
        return 1.0
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(color)
                .shadow(color: color.opacity(0.4), radius: 8, y: 4)
                // Glow on the card only: on the label it would lower the contrast.
                .shadow(color: isHighlighted ? .white.opacity(0.8) : .clear, radius: 12)

            content()
        }
        .overlay(alignment: .topTrailing) { badge() }
        .overlay {
            if isHighlighted {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .strokeBorder(.white, lineWidth: 5)
            }
        }
        .scaleEffect(cardScale)
        .contentShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .rotation3DEffect(.degrees(isTapped ? 6 : 0), axis: (x: 1, y: 0, z: 0))
        .animation(.spring(response: 0.35, dampingFraction: 0.5), value: isTapped)
        .onTapGesture {
            isTapped = true
            onTap()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isTapped = false
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
    }
}

extension TapCard where Badge == EmptyView {
    init(
        color: Color,
        label: String,
        isHighlighted: Bool = false,
        onTap: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(color: color, label: label, isHighlighted: isHighlighted, onTap: onTap, content: content, badge: { EmptyView() })
    }
}

/// An SF Symbol above a name, the content of most category cards.
struct SymbolLabel: View {
    let symbol: String
    let name: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 64))
                .foregroundStyle(.white)
                .symbolRenderingMode(.hierarchical)

            Text(name)
                .font(.heading(32))
                .foregroundStyle(.white)
        }
        .padding(16)
    }
}
