//
//  TodayBanner.swift
//  DayByDay
//

import SwiftUI

/// The mascot and today's day and date, at the top of home.
struct TodayBanner: View {
    static let gradientColors: [Color] = [Color(red: 0.84, green: 0.40, blue: 0.05), Color(red: 0.80, green: 0.45, blue: 0.0)]

    var body: some View {
        HStack(spacing: 20) {
            MascotView(mood: .idle)
                .frame(width: 96, height: 96)
            VStack(alignment: .leading, spacing: 6) {
                Text("Today is \(DayOfWeek.current.name)!")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                Text(Date.now.formatted(.dateTime.month(.wide).day()))
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .opacity(0.9)
            }
            .foregroundStyle(.white)
            Spacer(minLength: 0)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(LinearGradient(colors: Self.gradientColors,
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: Self.gradientColors[0].opacity(0.4), radius: 8, y: 4)
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}
