import Foundation
import Testing
@testable import DayByDay

struct ProfileSessionTests {
    let container = ProfileStore.makeContainer(inMemory: true)
    var store: ProfileStore { ProfileStore(context: container.mainContext) }
    let t0 = Date(timeIntervalSince1970: 1_000_000)

    @discardableResult
    func add(_ name: String) -> Profile {
        try! store.create(name: name, avatar: .cat, color: .red, birthday: nil)
    }

    @Test func noProfilesShowsSetup() {
        #expect(ProfileSession(store: store).screen == .setup)
    }

    @Test func singleProfileAutoSelects() {
        let maya = add("Maya")
        let session = ProfileSession(store: store)
        #expect(session.screen == .home)
        #expect(session.current?.id == maya.id)
    }

    @Test func multipleProfilesShowPicker() {
        add("Maya"); add("Sam")
        let session = ProfileSession(store: store)
        #expect(session.screen == .picker)
        session.select(store.all()[1])
        #expect(session.screen == .home)
        #expect(session.current?.name == "Sam")
    }

    @Test func shortBackgroundKeepsCurrent() {
        add("Maya"); add("Sam")
        let session = ProfileSession(store: store)
        session.select(store.all()[0])
        session.didEnterBackground(at: t0)
        session.willEnterForeground(at: t0.addingTimeInterval(599))
        #expect(session.screen == .home)
    }

    @Test func longBackgroundShowsPickerWithSiblings() {
        add("Maya"); add("Sam")
        let session = ProfileSession(store: store)
        session.select(store.all()[0])
        session.didEnterBackground(at: t0)
        session.willEnterForeground(at: t0.addingTimeInterval(ProfileSession.pickerAfterBackground))
        #expect(session.screen == .picker)
    }

    @Test func longBackgroundKeepsSoleProfile() {
        add("Maya")
        let session = ProfileSession(store: store)
        session.didEnterBackground(at: t0)
        session.willEnterForeground(at: t0.addingTimeInterval(3600))
        #expect(session.screen == .home)
    }

    @Test func deletingCurrentClearsIt() {
        add("Maya"); add("Sam"); add("Lee")
        let session = ProfileSession(store: store)
        session.select(store.all()[0])
        store.delete(store.all()[0])
        session.profilesChanged()
        #expect(session.current == nil)
        #expect(session.screen == .picker)
        session.select(store.all()[0])
        store.delete(store.all()[0])
        session.profilesChanged()
        #expect(session.screen == .home)
        #expect(session.current?.name == "Lee")
    }

    @Test func deletingLastProfileShowsSetup() {
        add("Maya")
        let session = ProfileSession(store: store)
        store.delete(store.all()[0])
        session.profilesChanged()
        #expect(session.current == nil)
        #expect(session.screen == .setup)
    }

    @Test func addingFirstProfileSelectsIt() {
        let session = ProfileSession(store: store)
        add("Maya")
        session.profilesChanged()
        #expect(session.screen == .home)
    }
}
