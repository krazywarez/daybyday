//
//  ParentAreaView.swift
//  DayByDay
//

import SwiftUI

/// Grown-up screen for adding, editing, and deleting profiles, and for
/// each child's progress.
struct ParentAreaView: View {
    let onDone: () -> Void

    @Environment(ProfileSession.self) private var session
    @State private var pendingDelete: Profile?

    var body: some View {
        NavigationStack {
            List {
                Section("Children") {
                    ForEach(session.profiles) { profile in
                        NavigationLink {
                            ProfileEditorView(profile: profile)
                        } label: {
                            ProfileRow(profile: profile)
                        }
                        .swipeActions {
                            Button("Delete", role: .destructive) { pendingDelete = profile }
                        }
                    }
                    NavigationLink {
                        ProfileEditorView(profile: nil)
                    } label: {
                        Label("Add a child", systemImage: "plus.circle.fill")
                    }
                }
                if !session.profiles.isEmpty {
                    Section("Progress") {
                        ForEach(session.profiles) { profile in
                            NavigationLink {
                                ChildProgressView(profile: profile)
                            } label: {
                                ProfileRow(profile: profile)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Grown-Ups")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDone)
                }
            }
            .confirmationDialog(
                "Delete \(pendingDelete?.name ?? "")?",
                isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("Delete Profile and Progress", role: .destructive) {
                    if let profile = pendingDelete {
                        session.store.delete(profile)
                        session.profilesChanged()
                    }
                    pendingDelete = nil
                }
            } message: {
                Text("This removes their stickers and progress. It can't be undone.")
            }
        }
    }
}

private struct ProfileRow: View {
    let profile: Profile

    var body: some View {
        HStack(spacing: 14) {
            AvatarBadge(avatar: profile.avatar, color: profile.color)
                .frame(width: 44, height: 44)
            Text(profile.name)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
        }
    }
}
