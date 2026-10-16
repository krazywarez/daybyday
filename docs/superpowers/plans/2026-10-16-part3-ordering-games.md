# Part 3: Ordering and Quantity Games Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ordering games for days, months and seasons (week train, yesterday/today/tomorrow, "what comes after", year wheel, "which season") and quantity games for numbers (count with me, which has the most), each reached from its topic hub.

**Architecture:** Question-style games reuse `Round`/`RoundView` through new `QuestionSource`s (`ComesNext`, `WhichSeason`, `Most`). Placement games run on a pure `SequencePuzzle` (ordered steps, a card pool, tap or drag to place) drawn by one `SequencePuzzleView` with a train layout and a three-slot layout. The year wheel and counting are their own small models (`YearWheel`, `CountingRound`) with their own views. `Game` gains the new cases; `Game.usesRound` and a `GameDestination` view let the hub open either kind.

**Tech Stack:** SwiftUI (`draggable`/`dropDestination` with `String` payloads), SwiftData, AVFoundation, Swift Testing, Xcode 27.

**Spec:** `docs/superpowers/specs/2026-10-16-learning-games-design.md` (part 3). Builds on the part 1 and part 2 plans in this folder.

## Global Constraints

- Effective deployment target is iOS 17.5.
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Pure logic types and extensions are `nonisolated`.
- New app files under `DayByDay/`, new tests under `DayByDayTests/`.
- No bundled image or audio files. All sound synthesized; all art in SwiftUI shapes and SF Symbols.
- Nothing requires reading. Every prompt is spoken; every card shows a symbol plus its name, like the existing day/month/season choice tiles.
- Wrong answers: `.gentleMiss` plus a spoken correction. No buzzer, no red X.
- Drag is never required: tapping a card places it too. Drop targets are the whole slot area, not a single slot.
- Reduce Motion: the year wheel jumps to its result instead of spinning; no other new motion beyond existing celebration.
- White content on any new fill is at least 3:1, covered in `ContrastTests`.
- Weeks start on Sunday. The season is "Fall". Seasons by month: Mar–May spring, Jun–Aug summer, Sep–Nov fall, Dec–Feb winter (matches `Season.current`).
- `Game` raw values are persisted in `AnswerRecord.gameRaw`; never rename existing ones.
- No new required SwiftData fields (no `VersionedSchema` yet).
- Branch `feat/ordering-games` from `main`. Every commit `Ref #N` (last `Closes #N`). No AI attribution anywhere.
- Test command: `xcodebuild test -project DayByDay.xcodeproj -scheme DayByDay -destination 'platform=iOS Simulator,name=iPhone 18 Pro'` (add `-only-testing:DayByDayTests/<Suite>`).

## Review Focus

1. Wrap-around: "What day comes after Saturday?" is Sunday; "after December" is January. Test in Task 1.
2. Yesterday/tomorrow wrap at the week's ends (today Sunday → yesterday Saturday; today Saturday → tomorrow Sunday), for every weekday. Test in Task 3.
3. Repeated or late input on placement games: a card already placed, a tap during a correction, or any tap after the puzzle is solved is ignored and records nothing. Test in Task 3.
4. Year wheel rotation that has accumulated many turns or is negative still maps to the right month, and every spin lands exactly on the chosen month's center. Test in Task 5.
5. Counting: tapping an already-counted object does not count it twice; taps after the set is done are ignored. Test in Task 6.

---

### Task 0: Branch and issue

- [ ] **Step 1:** `git checkout -b feat/ordering-games main`
- [ ] **Step 2:** `gitbay issue create --title "Part 3: ordering and quantity games" --json --file -` with a body naming the spec and this plan. Note the number as `N`.
- [ ] **Step 3:** `git add docs && git commit -m "docs: part 3 plan" -m "Ref #N"`

### Task 1: Question sources and catalog

**Files:**
- Create: `DayByDay/Quiz/OrderSources.swift`
- Modify: `DayByDay/Quiz/Game.swift`, `DayByDay/Quiz/ChoiceTile.swift` (make `Dots` internal; add `PileTile`)
- Test: `DayByDayTests/OrderSourcesTests.swift`, `DayByDayTests/GameTests.swift`

