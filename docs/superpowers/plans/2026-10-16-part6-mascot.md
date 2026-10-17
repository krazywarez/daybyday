# Part 6: Mascot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the placeholder face with one owl character drawn in code, with five moods (idle, asking, cheering, puzzled, waving), that hosts the Today banner, asks the questions in every game, cheers or looks puzzled at answers, and waves on the welcome and picker screens.

**Architecture:** A pure `MascotState` maps game events to a mood and how long it holds before settling back to idle; a pure `MascotMotion` turns a mood and the time since it began into a pose (bob, hop, blink, wing angle, tilt, beak). `MascotView` draws the owl in a `Canvas` from a pose, inside a `TimelineView` unless Reduce Motion is on, when it draws the mood's still pose. `GameMascot` binds a game's `MascotState`, draws it at a small size beside "Hear it again", and schedules the settle.

**Tech Stack:** SwiftUI, Swift Testing, Xcode 27.

**Spec:** `docs/superpowers/specs/2026-10-16-learning-games-design.md` (part 6). Builds on the part 1–5 plans in this folder.

## Global Constraints

- iOS 17.5 target; `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; pure logic `nonisolated`.
- One character, drawn in code; no image assets. Flat fills.
- Contrast ≥ 3:1 for each feature against what it sits on (eye whites, belly, beak, ink on body; pupils on eye whites) and for the body against the page in light (white) and dark (black). Tested in `ContrastTests`.
- Motion is subtle: blink, slow bob, a cheer hop, a wave, a talking beak. With Reduce Motion on, still poses only (no `TimelineView`).
- In games the mascot is 64 pt beside "Hear it again" so it never pushes choices down on a phone.
- Wrong answers stay gentle: puzzled is a tilt and a raised brow, never a frown or red.
- Lifecycle: `generation` guard (bumped only in `onDisappear`) on every new `asyncAfter`; a newer mascot event always wins over an older settle.
- The celebration overlay stays confetti only; the game's own mascot cheers while it plays (no second copy over the choices).
- Branch `feat/mascot`. Every commit `Ref #N` (last `Closes #N`). No AI attribution.
- Test command: `xcodebuild test -project DayByDay.xcodeproj -scheme DayByDay -destination 'platform=iOS Simulator,name=iPhone 18 Pro'` (full suite ~10 min; run in background).

## Review Focus

1. Overlapping events: a correct answer's settle firing after the next prompt began must not put the mascot back to idle mid-question. Test `newerEventWins` in Task 1.
2. Long and delayed prompts: asking lasts through a sound cue and the whole prompt, and an empty prompt still settles. Tests `promptHoldCoversDelayAndWords`, `emptyPromptSettles` in Task 1.
3. Reduce Motion: the still pose has no bob, hop or tilt drift, eyes open, beak at its mood's shape, for every mood. Test `stillPosesDoNotMove` in Task 2.
4. Blink and wave timing stay in range for any time, including negative or huge values after a long session. Tests `poseValuesInRange` in Task 2.
5. Small sizes: at 64 pt on a 402 pt-wide phone the mascot row fits without truncating "Hear it again"; Trace's two pills still fit. Checked in the Task 5 renders.

---

### Task 0: Branch and issue

