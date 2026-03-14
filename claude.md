# DayByDay – Project Context

## What this is
An iOS app for pre-K children (ages 4–5) that teaches days of the week, months
of the year, seasons, numbers, colors, shapes, animals, the alphabet, weather,
body parts, and fruits & vegetables through simple, tap-based interactions.

## Target user
A single child, approximately 4–5 years old, preparing to start school. Cannot
read yet. Parent may sit alongside but the child should be able to use the app
independently.

## Design principles
- Large tap targets — nothing small or fiddly
- Bright, clean colors — simple and friendly, not cluttered
- No text-dependent interactions — the child cannot read
- Audio is the primary feedback mechanism (names read aloud on tap)
- Simple animations on interaction — enough to delight, not enough to distract
- No timers, no failure states, no scores — purely exploratory

## Content (12 categories, accessible from a NavigationStack home grid)
- Today: summary card with current day, date, month, season
- Days of the week: Sunday through Saturday
- Months of the year: January through December
- Seasons: Spring, Summer, Fall, Winter
- Numbers: 1 through 10 (numeral + word + dot pattern)
- Colors: 10 basic colors (Red, Orange, Yellow, Green, Blue, Purple, Pink,
  Brown, Black, White)
- Shapes: 8 shapes (Circle, Square, Triangle, Star, Heart, Oval, Diamond,
  Rectangle)
- Animals: 12 animals with SF Symbol icons
- Alphabet: A through Z
- Weather: 8 weather types (Sunny, Cloudy, Rainy, Snowy, Windy, Stormy,
  Foggy, Rainbow)
- Body Parts: 12 body parts (Head, Eyes, Ears, Nose, Mouth, Hands, Fingers,
  Arms, Legs, Feet, Heart, Belly)
- Fruits & Vegetables: 12 foods (Apple, Banana, Carrot, Strawberry, Grapes,
  Lemon, Broccoli, Watermelon, Cherry, Orange, Corn, Pear)

## Technical constraints
- SwiftUI, iOS only
- Fully offline — no network requests, no accounts, no analytics
- No in-app purchases
- Targets latest iOS

## What good looks like
Each concept should feel like its own tactile card or object the child can tap
and explore. Transitions should be smooth. Audio should play immediately on tap
with no perceptible delay. The home screen is a colorful 2-column grid of square category
tiles that navigate into each section.
