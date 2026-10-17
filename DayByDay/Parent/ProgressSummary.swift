//
//  ProgressSummary.swift
//  DayByDay
//

nonisolated extension Category {
    /// "Knows 5 of 7 days."
    var progressNoun: String {
        switch self {
        case .today, .days: "days"
        case .months:    "months"
        case .seasons:   "seasons"
        case .numbers:   "numbers"
        case .colors:    "colors"
        case .shapes:    "shapes"
        case .animals:   "animals"
        case .alphabet:  "letters"
        case .weather:   "kinds of weather"
        case .bodyParts: "body parts"
        case .food:      "foods"
        }
    }
}

/// One child's progress in one topic, in plain words for a parent.
nonisolated struct ProgressSummary {
    static let listLimit = 4

    let known: String?
    let missing: String?

    init(category: Category, progress: ItemProgress) {
        let items = category.quizItems
        guard items.contains(where: { progress.statuses[$0.id] != nil }) else {
            known = "Not played yet."
            missing = nil
            return
        }
        let knownCount = items.filter { progress.status($0.id) == .known }.count
        let noun = category.progressNoun
        let knownLine: String? = switch knownCount {
        case items.count: "Knows all \(items.count) \(noun)."
        case 0: nil
        default: "Knows \(knownCount) of \(items.count) \(noun)."
        }
        // Letter items are named lowercase for speech; parents read capitals.
        let learning = items.filter { progress.status($0.id) == .learning }
            .map { category == .alphabet ? $0.name.uppercased() : $0.name }
        missing = learning.isEmpty ? nil : "Still mixing up \(Self.list(learning))."
        known = knownLine ?? (missing == nil ? "Just started." : nil)
    }

    /// "A", "A and B", "A, B and C", "A, B, C, D and 2 more".
    static func list(_ names: [String]) -> String {
        if names.count > listLimit {
            return names.prefix(listLimit).joined(separator: ", ") + " and \(names.count - listLimit) more"
        }
        guard names.count > 1 else { return names.first ?? "" }
        return names.dropLast().joined(separator: ", ") + " and " + names.last!
    }
}
