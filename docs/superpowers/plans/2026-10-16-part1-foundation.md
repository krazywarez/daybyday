# Part 1: Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Profiles, parent gate, answer log, sound engine, celebration, question engine with rounds, and the option-C home/hub navigation, with a unit test target.

**Architecture:** SwiftData models (`Profile`, `AnswerRecord`) behind a small `ProfileStore`. An `@Observable ProfileSession` holds the current child and decides when to show the picker. A pure question engine (`QuizItem`, `QuestionPicker`, `Round`) is driven by a generic `RoundView`. Sound effects are rendered to sample buffers by a pure `SoundSynth` and played by `SoundEngine` (AVAudioEngine). Home becomes a Today banner plus topic grid; each topic opens `CategoryHubView`.

**Tech Stack:** SwiftUI, SwiftData, AVFoundation (AVAudioEngine), Swift Testing, Xcode 27, `xcodeproj` Ruby gem (1.28.1, installed) for adding the test target.

**Spec:** `docs/superpowers/specs/2026-10-16-learning-games-design.md`

Parts 2–7 get their own plans, each written after the previous part merges.

## Global Constraints

- Effective deployment target is iOS 17.5. Use only APIs available on 17.5.
- Build settings: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, approachable concurrency on. Pure logic types that tests touch off the main actor must be `nonisolated`.
- New app files go under `DayByDay/` (file-system-synchronized group). New test files go under `DayByDayTests/`.
- No network, no analytics, no bundled image or audio files. All art in SwiftUI/SF Symbols, all sound synthesized at runtime.
- Nothing requires reading. Every child-facing prompt is spoken through `SpeechSynthesizer.shared.speak(_:)`.
- Wrong answers: soft sound plus spoken correction. No buzzer, no red X, no lost points.
- Rounds end with "You did it!" after 5 correct answers.
- Parent gate protects profile management. First-launch profile creation also goes through the gate.
- Profile picker: shown at launch when more than one profile exists, and on return to foreground after 10 or more minutes in the background. Skipped with exactly one profile. Avatar button in the home corner opens it, ungated.
- Weeks start on Sunday. The season is "Fall".
- Every commit message references the part 1 issue (`Ref #N`; the final one `Closes #N`). No AI attribution anywhere.
- Branch `feat/foundation` from `main`. Never push to `main`.

## Review Focus

1. Deleting the profile that is currently selected → session clears `current`; picker (or setup, if none remain) shows; that profile's answers are deleted with it. Test in Task 3 and Task 4.
2. Deleting the last profile → app returns to first-launch setup. Test in Task 4.
3. A child tapping repeatedly while feedback plays → only the first tap per question is recorded; further taps are ignored until the next question appears. Test in Task 2 (`Round` rejects answers while `isAwaitingNext`).
4. Reduce Motion on → confetti does not animate particles; celebration uses a fade only. Checked in Task 7.
5. Category with fewer items than the requested choice count, or a blank/whitespace profile name → picker clamps to the item count; setup refuses blank names. Tests in Task 2 and Task 3.

---

### Task 0: Branch and issue

- [ ] **Step 1:** `git checkout -b feat/foundation main`
- [ ] **Step 2:** Create the issue and note its number as `N` for all commit messages:

```bash
gitbay issue create --title "Part 1: foundation (profiles, question engine, sound, home hubs)" --file - <<'EOF'
Implements part 1 of docs/superpowers/specs/2026-10-16-learning-games-design.md.
Plan: docs/superpowers/plans/2026-10-16-part1-foundation.md
EOF
```

- [ ] **Step 3:** Commit the spec and this plan: `git add docs && git commit -m "docs: learning games design and part 1 plan" -m "Ref #N"`

### Task 1: Test target and quiz items

