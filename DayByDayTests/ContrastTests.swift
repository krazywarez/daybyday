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

    @Test(arguments: Season.allCases) func wheelColorAgainstWhite(_ season: Season) {
        for style in Self.styles {
            #expect(contrast(season.wheelColor, .white, style) >= 3, "\(season)")
        }
    }

    /// Uncounted objects sit on the page background in the numbers color.
    @Test func countingObjectsAgainstBackground() {
        let numbers = DayByDay.Category.numbers.color
        #expect(contrast(numbers, .white, .light) >= 3)
        #expect(contrast(numbers, .black, .dark) >= 3)
    }

    /// Train wheels sit on the page background in both modes.
    @Test func trainTireAgainstBackgrounds() {
        #expect(contrast(TrainStyle.tire, .white, .light) >= 3)
        #expect(contrast(TrainStyle.tire, .black, .dark) >= 3)
    }

    @Test(arguments: LearnAnimal.allCases) func animalColorAgainstWhite(_ animal: LearnAnimal) {
        #expect(contrast(animal.color, .white, .light) >= 3, "\(animal)")
    }

    @Test(arguments: LearnLetter.allCases) func letterColorAgainstWhite(_ letter: LearnLetter) {
        #expect(contrast(letter.color, .white, .light) >= 3, "\(letter)")
    }

    /// Sort bins carry white labels and must stand out on a black page.
    @Test func sortBinFill() {
        #expect(contrast(SortStyle.binFill, .white, .light) >= 3)
        #expect(contrast(SortStyle.binFill, .black, .dark) >= 3)
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
