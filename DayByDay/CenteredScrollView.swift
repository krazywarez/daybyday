//
//  CenteredScrollView.swift
//  DayByDay
//

import SwiftUI

/// Centers its content, and scrolls it when it is taller than the screen, as
/// it can be at the accessibility text sizes.
struct CenteredScrollView<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                content.frame(maxWidth: .infinity, minHeight: geo.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}