**Files:**
- Create: `scripts/add-test-target.rb` (run once, committed for reproducibility)
- Modify: `DayByDay.xcodeproj/project.pbxproj` (via script)
- Create: `DayByDay.xcodeproj/xcshareddata/xcschemes/DayByDay.xcscheme` (via script)
- Create: `DayByDay/Quiz/QuizItem.swift`
- Test: `DayByDayTests/QuizItemTests.swift`

**Interfaces:**
- Produces: `struct QuizItem: Identifiable, Hashable, Sendable { let id: String; let name: String; let category: Category }`; `extension Category { var quizItems: [QuizItem]; static var gridCases: [Category] }`. `id` is `"<category>.<case>"`, e.g. `"days.tuesday"`, built with `String(describing:)` on the enum case. `name` is the spoken name (`LearnLetter` uses `spokenName`).

- [ ] **Step 1:** Write `scripts/add-test-target.rb` using the `xcodeproj` gem: add a `DayByDayTests` unit-test bundle target (`com.apple.product-type.bundle.unit-test`) with `TEST_HOST`/`BUNDLE_LOADER` pointing at the app, deployment target 17.5, a file-system-synchronized root group for `DayByDayTests/`, and a shared `DayByDay` scheme whose test action includes `DayByDayTests`. If the gem cannot write a synchronized group for objectVersion 77, add the test files as regular file references instead.
- [ ] **Step 2:** Write the failing test:

```swift
import Testing
@testable import DayByDay

struct QuizItemTests {
    @Test func everyGridCategoryHasItems() {
        for category in Category.gridCases { #expect(!category.quizItems.isEmpty) }
    }
    @Test func gridExcludesToday() {
        #expect(!Category.gridCases.contains(.today))
        #expect(Category.gridCases.count == 11)
    }
    @Test func idsAreUniqueAndStable() {
        let all = Category.gridCases.flatMap(\.quizItems)
        #expect(Set(all.map(\.id)).count == all.count)
        #expect(Category.days.quizItems[2] == QuizItem(id: "days.tuesday", name: "Tuesday", category: .days))
    }
    @Test func lettersUseSpokenName() {
        #expect(Category.alphabet.quizItems.first?.name == "a")
    }
}
```

- [ ] **Step 3:** Run `ruby scripts/add-test-target.rb`, then `xcodebuild test -project DayByDay.xcodeproj -scheme DayByDay -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:DayByDayTests/QuizItemTests`. Expected: build fails, `quizItems` not found.
- [ ] **Step 4:** Implement `QuizItem.swift`: map each category to its enum (`DayOfWeek`, `MonthOfYear`, `Season`, `LearnNumber`, `LearnColor`, `LearnShape`, `LearnAnimal`, `LearnLetter`, `LearnWeather`, `LearnBodyPart`, `LearnFood`); `.today` returns `[]`.
- [ ] **Step 5:** Run the same test command. Expected: PASS.
- [ ] **Step 6:** Commit: `feat: add unit test target and quiz items` with `Ref #N`.

### Task 2: Question picker and round

**Files:**
- Create: `DayByDay/Quiz/Question.swift`, `DayByDay/Quiz/Round.swift`
- Test: `DayByDayTests/RoundTests.swift`

**Interfaces:**
- Consumes: `QuizItem`.
- Produces:
  - `struct Question: Equatable { let prompt: String; let choices: [QuizItem]; let answer: QuizItem }`
  - `struct QuestionPicker { var choiceCount: Int; var prompt: (QuizItem) -> String; func next(from items: [QuizItem], excluding previous: QuizItem?, using rng: inout some RandomNumberGenerator) -> Question }`. It picks the answer uniformly at random, never equal to `previous` when `items.count > 1`. Choices are the answer plus `min(choiceCount, items.count) - 1` distinct others, shuffled.
  - `enum AnswerOutcome: Equatable { case correct; case incorrect(correctName: String); case ignored }`
  - `struct Round { static let length = 5; init(items: [QuizItem], picker: QuestionPicker, rng: some RandomNumberGenerator); private(set) var current: Question; private(set) var correctCount: Int; private(set) var isAwaitingNext: Bool; var isFinished: Bool; mutating func answer(_ item: QuizItem) -> AnswerOutcome; mutating func advance() }`. A wrong answer keeps the same question (retry). A correct answer sets `isAwaitingNext = true`; any answer while awaiting returns `.ignored`. `advance()` picks the next question. `isFinished` when `correctCount == Round.length`.
  - Tests use a seeded generator: add `struct SeededGenerator: RandomNumberGenerator` (SplitMix64) in `DayByDayTests/SeededGenerator.swift`.

