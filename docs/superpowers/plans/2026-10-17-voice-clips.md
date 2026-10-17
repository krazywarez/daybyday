# Voice Clips Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every line DayByDay speaks plays as pre-rendered Kokoro `af_heart` clips, with the system voice only as a fallback for a missing clip.

**Architecture:** Spoken text is split into sentences; each sentence is one clip. `SpokenLines.all` enumerates every sentence the app can say by calling the same producers the games use. A render script on the Mac turns that list into mono AAC clips plus `Voice/voice-manifest.json`. `ClipLibrary` looks sentences up; `SpeechSynthesizer.speak` plays a line's clips back to back through `AVAudioPlayer` when all of them exist, otherwise speaks the whole line with the synthesizer. `stop()`, the haptic, the audio session and the completion rule cover both paths.

**Tech Stack:** Swift, SwiftUI, AVFoundation, Swift Testing; Kokoro-82M 0.9.4 in a `uv` Python 3.12 venv on the Mac (build time only), `afconvert`.

**Spec:** `docs/superpowers/specs/2026-10-16-better-voice.md` (option B, Decisions, Listening test, Build outline).

## Deviation from the spec

The spec looks clips up by exact line text. Several views join sentences into one utterance (sorting says praise + fact + next question; the week train says praise + next prompt), which would multiply the line count by thousands. Clips are therefore per sentence, and a line plays as its sentences in order with a 0.12 s gap. A sentence ends at `.`, `!` or `?` followed by a space or the end of the line. The calendar decision (every date × weather) is unchanged.

## Global Constraints

- iOS 17.5 target; `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; pure logic `nonisolated`.
- Voice `af_heart`, speed 0.9 (young listeners), seed fixed per sentence, misaki dictionary only (espeak fallback disabled), spaCy `en_core_web_sm` preinstalled.
- Clips: mono AAC in ADTS, 24 kHz, ~32 kbps, `.aac`, named by the first 16 hex digits of the SHA-256 of the sentence text, in `DayByDay/Voice/` with `voice-manifest.json` (`[{text, file, seconds}]`).
- No spoken line contains a profile name: the picker and routine greetings say "Hi there!"; the routine card still shows "Hi, <name>!".
- Completion fires once when the whole line ends, never for a line cut off by `stop()` or a newer `speak`.
- Nothing downloaded by the app. Render tooling lives in the scratchpad, never in the repo.
- Amend the learning-games spec's "No bundled image or audio files" line to allow generated speech clips.
- Branch `feat/voice-clips`. Every commit `Ref #N` (last `Closes #N`). No AI attribution.
- Ask the user before downloading Kokoro/PyTorch/weights and before committing the clips.

## Review Focus

1. A line where one sentence has no clip falls back to the synthesizer for the whole line, so a child never hears two voices in one line. Test in Task 4.
2. Cutting off a clip line with a synthesizer line, and the reverse, fires only the second completion. Test in Task 4.
3. Every sentence a game can produce is in the catalog (sampling with seeds the catalog did not use). Test in Task 3.
4. Sentence splitting keeps "On October 3, it was sunny." whole and splits "That's Thursday! Try again." in two. Test in Task 1.
5. Clip durations in the manifest match the files within 50 ms, and the app bundle carries every manifest file. Test in Task 5.

---

### Task 0: Issue
- [ ] `gitbay issue create --title "Bundled af_heart voice clips" --json --file -`; commit this plan with `Ref #N`.

### Task 1: Sentence splitting
- `nonisolated enum SpokenText { static func sentences(_ text: String) -> [String] }`. Trims whitespace; empty input gives `[]`.
- [ ] Tests: `"That's Thursday! Try again."` → 2; `"On October 3, it was sunny."` → 1; `"b. b is for ball."` → `["b.", "b is for ball."]`; `"Monday"` → `["Monday"]`; `"Great job! An apple is a fruit. Is the banana a fruit or a vegetable?"` → 3. RED, GREEN, commit.

