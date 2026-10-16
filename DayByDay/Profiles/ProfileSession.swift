//
//  ProfileSession.swift
//  DayByDay
//

import Foundation
import Observation
import SwiftData

enum SessionScreen: Equatable {
    case setup, picker, home
}

/// Tracks which child is using the app and which top-level screen to show.
@Observable
final class ProfileSession {
    /// Time in the background after which siblings pick again.
    static let pickerAfterBackground: TimeInterval = 600

    let store: ProfileStore
    private(set) var profiles: [Profile] = []
    var current: Profile?
    private var backgroundedAt: Date?

    init(store: ProfileStore) {
        self.store = store
        profilesChanged()
    }

    var screen: SessionScreen {
        if profiles.isEmpty { return .setup }
        return current == nil ? .picker : .home
    }

    func select(_ profile: Profile) {
        current = profile
    }

    func didEnterBackground(at date: Date) {
        backgroundedAt = date
    }

    func willEnterForeground(at date: Date) {
        defer { backgroundedAt = nil }
        guard let backgroundedAt, profiles.count > 1,
              date.timeIntervalSince(backgroundedAt) >= Self.pickerAfterBackground
        else { return }
        current = nil
    }

    /// Call after any profile is added, edited, or deleted.
    func profilesChanged() {
        profiles = store.all()
        if let current, !profiles.contains(where: { $0.persistentModelID == current.persistentModelID }) {
            self.current = nil
        }
        if current == nil, profiles.count == 1 {
            current = profiles[0]
        }
    }
}
