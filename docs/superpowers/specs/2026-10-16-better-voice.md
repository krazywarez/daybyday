# Better spoken voice

## Intent

Every prompt in DayByDay is spoken, and on most devices it is spoken by the
compact default en-US voice, which sounds robotic. `SpeechSynthesizer` already
picks the best installed en-US voice (premium > enhanced > default) at rate
0.4, but enhanced and premium voices are only present if someone downloaded
them in Settings. This spec compares ways to make the voice sound better and
picks one. It is a plan; no app code changes with it.

## Constraints

- No network use, accounts, analytics or ads. Nothing is downloaded by the app.
- All art and sound is made in code or generated. No camera, microphone or
  parent-recorded voice (this rules out Personal Voice).
- Every prompt is spoken. en-US only.
- App target deployment is iOS 17.5.
- Games advance from the `speak(_:completion:)` completion. A completion must
  fire once when the line ends, and must not fire for a line that is cut off
  (`SpeechCompletionTests`).
- The learning-games spec (2026-10-16-learning-games-design.md) says "No
  bundled image or audio files beyond the existing app icon." The user
  approved an exception for generated speech clips (Decisions, 1); amend that
  line in the same change that adds the clips.

## What is spoken

Spoken text comes from about 20 call sites (`SpeechSynthesizer.shared.speak`
and `CardVoice.say`). Apart from profile names, every line is a fixed string or
a template filled from a closed set: item names, `DayOfWeek`, `MonthOfYear`,
seasons, `DayPicture` kinds, weather, clothing, numbers, praise phrases
(`PraisePhrases.all`), corrections, and the routine lines in `RoutineScript`.
So the full set of lines, minus names, can be enumerated.

The largest template is the sticker calendar's
`"On \(monthName) \(day), it was \(weather)."` (12 × up to 31 × weather
kinds, roughly 2,000 lines). Everything else together is in the low thousands
at most. Lines that contain a profile name: `"Hi, \(name)!"` in
`ProfilePickerView` and `RoutineScript`. Per Decisions, 4, these are spoken as
`"Hi there!"` (the name stays on screen), so no spoken line contains a name.

## Options

### A. Get enhanced or premium Apple voices onto the device

The app cannot download a voice or start a download. No such API exists;
`AVSpeechSynthesisVoice(identifier:)` returns nil for a voice that is "not yet
downloaded by the user", and enhanced and premium voices are documented as
ones "you must download to use".

What the parent does: Settings > Accessibility > Spoken Content > Voices >
English (iOS 17 and 18), or Settings > Accessibility > Read & Speak > Voices
(iOS 26), then download an enhanced or premium US voice. Apple says
enhanced-quality voices "can be 100 MB or larger" and to use Wi-Fi. That
download is done by iOS, not by the app, so it does not break the no-network
rule, but it does depend on a parent finding and following the steps.

App work: show a parent-area notice when the selected voice is `.default`,
with the Settings path spelled out (children can't read it, so it lives behind
the parent gate). Re-run voice selection when the app returns to the
foreground; `voice` is currently a `let` chosen once at init.
`AVSpeechSynthesizer.availableVoicesDidChangeNotification` (iOS 17+) exists,
but its docs do not say it fires for downloaded Apple voices, so rely on the
foreground check.

- App size: none.
- Effort: 0.5–1 day.
- Timing risk: none. Same synthesizer and delegate.
- Result: much better voice on devices where a parent acts; no change
  anywhere else, which is most devices today.

### B. Bundled audio for every enumerable line, system voice for names

Render every line except those containing names ahead of time with an
open-license neural TTS model on a Mac, ship the clips in the app, and play
them with `AVAudioPlayer`. Lines with a name, and any line without a clip, go
to `AVSpeechSynthesizer` as now.

Which model renders the clips:

- System voices are out. The macOS Tahoe license allows System Voices only "for
  your personal, non-commercial use" and bars their "recording, publishing or
  redistribution … in a profit, non-profit, public sharing or commercial
  context". `AVSpeechSynthesizer.write(_:toBufferCallback:)` can render audio,
  but shipping that audio is not allowed.
- Kokoro-82M: Apache-2.0 weights; misaki G2P is Apache-2.0 and runs without
  espeak-ng when `fallback=None` (unknown words then need hand-written
  phonemes). en-US voices `af_heart` (grade A) and `af_bella` (A-) are the
  best rated. Output is 24 kHz.
- Piper voices are a poor fit: en_US-lessac comes from a research-only dataset
  and hfc_female is CC BY-NC-SA. ljspeech (public domain) is usable but lower
  quality than Kokoro.
- GPL tools used only on the build Mac do not make their output GPL, and none
  ship in the app.

Known model limits:

