# Part 7: Adaptive Review and Parent Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Missed items come up more often in "pick one" games until the child gets them right a few times, and a gated parent screen says per child and per topic what is known and what is still being missed, in plain words.

**Architecture:** A pure `ItemProgress` reads one child's answers in one topic and gives each item a status (new, learning, known) plus a pick weight. `QuestionPicker` and `OddOneOut` take optional weights and pick answers with them. `GameDestination` reads the current child's weights from the store and passes them in. A pure `ProgressSummary` turns statuses into sentences; `ChildProgressView` lists them per topic inside the existing parent area.

**Tech Stack:** SwiftUI, SwiftData, Swift Testing, Xcode 27.

**Spec:** `docs/superpowers/specs/2026-10-16-learning-games-design.md` (part 7). Builds on the part 1–6 plans in this folder.

## Global Constraints

- iOS 17.5 target; `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; pure logic `nonisolated`.
- No entity changes: everything is read from `AnswerRecord` (`itemID` is the question's answer, `isCorrect`, `timestamp`). No `VersionedSchema` needed in this part.
- An item's misses count against the question's answer. A correct answer within 60 s after a miss of the same item is the retry of that question and does not count toward getting it right.
- Learning: the item has a miss and fewer than 3 counted correct answers since its last miss. Known: no open miss and at least 2 counted correct answers. New: anything else.
- Pick weight: learning 3, otherwise 1. With no weights, `QuestionPicker` and `OddOneOut` pick exactly as before (same RNG use), so existing seeded tests are unchanged.
- "Never the previous answer when there is an alternative" still holds with weights.
- Parent copy is plain and neutral, never scolding: "Knows all 7 days.", "Knows 5 of 7 days.", "Still mixing up June, July and August.", "Not played yet."
- The parent screen is reached only from the gated parent area.
- Branch `feat/adaptive-review`. Every commit `Ref #N` (last `Closes #N`). No AI attribution.
- Test command: `xcodebuild test -project DayByDay.xcodeproj -scheme DayByDay -destination 'platform=iOS Simulator,name=iPhone 18 Pro'` (full suite ~10 min; run in background).

## Review Focus

1. The retry after a wrong tap (same question, seconds later) must not count as a correct answer toward clearing the miss. Test `retryDoesNotCount` in Task 1.
2. A miss after earlier corrects reopens the item; corrects before the last miss do not count. Test `newMissReopens` in Task 1.
3. Every item in learning (weights all 3) and a one-item pool still pick, and never return the previous answer when another exists. Tests `allLearningStillVaries`, `weightsKeepPreviousRule` in Task 2.
4. Answers from items no longer in the topic (removed in an earlier part) are ignored, not listed by ID. Test `unknownIDsIgnored` in Task 3.
5. Long missed lists stay readable: more than 4 items list the first 4 in topic order and "and N more". Test `longListTruncates` in Task 3.

---

### Task 0: Branch and issue

