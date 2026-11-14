/* Grammar book (13, 07), conjugation book (12), sentence building (20), word families (21). */
(function () {
  "use strict";
  const DQ = window.DQ;
  const { h, _ } = DQ;
  const S = DQ.store;
  const R = DQ.routes = DQ.routes || {};

  // ------------------------------------------------------------- grammar book
  R.grammar = (args) => {
    const p = S.profile();
    const lessons = DQ_DATA.grammar;
    if (args[0]) return lesson(lessons.find((l) => l.id === args[0]) || lessons[0]);
    const st = { q: "", fav: false };
    const list = h("div.grid.g2");
    const draw = () => {
      list.innerHTML = "";
      const q = DQ.fold(st.q);
      lessons.filter((l) => (!st.fav || (p.grammar[l.id] || {}).fav) && (!q || DQ.fold(l.de + " " + l.fr + " " + l.en + " " + l.intro.fr + " " + l.intro.en).includes(q))).forEach((l, i) => {
        const g = p.grammar[l.id] || {};
        list.append(h("a.tile", { href: "#/grammar/" + l.id },
          h("div.spread", h("span.pill", "A1 · " + (lessons.indexOf(l) + 1)), g.best !== undefined ? h("span.pill." + (g.best >= 0.8 ? "ok" : "mid"), Math.round(g.best * 100) + " %") : null, g.fav ? "⭐" : null),
          h("b", l.de), h("span", _(l.fr, l.en))));
      });
    };
    draw();
    return h("div.stack.fade-in", h("h1", "DeepQ Grammatikbuch — A1"),
      h("div.row", h("input", { type: "search", placeholder: _("Chercher : accusatif, pluriel, Perfekt…", "Search: accusative, plural, Perfekt…"), oninput: (e) => { st.q = e.target.value; draw(); }, style: { flex: 1 } }),
        h("label.check", h("input", { type: "checkbox", onchange: (e) => { st.fav = e.target.checked; draw(); } }), "⭐ " + _("Favoris", "Favourites"))),
      list,
      h("p.small.muted", _("Contenu de référence validé. Les niveaux A2 à C1 seront ajoutés progressivement.", "Validated reference content. Levels A2 to C1 will be added step by step.")));
  };

  function lesson(l) {
    const p = S.profile();
    const g = (p.grammar[l.id] = p.grammar[l.id] || {});
    const exBox = h("div.stack");
    let idx = 0, score = 0;
    const order = DQ.shuffle(l.ex.map((_x, i) => i));
    const drawEx = () => {
      exBox.innerHTML = "";
      if (idx >= order.length) {
        const r = score / order.length;
        g.best = Math.max(g.best || 0, r); g.done = Date.now(); S.save();
        exBox.append(h("div.fb." + (r >= 0.8 ? "ok" : "mid"), h("b", _("Résultat : ", "Result: ") + score + " / " + order.length),
          r >= 0.8 ? _("Leçon validée !", "Lesson passed!") : _("Relis l’explication et réessaie : 4/5 valide la leçon.", "Reread the explanation and try again: 4/5 passes the lesson.")),
          h("button.btn", { onclick: () => { idx = 0; score = 0; drawEx(); } }, _("Recommencer", "Try again")));
        return;
      }
      const x = l.ex[order[idx]];
      const card = h("div.card.stack",
        h("span.pill", (idx + 1) + " / " + order.length),
        h("div", { style: { fontSize: "21px", fontWeight: 650 } }, x.q.replace("___", "____")));
      const opts = DQ.shuffle(x.opts.map((o, i) => [o, i]));
      opts.forEach(([o, i]) => card.append(h("button.choice", { onclick: (ev) => {
        const ok = i === x.a;
        card.querySelectorAll(".choice").forEach((b) => (b.disabled = true));
        ev.currentTarget.classList.add(ok ? "right" : "wrong");
        if (!ok) card.querySelectorAll(".choice").forEach((b) => { if (b.textContent === x.opts[x.a]) b.classList.add("right"); });
        if (ok) score++;
        DQ.sfx(ok ? "success" : "wrong");
        DQ.learn.exercise(ok, { module: "grammar", lesson: l.id, cat: DQ.learn.LESSON_CAT[l.id] || "grammar", q: x.q, given: o, right: x.opts[x.a], why: _(x.why) });
        const sentence = x.q.replace("___", x.opts[x.a]).replace(/\s*\(.*?\)/g, "");
        card.append(h("div.fb." + (ok ? "ok" : "bad"), h("b", ok ? _("Richtig !", "Richtig!") : _("Pas tout à fait", "Not quite")), _(x.why)),
          h("div.row", DQ.speakBtn(sentence), h("button.btn.primary", { onclick: () => { idx++; drawEx(); } }, _("Suivant", "Next"))));
      } }, o)));
      exBox.append(card);
    };
    drawEx();
    const star = h("button.btn.small", { onclick: () => { g.fav = !g.fav; S.save(); star.textContent = g.fav ? "⭐ " + _("Favori", "Favourite") : "☆ " + _("Ajouter aux favoris", "Add to favourites"); } }, g.fav ? "⭐ " + _("Favori", "Favourite") : "☆ " + _("Ajouter aux favoris", "Add to favourites"));
    const i = DQ_DATA.grammar.indexOf(l);
    const nextL = DQ_DATA.grammar[i + 1];
    return h("div.stack.fade-in",
      h("a.small", { href: "#/grammar" }, "← Grammatikbuch"),
      h("div.spread", h("div", h("span.pill", "A1 · " + (i + 1)), h("h1", { style: { marginTop: "8px" } }, l.de), h("div.muted", _(l.fr, l.en))), star),
      h("div.card.lesson-body", { html: _(l.intro) }),
      l.tables.map((t) => h("div.card", { style: { overflowX: "auto" } }, h("table.t", h("tr", t.head.map((c) => h("th", c))), t.rows.map((r) => h("tr", r.map((c) => h("td", { html: c }))))))),
      h("div.card.stack", h("b", _("Exemples", "Examples")), l.examples.map((x, k) => h("div.spread", h("div", h("div", { style: { fontSize: "17px", fontWeight: 600 } }, x[0]), h("div.small.muted", DQ.lang() === "en" ? x[2] : x[1])), DQ.speakBtn(x[0], "g_" + l.id + "_" + k, true)))),
      h("div.row", h("a.btn.small", { href: "#/tutor?q=" + encodeURIComponent(_("Explique autrement : ", "Explain differently: ") + l.de) }, "🧑‍🏫 " + _("Explication alternative", "Alternative explanation"))),
      h("h2", _("Exercices", "Exercises")), exBox,
      nextL ? h("a.btn", { href: "#/grammar/" + nextL.id }, _("Leçon suivante : ", "Next lesson: ") + nextL.de + " →") : null);
  }

  // ------------------------------------------------------------- conjugation book
  const TENSES = [["praesens", "Präsens", "présent", "present"], ["perfekt", "Perfekt", "passé composé", "perfect"], ["praeteritum", "Präteritum", "prétérit", "simple past"],
    ["futur", "Futur I", "futur", "future"], ["plusquamperfekt", "Plusquamperfekt", "plus-que-parfait", "past perfect"], ["konjunktiv2", "Konjunktiv II", "subjonctif II", "subjunctive II"]];
  R.conj = (args) => {
    const box = h("div.stack.fade-in");
    const res = h("div.stack");
    const show = (q) => {
      res.innerHTML = "";
      const k = (q || "").trim().toLowerCase().replace(/^(ich|du|er|sie|es|wir|ihr) /, "");
      if (!k) return;
      const v = DQ.verbIndex.get(k) || DQ.verbIndex.get(k.replace(/^sich /, ""));
      if (!v) {
        res.append(h("div.fb.mid", h("b", _("Verbe pas encore dans le livre de conjugaison A1.", "Verb not yet in the A1 conjugation book.")),
          _("Les verbes ajoutés par l’IA doivent d’abord être validés. Tu peux demander au tuteur.", "Verbs suggested by AI must be validated first. You can ask the tutor."),
          h("div", h("a.btn.small", { href: "#/tutor?q=" + encodeURIComponent(_("Conjugue le verbe ", "Conjugate the verb ") + q) }, "🧑‍🏫 " + _("Demander au tuteur", "Ask the tutor")))));
        return;
      }
      const t = DQ.conj.table(v);
      const isForm = k !== v.inf && k !== v.inf.replace(/^sich /, "");
      res.append(h("div.card.stack",
        isForm ? h("div.pill.q", "« " + q + " » → " + v.inf) : null,
        h("div.spread", h("div", h("div.big-de", v.emoji + " " + v.inf), h("div.muted", v.fr + " · " + v.en)), DQ.speakBtn(v.inf, "v_" + DQ.lex.slug(v.inf), true)),
        h("div.row", h("span.pill", _("Auxiliaire : ", "Auxiliary: ") + v.aux), h("span.pill", "Partizip II : " + v.pp), v.sep ? h("span.pill.q", _("séparable : ", "separable: ") + v.sep + "-") : null,
          v.refl ? h("span.pill.q", _("pronominal", "reflexive")) : null, v.modal ? h("span.pill.q", _("verbe de modalité", "modal verb")) : null, v.obj ? h("span.pill", v.obj) : null,
          (v.pres || v.prt || v.prtFull) ? h("span.pill.mid", _("irrégulier", "irregular")) : h("span.pill.ok", _("régulier", "regular"))),
        h("div", h("i", v.ex[0]), " — ", h("span.muted", DQ.lang() === "en" ? v.ex[2] : v.ex[1]))),
        h("div.grid.g3", TENSES.filter(([key]) => t[key]).map(([key, de, fr, en]) => h("div.card",
          h("div.spread", h("b", de), h("span.small.muted", _(fr, en))),
          h("table.t", t[key].map((f) => h("tr", h("td", f), h("td", { style: { width: "40px" } }, DQ.speakBtn(f))))))),
          h("div.card", h("div.spread", h("b", "Imperativ"), h("span.small.muted", _("impératif", "imperative"))), h("table.t", t.imperativ.map((f, i) => h("tr", h("td.small.muted", ["du", "ihr", "Sie"][i]), h("td", f), h("td", DQ.speakBtn(f))))))),
        drill(v, t));
    };
    const inp = h("input", { type: "search", value: args[0] || "", placeholder: _("Infinitif ou forme conjuguée : gehen, isst, kaufe ein…", "Infinitive or conjugated form: gehen, isst, kaufe ein…"), oninput: (e) => show(e.target.value) });
    box.append(h("h1", _("Livre de conjugaison", "Conjugation book")), inp,
      h("div.chips", DQ_DATA.verbs.map((v) => h("button.chip", { onclick: () => { inp.value = v.inf; show(v.inf); } }, v.inf))), res);
    if (args[0]) show(args[0]);
    return box;
  };
  /** Quick self-test on the verb shown. */
  function drill(v, t) {
    const box = h("div.card.stack", h("b", "🎯 " + _("Teste-toi", "Test yourself")));
    const go = () => {
      box.querySelectorAll(".q").forEach((n) => n.remove());
      const [key, de] = DQ.sample(TENSES.filter(([k]) => t[k] && k !== "plusquamperfekt"), 1)[0];
      const i = Math.floor(Math.random() * 6);
      const full = t[key][i];
      const pron = full.split(" ")[0];
      const answer = full.slice(pron.length + 1);
      const inp = h("input", { type: "text", lang: "de", autocomplete: "off", spellcheck: "false" });
      const fb = h("div");
      const q = h("div.q.stack", h("div", de + " · ", h("b", pron), " … (" + v.inf + ")"),
        h("form.row", { onsubmit: (e) => { e.preventDefault(); const ok = DQ.sameGerman(inp.value, answer); DQ.sfx(ok ? "success" : "wrong");
          DQ.learn.exercise(ok, { module: "conj", cat: "verb", q: de + " " + pron + " (" + v.inf + ")", given: inp.value, right: answer });
          fb.innerHTML = ""; fb.append(h("div.fb." + (ok ? "ok" : "bad"), h("b", ok ? "Richtig!" : _("Réponse : ", "Answer: ") + full), h("button.btn.small", { onclick: go }, _("Une autre", "Another one")))); } },
          inp, h("button.btn.primary", _("Vérifier", "Check"))), fb);
      box.append(q);
    };
    go();
    return box;
  }

  // ------------------------------------------------------------- sentence building (20)
  R.build = () => {
    const list = DQ.shuffle(DQ_DATA.sentences);
    let i = 0, ok = 0;
    const box = h("div.stack.fade-in");
    const draw = () => {
      box.innerHTML = "";
      if (i >= list.length) { box.append(h("h1", _("Bravo !", "Well done!")), DQ.qubiSays(ok + " / " + list.length + _(" phrases construites du premier coup.", " sentences built first time."), "happy"), h("button.btn", { onclick: () => DQ.render() }, _("Rejouer", "Play again"))); return; }
      const [de, fr, en] = list[i];
      const words = de.split(" ");
      const picked = [];
      const line = h("div.answer-line");
      const bank = h("div.chips");
      let tries = 0;
      const refresh = () => {
        line.innerHTML = ""; bank.innerHTML = "";
        picked.forEach((w, k) => line.append(h("button.word-chip", { onclick: () => { picked.splice(k, 1); refresh(); } }, w.t)));
        pool.forEach((w) => bank.append(h("button.word-chip" + (picked.includes(w) ? ".used" : ""), { disabled: picked.includes(w), onclick: () => { picked.push(w); refresh(); } }, w.t)));
      };
      const pool = DQ.shuffle(words.map((t, k) => ({ t, k })));
      const fb = h("div");
      box.append(h("h1", _("Construire des phrases", "Build sentences")), h("span.pill", (i + 1) + " / " + list.length),
        h("div.card.stack", h("div", { style: { fontSize: "19px" } }, DQ.lang() === "en" ? en : fr), line, bank,
          h("div.row", h("button.btn.primary", { onclick: () => {
            const ans = picked.map((w) => w.t).join(" ");
            const good = ans === de; tries++;
            fb.innerHTML = "";
            if (good) { if (tries === 1) ok++; DQ.sfx("success"); DQ.say(de, { id: "s_" + DQ_DATA.sentences.indexOf(list[i]) });
              DQ.learn.exercise(true);
              fb.append(h("div.fb.ok", h("b", "Richtig!"), de), h("button.btn", { onclick: () => { i++; draw(); } }, _("Suivante", "Next")));
            } else {
              DQ.sfx("wrong");
              const verbPos = words.findIndex((w) => DQ.verbIndex.get(w.replace(/[?.!,]/g, "").toLowerCase()));
              DQ.learn.exercise(false, { module: "build", cat: "wordorder", q: DQ.lang() === "en" ? en : fr, given: ans, right: de });
              fb.append(h("div.fb.bad", h("b", _("Pas encore", "Not yet")), verbPos >= 0 ? _("Indice : le verbe conjugué « " + words[verbPos].replace(/[?.!,]/g, "") + " » est en position " + (verbPos + 1) + ".", "Hint: the conjugated verb “" + words[verbPos].replace(/[?.!,]/g, "") + "” is in position " + (verbPos + 1) + ".") : _("Regarde la place du verbe.", "Check where the verb goes.")),
                tries >= 2 ? h("button.btn.small", { onclick: () => { fb.append(h("div.fb.mid", de)); } }, _("Voir la solution", "Show the answer")) : null);
            }
          } }, _("Vérifier", "Check")), h("button.btn.ghost", { onclick: () => { picked.length = 0; refresh(); } }, _("Effacer", "Clear"))), fb));
      refresh();
    };
    draw();
    return box;
  };

  // ------------------------------------------------------------- word families (21)
  R.families = () => h("div.stack.fade-in",
    h("h1", _("Familles de mots", "Word families")),
    DQ.qubiSays(_("Un mot en apprend d’autres : repère la racine commune. Touche « Réviser » pour ajouter la famille à tes révisions.", "One word teaches you others: spot the common root. Tap “Review” to add the family to your reviews.")),
    h("div.grid.g2", DQ_DATA.families.map((f) => {
      const linked = f.members.map((m) => DQ.forms.get(DQ.fold(m[0].replace(/^(der|die|das) /, "")))).filter(Boolean);
      return h("div.card.stack",
        h("div.spread", h("b", { style: { fontSize: "19px" } }, "🌳 " + f.root), linked.length ? h("button.btn.small", { onclick: () => { linked.forEach((e) => DQ.learn.introduce(e.id)); DQ.toast(_(linked.length + " mots ajoutés aux révisions", linked.length + " words added to reviews")); } }, "➕ " + _("Réviser", "Review")) : null),
        h("table.t", f.members.map((m) => {
          const e = DQ.forms.get(DQ.fold(m[0].replace(/^(der|die|das) /, "")));
          return h("tr", h("td", e ? h("a", { href: "#/dict/" + e.id }, h("b", m[0])) : h("b", m[0])), h("td.small.muted", DQ.lang() === "en" ? m[2] : m[1]), h("td", DQ.speakBtn(m[0])));
        })));
    })));
})();
