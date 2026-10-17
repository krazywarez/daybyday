# Part 5: Today Routine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A short spoken morning routine (greeting, birthday line, today/yesterday/tomorrow, day picture, month, season, pick today's weather) that ends with a weather sticker on a browsable month calendar, per child, plus parent-set day pictures shown on day cards and in the routine.

**Architecture:** Two new SwiftData models, `Sticker` and `DayPicture`, reference a child by `profileID` instead of a relationship, so the existing `Profile` entity is unchanged and earlier stores open with a purely additive schema change; `ProfileStore` deletes them with the profile. The routine's lines come from a pure `RoutineScript`; the calendar layout from a pure `MonthGrid`. Views: `TodayRoutineView` (step cards, weather pick, sticker award) reached from the home banner, `StickerCalendarView`, and a day-pictures section in the profile editor.

**Tech Stack:** SwiftUI, SwiftData, Swift Testing, Xcode 27.

**Spec:** `docs/superpowers/specs/2026-10-16-learning-games-design.md` (part 5). Builds on the part 1–4 plans in this folder.

## Global Constraints

- iOS 17.5 target; SF Symbols must be in SF Symbols 5; each new symbol gets a `UIImage(systemName:)` test.
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; pure logic `nonisolated`.
- No change to the `Profile` or `AnswerRecord` entities. New entities only. A store written by the current main build must open with the new container and keep its profiles (test in Task 1).
- One sticker per child per calendar day; finishing the routine again that day replaces the sticker's weather.
- Weeks start on Sunday. Seasons as in `MonthOfYear.season`. The weather pick is not a quiz: any choice is accepted.
- Every prompt spoken; the child never needs to read. Flat fills; every new fill with white content ≥ 3:1 in `ContrastTests`.
- Lifecycle: `generation` guard on every `asyncAfter`; `ZStack` for screen states; advance on speech completion with a step-scoped backstop.
- Day pictures are set behind the parent gate (profile editor), per child.
- Branch `feat/today-routine`. Every commit `Ref #N` (last `Closes #N`). No AI attribution.
- Test command: `xcodebuild test -project DayByDay.xcodeproj -scheme DayByDay -destination 'platform=iOS Simulator,name=iPhone 18 Pro'` (full suite ~10 min; run in background).

## Review Focus

1. Day boundaries: yesterday/tomorrow wrap at the week's ends and across month and year ends (Friday Jan 1, 2027 → "Yesterday was Thursday.", "It's January."). Test in Task 2.
2. Birthday lines: Feb 29 birthdays in non-leap years get the month line all February and no "today" line; birthday today beats birthday month. Test in Task 2.
3. Stickers: finishing twice the same day keeps one sticker; deleting a child removes their stickers and day pictures and no one else's. Test in Task 1.
4. A store from the previous build (profiles and answers only) opens with the new schema and keeps its data. Test in Task 1.
5. Calendar browsing never goes past the current month, and a month with no stickers still renders its grid. Test in Task 2 (`MonthGrid`) and Task 5.

---

### Task 0: Branch and issue

- [ ] `git checkout -b feat/today-routine main`; `gitbay issue create --title "Part 5: Today routine and sticker calendar" --json --file -`; commit this plan with `Ref #N`.

### Task 1: Stickers and day pictures in the store

**Files:** Create `DayByDay/Profiles/Sticker.swift`, `DayByDay/Profiles/DayPicture.swift`. Modify `ProfileStore.swift` (container types, methods, delete). Test `DayByDayTests/StickerStoreTests.swift`.

**Interfaces:**
- `@Model final class Sticker { var profileID: UUID; var year: Int; var month: Int; var day: Int; var weatherRaw: Int; var createdAt: Date }`.
- `nonisolated enum DayPictureKind: String, CaseIterable { swim, school, grandma, park, music, soccer, library, dance }` with `name` ("swim day", "school day", "grandma day", "park day", "music day", "soccer day", "library day", "dance day") and `symbol` (`figure.pool.swim`, `backpack.fill`, `heart.fill`, `tree.fill`, `music.note`, `soccerball`, `books.vertical.fill`, `figure.dance`).
- `@Model final class DayPicture { var profileID: UUID; var weekdayRaw: Int; var kindRaw: String }`.
- `ProfileStore.makeContainer` includes `Sticker` and `DayPicture`. New methods: `addSticker(for: Profile, on: DateComponents (year, month, day), weather: LearnWeather)` (upsert), `stickers(for: Profile, year: Int, month: Int) -> [Sticker]`, `sticker(for: Profile, on:) -> Sticker?`, `setPicture(_ kind: DayPictureKind?, on: DayOfWeek, for: Profile)` (nil removes), `picture(on: DayOfWeek, for: Profile) -> DayPictureKind?`. `delete(_:)` also deletes the profile's stickers and pictures.

