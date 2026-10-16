import SwiftUI
import Testing
import UIKit
@testable import DayByDay

/// WCAG contrast for white or dark symbols and labels on the app's fills.
struct ContrastTests {
    static let styles: [UIUserInterfaceStyle] = [.light, .dark]

    func luminance(_ color: Color, _ style: UIUserInterfaceStyle) -> Double {
        let ui = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        func lin(_ c: CGFloat) -> Double {
            let c = Double(c)
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
    }

    func contrast(_ a: Color, _ b: Color, _ style: UIUserInterfaceStyle) -> Double {
        let la = luminance(a, style), lb = luminance(b, style)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    @Test(arguments: DayByDay.Category.allCases) func categoryColorAgainstWhite(_ category: DayByDay.Category) {
        for style in Self.styles {
            #expect(contrast(category.color, .white, style) >= 3, "\(category) \(style.rawValue)")
        }
    }

    @Test func todayBannerAgainstWhite() {
        for color in TodayBanner.gradientColors {
            #expect(contrast(color, .white, .light) >= 3)
        }
    }

    @Test func playAgainAgainstWhite() {
        #expect(contrast(RoundStyle.playAgainFill, .white, .light) >= 3)
    }

    @Test(arguments: ProfileColor.allCases) func avatarSymbolOnProfileColor(_ color: ProfileColor) {
        for style in Self.styles {
            #expect(contrast(color.symbolColor, color.color, style) >= 3, "\(color) \(style.rawValue)")
        }
    }

    /// White and black color swatches need an edge that shows on either background.
    @Test func swatchOutlineAgainstBackgrounds() {
        #expect(contrast(ChoiceStyle.swatchOutline, .white, .light) >= 3)
        #expect(contrast(ChoiceStyle.swatchOutline, .black, .dark) >= 3)
    }

    @Test func foodFillAgainstWhite() {
        for style in Self.styles {
            #expect(contrast(ChoiceStyle.foodFill, .white, style) >= 3)
        }
    }
}
