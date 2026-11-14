# DeepQ Deutsch Trainer

Offline German-learning app for French- and English-speaking adults, built from the consolidated
specification v2.0 (*Cahier des charges consolidé*). Version **1.0, A1 content**.

It is an installable web app (PWA): it runs in Chrome, Edge, Firefox or Safari on Windows, Android, macOS and iOS,
works offline, needs no account and keeps every piece of data on the device.

**Design decision (14 November 2026):** no 3D for now. The Life Simulator plays on the learner's imagination
with photos, voices and soundscapes. The earlier Godot 3D prototype is kept on the branch `archive-3d-pilot`.

## Running it

- **On a computer:** double-click `web/index.html`.
- **As an installed app (Windows / Android):** serve the `web/` folder from any web address
  (or locally with `cd web && python -m http.server 8000`), open it in Chrome or Edge, then
  "Install app" / "Add to home screen". A service worker caches every file, so it then works offline.

## What is in version 1.0

| # | Module (specification §4) | Status |
|---|---|---|
| 01 | Local profiles: several profiles, language, level, goals, history, export / restore / delete | ✔ |
| 02 | Personal dictionary: 388 A1 entries — article, plural, FR/EN, category, example, audio; verbs with auxiliary, participle, separability, object | ✔ |
| 03 | Anti-duplicates: lemma and inflected forms detected (`Bücher` → Buch, `isst` → essen); statuses new / learning / known / mastered / to review; a new word is introduced only once | ✔ |
| 04 | Flashcards: front/back, picture → word, article, plural, gap sentence, typed answer; answers and self-assessment recorded | ✔ |
| 05 | Spaced repetition: SM-2 variant (choice justified in `js/core/srs.js`); recognition, recall and active use tracked separately; no penalty for late reviews | ✔ |
| 06 | Vocabulary quizzes: meaning, picture, listening, plural, article — with explanations | ✔ |
| 07 | Grammar exercises (grammar book and quizzes) | ✔ A1 |
| 08 | Error journal: question, answer, explanation, category, date | ✔ |
| 09 | Audio: offline German voice for every word, example, sentence and text (Piper TTS); slow replay; device voice for the learner's own words | ✔ |
| 10 | Dashboard: time, goals, words in progress / known / mastered, reviews due, activity vs mastery | ✔ |
| 11 | Einstufungstest: adaptive, A1–C1, vocabulary / grammar / reading, estimative | ✔ |
| 12 | Conjugation book: search an infinitive or any form; Präsens, Perfekt, Präteritum, Futur I, Plusquamperfekt, Konjunktiv II, imperative; 64 verbs | ✔ |
| 13 | DeepQ Grammatikbuch: 13 A1 lessons with tables, translated examples, 65 exercises, favourites, search, alternative explanation | ✔ A1 |
| 14 | Picture dictionary (one picture per word) and **mystery picture** (noun, article and plural scored separately) | ✔ |
| 15 | DeepQ Tutor: validated answers from the app's content; with **Ollama** installed, a local AI explains, corrects, works in Socratic mode — AI output is always labelled | ✔ |
| 16 | Progress bars: daily goal, skills, A1 progress computed from assessments, not word counts | ✔ |
| 17 | Qubi: mascot with expressions, encouragement, tips, can be switched off | ✔ |
| 18 | Time management: 5–45 min or custom, session length separate from daily time, pause, saved immediately | ✔ |
| 19 | Life Simulator: mission "Brot kaufen" in photos and sound (`web/sim/`), next missions listed | ✔ 1 mission |
| 20 | Sentence building with hints on verb position | ✔ |
| 21 | Word families, added to reviews in one tap | ✔ |
| 22 | Pronunciation: listen, record yourself, compare (transcription: later phase) | partial |
| 23 | Smart reading: clickable texts, comprehension questions, import your own text | ✔ |
| 24 | Difficulty detection: explainable suggestions from recurring mistakes | ✔ |
| 25 | Object recognition | later phase |
| 26 | Weekly review by Qubi | ✔ |
| 27 | Think in German: picture situations, free writing, model answer, correction | ✔ |
| 28 | Quiz Arena: find the article, mystery picture, listen and choose, true/false, spot the mistake, quick conjugation, 60-second challenge, duel against Qubi, mix; optional timer and sounds; vertical 9:16 format | ✔ |

Reminders (§7): a new word every 1, 2 or 3 hours with "I know it" / "Learn" actions, quiet hours, rest days and a
daily limit. They work while the app is open or installed and active; Android may delay them.

## Content (A1)

236 nouns, 64 verbs, 88 other words and phrases, 13 grammar lessons (65 exercises), 30 placement items (A1–C1),
3 reading texts, 12 sentence-building items, 8 word families, 6 "think in German" situations, quiz items and
823 German audio files. All content is written for DeepQ and marked "validated"; words the learner adds are
marked "not verified". Levels A2–C1 are the next content step.

## Project layout

```
web/index.html, css/, js/app.js     app shell and routing
web/js/core/                        lexicon, conjugation, spaced repetition, storage, UI helpers, learning engine
web/js/modules/                     dashboard & profile, words & reviews, grammar & conjugation, quizzes, practice, tutor
web/data/                           A1 content (vocabulary, verbs, grammar, placement test, extras)
web/audio/lex/                      German audio of the content (tools/build_audio.py)
web/sim/                            Life Simulator (missions in photos and sound) and its credits
web/tests/                          node web/tests/core.test.js · node web/tests/mission.test.js
tools/build_audio.py                Piper TTS for all content    tools/build_sw.py   offline cache list
tools/gen_voices.py, gen_sfx.py, web_data.py                     simulator voices, interface sounds, mission data
```

## Notes on the specification

- **Storage:** the specification asks for SQLite. The web app stores a versioned JSON schema with migrations in the
  browser and offers export/restore; the same schema maps directly onto SQLite tables for a native build.
- **Local AI on Android:** the tutor can use Ollama running on a PC on the same Wi-Fi (set its address in the tutor
  settings). On-device models are a later step.

## Licences

Photos (simulator): Unsplash and Pixabay licences. Sounds: BigSoundBank (CC0). Voices: Piper TTS with
CC0-trained voices. Details in `web/sim/CREDITS.md`.
