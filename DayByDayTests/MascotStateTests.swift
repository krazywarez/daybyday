import Testing
@testable import DayByDay

struct MascotStateTests {
    @Test func eventsMapToMoods() {
        var s = MascotState()
        #expect(s.mood == .idle)
        s.handle(.prompt("Find it!"))
        #expect(s.mood == .asking)
        s.handle(.correct)
        #expect(s.mood == .cheering)
        s.handle(.wrong)
        #expect(s.mood == .puzzled)
        s.handle(.greet)
        #expect(s.mood == .waving)
    }

    @Test func promptHoldCoversDelayAndWords() {
        #expect(abs(MascotState.hold(for: .prompt("Can you find Monday?", after: 1.0)) - 3.3) < 1e-9)
        #expect(MascotState.hold(for: .correct) == 1.8)
        #expect(MascotState.hold(for: .wrong) == 1.6)
        #expect(MascotState.hold(for: .greet) == 2.4)
    }

    @Test func emptyPromptSettles() {
        var s = MascotState()
        s.handle(.prompt(""))
        #expect(s.hold == 0.5)
        s.settle(s.ticket)
        #expect(s.mood == .idle)
    }

    @Test func settleReturnsToIdle() {
        var s = MascotState()
        s.handle(.wrong)
        #expect(s.hold == 1.6)
        s.settle(s.ticket)
        #expect(s.mood == .idle)
    }

    @Test func newerEventWins() {
        var s = MascotState()
        s.handle(.correct)
        let first = s.ticket
        s.handle(.prompt("Can you find Monday?"))
        s.settle(first)
        #expect(s.mood == .asking)
        #expect(s.ticket != first)
    }
}
