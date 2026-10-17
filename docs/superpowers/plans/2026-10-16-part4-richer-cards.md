# Part 4: Richer Cards Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cards that do more than say their name (animal sound and fact, letter and example word), shake-for-rain on the weather cards, and five topic activities: mix colors, trace shapes and letters, dress for the weather, sort fruit and vegetables, and "Touch your nose!" moves.

**Architecture:** Card lines live on the item enums (`cardLine`) and are spoken through a small `CardVoice` that plays a sound first and cancels stale lines. Mix colors and dress for the weather are `QuestionSource`s run by `RoundView`, which gains a header that shows a question's `shown` items. Tracing, sorting and moves are pure models (`TraceChecker`/`TraceGuide`, `SortRound`, `MovesRound`) with their own views. All five are `Game` cases opened by `GameDestination`.

**Tech Stack:** SwiftUI, CoreGraphics/CoreText (trace regions), AVFoundation, Swift Testing, Xcode 27.

**Spec:** `docs/superpowers/specs/2026-10-16-learning-games-design.md` (part 4). Builds on the part 1–3 plans in this folder.

## Global Constraints

- Effective deployment target is iOS 17.5; SF Symbols used must exist on iOS 17 (SF Symbols 5). Each new symbol gets a `UIImage(systemName:)` test.
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; pure logic is `nonisolated`.
- New files under `DayByDay/` and `DayByDayTests/`. No bundled assets; sound synthesized, art in SwiftUI/SF Symbols/the food emoji already in use.
- Nothing requires reading: every prompt is spoken; bins and choices are pictures.
- Wrong answers: `.gentleMiss` plus a spoken correction. No buzzer, no red X.
- Every touched card uses flat fills; every new fill with white content is ≥ 3:1 in `ContrastTests`.
- Lifecycle: every `asyncAfter` checks a `generation` counter that only `onDisappear` bumps; screen states sit in a `ZStack`, not a `Group`; card grids stay stable.
- Advance after speech with `SpeechSynthesizer.speak(_:completion:)` instead of guessing its length, with a backstop timer.
- Reduce Motion: rain from shaking shows still drops that fade instead of falling.
- `Game` raw values are persisted; add new cases, never rename.
- No camera or microphone. Shake uses the UIKit shake event.
- Branch `feat/richer-cards`. Every commit `Ref #N` (last `Closes #N`). No AI attribution.
- Test command: `xcodebuild test -project DayByDay.xcodeproj -scheme DayByDay -destination 'platform=iOS Simulator,name=iPhone 18 Pro'` (about 10 min for the full suite; run in the background).

## Review Focus

1. Tracing accepts a child's wobbly but on-target trace and rejects a scribble elsewhere or a half-finished trace, at any canvas size. Test in Task 3.
2. Dress for the weather never offers a second suitable item as a distractor (coat and jacket suit rain, snow and wind). Test in Task 5.
3. Rapid taps on look-and-listen cards: only the last card's line is spoken; a sound from an earlier card never runs into a later card's line. Test in Task 1 (`CardVoice` token logic).
4. Sorting: a tap on a bin while a correction plays, or after the last food, is ignored and records nothing. Test in Task 6.
5. Leaving any new screen mid-feedback says nothing afterwards (generation guard). Checked in review.

---

### Task 0: Branch and issue

- [ ] `git checkout -b feat/richer-cards main`; `gitbay issue create --title "Part 4: richer cards and topic activities" --json --file -`; commit this plan with `Ref #N`.

### Task 1: Card lines, CardVoice, flat animal and letter cards

**Files:** Modify `AnimalCard.swift`, `LetterCard.swift`, `AnimalsView.swift`, `AlphabetView.swift`. Create `DayByDay/Quiz/CardVoice.swift`. Test `DayByDayTests/CardLineTests.swift`, `ContrastTests.swift`.