- [ ] **Step 1:** Write the failing tests:

```swift
@Test func choicesIncludeAnswerAndAreDistinct()     // 4 choices, contains answer, Set(choices).count == 4
@Test func choiceCountClampsToItemCount()           // Season (4 items), choiceCount 6 → 4 choices
@Test func neverRepeatsPreviousAnswer()             // 200 draws from days with previous set → answer != previous
@Test func promptUsesClosure()                      // prompt { "Can you find \($0.name)?" } → "Can you find Tuesday?" when answer is Tuesday
@Test func wrongAnswerRetriesSameQuestion()         // outcome == .incorrect(correctName: answer.name); current unchanged; correctCount == 0
@Test func tapsWhileAwaitingNextAreIgnored()        // correct, then any answer → .ignored; correctCount == 1
@Test func finishesAfterFiveCorrect()               // 5 × (answer correct, advance) → isFinished
```

- [ ] **Step 2:** Run `xcodebuild test ... -only-testing:DayByDayTests/RoundTests`. Expected: FAIL (types not defined).
- [ ] **Step 3:** Implement `Question.swift` and `Round.swift` per the interfaces. Mark both `nonisolated`.
- [ ] **Step 4:** Run the same command. Expected: PASS.
- [ ] **Step 5:** Commit: `feat: add question picker and round` with `Ref #N`.

### Task 3: Profiles and answer log

**Files:**
- Create: `DayByDay/Profiles/Profile.swift`, `DayByDay/Profiles/AnswerRecord.swift`, `DayByDay/Profiles/ProfileStore.swift`, `DayByDay/Profiles/Avatar.swift`
- Test: `DayByDayTests/ProfileStoreTests.swift`

**Interfaces:**
- Produces:
  - `enum AvatarAnimal: String, CaseIterable { cat, dog, bird, fish, rabbit, tortoise, ladybug, hare }` with `var symbol: String` (`"cat.fill"`, `"dog.fill"`, `"bird.fill"`, `"fish.fill"`, `"rabbit.fill"`, `"tortoise.fill"`, `"ladybug.fill"`, `"hare.fill"`) and `var spokenName: String`.
  - `enum ProfileColor: Int, CaseIterable` with 8 cases and `var color: Color`.
  - `@Model final class Profile { var id: UUID; var name: String; var avatarRaw: String; var colorRaw: Int; var birthdayMonth: Int?; var birthdayDay: Int?; var createdAt: Date; @Relationship(deleteRule: .cascade, inverse: \AnswerRecord.profile) var answers: [AnswerRecord] }` with computed `avatar: AvatarAnimal` and `color: ProfileColor`.
  - `@Model final class AnswerRecord { var categoryRaw: Int; var itemID: String; var isCorrect: Bool; var timestamp: Date; var profile: Profile? }`
  - `enum ProfileError: Error, Equatable { case blankName; case invalidBirthday }`
  - `final class ProfileStore { init(context: ModelContext); func all() -> [Profile]` (sorted by `createdAt`)`; func create(name: String, avatar: AvatarAnimal, color: ProfileColor, birthday: (month: Int, day: Int)?) throws -> Profile; func update(_ p: Profile, name: String, avatar: AvatarAnimal, color: ProfileColor, birthday: (month: Int, day: Int)?) throws; func delete(_ p: Profile); func record(_ item: QuizItem, correct: Bool, for p: Profile, at date: Date = .now); func answers(for p: Profile, category: Category?) -> [AnswerRecord] }`
  - Names are trimmed; blank → `.blankName`. Birthday day must be valid for the month in a leap year (Feb allows 29) → else `.invalidBirthday`.
  - `static func makeContainer(inMemory: Bool) -> ModelContainer` on `ProfileStore`.

