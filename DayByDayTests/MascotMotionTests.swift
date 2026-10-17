import Testing
@testable import DayByDay

struct MascotMotionTests {
    @Test func blinksOncePerCycle() {
        #expect(MascotMotion.pose(.idle, at: 1.0).eyeOpen == 1)
        #expect(MascotMotion.pose(.idle, at: 3.75).eyeOpen == 0.1)
        #expect(MascotMotion.pose(.idle, at: 3.85).eyeOpen == 1)
        #expect(MascotMotion.pose(.idle, at: 7.55).eyeOpen == 0.1)
    }

    @Test func cheerHopsThenRests() {
        #expect(MascotMotion.pose(.cheering, at: 0.2).hop < 0)
        #expect(MascotMotion.pose(.cheering, at: 2.0).hop == 0)
        #expect(MascotMotion.pose(.cheering, at: 4.2).hop < 0)
        #expect(MascotMotion.pose(.cheering, at: 0.2).wing == 130)
    }

    @Test func waveSwingsThenHolds() {
        let swings = [0.1, 0.3, 0.5].map { MascotMotion.pose(.waving, at: $0).wing }
        #expect(Set(swings).count == 3)
        #expect(MascotMotion.pose(.waving, at: 3.0).wing == 135)
        #expect(MascotMotion.pose(.idle, at: 0.3).wing == 0)
    }

    @Test(arguments: MascotMood.allCases) func stillPosesDoNotMove(_ mood: MascotMood) {
        let pose = MascotMotion.still(mood)
        #expect(pose.bob == 0)
        #expect(pose.hop == 0)
        #expect(pose.eyeOpen == 1)
        #expect(pose.beakOpen == (mood == .asking ? 1 : 0))
        #expect(pose.wing == [.cheering: 130, .waving: 135][mood, default: 0])
        #expect(pose.tilt == [.asking: 4, .puzzled: -10][mood, default: 0])
    }

    @Test(arguments: MascotMood.allCases) func poseValuesInRange(_ mood: MascotMood) {
        for t in [-5, 0, 0.37, 1e6] {
            let pose = MascotMotion.pose(mood, at: t)
            #expect((0...1).contains(pose.eyeOpen), "\(mood) \(t)")
            #expect((0...1).contains(pose.beakOpen), "\(mood) \(t)")
            #expect((-0.06...0).contains(pose.hop), "\(mood) \(t)")
            #expect((-0.012...0).contains(pose.bob), "\(mood) \(t)")
            #expect((0...150).contains(pose.wing), "\(mood) \(t)")
            if mood == .waving { #expect(pose.wing >= 120, "\(t)") }
        }
        #expect(MascotMotion.pose(mood, at: -5) == MascotMotion.pose(mood, at: 0))
    }
}