- [ ] Tests: `stickerUpsertsPerDay`, `stickersByMonth`, `picturesSetReplaceRemove`, `deleteRemovesOnlyThatChildsData`, `pictureSymbolsExist`, `oldStoreOpens` (create an on-disk store at a temp URL with a container of `Profile` and `AnswerRecord` only, insert a profile and an answer, drop it, open the same URL with `makeContainer`'s full type list, expect the profile and answer). RED, implement, GREEN, commit `feat: stickers and day pictures`.

### Task 2: Routine script and month grid

**Files:** Create `DayByDay/Today/RoutineScript.swift`, `DayByDay/Today/MonthGrid.swift`. Test `DayByDayTests/RoutineScriptTests.swift`, `DayByDayTests/MonthGridTests.swift`.

**Interfaces:**
- `nonisolated struct RoutineScript { struct Line: Equatable { let text: String; let symbol: String } ; init(date: Date, calendar: Calendar, name: String?, birthday: (month: Int, day: Int)?, picture: DayPictureKind?); let lines: [Line] }`. Order:
  1. `"Hi, \(name)!"` (or `"Hi!"`), symbol `sun.max.fill`.
  2. Birthday today: `"Today is your birthday! Happy birthday!"` (`birthday.cake.fill`); else birthday month: `"Your birthday is in \(Month)!"` (`gift.fill`). Feb 29 birthdays count as "today" only on Feb 29.
  3. `"Today is \(Day)."` (that day's `DayOfWeek.symbol`); then, if a picture is set for today, `"Today is \(picture.name)!"` (picture symbol).
  4. `"Yesterday was \(Day)."`, 5. `"Tomorrow is \(Day)."` (day symbols).
  6. `"It's \(Month)."` (month symbol), 7. `"It's \(Season)."` (season symbol).
- `nonisolated struct MonthGrid { init(year: Int, month: Int, calendar: Calendar); let leadingBlanks: Int (Sunday-first); let days: Int; var cells: [Int?] (blanks then 1…days); func shifted(by months: Int) -> MonthGrid }`.

- [ ] Tests with a Gregorian calendar fixed to UTC: `fridayScript` (2026-10-16, "Maya", no birthday, no picture → the 7 lines exactly), `birthdayMonthLine`, `birthdayTodayBeatsMonth`, `leapBirthday` (Feb 29 birthday on 2027-02-28 → month line only; on 2028-02-29 → today line), `pictureLine`, `weekWraps` (2026-10-18 Sunday → yesterday Saturday; 2026-10-17 Saturday → tomorrow Sunday), `yearEnd` (2027-01-01 → "It's January.", yesterday Thursday), `octoberGrid` (2026-10: 4 blanks, 31 days), `februaryGrids` (2027: 28, 2028: 29), `shiftAcrossYear` (2026-12 shifted by 1 → 2027-01). RED, implement, GREEN, commit `feat: routine script and month grid`.

### Task 3: Day pictures for parents and on day cards

**Files:** Modify `DayByDay/Profiles/ProfileEditorView.swift` (section), `DayByDay/DayCard.swift` (flat fill + badge), `DayByDay/DaysOfWeekView.swift`. Test `ContrastTests`.

**Interfaces:**
- Profile editor (existing profiles only): section "Day pictures" with a picker per weekday (None + each kind, symbol and name), saving through `setPicture`.
- `DayCard(day:isHighlighted:picture:)`: flat fill; `DayOfWeek.color` changed to values ≥ 3:1 against white; when `picture` is set, a white badge circle with the picture symbol in the day color sits in the top-trailing corner, and tapping says `"\(Day). It's \(picture.name)!"` instead of the day name.
- `DaysOfWeekView` reads the current profile's pictures from the session.

- [ ] Test `dayColorAgainstWhite` over all days. RED, implement, GREEN, render, commit `feat: day pictures`.

### Task 4: Today routine screen

**Files:** Create `DayByDay/Today/TodayRoutineView.swift`. Modify `DayByDay/Home/HomeView.swift`, `DayByDay/Home/TodayBanner.swift`.

**Interfaces:**
- `TodayRoutineView`: one large step card at a time (symbol 120 pt, the line in large text on the today color), spoken on appear; a big "next" arrow button advances (and "Hear it again"). After the last line: `"What's the weather like today?"` with `ChoiceTile`s for sunny, cloudy, rainy, snowy, windy. Any tap: `.success`, `"It's \(weather) today! Here's your sticker!"`, `addSticker(today, weather)`, then `StickerCalendarView` for the current month with today's sticker, plus "Play again" style "Done" back navigation. Without a current profile (cannot happen past the picker) the routine still runs and skips the sticker.
- Home banner links to `TodayRoutineView`; its subtitle line shows "Tap for your sticker!" until today's sticker exists, then a small sticker in today's weather.

- [ ] Build, render (steps and weather pick), commit `feat: today routine`.

### Task 5: Sticker calendar

**Files:** Create `DayByDay/Today/StickerCalendarView.swift`.

**Interfaces:**
- `StickerCalendarView(profile:, year:, month:)`: month name and year header with back/forward arrows (forward disabled at the current month); weekday initials row; 7-column grid from `MonthGrid`; each day cell shows its number, today outlined, and a sticker (weather symbol, white, in a circle of `Category.weather.color`) when present. Tapping a stickered day says `"On October 3, it was sunny."`.

- [ ] Build, render a month with stickers and an empty month, commit `feat: sticker calendar`.

### Task 6: Reviews, MR, merge

- [ ] Extend `ReviewExport`. Fresh art/sound reviewer (two rounds max). Fresh whole-branch code reviewer with this Review Focus. One fix pass, RED→GREEN. Full suite green. Push, MR `Closes #N`, squash-merge, delete branch.
