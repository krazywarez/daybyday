//
//  HomeView.swift
//  DayByDay
//

import SwiftUI

/// Today banner on top, then the topic grid.
struct HomeView: View {
    @Environment(ProfileSession.self) private var session
    @Environment(\.dynamicTypeSize) private var typeSize
    @AppStorage("hasSeenVoiceTip") private var hasSeenVoiceTip = false
    @State private var showingParentArea = false

    /// Two square tiles a row; one wide tile at the accessibility text sizes.
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 24), count: typeSize.isAccessibilitySize ? 1 : 2)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    NavigationLink {
                        TodayRoutineView().navigationTitle(Category.today.label)
                    } label: {
                        TodayBanner()
                    }
                    .buttonStyle(.plain)

                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(Category.gridCases) { category in
                            NavigationLink(value: category) {
                                CategoryTile(category: category)
                                    .aspectRatio(typeSize.isAccessibilitySize ? 2 : 1, contentMode: .fit)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    footerButton("Voice Quality Tips", systemImage: "speaker.wave.2.fill") {
                        hasSeenVoiceTip = false
                    }
                    footerButton("Grown-Ups", systemImage: "lock.fill") {
                        showingParentArea = true
                    }
                }
                .padding(24)
            }
            .navigationTitle("DayByDay")
            .navigationDestination(for: Category.self) { category in
                CategoryHubView(category: category)
                    .navigationTitle(category.label)
            }
            .toolbar {
                if session.profiles.count > 1, let current = session.current {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            session.current = nil
                        } label: {
                            AvatarBadge(avatar: current.avatar, color: current.color)
                                .frame(width: 40, height: 40)
                        }
                        .accessibilityLabel("Switch child")
                    }
                }
            }
            .overlay {
                if !hasSeenVoiceTip {
                    VoiceTipOverlay {
                        withAnimation { hasSeenVoiceTip = true }
                    }
                }
            }
            .sheet(isPresented: $showingParentArea) {
                GatedView(onCancel: { showingParentArea = false }) {
                    ParentAreaView(onDone: { showingParentArea = false })
                }
            }
        }
    }

    private func footerButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(.callout, design: .rounded, weight: .medium))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.systemGray6))
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}
