# Part 2: Question Games Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** "Find it!" for all 11 grid topics, odd one out for food, animals and shapes, and listen-and-pick for animals, weather, alphabet and numbers, reached from each topic hub.

**Architecture:** `Round` runs any `QuestionSource`: `QuestionPicker` (find it and listen-and-pick, with separate answer and distractor pools and a choice count that grows from 3 to 4 within a round) or `OddOneOut` (two groups, one odd choice). A `Game` enum plus `Category.games` and `Category.questionSource(for:)` hold the per-topic catalog and spoken copy. `RoundView` plays a question's sound cue before the prompt and records the chosen item and game. Choices render through one `ChoiceTile` with flat fills. Animal, weather and beep sounds are synthesized by `SoundSynth` (additive voice with formants, filtered noise) and rendered lazily by `SoundEngine`.

**Tech Stack:** SwiftUI, SwiftData, AVFoundation, Swift Testing, Xcode 27.

**Spec:** `docs/superpowers/specs/2026-10-16-learning-games-design.md` (part 2). Builds on `docs/superpowers/plans/2026-10-16-part1-foundation.md`.

## Global Constraints

- Effective deployment target is iOS 17.5. SF Symbols used must exist on iOS 17. There are no cow, pig, sheep or duck symbols; those are drawn with SwiftUI paths.
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Pure logic types are `nonisolated`.
- New app files under `DayByDay/`, new test files under `DayByDayTests/`.
- No bundled image or audio files. All sound synthesized at runtime; all art in SwiftUI shapes, SF Symbols, or the emoji the food cards already use.
- Nothing requires reading. Every prompt is spoken; every choice is a picture, color, numeral or letter shape. Days, months and seasons tiles show their symbol and name, as the existing cards do.
- Wrong answers: `.gentleMiss` plus spoken correction. No buzzer, no red X.
- Round length stays 5 correct answers. Choices: 3 for the first two questions, 4 after that.
- Choice tiles do not reuse `DayCard`, `MonthCard`, `SeasonCard` or any other `*Card`; they use flat fills with content at 3:1 or better, covered in `ContrastTests`.
- Branch `feat/question-games` from `main`. Every commit `Ref #N` (the last `Closes #N`). No AI attribution anywhere.
- Test command: `xcodebuild test -project DayByDay.xcodeproj -scheme DayByDay -destination 'platform=iOS Simulator,name=iPhone 18 Pro'` (add `-only-testing:DayByDayTests/<Suite>` per task).

## Review Focus

1. Odd one out never has two valid answers: exactly one choice is outside the majority group, for every category and choice count. Test in Task 4 (`oddOneOutHasExactlyOneOddChoice`, 300 draws per category).
2. A topic whose answer pool is smaller than the choice count (weather listen has 3 answers; seasons has 4 items) still yields distinct choices and never repeats the previous answer. Tests in Task 3 and Task 4.
3. Tapping "Hear it again" while a sound cue is still playing does not stack the sound or clip; the prompt follows the cue rather than overlapping it. `SoundEngine` skips a repeat of a playing effect (part 1); the replay schedules speech after the cue's duration. Checked by hand in Task 6.
4. Answer history from part 1 keeps loading after `AnswerRecord` gains fields (lightweight migration of optional properties). Checked in Task 5 by launching the part 1 build, answering a question, then installing this build over it.
5. Renaming an item enum case orphans recorded history. Pin every item ID in a test (Task 1).

---

### Task 0: Branch and issue

