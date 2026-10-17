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
                                .font(.system(size: 26, weight: .bold, design: .rounded))
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
            Button("Grown-Ups") { showingParentArea = true }
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.bottom, 12)
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
            VStack(spacing: 24) {
                MascotView(mood: .waving)
                    .frame(width: 160, height: 160)
                Text("Welcome to Day By Day")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text("Set up a profile for your child.")
                    .font(.system(size: 20, design: .rounded))
                    .foregroundStyle(.secondary)
                Button("Get Started") { started = true }
                    .buttonStyle(.borderedProminent)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
            }
            .padding(40)
            .multilineTextAlignment(.center)
        }
    }
}