- [ ] **Step 1:** Write the failing tests (all on an in-memory container):

```swift
@Test func createTrimsName()                 // "  Maya " → "Maya"
@Test func blankNameThrows()                 // "   " → ProfileError.blankName
@Test func birthdayValidation()              // (2, 29) ok; (2, 30) and (4, 31) and (13, 1) → .invalidBirthday
@Test func allSortedByCreation()
@Test func recordsAnswersPerProfile()        // record for Maya and Sam; answers(for: maya, category: .days).count == 1
@Test func deletingProfileDeletesAnswers()   // delete(maya) → no AnswerRecord rows with profile == nil remain
```

- [ ] **Step 2:** Run `xcodebuild test ... -only-testing:DayByDayTests/ProfileStoreTests`. Expected: FAIL.
- [ ] **Step 3:** Implement the files per the interfaces.
- [ ] **Step 4:** Run the same command. Expected: PASS.
- [ ] **Step 5:** Commit: `feat: add profiles and answer log` with `Ref #N`.

### Task 4: Profile session

**Files:**
- Create: `DayByDay/Profiles/ProfileSession.swift`
- Test: `DayByDayTests/ProfileSessionTests.swift`

**Interfaces:**
- Consumes: `Profile`, `ProfileStore`.
- Produces: `@Observable final class ProfileSession { static let pickerAfterBackground: TimeInterval = 600; var current: Profile?; init(store: ProfileStore); var screen: SessionScreen; func select(_ p: Profile); func didEnterBackground(at: Date); func willEnterForeground(at: Date); func profilesChanged() }` and `enum SessionScreen: Equatable { case setup, picker, home }`.
  - `screen`: no profiles → `.setup`; `current == nil` and one profile → auto-select it, `.home`; `current == nil` and several → `.picker`; otherwise `.home`.
  - `willEnterForeground` clears `current` when profile count > 1 and the background interval ≥ 600 s.
  - `profilesChanged()` clears `current` if it was deleted.

- [ ] **Step 1:** Write the failing tests:

```swift
@Test func noProfilesShowsSetup()
@Test func singleProfileAutoSelects()                  // screen == .home, current == only profile
@Test func multipleProfilesShowPicker()
@Test func shortBackgroundKeepsCurrent()               // 599 s → .home
@Test func longBackgroundShowsPickerWithSiblings()     // 600 s, 2 profiles → .picker
@Test func longBackgroundKeepsSoleProfile()            // 600 s, 1 profile → .home
@Test func deletingCurrentClearsIt()                   // delete current, profilesChanged() → .picker (2 left) / .home (1 left)
@Test func deletingLastProfileShowsSetup()
```

- [ ] **Step 2:** Run `-only-testing:DayByDayTests/ProfileSessionTests`. Expected: FAIL.
- [ ] **Step 3:** Implement `ProfileSession.swift`.
- [ ] **Step 4:** Run it. Expected: PASS.
- [ ] **Step 5:** Commit: `feat: add profile session` with `Ref #N`.

### Task 5: Parent gate

**Files:**
- Create: `DayByDay/Parent/ParentGate.swift` (logic), `DayByDay/Parent/ParentGateView.swift`
- Test: `DayByDayTests/ParentGateTests.swift`