- [ ] **Step 1:** `git checkout -b feat/question-games main`
- [ ] **Step 2:** Create the issue, note its number as `N` (it is #2):

```bash
gitbay issue create --title "Part 2: question games (find it, odd one out, listen and pick)" --file - <<'EOF'
Implements part 2 of docs/superpowers/specs/2026-10-16-learning-games-design.md.
Plan: docs/superpowers/plans/2026-10-16-part2-question-games.md
EOF
```

- [ ] **Step 3:** `git add docs && git commit -m "docs: part 2 plan" -m "Ref #N"`

### Task 1: Item sets, attributes, drawn animals

**Files:**
- Modify: `AnimalCard.swift` (enum and card icon), `FoodCard.swift`, `ShapeCard.swift`, `LetterCard.swift` (attributes only)
- Modify: `DayByDay/Quiz/QuizItem.swift`
- Create: `DayByDay/Quiz/AnimalIcon.swift`
- Test: `DayByDayTests/QuizItemTests.swift`

**Interfaces:**
- Produces:
  - `LearnAnimal` cases in this order: `cat, dog, bird, fish, rabbit, turtle, ladybug, cow, duck, sheep, pig` (ant and lizard removed). New names "Cow", "Duck", "Sheep", "Pig"; colors cow `(0.35, 0.38, 0.45)`, duck `(0.95, 0.75, 0.2)`, sheep `(0.55, 0.6, 0.7)`, pig `(0.95, 0.5, 0.65)`. `var symbol: String?` (nil for the four drawn animals). `var canFly: Bool` (bird, duck, ladybug).
  - `LearnFood.isFruit: Bool` (false for carrot, broccoli, corn).
  - `LearnShape.hasCorners: Bool?` (false for circle and oval, nil for heart, true otherwise).
  - `LearnLetter.exampleWord: String`: apple, ball, cat, dog, egg, fish, goat, hat, igloo, jam, kite, lion, moon, nest, octopus, pig, queen, rain, sun, tiger, umbrella, van, web, fox, yo-yo, zebra.
  - `struct AnimalIcon: View { init(animal: LearnAnimal) }`: the SF Symbol, or a white silhouette drawn in a `Canvas` filled with `.foreground` with details cut out (`blendMode = .destinationOut`), so it takes `foregroundStyle` like a symbol. Pig: front face, triangle ears, snout with nostrils. Cow: front face with horns, side ears, wide muzzle with nostrils, one spot. Sheep: side view, cloud body of overlapping circles, four legs, head. Duck: side view, body with raised tail, round head, beak, wing line. `AnimalCard` uses it.
  - `extension Category { func item(_ value: some CaseIterable) -> QuizItem }` (looks up by `"\(key).\(value)"`) and `extension QuizItem { func value<T: CaseIterable>(_: T.Type) -> T? }`.

- [ ] **Step 1:** Write failing tests:

```swift
@Test(arguments: Category.gridCases) func idsArePinned(_ c: Category)
// expected case names per category, space-separated, e.g.
// .animals: "cat dog bird fish rabbit turtle ladybug cow duck sheep pig"
// #expect(c.quizItems.map(\.id) == names.split(separator: " ").map { "\(c.key).\($0)" })
@Test func itemAndValueRoundTrip()   // Category.animals.item(LearnAnimal.cow).value(LearnAnimal.self) == .cow; .name == "Cow"
@Test func flyers()                  // LearnAnimal.allCases.filter(\.canFly) == [.bird, .ladybug, .duck]
@Test func vegetables()              // LearnFood.allCases.filter { !$0.isFruit } == [.carrot, .broccoli, .corn]
@Test func roundShapes()             // filter { $0.hasCorners == false } == [.circle, .oval]; LearnShape.heart.hasCorners == nil
@Test func exampleWordsStartWithTheirLetter() // every letter except x: exampleWord.first == character.lowercased().first
```

- [ ] **Step 2:** Run `-only-testing:DayByDayTests/QuizItemTests`. Expected: build fails.
- [ ] **Step 3:** Implement. Draw each animal in a 100×100 unit space scaled to the canvas; keep holes at least 6 units wide so they read at 64 pt.
- [ ] **Step 4:** Run. Expected: PASS.
- [ ] **Step 5:** Commit `feat: revise animal set and add item attributes` with `Ref #N`.

### Task 2: Synthesized cue sounds

**Files:**
- Modify: `DayByDay/Sound/SoundSynth.swift`, `DayByDay/Sound/SoundEngine.swift`
- Test: `DayByDayTests/SoundSynthTests.swift`

**Interfaces:**
- Produces:
  - `nonisolated enum SoundEffect: Hashable, CaseIterable { case success, gentleMiss, roundComplete, moo, quack, baa, oink, meow, woof, tweet, rain, wind, thunder, beeps(Int) }` with `allCases` listing `beeps(1)...beeps(5)`. `.tap` is removed (unused).
  - `SoundSynth.render(_:) -> [Float]` for every case; `SoundSynth.duration(_:) -> Double`.
  - `SoundEngine.play(_:)` renders and attaches a player on first use of an effect (no startup render of everything). `SoundEngine.duration(_:) -> TimeInterval`.
- Approach: animals are an additive voice: a time-varying f0, harmonics up to 8 kHz weighted by `1/√n` and by Gaussian formant peaks interpolated between vowel targets over time, optional vibrato and tremolo, optional seeded noise. Weather is seeded noise through one- and two-pole filters (rain: high-passed hiss plus soft windowed droplets; wind: band-pass with a slowly moving center and a swell; thunder: low-passed brown noise with a soft 80 ms attack and two rolling swells, DC-blocked). Beeps: `n` notes at 660 Hz, 0.12 s each, 0.42 s apart. Animal targets: moo f0 110→140→100 Hz, 1.2 s, "oo-ah-oo"; meow 450→700→450 Hz, 0.7 s, "ee-ah-oo"; baa ~330 Hz, 7 Hz vibrato and tremolo, 0.8 s; quack two 0.18 s nasal bursts ~220→180 Hz; oink two 0.2 s grunts 140→110 Hz with 30 Hz roughness; woof two 0.18 s barks 300→180 Hz; tweet three 0.09 s sine sweeps 2.5→4.2 kHz then a short warble.
  - `roundComplete`: give the arpeggio notes a gain so its peak is at least half the chord's.

- [ ] **Step 1:** Write failing tests (existing `noClipping`, `noClicks`, `notSilent` now run over the new cases too):

```swift
@Test(arguments: SoundEffect.allCases) func noDCOffset(_ e)       // abs(mean) < 0.01
@Test func cueDurations()   // animals 0.35...1.6 s; rain, wind, thunder 1.5...2.6 s; beeps(n) == 0.42*(n-1)+0.12 ± 0.02
@Test(arguments: 1...5) func beepCountMatches(_ n: Int)   // onsets: count of 10 ms windows whose rms rises above 0.1 after being below 0.02 == n
@Test func brightAndDarkCues()  // zeroCrossingRate(.tweet) > 5 * zeroCrossingRate(.moo); zeroCrossingRate(.thunder) < zeroCrossingRate(.rain) / 5
@Test func arpeggioNotDrownedByChord() // roundComplete: peak of first 0.38 s >= 0.5 * peak of the rest
@Test func thunderIsGentle()    // no sample in the first 50 ms above 0.2; peak <= 0.6
```

- [ ] **Step 2:** Run `-only-testing:DayByDayTests/SoundSynthTests`. Expected: build fails.
- [ ] **Step 3:** Implement `SoundSynth` and lazy `SoundEngine`.
- [ ] **Step 4:** Run. Expected: PASS.
- [ ] **Step 5:** Commit `feat: synthesize animal, weather and beep cues` with `Ref #N`.

### Task 3: Question sources

**Files:**
- Modify: `DayByDay/Quiz/Question.swift`, `DayByDay/Quiz/Round.swift`
- Test: `DayByDayTests/RoundTests.swift`

**Interfaces:**
- Consumes: `QuizItem`, `SoundEffect`.
- Produces:
  - `nonisolated struct Question: Equatable { let prompt: String; let choices: [QuizItem]; let answer: QuizItem; var sound: SoundEffect? = nil; var facts: [QuizItem: String] = [:]; func correction(for tapped: QuizItem) -> String }`. `correction` returns `"\(facts[tapped]!) Try again!"` when a fact exists, else `PraisePhrases.correction(for: answer.name)`.
  - `nonisolated protocol QuestionSource { func next(correctCount: Int, excluding previous: QuizItem?, using rng: inout some RandomNumberGenerator) -> Question }`
  - `QuestionPicker: QuestionSource { init(answers: [QuizItem], distractors: [QuizItem]? = nil, prompt: @escaping (QuizItem) -> String, sound: @escaping (QuizItem) -> SoundEffect? = { _ in nil }) }`. Answer from `answers`, never `previous` when another exists; distractors from `distractors ?? answers` minus the answer; count `min(Round.choiceCount(correctCount:), pool size)`. `precondition(!answers.isEmpty)`.
  - `OddOneOut: QuestionSource { struct Group { let members: [QuizItem]; let fact: (QuizItem) -> String }; init(_ a: Group, _ b: Group) }`. Prompt `"Which one is different?"`. Picks an orientation (majority, odd) at random among those where the majority has at least `k - 1` members, lowering `k` to 3 if neither fits; odd answer never `previous` when possible; `facts` holds each choice's group fact.
  - `Round`: `init(source: any QuestionSource, rng: some RandomNumberGenerator = SystemRandomNumberGenerator())`; `static func choiceCount(correctCount: Int) -> Int` (3 below 2, else 4). The `items:picker:` initializer goes away.

- [ ] **Step 1:** Update `RoundTests` to build rounds from `QuestionPicker(answers: days) { "Can you find \($0.name)?" }` and add:

```swift
@Test func choicesGrowWithinRound()        // counts over 5 correct answers: [3, 3, 4, 4, 4]
@Test func distractorsComeFromTheirPool()  // answers = first 3 days, distractors = all days → answer ∈ first 3, choices ⊂ days, 300 draws
@Test func smallAnswerPoolStillVaries()    // answers of 2 items, 100 draws with previous → answer != previous
@Test func soundComesFromClosure()          // sound: { _ in .moo } → question.sound == .moo
@Test func correctionUsesFactWhenPresent()  // facts [apple: "Apple is a fruit."] → correction(for: apple) == "Apple is a fruit. Try again!"; for another item → "That's \(answer.name)! Try again."
@Test func oddOneOutShape()                 // fruits vs vegetables: 300 draws × correctCount 0 and 4 → exactly one choice from the answer's group, the rest from the other; facts.count == choices.count
@Test func oddOneOutFallsBackToThree()      // groups of 2 and 2 at correctCount 4 → 3 choices
```

- [ ] **Step 2:** Run `-only-testing:DayByDayTests/RoundTests`. Expected: build fails.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run. Expected: PASS.
- [ ] **Step 5:** Commit `feat: add question sources with growing choices and odd one out` with `Ref #N`.

### Task 4: Game catalog

**Files:**
- Create: `DayByDay/Quiz/Game.swift`
- Test: `DayByDayTests/GameTests.swift`

**Interfaces:**
- Consumes: Task 1 attributes, `QuestionPicker`, `OddOneOut`, `SoundEffect`.
- Produces:
  - `nonisolated enum Game: String, CaseIterable { case findIt, oddOneOut, listen; var title: String; var symbol: String }`. Titles "Find it!", "Odd one out", "Listen"; symbols `magnifyingglass`, `square.grid.2x2.fill`, `ear.fill`.
  - `extension Category { var games: [Game]; func questionSource(for game: Game) -> any QuestionSource }`.
  - Find it, all grid topics. Prompt `"Can you find \(x)?"` where x is `"the letter \(name)"` (alphabet), `"the number \(name)"` (numbers), `"the \(name)"` (animals, food, shapes, body), else `name`.
  - Odd one out: food (fruit / vegetable, facts "\(name) is a fruit." / "\(name) is a vegetable."), animals (can fly / can't fly, "\(name) can fly." / "\(name) can't fly."), shapes without heart (round / corners, "\(name) is round." / "\(name) has corners.").
  - Listen: animals with a sound (cat meow, dog woof, bird tweet, cow moo, duck quack, sheep baa, pig oink) as both pools, prompt "Who says this?"; weather answers rainy (rain), windy (wind), stormy (thunder), distractors all weather, prompt "What weather sounds like this?"; numbers one through five, sound `.beeps(n)`, prompt "How many beeps?"; alphabet without k, q, x, no sound, prompt `"Which letter does \(exampleWord) start with?"`.

- [ ] **Step 1:** Write failing tests:

```swift
@Test func catalog()  // every grid topic has .findIt first; oddOneOut exactly for [.animals, .shapes, .food]; listen exactly for [.numbers, .animals, .alphabet, .weather]
@Test(arguments: Category.gridCases) func everyGameMakesValidQuestions(_ c: Category)
// for each game, 300 draws at correctCount 0...4: choices distinct, contain answer, count in 3...4 (or the pool size if smaller), prompt not empty
@Test(arguments: [Category.animals, .shapes, .food]) func oddOneOutHasExactlyOneOddChoice(_ c: Category)
// using the category's attribute: exactly one choice disagrees with the others
@Test func listenCues()  // animals: every answer has a sound; weather: answers ⊂ {rainy, windy, stormy}; numbers: sound == .beeps(numeral); alphabet: no k/q/x, prompt contains exampleWord, sound nil
@Test func findItPromptCopy() // "Can you find the letter b?", "Can you find the number Three?", "Can you find the Cow?", "Can you find Tuesday?"
```

- [ ] **Step 2:** Run `-only-testing:DayByDayTests/GameTests`. Expected: build fails.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run. Expected: PASS.
- [ ] **Step 5:** Commit `feat: add game catalog per topic` with `Ref #N`.

### Task 5: Answer log fields

**Files:**
- Modify: `DayByDay/Profiles/AnswerRecord.swift`, `DayByDay/Profiles/ProfileStore.swift`
- Test: `DayByDayTests/ProfileStoreTests.swift`

**Interfaces:**
- Produces: `AnswerRecord.chosenID: String?`, `AnswerRecord.gameRaw: String?` (both default nil, so existing stores migrate). `ProfileStore.record(_ item: QuizItem, chosen: QuizItem? = nil, game: Game? = nil, correct: Bool, for: Profile, at: Date = .now)`.

- [ ] **Step 1:** Failing test `recordsChosenItemAndGame`: record answer Tuesday, chosen Monday, game `.findIt`, correct false → stored `chosenID == "days.monday"`, `gameRaw == "findIt"`. Existing call sites without the new arguments still compile.
- [ ] **Step 2:** Run `-only-testing:DayByDayTests/ProfileStoreTests`. Expected: FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run. Expected: PASS. Then: install the `main` build in the simulator, answer a question, install this branch's build over it, open the app: no crash, profile still there.
- [ ] **Step 5:** Commit `feat: record chosen item and game per answer` with `Ref #N`.

### Task 6: Choice tiles, round view, hub

**Files:**
- Create: `DayByDay/Quiz/ChoiceTile.swift`
- Modify: `DayByDay/Quiz/RoundView.swift`, `DayByDay/Home/CategoryHubView.swift`
- Test: `DayByDayTests/ContrastTests.swift`

**Interfaces:**
- Consumes: Tasks 1–5.
- Produces:
  - `enum ChoiceStyle { static let foodFill: Color; static let swatchOutline: Color }`. `foodFill` `(0.24, 0.16, 0.10)`; `swatchOutline` `Color(white: 0.45)`.
  - `struct ChoiceTile: View { init(item: QuizItem) }`: rounded rect, corner 32, flat fill. Colors: the color itself as fill with a 4 pt `swatchOutline` border, no text. Food: emoji at 72 pt on `foodFill`. Every other topic: white content on `category.color`: animals `AnimalIcon`, weather/body symbol, shapes `shapeView`, alphabet the letter at 72 pt heavy rounded, numbers numeral plus solid white `DotPattern`-style dots, days/months/seasons symbol plus name.
  - `RoundView<Choice>`: `init(source: any QuestionSource, game: Game, @ViewBuilder choice:)`. Prompt: if `current.sound` is set, play it, then speak the prompt `SoundEngine.duration + 0.2` s later; "Hear it again" does the same. Records `round.current.answer` with `chosen: tapped`, `game:`. Correct: `.success` now, praise 0.25 s later, advance after 1.8 s. Incorrect: `.gentleMiss` now, `current.correction(for: tapped)` 0.25 s later. "You did it!" spoken 0.4 s after `.roundComplete`.
  - `CategoryHubView`: one large button per `category.games` after "Look and listen", same style, destination `RoundView(source: category.questionSource(for: game), game: game) { ChoiceTile(item: $0) }.navigationTitle(game.title)`.

- [ ] **Step 1:** Failing tests in `ContrastTests`: `swatchOutlineAgainstBackgrounds` (vs `.white` and `.black` ≥ 3), `foodFillAgainstWhite` (≥ 3). Run `-only-testing:DayByDayTests/ContrastTests`. Expected: build fails.
- [ ] **Step 2:** Implement `ChoiceTile`, `RoundView`, hub.
- [ ] **Step 3:** Run the full suite. Expected: `** TEST SUCCEEDED **`.
- [ ] **Step 4:** In the simulator: each hub shows its games; play one round each of find it (days, colors, food), odd one out (animals), listen (animals, numbers, alphabet, weather); "Hear it again" during a cue does not stack; a wrong odd-one-out tap speaks the tapped item's fact. iPad landscape layout holds four tiles.
- [ ] **Step 5:** Commit `feat: play find it, odd one out and listen from topic hubs` with `Ref #N`.

### Task 7: Review exports, reviews, MR, merge

**Files:**
- Create: `DayByDayTests/ReviewExport.swift`

- [ ] **Step 1:** Add `ReviewExport`, enabled only when `EXPORT_DIR` is set (`TEST_RUNNER_EXPORT_DIR` on the xcodebuild command line): writes every `SoundEffect` as 16-bit WAV and every `ChoiceTile` (all items, light and dark), `AnimalIcon` and hub as PNG via `ImageRenderer` at scale 2.
- [ ] **Step 2:** Run it into the scratchpad. Dispatch a fresh art/sound reviewer with the PNGs, WAVs and source. Block on clear defects (clipping, clicks, harsh or startling sound, unrecognizable drawing, contrast under 3:1). Fix, rerun, second round at most. Unresolved taste notes go in the MR description.
- [ ] **Step 3:** Fresh whole-branch code review (`git diff main...`). Fix findings that hold up.
- [ ] **Step 4:** Full suite. Expected: `** TEST SUCCEEDED **`.
- [ ] **Step 5:** `git push -u origin feat/question-games`; `gitbay mr create --source feat/question-games --target main --title "Part 2: question games" --file -` with a short body ending `Closes #N`.
- [ ] **Step 6:** `gitbay mr merge <mr> --strategy squash`; `git checkout main && git pull && git branch -D feat/question-games && git push origin --delete feat/question-games`; confirm `gitbay issue show N` is closed (close it if not).

## Deferred

- `VersionedSchema`: the two new fields are optional, so automatic lightweight migration covers them. Adopt a versioned schema in part 7 before any non-optional change.
