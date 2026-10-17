//
//  FinishedView.swift
//  DayByDay
//

import SwiftUI

/// End of a game: cheering mascot, "You did it!", and Play again.
struct FinishedView: View {
    let onPlayAgain: () -> Void

    @State private var speechToken = 0

    var body: some View {
        VStack(spacing: 28) {
            MascotView(mood: .cheering)
                .frame(width: 180, height: 180)
            Text("You did it!")
                .font(.system(size: 48, weight: .heavy, design: .rounded))
            Button(action: onPlayAgain) {
                Label("Play again", systemImage: "arrow.clockwise")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .background(Capsule().fill(RoundStyle.playAgainFill))
            }
            .buttonStyle(.plain)
        }
        .padding(32)
        .onAppear {
            SoundEngine.shared.play(.roundComplete)
            speechToken += 1
            let token = speechToken
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                if token == speechToken { SpeechSynthesizer.shared.speak(Lines.youDidIt) }
            }
        }
        .onDisappear { speechToken += 1 }
    }
}
