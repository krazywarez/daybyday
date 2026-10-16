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
    var isCorrect: Bool
    var timestamp: Date
    var profile: Profile?

    init(categoryRaw: Int, itemID: String, isCorrect: Bool, timestamp: Date, profile: Profile) {
        self.categoryRaw = categoryRaw
        self.itemID = itemID
        self.isCorrect = isCorrect
        self.timestamp = timestamp
        self.profile = profile
    }
}
