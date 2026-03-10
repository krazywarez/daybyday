//
//  ContentView.swift
//  DayByDay
//
//  Created by cmc on 2026-03-09.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @AppStorage("hasSeenVoiceTip") private var hasSeenVoiceTip = false

    private let tabs: [(label: String, symbol: String)] = [
        ("Days", "calendar"),
        ("Months", "calendar.badge.clock"),
        ("Seasons", "leaf.fill"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case 0:  DaysOfWeekView()
                case 1:  MonthsOfYearView()
                default: SeasonsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Bottom tab bar with large tap targets
            HStack(spacing: 0) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    Button {
                        selectedTab = index
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: tab.symbol)
                                .font(.system(size: 32))
                            Text(tab.label)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(selectedTab == index ? Color.accentColor : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tab.label)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            .background(.bar)
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

                Text("For the best experience, download an enhanced voice on your iPad.\n\nSettings → Accessibility → Spoken Content → Voices → English → tap a voice marked Enhanced or Premium to download it.")
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
