//
//  Sticker.swift
//  DayByDay
//

import Foundation
import SwiftData

/// A finished Today routine: one per child per day, showing that day's weather.
/// Points at its child by id, so the Profile entity stays unchanged.
@Model
final class Sticker {
    var profileID: UUID
    var year: Int
    var month: Int
    var day: Int
    var weatherRaw: Int
    var createdAt: Date

    init(profileID: UUID, year: Int, month: Int, day: Int, weather: LearnWeather, createdAt: Date = .now) {
        self.profileID = profileID
        self.year = year
        self.month = month
        self.day = day
        self.weatherRaw = weather.rawValue
        self.createdAt = createdAt
    }

    var weather: LearnWeather { LearnWeather(rawValue: weatherRaw) ?? .sunny }
}
