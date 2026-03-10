# DayByDay – Project Context

## What this is
An iPad app for pre-K children (ages 4–5) that teaches days of the week, months
of the year, and seasons through simple, tap-based interactions.

## Target user
A single child, approximately 4–5 years old, preparing to start school. Cannot
read yet. Parent may sit alongside but the child should be able to use the app
independently.

## Design principles
- Large tap targets — nothing small or fiddly
- Bright, clean colors — simple and friendly, not cluttered
- No text-dependent interactions — the child cannot read
- Audio is the primary feedback mechanism (day/month/season name read aloud on
  tap)
- Simple animations on interaction — enough to delight, not enough to distract
- No timers, no failure states, no scores — purely exploratory

## Content
- Days of the week: Sunday through Saturday
- Months of the year: January through December
- Seasons: Spring, Summer, Fall, Winter

## Technical constraints
- SwiftUI, iOS only
- Fully offline — no network requests, no accounts, no analytics
- No in-app purchases
- Targets latest iOS

## What good looks like
Each concept (day, month, season) should feel like its own tactile card or
object the child can tap and explore. Transitions should be smooth. Audio should
play immediately on tap with no perceptible delay.
