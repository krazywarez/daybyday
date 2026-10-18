//
//  ContentView.swift
//  DayByDay
//
//  Created by cmc on 2026-03-09.
//

import SwiftData
import SwiftUI

// MARK: - Category model

nonisolated enum Category: Int, CaseIterable, Identifiable {
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

    /// Fixed colors with at least 3:1 contrast against white labels in light and dark mode.
    var color: Color {
        switch self {
        case .today:     Color(red: 0.84, green: 0.40, blue: 0.08)
        case .days:      Color(red: 0.0, green: 0.42, blue: 0.85)
        case .months:    Color(red: 0.62, green: 0.22, blue: 0.78)
        case .seasons:   Color(red: 0.18, green: 0.56, blue: 0.28)
        case .numbers:   Color(red: 0.86, green: 0.20, blue: 0.22)
        case .colors:    Color(red: 0.82, green: 0.25, blue: 0.52)
        case .shapes:    Color(red: 0.0, green: 0.53, blue: 0.56)
        case .animals:   Color(red: 0.63, green: 0.40, blue: 0.18)
        case .alphabet:  Color(red: 0.35, green: 0.34, blue: 0.84)
        case .weather:   Color(red: 0.10, green: 0.48, blue: 0.78)
        case .bodyParts: Color(red: 0.80, green: 0.30, blue: 0.46)
        case .food:      Color(red: 0.80, green: 0.42, blue: 0.08)
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
                    .fill(category.color)
                    .shadow(color: category.color.opacity(0.4), radius: 8, y: 4)
            }

            VStack(spacing: 12) {
                Image(systemName: category.symbol)
                    .font(.system(size: 48))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)

                Text(category.label)
                    .font(.heading(24))
                    .foregroundStyle(.white)
            }
            .padding(12)
            .shadow(color: category.usesGradientBackground ? .black.opacity(0.6) : .clear, radius: 2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(category.label)
    }
}

// MARK: - Content view

/// Routes between first-launch setup, the profile picker, and home.
struct ContentView: View {
    @Environment(ProfileSession.self) private var session
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            switch session.screen {
            case .setup:  ProfileSetupView()
            case .picker: ProfilePickerView()
            case .home:   HomeView()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background: session.didEnterBackground(at: .now)
            case .active:     session.willEnterForeground(at: .now)
            default:          break
            }
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

            CenteredScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)

                    Text("Better Voices Available")
                        .font(.system(.title, design: .rounded, weight: .bold))

                    Text("For the best experience, download an enhanced voice on your device.\n\nSettings → Accessibility → Read & Speak → Voices → English → tap a voice marked Enhanced or Premium to download it.")
                        .font(.system(.body, design: .rounded))
                        .multilineTextAlignment(.center)

                    Text("Tap anywhere to dismiss")
                        .font(.system(.callout, design: .rounded, weight: .medium))
                        .padding(.top, 8)
                }
                .padding(40)
                .frame(maxWidth: 520)
                .background(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(.regularMaterial)
                )
                .padding(24)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onDismiss)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    let container = ProfileStore.makeContainer(inMemory: true)
    ContentView()
        .environment(ProfileSession(store: ProfileStore(context: container.mainContext)))
        .modelContainer(container)
}
