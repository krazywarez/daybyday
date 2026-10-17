//
//  SpokenText.swift
//  DayByDay
//

import Foundation

/// Splits spoken text into sentences, the unit voice clips are recorded in.
nonisolated enum SpokenText {
    /// A sentence ends at ".", "!" or "?" followed by a space or the end.
    static func sentences(_ text: String) -> [String] {
        var result: [String] = []
        var current = ""
        let chars = Array(text)
        for (i, c) in chars.enumerated() {
            current.append(c)
            let atBreak = ".!?".contains(c) && (i + 1 == chars.count || chars[i + 1] == " ")
            if atBreak {
                append(current, to: &result)
                current = ""
            }
        }
        append(current, to: &result)
        return result
    }

    private static func append(_ sentence: String, to result: inout [String]) {
        let trimmed = sentence.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { result.append(trimmed) }
    }
}
