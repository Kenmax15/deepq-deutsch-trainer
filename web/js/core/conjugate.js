/* German conjugation for the DeepQ verb data (module 12).
 * Irregular forms come from the data file; regular forms are generated with the usual rules:
 *  - e-insertion after stems in -t/-d and consonant + m/n (arbeitest, öffnet, wartete)
 *  - du-ending -t after s/ß/z/x (du heißt, du tanzt)
 *  - separable prefix at the end of main clauses (ich kaufe ein), reflexive pronouns (ich freue mich). */
(function (root) {
  "use strict";
  const PERSONS = ["ich", "du", "er/sie/es", "wir", "ihr", "sie/Sie"];
  const REFL = ["mich", "dich", "sich", "uns", "euch", "sich"];

  function parts(v) {
    let inf = v.inf.replace(/^sich /, "");
    const sep = v.sep || "";
    const base = sep && inf.startsWith(sep) ? inf.slice(sep.length) : inf;
    return { inf, sep, base };
  }
  function stemOf(base) { return base.endsWith("en") ? base.slice(0, -2) : base.replace(/n$/, ""); }
  /** needs an extra e before -st/-t: arbeit-, wart-, find-, öffn-, atm- (but not lern-, wohn-) */
  function needsE(stem) {
    if (/[td]$/.test(stem)) return true;
    return /[^aeiouäöülrhmn][mn]$/.test(stem);
  }
  function sibilant(stem) { return /(s|ß|z|x)$/.test(stem); }

  function presentRaw(v) {
    if (v.pres) return v.pres.slice();
    const { base } = parts(v);
    const st = stemOf(base);
    const e = needsE(st) ? "e" : "";
    return [st + "e", st + (sibilant(st) ? "t" : e + "st"), st + e + "t", base, st + e + "t", base];
  }
  function preteritumRaw(v) {
    if (v.prtFull) return v.prtFull.slice();
    const { base } = parts(v);
    if (v.prt) {
      const s = v.prt;
      const du = /(s|ß|z|sch|d|t)$/.test(s) ? s + "est" : s + "st";
      const ihr = /[dt]$/.test(s) ? s + "et" : s + "t";
      return [s, du, s, s + "en", ihr, s + "en"];
    }
    const st = stemOf(base);
    const t = (needsE(st) ? "e" : "") + "te";
    return [st + t, st + t + "st", st + t, st + t + "n", st + t + "t", st + t + "n"];
  }
  /** Attach separable prefix and reflexive pronoun to a finite form (main clause word order). */
  function finite(v, form, i) {
    const { sep } = parts(v);
    let s = form;
    if (v.refl) s += " " + REFL[i];
    if (sep) s += " " + sep;
    return s;
  }
  function withPronoun(i, s) { return PERSONS[i].split("/")[0] + " " + s; }

  function present(v) { return presentRaw(v).map((f, i) => finite(v, f, i)); }
  function preteritum(v) { return preteritumRaw(v).map((f, i) => finite(v, f, i)); }
  function konjunktiv2(v) { return v.kon2 ? v.kon2.map((f, i) => finite(v, f, i)) : null; }
  function aux(v, table) { return table[v.aux === "sein" ? "sein" : "haben"]; }
  const AUX_PRES = { haben: ["habe", "hast", "hat", "haben", "habt", "haben"], sein: ["bin", "bist", "ist", "sind", "seid", "sind"] };
  const AUX_PRT = { haben: ["hatte", "hattest", "hatte", "hatten", "hattet", "hatten"], sein: ["war", "warst", "war", "waren", "wart", "waren"] };
  const WERDEN = ["werde", "wirst", "wird", "werden", "werdet", "werden"];
  function compound(v, auxForms, last) {
    return auxForms.map((a, i) => a + (v.refl ? " " + REFL[i] : "") + " " + last);
  }
  function perfekt(v) { return compound(v, aux(v, AUX_PRES), v.pp); }
  function plusquamperfekt(v) { return compound(v, aux(v, AUX_PRT), v.pp); }
  function futur(v) { return compound(v, WERDEN, parts(v).inf); }

  function imperative(v) {
    const { sep, base } = parts(v);
    const st = stemOf(base);
    const pres = presentRaw(v);
    let du = v.imp || (needsE(st) || /(s|ß)$/.test(st) ? st + "e" : st);
    const ihr = v.impIhr || pres[4];
    const sie = v.impSie || base + " Sie";
    const tail = (refl) => (v.refl ? " " + refl : "") + (sep ? " " + sep : "");
    return [du + tail("dich") + "!", ihr + tail("euch") + "!", sie + tail("sich") + "!"];
  }

  /** All tenses for display, each as 6 strings with pronouns. */
  function table(v) {
    const pp = (arr) => (arr ? arr.map((f, i) => withPronoun(i, f)) : null);
    return {
      praesens: pp(present(v)),
      praeteritum: pp(preteritum(v)),
      perfekt: pp(perfekt(v)),
      plusquamperfekt: pp(plusquamperfekt(v)),
      futur: pp(futur(v)),
      konjunktiv2: pp(konjunktiv2(v)),
      imperativ: imperative(v),
      partizip2: v.pp,
      hilfsverb: v.aux,
    };
  }

  /** Map any conjugated form back to its verb (search "isst" → essen). */
  function index(verbs) {
    const map = new Map();
    const add = (k, v) => { k = k.toLowerCase(); if (!map.has(k)) map.set(k, v); };
    for (const v of verbs) {
      const p = parts(v);
      add(v.inf, v); add(p.inf, v); add(v.pp, v);
      [...presentRaw(v), ...preteritumRaw(v), ...(v.kon2 || [])].forEach((f) => { add(f, v); if (p.sep) add(f + " " + p.sep, v); });
    }
    return map;
  }

  const api = { PERSONS, present, preteritum, perfekt, plusquamperfekt, futur, konjunktiv2, imperative, table, index, presentRaw };
  if (typeof module !== "undefined" && module.exports) module.exports = api;
  else (root.DQ = root.DQ || {}).conj = api;
})(typeof window !== "undefined" ? window : globalThis);
