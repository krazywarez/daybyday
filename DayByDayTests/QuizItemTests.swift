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

struct ItemSetTests {
    static let pinned: [DayByDay.Category: String] = [
        .days: "sunday monday tuesday wednesday thursday friday saturday",
        .months: "january february march april may june july august september october november december",
        .seasons: "spring summer fall winter",
        .numbers: "one two three four five six seven eight nine ten",
        .colors: "red orange yellow green blue purple pink brown black white",
        .shapes: "circle square triangle star heart oval diamond rectangle",
        .animals: "cat dog bird fish rabbit turtle ladybug cow duck sheep pig",
        .alphabet: "a b c d e f g h i j k l m n o p q r s t u v w x y z",
        .weather: "sunny cloudy rainy snowy windy stormy foggy rainbow",
        .bodyParts: "head eyes ears nose mouth hands fingers arms legs feet heart belly",
        .food: "apple banana carrot strawberry grapes lemon broccoli watermelon cherry orange corn pear",
    ]

    /// Answer history is keyed by these IDs; renaming a case orphans it.
    @Test(arguments: DayByDay.Category.gridCases) func idsArePinned(_ c: DayByDay.Category) {
        let names = Self.pinned[c]!.split(separator: " ")
        #expect(c.quizItems.map(\.id) == names.map { "\(c.key).\($0)" })
    }

    @Test func itemAndValueRoundTrip() {
        let cow = DayByDay.Category.animals.item(LearnAnimal.cow)
        #expect(cow.name == "Cow")
        #expect(cow.value(LearnAnimal.self) == .cow)
        #expect(cow.value(LearnFood.self) == nil)
    }

    @Test func flyers() {
        #expect(LearnAnimal.allCases.filter(\.canFly) == [.bird, .ladybug, .duck])
    }

    @Test func vegetables() {
        #expect(LearnFood.allCases.filter { !$0.isFruit } == [.carrot, .broccoli, .corn])
    }

    @Test func roundShapes() {
        #expect(LearnShape.allCases.filter { $0.hasCorners == false } == [.circle, .oval])
        #expect(LearnShape.heart.hasCorners == nil)
    }

    @Test func exampleWordsStartWithTheirLetter() {
        for letter in LearnLetter.allCases where letter != .x {
            #expect(letter.exampleWord.first == letter.spokenName.first, "\(letter)")
        }
    }

    @Test func drawnAnimalsHaveNoSymbol() {
        #expect(LearnAnimal.allCases.filter { $0.symbol == nil } == [.cow, .duck, .sheep, .pig])
    }
}
