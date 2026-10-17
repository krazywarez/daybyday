//
//  TodayBanner.swift
//  DayByDay
//

import SwiftUI

/// The mascot and today's day and date, at the top of home.
struct TodayBanner: View {
    @Environment(ProfileSession.self) private var session
    /// Today's sticker, read when home appears.
    @State private var sticker: LearnWeather?

    static let gradientColors: [Color] = [Color(red: 0.84, green: 0.40, blue: 0.05), Color(red: 0.80, green: 0.45, blue: 0.0)]

    var body: some View {
        HStack(spacing: 20) {
            // On white: the orange is too close to the owl's purple.
            MascotView(mood: .idle)
                .padding(8)
                .frame(width: 96, height: 96)
                .background(Circle().fill(.white))
            VStack(alignment: .leading, spacing: 6) {
                Text("Today is \(DayOfWeek.current.name)!")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                Text(Date.now.formatted(.dateTime.month(.wide).day()))
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .opacity(0.9)
                if let sticker {
                    StickerBadge(weather: sticker).frame(width: 56, height: 56)
                } else {
                    Text("Tap for your sticker!")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
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
        .onAppear {
            let today = AppCalendar.current.dateComponents([.year, .month, .day], from: .now)
            sticker = session.current.flatMap { session.store.sticker(for: $0, on: today)?.weather }
        }
    }
}
