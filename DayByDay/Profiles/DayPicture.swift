//
//  DayPicture.swift
//  DayByDay
//

import Foundation
import SwiftData

/// Something special a child does on a weekday, set by a grown-up.
nonisolated enum DayPictureKind: String, CaseIterable, Identifiable {
    case swim, school, grandma, park, music, soccer, library, dance

    var id: String { rawValue }

    var name: String { "\(rawValue) day" }

    var symbol: String {
        switch self {
        case .swim:    "figure.pool.swim"
        case .school:  "backpack.fill"
        case .grandma: "house.fill"
        case .park:    "tree.fill"
        case .music:   "music.note"
        case .soccer:  "soccerball"
        case .library: "books.vertical.fill"
        case .dance:   "figure.socialdance"
        }
    }
}

/// A day picture for one child and weekday. Points at its child by id.
@Model
final class DayPicture {
    var profileID: UUID
    var weekdayRaw: Int
    var kindRaw: String

    init(profileID: UUID, weekday: DayOfWeek, kind: DayPictureKind) {
        self.profileID = profileID
        self.weekdayRaw = weekday.rawValue
        self.kindRaw = kind.rawValue
    }

    var kind: DayPictureKind? { DayPictureKind(rawValue: kindRaw) }
}
