//
//  Avatar.swift
//  DayByDay
//

import SwiftUI

/// The animal a child picks to stand for their profile.
enum AvatarAnimal: String, CaseIterable, Identifiable {
    case cat, dog, bird, fish, teddybear, tortoise, ladybug, hare

    var id: String { rawValue }

    var symbol: String { "\(rawValue).fill" }

    var spokenName: String {
        switch self {
        case .cat:      "Cat"
        case .dog:      "Dog"
        case .bird:     "Bird"
        case .fish:     "Fish"
        case .teddybear: "Teddy"
        case .tortoise: "Turtle"
        case .ladybug:  "Ladybug"
        case .hare:     "Bunny"
        }
    }
}

/// The color a child picks for their profile tile.
enum ProfileColor: Int, CaseIterable, Identifiable {
    case red, orange, yellow, green, teal, blue, purple, pink

    var id: Int { rawValue }

    var color: Color {
        switch self {
        case .red:    Color(red: 0.86, green: 0.20, blue: 0.22)
        case .orange: Color(red: 0.84, green: 0.40, blue: 0.08)
        case .yellow: Color(red: 0.95, green: 0.75, blue: 0.15)
        case .green:  Color(red: 0.18, green: 0.56, blue: 0.28)
        case .teal:   Color(red: 0.0, green: 0.53, blue: 0.56)
        case .blue:   Color(red: 0.0, green: 0.42, blue: 0.85)
        case .purple: Color(red: 0.55, green: 0.4, blue: 0.85)
        case .pink:   Color(red: 0.82, green: 0.25, blue: 0.52)
        }
    }

    /// Color for the avatar symbol drawn on `color`.
    var symbolColor: Color {
        self == .yellow ? Color(red: 0.19, green: 0.15, blue: 0.03) : .white
    }
}