- Kokoro's voice notes say voices are weak on short utterances, "especially
  less than 10-20 tokens". Single words ("Monday", "Super!") are most of the
  card lines. Mitigation: render each short line inside a carrier sentence and
  trim it, or re-render with other seeds until a listener accepts it. Every
  clip gets a listening review regardless.
- Output is not bit-identical between runs (the vocoder samples noise). Seed
  the generator; clips are rendered once and committed, so this only matters
  when re-rendering.

Size: speech compressed as mono AAC at ~32 kbps is ~4 KB per second. At
roughly 3,000 lines averaging 1.5 s, the clips come to ~18 MB. Rewording the
sticker calendar line to drop the date ("It was sunny.", with the date shown
on screen) would remove ~2,000 of those lines and bring the total to a few MB.

Mixed voices: "Hi, Maya!" would be the system voice while the rest of the app
is Kokoro. Stitching a Kokoro "Hi," to a system-voice name sounds worse than
either alone. Decided (Decisions, 4): the two greeting call sites speak
`"Hi there!"` instead, so every line comes from the clips and the synthesizer
is only a fallback for a missing clip.

Completion timing: `AVAudioPlayerDelegate.audioPlayerDidFinishPlaying` gives
the same "ended" signal, and `stop()` on a player sends no finish callback, so
the current rule (no completion for a line that was cut off) carries over.
Clip lengths are known up front, which makes timing more predictable than TTS.
The risk is in the switch between paths: `stop()` and `isSpeaking` must cover
both the player and the synthesizer, or a clip and an utterance could overlap.

- App size: ~18 MB with every calendar combination (decided), or a few MB with
  the calendar line reworded.
- Effort: 5–7 days (render pipeline 1.5, line catalog 1.5, player and fallback
  1, tests 1, listening review and re-renders 1–2).
- Timing risk: low, if both paths sit behind the existing `speak` and `stop`.
- Result: the same good voice on every device, for every line (names are no
  longer spoken; Decisions, 4).

### C. Neural TTS model running on device

- Every Kokoro Swift/Core ML/MLX port found (kokoro-ios, kokoro-coreml,
  FluidAudio, speech-swift) requires iOS 18. Using one means raising the
  deployment target from 17.5.
- The only iOS 13+ runtime that runs Kokoro, Piper, Matcha or Kitten is
  sherpa-onnx, and its iOS build statically links espeak-ng (GPL-3.0-or-later),
  which conflicts with App Store distribution. A custom ONNX Runtime + Kokoro +
  misaki-style G2P path without espeak would avoid that, but no package exists.
- Size: Kokoro is 86–163 MB as quantized/fp16 ONNX and ~178 MB as the Core ML
  set. FluidAudio's 8M-parameter distillation is 12 MB int8, one voice, and its
  README says physical iOS inference is unvalidated.
- Latency: kokoro-coreml measured 1,383 ms to produce 3 s of audio on an
  iPhone 12 Pro (A14), 702 ms on an iPhone 15 Pro Max. The first load spends
  several seconds compiling the model. kokoro-ios (MLX) ran out of memory on
  an iPhone 12 Pro for 30 s clips. No data for A12/A13 iPads.
- The short-utterance weakness in B applies here too, and it can't be fixed by
  a human listening to each clip.

- App size: 12–180 MB.
- Effort: 8–12 days, plus a deployment-target change or a custom G2P.
- Timing risk: high. Every line waits ~0.5–1.5 s before sound starts on older
  devices, and memory pressure on 4 GB devices can kill synthesis mid-line.
- Result: names would match the rest of the voice. Nothing else is better than
  B.

### D. Tune AVSpeechSynthesizer

- `rate` runs 0.0–1.0 with default 0.5; the app uses 0.4. `pitchMultiplier`
  runs 0.5–2.0. A slightly higher pitch (about 1.1) and per-line pauses may
  sound friendlier to young children; it needs a listening test.
- SSML (`AVSpeechUtterance(ssmlRepresentation:)`, iOS 16+) ignores `rate` and
  `pitchMultiplier`; prosody has to come from `<prosody>` instead. Apple lists
  no supported elements beyond the `<break>` and `<prosody>` shown at WWDC23.
  Forum reports describe audible pauses around `<sub>`/`<phoneme>` and a freeze
  with `<emphasis>`. Not worth the risk for small gains.
- `preUtteranceDelay` and `postUtteranceDelay` add gaps; `didFinish` ignores
  the final utterance's `postUtteranceDelay`.
- None of this changes the compact voice's timbre, which is the main problem.

- App size: none.
- Effort: 0.5 day.
- Timing risk: low for rate/pitch; medium for SSML.
- Result: small.

## Comparison