**Interfaces:**
- `nonisolated extension LearnAnimal { var fact: String; var cardLine: String }`. `cardLine == "\(name)! \(fact)"`. Facts: cat "Cats say meow.", dog "Dogs say woof.", bird "Birds can fly.", fish "Fish swim in water.", rabbit "Rabbits hop.", turtle "Turtles carry their shell.", ladybug "Ladybugs have spots.", cow "Cows say moo.", duck "Ducks say quack.", sheep "Sheep say baa.", pig "Pigs say oink."
- `nonisolated extension LearnLetter { var cardLine: String }` = `"\(spokenName). \(spokenName) is for \(exampleWord)."`
- `@MainActor final class CardVoice { static let shared; func say(_ line: String, after sound: SoundEffect?); func cancel() }`. Bumps a token, stops speech, plays the sound, speaks after `SoundEngine.remaining(sound) + 0.2` only if the token is unchanged. Testable seam: `nonisolated struct LineQueue { mutating func next() -> Int; func isCurrent(_ token: Int) -> Bool }` used by `CardVoice`.
- `LearnAnimal.color` and `LearnLetter.color` changed to values ≥ 3:1 against white; cards use flat fills. Card taps call `CardVoice.shared.say(animal.cardLine, after: animal.sound)` / `say(letter.cardLine, after: nil)`. Views call `CardVoice.shared.cancel()` on disappear.

- [ ] Tests: `animalLines` (cow → "Cow! Cows say moo."), `letterLines` (b → "b. b is for ball."), `lineQueueKeepsOnlyLatest` (tokens 1, 2: isCurrent(1) false, isCurrent(2) true), `ContrastTests.animalColorAgainstWhite` and `letterColorAgainstWhite` over all cases. RED, implement, GREEN, commit `feat: animal and letter cards say more`.

### Task 2: Question header and Mix colors

**Files:** Modify `Question.swift` (`shown`), `RoundView.swift` (header), `Game.swift`, `GameDestination.swift`. Create `DayByDay/Quiz/MixColors.swift`. Test `DayByDayTests/MixColorsTests.swift`, `GameTests.swift`.

**Interfaces:**
- `Question.shown: [QuizItem] = []`: items drawn above the choices.
- `RoundView` draws a header when `current.shown` is not empty: the shown items as 110 pt tiles joined by "+" and followed by "= ?" when there are two; a single item is drawn alone. Existing call sites unchanged.
- `nonisolated struct MixColors: QuestionSource`. Mixes: red + yellow = orange, blue + yellow = green, red + blue = purple, red + white = pink. Prompt `"What do \(a) and \(b) make?"` (lower-case color names). Choices: the answer plus other colors, never `a` or `b`. Correction fact on every wrong choice: `"\(A) and \(b) make \(answer)."`.
- `Game.mixColors` ("Mix colors", symbol `paintbrush.fill`, `usesRound`). Colors games `[findIt, mixColors]`.

- [ ] Tests: `everyMixIsRight` (answer matches the table for the shown pair), `mixNeverOffersIngredients`, `mixPrompt`, `mixCorrection`; catalog. RED, implement, GREEN, render check, commit `feat: mix colors`.

### Task 3: Trace model

**Files:** Create `DayByDay/Quiz/Trace.swift`. Test `DayByDayTests/TraceTests.swift`.

**Interfaces:**
- `nonisolated enum TraceGuide { static func region(for item: QuizItem, size: CGFloat) -> CGPath }`: letters are the filled glyph of the uppercase letter in the system rounded heavy font, scaled to fit 80% of a `size`×`size` square and centered; shapes are their outline stroked at `0.12 * size` (circle, square, triangle, star (5 points), heart, oval, diamond, rectangle).
- `nonisolated struct TraceChecker { init(region: CGPath, size: CGFloat); let samples: [CGPoint]; func score(_ drawn: [CGPoint]) -> (coverage: Double, accuracy: Double); func passes(_ drawn: [CGPoint]) -> Bool }`. Samples are grid points inside the region at spacing `size / 30`. Tolerance `size * 0.07`. Coverage: share of samples within tolerance of a drawn point. Accuracy: share of drawn points inside the region or within tolerance of a sample. Passes at coverage ≥ 0.75 and accuracy ≥ 0.75.

