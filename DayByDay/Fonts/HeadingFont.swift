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

    /// Registers the bundled font and styles navigation titles with it, at
    /// the text size set when the app launches.
    static func register() {
        if let url = Bundle.main.url(forResource: "Baloo2", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
        if let large = UIFont(name: extraBold, size: 34), let inline = UIFont(name: bold, size: 19) {
            UINavigationBar.appearance().largeTitleTextAttributes =
                [.font: UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: large)]
            UINavigationBar.appearance().titleTextAttributes =
                [.font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: inline, maximumPointSize: 28)]
        }
    }

    /// The text style whose default size is nearest `size`, so a heading
    /// grows with Dynamic Type at the same rate as system text that size.
    static func textStyle(for size: CGFloat) -> Font.TextStyle {
        switch size {
        case ..<12: .caption2
        case ..<14: .footnote
        case ..<16.5: .callout
        case ..<18.5: .body
        case ..<21: .title3
        case ..<25: .title2
        case ..<31: .title
        default: .largeTitle
        }
    }
}

extension Font {
    /// A heading in Baloo 2: ExtraBold for `.heavy` and `.black`, Bold otherwise.
    /// Scales with Dynamic Type like the text style nearest `size`.
    static func heading(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .custom(weight == .heavy || weight == .black ? HeadingFont.extraBold : HeadingFont.bold,
                size: size, relativeTo: HeadingFont.textStyle(for: size))
    }
}

