//
//  GatedView.swift
//  DayByDay
//

import SwiftUI

/// Shows the parent gate first, then `content` once it is passed.
struct GatedView<Content: View>: View {
    let onCancel: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var passed = false

    var body: some View {
        if passed {
            content()
        } else {
            ParentGateView(onPass: { passed = true }, onCancel: onCancel)
        }
    }
}
