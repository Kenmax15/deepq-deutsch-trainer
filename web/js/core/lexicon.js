/* Builds the unified A1 lexicon from the data files (nouns, verbs, other words) and
 * offers lookup by lemma or inflected form (modules 02, 03, 14, 23). */
(function (root) {
  "use strict";
  const fold = (s) => String(s).toLowerCase().replace(/ä/g, "ae").replace(/ö/g, "oe").replace(/ü/g, "ue").replace(/ß/g, "ss");
  const slug = (s) => fold(s).replace(/[^a-z0-9]+/g, "_").replace(/^_|_$/g, "");

  function build(D) {
    const out = [];
    const seen = new Set();
    const push = (e) => { let id = e.id; let k = 2; while (seen.has(id)) id = e.id + "_" + k++; e.id = id; seen.add(id); out.push(e); };
    for (const r of D.nouns || []) {
      const [de, art, pl, fr, en, emoji, cat, exDe, exFr, exEn] = r;
      push({ id: "n_" + slug(de), type: "noun", lemma: de, de, art, pl, fr, en, emoji, cat, lvl: "A1",
        say: (art ? art + " " : "") + de, ex: [exDe, exFr, exEn], status: "validated", source: "DeepQ A1" });
    }
    for (const v of D.verbs || []) {
      push({ id: "v_" + slug(v.inf), type: "verb", lemma: v.inf, de: v.inf, fr: v.fr, en: v.en, emoji: v.emoji, cat: "verbs", lvl: "A1",
        say: v.inf, ex: v.ex, verb: v, aux: v.aux, pp: v.pp, sep: v.sep || "", refl: !!v.refl, obj: v.obj || "", status: "validated", source: "DeepQ A1" });
    }
    for (const r of D.words || []) {
      const [de, pos, fr, en, emoji, cat, exDe, exFr, exEn, ant] = r;
      push({ id: "w_" + slug(de), type: pos, lemma: de, de, fr, en, emoji, cat, lvl: "A1", say: de, ex: [exDe, exFr, exEn], ant: ant || "",
        status: "validated", source: "DeepQ A1" });
    }
    return out;
  }

  /** Index every known form (lemma, plural, conjugated forms) → entry, for anti-duplicates and reading. */
  function indexForms(entries, conj) {
    const map = new Map();
    const add = (form, e) => { const k = fold(form).trim(); if (k && !map.has(k)) map.set(k, e); };
    for (const e of entries) {
      add(e.lemma, e);
      if (e.pl) add(e.pl, e);
      if (e.type === "verb" && conj) {
        const v = e.verb;
        [...conj.presentRaw(v), v.pp].forEach((f) => add(f, e));
        try { conj.preteritum(v).forEach((f) => add(f.split(" ")[0], e)); } catch (err) { /* ignore */ }
        (v.kon2 || []).forEach((f) => add(f, e));
      }
      if (e.type === "adj") ["e", "en", "er", "es", "em"].forEach((s) => add(e.lemma + s, e));
    }
    return map;
  }

  const api = { build, indexForms, fold, slug };
  if (typeof module !== "undefined" && module.exports) module.exports = api;
  else (root.DQ = root.DQ || {}).lex = api;
})(typeof window !== "undefined" ? window : globalThis);
