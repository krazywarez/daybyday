# Learning games, Today routine, and profiles

## Intent

DayByDay is an offline iOS/iPadOS app for ages 4–5. Today every category is a
grid of cards that speak one word when tapped. Children lose interest because
nothing asks them anything, nothing reacts to what they do, and nothing changes
between visits. This work turns each topic into something the child plays:
questions with feedback, ordering games for the topics that are about sequence,
richer cards, a daily routine with a sticker calendar, a mascot, and a review
loop that favors what the child gets wrong.

## Goals

- Every topic (the 11 grid categories; Today moves to the banner) has a "Find it!" question game.
- Days, months, seasons and numbers teach order and quantity, not just names.
- Each card does more than say its label (sound, fact, or an interaction).
- A short daily routine on Today that children want to repeat, with a visible
  record (sticker calendar).
- Separate profiles for siblings on one device.
- Question selection adapts to each child's misses; parents can see progress.

## Non-goals

- Camera, microphone, speech recognition, or parent-recorded voice. Deferred to
  a later round.
- iCloud sync or any network use. Profiles and progress stay on the device.
- Localization beyond en-US.
- New categories.

## Anti-goals

These would make the work a failure even if it functions:

- Streak loss, guilt messaging, timers, loot boxes, or any mechanic designed to
  extend sessions. Rounds end with a clear "You did it!".
- Punishing wrong answers: no buzzer, no red X, no lost points.
- Anything that requires reading to use. Every prompt is spoken; every choice is
  a picture, color, or symbol.
- Ads, accounts, analytics, network calls.
- Third-party assets with unclear licenses.

## Constraints

- SwiftUI. The app target's effective deployment target is iOS 17.5 (the
  project-level setting is 26.2; the README says iOS 26). Use only APIs
  available on 17.5, or raise the target in a separate, stated change.
- Some sources live at the repo root and are added to the target individually;
  `DayByDay/` is a file-system-synchronized group. New files go under
  `DayByDay/` so they are picked up automatically.
- Speech uses the existing `SpeechSynthesizer` (AVSpeechSynthesizer, best en-US
  voice, rate 0.4). It triggers a haptic on every `speak()`.
- Large tap targets; works in portrait and landscape on iPhone and iPad.
- All art and sound is made in code: SwiftUI shapes and SF Symbols for visuals,
  sounds synthesized at runtime (e.g. AVAudioEngine tone/noise generation). No
  bundled image or audio files beyond the existing app icon, except generated
  speech clips (`DayByDay/Voice/`, rendered with ElevenLabs under a commercial
  license; see 2026-10-16-better-voice.md).
- Every MR that adds or changes art or sound gets a review by a separate
  reviewer agent focused on art and sound quality, before the MR is opened.
- Repo is on gitbay. One MR per part below, branched from `main`, never pushed
  to `main` directly.

## Decided by the user

- All seven parts below are in scope (camera, microphone, and parent voice
  excluded).
- All art and sound is generated in code, with an art/sound reviewer agent.
- Profiles per sibling.
- Data stays on device; no sync.
- Navigation option C: home shows the mascot and today's routine on top, then
  the topic grid. Tapping a topic opens a hub with large activity buttons:
  "Look and listen" (the existing cards), "Find it!", and that topic's special
  game. Same hub layout for every topic.
- Each part's MR is merged once its tests and the art/sound review pass; no
  wait for a human review between parts.
- Item sets in existing categories may be revised (added, removed, swapped)
  where it makes the games work, e.g. Animals gains animals with recognizable
  sounds (cow, duck, sheep, pig) in place of ones without (ant, lizard).

## The parts, in build order

### 1. Foundation

- **Profiles.** SwiftData model on device. A profile has a display name, an
  avatar (an animal drawn from SF Symbols / shapes), a color, an optional
  birthday (month and day), and per-day pictures (step 5). At launch, if more
  than one profile exists, show a picker of large avatar tiles; tapping one
  speaks "Hi, <name>!". With exactly one profile, skip the picker. On first
  launch, create one profile through a short parent-facing setup (behind the
  parent gate). No cap on profile count.
- **Parent gate.** Press-and-hold for about 2 seconds, then answer a simple sum
  shown as text. Protects profile management and, later, the progress screen.
- **Answer log.** Every answer a child gives is recorded: profile, category,
  item identifier, correct or not, timestamp. All later progress features read
  from this log.
- **Celebration.** One reusable overlay for correct answers: confetti
  animation, a generated cheerful sound, a spoken praise phrase chosen from a
  varied list, and the existing haptic. Wrong answers get a soft generated sound
  and a spoken correction ("That's Thursday! Try again.").