**Interfaces:**
- Produces:
  - `nonisolated extension MonthOfYear { var season: Season }` (same months as `Season.current`).
  - `Game` new cases (raw values as written): `comesNext, weekTrain, yesterdayTomorrow, yearWheel, whichSeason, counting, most`. Titles: "What comes next?", "Week train", "Yesterday and tomorrow", "Year wheel", "Which season?", "Count with me", "Which has the most?". Symbols: `arrow.right.circle.fill`, `train.side.front.car`, `calendar.day.timeline.left`, `circle.dashed`, `leaf.fill`, `hand.tap.fill`, `chart.bar.fill`. `var usesRound: Bool` (true for `findIt, oddOneOut, listen, comesNext, whichSeason, most`).
  - `Category.games` after this task: days `[findIt, comesNext]`, months `[findIt, comesNext]`, seasons `[findIt, whichSeason]`, numbers `[findIt, listen, most]`; others unchanged. Later tasks append their special games.
  - `nonisolated struct ComesNext: QuestionSource { init(items: [QuizItem], noun: String) }`. Picks an asked item, answer is the next item cyclically. Prompt `"What \(noun) comes after \(asked.name)?"`. The asked item is never a choice. Answer never equals `previous` when possible. Correction fact on a wrong tap: `"\(answer.name) comes after \(asked.name)."` (via `Question.facts` on every wrong choice).
  - `nonisolated struct WhichSeason: QuestionSource`. Answer is a season; the prompt names a random month of it: `"Which season is \(month.name) in?"`. Choices are 3 or 4 seasons. Fact on a wrong tap: `"\(month.name) is in \(answer.name)."`.
  - `nonisolated struct Most: QuestionSource`. Choices are distinct `LearnNumber` items from 1...10, answer is the largest. Prompt `"Which one has the most?"`. Fact on a wrong tap: `"That one has \(n)."`. Answer never equals `previous` when possible.
  - `PileTile(item:)`: number-topic fill with dots only (no numeral), dots larger than in `ChoiceTile`.

- [ ] **Step 1:** Write failing tests in `OrderSourcesTests`:

```swift
@Test func monthSeasons()            // Dec, Jan, Feb → winter; Mar → spring; Jun → summer; Sep, Nov → fall
@Test func comesNextWraps()          // seeded draws until asked == Saturday: answer == Sunday; asked == December: answer == January
@Test func comesNextNeverOffersAskedItem()   // 300 draws: the name between "after " and "?" in the prompt is never a choice's name
@Test func whichSeasonPromptMatchesAnswer()  // 300 draws: month named in prompt has .season == answer
@Test func mostAnswerIsLargest()     // 300 draws: answer numeral > every other choice's numeral
@Test func mostFacts()               // a wrong choice's correction == "That one has 3. Try again!" for numeral 3
```

Update `GameTests.catalog` to the new `games` lists and limit `everyGameMakesValidQuestions` to `game.usesRound`.

- [ ] **Step 2:** Run `-only-testing:DayByDayTests/OrderSourcesTests -only-testing:DayByDayTests/GameTests`. Expected: build fails (types missing).
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run the same command. Expected: PASS.
- [ ] **Step 5:** Commit `feat: what-comes-next, which-season and most question sources`.

### Task 2: Hub destinations and finished screen

**Files:**
- Create: `DayByDay/Quiz/GameDestination.swift`, `DayByDay/Quiz/FinishedView.swift`
- Modify: `DayByDay/Quiz/RoundView.swift` (use `FinishedView`), `DayByDay/Home/CategoryHubView.swift`

**Interfaces:**
- Produces:
  - `struct FinishedView: View { init(onPlayAgain: @escaping () -> Void) }`: the existing mascot, "You did it!", Play again button; plays `.roundComplete` and says "You did it!" on appear (moved from `RoundView` unchanged).
  - `struct GameDestination: View { init(category: Category, game: Game) }`: `RoundView` with `ChoiceTile` for round games, `PileTile` for `.most`; later tasks add the special games to its switch.
  - Hub uses `GameDestination` for every entry in `category.games`.

