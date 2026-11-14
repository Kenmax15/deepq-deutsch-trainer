/* DeepQ Deutsch Trainer — mission engine (no DOM).
 * Port of godot/scripts/mission_runner.gd: reads a mission JSON, runs the
 * dialogue nodes, evaluates guided and typed answers with offline rules,
 * tracks objectives, errors, hints and score, and keeps a checkpoint.
 * Works in the browser (window.MissionEngine) and in Node (module.exports).
 */
(function (root) {
  "use strict";

  function pick(d, lang) {
    if (d === null || d === undefined) return "";
    if (typeof d !== "object") return String(d);
    return d[lang] || d.en || d.fr || "";
  }

  function formatEur(cents) {
    const e = Math.floor(cents / 100), c = cents % 100;
    return e + "," + String(c).padStart(2, "0") + " €";
  }

  /** Lower-case, fold umlauts/ß, drop punctuation, squeeze spaces. */
  function normalize(s) {
    let t = String(s).toLowerCase();
    t = t.replace(/ä/g, "ae").replace(/ö/g, "oe").replace(/ü/g, "ue").replace(/ß/g, "ss");
    let out = "";
    for (const ch of t) out += /[a-z0-9 ,.]/.test(ch) ? ch : " ";
    out = out.replace(/,/g, " , ").replace(/\./g, " . ").replace(/\s+/g, " ");
    // "broetchen" typed as "brotchen" (no umlaut key) is folded too
    out = out.replace(/brotchen/g, "broetchen").replace(/weisbrot/g, "weissbrot");
    return out.replace(/ , /g, " ").replace(/ \. /g, " ").replace(/[ ,.]+$/, "").replace(/^[ ,.]+/, "").trim();
  }

  function parseAmount(s) {
    const m = /^(\d+)(?:[ ,.](\d{1,2}))?$/.exec(s.trim());
    if (!m) return -1;
    let cents = 0;
    if (m[2]) cents = parseInt(m[2], 10) * (m[2].length === 1 ? 10 : 1);
    return parseInt(m[1], 10) * 100 + cents;
  }

  function shuffle(a, rnd) {
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(rnd() * (i + 1));
      [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
  }

  class MissionEngine {
    /**
     * @param {object} data   parsed mission JSON
     * @param {object} opts   {lang: () => "fr"|"en", store: {load(),save(rec)}, random: () => number}
     */
    constructor(data, opts = {}) {
      this.data = data;
      this.id = data.id;
      this.lang = opts.lang || (() => "fr");
      this.store = opts.store || null;
      this.random = opts.random || Math.random;
      this.listeners = {};
      this._rx = {};
      this.reset();
    }

    on(evt, fn) { (this.listeners[evt] = this.listeners[evt] || []).push(fn); return this; }
    emit(evt, ...args) { (this.listeners[evt] || []).forEach((fn) => fn(...args)); }
    t(d) { return pick(d, this.lang()); }

    reset() {
      this.nodeId = this.data.start;
      this.vars = { bread: "roggen", rolls: 0 };
      this.done = [];
      this.stats = { answers: 0, firstTryCorrect: 0, hints: 0, errors: [], steps: [] };
      this.finished = false;
      this.tries = 0;
    }

    // ---------------------------------------------------------- persistence
    record() {
      const all = (this.store && this.store.load()) || {};
      all.missions = all.missions || {};
      all.missions[this.id] = all.missions[this.id] || {};
      return { all, rec: all.missions[this.id] };
    }
    persist(all) { if (this.store) this.store.save(all); }
    hasCheckpoint() {
      const cp = this.record().rec.checkpoint;
      return !!(cp && cp.node && this.data.nodes[cp.node]);
    }
    saveCheckpoint() {
      const { all, rec } = this.record();
      rec.checkpoint = { node: this.nodeId, vars: this.vars, objectives: this.done, stats: this.stats };
      this.persist(all);
    }
    restoreCheckpoint() {
      const cp = this.record().rec.checkpoint;
      if (!cp || !this.data.nodes[cp.node]) return false;
      this.nodeId = cp.node;
      this.vars = cp.vars || this.vars;
      this.done = cp.objectives || [];
      this.stats = cp.stats || this.stats;
      return true;
    }
    clearCheckpoint() {
      const { all, rec } = this.record();
      delete rec.checkpoint;
      this.persist(all);
    }

    // ----------------------------------------------------------- objectives
    complete(objId) {
      if (!objId || this.done.includes(objId)) return;
      this.done.push(objId);
      this.emit("objective", objId);
    }
    /** Marks every objective listed before objId as done. */
    completeUpTo(objId) {
      for (const o of this.data.objectives) {
        if (o.id === objId) return;
        this.complete(o.id);
      }
    }

    // ------------------------------------------------------------- dialogue
    node() { return this.data.nodes[this.nodeId] || {}; }
    line(id) { return this.data.lines[id] || {}; }
    resolve(tpl) { return tpl.replace("{bread}", this.vars.bread).replace("{rolls}", String(this.vars.rolls | 0)); }

    begin() { if (!this.finished) this.present(this.nodeId, false); }

    present(id, retry) {
      this.nodeId = id;
      const n = this.node();
      this.completeUpTo(n.objective || "");
      const lineId = this.resolve(retry && n.retry_line ? n.retry_line : n.line);
      this.emit("npcLine", lineId, this.line(lineId));
      if (retry && n.type === "pay") {
        const p = this.resolve(n.line);
        this.emit("npcLine", p, this.line(p));
      }
      this.emitChoices();
    }

    emitChoices() {
      const n = this.node();
      if (n.type === "pay") this.emit("choices", this.nodeId, this.payOptions(), "pay");
      else this.emit("choices", this.nodeId, (n.options || []).map((o) => o.de), "say");
    }

    hint() {
      const h = this.t(this.node().hint || {});
      if (h) { this.stats.hints += 1; this.emit("hint", h); }
      return h;
    }

    // --------------------------------------------------------------- paying
    totalCents() {
      const p = this.data.prices;
      return Math.round((p[this.vars.bread] + p.broetchen * (this.vars.rolls | 0)) * 100);
    }
    /** Correct total plus listening traps (swapped digits, other euro, tens). */
    payOptions() {
      const c = this.totalCents(), e = Math.floor(c / 100), ct = c % 100;
      const cand = [c, Math.floor(ct / 10) * 100 + e * 10 + (ct % 10), (5 - e) * 100 + ct, e * 100 + ((Math.floor(ct / 10) + 1) % 10) * 10];
      const out = [];
      for (const v of cand) {
        const f = formatEur(v);
        if (v > 0 && v !== c && !out.includes(f) && out.length < 3) out.push(f);
      }
      while (out.length < 3) out.push(formatEur(c + 100 * (out.length + 1)));
      out.push(formatEur(c));
      return shuffle(out, this.random);
    }

    // ----------------------------------------------------------- evaluation
    choose(index) {
      const n = this.node();
      if (n.type === "pay") return;
      const o = (n.options || [])[index];
      if (o) this.apply(o, o.de);
    }

    pay(label) {
      const n = this.node();
      const total = formatEur(this.totalCents());
      if (label === total) {
        const fb = { fr: "Exact : %s.", en: "Right: %s." }[this.lang()].replace("%s", total);
        this.apply({ result: "correct", next: n.next }, label, fb);
      } else {
        this.apply({ result: "wrong", error: n.error || {} }, label, this.t(n.hint || {}));
      }
    }

    submitFree(text) {
      const n = this.node();
      const norm = normalize(text);
      if (!norm) return;
      if (n.type === "pay") {
        const digits = norm.replace(" euro", "").replace("eur", "").trim();
        const cents = parseAmount(digits);
        if (cents >= 0) { this.pay(formatEur(cents)); return; }
      }
      for (const rule of (n.free && n.free.rules) || []) {
        if (!this.ruleMatches(rule, norm)) continue;
        let merged = {};
        if ("ref" in rule) merged = JSON.parse(JSON.stringify(n.options[rule.ref]));
        if ("feedback_ref" in rule) merged.feedback = n.options[rule.feedback_ref].feedback;
        for (const k of Object.keys(rule)) if (!["all", "ref", "feedback_ref"].includes(k)) merged[k] = rule[k];
        this.apply(merged, text);
        return;
      }
      // nothing recognised: the shop assistant asks again, no error logged
      this.stats.answers += 1;
      this.tries += 1;
      this.emit("evaluated", "unknown", null, "", text);
      const retry = this.resolve(n.retry_line || n.line);
      this.emit("npcLine", retry, this.line(retry));
      this.emitChoices();
    }

    ruleMatches(rule, norm) {
      return (rule.all || []).every((p) => {
        if (!this._rx[p]) this._rx[p] = new RegExp("\\b(?:" + p + ")\\b");
        return this._rx[p].test(norm);
      });
    }

    apply(o, answer, fbOverride) {
      const result = o.result || "wrong";
      this.stats.answers += 1;
      if (!this.stats.steps.includes(this.nodeId)) {
        this.stats.steps.push(this.nodeId);
        if (result === "correct" && this.tries === 0) this.stats.firstTryCorrect += 1;
      }
      this.tries += 1;
      const fb = fbOverride || this.t(o.feedback || {});
      if (o.error && result !== "correct") {
        this.stats.errors.push({ node: this.nodeId, cat: o.error.cat || "other", label: this.t(o.error.label || {}), given: answer, explanation: fb });
      }
      for (const k of Object.keys(o.set || {})) this.vars[k] = o.set[k];
      this.emit("evaluated", result, fb, o.model || "", answer);
      if (o.next && result !== "wrong") {
        this.advance(o.next);
      } else {
        const n = this.node();
        const retry = this.resolve(n.retry_line || n.line);
        this.emit("npcLine", retry, this.line(retry));
        if (n.type === "pay") {
          const p = this.resolve(n.line);
          this.emit("npcLine", p, this.line(p));
        }
        this.emitChoices();
      }
    }

    advance(next) {
      this.complete(this.node().objective || "");
      this.tries = 0;
      if (next === "end") { this.finish(); return; }
      this.nodeId = next;
      this.saveCheckpoint();
      this.present(next, false);
    }

    finish() {
      this.finished = true;
      for (const o of this.data.objectives) this.complete(o.id);
      const steps = this.stats.steps.length;
      const score = steps ? Math.round((100 * this.stats.firstTryCorrect) / steps) : 0;
      const { all, rec } = this.record();
      rec.completed = true;
      rec.attempts = (rec.attempts || 0) + 1;
      rec.best = Math.max(rec.best || 0, score);
      delete rec.checkpoint;
      all.errors = (all.errors || []).concat(this.stats.errors.map((e) => Object.assign({ mission: this.id }, e))).slice(-200);
      this.persist(all);
      this.emit("npcLine", "s_closing", this.line("s_closing"));
      this.emit("finished", {
        score, hints: this.stats.hints, errors: this.stats.errors,
        vocabulary: this.data.vocabulary || [], grammar: this.data.grammar || [],
        best: rec.best, attempts: rec.attempts,
      });
    }
  }

  MissionEngine.normalize = normalize;
  MissionEngine.formatEur = formatEur;
  MissionEngine.pick = pick;
  if (typeof module !== "undefined" && module.exports) module.exports = MissionEngine;
  else root.MissionEngine = MissionEngine;
})(typeof window !== "undefined" ? window : globalThis);
