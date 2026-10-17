import Foundation
import SwiftData
import Testing
import UIKit
@testable import DayByDay

struct StickerStoreTests {
    let container = ProfileStore.makeContainer(inMemory: true)
    var store: ProfileStore { ProfileStore(context: container.mainContext) }

    func day(_ y: Int, _ m: Int, _ d: Int) -> DateComponents { DateComponents(year: y, month: m, day: d) }

    @Test func stickerUpsertsPerDay() throws {
        let s = store
        let maya = try s.create(name: "Maya", avatar: .cat, color: .red, birthday: nil)
        s.addSticker(for: maya, on: day(2026, 10, 16), weather: .sunny)
        s.addSticker(for: maya, on: day(2026, 10, 16), weather: .rainy)
        let stickers = s.stickers(for: maya, year: 2026, month: 10)
        #expect(stickers.count == 1)
        #expect(stickers.first?.weatherRaw == LearnWeather.rainy.rawValue)
        #expect(s.sticker(for: maya, on: day(2026, 10, 16)) != nil)
        #expect(s.sticker(for: maya, on: day(2026, 10, 17)) == nil)
    }

    @Test func stickersByMonth() throws {
        let s = store
        let maya = try s.create(name: "Maya", avatar: .cat, color: .red, birthday: nil)
        s.addSticker(for: maya, on: day(2026, 9, 30), weather: .sunny)
        s.addSticker(for: maya, on: day(2026, 10, 1), weather: .cloudy)
        s.addSticker(for: maya, on: day(2026, 10, 2), weather: .windy)
        #expect(s.stickers(for: maya, year: 2026, month: 10).map(\.day).sorted() == [1, 2])
        #expect(s.stickers(for: maya, year: 2025, month: 10).isEmpty)
    }

    @Test func picturesSetReplaceRemove() throws {
        let s = store
        let maya = try s.create(name: "Maya", avatar: .cat, color: .red, birthday: nil)
        s.setPicture(.swim, on: .monday, for: maya)
        #expect(s.picture(on: .monday, for: maya) == .swim)
        s.setPicture(.school, on: .monday, for: maya)
        #expect(s.picture(on: .monday, for: maya) == .school)
        s.setPicture(nil, on: .monday, for: maya)
        #expect(s.picture(on: .monday, for: maya) == nil)
        #expect(try container.mainContext.fetch(FetchDescriptor<DayPicture>()).isEmpty)
    }

    @Test func deleteRemovesOnlyThatChildsData() throws {
        let s = store
        let maya = try s.create(name: "Maya", avatar: .cat, color: .red, birthday: nil)
        let sam = try s.create(name: "Sam", avatar: .dog, color: .blue, birthday: nil)
        for p in [maya, sam] {
            s.addSticker(for: p, on: day(2026, 10, 16), weather: .sunny)
            s.setPicture(.park, on: .friday, for: p)
        }
        s.delete(maya)
        #expect(try container.mainContext.fetch(FetchDescriptor<Sticker>()).count == 1)
        #expect(try container.mainContext.fetch(FetchDescriptor<DayPicture>()).count == 1)
        #expect(s.picture(on: .friday, for: sam) == .park)
    }

    @Test(arguments: DayPictureKind.allCases) func pictureSymbolsExist(_ kind: DayPictureKind) {
        #expect(UIImage(systemName: kind.symbol) != nil, "\(kind.symbol)")
        #expect(kind.name.hasSuffix(" day"))
    }

    /// A store written before stickers existed opens with the new schema and keeps its data.
    @Test func oldStoreOpens() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("old-\(UUID().uuidString).store")
        do {
            let old = try ModelContainer(for: Profile.self, AnswerRecord.self,
                                         configurations: ModelConfiguration(url: url))
            let s = ProfileStore(context: old.mainContext)
            let maya = try s.create(name: "Maya", avatar: .cat, color: .red, birthday: (month: 5, day: 1))
            s.record(DayByDay.Category.days.quizItems[0], correct: true, for: maya)
        }
        let new = try ModelContainer(for: Schema(ProfileStore.modelTypes),
                                     configurations: ModelConfiguration(url: url))
        let profiles = try new.mainContext.fetch(FetchDescriptor<Profile>())
        #expect(profiles.map(\.name) == ["Maya"])
        #expect(profiles.first?.answers.count == 1)
        let s = ProfileStore(context: new.mainContext)
        s.addSticker(for: profiles[0], on: day(2026, 10, 16), weather: .snowy)
        #expect(s.stickers(for: profiles[0], year: 2026, month: 10).count == 1)
    }
}
