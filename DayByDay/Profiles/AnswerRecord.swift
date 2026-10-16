//
//  AnswerRecord.swift
//  DayByDay
//

import Foundation
import SwiftData

/// One answer a child gave to a question.
@Model
final class AnswerRecord {
    var categoryRaw: Int
    var itemID: String
    /// The item the child tapped. Nil for answers recorded before part 2.
    var chosenID: String?
    /// `Game.rawValue`. Nil for answers recorded before part 2.
    var gameRaw: String?
    var isCorrect: Bool
    var timestamp: Date
    var profile: Profile?

    init(categoryRaw: Int, itemID: String, chosenID: String? = nil, gameRaw: String? = nil,
         isCorrect: Bool, timestamp: Date, profile: Profile) {
        self.categoryRaw = categoryRaw
        self.itemID = itemID
        self.chosenID = chosenID
        self.gameRaw = gameRaw
        self.isCorrect = isCorrect
        self.timestamp = timestamp
        self.profile = profile
    }
}
