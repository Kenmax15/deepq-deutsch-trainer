/* Learning engine shared by the modules: card selection, grading, statuses, progress,
 * error categories and recommendations (modules 03, 05, 08, 10, 16, 24). */
(function () {
  "use strict";
  const DQ = window.DQ;
  const S = DQ.store;
  const SRS = DQ.srs;
  const { _ } = DQ;

  // order in which new words are introduced (everyday survival first)
  const CAT_ORDER = ["phrases", "people", "numbers", "food", "bakery", "verbs", "shopping", "time", "home", "town", "adjectives", "colours",
    "adverbs", "work", "body", "clothes", "leisure", "nature", "animals", "communication", "personal"];

  const L = {
    status(id, p = S.profile()) { return SRS.status(p.cards[id], Date.now()); },
    /** Cards due now: [{id, skill}] — late cards first, no penalty for being late. */
    due(p = S.profile(), now = Date.now()) {
      const out = [];
      for (const [id, cs] of Object.entries(p.cards)) {
        if (!DQ.entry(id)) continue;
        for (const k of SRS.SKILLS) if (cs[k] && cs[k].due <= now) out.push({ id, skill: k, due: cs[k].due });
      }
      return out.sort((a, b) => a.due - b.due);
    },
    /** New words never shown before (anti-repetition: a word is introduced once). */
    fresh(n, p = S.profile(), cat) {
      const list = DQ.allEntries().filter((e) => !p.introduced[e.id] && !p.cards[e.id] && (!cat || e.cat === cat));
      list.sort((a, b) => CAT_ORDER.indexOf(a.cat) - CAT_ORDER.indexOf(b.cat));
      return list.slice(0, n);
    },
    introduce(id, p = S.profile()) {
      const now = Date.now();
      if (!p.introduced[id]) { p.introduced[id] = now; S.day(p).newWords += 1; }
      p.cards[id] = p.cards[id] || {};
      for (const k of SRS.SKILLS) if (!p.cards[id][k]) p.cards[id][k] = SRS.newCard(now);
      S.save();
    },
    /** grade: 1 again, 3 hard, 4 good, 5 easy */
    grade(id, skill, g, p = S.profile()) {
      const now = Date.now();
      p.cards[id] = p.cards[id] || {};
      p.cards[id][skill] = SRS.schedule(p.cards[id][skill] || SRS.newCard(now), g, now);
      if (!p.introduced[id]) p.introduced[id] = now;
      const d = S.day(p); d.reviews += 1; if (g >= 3) d.correct += 1;
      S.save();
    },
    /** Exercise result outside the SRS (grammar, quiz, conjugation…) for statistics and mastery. */
    exercise(ok, info, p = S.profile()) {
      const d = S.day(p); d.ex += 1; if (ok) d.exOk += 1;
      if (!ok && info) S.logError(info); else S.save();
    },
    counts(p = S.profile()) {
      const c = { unknown: 0, learning: 0, known: 0, mastered: 0, due: 0 };
      const now = Date.now();
      for (const e of DQ.allEntries()) c[SRS.status(p.cards[e.id], now)] += 1;
      return c;
    },
    /** Days with activity in the last n days (no streak pressure: shown as a calendar, never as a loss). */
    activeDays(n = 7, p = S.profile()) {
      const out = [];
      for (let i = n - 1; i >= 0; i--) { const d = new Date(Date.now() - i * SRS.DAY); const k = S.today(d); out.push({ key: k, d, v: p.days[k] || null }); }
      return out;
    },
    /** Skill levels 0–1 from evaluations (accuracy × coverage), not only from word counts. */
    skills(p = S.profile()) {
      const now = Date.now();
      const entries = DQ.lexicon;
      const score = (list) => { if (!list.length) return 0; let s = 0; for (const e of list) { const st = SRS.status(p.cards[e.id], now); s += st === "mastered" ? 1 : st === "known" ? 0.7 : st === "due" ? 0.45 : st === "learning" ? 0.25 : 0; } return s / list.length; };
      const g = DQ_DATA.grammar; const gDone = g.filter((l) => (p.grammar[l.id] || {}).best >= 0.8).length / g.length;
      const verbs = entries.filter((e) => e.type === "verb");
      const days = Object.values(p.days); const ex = days.reduce((a, d) => a + d.ex, 0), exOk = days.reduce((a, d) => a + d.exOk, 0);
      const rev = days.reduce((a, d) => a + d.reviews, 0), revOk = days.reduce((a, d) => a + d.correct, 0);
      return {
        vocab: score(entries.filter((e) => e.type !== "verb")),
        verbs: score(verbs),
        grammar: gDone,
        accuracy: ex + rev ? (exOk + revOk) / (ex + rev) : 0,
        listening: Math.min(1, ((p.missions.brot_kaufen || {}).best || 0) / 100),
      };
    },
    /** Progress within A1, based on evaluated skills (weights: vocabulary 35 %, verbs 15 %, grammar 30 %, accuracy 10 %, mission 10 %). */
    cefr(p = S.profile()) {
      const s = L.skills(p);
      const a1 = 0.35 * s.vocab + 0.15 * s.verbs + 0.3 * s.grammar + 0.1 * s.accuracy + 0.1 * s.listening;
      return { level: p.level || "A1", progress: Math.round(a1 * 100), skills: s };
    },
    /** Error categories → where to practise (module 24, explainable). */
    CATS: {
      article: { fr: "Articles et genre", en: "Articles and gender", lesson: "g03", quiz: "article" },
      accusative: { fr: "Accusatif", en: "Accusative", lesson: "g05", quiz: "article" },
      plural: { fr: "Pluriel", en: "Plural", lesson: "g04", quiz: "mystery" },
      verb: { fr: "Conjugaison", en: "Conjugation", lesson: "g02", quiz: "conj" },
      wordorder: { fr: "Ordre des mots", en: "Word order", lesson: "g07", quiz: "build" },
      negation: { fr: "Négation", en: "Negation", lesson: "g06" },
      modal: { fr: "Verbes de modalité", en: "Modal verbs", lesson: "g08" },
      perfekt: { fr: "Parfait (Perfekt)", en: "Perfect tense", lesson: "g12" },
      dative: { fr: "Datif et prépositions", en: "Dative and prepositions", lesson: "g11" },
      politeness: { fr: "Politesse", en: "Politeness", lesson: "g08" },
      greeting: { fr: "Salutations", en: "Greetings", quiz: "listen" },
      numbers: { fr: "Nombres et prix", en: "Numbers and prices", quiz: "listen" },
      vocab: { fr: "Vocabulaire", en: "Vocabulary", quiz: "mystery" },
      grammar: { fr: "Grammaire", en: "Grammar" },
    },
    LESSON_CAT: { g01: "verb", g02: "verb", g03: "article", g04: "plural", g05: "accusative", g06: "negation", g07: "wordorder", g08: "modal", g09: "verb", g10: "article", g11: "dative", g12: "perfekt", g13: "verb" },
    recommendations(p = S.profile(), days = 14) {
      const since = Date.now() - days * SRS.DAY;
      const counts = {};
      for (const e of p.journal) if (e.t >= since) counts[e.cat || "grammar"] = (counts[e.cat || "grammar"] || 0) + 1;
      return Object.entries(counts).filter(([, n]) => n >= 2).sort((a, b) => b[1] - a[1]).slice(0, 3).map(([cat, n]) => {
        const c = L.CATS[cat] || L.CATS.grammar;
        return { cat, n, label: _(c), lesson: c.lesson, quiz: c.quiz,
          why: _("Tu as fait " + n + " erreurs de ce type ces " + days + " derniers jours.", "You made " + n + " mistakes of this kind in the last " + days + " days.") };
      });
    },
  };
  DQ.learn = L;
})();
