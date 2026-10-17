//
//  StickerCalendarView.swift
//  DayByDay
//

import SwiftUI

enum StickerStyle {
    /// White weather symbols sit on this, at least 3:1.
    static let fill = Category.weather.color
}

/// A sticker in the weather of that day.
struct StickerBadge: View {
    let weather: LearnWeather

    var body: some View {
        Circle()
            .fill(StickerStyle.fill)
            .overlay {
                Image(systemName: weather.symbol)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .padding(5)
            }
            .accessibilityLabel(weather.name)
    }
}

/// One month of a child's stickers. Arrows go back through earlier months,
/// never past the current one.
struct StickerCalendarView: View {
    let profile: Profile?

    @Environment(ProfileSession.self) private var session
    @State private var grid: MonthGrid
    private let today: DateComponents
    private let calendar: Calendar

    init(profile: Profile?, calendar: Calendar = AppCalendar.current, now: Date = .now) {
        self.profile = profile
        self.calendar = calendar
        today = calendar.dateComponents([.year, .month, .day], from: now)
        _grid = State(initialValue: MonthGrid(year: today.year!, month: today.month!, calendar: calendar))
    }

    private var isCurrentMonth: Bool { grid.year == today.year && grid.month == today.month }
    private var canGoLater: Bool { grid.canGoLater(than: (year: today.year!, month: today.month!)) }
    private var monthName: String { MonthOfYear(rawValue: grid.month - 1)!.name }

    private var stickers: [Int: Sticker] {
        guard let profile else { return [:] }
        return Dictionary(session.store.stickers(for: profile, year: grid.year, month: grid.month).map { ($0.day, $0) },
                          uniquingKeysWith: { a, _ in a })
    }

    var body: some View {
        let stickers = self.stickers
        VStack(spacing: 16) {
            HStack {
                arrow("chevron.left", label: "Earlier month") { grid = grid.shifted(by: -1) }
                Spacer()
                Text(verbatim: "\(monthName) \(grid.year)")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                Spacer()
                arrow("chevron.right", label: "Later month") { grid = grid.shifted(by: 1) }
                    .disabled(!canGoLater)
                    .opacity(canGoLater ? 1 : 0.3)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { _, d in
                    Text(d).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(.primary)
                }
                ForEach(Array(grid.cells.enumerated()), id: \.offset) { _, day in
                    if let day {
                        cell(day, sticker: stickers[day])
                    } else {
                        Color.clear.frame(height: 48)
                    }
                }
            }
        }
        .padding(16)
    }

    private func cell(_ day: Int, sticker: Sticker?) -> some View {
        let isToday = isCurrentMonth && day == today.day
        return ZStack {
            if let sticker {
                StickerBadge(weather: sticker.weather)
                    .padding(isToday ? 5 : 0)
                    .overlay(alignment: .bottomTrailing) {
                        // Keep the date readable on a stickered day.
                        Text("\(day)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .padding(3)
                            .background(Circle().fill(Color(.systemBackground)))
                    }
            } else {
                Text("\(day)").font(.system(size: 18, weight: .semibold, design: .rounded))
            }
        }
        .frame(height: 48)
        .frame(maxWidth: .infinity)
        .overlay {
            if isToday {
                Circle().strokeBorder(Color.primary, lineWidth: 4).frame(width: 52, height: 52)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            let line = sticker.map { "On \(monthName) \(day), it was \($0.weather.name.lowercased())." }
                ?? "\(monthName) \(day)."
            CardVoice.shared.say(line, after: nil)
        }
        .accessibilityLabel(sticker.map { "\(monthName) \(day), \($0.weather.name)" } ?? "\(monthName) \(day)")
    }

    private func arrow(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 26, weight: .bold))
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color(.systemGray6)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
