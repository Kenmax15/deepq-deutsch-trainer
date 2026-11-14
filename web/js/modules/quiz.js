/* DeepQ Quiz Arena (modules 06, 28 and §6): one common engine, many short formats.
 * Every question: { prompt (node), say?, options[], answer, explain, cat }. Timer and sounds can be switched off. */
(function () {
  "use strict";
  const DQ = window.DQ;
  const { h, _ } = DQ;
  const S = DQ.store;
  const R = DQ.routes = DQ.routes || {};

  const nouns = () => DQ.lexicon.filter((e) => e.type === "noun" && e.art && e.emoji);
  const learned = (list) => { const p = S.profile(); const l = list.filter((e) => p.introduced[e.id]); return l.length >= 8 ? l : list; };

  // ---- question generators
  const GEN = {
    article() {
      const e = DQ.sample(learned(nouns()), 1)[0];
      return { prompt: h("div", h("div.emoji-xl", e.emoji), h("div.big-de", "___ " + e.de)), say: null, options: ["der", "die", "das"], answer: e.art,
        explain: e.art + " " + e.de + " — " + DQ.tr(e), cat: "article", after: () => DQ.say(e.say, { id: e.id }) };
    },
    mystery() { // image mystère: noun, article and plural assessed separately (R03)
      const e = DQ.sample(learned(nouns().filter((x) => x.pl)), 1)[0];
      return { mystery: e };
    },
    listen() {
      const pool = learned(DQ.lexicon.filter((x) => x.emoji && (x.type === "noun" || x.type === "verb" || x.type === "adj")));
      const e = DQ.sample(pool, 1)[0];
      const others = DQ.sample(pool.filter((x) => x.id !== e.id && x.emoji !== e.emoji), 3);
      return { prompt: h("div", h("div", { style: { fontSize: "54px" } }, "🎧"), h("b", _("Écoute et choisis l’image", "Listen and pick the picture"))),
        say: [e.say, e.id], options: DQ.shuffle([e, ...others]).map((x) => x.emoji + " " + DQ.tr(x)), answer: e.emoji + " " + DQ.tr(e), explain: e.say + " = " + DQ.tr(e), cat: "vocab", big: true };
    },
    meaning() {
      const pool = learned(DQ.lexicon.filter((x) => x.type !== "num"));
      const e = DQ.sample(pool, 1)[0];
      const others = DQ.sample(pool.filter((x) => x.id !== e.id && x.type === e.type), 3);
      return { prompt: h("div", h("div.big-de", (e.art ? e.art + " " : "") + e.de)), say: [e.say, e.id], options: DQ.shuffle([e, ...others]).map((x) => DQ.tr(x)), answer: DQ.tr(e), explain: (e.emoji || "") + " " + e.de + " = " + DQ.tr(e), cat: "vocab" };
    },
    truefalse() {
      const [st, val, fr, en] = DQ.sample(DQ_DATA.truefalse, 1)[0];
      const T = _("Vrai", "True"), F = _("Faux", "False");
      return { prompt: h("div", { style: { fontSize: "21px", fontWeight: 650 } }, st), options: [T, F], answer: val ? T : F, explain: _(fr, en), cat: "grammar" };
    },
    error() {
      const it = DQ.sample(DQ_DATA.errors, 1)[0];
      return { prompt: h("div", h("b", _("Touche le mot faux", "Tap the wrong word"))), options: it.s, answer: it.s[it.bad], keepOrder: true, inline: true,
        explain: "→ " + it.fix + " · " + _(it.why[0], it.why[1]), cat: "grammar" };
    },
    conj() {
      const v = DQ.sample(DQ_DATA.verbs.filter((x) => !x.refl), 1)[0];
      const forms = DQ.conj.present(v);
      const i = Math.floor(Math.random() * 6);
      const pron = DQ.conj.PERSONS[i].split("/")[0];
      const opts = DQ.shuffle([...new Set(forms)]).slice(0, 4);
      if (!opts.includes(forms[i])) opts[0] = forms[i];
      return { prompt: h("div", h("div.small.muted", v.inf + " · Präsens"), h("div.big-de", pron + " ___")), options: DQ.shuffle(opts), answer: forms[i], explain: pron + " " + forms[i], cat: "verb" };
    },
    plural() {
      const e = DQ.sample(learned(nouns().filter((x) => x.pl)), 1)[0];
      const fakes = DQ.shuffle([...new Set([e.de + "s", e.de + "en", e.de + "e", e.de + "er"].filter((x) => x !== e.pl))]).slice(0, 2);
      return { prompt: h("div", h("div.emoji-xl", e.emoji), h("div.big-de", e.art + " " + e.de + " → die ___")), options: DQ.shuffle([e.pl, ...fakes]), answer: e.pl, explain: "die " + e.pl, cat: "plural" };
    },
  };
  const FORMATS = [
    ["article", "🎨", "Trouve l’article", "Find the article", ["article"]],
    ["mystery", "🕵️", "Image mystère", "Mystery picture", ["mystery"]],
    ["listen", "🎧", "Écoute et choisis", "Listen and choose", ["listen"]],
    ["truefalse", "✅", "Vrai ou faux", "True or false", ["truefalse"]],
    ["error", "🔍", "Trouve l’erreur", "Spot the mistake", ["error"]],
    ["conj", "🔤", "Conjugaison express", "Quick conjugation", ["conj"]],
    ["timed", "⏱️", "Défi 60 secondes", "60-second challenge", ["article", "meaning", "plural", "conj", "listen"]],
    ["duel", "🤖", "Duel contre Qubi", "Duel against Qubi", ["meaning", "article", "plural", "truefalse", "conj"]],
    ["mix", "🎲", "Mélange", "Mix", ["article", "meaning", "plural", "truefalse", "error", "conj", "listen", "mystery"]],
  ];

  R.quiz = (args, params, onCleanup) => {
    const p = S.profile();
    if (args[0] === "build") { DQ.go("build"); return null; }
    if (args[0]) return play(FORMATS.find((f) => f[0] === args[0]) || FORMATS[0], onCleanup);
    const vert = h("label.check", h("input", { type: "checkbox", checked: !!p.quiz.vertical, onchange: (e) => { p.quiz.vertical = e.target.checked; S.save(); } }), _("Format vertical 9:16 (style vidéo courte)", "Vertical 9:16 format (short-video style)"));
    const timer = h("label.check", h("input", { type: "checkbox", checked: p.quiz.timer !== false, onchange: (e) => { p.quiz.timer = e.target.checked; S.save(); } }), _("Chronomètre (10 s par question)", "Timer (10 s per question)"));
    return h("div.stack.fade-in", h("h1", "DeepQ Quiz Arena"),
      DQ.qubiSays(_("Des quiz courts, rapides et visuels. Tes erreurs vont dans le journal, tes réponses nourrissent tes révisions.", "Short, quick, visual quizzes. Your mistakes go to the journal, your answers feed your reviews.")),
      h("div.grid.g3", FORMATS.map((f) => h("a.tile", { href: "#/quiz/" + f[0] }, h("div.ic", f[1]), h("b", _(f[2], f[3])),
        h("span", (p.quiz.best[f[0]] !== undefined ? _("Record : ", "Best: ") + p.quiz.best[f[0]] : _("Pas encore joué", "Not played yet")))))),
      h("a.tile", { href: "#/build" }, h("div.ic", "🧩"), h("b", _("Construis la phrase", "Build the sentence")), h("span", _("Remets les mots dans l’ordre", "Put the words in order"))),
      h("div.card.stack", h("b", _("Réglages", "Settings")), timer, vert,
        h("label.check", h("input", { type: "checkbox", checked: p.prefs.sfx, onchange: (e) => { p.prefs.sfx = e.target.checked; S.save(); } }), _("Effets sonores", "Sound effects"))));
  };

  function play(fmt, onCleanup) {
    const p = S.profile();
    const [key, icon, fr, en, gens] = fmt;
    const timed = key === "timed", duel = key === "duel";
    const N = timed ? 999 : 10;
    const arena = h("div.arena.stack" + (p.quiz.vertical ? ".vertical" : ""));
    let n = 0, score = 0, qubiScore = 0, tLeft = 60, tick = 0, qTimer = 0, ended = false;
    const header = h("div.spread");
    const body = h("div.stack");
    arena.append(h("a.small", { href: "#/quiz", style: { color: "inherit" } }, "← Quiz Arena"), header, body);
    const updHeader = () => {
      header.innerHTML = "";
      header.append(h("b", icon + " " + _(fr, en)),
        duel ? h("span.pill", _("Toi ", "You ") + score + " – " + qubiScore + " Qubi") : h("span.pill.q", (timed ? "⏱ " + tLeft + " s · " : (n + "/" + N + " · ")) + score + " pts"));
    };
    const finish = () => {
      if (ended) return; ended = true;
      clearInterval(tick); clearTimeout(qTimer);
      const best = p.quiz.best[key] || 0;
      if (score > best) p.quiz.best[key] = score;
      p.quiz.played = (p.quiz.played || 0) + 1; S.save();
      body.innerHTML = "";
      const won = duel ? score > qubiScore : null;
      body.append(h("div.reveal", { style: { textAlign: "center" } }, DQ.qubiFace(duel ? (won ? "sleepy" : "cheer") : "happy", 80),
        h("h1", duel ? (won ? _("Tu as battu Qubi !", "You beat Qubi!") : score === qubiScore ? _("Égalité !", "Draw!") : _("Qubi gagne cette fois…", "Qubi wins this time…")) : score + " " + _("points", "points")),
        score > best ? h("p", "🏆 " + _("Nouveau record !", "New record!")) : h("p.muted", _("Record : ", "Best: ") + Math.max(best, score))),
        h("div.row", { style: { justifyContent: "center" } }, h("button.btn.primary", { onclick: () => DQ.render() }, _("Rejouer", "Play again")), h("a.btn", { href: "#/quiz" }, "Quiz Arena")));
      DQ.sfx("success", 0.5);
    };
    const next = () => {
      clearTimeout(qTimer);
      if (ended) return;
      if (n >= N) return finish();
      n++; updHeader();
      const g = GEN[DQ.sample(gens, 1)[0]]();
      body.innerHTML = "";
      if (g.mystery) return mystery(g.mystery);
      const box = h("div.stack.reveal", { style: { textAlign: "center" } }, g.prompt);
      if (g.say) { box.append(h("div", DQ.speakBtn(g.say[0], g.say[1], true))); setTimeout(() => DQ.say(g.say[0], { id: g.say[1] }), 200); }
      const bar = h("div.timer", h("i", { style: { width: "100%" } }));
      if (!timed && p.quiz.timer !== false) { box.append(bar); requestAnimationFrame(() => requestAnimationFrame(() => { bar.firstChild.style.transition = "width 10s linear"; bar.firstChild.style.width = "0%"; })); }
      const opts = h(g.inline ? "div.chips" : "div.stack", { style: g.inline ? { justifyContent: "center" } : {} });
      const answer = (o, btn) => {
        clearTimeout(qTimer);
        const ok = o === g.answer;
        opts.querySelectorAll("button").forEach((b) => { b.disabled = true; if (b.dataset.v === g.answer) b.classList.add("right"); });
        if (btn && !ok) btn.classList.add("wrong");
        if (ok) score += timed ? 1 : 10;
        DQ.sfx(ok ? "success" : "wrong", 0.4);
        DQ.learn.exercise(ok, { module: "quiz", cat: g.cat, q: g.prompt.textContent.slice(0, 120), given: o || "—", right: g.answer, why: g.explain });
        if (duel) { const qubiRight = Math.random() < 0.72; if (qubiRight) qubiScore += 10; box.append(h("div.small", "🤖 Qubi " + (qubiRight ? _("a trouvé", "got it") : _("s’est trompé", "got it wrong")))); }
        updHeader();
        box.append(h("div.fb." + (ok ? "ok" : "bad"), h("b", ok ? "Richtig!" : _("Réponse : ", "Answer: ") + g.answer), g.explain));
        if (g.after) g.after();
        setTimeout(next, timed ? 650 : ok ? 1300 : 2200);
      };
      (g.keepOrder ? g.options : g.options).forEach((o) => {
        const b = h(g.inline ? "button.word-chip" : "button.choice", { "data-v": o, onclick: (e) => answer(o, e.currentTarget) }, o);
        if (g.big) b.style.fontSize = "18px";
        opts.append(b);
      });
      box.append(opts);
      body.append(box);
      if (!timed && p.quiz.timer !== false) qTimer = setTimeout(() => answer(null, null), 10000);
    };
    // image mystère: name, article and plural evaluated separately
    const mystery = (e) => {
      const steps = [["word", _("Quel est ce mot ?", "What is this word?"), e.de], ["art", _("Son article ?", "Its article?"), e.art], ["pl", _("Son pluriel ?", "Its plural?"), e.pl]];
      let k = 0;
      const res = {};
      const box = h("div.stack.reveal", { style: { textAlign: "center" } }, h("div.emoji-xl", e.emoji));
      const zone = h("div.stack");
      box.append(zone);
      body.append(box);
      const step = () => {
        zone.innerHTML = "";
        if (k >= steps.length) {
          const pts = Object.values(res).filter(Boolean).length;
          score += pts * 4;
          updHeader();
          zone.append(h("div.fb." + (pts === 3 ? "ok" : pts ? "mid" : "bad"), h("b", e.art + " " + e.de + " · die " + e.pl),
            [["word", _("Nom", "Noun")], ["art", _("Article", "Article")], ["pl", _("Pluriel", "Plural")]].map(([x, l]) => h("span.pill." + (res[x] ? "ok" : "bad"), (res[x] ? "✔ " : "✘ ") + l))));
          DQ.say(e.say, { id: e.id });
          ["word", "art", "pl"].forEach((x) => { if (!res[x]) S.logError({ module: "quiz", cat: x === "art" ? "article" : x === "pl" ? "plural" : "vocab", q: e.emoji + " " + DQ.tr(e), given: "", right: x === "pl" ? e.pl : x === "art" ? e.art : e.de }); });
          DQ.learn.grade(e.id, "use", pts === 3 ? 4 : pts === 2 ? 3 : 1);
          setTimeout(next, 2200);
          return;
        }
        const [key2, q, right] = steps[k];
        let opts;
        if (key2 === "art") opts = ["der", "die", "das"];
        else if (key2 === "pl") opts = DQ.shuffle([e.pl, ...[e.de + "s", e.de + "en", e.de + "e"].filter((x) => x !== e.pl).slice(0, 2)]);
        else opts = DQ.shuffle([e.de, ...DQ.sample(nouns().filter((x) => x.id !== e.id), 2).map((x) => x.de)]);
        zone.append(h("b", q), h("div.stack", opts.map((o) => h("button.choice", { onclick: (ev) => {
          res[key2] = o === right; DQ.sfx(res[key2] ? "success" : "wrong", 0.35);
          zone.querySelectorAll("button").forEach((b) => { b.disabled = true; if (b.textContent === right) b.classList.add("right"); });
          if (!res[key2]) ev.currentTarget.classList.add("wrong");
          setTimeout(() => { k++; step(); }, 700);
        } }, o))));
      };
      step();
    };
    if (onCleanup) onCleanup(() => { ended = true; clearInterval(tick); clearTimeout(qTimer); });
    updHeader();
    if (timed) tick = setInterval(() => { tLeft--; updHeader(); if (tLeft <= 0) finish(); }, 1000);
    next();
    return arena;
  }
})();
