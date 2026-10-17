import SwiftUI
import Testing
import UIKit
@testable import DayByDay

@MainActor
struct HeadingFontTests {
    @Test func balooIsBundledAndRegistered() {
        HeadingFont.register()
        #expect(UIFont(name: HeadingFont.bold, size: 20) != nil)
        #expect(UIFont(name: HeadingFont.extraBold, size: 20) != nil)
    }
}
