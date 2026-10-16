//
//  ProfileStore.swift
//  DayByDay
//

import Foundation
import SwiftData

enum ProfileError: Error, Equatable {
    case blankName
    case invalidBirthday
}

final class ProfileStore {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    static func makeContainer(inMemory: Bool) -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        return try! ModelContainer(for: Profile.self, AnswerRecord.self, configurations: config)
    }

    func all() -> [Profile] {
        let descriptor = FetchDescriptor<Profile>(sortBy: [SortDescriptor(\.createdAt)])
        return (try? context.fetch(descriptor)) ?? []
    }

    @discardableResult
    func create(name: String, avatar: AvatarAnimal, color: ProfileColor, birthday: (month: Int, day: Int)?) throws -> Profile {
        let name = try Self.validName(name)
        try Self.validate(birthday)
        let profile = Profile(name: name, avatar: avatar, color: color,
                              birthdayMonth: birthday?.month, birthdayDay: birthday?.day)
        context.insert(profile)
        try? context.save()
        return profile
    }

    func update(_ profile: Profile, name: String, avatar: AvatarAnimal, color: ProfileColor, birthday: (month: Int, day: Int)?) throws {
        let name = try Self.validName(name)
        try Self.validate(birthday)
        profile.name = name
        profile.avatarRaw = avatar.rawValue
        profile.colorRaw = color.rawValue
        profile.birthdayMonth = birthday?.month
        profile.birthdayDay = birthday?.day
        try? context.save()
    }

    func delete(_ profile: Profile) {
        context.delete(profile)
        try? context.save()
    }

    /// `item` is the question's answer; `chosen` is what the child tapped.
    func record(_ item: QuizItem, chosen: QuizItem? = nil, game: Game? = nil, correct: Bool,
                for profile: Profile, at date: Date = .now) {
        context.insert(AnswerRecord(categoryRaw: item.category.rawValue, itemID: item.id,
                                    chosenID: chosen?.id, gameRaw: game?.rawValue,
                                    isCorrect: correct, timestamp: date, profile: profile))
        try? context.save()
    }

    func answers(for profile: Profile, category: Category?) -> [AnswerRecord] {
        profile.answers
            .filter { category == nil || $0.categoryRaw == category!.rawValue }
            .sorted { $0.timestamp < $1.timestamp }
    }

    /// Days per month in a leap year, so February 29 birthdays are allowed.
    static let daysInMonth = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

    private static func validName(_ name: String) throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ProfileError.blankName }
        return trimmed
    }

    private static func validate(_ birthday: (month: Int, day: Int)?) throws {
        guard let birthday else { return }
        guard (1...12).contains(birthday.month),
              (1...daysInMonth[birthday.month - 1]).contains(birthday.day)
        else { throw ProfileError.invalidBirthday }
    }
}
