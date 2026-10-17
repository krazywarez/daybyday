import Foundation
import Testing
@testable import DayByDay

struct RoutineScriptTests {
    static var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        Self.calendar.date(from: DateComponents(year: y, month: m, day: d, hour: 9))!
    }

    func script(_ y: Int, _ m: Int, _ d: Int, name: String? = "Maya",
                birthday: (month: Int, day: Int)? = nil, picture: DayPictureKind? = nil) -> [String] {
        RoutineScript(date: date(y, m, d), calendar: Self.calendar, name: name,
                      birthday: birthday, picture: picture).lines.map(\.text)
    }

    @Test func fridayScript() {
        #expect(script(2026, 10, 16) == [
            "Hi, Maya!", "Today is Friday.", "Yesterday was Thursday.", "Tomorrow is Saturday.",
            "It's October.", "It's Fall.",
        ])
        #expect(script(2026, 10, 16, name: nil).first == "Hi!")
        let greeting = RoutineScript(date: date(2026, 10, 16), calendar: Self.calendar, name: "Maya",
                                     birthday: nil, picture: nil).lines[0]
        #expect(greeting.spoken == "Hi there!")
        let named = RoutineScript(date: date(2026, 10, 16), calendar: Self.calendar, name: "izzy",
                                  birthday: nil, picture: nil).lines[0]
        #expect(named.text == "Hi, izzy!")
        #expect(named.spoken == "Hi, Izzy!")
        #expect(RoutineScript(date: date(2026, 10, 16), calendar: Self.calendar, name: "Maya",
                              birthday: nil, picture: nil).lines[1].spoken == "Today is Friday.")
        let lines = RoutineScript(date: date(2026, 10, 16), calendar: Self.calendar, name: nil,
                                  birthday: nil, picture: nil).lines
        #expect(lines[1].symbol == DayOfWeek.friday.symbol)
        #expect(lines[4].symbol == MonthOfYear.october.symbol)
        #expect(lines[5].symbol == Season.fall.symbol)
    }

    @Test func birthdayMonthLine() {
        #expect(script(2026, 10, 16, birthday: (month: 10, day: 30))[1] == "Your birthday is in October!")
        #expect(!script(2026, 10, 16, birthday: (month: 5, day: 1)).contains { $0.contains("birthday") })
    }

    @Test func birthdayTodayBeatsMonth() {
        let lines = script(2026, 10, 16, birthday: (month: 10, day: 16))
        #expect(lines[1] == "Today is your birthday! Happy birthday!")
        #expect(!lines.contains("Your birthday is in October!"))
    }

    @Test func leapBirthday() {
        #expect(script(2027, 2, 28, birthday: (month: 2, day: 29))[1] == "Your birthday is in February!")
        #expect(script(2028, 2, 29, birthday: (month: 2, day: 29))[1] == "Today is your birthday! Happy birthday!")
        #expect(!script(2027, 3, 1, birthday: (month: 2, day: 29)).contains { $0.contains("birthday") })
    }

    @Test func pictureLine() {
        let lines = script(2026, 10, 16, picture: .swim)
        #expect(lines[1] == "Today is Friday.")
        #expect(lines[2] == "Today is swim day!")
    }

    @Test func weekWraps() {
        #expect(script(2026, 10, 18).contains("Yesterday was Saturday."))
        #expect(script(2026, 10, 18)[1] == "Today is Sunday.")
        #expect(script(2026, 10, 17).contains("Tomorrow is Sunday."))
    }

    @Test func monthEnd() {
        let lines = script(2026, 10, 31)
        #expect(lines.contains("Tomorrow is Sunday."))
        #expect(lines.contains("It's October."))
    }

    /// Dates are always Gregorian, whatever calendar the device uses.
    @Test func appCalendarIsGregorian() {
        #expect(AppCalendar.current.identifier == .gregorian)
        #expect(AppCalendar.current.firstWeekday == 1)
        #expect(AppCalendar.current.timeZone == .current)
    }

    @Test func yearEnd() {
        let lines = script(2027, 1, 1)
        #expect(lines.contains("It's January."))
        #expect(lines.contains("Yesterday was Thursday."))
        #expect(lines.contains("It's Winter."))
    }
}

struct MonthGridTests {
    let calendar = RoutineScriptTests.calendar

    @Test func octoberGrid() {
        let g = MonthGrid(year: 2026, month: 10, calendar: calendar)
        #expect(g.leadingBlanks == 4)
        #expect(g.days == 31)
        #expect(g.cells.prefix(5) == [nil, nil, nil, nil, 1])
        #expect(g.cells.last == 31)
    }

    @Test func februaryGrids() {
        #expect(MonthGrid(year: 2027, month: 2, calendar: calendar).days == 28)
        #expect(MonthGrid(year: 2028, month: 2, calendar: calendar).days == 29)
    }

    @Test func neverPastCurrentMonth() {
        let today = (year: 2026, month: 10)
        #expect(!MonthGrid(year: 2026, month: 10, calendar: calendar).canGoLater(than: today))
        #expect(MonthGrid(year: 2026, month: 9, calendar: calendar).canGoLater(than: today))
        #expect(MonthGrid(year: 2025, month: 12, calendar: calendar).canGoLater(than: today))
        #expect(!MonthGrid(year: 2027, month: 1, calendar: calendar).canGoLater(than: today))
    }

    @Test func shiftAcrossYear() {
        let jan = MonthGrid(year: 2026, month: 12, calendar: calendar).shifted(by: 1)
        #expect(jan.year == 2027 && jan.month == 1)
        let nov = MonthGrid(year: 2027, month: 1, calendar: calendar).shifted(by: -2)
        #expect(nov.year == 2026 && nov.month == 11)
    }
}
