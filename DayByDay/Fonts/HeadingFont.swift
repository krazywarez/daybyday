//
//  HeadingFont.swift
//  DayByDay
//

import CoreText
import SwiftUI
import UIKit

/// Baloo 2 (SIL Open Font License, Baloo2-OFL.txt) for the headings and
/// labels a child sees. The Grown-Ups screens keep the system font.
enum HeadingFont {
    static let bold = "Baloo2-Bold"
    static let extraBold = "Baloo2-ExtraBold"

    /// Registers the bundled font and styles navigation titles with it.
    static func register() {
        if let url = Bundle.main.url(forResource: "Baloo2", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
        if let large = UIFont(name: extraBold, size: 34), let inline = UIFont(name: bold, size: 19) {
            UINavigationBar.appearance().largeTitleTextAttributes = [.font: large]
            UINavigationBar.appearance().titleTextAttributes = [.font: inline]
        }
    }
}

extension Font {
    /// A heading in Baloo 2: ExtraBold for `.heavy` and `.black`, Bold otherwise.
    static func heading(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .custom(weight == .heavy || weight == .black ? HeadingFont.extraBold : HeadingFont.bold, fixedSize: size)
    }
}
