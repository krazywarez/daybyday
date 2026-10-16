//
//  QuizItem.swift
//  DayByDay
//

/// One askable thing in a category, e.g. "Tuesday" in Days.
nonisolated struct QuizItem: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let category: Category
}

nonisolated extension Category {
    /// Categories shown in the home grid. Today is reached from the banner.
    static var gridCases: [Category] {
        allCases.filter { $0 != .today }
    }

    var quizItems: [QuizItem] {
        switch self {
        case .today:     []
        case .days:      items(DayOfWeek.allCases, \.name)
        case .months:    items(MonthOfYear.allCases, \.name)
        case .seasons:   items(Season.allCases, \.name)
        case .numbers:   items(LearnNumber.allCases, \.name)
        case .colors:    items(LearnColor.allCases, \.name)
        case .shapes:    items(LearnShape.allCases, \.name)
        case .animals:   items(LearnAnimal.allCases, \.name)
        case .alphabet:  items(LearnLetter.allCases, \.spokenName)
        case .weather:   items(LearnWeather.allCases, \.name)
        case .bodyParts: items(LearnBodyPart.allCases, \.name)
        case .food:      items(LearnFood.allCases, \.name)
        }
    }

    var key: String {
        switch self {
        case .today:     "today"
        case .days:      "days"
        case .months:    "months"
        case .seasons:   "seasons"
        case .numbers:   "numbers"
        case .colors:    "colors"
        case .shapes:    "shapes"
        case .animals:   "animals"
        case .alphabet:  "alphabet"
        case .weather:   "weather"
        case .bodyParts: "bodyParts"
        case .food:      "food"
        }
    }

    /// The quiz item for one of this category's enum cases.
    func item(_ value: some CaseIterable) -> QuizItem {
        quizItems.first { $0.id == "\(key).\(value)" }!
    }

    private func items<T>(_ cases: [T], _ name: KeyPath<T, String>) -> [QuizItem] {
        cases.map { QuizItem(id: "\(key).\($0)", name: $0[keyPath: name], category: self) }
    }
}

nonisolated extension QuizItem {
    /// The enum case this item was made from, if it is of type `T`.
    func value<T: CaseIterable>(_: T.Type) -> T? {
        T.allCases.first { id == "\(category.key).\($0)" }
    }
}
