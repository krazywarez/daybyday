//
//  ScreenshotScene.swift
//  DayByDay
//

#if DEBUG
import SwiftUI

/// App Store screens, opened by `scripts/take-screenshots.sh` with
/// `-screenshot <name>`. The app then runs on an in-memory store seeded with
/// one demo child. `setup` (no children) and `picker` (two children, none
/// picked) are for the UI tests.
enum ScreenshotScene: String, CaseIterable {
    case home, routine, animals, train, trace, counting, calendar, progress
    case setup, picker

    static var requested: ScreenshotScene? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-screenshot"), i + 1 < args.count else { return nil }
        return ScreenshotScene(rawValue: args[i + 1])
    }

    @ViewBuilder @MainActor
    func view(_ session: ProfileSession) -> some View {
        switch self {
        case .home, .setup, .picker:
            ContentView()
        case .routine:
            NavigationStack { TodayRoutineView().navigationTitle(Category.today.label) }
        case .animals:
            NavigationStack { Category.animals.lookAndListenView.navigationTitle(Category.animals.label) }
        case .train:
            NavigationStack {
                SequencePuzzleView(game: .weekTrain) {
                    var rng = SystemRandomNumberGenerator()
                    var train = SequencePuzzle.weekTrain(using: &rng)
                    _ = train.place(Category.days.item(DayOfWeek.sunday))
                    return train
                }
                .navigationTitle(Game.weekTrain.title)
            }
        case .trace:
            NavigationStack { GameDestination(category: .alphabet, game: .trace) }
        case .counting:
            NavigationStack { GameDestination(category: .numbers, game: .counting) }
        case .calendar:
            NavigationStack {
                ScrollView { StickerCalendarView(profile: session.current).frame(maxWidth: 560).padding() }
                    .navigationTitle("Stickers")
            }
        case .progress:
            NavigationStack {
                if let profile = session.current { ChildProgressView(profile: profile) }
            }
        }
    }

    /// One child with a birthday this month, a day picture today, stickers on
    /// earlier days this month, and answers that leave a few months to practice.
    @MainActor
    static func seed(_ session: ProfileSession, calendar: Calendar = AppCalendar.current, now: Date = .now) {
        switch requested {
        case .setup:
            return
        case .picker:
            _ = try? session.store.create(name: "Olive", avatar: .hare, color: .teal, birthday: nil)
            _ = try? session.store.create(name: "Max", avatar: .dog, color: .blue, birthday: nil)
            session.profilesChanged()
            return
        default:
            break
        }
        let today = calendar.dateComponents([.year, .month, .day], from: now)
        guard let olive = try? session.store.create(name: "Olive", avatar: .hare, color: .teal,
                                                    birthday: (month: today.month!, day: today.day! == 28 ? 27 : 28)) else { return }
        session.store.setPicture(.swim, on: .current, for: olive)
        let weathers: [LearnWeather] = [.sunny, .cloudy, .rainy, .sunny, .windy, .snowy, .sunny]
        for (i, day) in (1..<today.day!).reversed().prefix(10).enumerated() {
            session.store.addSticker(for: olive, on: DateComponents(year: today.year, month: today.month, day: day),
                                     weather: weathers[i % weathers.count])
        }
        let days = Category.days.quizItems, months = Category.months.quizItems
        let t = now.addingTimeInterval(-86_400)
        for (i, day) in days.enumerated() {
            session.store.record(day, correct: true, for: olive, at: t + Double(i) * 300)
            session.store.record(day, correct: true, for: olive, at: t + 5000 + Double(i) * 300)
        }
        for (i, month) in months.enumerated() where i < 5 {
            session.store.record(month, correct: true, for: olive, at: t + Double(i) * 300)
            session.store.record(month, correct: true, for: olive, at: t + 5000 + Double(i) * 300)
        }
        for month in months[5...7] { session.store.record(month, correct: false, for: olive, at: t + 9000) }
        for category in [Category.numbers, .colors, .shapes, .seasons] {
            for (i, item) in category.quizItems.enumerated() {
                session.store.record(item, correct: true, for: olive, at: t + Double(i) * 60)
                session.store.record(item, correct: true, for: olive, at: t + 5000 + Double(i) * 60)
            }
        }
        session.store.record(Category.shapes.quizItems[0], correct: false, for: olive, at: t + 9000)
        session.profilesChanged()
        session.select(olive)
    }
}
#endif
