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

            Section("Birthday") {
                Toggle("Add birthday", isOn: $hasBirthday)
                if hasBirthday {
                    Picker("Month", selection: $month) {
                        ForEach(1...12, id: \.self) { m in
                            Text(Calendar.current.monthSymbols[m - 1]).tag(m)
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
        .onChange(of: month) {
            day = min(day, ProfileStore.daysInMonth[month - 1])
        }
    }

    private func save() {
        let birthday = hasBirthday ? (month: month, day: day) : nil
        do {
            if let profile {
                try session.store.update(profile, name: name, avatar: avatar, color: color, birthday: birthday)
            } else {
                try session.store.create(name: name, avatar: avatar, color: color, birthday: birthday)
            }
            session.profilesChanged()
            dismiss()
        } catch let profileError as ProfileError {
            error = profileError
        } catch {}
    }
}
