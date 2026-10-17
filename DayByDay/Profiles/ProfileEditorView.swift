//
//  ProfileEditorView.swift
//  DayByDay
//

import SwiftUI

/// Creates a profile (`profile == nil`) or edits an existing one.
struct ProfileEditorView: View {
    let profile: Profile?

    @Environment(ProfileSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var avatar: AvatarAnimal = .cat
    @State private var color: ProfileColor = .blue
    @State private var hasBirthday = false
    @State private var month = 1
    @State private var day = 1
    @State private var error: ProfileError?
    @State private var pictures: [DayOfWeek: DayPictureKind] = [:]

    private let avatarColumns = [GridItem(.adaptive(minimum: 64), spacing: 12)]

    init(profile: Profile?) {
        self.profile = profile
        if let profile {
            _name = State(initialValue: profile.name)
            _avatar = State(initialValue: profile.avatar)
            _color = State(initialValue: profile.color)
            _hasBirthday = State(initialValue: profile.birthdayMonth != nil)
            _month = State(initialValue: profile.birthdayMonth ?? 1)
            _day = State(initialValue: profile.birthdayDay ?? 1)
        }
    }

    var body: some View {
        Form {
            Section("Name") {
                TextField("Child's name", text: $name)
                    .textInputAutocapitalization(.words)
                if error == .blankName {
                    Text("Enter a name.").foregroundStyle(.red)
                }
            }

            Section("Animal") {
                LazyVGrid(columns: avatarColumns, spacing: 12) {
                    ForEach(AvatarAnimal.allCases) { option in
                        Button { avatar = option } label: {
                            AvatarBadge(avatar: option, color: color)
                                .overlay(Circle().strokeBorder(.primary, lineWidth: avatar == option ? 4 : 0))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(option.spokenName)
                        .accessibilityAddTraits(avatar == option ? .isSelected : [])
                    }
                }
                .padding(.vertical, 6)
            }

            Section("Color") {
                LazyVGrid(columns: avatarColumns, spacing: 12) {
                    ForEach(ProfileColor.allCases) { option in
                        Button { color = option } label: {
                            Circle()
                                .fill(option.color)
                                .frame(width: 52, height: 52)
                                .overlay(Circle().strokeBorder(.primary, lineWidth: color == option ? 4 : 0))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(String(describing: option))
                        .accessibilityAddTraits(color == option ? .isSelected : [])
                    }
                }
                .padding(.vertical, 6)
            }

            Section {
                ForEach(DayOfWeek.allCases) { day in
                    Picker(day.name, selection: Binding(
                        get: { pictures[day] },
                        set: { pictures[day] = $0 }
                    )) {
                        Text("None").tag(DayPictureKind?.none)
                        ForEach(DayPictureKind.allCases) { kind in
                            Label(kind.name.capitalized, systemImage: kind.symbol).tag(DayPictureKind?.some(kind))
                        }
                    }
                }
            } header: {
                Text("Day pictures")
            } footer: {
                Text("Shown on that day's card and said in the Today routine, e.g. \"Today is swim day!\"")
            }

            Section("Birthday") {
                Toggle("Add birthday", isOn: $hasBirthday)
                if hasBirthday {
                    Picker("Month", selection: $month) {
                        ForEach(1...12, id: \.self) { m in
                            Text(AppCalendar.current.monthSymbols[m - 1]).tag(m)
                        }
                    }
                    Picker("Day", selection: $day) {
                        ForEach(1...ProfileStore.daysInMonth[month - 1], id: \.self) { d in
                            Text("\(d)").tag(d)
                        }
                    }
                }
            }
        }
        .navigationTitle(profile == nil ? "New Child" : "Edit \(profile!.name)")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
            }
        }
        .onAppear {
            guard let profile, pictures.isEmpty else { return }
            for day in DayOfWeek.allCases {
                pictures[day] = session.store.picture(on: day, for: profile)
            }
        }
        .onChange(of: month) {
            day = min(day, ProfileStore.daysInMonth[month - 1])
        }
    }

    private func save() {
        let birthday = hasBirthday ? (month: month, day: day) : nil
        do {
            let saved: Profile
            if let profile {
                try session.store.update(profile, name: name, avatar: avatar, color: color, birthday: birthday)
                saved = profile
            } else {
                saved = try session.store.create(name: name, avatar: avatar, color: color, birthday: birthday)
            }
            for day in DayOfWeek.allCases {
                session.store.setPicture(pictures[day], on: day, for: saved)
            }
            session.profilesChanged()
            dismiss()
        } catch let profileError as ProfileError {
            error = profileError
        } catch {}
    }
}
