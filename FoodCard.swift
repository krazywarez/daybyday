//
//  FoodCard.swift
//  DayByDay
//

import SwiftUI

/// A single large, colorful card representing one fruit or vegetable.
/// Tapping the card plays a bounce animation and speaks the food name aloud.
/// Each food displays its emoji at large size for instant recognition.
struct FoodCard: View {
    let food: LearnFood
    @State private var isTapped = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(food.color)
                .shadow(color: food.color.opacity(0.4), radius: 8, y: 4)

            VStack(spacing: 16) {
                Text(food.emoji)
                    .font(.system(size: 72))

                Text(food.name)
                    .font(.heading(28))
                    .foregroundStyle(.white)
            }
            .padding(16)
        }
        .scaleEffect(isTapped ? 1.12 : 1.0)
        .contentShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .rotation3DEffect(.degrees(isTapped ? 6 : 0), axis: (x: 1, y: 0, z: 0))
        .animation(.spring(response: 0.35, dampingFraction: 0.5), value: isTapped)
        .onTapGesture {
            isTapped = true
            SpeechSynthesizer.shared.speak(food.name)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isTapped = false
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(food.name)
        .accessibilityAddTraits(.isButton)
    }

}

// MARK: - Food model

nonisolated enum LearnFood: Int, CaseIterable, Identifiable {
    case apple, banana, carrot, strawberry, grapes, lemon,
         broccoli, watermelon, cherry, orange, corn, pear

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .apple:      "Apple"
        case .banana:     "Banana"
        case .carrot:     "Carrot"
        case .strawberry: "Strawberry"
        case .grapes:     "Grapes"
        case .lemon:      "Lemon"
        case .broccoli:   "Broccoli"
        case .watermelon: "Watermelon"
        case .cherry:     "Cherry"
        case .orange:     "Orange"
        case .corn:       "Corn"
        case .pear:       "Pear"
        }
    }

    var isFruit: Bool {
        switch self {
        case .carrot, .broccoli, .corn: false
        default: true
        }
    }

    var emoji: String {
        switch self {
        case .apple:      "🍎"
        case .banana:     "🍌"
        case .carrot:     "🥕"
        case .strawberry: "🍓"
        case .grapes:     "🍇"
        case .lemon:      "🍋"
        case .broccoli:   "🥦"
        case .watermelon: "🍉"
        case .cherry:     "🍒"
        case .orange:     "🍊"
        case .corn:       "🌽"
        case .pear:       "🍐"
        }
    }

    var color: Color {
        switch self {
        case .apple:      Color(red: 0.85, green: 0.2, blue: 0.2)    // red
        case .banana:     Color(red: 0.64, green: 0.54, blue: 0.14)    // yellow
        case .carrot:     Color(red: 0.83, green: 0.45, blue: 0.12)   // orange
        case .strawberry: Color(red: 0.9, green: 0.25, blue: 0.3)    // strawberry red
        case .grapes:     Color(red: 0.55, green: 0.3, blue: 0.7)    // purple
        case .lemon:      Color(red: 0.62, green: 0.55, blue: 0.14)     // lemon yellow
        case .broccoli:   Color(red: 0.29, green: 0.62, blue: 0.29)    // green
        case .watermelon: Color(red: 0.31, green: 0.61, blue: 0.36)    // watermelon green
        case .cherry:     Color(red: 0.7, green: 0.15, blue: 0.2)    // dark red
        case .orange:     Color(red: 0.79, green: 0.47, blue: 0.12)    // orange
        case .corn:       Color(red: 0.65, green: 0.54, blue: 0.15)    // golden yellow
        case .pear:       Color(red: 0.45, green: 0.6, blue: 0.24)   // pear green
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        FoodCard(food: .apple)
            .frame(width: 200, height: 260)
        FoodCard(food: .carrot)
            .frame(width: 200, height: 260)
    }
    .padding()
}