**Interfaces:**
- Produces: `nonisolated struct ParentGateChallenge { let a: Int; let b: Int; var answer: Int { a + b }; static func random(using rng: inout some RandomNumberGenerator) -> ParentGateChallenge; func accepts(_ input: String) -> Bool }`. `a` and `b` in `6...9` (sums 12–18). `accepts` trims whitespace and compares as an integer. `static let holdDuration: TimeInterval = 2`.
- Produces: `struct ParentGateView: View { init(onPass: @escaping () -> Void, onCancel: @escaping () -> Void) }`. Step 1: a "Hold for grown-ups" button that must be held for `holdDuration` (progress ring fills while held; release resets). Step 2: shows "What is a + b?" as text with a number-pad field; correct entry calls `onPass`, wrong entry shows a new challenge.

- [ ] **Step 1:** Write failing tests: `operandsInRange` (1000 draws, both in 6...9), `acceptsCorrectSum` ("15", " 15 "), `rejectsWrong` ("14", "", "abc").
- [ ] **Step 2:** Run `-only-testing:DayByDayTests/ParentGateTests`. Expected: FAIL.
- [ ] **Step 3:** Implement `ParentGate.swift`, then `ParentGateView.swift`.
- [ ] **Step 4:** Run it. Expected: PASS. Then check the view in an Xcode preview or the simulator: the hold resets on early release, and a correct sum passes.
- [ ] **Step 5:** Commit: `feat: add parent gate` with `Ref #N`.

### Task 6: Sound synthesis and engine

**Files:**
- Create: `DayByDay/Sound/SoundSynth.swift`, `DayByDay/Sound/SoundEngine.swift`
- Test: `DayByDayTests/SoundSynthTests.swift`

**Interfaces:**
- Produces: `nonisolated enum SoundEffect: CaseIterable { case success, gentleMiss, tap, roundComplete }`; `nonisolated enum SoundSynth { static let sampleRate: Double = 44_100; static func render(_ effect: SoundEffect) -> [Float] }`; `final class SoundEngine { static let shared: SoundEngine; func play(_ effect: SoundEffect) }`.
  - Shaping: `success` is a rising major arpeggio (about 3 notes, about 0.4 s); `gentleMiss` is a soft, low, two-note falling tone (about 0.35 s, quieter than success); `tap` is a short click-free blip (under 0.08 s); `roundComplete` is a longer fanfare (about 1.2 s). Use sine plus soft harmonics with an attack/release envelope.
  - `SoundEngine` pre-renders every effect into an `AVAudioPCMBuffer` at init and plays it on an `AVAudioPlayerNode`. The audio session uses `.playback` like `SpeechSynthesizer`, plus `.mixWithOthers` so effects and speech overlap.

- [ ] **Step 1:** Write the failing tests, one parameterized over `SoundEffect.allCases`:

```swift
@Test(arguments: SoundEffect.allCases) func noClipping(_ e: SoundEffect)      // max(abs(sample)) <= 0.9
@Test(arguments: SoundEffect.allCases) func noClicks(_ e: SoundEffect)        // first and last 64 samples: abs < 0.01
@Test(arguments: SoundEffect.allCases) func notSilent(_ e: SoundEffect)       // RMS > 0.02
@Test func durations()                                                        // tap < 0.08 s; success 0.3–0.6 s; gentleMiss 0.25–0.5 s; roundComplete 0.9–1.6 s
@Test func missIsQuieterThanSuccess()                                         // RMS(gentleMiss) < RMS(success)
```

- [ ] **Step 2:** Run `-only-testing:DayByDayTests/SoundSynthTests`. Expected: FAIL.
- [ ] **Step 3:** Implement `SoundSynth.swift`, then `SoundEngine.swift`.
- [ ] **Step 4:** Run it. Expected: PASS.
- [ ] **Step 5:** Commit: `feat: add synthesized sound effects` with `Ref #N`.

### Task 7: Celebration and round view

