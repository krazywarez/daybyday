//
//  CategoryHubView.swift
//  DayByDay
//

import SwiftUI

/// What a child can do with one topic. Same layout for every topic.
struct CategoryHubView: View {
    let category: Category

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                activity(Lines.lookAndListen, systemImage: "eye.fill", color: category.color) {
                    category.lookAndListenView
                        .navigationTitle(category.label)
                }
                ForEach(category.games, id: \.self) { game in
                    activity(game.title, systemImage: game.symbol, color: category.color) {
                        GameDestination(category: category, game: game)
                    }
                }
            }
            .padding(typeSize.isAccessibilitySize ? 16 : 32)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
    }

    private func activity(_ title: String, systemImage: String, color: Color,
                          @ViewBuilder destination: @escaping () -> some View) -> some View {
        NavigationLink(destination: destination) {
            // The symbol goes above the title at the accessibility text sizes.
            let layout = typeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout(spacing: 20))
            layout {
                Image(systemName: systemImage)
                    .font(.system(size: 44))
                Text(title)
                    .font(.heading(32))
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, typeSize.isAccessibilitySize ? 20 : 32)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 32, style: .continuous).fill(color))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("activity:\(title)")
        .simultaneousGesture(TapGesture().onEnded { SpeechSynthesizer.shared.speak(title) })
    }
}

extension Category {
    /// The existing card grid for this topic.
    @ViewBuilder
    var lookAndListenView: some View {
        switch self {
        case .today:     TodayRoutineView()
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
