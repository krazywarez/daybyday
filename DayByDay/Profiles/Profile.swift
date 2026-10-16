//
//  Profile.swift
//  DayByDay
//

import Foundation
import SwiftData

@Model
final class Profile {
    var id: UUID
    var name: String
    var avatarRaw: String
    var colorRaw: Int
    var birthdayMonth: Int?
    var birthdayDay: Int?
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \AnswerRecord.profile)
    var answers: [AnswerRecord] = []

    init(name: String, avatar: AvatarAnimal, color: ProfileColor, birthdayMonth: Int?, birthdayDay: Int?, createdAt: Date = .now) {
        self.id = UUID()
        self.name = name
        self.avatarRaw = avatar.rawValue
        self.colorRaw = color.rawValue
        self.birthdayMonth = birthdayMonth
        self.birthdayDay = birthdayDay
        self.createdAt = createdAt
    }

    var avatar: AvatarAnimal { AvatarAnimal(rawValue: avatarRaw) ?? .cat }
    var color: ProfileColor { ProfileColor(rawValue: colorRaw) ?? .blue }
}
