//
//  ChoiceTile.swift
//  DayByDay
//

import SwiftUI

enum ChoiceStyle {
    /// Dark enough that every food emoji stands out.
    static let foodFill = Color(red: 0.24, green: 0.16, blue: 0.10)
    /// Edge for color swatches, visible on light and dark backgrounds.
    static let swatchOutline = Color(white: 0.45)
}

/// One answer choice in a game. Flat fills only: white content sits on the
/// topic color, which is at least 3:1 against white.
struct ChoiceTile: View {
    let item: QuizItem

    @Environment(\.colorScheme) private var colorScheme

    private static let shape = RoundedRectangle(cornerRadius: 32, style: .continuous)

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(12)
            .background(Self.shape.fill(fill))
            .overlay {
                if item.category == .colors {
                    Self.shape.strokeBorder(ChoiceStyle.swatchOutline, lineWidth: 4)
                } else if item.category == .food, colorScheme == .dark {
                    Self.shape.strokeBorder(.white.opacity(0.25), lineWidth: 2)
                }
            }
            .contentShape(Self.shape)
    }

    private var fill: Color {
        switch item.category {
        case .colors: item.value(LearnColor.self)!.color
        case .food:   ChoiceStyle.foodFill
        default:      item.category.color
        }
    }

    @ViewBuilder
    private var content: some View {
        switch item.category {
        case .colors:
            Color.clear
        case .food:
            Text(item.value(LearnFood.self)!.emoji)
                .font(.system(size: 80))
        case .animals:
            AnimalIcon(animal: item.value(LearnAnimal.self)!)
                .font(.system(size: 72))
                .frame(width: 100, height: 100)
                .foregroundStyle(.white)
        case .weather:
            symbol(item.value(LearnWeather.self)!.symbol)
        case .bodyParts:
            symbol(item.value(LearnBodyPart.self)!.symbol)
        case .shapes:
            let shape = item.value(LearnShape.self)!
            shape.shapeView
                .frame(width: 90, height: 90)
                .scaleEffect([.star, .heart].contains(shape) ? 1.15 : 1)
        case .alphabet:
            Text(item.value(LearnLetter.self)!.character)
                .font(.system(size: 80, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        case .numbers:
            let number = item.value(LearnNumber.self)!
            VStack(spacing: 8) {
                Text("\(number.numeral)")
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                Dots(count: number.numeral)
            }
            .foregroundStyle(.white)
        case .days:
            labeled(item.value(DayOfWeek.self)!.symbol)
        case .months:
            labeled(item.value(MonthOfYear.self)!.symbol)
        case .seasons:
            labeled(item.value(Season.self)!.symbol)
        case .today:
            EmptyView()
        }
    }

    private func symbol(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 72))
            .foregroundStyle(.white)
    }

    private func labeled(_ name: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: name)
                .font(.system(size: 52))
                .frame(height: 60)
            Text(item.name)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .foregroundStyle(.white)
    }
}

/// A pile for "Which has the most?": dots only, so the child compares amounts.
struct PileTile: View {
    let item: QuizItem

    var body: some View {
        Dots(count: item.value(LearnNumber.self)!.numeral, size: 22)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(RoundedRectangle(cornerRadius: 32, style: .continuous).fill(Category.numbers.color))
            .contentShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    }
}

/// Solid dots for a quantity, in rows of five.
struct Dots: View {
    let count: Int
    var size: CGFloat = 16

    var body: some View {
        VStack(spacing: 6) {
            ForEach(Array(stride(from: 0, to: count, by: 5)), id: \.self) { start in
                HStack(spacing: 6) {
                    ForEach(start..<min(start + 5, count), id: \.self) { _ in
                        Circle().frame(width: size, height: size)
                    }
                }
            }
        }
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 20)], spacing: 20) {
        ForEach([Category.days, .colors, .food, .animals, .numbers, .shapes, .alphabet, .weather], id: \.self) { c in
            ChoiceTile(item: c.quizItems[1]).frame(height: 160)
        }
    }
    .padding()
}
