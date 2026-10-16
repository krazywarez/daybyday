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
        VStack(spacing: 32) {
            Text("For Grown-Ups")
                .font(.system(size: 32, weight: .bold, design: .rounded))

            if held {
                sumStep
            } else {
                holdStep
            }

            Button("Cancel", action: onCancel)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(maxWidth: 520)
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

            Text("Press and hold")
                .font(.system(size: 18, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private var sumStep: some View {
        VStack(spacing: 20) {
            Text("What is \(challenge.a) + \(challenge.b)?")
                .font(.system(size: 26, weight: .semibold, design: .rounded))
            TextField("Answer", text: $input)
                .keyboardType(.numberPad)
                .focused($fieldFocused)
                .multilineTextAlignment(.center)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .padding(12)
                .frame(width: 160)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
            Button("Continue", action: submit)
                .buttonStyle(.borderedProminent)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
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
