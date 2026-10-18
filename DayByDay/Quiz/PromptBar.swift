//
//  PromptBar.swift
//  DayByDay
//

import SwiftUI

/// A game's mascot and "Hear it again", which repeats the spoken prompt.
/// VoiceOver also reads the prompt as the button's value.
struct PromptBar: View {
    @Binding var mascot: MascotState
    var prompt: String?
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        // The mascot goes above the button at the accessibility text sizes.
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 12)) : AnyLayout(HStackLayout(spacing: 12))
        layout {
            GameMascot(state: $mascot)
            Button(action: action) {
                Label {
                    // Room for Baloo's tall glyphs inside the text's own frame.
                    Text("Hear it again").padding(.vertical, 4)
                } icon: {
                    Image(systemName: "speaker.wave.2.fill")
                }
                .font(.heading(24))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .frame(maxWidth: typeSize.isAccessibilitySize ? .infinity : nil)
                .background(RoundedRectangle(cornerRadius: 30, style: .continuous).fill(Color(.systemGray6)))
            }
            .buttonStyle(.plain)
            .accessibilityValue(prompt ?? "")
        }
    }
}