| Option | App size | Effort | Timing risk | Who benefits |
|---|---|---|---|---|
| A. Settings voices + parent notice | 0 | 0.5–1 d | none | devices where a parent downloads a voice |
| B. Bundled Kokoro clips, names not spoken (decided) | ~18 MB | 5–7 d | low | every device |
| C. On-device neural TTS | 12–180 MB | 8–12 d | high | every device, iOS 18+ only |
| D. Rate/pitch/SSML tuning | 0 | 0.5 d | low–medium | marginal |

## Recommendation

B, with A included. B gives every child the same good voice without a parent
doing anything, keeps the iOS 17.5 target, ships nothing GPL, and has the most
predictable completion timing. A costs half a day and improves the lines B
cannot cover (names and any missing clip). C is rejected on size, iOS 18,
latency on older iPads, and the espeak-ng license. D's rate/pitch change can
be tried during B's listening review but is not a separate part.

## Decisions

Made by the user on 2026-10-17:

1. Bundled audio: allowed for generated speech clips only. The learning-games
   spec line "No bundled image or audio files" is amended when B is built.
2. Voice: ElevenLabs Jessica on `eleven_v4`, with tone tags (`[excited]`
   for praise, `[gently]` for corrections, `[curious]` for questions), chosen
   over Kokoro `af_heart` and the Matilda, Sarah and v3 renders in a listening
   test of 18 app lines. Letters are sent as capitals, except g, h, i, u, w, y
   and z, which are sent as names ("Gee", "Aitch", "Eye", "You", "Double-you",
   "Why", "Zee"). Rendered with `scripts/render-voice-elevenlabs.py` on a plan
   that includes a commercial license. Kokoro `af_heart`
   (`scripts/render-voice.py`, see Listening test) stays as the open-licensed
   fallback renderer.
3. Sticker calendar: keep the date and render every combination
   (`"On \(month) \(day), it was \(weather)."`, about 2,000 clips), accepting
   ~18 MB in total.
4. Names: dropped from speech. The greeting is spoken as `"Hi there!"` in the
   clip voice; the child's name stays on screen. No line falls back to the
   system voice by design. Amended: names in `Lines.spokenNames` (Gianna, Gigi,
   Ashlynn, Ash, Olive, Ollie, Elijah, Arthur, Noah, Thad, Thadeus, Izzy,
   Isabella, Sam, Sammy, Frankie, Franklin) have recorded greetings
   (`"Hi, Gianna!"`), matched ignoring case and surrounding spaces; any other
   name gets `"Hi there!"`.

## Listening test

Rendered on a Mac with Kokoro 0.9.4 (Python 3.12 via `uv`, torch 2.14.1),
24 kHz, seed 0, misaki dictionary only (espeak fallback disabled). Lines:
"Monday", "Super!", "Can you find the cow?", "Hi there!", "That's Thursday!
Try again.", "On October 3, it was sunny.", "Today is swim day!", "You did
it!". No clipping; peaks 0.26–0.45, RMS within about 1 dB between voices.
Setup notes for `scripts/render-voice.py`:

- The `espeakng-loader` wheel's library points at its build machine's data
  folder and exits the process when espeak is used. Since the plan runs
  without espeak, replace `misaki.espeak.EspeakFallback` with a class whose
  constructor raises, so `KPipeline` falls back to `None`.
- misaki installs the spaCy `en_core_web_sm` model on first use through pip,
  which a `uv` venv lacks. Install it up front:
  `en_core_web_sm @ https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl`.

## Build outline

### Files

- `DayByDay/Speech/SpokenLines.swift` (new): enumerates every line the app can
  speak by calling the same functions the games use
  (`QuestionPicker` prompts, `PraisePhrases.all`, `PraisePhrases.correction`,
  `RoutineScript`, `SequencePuzzle`, `SortRound`, `MixColors`, `OrderSources`,
  `StickerCalendarView` line, card names). Producers that build strings inline
  move that string into a static function so the catalog and the view share it.
- `DayByDay/Speech/ClipLibrary.swift` (new): loads `Voice/manifest.json`
  (text → file name, duration) and looks up a clip by exact text.
- `DayByDay/SpeechSynthesizer.swift`: `speak` plays a clip through
  `AVAudioPlayer` when the library has one, otherwise uses the synthesizer.
  `stop`, the haptic, the `.playback` session and the completion rule cover
  both paths. `voice` becomes re-selectable on foreground (option A).
- `DayByDay/DayByDayApp.swift`: warmup also preloads the manifest.
- `DayByDay/Parent/ParentAreaView.swift`: notice with the Settings path when
  the selected voice is `.default`.
- `DayByDay/Voice/` (new, resources): `manifest.json` and `.m4a` clips (mono
  AAC, 24 kHz). File names are a hash of the line text.