- [ ] Tests, for the circle, star and letters A and S at sizes 300 and 600: `tracingTheGuidePasses` (drawn = samples jittered by up to 0.03·size), `scribbleElsewhereFails` (points in a box outside the region), `halfTraceFails` (first half of samples by x), `regionsFitTheCanvas` (bounding box inside the square, at least 40% of it). RED, implement, GREEN, commit `feat: trace checker`.

### Task 4: Trace game

**Files:** Create `DayByDay/Quiz/TraceView.swift`. Modify `Game.swift`, `GameDestination.swift`.

**Interfaces:**
- `Game.trace` ("Trace it", symbol `hand.draw.fill`, not `usesRound`). Shapes games `[findIt, oddOneOut, trace]`; alphabet games `[findIt, listen, trace]`.
- `TraceView(category:)`: five random items per round. The guide region is filled in the topic color at 30% opacity with a dashed topic-color edge; the finger's ink is the topic color at 0.08·size wide. It speaks `"Trace the \(name) with your finger."` (letters: `"Trace the letter \(spokenName)."`). On each lift, if `passes` → `.success`, "You traced the \(name)!", next item after the line ends; if accuracy < 0.5 and coverage > 0.4 → `.gentleMiss`, "Stay on the \(name). Let's try again.", ink cleared. "Start over" clears the ink. After five → `FinishedView`. Records `record(item, game: .trace, correct:)` for each pass or miss.

- [ ] Catalog test update; build; render check; commit `feat: trace shapes and letters`.

### Task 5: Dress for the weather

**Files:** Create `DayByDay/Quiz/DressUp.swift`, `DayByDay/Quiz/ClothingTile.swift`. Modify `Game.swift`, `GameDestination.swift`. Test `DayByDayTests/DressUpTests.swift`.

