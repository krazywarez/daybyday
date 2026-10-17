//
//  ClothingTile.swift
//  DayByDay
//

import SwiftUI

/// A thing to wear, white on the weather topic color.
struct ClothingTile: View {
    let item: QuizItem

    var body: some View {
        let clothing = Clothing.from(item)
        VStack(spacing: 10) {
            Image(systemName: clothing?.symbol ?? "questionmark")
                .font(.system(size: 56))
                .frame(height: 64)
            Text(item.name)
                .font(.heading(24))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 32, style: .continuous).fill(Category.weather.color))
        .contentShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    }
}
