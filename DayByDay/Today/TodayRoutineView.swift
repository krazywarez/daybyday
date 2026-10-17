//
//  TodayRoutineView.swift
//  DayByDay
//

import SwiftUI

/// The morning routine: a few spoken lines about today, the child picks
/// today's weather, and a sticker goes on the calendar.
struct TodayRoutineView: View {
    static let weathers: [LearnWeather] = [.sunny, .cloudy, .rainy, .snowy, .windy]

    private enum Phase: Equatable { case line(Int), weather, done }

    @Environment(ProfileSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var phase = Phase.line(0)
    @State private var lines: [RoutineScript.Line] = []
    @State private var celebrating = false
    @State private var mascot = MascotState()
    @State private var speechToken = 0
    /// Bumped when the screen goes away, so pending work does nothing.
    @State private var generation = 0

    private let columns = [GridItem(.adaptive(minimum: 140, maximum: 220), spacing: 16)]

    var body: some View {
        ZStack {
            switch phase {
            case .line(let i) where i < lines.count:
                lineCard(lines[i])
            case .line:
                Color.clear
            case .weather:
                weatherPick
            case .done:
                ScrollView {
                    VStack(spacing: 20) {
                        GameMascot(state: $mascot)
                        StickerCalendarView(profile: session.current)
                            .frame(maxWidth: 560)
                            .padding(.top, 8)
                        Button { dismiss() } label: {
                            Label("Done", systemImage: "checkmark")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 44)
                                .padding(.vertical, 20)
                                .background(Capsule().fill(RoundStyle.playAgainFill))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .overlay { CelebrationOverlay(isActive: celebrating) }
        .onAppear {
            if lines.isEmpty { lines = script().lines }
            speakCurrent()
        }
        .onDisappear {
            generation += 1
            speechToken += 1
            SpeechSynthesizer.shared.stop()
        }
    }

    private func script() -> RoutineScript {
        let profile = session.current
        let birthday = profile.flatMap { p in p.birthdayMonth.flatMap { m in p.birthdayDay.map { (month: m, day: $0) } } }
        return RoutineScript(date: .now, calendar: AppCalendar.current, name: profile?.name, birthday: birthday,
                             picture: profile.flatMap { session.store.picture(on: .current, for: $0) })
    }

    private func lineCard(_ line: RoutineScript.Line) -> some View {
        VStack(spacing: 28) {
            hearAgain
            VStack(spacing: 20) {
                Image(systemName: line.symbol)
                    .font(.system(size: 110))
                    .frame(height: 130)
                Text(line.text)
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
            }
            .foregroundStyle(.white)
            .padding(28)
            .frame(maxWidth: 520, minHeight: 300)
            .background(RoundedRectangle(cornerRadius: 36, style: .continuous).fill(TodayBanner.gradientColors[0]))
            .accessibilityElement(children: .combine)

            Button(action: next) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 96, height: 96)
                    .background(Circle().fill(RoundStyle.playAgainFill))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next")
        }
        .padding(24)
    }

    private var weatherPick: some View {
        ScrollView {
            VStack(spacing: 24) {
                hearAgain
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Self.weathers) { weather in
                        Button { pick(weather) } label: {
                            ChoiceTile(item: Category.weather.item(weather)).frame(height: 140)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(weather.name)
                    }
                }
            }
            .padding(24)
        }
    }

    private var hearAgain: some View {
        HStack(spacing: 12) {
            GameMascot(state: $mascot)
            Button(action: speakCurrent) {
                Label("Hear it again", systemImage: "speaker.wave.2.fill")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Color(.systemGray6)))
            }
            .buttonStyle(.plain)
        }
    }

    private func next() {
        guard case .line(let i) = phase else { return }
        phase = i + 1 < lines.count ? .line(i + 1) : .weather
        speakCurrent()
    }

    private func speakCurrent() {
        switch phase {
        case .line(0) where !lines.isEmpty:
            mascot.handle(.greet)
            say(lines[0].text)
        case .line(let i) where i < lines.count: ask(lines[i].text)
        case .weather: ask("What's the weather like today?")
        default: break
        }
    }

    private func pick(_ weather: LearnWeather) {
        guard phase == .weather else { return }
        let today = AppCalendar.current.dateComponents([.year, .month, .day], from: .now)
        if let profile = session.current {
            session.store.addSticker(for: profile, on: today, weather: weather)
        }
        SoundEngine.shared.play(.success)
        mascot.handle(.correct)
        celebrating = true
        phase = .done
        say("It's \(weather.name.lowercased()) today! Here's your sticker!", after: RoundStyle.speechDelay)
        let gen = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if gen == generation { celebrating = false }
        }
    }

    private func ask(_ text: String) {
        mascot.handle(.prompt(text))
        say(text)
    }

    private func say(_ text: String, after delay: TimeInterval = 0) {
        speechToken += 1
        let token = speechToken, gen = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if token == speechToken, gen == generation { SpeechSynthesizer.shared.speak(text) }
        }
    }
}
