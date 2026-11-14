/* Shared UI helpers: element builder, bilingual strings, audio (Piper files or offline system TTS),
 * sound effects, toasts and Qubi. */
(function () {
  "use strict";
  const DQ = (window.DQ = window.DQ || {});

  /** h("div.card#id", {onclick}, child, "text", [children]) */
  function h(sel, attrs, ...kids) {
    const m = /^([a-z0-9]+)?((?:[.#][\w-]+)*)$/i.exec(sel) || [];
    const e = document.createElement(m[1] || "div");
    (m[2] || "").replace(/([.#])([\w-]+)/g, (_, t, n) => { if (t === ".") e.classList.add(n); else e.id = n; });
    if (attrs && (typeof attrs !== "object" || attrs instanceof Node || Array.isArray(attrs))) { kids.unshift(attrs); attrs = null; }
    for (const [k, v] of Object.entries(attrs || {})) {
      if (v === undefined || v === null || v === false) continue;
      if (k.startsWith("on")) e.addEventListener(k.slice(2), v);
      else if (k === "html") e.innerHTML = v;
      else if (k === "style" && typeof v === "object") Object.assign(e.style, v);
      else if (k === "class") e.className += " " + v;
      else e.setAttribute(k, v === true ? "" : v);
    }
    const add = (k) => { if (k === null || k === undefined || k === false) return; if (Array.isArray(k)) k.forEach(add); else e.append(k instanceof Node ? k : document.createTextNode(String(k))); };
    kids.forEach(add);
    return e;
  }
  const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));

  /** Bilingual string: _("Bonjour", "Hello") or _({fr, en}) */
  function _(fr, en) {
    const lang = (DQ.store && DQ.store.profile() && DQ.store.profile().lang) || DQ.uiLang || "fr";
    if (fr && typeof fr === "object") return fr[lang] || fr.en || fr.fr || "";
    return lang === "en" ? (en === undefined ? fr : en) : fr;
  }
  const lang = () => (DQ.store && DQ.store.profile() && DQ.store.profile().lang) || DQ.uiLang || "fr";

  // ------------------------------------------------------------- audio
  let current = null;
  let germanVoice = null;
  function pickVoice() {
    if (!("speechSynthesis" in window)) return null;
    const vs = speechSynthesis.getVoices().filter((v) => /^de(-|_|$)/i.test(v.lang));
    germanVoice = vs.find((v) => v.localService) || vs[0] || null;
    return germanVoice;
  }
  if ("speechSynthesis" in window) { pickVoice(); speechSynthesis.onvoiceschanged = pickVoice; }

  function stop() {
    if (current) { current.pause(); current = null; }
    if ("speechSynthesis" in window) speechSynthesis.cancel();
  }
  /** Play a prepared file (audio/lex/<id>.mp3) or fall back to the device's German voice. */
  function say(text, opts = {}) {
    stop();
    const p = DQ.store && DQ.store.profile();
    const rate = (opts.slow ? 0.72 : 1) * ((p && p.prefs.audioRate) || 1);
    return new Promise((resolve) => {
      const viaTTS = () => {
        if (!("speechSynthesis" in window) || !text) return resolve(false);
        const u = new SpeechSynthesisUtterance(text);
        u.lang = "de-DE"; u.rate = 0.95 * rate;
        if (germanVoice || pickVoice()) u.voice = germanVoice;
        u.onend = () => resolve(true); u.onerror = () => resolve(false);
        speechSynthesis.speak(u);
      };
      if (!opts.id) return viaTTS();
      const a = new Audio("audio/lex/" + opts.id + ".mp3");
      a.playbackRate = rate;
      if ("preservesPitch" in a) a.preservesPitch = true;
      current = a;
      a.onended = () => resolve(true);
      a.onerror = () => { if (current === a) viaTTS(); };
      a.play().catch(() => viaTTS());
    });
  }
  function sfx(name, vol = 0.5) {
    const p = DQ.store && DQ.store.profile();
    if (p && !p.prefs.sfx) return;
    const a = new Audio("audio/ui/" + name + ".mp3");
    a.volume = vol;
    a.play().catch(() => {});
  }
  /** A small ▶ button that speaks a German text (and its slow version with a long press / second button). */
  function speakBtn(text, id, label) {
    const b = h("button.icon-btn", { title: _("Écouter", "Listen"), "aria-label": _("Écouter", "Listen") }, "🔊");
    b.onclick = (e) => { e.stopPropagation(); say(text, { id }); };
    if (!label) return b;
    const s = h("button.icon-btn", { title: _("Lentement", "Slowly"), "aria-label": _("Lentement", "Slowly") }, "🐢");
    s.onclick = (e) => { e.stopPropagation(); say(text, { id, slow: true }); };
    return h("span.row", { style: { gap: "6px" } }, b, s);
  }

  // ------------------------------------------------------------- toasts & Qubi
  function toast(msg, ms = 2200) {
    const t = h("div.toast", msg);
    document.body.appendChild(t);
    setTimeout(() => t.remove(), ms);
  }
  function qubiFace(mood = "", size) {
    const q = h("div.qubi" + (mood ? "." + mood : ""), h("i.ant"), h("i.eye.l"), h("i.eye.r"), h("i.mouth"));
    if (size) q.style.setProperty("--s", size + "px");
    return q;
  }
  /** Qubi with a speech bubble; returns null when the learner switched Qubi off. */
  function qubiSays(text, mood) {
    const p = DQ.store && DQ.store.profile();
    if (p && !p.prefs.qubi) return null;
    return h("div.qubi-say.fade-in", qubiFace(mood), h("div.bubble", text));
  }

  function shuffle(a) { a = a.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; }
  function sample(a, n) { return shuffle(a).slice(0, n); }
  const fold = (s) => String(s).toLowerCase().replace(/ä/g, "ae").replace(/ö/g, "oe").replace(/ü/g, "ue").replace(/ß/g, "ss").replace(/[.,!?;:„“"'()«»]/g, "").replace(/\s+/g, " ").trim();
  /** Lenient comparison of typed German (umlauts may be typed as ae/oe/ue, case ignored). */
  function sameGerman(a, b) { return fold(a) === fold(b); }

  function artClass(art) { return art ? "art-" + art : ""; }
  function nounLabel(e) { return h("span", e.art ? h("span." + artClass(e.art), e.art + " ") : null, e.de); }
  function tr(e) { return lang() === "en" ? e.en : e.fr; }

  Object.assign(DQ, { h, esc, _, lang, say, stop, sfx, speakBtn, toast, qubiFace, qubiSays, shuffle, sample, fold, sameGerman, artClass, nounLabel, tr });
})();