- [ ] **Step 1:** Build. Expected: `BUILD SUCCEEDED`.
- [ ] **Step 2:** Full suite. Expected: `** TEST SUCCEEDED **`.
- [ ] **Step 3:** Commit `feat: hub destinations for ordering games`.

### Task 3: Sequence puzzle model

**Files:**
- Create: `DayByDay/Quiz/SequencePuzzle.swift`
- Test: `DayByDayTests/SequencePuzzleTests.swift`

**Interfaces:**
- Produces: `nonisolated struct SequencePuzzle`:
  - `struct Step { let answer: QuizItem; let prompt: String }`
  - `let steps: [Step]`, `let pool: [QuizItem]` (cards shown, shuffled once), `private(set) var placed: [QuizItem]`, `private(set) var isShowingCorrection`
  - `var current: Step?` (nil when solved), `var isSolved: Bool`
  - `mutating func place(_ item: QuizItem) -> AnswerOutcome`: `.ignored` when solved, during a correction, or when `item` is already placed; `.correct` when `item == current.answer` (appends to `placed`); otherwise `.incorrect(correctName:)` and `isShowingCorrection = true`.
  - `mutating func resume()`
  - `func correction(for item: QuizItem) -> String` — `"\(current.answer.name) comes next. Try again!"` for the train; slot puzzles pass their own copy (see below).
  - `static func weekTrain(using rng: inout some RandomNumberGenerator) -> SequencePuzzle`: steps Sunday…Saturday; first prompt "Which day comes first?", then `"What comes after \(previous.name)?"`; pool is all 7 days shuffled. Correction: `"\(answer) comes next."`.
  - `static func yesterdayTomorrow(today: DayOfWeek, using rng: inout some RandomNumberGenerator) -> SequencePuzzle`: steps yesterday, today, tomorrow with prompts "Which day was yesterday?", "Which day is today?", "Which day will it be tomorrow?"; pool is those three plus one other day, shuffled. Corrections: `"Yesterday was \(x)."`, `"Today is \(x)."`, `"Tomorrow will be \(x)."`.
  - `let slotLabels: [String]?` — `["Yesterday", "Today", "Tomorrow"]` for that puzzle, nil for the train.

- [ ] **Step 1:** Write failing tests:

```swift
@Test func trainOrder()                    // steps map to Sunday…Saturday; pool is a permutation of 7 days
@Test(arguments: DayOfWeek.allCases) func yesterdayTomorrowWraps(_ today: DayOfWeek)  // answers == [today-1, today, today+1] mod 7; pool has 4 distinct days including those 3
@Test func correctPlacementAdvances()      // place Sunday → .correct, current.prompt == "What comes after Sunday?"
@Test func wrongPlacementWaits()           // place Tuesday first → .incorrect(correctName: "Sunday"); place Sunday → .ignored until resume()
@Test func placedCardIgnored()             // place Sunday, then Sunday again → .ignored
@Test func solvedIgnoresInput()            // place all 7 → isSolved, any place → .ignored
@Test func corrections()                   // yesterdayTomorrow(today: .friday): wrong on step 0 → "Yesterday was Thursday. Try again!"
```

- [ ] **Step 2:** Run `-only-testing:DayByDayTests/SequencePuzzleTests`. Expected: FAIL (type missing).
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run. Expected: PASS.
- [ ] **Step 5:** Commit `feat: sequence puzzle model`.

### Task 4: Week train and yesterday/tomorrow views, whistle

**Files:**
- Create: `DayByDay/Quiz/SequencePuzzleView.swift`
- Modify: `DayByDay/Sound/SoundSynth.swift` (`.whistle`), `DayByDay/Quiz/Game.swift` (days games), `DayByDay/Quiz/GameDestination.swift`
- Test: `DayByDayTests/SoundSynthTests.swift`, `DayByDayTests/GameTests.swift`

