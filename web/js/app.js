/* DeepQ Deutsch Trainer — web edition: scenes, dialogue UI, sound. */
(function () {
  "use strict";
  const $ = (id) => document.getElementById(id);
  const el = (tag, cls, html) => { const e = document.createElement(tag); if (cls) e.className = cls; if (html !== undefined) e.innerHTML = html; return e; };
  const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
  const wait = (ms) => new Promise((r) => setTimeout(r, ms));

  // ------------------------------------------------------------ storage
  const KEY_SET = "dqdt.settings", KEY_PROG = "dqdt.progress";
  const ls = {
    get(k, d) { try { const v = localStorage.getItem(k); return v ? JSON.parse(v) : d; } catch (e) { return d; } },
    set(k, v) { try { localStorage.setItem(k, JSON.stringify(v)); } catch (e) { /* private mode */ } },
  };
  const navLang = (navigator.language || "fr").slice(0, 2) === "fr" ? "fr" : (navigator.language || "").startsWith("en") ? "en" : "fr";
  const S = Object.assign({ lang: navLang, trans: true, subs: true, muted: false, vVoice: 1, vSfx: 0.8, vAmb: 0.45 }, ls.get(KEY_SET, {}));
  const saveSettings = () => ls.set(KEY_SET, S);
  const T = (k) => { const e = window.I18N[k]; return e ? (e[S.lang] || e.en) : k; };

  // -------------------------------------------------------------- audio
  const Snd = {
    voiceEl: null, queue: [], busy: false, amb: null, ambSrc: "", coffeeTimer: 0, onIdle: null,
    vol(kind) { return S.muted ? 0 : kind === "voice" ? S.vVoice : kind === "amb" ? S.vAmb : S.vSfx; },
    sfx(name, gain = 1) {
      const a = new Audio("audio/sfx/" + name + ".mp3");
      a.volume = Math.min(1, this.vol("sfx") * gain);
      a.play().catch(() => {});
      return a;
    },
    /** Queue voice lines; resolves when this line has finished. */
    say(id, slow) {
      return new Promise((resolve) => { this.queue.push({ id, slow, resolve }); this.next(); });
    },
    next() {
      if (this.busy || !this.queue.length) { if (!this.busy && this.onIdle) this.onIdle(); return; }
      const { id, slow, resolve } = this.queue.shift();
      this.busy = true;
      const a = new Audio("audio/voice/" + id + (slow ? "_slow" : "") + ".mp3");
      this.voiceEl = a;
      a.volume = this.vol("voice");
      markSpeaking(id, true);
      const done = () => { if (this.voiceEl !== a) return; markSpeaking(id, false); this.busy = false; this.voiceEl = null; resolve(); this.next(); };
      a.onended = done; a.onerror = done;
      a.play().catch(done);
    },
    stopVoice() {
      this.queue.forEach((q) => q.resolve());
      this.queue = [];
      if (this.voiceEl) { const a = this.voiceEl; this.voiceEl = null; a.pause(); this.busy = false; document.querySelectorAll(".pill.speaking").forEach((p) => p.classList.remove("speaking")); }
    },
    /** Looping ambience with a soft cross-fade between two players. */
    ambience(name) {
      if (this.ambSrc === name) return;
      this.ambSrc = name;
      const old = this.amb;
      if (old) fade(old.cur, 0, 1200, () => { old.stop(); });
      if (!name) { this.amb = null; return; }
      const src = "audio/sfx/" + name + ".mp3";
      const make = () => { const a = new Audio(src); a.preload = "auto"; return a; };
      const st = { cur: make(), other: make(), timer: 0, stop() { clearInterval(this.timer); this.cur.pause(); this.other.pause(); } };
      st.cur.volume = 0;
      st.cur.play().catch(() => {});
      fade(st.cur, this.vol("amb"), 1500);
      st.timer = setInterval(() => {
        const a = st.cur;
        if (a.duration && a.currentTime > a.duration - 2.1 && st.other.paused) {
          st.other.currentTime = 0; st.other.volume = this.vol("amb"); st.other.play().catch(() => {});
          setTimeout(() => { a.pause(); }, 2300);
          [st.cur, st.other] = [st.other, a];
        }
      }, 250);
      this.amb = st;
    },
    refreshVolumes() {
      if (this.amb) this.amb.cur.volume = this.vol("amb");
      if (this.voiceEl) this.voiceEl.volume = this.vol("voice");
    },
    coffee(on) {
      clearTimeout(this.coffeeTimer);
      if (!on) return;
      const tick = () => { this.sfx("coffee_machine", 0.35); this.coffeeTimer = setTimeout(tick, 28000 + Math.random() * 25000); };
      this.coffeeTimer = setTimeout(tick, 6000);
    },
  };
  function fade(a, to, ms, cb) {
    const from = a.volume, t0 = performance.now();
    const step = (t) => { const k = Math.min(1, (t - t0) / ms); a.volume = Math.max(0, Math.min(1, from + (to - from) * k)); if (k < 1) requestAnimationFrame(step); else if (cb) cb(); };
    requestAnimationFrame(step);
  }
  function markSpeaking(id, on) {
    document.querySelectorAll('.pill[data-line="' + id + '"]').forEach((p) => p.classList.toggle("speaking", on));
  }

  // ------------------------------------------------------------- scenes
  let bgFront = $("bgA"), bgBack = $("bgB");
  function setBg(name) {
    const url = "url(img/" + name + ".webp)";
    if (bgFront.style.backgroundImage === url) return;
    bgBack.style.backgroundImage = url;
    bgBack.classList.add("on");
    bgFront.classList.remove("on");
    [bgFront, bgBack] = [bgBack, bgFront];
  }

  // ---------------------------------------------------------- mission
  let mission = null, engine = null, kind = "say", ended = false;
  const store = { load: () => ls.get(KEY_PROG, {}), save: (v) => ls.set(KEY_PROG, v) };

  async function boot() {
    const res = await fetch("data/brot_kaufen.json");
    mission = await res.json();
    engine = new MissionEngine(mission, { lang: () => S.lang, store });
    wire(engine);
    applyLang();
    setBg("breadstack");
    document.body.classList.add("title-mode");
    $("resumeBtn").hidden = !engine.hasCheckpoint();
  }

  function applyLang() {
    document.documentElement.lang = S.lang;
    document.querySelectorAll("[data-i18n]").forEach((n) => { n.textContent = T(n.dataset.i18n); });
    document.querySelectorAll(".lang-switch button").forEach((b) => b.classList.toggle("on", b.dataset.lang === S.lang));
    if (mission) {
      $("goalText").textContent = MissionEngine.pick(mission.goal, S.lang);
      renderObjectives();
    }
    $("freeInput").placeholder = T(kind === "pay" ? "your_amount" : "your_answer");
    renderSound();
  }

  function renderSound() {
    $("soundBtn").innerHTML = S.muted
      ? '<svg viewBox="0 0 24 24"><path d="M11 5 6 9H3v6h3l5 4V5Z"/><path d="m22 9-6 6M16 9l6 6"/></svg>'
      : '<svg viewBox="0 0 24 24"><path d="M11 5 6 9H3v6h3l5 4V5Z"/><path d="M15.5 8.5a5 5 0 0 1 0 7M18.5 5.5a9 9 0 0 1 0 13"/></svg>';
    $("soundBtn").setAttribute("aria-label", T(S.muted ? "sound_off" : "sound_on"));
  }

  function renderObjectives() {
    const done = engine ? engine.done : [];
    $("objDots").innerHTML = mission.objectives.map((o) => '<i class="' + (done.includes(o.id) ? "done" : "") + '"></i>').join("");
    $("objLabel").textContent = T("objectives") + " " + done.length + "/" + mission.objectives.length;
    $("objTitle").textContent = T("objectives") + " · " + MissionEngine.pick(mission.title, S.lang);
    $("objList").innerHTML = mission.objectives.map((o) => '<li class="' + (done.includes(o.id) ? "done" : "") + '">' + esc(MissionEngine.pick(o, S.lang)) + "</li>").join("");
  }

  // ------------------------------------------------------------- dialogue UI
  const log = () => $("log");
  function scrollLog() { const l = log(); requestAnimationFrame(() => { l.scrollTop = l.scrollHeight; }); }

  let qubiKind = "";
  function qubi(text, k) {
    qubiKind = k || "";
    $("qubiText").textContent = text;
    const b = $("qubiBubble");
    b.hidden = false;
    b.style.animation = "none"; void b.offsetWidth; b.style.animation = "";
  }

  function speakerOf(id) { return id.startsWith("p_") ? "passerby" : id.startsWith("m_") ? "model" : "seller"; }

  function npcMessage(id, line) {
    const who = speakerOf(id);
    const m = el("div", "msg");
    const av = el("div", "av");
    if (who === "seller") av.style.backgroundImage = "url(img/avatar_seller.webp)";
    else av.textContent = "👤";
    const body = el("div", "body");
    body.appendChild(el("div", "who", esc(T(who))));
    const de = el("div", "de" + (S.subs ? "" : " veiled"), esc(line.de || ""));
    de.title = S.subs ? "" : "👁";
    de.addEventListener("click", () => de.classList.remove("veiled"));
    body.appendChild(de);
    const tr = el("div", "tr", esc(line[S.lang] || ""));
    tr.hidden = !S.trans || !line[S.lang];
    body.appendChild(tr);
    const ctl = el("div", "ctl");
    const rep = el("button", "pill", "▶ " + esc(T("replay")));
    rep.dataset.line = id;
    rep.onclick = () => { Snd.stopVoice(); Snd.say(id, false); };
    const slow = el("button", "pill", "🐢 " + esc(T("slow")));
    slow.onclick = () => { Snd.stopVoice(); Snd.say(id, true); };
    ctl.append(rep, slow);
    if (!S.trans && line[S.lang]) {
      const tb = el("button", "pill", "💬");
      tb.title = T("translation");
      tb.onclick = () => { tr.hidden = !tr.hidden; };
      ctl.append(tb);
    }
    body.appendChild(ctl);
    m.append(av, body);
    log().appendChild(m);
    scrollLog();
    Snd.say(id, false);
  }

  function myMessage(text) {
    const m = el("div", "msg me");
    m.append(el("div", "av", S.lang === "fr" ? "Moi" : "Me"));
    const b = el("div", "body");
    b.appendChild(el("div", "de", esc(text)));
    m.appendChild(b);
    log().appendChild(m);
    scrollLog();
  }

  function feedback(result, text, model) {
    const f = el("div", "fb " + result);
    f.appendChild(el("b", "", esc(T(result))));
    f.appendChild(el("div", "", esc(text || T("not_understood"))));
    if (model && result !== "correct") {
      const line = engine.line(model);
      const row = el("div", "model");
      const b = el("button", "pill", "▶ " + esc(T("hear_model")));
      b.dataset.line = model;
      b.onclick = () => { Snd.stopVoice(); Snd.say(model, false); };
      row.append(b, el("em", "", esc(line.de || "")));
      f.appendChild(row);
    }
    log().appendChild(f);
    scrollLog();
  }

  function renderChoices(opts, k) {
    kind = k;
    $("answer").hidden = false;
    $("sceneActions").innerHTML = "";
    $("answerLabel").textContent = T(k === "pay" ? "how_much" : "say");
    const box = $("choices");
    box.className = "choices" + (k === "pay" ? " pay" : "");
    box.innerHTML = "";
    opts.forEach((o, i) => {
      const b = el("button", "choice", "<kbd>" + (i + 1) + "</kbd><span>" + esc(o) + "</span>");
      b.onclick = () => answerChoice(i, o);
      box.appendChild(b);
    });
    $("freeInput").placeholder = T(k === "pay" ? "your_amount" : "your_answer");
    $("freeInput").value = "";
  }

  function answerChoice(i, label) {
    if (ended) return;
    Snd.sfx("ui_click", 0.6);
    lockAnswers();
    myMessage(label);
    if (kind === "pay") engine.pay(label); else engine.choose(i);
  }

  function lockAnswers() { $("answer").hidden = true; Snd.stopVoice(); }

  // context cards for the current step
  function showContext(nodeId) {
    const c = $("context");
    c.innerHTML = "";
    const P = mission.prices, f = (v) => MissionEngine.formatEur(Math.round(v * 100));
    const card = (img, de, tr, price, wide) => {
      const d = el("div", "card" + (wide ? " wide" : ""));
      d.innerHTML = '<img src="img/' + img + '.webp" alt="' + esc(de) + '" loading="lazy"><div class="cap">' +
        (price ? '<span class="price">' + price + "</span>" : "") + "<b>" + esc(de) + "</b><span>" + esc(tr) + "</span></div>";
      return d;
    };
    const voc = (de) => (mission.vocabulary || []).find((v) => v.de === de) || {};
    if (nodeId === "bread") {
      c.appendChild(el("p", "card-title", esc(T("our_breads"))));
      [["roggen", "das Roggenbrot"], ["vollkorn", "das Vollkornbrot"], ["weiss", "das Weißbrot"]].forEach(([k, de]) =>
        c.appendChild(card("p_" + k, de, MissionEngine.pick(voc(de), S.lang), f(P[k]))));
    } else if (nodeId === "extras") {
      c.appendChild(card("p_broetchen", "das Brötchen · die Brötchen", MissionEngine.pick(voc("das Brötchen"), S.lang), f(P.broetchen), true));
    } else if (nodeId === "pay") {
      c.appendChild(card("coins", "Das macht …", MissionEngine.pick(voc("Das macht …"), S.lang), "", true));
    } else if (nodeId === "bag") {
      c.appendChild(card("bag", "die Tüte", MissionEngine.pick(voc("die Tüte"), S.lang), "", true));
    }
  }

  // ------------------------------------------------------------- wiring
  function wire(en) {
    en.on("objective", () => renderObjectives());
    en.on("npcLine", (id, line) => npcMessage(id, line));
    let lastNode = "";
    en.on("choices", (nodeId, opts, k) => {
      showContext(nodeId);
      if (nodeId !== lastNode && (qubiKind === "hint" || qubiKind === "pay")) $("qubiBubble").hidden = true;
      lastNode = nodeId;
      if (k === "pay") qubi(T("qubi_pay"), "pay");
      renderChoices(opts, k);
    });
    en.on("hint", (h) => qubi(T("qubi_hint") + " " + h, "hint"));
    en.on("evaluated", (result, fb, model) => {
      feedback(result, fb, model);
      if (result === "correct") {
        Snd.sfx("success", 0.5);
        if (Math.random() < 0.35) qubi(T("qubi_cheer"));
      } else {
        Snd.sfx(result === "unknown" ? "hint" : "wrong", 0.5);
        if (result === "wrong") qubi(T("qubi_oops"));
      }
      if (result === "correct" && en.node().type === "pay") { Snd.sfx("till_beep"); setTimeout(() => Snd.sfx("coin"), 350); setTimeout(() => Snd.sfx("coin", 0.8), 650); }
      if (result === "correct" && en.nodeId === "bag") Snd.sfx("paper_bag");
    });
    en.on("finished", async (summary) => {
      ended = true;
      $("answer").hidden = true;
      $("context").innerHTML = "";
      qubi(T("qubi_done"));
      await Snd.say("s_closing", false);
      await wait(400);
      Snd.sfx("shop_bell");
      showActions([[T("see_summary"), () => showResults(summary), true]]);
    });
  }

  function showActions(list) {
    const row = $("sceneActions");
    row.innerHTML = "";
    list.forEach(([label, fn, primary]) => {
      const b = el("button", "btn " + (primary ? "primary" : "ghost"), esc(label));
      b.onclick = () => { Snd.sfx("ui_click", 0.6); fn(); };
      row.appendChild(b);
    });
  }

  // ------------------------------------------------------------- flow
  function enterStage() {
    document.body.classList.remove("title-mode");
    $("titleScreen").hidden = true;
    $("results").hidden = true;
    $("stage").hidden = false;
    $("topbar").hidden = false;
    log().innerHTML = "";
    $("context").innerHTML = "";
    $("answer").hidden = true;
    $("qubiBubble").hidden = true;
    ended = false;
    renderObjectives();
  }

  function sceneStreet() {
    enterStage();
    setBg("street");
    Snd.ambience("street_amb");
    Snd.coffee(false);
    qubi(T("qubi_welcome"));
    let asked = false;
    const actions = () => showActions([
      ...(asked ? [] : [[T("ask_way"), askWay, false]]),
      [T("enter"), enterBakery, true],
    ]);
    async function askWay() {
      asked = true;
      $("sceneActions").innerHTML = "";
      myMessage(T("ask_way_de"));
      npcMessage("p_way", engine.line("p_way"));
      await wait(600);
      qubi(T("qubi_way"));
      actions();
    }
    actions();
  }

  async function enterBakery(resume) {
    $("sceneActions").innerHTML = "";
    Snd.stopVoice();
    Snd.sfx("shop_bell");
    setBg("counter");
    Snd.ambience("bakery_amb");
    Snd.coffee(true);
    log().innerHTML = "";
    engine.complete("enter");
    qubi(T("qubi_enter"));
    if (resume === true) { await wait(700); engine.begin(); return; }
    showActions([[T("talk"), () => { $("sceneActions").innerHTML = ""; engine.begin(); }, true]]);
  }

  function start(resume) {
    engine.reset();
    if (resume && engine.restoreCheckpoint()) {
      enterStage();
      enterBakery(true);
    } else {
      engine.clearCheckpoint();
      sceneStreet();
    }
  }

  function showResults(sum) {
    Snd.stopVoice();
    Snd.coffee(false);
    Snd.ambience("street_amb");
    setBg("cafe");
    $("stage").hidden = true;
    $("topbar").hidden = true;
    $("results").hidden = false;
    $("results").scrollTop = 0;
    $("scoreNum").textContent = sum.score;
    $("scoreArc").style.strokeDashoffset = 327;
    requestAnimationFrame(() => requestAnimationFrame(() => { $("scoreArc").style.strokeDashoffset = 327 * (1 - sum.score / 100); }));
    $("resMeta").textContent = T("meta").replace("%h", sum.hints).replace("%b", sum.best).replace("%a", sum.attempts);
    const er = $("resErrors");
    er.innerHTML = sum.errors.length ? "" : '<li class="none">' + esc(T("no_errors")) + "</li>";
    sum.errors.forEach((e) => {
      er.appendChild(el("li", "", "<b>" + esc(e.label) + "</b> · " + esc(T("you_said")) + " « " + esc(e.given) + " »<br>" + esc(e.explanation)));
    });
    $("resVocab").innerHTML = sum.vocabulary.map((v) => "<li><b>" + esc(v.de) + (v.pl ? " · " + esc(v.pl) : "") + "</b><span>" + esc(MissionEngine.pick(v, S.lang)) + "</span></li>").join("");
    $("resGrammar").innerHTML = sum.grammar.map((g) => "<li>" + esc(MissionEngine.pick(g, S.lang)) + "</li>").join("");
    Snd.sfx("success", 0.7);
  }

  function toTitle() {
    Snd.stopVoice();
    Snd.coffee(false);
    Snd.ambience("");
    $("stage").hidden = true;
    $("topbar").hidden = true;
    $("results").hidden = true;
    $("titleScreen").hidden = false;
    document.body.classList.add("title-mode");
    setBg("breadstack");
    $("resumeBtn").hidden = !engine.hasCheckpoint();
  }

  // ------------------------------------------------------------- controls
  $("startBtn").onclick = () => start(false);
  $("resumeBtn").onclick = () => start(true);
  $("againBtn").onclick = () => start(false);
  $("hintBtn").onclick = () => { Snd.sfx("hint", 0.5); engine.hint(); };
  $("freeForm").onsubmit = (e) => {
    e.preventDefault();
    const v = $("freeInput").value.trim();
    if (!v || ended) return;
    lockAnswers();
    myMessage(v);
    engine.submitFree(v);
  };
  document.querySelectorAll(".lang-switch button").forEach((b) => (b.onclick = () => { S.lang = b.dataset.lang; saveSettings(); applyLang(); }));
  $("objBtn").onclick = () => { const p = $("objPanel"); p.hidden = !p.hidden; $("objBtn").setAttribute("aria-expanded", String(!p.hidden)); };
  $("soundBtn").onclick = () => { S.muted = !S.muted; saveSettings(); renderSound(); Snd.refreshVolumes(); };
  $("settingsBtn").onclick = () => {
    $("setLang").value = S.lang; $("setTrans").checked = S.trans; $("setSubs").checked = S.subs;
    $("volVoice").value = S.vVoice; $("volSfx").value = S.vSfx; $("volAmb").value = S.vAmb;
    $("settings").showModal();
  };
  $("setLang").onchange = (e) => { S.lang = e.target.value; saveSettings(); applyLang(); };
  $("setTrans").onchange = (e) => { S.trans = e.target.checked; saveSettings(); document.querySelectorAll(".msg .tr").forEach((t) => { t.hidden = !S.trans; }); };
  $("setSubs").onchange = (e) => { S.subs = e.target.checked; saveSettings(); };
  [["volVoice", "vVoice"], ["volSfx", "vSfx"], ["volAmb", "vAmb"]].forEach(([id, k]) => ($(id).oninput = (e) => { S[k] = parseFloat(e.target.value); saveSettings(); Snd.refreshVolumes(); }));
  $("settings").addEventListener("close", () => { if ($("settings").returnValue === "restart") { engine.reset(); engine.clearCheckpoint(); toTitle(); } });
  document.addEventListener("keydown", (e) => {
    if (e.target.tagName === "INPUT" || e.target.tagName === "SELECT" || $("settings").open) return;
    if (!$("answer").hidden && /^[1-4]$/.test(e.key)) {
      const b = $("choices").children[parseInt(e.key, 10) - 1];
      if (b) b.click();
    } else if (e.key === "h" || e.key === "H") { if (!$("answer").hidden) $("hintBtn").click(); }
    else if (e.key === "r" || e.key === "R") { const p = [...document.querySelectorAll(".msg:not(.me) .pill[data-line]")].pop(); if (p) p.click(); }
  });

  boot().catch((err) => { document.body.innerHTML = '<p style="padding:24px">Erreur de chargement : ' + esc(err.message) + "</p>"; });
  window.__dq = { get engine() { return engine; }, Snd, S };
})();
