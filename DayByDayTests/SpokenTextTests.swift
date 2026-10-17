import Testing
@testable import DayByDay

struct SpokenTextTests {
    @Test func splitsSentences() {
        #expect(SpokenText.sentences("That's Thursday! Try again.") == ["That's Thursday!", "Try again."])
        #expect(SpokenText.sentences("On October 3, it was sunny.") == ["On October 3, it was sunny."])
        #expect(SpokenText.sentences("b. b is for ball.") == ["b.", "b is for ball."])
        #expect(SpokenText.sentences("Monday") == ["Monday"])
        #expect(SpokenText.sentences("Great job! An apple is a fruit. Is the banana a fruit or a vegetable?")
                == ["Great job!", "An apple is a fruit.", "Is the banana a fruit or a vegetable?"])
    }

    @Test func trimsAndDropsEmpty() {
        #expect(SpokenText.sentences("  Super!  ") == ["Super!"])
        #expect(SpokenText.sentences("Great job! ") == ["Great job!"])
        #expect(SpokenText.sentences("") == [])
    }

    @Test func greetingNamesOnlyListedNames() {
        #expect(Lines.greeting(for: "Maya") == "Hi there!")
        #expect(Lines.greeting(for: nil) == "Hi there!")
        #expect(Lines.greeting(for: "Sammy B") == "Hi there!")
        #expect(Lines.greeting(for: " gianna ") == "Hi, Gianna!")
        #expect(Lines.greeting(for: "THADEUS") == "Hi, Thadeus!")
        #expect(Lines.greeting(for: "Ollie") == "Hi, Ollie!")
    }
}

struct CalendarDayLineTests {
    @Test func datesSayTheirEnding() {
        #expect(Lines.calendarDay(.october, 9, weather: nil) == "October 9th.")
        #expect(Lines.calendarDay(.october, 3, weather: .sunny) == "On October 3rd, it was sunny.")
        let endings = [1: "1st", 2: "2nd", 3: "3rd", 4: "4th", 11: "11th", 12: "12th", 13: "13th",
                       21: "21st", 22: "22nd", 23: "23rd", 24: "24th", 30: "30th", 31: "31st"]
        for (day, text) in endings {
            #expect(Lines.ordinal(day) == text, "\(day)")
        }
    }
}
