//
//  ParentGate.swift
//  DayByDay
//

import Foundation

/// A sum a 4–5 year old can't read or solve, asked before grown-up screens.
nonisolated struct ParentGateChallenge: Equatable {
    static let holdDuration: Double = 2

    let a: Int
    let b: Int

    var answer: Int { a + b }

    static func random(using rng: inout some RandomNumberGenerator) -> ParentGateChallenge {
        ParentGateChallenge(a: Int.random(in: 6...9, using: &rng), b: Int.random(in: 6...9, using: &rng))
    }

    func accepts(_ input: String) -> Bool {
        Int(input.trimmingCharacters(in: .whitespaces)) == answer
    }
}
