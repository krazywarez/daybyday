//
//  TodayView.swift
//  DayByDay
//

import SwiftUI

/// A single-screen summary of today: day of the week, date, month, and season.
/// The child taps the large card to hear "Today is [day], [month] [date]. It is [season]."
struct TodayView: View {
    @State private var isTapped = false

    private var todayText: String {
        let day = DayOfWeek.current.name
        let month = MonthOfYear.current.name
        let date = Calendar.current.component(.day, from: Date())
        let season = Season.current.name
        return "Today is \(day), \(month) \(date). It is \(season)."
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Main today card
                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(Color.orange.gradient)
                        .shadow(color: Color.orange.opacity(0.4), radius: 8, y: 4)

                    VStack(spacing: 20) {
                        Image(systemName: "sun.horizon.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.white)
                            .symbolRenderingMode(.hierarchical)

                        // Day of the week
                        Text(DayOfWeek.current.name)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        // Date number
                        let dayNumber = Calendar.current.component(.day, from: Date())
                        Text("\(dayNumber)")
                            .font(.system(size: 72, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))

                        // Month and season
                        HStack(spacing: 24) {
                            Label(MonthOfYear.current.name, systemImage: MonthOfYear.current.symbol)
                            Label(Season.current.name, systemImage: Season.current.symbol)
                        }
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(.vertical, 32)
                }
                .frame(height: 420)
                .scaleEffect(isTapped ? 1.08 : 1.0)
                .rotation3DEffect(.degrees(isTapped ? 6 : 0), axis: (x: 1, y: 0, z: 0))
                .animation(.spring(response: 0.35, dampingFraction: 0.5), value: isTapped)
                .contentShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .onTapGesture {
                    isTapped = true
                    SpeechSynthesizer.shared.speak(todayText)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        isTapped = false
                    }
                }
                .accessibilityLabel(todayText)
                .accessibilityAddTraits(.isButton)

                // Tap hint
                Label("Tap to hear today", systemImage: "speaker.wave.2.fill")
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(32)
        }
    }
}

#Preview {
    TodayView()
}