### Task 2: Greetings without names
- `RoutineScript.Line` gains `spoken: String` (defaults to `text`); the greeting line is `text: "Hi, Maya!"` (or `"Hi!"`), `spoken: "Hi there!"`. `TodayRoutineView` speaks `spoken`. `ProfilePickerView` speaks `ProfilePickerView.greeting == "Hi there!"`.
- [ ] Tests update `fridayScript` (`lines[0].text == "Hi, Maya!"`, `lines[0].spoken == "Hi there!"`). RED, GREEN, commit.

### Task 3: Spoken line catalog
- `DayByDay/Speech/SpokenLines.swift`: `nonisolated enum SpokenLines { static var all: Set<String> }` — the sentences of every line from: card taps (all categories, animal and letter card lines, day card picture lines), hub titles, picker, finish screen, praise, every `usesRound` game's prompts and corrections (collected by drawing seeded questions until a fixed draw count, plus corrections for every choice), sequence puzzles (train and every weekday's yesterday/tomorrow), sort, moves, counting, trace, year wheel, routine (every day of 2028 plus birthday and picture lines), weather pick and sticker lines, calendar lines for every date × routine weather plus every date alone, "It's raining!". View strings built inline move into static functions the views call.
- [ ] Tests: `noLineNamesAChild` (no sentence starts with "Hi, "), `producersAreCovered` (each `usesRound` game sampled 2,000 times with seeds 900+ → every sentence of prompts and corrections is in `all`; `RoutineScript` for every day of 2027 with random birthdays/pictures; every `SequencePuzzle`/`SortRound`/`CountingRound` line), `catalogSize` (between 2,000 and 4,000). RED, GREEN, commit.

### Task 4: Clip playback
- `DayByDay/Speech/ClipLibrary.swift`: `final class ClipLibrary { init(manifest: URL, directory: URL); static let bundled: ClipLibrary?; func clip(for sentence: String) -> (url: URL, seconds: Double)? }`.
- `SpeechSynthesizer`: `var library: ClipLibrary?` (bundled by default; tests inject one). `speak(text, completion)` stops anything playing, then plays every sentence's clip in order with `AVAudioPlayer` (0.12 s gap) if all are found, else speaks the whole text with the synthesizer. `stop()` stops both and drops pending completions. Haptic and audio session unchanged.
- [ ] Tests (with a temp manifest of generated 0.3 s tone `.m4a` files): `clipLineCompletes`, `missingSentenceFallsBackForWholeLine` (synthesizer path used), `clipCutOffByTTSCompletesOnlySecond`, `ttsCutOffByClipCompletesOnlySecond`, `stopDropsClipCompletion`; existing `SpeechCompletionTests` still pass. RED, GREEN, commit.

### Task 5: Render and bundle
- `ReviewExport.lines()` writes `SpokenLines.all` (sorted) to `EXPORT_DIR/lines.txt`.
- `scripts/render-voice.py <lines.txt> <DayByDay/Voice>`: renders missing sentences (by hash) with Kokoro `af_heart` at speed 0.9, trims leading/trailing silence to 40 ms, converts with `afconvert -f adts -d aac -b 32000 -c 1`, removes clips no longer listed, rewrites `manifest.json`.
- Ask the user, then download tooling, render, listen-review (Task 6), and commit the clips.
- [ ] Tests: `catalogMatchesManifest` (both directions), `manifestDurations` (within 50 ms of `AVAudioFile` length), `bundleHasEveryClip`. Commit.

### Task 6: Reviews, spec, MR
- [ ] Amend the learning-games spec line. Fresh listening reviewer: every clip of three words or fewer plus a 60-clip random sample; rejected clips re-rendered with another seed or inside a carrier sentence; two rounds max. Fresh whole-branch code review; one fix pass. Full suite green. Push, MR `Closes #N`, squash-merge, delete `feat/voice-clips` and `claude/better-voice-plan-bfee2d`.
