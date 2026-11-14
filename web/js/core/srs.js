/* Spaced repetition (module 05) — SM-2 variant.
 * Why SM-2 rather than FSRS: it needs no trained parameters, behaves predictably with very little
 * review history (a new learner's situation) and is easy to explain to the learner. FSRS can replace
 * schedule() later without changing the card format.
 * Each word has up to three independent cards: rec (recognise: German → meaning), rcl (recall: meaning →
 * German, typed) and use (active use in a sentence, article or plural). Late reviews are never punished:
 * a card answered correctly after a long delay gets credit for the time it was remembered. */
(function (root) {
  "use strict";
  const DAY = 86400000;
  const SKILLS = ["rec", "rcl", "use"];

  function newCard(now) { return { ef: 2.5, int: 0, reps: 0, lapses: 0, due: now, last: 0, seen: now }; }

  /** grade: 1 = again, 3 = hard, 4 = good, 5 = easy */
  function schedule(card, grade, now) {
    const c = Object.assign({}, card);
    const elapsed = c.last ? Math.max(0, (now - c.last) / DAY) : 0;
    if (grade < 3) {
      c.reps = 0;
      c.lapses += 1;
      c.int = 0;                          // see again in this session / tomorrow
      c.due = now + 10 * 60000;
      c.ef = Math.max(1.3, c.ef - 0.2);
    } else {
      c.ef = Math.max(1.3, c.ef + (0.1 - (5 - grade) * (0.08 + (5 - grade) * 0.02)));
      // no penalty for lateness: base the next interval on the real time the word was kept in memory
      const base = Math.max(c.int, elapsed);
      if (c.reps === 0) c.int = grade === 5 ? 3 : 1;
      else if (c.reps === 1) c.int = grade === 5 ? 8 : 6;
      else c.int = Math.round(base * c.ef * (grade === 3 ? 0.8 : grade === 5 ? 1.3 : 1));
      c.int = Math.min(Math.max(c.int, 1), 365);
      c.reps += 1;
      c.due = now + c.int * DAY;
    }
    c.last = now;
    return c;
  }

  /** Word status for the dictionary and dashboard (module 03). */
  function status(cards, now) {
    if (!cards || !Object.keys(cards).length) return "unknown";
    const list = SKILLS.map((k) => cards[k]).filter(Boolean);
    if (list.some((c) => c.due <= now && c.reps > 0)) return "due";
    const minInt = Math.min(...list.map((c) => c.int));
    if (list.length === 3 && minInt >= 21) return "mastered";
    if (list.some((c) => c.int >= 7)) return "known";
    return "learning";
  }

  const api = { DAY, SKILLS, newCard, schedule, status };
  if (typeof module !== "undefined" && module.exports) module.exports = api;
  else (root.DQ = root.DQ || {}).srs = api;
})(typeof window !== "undefined" ? window : globalThis);
