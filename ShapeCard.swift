//
//  ShapeCard.swift
//  DayByDay
//

import SwiftUI

/// A single large, colorful card representing one shape.
/// Tapping the card plays a bounce animation and speaks the shape name aloud.
struct ShapeCard: View {
    let shape: LearnShape
    @State private var isTapped = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(shape.color.gradient)
                .shadow(color: shape.color.opacity(0.4), radius: 8, y: 4)

            VStack(spacing: 16) {
                shape.shapeView
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.white)

                Text(shape.name)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .scaleEffect(isTapped ? 1.12 : 1.0)
        .contentShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .rotation3DEffect(.degrees(isTapped ? 6 : 0), axis: (x: 1, y: 0, z: 0))
        .animation(.spring(response: 0.35, dampingFraction: 0.5), value: isTapped)
        .onTapGesture {
            isTapped = true
            SpeechSynthesizer.shared.speak(shape.name)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isTapped = false
            }
        }
        .accessibilityLabel(shape.name)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Shape model

enum LearnShape: Int, CaseIterable, Identifiable {
    case circle, square, triangle, star, heart, oval, diamond, rectangle

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .circle:    "Circle"
        case .square:    "Square"
        case .triangle:  "Triangle"
        case .star:      "Star"
        case .heart:     "Heart"
        case .oval:      "Oval"
        case .diamond:   "Diamond"
        case .rectangle: "Rectangle"
        }
    }

    @ViewBuilder
    var shapeView: some View {
        switch self {
        case .circle:
            Circle().fill(.white)
        case .square:
            SwiftUI.Rectangle().fill(.white)
        case .triangle:
            TriangleShape().fill(.white)
        case .star:
            Image(systemName: "star.fill")
                .font(.system(size: 72))
                .foregroundStyle(.white)
        case .heart:
            Image(systemName: "heart.fill")
                .font(.system(size: 72))
                .foregroundStyle(.white)
        case .oval:
            Ellipse().fill(.white)
                .frame(width: 90, height: 60)
        case .diamond:
            SwiftUI.Rectangle().fill(.white)
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(45))
        case .rectangle:
            SwiftUI.Rectangle().fill(.white)
                .frame(width: 90, height: 55)
        }
    }

    var color: Color {
        switch self {
        case .circle:    Color(red: 0.9, green: 0.3, blue: 0.3)   // red
        case .square:    Color(red: 0.3, green: 0.5, blue: 0.9)   // blue
        case .triangle:  Color(red: 0.35, green: 0.75, blue: 0.45) // green
        case .star:      Color(red: 1.0, green: 0.75, blue: 0.15)  // gold
        case .heart:     Color(red: 0.9, green: 0.35, blue: 0.5)   // pink
        case .oval:      Color(red: 0.55, green: 0.4, blue: 0.85)  // purple
        case .diamond:   Color(red: 0.2, green: 0.75, blue: 0.8)   // teal
        case .rectangle: Color(red: 1.0, green: 0.55, blue: 0.2)   // orange
        }
    }
}

/// A simple triangle drawn with a Path.
struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        ShapeCard(shape: .triangle)
            .frame(width: 200, height: 260)
        ShapeCard(shape: .star)
            .frame(width: 200, height: 260)
    }
    .padding()
}
