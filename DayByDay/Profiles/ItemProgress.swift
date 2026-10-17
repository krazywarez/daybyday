//
//  ItemProgress.swift
//  DayByDay
//

import Foundation

/// One answer, as `ItemProgress` needs it.
nonisolated struct AnswerFact: Equatable {
    /// The question's answer.
    let itemID: String
    let isCorrect: Bool
    let timestamp: Date
}

nonisolated enum ItemStatus: Equatable {
    case new, learning, known
}

/// How one child is doing with each item in a topic. A missed item stays
/// learning until it is answered right `clearAfter` times; the right answer
/// that just retries the missed question does not count.
nonisolated struct ItemProgress {
    static let retryWindow: TimeInterval = 60
    static let clearAfter = 3
    static let knownAfter = 2
    static let learningWeight = 3.0

    private(set) var statuses: [String: ItemStatus] = [:]
    private(set) var lastMiss: [String: Date] = [:]

    init(_ facts: [AnswerFact]) {
        var counted: [String: Int] = [:]
        var awaitingRetry: Set<String> = []
        for fact in facts.sorted(by: { $0.timestamp < $1.timestamp }) {
            let id = fact.itemID
            if !fact.isCorrect {
                lastMiss[id] = fact.timestamp
                counted[id] = 0
                awaitingRetry.insert(id)
            } else if awaitingRetry.remove(id) != nil,
                      let miss = lastMiss[id], fact.timestamp.timeIntervalSince(miss) < Self.retryWindow {
                continue
            } else {
                counted[id, default: 0] += 1
            }
        }
        for (id, count) in counted {
            if lastMiss[id] != nil && count < Self.clearAfter {
                statuses[id] = .learning
            } else {
                statuses[id] = count >= Self.knownAfter ? .known : .new
            }
        }
    }

    func status(_ itemID: String) -> ItemStatus {
        statuses[itemID] ?? .new
    }

    func weight(_ itemID: String) -> Double {
        status(itemID) == .learning ? Self.learningWeight : 1
    }
}