- [ ] `git checkout -b feat/mascot main`; `gitbay issue create --title "Part 6: Mascot" --json --file -` (#6); commit this plan with `Ref #N`.

### Task 1: Mood model

**Files:** Create `DayByDay/Mascot/MascotState.swift`. Test `DayByDayTests/MascotStateTests.swift`.

**Interfaces:**
- `nonisolated enum MascotMood: CaseIterable { case idle, asking, cheering, puzzled, waving }`.
- `nonisolated enum MascotEvent: Equatable { case prompt(String, after: TimeInterval = 0), correct, wrong, greet }`. Moods: prompt → asking, correct → cheering, wrong → puzzled, greet → waving.
- `nonisolated struct MascotState: Equatable { private(set) var mood: MascotMood = .idle; private(set) var ticket = 0; private(set) var hold: TimeInterval = 0; mutating func handle(_ event: MascotEvent); mutating func settle(_ ticket: Int); static func hold(for: MascotEvent) -> TimeInterval }`. `handle` sets the mood, bumps `ticket`, sets `hold`. `settle` returns to idle only when `ticket` matches.
- Holds: prompt = `after + 0.5 + 0.45 × words` (words split on spaces); correct 1.8; wrong 1.6; greet 2.4.

- [ ] Tests: `eventsMapToMoods`, `promptHoldCoversDelayAndWords` (`"Can you find Monday?"` after 1.0 → 3.3), `emptyPromptSettles` (hold 0.5, settle → idle), `settleReturnsToIdle`, `newerEventWins` (correct, then prompt, then settle(first ticket) → still asking). RED, implement, GREEN, commit `feat: mascot mood model`.

### Task 2: Motion

**Files:** Create `DayByDay/Mascot/MascotMotion.swift`. Test `DayByDayTests/MascotMotionTests.swift`.

**Interfaces:**
- `nonisolated struct MascotPose: Equatable { var bob: Double; var hop: Double; var eyeOpen: Double; var wing: Double; var tilt: Double; var beakOpen: Double }`. `bob`, `hop` in fractions of the size (up is negative); `eyeOpen` 0…1; `wing` degrees the raised wing is lifted; `tilt` degrees; `beakOpen` 0…1.
- `nonisolated enum MascotMotion { static func pose(_ mood: MascotMood, at t: TimeInterval) -> MascotPose; static func still(_ mood: MascotMood) -> MascotPose }`. `t` is seconds since the mood began.
- Values: bob = −0.012 × (1 − cos(2πt/2.6))/2 for every mood. Blink: eyes shut (0.1) for 0.14 s at the end of each 3.8 s cycle, except cheering (eyes are happy arcs). Cheering: hop = −0.06 × |sin(πt/0.4)| while `t mod 4 < 1.6`, else 0; wings up 150. Waving: wing = 120 + 22 × sin(2πt/0.7) while `t mod 5 < 2.1`, else 120. Asking: beakOpen = 0.5 + 0.5 × |sin(πt/0.22)|; tilt 4. Puzzled: tilt −10, beakOpen 0.2. Idle: beakOpen 0, wing 0, tilt 0.
- `still`: bob 0, hop 0, eyeOpen 1, beakOpen 1 for asking, cheering wings 150, waving wing 120, tilts as above.
- Negative `t` is treated as 0.

- [ ] Tests: `blinksOncePerCycle` (idle: eyeOpen 1 at t 1.0, 0.1 at t 3.75), `cheerHopsThenRests` (hop < 0 at 0.2, 0 at 2.0, < 0 at 4.2), `waveSwingsThenHolds`, `stillPosesDoNotMove` (all moods), `poseValuesInRange` (t in −5, 0, 0.37, 1e6 for all moods: eyeOpen and beakOpen in 0…1, hop in −0.06…0, wing in 0…150). RED, implement, GREEN, commit `feat: mascot motion`.

### Task 3: Owl drawing

**Files:** Rewrite `DayByDay/Mascot/MascotView.swift`. Test `ContrastTests`.

**Interfaces:**
- `enum MascotStyle { static let body, belly, ink, beak, eyeWhite: Color }` — body ≈ (0.55, 0.36, 0.85) purple, belly ≈ (0.93, 0.89, 1.0), ink ≈ (0.12, 0.08, 0.25), beak ≈ (1.0, 0.88, 0.45), eye white `.white`.
- `MascotView(mood: MascotMood)`: square, `accessibilityHidden`. Records when `mood` changed and passes `t` since then to `MascotMotion.pose`; with `accessibilityReduceMotion` it draws `MascotMotion.still(mood)` without a `TimelineView`.
- Drawing (100×100 space, `Canvas`): egg body with two ear tufts; belly oval; two large eye whites with ink pupils and a white catch-light, lids shut by `eyeOpen`; beak triangle that opens by `beakOpen`; wings at the sides, the right one raised by `wing` (both for cheering); three-toed beak-colored feet over the body's bottom edge. Moods: cheering eyes are ink arcs on the eye whites; asking raises both brows; puzzled raises one brow, the other flat, plus a body-colored "?" beside the head; the whole owl rotates by `tilt` and moves by `bob + hop`.
- Remove the old `Mood` enum; callers use `MascotMood`.

- [ ] Test `mascotContrast`: body vs white (light) and black (dark); eye white, belly, beak and ink vs body; ink vs eye white; all ≥ 3 in both styles. RED, implement, GREEN.
- [ ] Add `mascotPoses` to `ReviewExport`: every mood at 180 pt and 64 pt, still poses, light and dark sheets. Render, look, commit `feat: owl mascot`.

### Task 4: Banner, finish, welcome, picker

**Files:** Modify `DayByDay/Home/TodayBanner.swift`, `DayByDay/Quiz/FinishedView.swift`, `DayByDay/Profiles/ProfilePickerView.swift`.

- TodayBanner: idle mascot on a white disc (the orange gradient is too close to the body color), 96 pt overall.
- FinishedView: `MascotView(mood: .cheering)`.
- ProfileSetupView (welcome) and ProfilePickerView ("Who's playing?", mascot above the grid at 120 pt): `.waving`.

- [ ] Build, render banner and picker, commit `feat: mascot on home, finish and picker`.

### Task 5: Mascot in the games

**Files:** Create `DayByDay/Mascot/GameMascot.swift`. Modify `RoundView`, `SequencePuzzleView`, `TraceView`, `SortView`, `MovesView`, `CountingView`, `TodayRoutineView`.

**Interfaces:**
- `GameMascot(state: Binding<MascotState>)`: `MascotView(mood: state.mood)` at 64×64; on appear and on `ticket` change, `asyncAfter(hold)` then `settle(ticket)`, guarded by its own `generation` bumped in `onDisappear`.
- Each game holds `@State private var mascot = MascotState()` and puts `GameMascot(state: $mascot)` in an `HStack(spacing: 12)` with its "Hear it again" button (Trace: on its own row above both pills, which would truncate beside it). Today routine also shows it above the sticker calendar so the cheer for the picked weather is seen.
- Events: every spoken prompt (on appear, hear again, play again, next question/step/move/line) → `.prompt(text, after: delay)`; correct answer, solved puzzle, passed trace, finished count set, finished move, picked weather → `.correct`; wrong answer, missed trace, wrong bin → `.wrong`. Counting's per-tap numbers send nothing. The only new `asyncAfter` is the settle in `GameMascot`.

- [ ] Build, run the existing suites for the touched games (`RoundTests`, `SequencePuzzleTests`, `SortRoundTests`, `TraceTests`, `MovesRoundTests`, `CountingTests`), render every game screen on a phone size in both modes, commit `feat: mascot asks and reacts in games`.

### Task 6: Reviews, MR, merge

- [ ] Fresh art reviewer on the pose sheets and screen renders: recognizable, appealing, readable in both modes, contrast ≥ 3:1; two rounds max, block on clear defects, taste notes to the MR. Fresh whole-branch code reviewer with this Review Focus. One fix pass, RED→GREEN. Full suite green. Push, MR `Closes #N`, squash-merge, delete the branch locally and on the remote.
