//
//  CategoryHubView.swift
//  DayByDay
//

import SwiftUI

/// What a child can do with one topic. Same layout for every topic.
struct CategoryHubView: View {
    let category: Category

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                activity("Look and listen", systemImage: "eye.fill", color: category.color) {
                    category.lookAndListenView
                        .navigationTitle(category.label)
                }
            }
            .padding(32)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
    }

    private func activity(_ title: String, systemImage: String, color: Color,
                          @ViewBuilder destination: @escaping () -> some View) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 20) {
                Image(systemName: systemImage)
                    .font(.system(size: 44))
                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 32)
            .frame(height: 120)
            .background(RoundedRectangle(cornerRadius: 32, style: .continuous).fill(color))
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded { SpeechSynthesizer.shared.speak(title) })
    }
}

extension Category {
    /// The existing card grid for this topic.
    @ViewBuilder
    var lookAndListenView: some View {
        switch self {
        case .today:     TodayView()
        case .days:      DaysOfWeekView()
        case .months:    MonthsOfYearView()
        case .seasons:   SeasonsView()
        case .numbers:   NumbersView()
        case .colors:    ColorsView()
        case .shapes:    ShapesView()
        case .animals:   AnimalsView()
        case .alphabet:  AlphabetView()
        case .weather:   WeatherView()
        case .bodyParts: BodyPartsView()
        case .food:      FoodView()
        }
    }
}