- `scripts/render-voice-elevenlabs.py` (new): the same as `render-voice.py`
  below with ElevenLabs as the engine (Decisions, 2). Reads the API key from
  `ELEVENLABS_API_KEY`; `--dry-run` prints the text sent for each line.
- `scripts/render-voice.py` (new): reads the exported line list, renders
  missing lines with Kokoro (pinned version, fixed seed, misaki with no espeak
  fallback, carrier sentences for short lines), trims, converts with
  `afconvert`, and rewrites the manifest. Runs on a Mac, never in the app.
- `DayByDayTests/ReviewExport.swift`: add `lines()`, which writes
  `SpokenLines.all` to `EXPORT_DIR/lines.txt` for the render script, following
  the existing sounds/tiles export.

### Tests

- Every line in `SpokenLines.all` has a clip in the manifest, and every
  manifest entry is in `SpokenLines.all` (no stale clips).
- Sample real producers (seeded rounds of each game, `RoutineScript` for every
  day of a year, every `PraisePhrases` value) and check each produced line is
  in `SpokenLines.all`. This catches a new template that the catalog missed.
- `SpeechCompletionTests`: run both existing tests against a clip line and a
  fallback line; add one where a clip is cut off by a TTS line and the reverse,
  checking only the second completion fires.
- No line in `SpokenLines.all` contains a profile name; the picker and
  routine greetings speak `"Hi there!"`.
- A line with no clip falls back to the synthesizer.
- Manifest durations match the files (within 50 ms).
- Voice re-selection picks a higher-quality voice when one is added (inject the
  voice list).

### Review

The clips go through the art/sound reviewer like any other sound. Short lines
get a listen each; a rejected clip is re-rendered with another seed or a
different carrier sentence.

## Sources

Apple:

- https://developer.apple.com/documentation/avfaudio/avspeechsynthesisvoicequality
- https://developer.apple.com/documentation/avfaudio/avspeechsynthesisvoicequality/enhanced
- https://developer.apple.com/documentation/avfaudio/avspeechsynthesisvoicequality/premium
- https://developer.apple.com/documentation/avfaudio/avspeechsynthesisvoice/speechvoices()
- https://support.apple.com/guide/iphone/iph96b214f0/18.0/ios/18.0
- https://support.apple.com/guide/iphone/iph96b214f0/26.0/ios/26.0
- https://support.apple.com/en-us/111798
- https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer/availablevoicesdidchangenotification
- https://developer.apple.com/documentation/avfaudio/avspeechutterance/init(ssmlrepresentation:)-8zam9
- https://developer.apple.com/videos/play/wwdc2023/10033/
- https://developer.apple.com/forums/thread/712411
- https://developer.apple.com/documentation/avfaudio/avspeechutterance/rate
- https://developer.apple.com/documentation/avfaudio/avspeechutterance/pitchmultiplier
- https://developer.apple.com/documentation/avfaudio/avspeechutterance/postutterancedelay
- https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer/write(_:tobuffercallback:)
- https://developer.apple.com/documentation/avfaudio/avspeechsynthesizerdelegate/speechsynthesizer(_:didfinish:)
- https://developer.apple.com/documentation/avfaudio/avspeechsynthesizerdelegate/speechsynthesizer(_:didcancel:)
- https://www.apple.com/legal/sla/docs/macOSTahoe.pdf (section F, Voices)
- https://www.apple.com/legal/sla/docs/iOS26_iPadOS26.pdf
- https://developer.apple.com/forums/thread/812285

Neural TTS:

- https://huggingface.co/hexgrad/Kokoro-82M
- https://huggingface.co/hexgrad/Kokoro-82M/blob/main/VOICES.md
- https://github.com/hexgrad/kokoro
- https://raw.githubusercontent.com/hexgrad/kokoro/main/kokoro/istftnet.py
- https://github.com/hexgrad/misaki
- https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX
- https://github.com/mlalma/kokoro-ios
- https://huggingface.co/mattmireles/kokoro-coreml
- https://github.com/FluidInference/FluidAudio
- https://soniqo.audio/guides/kokoro
- https://github.com/k2-fsa/sherpa-onnx
- https://raw.githubusercontent.com/k2-fsa/sherpa-onnx/master/build-ios.sh
- https://github.com/espeak-ng/espeak-ng
- https://github.com/OHF-Voice/piper1-gpl/blob/main/docs/VOICES.md
- https://www.cstr.ed.ac.uk/projects/blizzard/2013/lessac_blizzard2013/license.html
- https://huggingface.co/rhasspy/piper-voices/blob/main/en/en_US/hfc_female/medium/MODEL_CARD
- https://www.gnu.org/licenses/gpl-faq.html#WhatCaseIsOutputGPL