**Interfaces:**
- `nonisolated enum Clothing: Int, CaseIterable { sunglasses, sunHat, tshirt, umbrella, coat, jacket }` with `name`, `symbol` (`sunglasses.fill`, `hat.widebrim.fill`, `tshirt.fill`, `umbrella.fill`, `coat.fill`, `jacket.fill`), `suits: Set<LearnWeather>` (sunglasses, sunHat, tshirt: sunny; umbrella: rainy; coat and jacket: rainy, snowy, windy), `item: QuizItem` (`id "clothing.<case>"`, category `.weather`), `static func from(_ item: QuizItem) -> Clothing?`.
- `nonisolated struct DressUp: QuestionSource`: weather from `[sunny, rainy, snowy, windy]` (never the previous question's weather); answer from the clothing that suits it; distractors only from clothing that does not. Prompt `"It's \(weather.name.lowercased())! What should we wear?"`; `shown = [weather item]`. Facts on wrong choices: `"\(Name) is not for \(weather) days."` (umbrella: "An umbrella is for rainy days." style — use `fact(for:)` per clothing: "Sunglasses are for sunny days.", "A sun hat is for sunny days.", "A T-shirt is for warm days.", "An umbrella is for rainy days.", "A coat is for cold days.", "A jacket is for cold, windy days.").
- `ClothingTile(item:)`: weather-topic flat fill, white symbol.
- `Game.dressUp` ("Dress for the weather", symbol `tshirt.fill`, `usesRound`). Weather games `[findIt, listen, dressUp]`.

- [ ] Tests: `onlyOneSuitableChoice` (300 draws: exactly one choice suits the shown weather), `promptAndShown`, `clothingSymbolsExist`, `idsPinned` (all six ids). RED, implement, GREEN, render, commit `feat: dress for the weather`.

### Task 6: Sort fruit and vegetables

**Files:** Create `DayByDay/Quiz/SortRound.swift`, `DayByDay/Quiz/SortView.swift`. Modify `Game.swift`, `GameDestination.swift`. Test `DayByDayTests/SortRoundTests.swift`.

**Interfaces:**
- `nonisolated struct SortRound { init(using:); let foods: [LearnFood] (3 fruit + 3 vegetables, shuffled); var current: LearnFood?; private(set) var fruitBin, vegetableBin: [LearnFood]; private(set) var isShowingCorrection; mutating func place(isFruit: Bool) -> AnswerOutcome; mutating func resume(); func correction() -> String; var prompt: String? }`. Prompt `"Is the \(name.lowercased()) a fruit or a vegetable?"`. Correction `"\(A/An) \(name.lowercased()) is a \(fruit|vegetable). Try again!"`.
- `SortView`: current food emoji large (draggable); two bins below (🍓 "Fruit", 🥕 "Vegetables" as pictures with labels), tap or drop. Correct food drops into its bin (bin shows the foods it holds). Records `record(food item, game: .sortFood, correct:)`. After six → `FinishedView`.
- `Game.sortFood` ("Fruit or vegetable?", symbol `basket.fill`, not `usesRound`). Food games `[findIt, oddOneOut, sortFood]`.

- [ ] Tests: `threeOfEach`, `correctBinAdvances`, `wrongBinWaits` (.incorrect, then .ignored until resume), `doneIgnoresInput`, `correctionCopy` (apple → "An apple is a fruit. Try again!"). RED, implement, GREEN, render, commit `feat: sort fruit and vegetables`.

### Task 7: Touch your nose

**Files:** Create `DayByDay/Quiz/MovesRound.swift`, `DayByDay/Quiz/MovesView.swift`. Modify `Game.swift`, `GameDestination.swift`. Test `DayByDayTests/MovesRoundTests.swift`.

**Interfaces:**
- `nonisolated extension LearnBodyPart { var command: String }`: head "Touch your head!", eyes "Blink your eyes!", ears "Touch your ears!", nose "Touch your nose!", mouth "Point to your mouth!", hands "Clap your hands!", fingers "Wiggle your fingers!", arms "Wave your arms!", legs "March in place!", feet "Stomp your feet!", heart "Put your hand on your heart!", belly "Pat your belly!".
- `nonisolated struct MovesRound { static let length = 5; init(using:); let parts: [LearnBodyPart] (5 distinct); private(set) var index; var current: LearnBodyPart?; mutating func next() }`.
- `MovesView`: the body-part tile large; speaks the command; 3 s after the line ends plays `.success` and a praise phrase; moves on after that line ends. "Hear it again". After five → `FinishedView`. Nothing recorded.
- `Game.moves` ("Move your body", symbol `figure.wave`, not `usesRound`). Body games `[findIt, moves]`.

- [ ] Tests: `fiveDistinctParts`, `commandsForAll`, `advancesToEnd`. RED, implement, GREEN, render, commit `feat: move your body`.

### Task 8: Shake for rain

**Files:** Create `DayByDay/Quiz/ShakeRain.swift`. Modify `WeatherView.swift`.

**Interfaces:**
- `extension UIWindow { open override func motionEnded(_:with:) }` posts `Notification.Name.deviceDidShake` for `.motionShake`. `View.onShake(_:)` modifier.
- `RainOverlay(isActive:)`: falling drops for 3 s in a light-and-dark-visible blue; Reduce Motion shows still drops that fade. `WeatherView` plays `.rain`, shows the overlay and says "It's raining!" on shake; a shake during rain is ignored.

- [ ] Build; render check of the overlay; commit `feat: shake for rain`.

### Task 9: Reviews, MR, merge

- [ ] Extend `ReviewExport` with the new screens and run it. Fresh art/sound reviewer (two rounds max, block on clear defects). Fresh whole-branch code reviewer with this Review Focus. One fix pass, each fix RED→GREEN. Full suite green. Push, MR with `Closes #N` and open notes, squash-merge, delete branch.
