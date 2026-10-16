import Foundation
import SwiftData
import Testing
@testable import DayByDay

struct ProfileStoreTests {
    let container = ProfileStore.makeContainer(inMemory: true)
    var store: ProfileStore { ProfileStore(context: container.mainContext) }

    @Test func createTrimsName() throws {
        let p = try store.create(name: "  Maya ", avatar: .cat, color: .blue, birthday: nil)
        #expect(p.name == "Maya")
        #expect(p.avatar == .cat)
        #expect(p.color == .blue)
    }

    @Test func blankNameThrows() {
        #expect(throws: ProfileError.blankName) {
            try store.create(name: "   ", avatar: .dog, color: .red, birthday: nil)
        }
    }

    @Test func birthdayValidation() throws {
        let p = try store.create(name: "Leap", avatar: .dog, color: .red, birthday: (month: 2, day: 29))
        #expect(p.birthdayMonth == 2 && p.birthdayDay == 29)
        for bad in [(2, 30), (4, 31), (13, 1), (0, 5), (5, 0)] {
            #expect(throws: ProfileError.invalidBirthday) {
                try store.create(name: "X", avatar: .dog, color: .red, birthday: (month: bad.0, day: bad.1))
            }
        }
    }

    @Test func allSortedByCreation() throws {
        let s = store
        let a = try s.create(name: "A", avatar: .cat, color: .red, birthday: nil)
        let b = try s.create(name: "B", avatar: .dog, color: .blue, birthday: nil)
        #expect(s.all().map(\.id) == [a.id, b.id])
    }

    @Test func updateValidates() throws {
        let s = store
        let p = try s.create(name: "Maya", avatar: .cat, color: .red, birthday: nil)
        try s.update(p, name: " Mae ", avatar: .bird, color: .green, birthday: (month: 5, day: 1))
        #expect(p.name == "Mae" && p.avatar == .bird && p.birthdayMonth == 5)
        #expect(throws: ProfileError.blankName) {
            try s.update(p, name: "", avatar: .bird, color: .green, birthday: nil)
        }
    }

    @Test func recordsAnswersPerProfile() throws {
        let s = store
        let maya = try s.create(name: "Maya", avatar: .cat, color: .red, birthday: nil)
        let sam = try s.create(name: "Sam", avatar: .dog, color: .blue, birthday: nil)
        s.record(Category.days.quizItems[0], correct: true, for: maya)
        s.record(Category.months.quizItems[0], correct: false, for: maya)
        s.record(Category.days.quizItems[1], correct: true, for: sam)
        #expect(s.answers(for: maya, category: .days).count == 1)
        #expect(s.answers(for: maya, category: nil).count == 2)
        #expect(s.answers(for: sam, category: nil).first?.itemID == "days.monday")
    }

    @Test func deletingProfileDeletesAnswers() throws {
        let s = store
        let maya = try s.create(name: "Maya", avatar: .cat, color: .red, birthday: nil)
        let sam = try s.create(name: "Sam", avatar: .dog, color: .blue, birthday: nil)
        s.record(Category.days.quizItems[0], correct: true, for: maya)
        s.record(Category.days.quizItems[1], correct: true, for: sam)
        s.delete(maya)
        let remaining = try container.mainContext.fetch(FetchDescriptor<AnswerRecord>())
        #expect(remaining.count == 1)
        #expect(s.all().map(\.name) == ["Sam"])
    }
}
