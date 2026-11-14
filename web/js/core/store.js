/* Local storage of profiles and progress (modules 01, 08, 10, 18 and DeepQ Core).
 * Everything stays on the device (localStorage). Versioned schema with migrations;
 * export / import of a JSON backup for saving and restoring (acceptance test R10). */
(function (root) {
  "use strict";
  const KEY = "dq.core";
  const SCHEMA = 1;
  const uid = () => Math.random().toString(36).slice(2, 10) + Date.now().toString(36).slice(-4);
  const today = (d = new Date()) => d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0");

  const backend = {
    read() { try { const s = root.localStorage.getItem(KEY); return s ? JSON.parse(s) : null; } catch (e) { return null; } },
    write(v) { try { root.localStorage.setItem(KEY, JSON.stringify(v)); return true; } catch (e) { return false; } },
  };

  function newProfile(name, lang) {
    return {
      id: uid(), name: name || "Moi", created: Date.now(), lang: lang || "fr",
      level: "A1", placement: null,
      time: { daily: 15, session: 10 },
      notif: { enabled: false, every: 2, quietFrom: "21:00", quietTo: "08:00", restDays: [], maxPerDay: 4, sentToday: 0, sentDay: "" },
      prefs: { qubi: true, sfx: true, timer: true, audioRate: 1, newPerSession: 8, showTranslation: true },
      cards: {},            // entryId → { rec, rcl, use }
      introduced: {},       // entryId → timestamp the word was first shown (anti-repetition)
      personal: [],         // words added by the learner
      journal: [],          // errors: { t, module, cat, q, given, right, why }
      days: {},             // "YYYY-MM-DD" → { sec, reviews, correct, newWords, ex, exOk }
      grammar: {},          // lessonId → { done, best, fav }
      quiz: { best: {}, played: 0 },
      missions: {},
      weekly: { lastShown: "" },
    };
  }

  function migrate(db) {
    if (!db || typeof db !== "object") return null;
    if (!db.schema) db.schema = 1;
    // future migrations: if (db.schema < 2) { …; db.schema = 2; }
    for (const p of Object.values(db.profiles || {})) {
      const base = newProfile(p.name, p.lang);
      for (const k of Object.keys(base)) if (p[k] === undefined) p[k] = base[k];
      for (const k of ["time", "notif", "prefs"]) p[k] = Object.assign({}, base[k], p[k]);
    }
    db.schema = SCHEMA;
    return db;
  }

  const Store = {
    db: null,
    load() {
      this.db = migrate(backend.read()) || { schema: SCHEMA, active: "", profiles: {} };
      return this.db;
    },
    save() { return backend.write(this.db); },
    profile() { return this.db.profiles[this.db.active] || null; },
    profiles() { return Object.values(this.db.profiles).sort((a, b) => a.created - b.created); },
    create(name, lang) { const p = newProfile(name, lang); this.db.profiles[p.id] = p; this.db.active = p.id; this.save(); return p; },
    switchTo(id) { if (this.db.profiles[id]) { this.db.active = id; this.save(); } },
    remove(id) {
      delete this.db.profiles[id];
      if (this.db.active === id) this.db.active = (this.profiles()[0] || {}).id || "";
      this.save();
    },
    exportJSON(id) {
      const p = id ? { [id]: this.db.profiles[id] } : this.db.profiles;
      return JSON.stringify({ app: "DeepQ Deutsch Trainer", schema: SCHEMA, exported: new Date().toISOString(), profiles: p }, null, 1);
    },
    /** Import a backup; profiles with the same id are replaced only if the backup is newer (no silent loss). */
    importJSON(text) {
      const data = JSON.parse(text);
      if (!data || !data.profiles) throw new Error("format");
      const incoming = migrate({ profiles: data.profiles }).profiles;
      let added = 0, kept = 0;
      for (const [id, p] of Object.entries(incoming)) {
        const mine = this.db.profiles[id];
        const stamp = (q) => Math.max(q.created || 0, ...Object.values(q.cards || {}).flatMap((c) => Object.values(c).map((x) => x.last || 0)));
        if (!mine || stamp(p) >= stamp(mine)) { this.db.profiles[id] = p; added++; } else kept++;
      }
      if (!this.db.active) this.db.active = Object.keys(this.db.profiles)[0] || "";
      this.save();
      return { added, kept };
    },
    // ---- daily activity
    day(p = this.profile(), key = today()) {
      p.days[key] = p.days[key] || { sec: 0, reviews: 0, correct: 0, newWords: 0, ex: 0, exOk: 0 };
      return p.days[key];
    },
    logError(e) {
      const p = this.profile(); if (!p) return;
      p.journal.push(Object.assign({ t: Date.now() }, e));
      if (p.journal.length > 500) p.journal = p.journal.slice(-500);
      this.save();
    },
  };

  const api = Object.assign(Store, { today, uid, newProfile, migrate, SCHEMA });
  if (typeof module !== "undefined" && module.exports) module.exports = api;
  else (root.DQ = root.DQ || {}).store = api;
})(typeof window !== "undefined" ? window : globalThis);
