import Testing
@testable import DayByDay

struct QuizItemTests {
    @Test func everyGridCategoryHasItems() {
        for category in Category.gridCases {
            #expect(!category.quizItems.isEmpty)
        }
    }

    @Test func gridExcludesToday() {
        #expect(!Category.gridCases.contains(.today))
        #expect(Category.gridCases.count == 11)
    }

    @Test func idsAreUniqueAndStable() {
        let all = Category.gridCases.flatMap(\.quizItems)
        #expect(Set(all.map(\.id)).count == all.count)
        #expect(Category.days.quizItems[2] == QuizItem(id: "days.tuesday", name: "Tuesday", category: .days))
    }

    @Test func lettersUseSpokenName() {
        #expect(Category.alphabet.quizItems.first?.name == "a")
    }
}
