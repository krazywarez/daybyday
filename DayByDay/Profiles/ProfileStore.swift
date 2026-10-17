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

    /// Stickers and day pictures were added after the first release as new
    /// entities only, so earlier stores migrate without a versioned schema.
    static let modelTypes: [any PersistentModel.Type] = [Profile.self, AnswerRecord.self, Sticker.self, DayPicture.self]

    static func makeContainer(inMemory: Bool) -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        return try! ModelContainer(for: Schema(modelTypes), configurations: config)
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
        let id = profile.id
        try? context.delete(model: Sticker.self, where: #Predicate { $0.profileID == id })
        try? context.delete(model: DayPicture.self, where: #Predicate { $0.profileID == id })
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

    /// Games where an answer shows whether the child recognizes the item.
    /// Tracing, sorting, ordering and comparing are left out. Answers with
    /// no game were recorded before part 2 and are kept.
    static let recognitionGames: Set<String> = Set([Game.findIt, .listen, .oddOneOut, .comesNext, .whichSeason].map(\.rawValue))

    func progress(for profile: Profile, category: Category) -> ItemProgress {
        ItemProgress(answers(for: profile, category: category)
            .filter { $0.gameRaw.map(Self.recognitionGames.contains) ?? true }
            .map { AnswerFact(itemID: $0.itemID, isCorrect: $0.isCorrect, timestamp: $0.timestamp) })
    }

    /// Pick weights for the topic's items the child is missing; the rest
    /// weigh 1. Empty when nothing is being missed.
    func reviewWeights(for profile: Profile, category: Category) -> [QuizItem: Double] {
        let progress = progress(for: profile, category: category)
        return Dictionary(uniqueKeysWithValues: category.quizItems.compactMap { item in
            let weight = progress.weight(item.id)
            return weight > 1 ? (item, weight) : nil
        })
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

    // MARK: - Stickers

    /// Adds the day's sticker, or changes its weather if there is one.
    func addSticker(for profile: Profile, on date: DateComponents, weather: LearnWeather) {
        if let existing = sticker(for: profile, on: date) {
            existing.weatherRaw = weather.rawValue
        } else {
            context.insert(Sticker(profileID: profile.id, year: date.year!, month: date.month!,
                                   day: date.day!, weather: weather))
        }
        try? context.save()
    }

    func sticker(for profile: Profile, on date: DateComponents) -> Sticker? {
        let id = profile.id, y = date.year!, m = date.month!, d = date.day!
        let descriptor = FetchDescriptor<Sticker>(predicate: #Predicate {
            $0.profileID == id && $0.year == y && $0.month == m && $0.day == d
        })
        return try? context.fetch(descriptor).first
    }

    func stickers(for profile: Profile, year: Int, month: Int) -> [Sticker] {
        let id = profile.id
        let descriptor = FetchDescriptor<Sticker>(predicate: #Predicate {
            $0.profileID == id && $0.year == year && $0.month == month
        }, sortBy: [SortDescriptor(\.day)])
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Day pictures

    /// Sets or, with nil, removes the child's picture for a weekday.
    func setPicture(_ kind: DayPictureKind?, on weekday: DayOfWeek, for profile: Profile) {
        let id = profile.id, w = weekday.rawValue
        try? context.delete(model: DayPicture.self, where: #Predicate { $0.profileID == id && $0.weekdayRaw == w })
        if let kind { context.insert(DayPicture(profileID: id, weekday: weekday, kind: kind)) }
        try? context.save()
    }

    func picture(on weekday: DayOfWeek, for profile: Profile) -> DayPictureKind? {
        let id = profile.id, w = weekday.rawValue
        let descriptor = FetchDescriptor<DayPicture>(predicate: #Predicate { $0.profileID == id && $0.weekdayRaw == w })
        return (try? context.fetch(descriptor).first)?.kind
    }
}
