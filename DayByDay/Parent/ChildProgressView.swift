//
//  ChildProgressView.swift
//  DayByDay
//

import SwiftUI

/// For grown-ups: what one child knows and is still mixing up, per topic.
struct ChildProgressView: View {
    let profile: Profile

    @Environment(ProfileSession.self) private var session

    var body: some View {
        List(DayByDay.Category.gridCases) { category in
            let summary = ProgressSummary(category: category, progress: session.store.progress(for: profile, category: category))
            HStack(alignment: .top, spacing: 14) {
                // A fixed box, so wide symbols such as "abc" stay inside the circle.
                Image(systemName: category.symbol)
                    .resizable()
                    .scaledToFit()
                    .fontWeight(.semibold)
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(category.color))
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.label)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                    if let known = summary.known {
                        Text(known)
                    }
                    if let missing = summary.missing {
                        Text(missing)
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
        }
        .navigationTitle("\(profile.name)'s progress")
    }
}