- **Question engine.** A shared model: a spoken prompt, a set of choices, which
  choice is correct, and a way to render a choice. Each category exposes its
  items through a common protocol. The engine picks questions (uniformly at
  random in this step) and runs a round of about 5 questions ending with a
  "You did it!" screen.
- **Sound engine.** Runtime-synthesized sound effects shared by everything that
  follows.
- **Home and hubs (option C).** Restructure `ContentView`: a Today banner with
  the mascot placeholder at the top, then the topic grid. Each topic opens a
  hub with "Look and listen", "Find it!", and a slot for the topic's special
  game (hidden until that game exists). Today itself is reached via the banner,
  not a grid tile.
- **Tests.** Add a unit test target. Cover the question engine, answer logging,
  and profile CRUD.

### 2. Question games (all 12 categories)

- **Find it!** "Can you find <item>?" with 3–4 choices on screen (number grows
  with correct answers in a round).
- **Odd one out.** Where items have a natural grouping (food: fruit vs
  vegetable; animals: pets vs wild or land vs water; shapes: round vs pointy;
  weather: hot vs cold). Only for categories where the grouping is unambiguous.
- **Listen and pick.** A generated sound or a spoken clue, child picks the
  card. Animals (animal sound), weather (rain, wind, thunder), letters (letter
  sound), numbers (that many beeps).

### 3. Ordering and quantity games

- **Week train.** Seven train cars, shuffled; the child drags them into order.
  Also "What comes after Monday?" as a single-question variant.
- **Year wheel.** Months around a wheel with seasons as colored sections. Child
  spins it and is asked to find a month or a season; or places a month in its
  season.
- **Yesterday / today / tomorrow.** Three slots, child drags day cards in.
- **Counting.** Tap objects to count them aloud; show the numeral beside the
  dots. "Which pile has more?" comparison.

### 4. Richer cards

Inside "Look and listen", tapping a card does more than say its name:

- Animals: generated animal sound plus one short fact.
- Letters: letter name, letter sound, and an example word ("B… buh… ball").
- Colors: a mixing activity (red + yellow → orange) as the Colors special game.
- Shapes and letters: finger tracing with a path check.
- Weather: dress a character for the weather (special game); shake the device
  on the weather screen to make it rain (Core Motion).
- Food: build a plate, or sort into fruit and vegetable bins (special game).
- Body: "Touch your nose!" movement prompts the child acts out; the app waits,
  then cheers.

### 5. Today routine

- A short spoken script the child taps through: "Today is Friday. Yesterday was
  Thursday. Tomorrow is Saturday. It's October. It's Fall." Then the child
  picks today's weather from picture choices.
- Finishing the routine places a sticker on that day in a month calendar page.
  One sticker per day per profile. Past months are browsable.
- Personal lines when they apply: the child's name in the greeting, "Your
  birthday is in May!" in the birthday month, "Today is your birthday!" on the
  day.
- Day pictures: a parent assigns a symbol to a weekday for a child (swim,
  grandma, school). It appears on that day's card and in the routine ("Today is
  swim day!").

### 6. Mascot

A single character drawn in SwiftUI shapes, with a few states: idle, asking,
cheering, puzzled (on wrong answers), waving. It hosts the Today banner, asks
questions in games, and appears in the celebration overlay. Replace the
placeholder from step 1.

### 7. Adaptive review and parent screen

- The question engine weights items by recent misses per profile, so missed
  items come up more often until answered correctly a few times.
- Parent screen (behind the gate): per child, per category, which items are
  known and which are still being missed, in plain terms ("Knows all the days.
  Still mixing up June, July, August.").

## Calls made without the user

- **Switching profiles.** The home screen shows the current child's avatar in
  a corner; tapping it (no gate) opens the profile picker. The picker also
  appears when the app returns to the foreground after 10 or more minutes in
  the background. Answers and stickers always go to the profile shown in that
  corner.
- **Art/sound review.** A rejection for a clear defect (clipping, harsh or
  startling sound, unrecognizable drawing, poor contrast) blocks the MR until
  fixed. Taste-level comments are advisory; after two rounds, remaining
  disagreements are noted in the MR description for the user.
- **Week order and wording.** Weeks start on Sunday, matching `DayOfWeek`. The
  season is "Fall", matching the existing code.
- **Weather in the routine.** Any weather choice is accepted; it is
  self-report, not a quiz.

## Left to the builder

- Exact SwiftData schema, protocol names, and file layout.
- Confetti and mascot visual design, sound synthesis approach, praise phrase
  list, and animal facts, subject to the art/sound review.
- Exact number of choices and round length (start around 3–4 choices and 5
  questions).
- Which categories get odd-one-out and listen-and-pick, within the rules above.
- How "known" is defined for the adaptive weighting and the parent screen.
- Whether existing per-category card views are refactored onto a shared
  card component, as long as each change stays within the step that needs it.
