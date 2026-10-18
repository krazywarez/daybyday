//
//  ParentGateView.swift
//  DayByDay
//

import SwiftUI

/// Press-and-hold, then a sum. Calls `onPass` when both are done.
struct ParentGateView: View {
    let onPass: () -> Void
    let onCancel: () -> Void

    @State private var holdProgress: CGFloat = 0
    @State private var held = false
    @State private var challenge = ParentGateView.newChallenge()
    @State private var input = ""
    @FocusState private var fieldFocused: Bool

    init(onPass: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.onPass = onPass
        self.onCancel = onCancel
    }

    var body: some View {
        CenteredScrollView {
            VStack(spacing: 32) {
                Text("For Grown-Ups")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))

                if held {
                    sumStep
                } else {
                    holdStep
                }

                Button("Cancel", action: onCancel)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(.primary)
            }
            .padding(40)
            .frame(maxWidth: 520)
            .multilineTextAlignment(.center)
        }
    }

    private var holdStep: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: holdProgress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 140, height: 140)
            .contentShape(Circle())
            .onLongPressGesture(minimumDuration: ParentGateChallenge.holdDuration) {
                held = true
                fieldFocused = true
            } onPressingChanged: { pressing in
                if pressing {
                    withAnimation(.linear(duration: ParentGateChallenge.holdDuration)) { holdProgress = 1 }
                } else if !held {
                    withAnimation(.easeOut(duration: 0.2)) { holdProgress = 0 }
                }
            }
            .accessibilityLabel("Hold for grown-ups")
            .accessibilityAddTraits(.isButton)
            // Assistive technologies skip the hold; the sum still keeps children out.
            .accessibilityAction {
                held = true
                fieldFocused = true
            }

            Text("Press and hold")
                .font(.system(.body, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var sumStep: some View {
        VStack(spacing: 20) {
            Text("What is \(challenge.a) + \(challenge.b)?")
                .font(.system(.title, design: .rounded, weight: .semibold))
            TextField("Answer", text: $input)
                .keyboardType(.numberPad)
                .focused($fieldFocused)
                .multilineTextAlignment(.center)
                .font(.system(.title, design: .rounded, weight: .bold))
                .padding(12)
                .frame(width: 160)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
            Button("Continue", action: submit)
                .buttonStyle(.borderedProminent)
                .font(.system(.title3, design: .rounded, weight: .semibold))
        }
    }

    private func submit() {
        if challenge.accepts(input) {
            onPass()
        } else {
            challenge = Self.newChallenge()
            input = ""
            held = false
            holdProgress = 0
        }
    }

    private static func newChallenge() -> ParentGateChallenge {
        var rng = SystemRandomNumberGenerator()
        return .random(using: &rng)
    }
}

#Preview {
    ParentGateView(onPass: {}, onCancel: {})
}