**Interfaces:**
- Consumes: `SequencePuzzle`, `ChoiceTile`, `FinishedView`, `SoundEngine`, `ProfileStore.record`.
- Produces:
  - `SoundEffect.whistle`: two-tone train whistle (sines near 600 and 750 Hz with soft harmonics, slight vibrato), 0.6–1.2 s, peak ≤ 0.6, included in `allCases`.
  - `struct SequencePuzzleView: View { init(game: Game, make: @escaping () -> SequencePuzzle) }`:
    - Top: the slots area. Train layout (no `slotLabels`): an engine shape plus 7 cars in a horizontal scroll, filled cars show the placed day tile, the next empty car is outlined. Slot layout: three labeled slots side by side, label text above each, the current slot outlined.
    - Bottom: the unplaced pool cards as `ChoiceTile`s. Tap places; `.draggable(item.id)` onto the slots area's `.dropDestination(for: String.self)` places too.
    - Speaks `current.prompt` on appear and after each correct placement; "Hear it again" button as in `RoundView`.
    - Correct: `.success` + praise; wrong: `.gentleMiss`, dims the card, speaks the correction, `resume()` after 1.2 s. Each placement is recorded with `record(step.answer, chosen:, game:, correct:)`.
    - Solved: `.whistle` (train) or `.success` (slots), speaks the full order ("Sunday, Monday, …, Saturday!" or "Yesterday was Thursday, today is Friday, tomorrow will be Saturday!"), then `FinishedView`; Play again calls `make()`.
  - Days games become `[findIt, comesNext, weekTrain, yesterdayTomorrow]`.

- [ ] **Step 1:** Add `cueDurations` range for `.whistle` (0.6...1.2) and update `GameTests.catalog`. Run `-only-testing:DayByDayTests/SoundSynthTests -only-testing:DayByDayTests/GameTests`. Expected: FAIL (`.whistle` missing).
- [ ] **Step 2:** Implement `.whistle`, the view, catalog and destination.
- [ ] **Step 3:** Run the same tests (the parameterized clipping/click/DC tests now cover `.whistle`). Expected: PASS.
- [ ] **Step 4:** Simulator check (rendered-image or screenshot, taking two screenshots per step): both layouts render on iPhone 18 Pro; tapping cards places them; a wrong card dims.
- [ ] **Step 5:** Commit `feat: week train and yesterday/tomorrow games`.

### Task 5: Year wheel

**Files:**
- Create: `DayByDay/Quiz/YearWheel.swift` (model), `DayByDay/Quiz/YearWheelView.swift`
- Modify: `DayByDay/Quiz/Game.swift` (months games), `DayByDay/Quiz/GameDestination.swift`
- Test: `DayByDayTests/YearWheelTests.swift`, `DayByDayTests/ContrastTests.swift`

**Interfaces:**
- Produces:
  - `nonisolated enum YearWheel`: month `i` (January = 0) is drawn centered `i * 30°` clockwise from the top pointer before rotation. `static func month(atRotation degrees: Double) -> MonthOfYear` (month under the pointer after rotating the wheel clockwise by `degrees`; any real value). `static func target(from rotation: Double, landingOn month: MonthOfYear, turns: Int) -> Double` (a rotation greater than `rotation` by at least `turns` full turns whose `month(atRotation:)` is `month`, exactly at its center).
  - `extension Season { var wheelColor: Color }`: spring `(0.18, 0.56, 0.28)`, summer `(0.84, 0.40, 0.08)`, fall `(0.66, 0.30, 0.10)`, winter `(0.0, 0.42, 0.85)`. All ≥ 3:1 against white.
  - `YearWheelView`: wheel of 12 wedges in season colors with three-letter month labels in white, a pointer at the top, a large "Spin!" button. Spin picks a random month (never the current one), animates to `target(…, turns: 3)` over about 2.5 s with ease-out (Reduce Motion: no animation), then says `"\(month.name)! \(month.name) is in \(season.name)."`. Tapping a wedge says the same for that month. Spin is ignored while spinning. Nothing is recorded (no right or wrong).
  - Months games become `[findIt, comesNext, yearWheel]`.

- [ ] **Step 1:** Write failing tests:

```swift
@Test func monthAtRotation()          // 0 → January; 30 → December (wheel turned clockwise brings December under the pointer); -30 → February; 360*7 + 30 → December; -1085 → mapped consistently with the definition
@Test(arguments: MonthOfYear.allCases) func targetLandsOnMonth(_ m: MonthOfYear)  // for rotations [0, 47.5, -800, 12345]: t = target(from:landingOn:turns: 3); t >= rotation + 1080; month(atRotation: t) == m; (t mod 30) is a center (multiple of 30)
@Test(arguments: Season.allCases) func wheelColorAgainstWhite(_ s: Season)   // ContrastTests
```

