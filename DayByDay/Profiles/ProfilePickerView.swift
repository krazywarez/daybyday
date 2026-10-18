//
//  ProfilePickerView.swift
//  DayByDay
//

import SwiftUI

/// "Who's playing?" Big avatar tiles; no reading needed.
struct ProfilePickerView: View {
    @Environment(ProfileSession.self) private var session
    @State private var showingParentArea = false

    private let columns = [GridItem(.adaptive(minimum: 140, maximum: 260), spacing: 28)]

    var body: some View {
        ScrollView {
            MascotView(mood: .waving)
                .frame(width: 120, height: 120)
                .padding(.top, 16)
            LazyVGrid(columns: columns, spacing: 28) {
                ForEach(session.profiles) { profile in
                    Button {
                        SpeechSynthesizer.shared.speak(Lines.greeting(for: profile.name))
                        session.select(profile)
                    } label: {
                        VStack(spacing: 12) {
                            AvatarBadge(avatar: profile.avatar, color: profile.color)
                            Text(profile.name)
                                .font(.heading(26))
                                .foregroundStyle(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(profile.name)
                }
            }
            .padding(32)
        }
        .safeAreaInset(edge: .bottom) {
            Button { showingParentArea = true } label: {
                Text("Grown-Ups")
                    .padding(.horizontal, 20)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .font(.system(.callout, design: .rounded, weight: .medium))
            .foregroundStyle(.primary)
            .padding(.bottom, 4)
        }
        .onAppear { SpeechSynthesizer.shared.speak(Lines.whoIsPlaying) }
        .sheet(isPresented: $showingParentArea) {
            GatedView(onCancel: { showingParentArea = false }) {
                ParentAreaView(onDone: { showingParentArea = false })
            }
        }
    }
}

/// First launch: a grown-up creates the first profile.
struct ProfileSetupView: View {
    @State private var started = false

    var body: some View {
        if started {
            GatedView(onCancel: { started = false }) {
                NavigationStack {
                    ProfileEditorView(profile: nil)
                }
            }
        } else {
            CenteredScrollView {
                VStack(spacing: 24) {
                    MascotView(mood: .waving)
                        .frame(width: 160, height: 160)
                    Text("Welcome to Day By Day")
                        .font(.heading(32))
                    Text("Set up a profile for your child.")
                        .font(.system(.title3, design: .rounded))
                    Button("Get Started") { started = true }
                        .buttonStyle(.borderedProminent)
                        .font(.system(.title2, design: .rounded, weight: .semibold))
                }
                .padding(40)
                .multilineTextAlignment(.center)
            }
        }
    }
}