- [ ] `git checkout -b feat/adaptive-review main`; `gitbay issue create --title "Part 7: Adaptive review and parent screen" --json --file -` (#7); commit this plan with `Ref #N`.

### Task 1: Item progress

**Files:** Create `DayByDay/Profiles/ItemProgress.swift`. Test `DayByDayTests/ItemProgressTests.swift`.

**Interfaces:**
- `nonisolated struct AnswerFact: Equatable { let itemID: String; let isCorrect: Bool; let timestamp: Date }`.
- `nonisolated enum ItemStatus: Equatable { case new, learning, known }`.
- `nonisolated struct ItemProgress { static let retryWindow: TimeInterval = 60; static let clearAfter = 3; static let knownAfter = 2; static let learningWeight = 3.0; private(set) var statuses: [String: ItemStatus]; private(set) var lastMiss: [String: Date]; init(_ facts: [AnswerFact]); func status(_ itemID: String) -> ItemStatus; func weight(_ itemID: String) -> Double }`. Facts may arrive in any order; sort by timestamp.

- [ ] Tests: `untouchedIsNew`, `twoRightIsKnown`, `oneRightIsNew`, `missIsLearning`, `threeRightClearsMiss` (miss, then 3 counted corrects → known), `retryDoesNotCount` (miss, correct 5 s later, 2 more corrects minutes apart → still learning; a third → known), `newMissReopens` (5 corrects, miss → learning), `weights` (learning 3, others 1), `unorderedInput`. RED, implement, GREEN, commit `feat: item progress from answers`.

### Task 2: Weighted picks

**Files:** Modify `DayByDay/Quiz/Question.swift`, `DayByDay/Quiz/Game.swift`, `DayByDay/Quiz/GameDestination.swift`, `DayByDay/Profiles/ProfileStore.swift`. Test `DayByDayTests/RoundTests.swift`, `DayByDayTests/ProfileStoreTests.swift`.

**Interfaces:**
- `QuestionPicker` and `OddOneOut` gain `var weights: [QuizItem: Double] = [:]`. When non-empty, the answer is drawn from the same candidates by weight (default 1 for unlisted items); when empty, the existing `randomElement` call is kept.
- `nonisolated extension Array where Element == QuizItem { func weightedRandom(_ weights: [QuizItem: Double], using: inout some RandomNumberGenerator) -> QuizItem }` in `Question.swift`.
- `Category.questionSource(for: Game, weights: [QuizItem: Double] = [:]) -> any QuestionSource`: findIt, oddOneOut and listen get the weights; the other sources ignore them.
- `ProfileStore.progress(for: Profile, category: Category) -> ItemProgress` and `reviewWeights(for: Profile, category: Category) -> [QuizItem: Double]` (only items in `category.quizItems`).
- `GameDestination` reads `ProfileSession` and passes `reviewWeights` for the current child.

- [ ] Tests: `weightedPickFavorsLearning` (one of 7 days weighted 3: picked between 25% and 45% of 2000 seeded draws, against ~14% unweighted), `allLearningStillVaries`, `weightsKeepPreviousRule`, `emptyWeightsMatchOldPicks` (same seed, same answers with and without an empty map), `storeReviewWeights` (record a miss of Monday for one child → weight 3 for that child, 1 for a sibling). RED, implement, GREEN, commit `feat: missed items come up more often`.

### Task 3: Progress summary

**Files:** Create `DayByDay/Parent/ProgressSummary.swift`. Test `DayByDayTests/ProgressSummaryTests.swift`.

**Interfaces:**
- `nonisolated extension Category { var progressNoun: String }`: days, months, seasons, numbers, colors, shapes, animals, letters, kinds of weather, body parts, foods.
- `nonisolated struct ProgressSummary { init(category: Category, progress: ItemProgress); let known: String?; let missing: String? }`; played means any of the topic's items has a status. Sentences:
  - not played → `known = "Not played yet."`, `missing = nil`;
  - all known → `"Knows all \(count) \(noun)."` (seasons: "Knows all 4 seasons.");
  - some known → `"Knows \(k) of \(count) \(noun)."`; none known → nil;
  - learning items in topic order → `"Still mixing up A, B and C."`; more than 4 → first 4 then `"and \(n) more."` ("Still mixing up A, B, C, D and 2 more.").
- Item names come from `category.quizItems`; unknown IDs are ignored.

- [ ] Tests: `notPlayed`, `knowsAll`, `knowsSome`, `mixingUpList` (June, July, August), `twoItemsUseAnd`, `longListTruncates`, `unknownIDsIgnored`. RED, implement, GREEN, commit `feat: progress summary`.

### Task 4: Parent progress screen

**Files:** Create `DayByDay/Parent/ChildProgressView.swift`. Modify `DayByDay/Parent/ParentAreaView.swift`.

**Interfaces:**
- `ParentAreaView`: a "Progress" section with one `NavigationLink` per child (`ProfileRow`) to `ChildProgressView(profile:)`.
- `ChildProgressView(profile:)`: `List` of `Category.gridCases`, each row the topic symbol in a circle of its color (white symbol), the topic label, and the summary's lines (missing line in `.secondary` weight semibold). Title "\(name)'s progress".

- [ ] Add `parent-progress` to `ReviewExport` with a seeded child who has known days, missed months and no food answers. Build, render light and dark, commit `feat: parent progress screen`.

### Task 5: Reviews, MR, merge

- [ ] Fresh whole-branch code reviewer with this Review Focus. Fresh reviewer for the parent screen render and copy (plain, neutral, readable in both modes). One fix pass, RED→GREEN. Full suite green. Push, MR `Closes #N`, squash-merge, delete the branch locally and on the remote.
