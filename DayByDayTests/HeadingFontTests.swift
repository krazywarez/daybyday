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

    @Test func headingsScaleLikeTheNearestTextStyle() {
        #expect(HeadingFont.textStyle(for: 11) == .caption2)
        #expect(HeadingFont.textStyle(for: 17) == .body)
        #expect(HeadingFont.textStyle(for: 22) == .title2)
        #expect(HeadingFont.textStyle(for: 28) == .title)
        #expect(HeadingFont.textStyle(for: 96) == .largeTitle)
    }
}