**Files:**
- Create: `DayByDay/Quiz/PraisePhrases.swift`, `DayByDay/Quiz/CelebrationOverlay.swift`, `DayByDay/Quiz/RoundView.swift`
- Test: `DayByDayTests/PraisePhrasesTests.swift`

**Interfaces:**
- Consumes: `Round`, `QuestionPicker`, `QuizItem`, `SoundEngine`, `SpeechSynthesizer`, `ProfileStore.record`, `ProfileSession.current`.
- Produces:
  - `nonisolated struct PraisePhrases { static let all: [String]; mutating func next(using rng: inout some RandomNumberGenerator) -> String }`. At least 8 phrases ("Great job!", "You got it!", "Super!", "Way to go!", ...). Never returns the same phrase twice in a row. `static func correction(for name: String) -> String` returns `"That's \(name)! Try again."`.
  - `struct CelebrationOverlay: View { init(isActive: Bool) }`: confetti burst in Canvas/TimelineView, about 1 s. With `accessibilityReduceMotion`, a static sparkle that fades instead.
  - `struct RoundView<Choice: View>: View { init(items: [QuizItem], picker: QuestionPicker, @ViewBuilder choice: @escaping (QuizItem) -> Choice) }`. It speaks `current.prompt` on appear and on each new question, with a large replay-prompt button. On a tap it records via `ProfileStore.record` (skipped for `.ignored`). Correct: `SoundEngine.play(.success)`, overlay, speak praise, then `advance()` after 1.5 s. Incorrect: `.gentleMiss`, speak the correction, and that choice dims briefly. When finished it shows a "You did it!" screen with the mascot placeholder: it plays `.roundComplete`, speaks "You did it!", and offers a big "Play again" button plus back navigation.
  - `struct MascotView: View { enum Mood { case idle, cheering }; init(mood: Mood) }`: placeholder (simple face in a circle), replaced in part 6.

- [ ] **Step 1:** Write failing tests: `neverRepeatsConsecutively` (500 draws with seeded rng), `atLeastEightPhrases`, `correctionCopy` (`correction(for: "Thursday") == "That's Thursday! Try again."`).
- [ ] **Step 2:** Run `-only-testing:DayByDayTests/PraisePhrasesTests`. Expected: FAIL.
- [ ] **Step 3:** Implement `PraisePhrases.swift`, `CelebrationOverlay.swift`, `MascotView` (in `DayByDay/Mascot/MascotView.swift`), and `RoundView.swift`.
- [ ] **Step 4:** Run it. Expected: PASS. In the simulator, with a temporary preview using `Category.days.quizItems` and `DayCard`-styled choices: rapid taps after a correct answer don't double-record; with Settings › Accessibility › Motion › Reduce Motion on, confetti doesn't fly.
- [ ] **Step 5:** Commit: `feat: add celebration and round view` with `Ref #N`.

### Task 8: Profile picker, setup, and parent area

**Files:**
- Create: `DayByDay/Profiles/ProfilePickerView.swift`, `DayByDay/Profiles/ProfileEditorView.swift`, `DayByDay/Parent/ParentAreaView.swift`

**Interfaces:**
- Consumes: `ProfileSession`, `ProfileStore`, `ParentGateView`, `AvatarAnimal`, `ProfileColor`.
- Produces:
  - `ProfilePickerView`: a grid of large avatar tiles on the profile color. Tapping one speaks "Hi, <name>!" and calls `session.select`. A small grown-ups button opens `ParentGateView` → `ParentAreaView`.
  - `ProfileEditorView(profile: Profile?)`: name field, avatar grid, color swatches, optional birthday (month and day pickers, day range limited by month). Shows the `ProfileError` message inline.
  - `ParentAreaView`: lists profiles with add, edit, and delete (delete asks for confirmation). Calls `session.profilesChanged()` after any change.
  - The setup screen is `ParentGateView` → `ProfileEditorView(profile: nil)`, preceded by a short parent-facing line ("Set up a profile for your child").