- [ ] **Step 2:** Run `-only-testing:DayByDayTests/YearWheelTests -only-testing:DayByDayTests/ContrastTests`. Expected: FAIL.
- [ ] **Step 3:** Implement the model, colors, view, catalog and destination.
- [ ] **Step 4:** Run. Expected: PASS. Render check: wedges, labels, pointer readable on iPhone 18 Pro.
- [ ] **Step 5:** Commit `feat: year wheel`.

### Task 6: Count with me

**Files:**
- Create: `DayByDay/Quiz/Counting.swift` (model), `DayByDay/Quiz/CountingView.swift`
- Modify: `DayByDay/Quiz/Game.swift` (numbers games), `DayByDay/Quiz/GameDestination.swift`
- Test: `DayByDayTests/CountingTests.swift`

**Interfaces:**
- Produces:
  - `nonisolated struct CountingRound`: `static let length = 5` sets. `struct Thing { let symbol: String; let singular: String; let plural: String }` with five kinds: star, heart, leaf ("leaf"/"leaves"), moon, fish ("fish"/"fish"), using their `.fill` SF Symbols. `private(set) var target: Int` (1...10, never equal to the previous set's), `private(set) var thing: Thing`, `private(set) var counted: [Int]` (object indices in tap order), `private(set) var setsDone: Int`.
  - `mutating func tap(_ index: Int) -> Int?`: returns the new count, or nil if `index` is out of range, already counted, or the set is done.
  - `var isSetDone: Bool`, `mutating func nextSet()`, `var isComplete: Bool` (after 5 sets).
  - `func summary() -> String`: `"\(n)! There \(n == 1 ? "is" : "are") \(n) \(n == 1 ? singular : plural)."` with `n` spelled as a numeral word from `LearnNumber.name`.
  - `CountingView`: says "Tap each \(singular) to count." The objects sit in a flexible grid in the numbers topic color. Each tap says the number, shows it on the object (white on the topic color), and plays no sound effect. When the set is done it plays `.success`, shows the numeral large, says `summary()`, then moves to the next set after 2.5 s. After 5 sets it shows `FinishedView`. Nothing is recorded.
  - Numbers games become `[findIt, listen, counting, most]`.

- [ ] **Step 1:** Write failing tests:

```swift
@Test func countsEachObjectOnce()      // target 4: tap 0,1,1,2 → 1,2,nil,3
@Test func ignoresOutOfRangeAndDone()  // tap(target) → nil; after all counted, tap(0) → nil
@Test func setsNeverRepeatTarget()     // seeded 200 sets: consecutive targets differ, all in 1...10
@Test func completesAfterFiveSets()
@Test func summaryCopy()               // n=1 → "One! There is one star."; n=3 → "Three! There are three stars."
```

- [ ] **Step 2:** Run `-only-testing:DayByDayTests/CountingTests`. Expected: FAIL.
- [ ] **Step 3:** Implement the model, view, catalog and destination.
- [ ] **Step 4:** Run. Expected: PASS. Then the full suite. Expected: `** TEST SUCCEEDED **`.
- [ ] **Step 5:** Commit `feat: count with me`.

### Task 7: Reviews, MR, merge

- [ ] **Step 1:** Export review assets (`TEST_RUNNER_EXPORT_DIR=<scratch> … -only-testing:DayByDayTests/ReviewExport`, adding the whistle and renders of the train, slots, wheel, pile and counting views to `ReviewExport`). Dispatch a fresh art/sound reviewer: block on clear defects (clipping, clicks, harsh or startling sound, unrecognizable drawing, contrast < 3:1); two rounds at most.
- [ ] **Step 2:** Dispatch a fresh whole-branch code reviewer with this plan, the spec, the ledger rulings and this Review Focus. One fix pass, each fix RED→GREEN.
- [ ] **Step 3:** Full suite green. Push, `gitbay mr create --source feat/ordering-games --target main --title "Part 3: ordering and quantity games"` with `Closes #N` and the unresolved art notes. Squash-merge, delete the branch locally and remotely.
