//
//  YearWheel.swift
//  DayByDay
//

import Foundation

/// Geometry of the year wheel. Month `i` (January = 0) is drawn centered
/// `i * 30°` clockwise from the pointer at the top; the wheel then turns
/// clockwise by its rotation.
nonisolated enum YearWheel {
    static let wedge = 30.0

    /// The month under the pointer after turning the wheel clockwise by `degrees`.
    static func month(atRotation degrees: Double) -> MonthOfYear {
        let index = Int((-degrees / wedge).rounded())
        return MonthOfYear.allCases[((index % 12) + 12) % 12]
    }

    /// The first rotation at least `turns` full turns past `rotation` that
    /// puts the center of `month` under the pointer.
    static func target(from rotation: Double, landingOn month: MonthOfYear, turns: Int) -> Double {
        let index = Double(MonthOfYear.allCases.firstIndex(of: month)!)
        let base = -index * wedge
        let minimum = rotation + Double(turns) * 360
        return base + 360 * ((minimum - base) / 360).rounded(.up)
    }

    static func line(for month: MonthOfYear) -> String {
        "\(month.name)! \(month.name) is in \(month.season.name.lowercased())."
    }
}