- [ ] **Step 1:** Build: `xcodebuild build -project DayByDay.xcodeproj -scheme DayByDay -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`. Expected: `BUILD SUCCEEDED`.
- [ ] **Step 2:** In the simulator, check: create two profiles; the picker speaks the name; delete the current profile from the parent area → picker; delete all → setup.
- [ ] **Step 3:** Commit: `feat: add profile picker, editor, and parent area` with `Ref #N`.

### Task 9: Home and topic hubs

**Files:**
- Create: `DayByDay/Home/HomeView.swift`, `DayByDay/Home/TodayBanner.swift`, `DayByDay/Home/CategoryHubView.swift`
- Modify: `DayByDay/ContentView.swift` (routing by `session.screen`; keep `Category`, `CategoryTile`, `VoiceTipOverlay`), `DayByDay/DayByDayApp.swift` (model container, `ProfileSession` in the environment, scenePhase → `didEnterBackground`/`willEnterForeground`)

**Interfaces:**
- Consumes: everything above.
- Produces:
  - `TodayBanner`: `MascotView(mood: .idle)`, "Today is <day>!" and the date; tapping opens the existing `TodayView`.
  - `HomeView`: `TodayBanner`, then a `LazyVGrid` of `CategoryTile` over `Category.gridCases`. Current avatar button in the top-trailing corner opens the picker. "Voice Quality Tips" button kept.
  - `CategoryHubView(category:)`: large activity buttons, laid out the same way for every topic. Part 1 ships "Look and listen" (opens the existing per-category view). It has slots for "Find it!" (part 2) and the topic's special game (parts 3–4), hidden until those exist. Tapping a button also speaks its label.
  - `ContentView` switches on `session.screen`: `.setup` → setup flow, `.picker` → `ProfilePickerView`, `.home` → `HomeView` in the existing `NavigationStack`.

- [ ] **Step 1:** Build (same command as Task 8). Expected: `BUILD SUCCEEDED`.
- [ ] **Step 2:** Run the full suite: `xcodebuild test -project DayByDay.xcodeproj -scheme DayByDay -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`. Expected: `** TEST SUCCEEDED **`.
- [ ] **Step 3:** In the simulator (iPhone, then an iPad simulator, portrait and landscape), check: home shows the banner and 11 topics; a topic opens the hub; "Look and listen" shows the old cards and they still speak. Background the app for more than 10 minutes (`xcrun simctl` to advance, or temporarily lower the constant) with two profiles → picker on return.
- [ ] **Step 4:** Commit: `feat: add home banner and topic hubs` with `Ref #N`.

### Task 10: Art/sound review, MR, merge

- [ ] **Step 1:** Dispatch a fresh reviewer agent to review the art and sound in this branch: `SoundSynth` output (render each effect to a WAV in the scratchpad and inspect the waveform and spectrum), `CelebrationOverlay`, `MascotView` placeholder, avatars and colors, plus simulator screenshots. Block on clear defects (clipping, harsh or startling sound, unrecognizable drawing, poor contrast). Taste comments are advisory; after two rounds, note what's unresolved for the MR description.
- [ ] **Step 2:** Fix blocking findings and rerun the full suite. Expected: `** TEST SUCCEEDED **`.
- [ ] **Step 3:** Push and open the MR:

```bash
git push -u origin feat/foundation
gitbay mr create --source feat/foundation --target main --title "Part 1: foundation" --file - <<'EOF'
Profiles with parent gate, answer log, synthesized sound effects, celebration, question engine and rounds, home banner with topic hubs, unit test target.

Closes #N
EOF
```

- [ ] **Step 4:** Check CI with `gitbay build list` and `gitbay build log <n>` if present. When green, merge with `gitbay mr merge <mr> --strategy squash`, then `git checkout main && git pull && git branch -d feat/foundation && git push origin --delete feat/foundation`.
