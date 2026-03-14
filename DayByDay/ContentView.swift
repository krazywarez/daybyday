//
//  ContentView.swift
//  DayByDay
//
//  Created by cmc on 2026-03-09.
//

import SwiftUI

// MARK: - Category model

enum Category: Int, CaseIterable, Identifiable {
    case today, days, months, seasons, numbers, colors, shapes, animals, alphabet,
         weather, bodyParts, food

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .today:     "Today"
        case .days:      "Days"
        case .months:    "Months"
        case .seasons:   "Seasons"
        case .numbers:   "Numbers"
        case .colors:    "Colors"
        case .shapes:    "Shapes"
        case .animals:   "Animals"
        case .alphabet:  "Alphabet"
        case .weather:   "Weather"
        case .bodyParts: "Body"
        case .food:      "Food"
        }
    }

    var symbol: String {
        switch self {
        case .today:     "sun.horizon.fill"
        case .days:      "calendar"
        case .months:    "calendar.badge.clock"
        case .seasons:   "leaf.fill"
        case .numbers:   "123.rectangle.fill"
        case .colors:    "paintpalette.fill"
        case .shapes:    "pentagon.fill"
        case .animals:   "pawprint.fill"
        case .alphabet:  "abc"
        case .weather:   "cloud.sun.rain.fill"
        case .bodyParts: "figure.stand"
        case .food:      "carrot.fill"
        }
    }

    var color: Color {
        switch self {
        case .today:     .orange
        case .days:      .blue
        case .months:    .purple
        case .seasons:   .green
        case .numbers:   .red
        case .colors:    .pink
        case .shapes:    .teal
        case .animals:   Color(red: 0.7, green: 0.45, blue: 0.2)
        case .alphabet:  .indigo
        case .weather:   Color(red: 0.4, green: 0.75, blue: 0.95)
        case .bodyParts: Color(red: 0.9, green: 0.5, blue: 0.6)
        case .food:      Color(red: 0.95, green: 0.6, blue: 0.2)
        }
    }

    /// Whether this tile uses a special gradient background instead of the solid color.
    var usesGradientBackground: Bool {
        self == .colors
    }
}

// MARK: - Home grid tile

struct CategoryTile: View {
    let category: Category

    var body: some View {
        ZStack {
            if category.usesGradientBackground {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.red, .orange, .yellow, .green, .blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: category.color.opacity(0.4), radius: 8, y: 4)
            } else {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(category.color.gradient)
                    .shadow(color: category.color.opacity(0.4), radius: 8, y: 4)
            }

            VStack(spacing: 12) {
                Image(systemName: category.symbol)
                    .font(.system(size: 48))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)

                Text(category.label)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .accessibilityLabel(category.label)
    }
}

// MARK: - Content view

struct ContentView: View {
    @AppStorage("hasSeenVoiceTip") private var hasSeenVoiceTip = false

    private let columns = [
        GridItem(.flexible(), spacing: 24),
        GridItem(.flexible(), spacing: 24)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(Category.allCases) { category in
                        NavigationLink(value: category) {
                            CategoryTile(category: category)
                                .aspectRatio(1, contentMode: .fit)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(24)

                Button {
                    hasSeenVoiceTip = false
                } label: {
                    Label("Voice Quality Tips", systemImage: "speaker.wave.2.fill")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .navigationTitle("DayByDay")
            .navigationDestination(for: Category.self) { category in
                destinationView(for: category)
                    .navigationTitle(category.label)
            }
            .overlay {
                if !hasSeenVoiceTip {
                    VoiceTipOverlay {
                        withAnimation { hasSeenVoiceTip = true }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func destinationView(for category: Category) -> some View {
        switch category {
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

/// A one-time informational overlay for parents explaining how to download
/// a higher-quality voice for the best experience. Dismissed with a single tap.
struct VoiceTipOverlay: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)

                Text("Better Voices Available")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Text("For the best experience, download an enhanced voice on your device.\n\nSettings → Accessibility → Read & Speak → Voices → English → tap a voice marked Enhanced or Premium to download it.")
                    .font(.system(size: 18, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Text("Tap anywhere to dismiss")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 8)
            }
            .padding(40)
            .frame(maxWidth: 520)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(.regularMaterial)
            )
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onDismiss)
    }
}

#Preview {
    ContentView()
}
