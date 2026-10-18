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

    @Test(arguments: LearnWeather.allCases) func weatherCardAgainstWhite(_ weather: LearnWeather) {
        #expect(contrast(weather.color, .white, .light) >= 3, "\(weather)")
    }

    @Test(arguments: LearnShape.allCases) func shapeCardAgainstWhite(_ shape: LearnShape) {
        #expect(contrast(shape.color, .white, .light) >= 3, "\(shape)")
    }

    @Test(arguments: Season.allCases) func seasonCardAgainstWhite(_ season: Season) {
        #expect(contrast(season.color, .white, .light) >= 3, "\(season)")
    }

    @Test(arguments: MonthOfYear.allCases) func monthCardAgainstWhite(_ month: MonthOfYear) {
        #expect(contrast(month.color, .white, .light) >= 3, "\(month)")
    }

    @Test(arguments: LearnFood.allCases) func foodCardAgainstWhite(_ food: LearnFood) {
        #expect(contrast(food.color, .white, .light) >= 3, "\(food)")
    }

    @Test(arguments: LearnBodyPart.allCases) func bodyPartCardAgainstWhite(_ part: LearnBodyPart) {
        #expect(contrast(part.color, .white, .light) >= 3, "\(part)")
    }

    @Test(arguments: LearnNumber.allCases) func numberCardAgainstWhite(_ number: LearnNumber) {
        #expect(contrast(number.color, .white, .light) >= 3, "\(number)")
    }

    @Test(arguments: LearnColor.allCases) func colorCardLabel(_ color: LearnColor) {
        #expect(contrast(color.color, color.labelColor, .light) >= 3, "\(color)")
    }

    @Test(arguments: DayOfWeek.allCases) func dayColorAgainstWhite(_ day: DayOfWeek) {
        #expect(contrast(day.color, .white, .light) >= 3, "\(day)")
    }

    @Test func stickerFillAgainstWhite() {
        #expect(contrast(StickerStyle.fill, .white, .light) >= 3)
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

    /// Body on the page in both modes; each feature on what it sits on.
    @Test func mascotContrast() {
        #expect(contrast(MascotStyle.body, .white, .light) >= 3)
        #expect(contrast(MascotStyle.body, .black, .dark) >= 3)
        for style in Self.styles {
            for feature in [MascotStyle.eyeWhite, MascotStyle.belly, MascotStyle.beak, MascotStyle.ink] {
                #expect(contrast(feature, MascotStyle.body, style) >= 3, "\(feature) \(style.rawValue)")
            }
            #expect(contrast(MascotStyle.ink, MascotStyle.eyeWhite, style) >= 3)
            #expect(contrast(MascotStyle.ink, MascotStyle.belly, style) >= 3)
        }
    }
}
