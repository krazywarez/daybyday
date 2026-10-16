//
//  AvatarBadge.swift
//  DayByDay
//

import SwiftUI

/// A child's avatar animal on their color.
struct AvatarBadge: View {
    let avatar: AvatarAnimal
    let color: ProfileColor

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle().fill(color.color)
                Image(systemName: avatar.symbol)
                    .font(.system(size: geo.size.width * 0.5))
                    .foregroundStyle(color.symbolColor)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}
