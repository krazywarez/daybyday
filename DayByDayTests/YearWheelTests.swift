import Foundation
import Testing
@testable import DayByDay

struct YearWheelTests {
    @Test func monthAtRotation() {
        #expect(YearWheel.month(atRotation: 0) == .january)
        #expect(YearWheel.month(atRotation: 30) == .december)
        #expect(YearWheel.month(atRotation: -30) == .february)
        #expect(YearWheel.month(atRotation: 360 * 7 + 30) == .december)
        #expect(YearWheel.month(atRotation: -360 * 5 - 60) == .march)
        // Within half a wedge of a center still counts as that month.
        #expect(YearWheel.month(atRotation: 14) == .january)
        #expect(YearWheel.month(atRotation: 16) == .december)
    }

    @Test(arguments: MonthOfYear.allCases) func targetLandsOnMonth(_ m: MonthOfYear) {
        for rotation in [0, 47.5, -800, 12345] {
            let t = YearWheel.target(from: rotation, landingOn: m, turns: 3)
            #expect(t >= rotation + 1080)
            #expect(t < rotation + 1080 + 360)
            #expect(YearWheel.month(atRotation: t) == m)
            #expect(abs(t / 30 - (t / 30).rounded()) < 1e-9)
        }
    }

    @Test func landingLine() {
        #expect(YearWheel.line(for: .july) == "July! July is in summer.")
        #expect(YearWheel.line(for: .december) == "December! December is in winter.")
    }
}
