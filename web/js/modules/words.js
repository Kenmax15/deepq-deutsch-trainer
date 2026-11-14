/* Dictionary & personal words (02, 03, 14), review sessions & flashcards (04, 05). */
(function () {
  "use strict";
  const DQ = window.DQ;
  const { h, _ } = DQ;
  const S = DQ.store;
  const R = DQ.routes = DQ.routes || {};
  const STATUS = { unknown: ["nouveau", "new", ""], learning: ["en cours", "learning", "q"], known: ["connu", "known", "ok"], mastered: ["maîtrisé", "mastered", "ok"], due: ["à réviser", "to review", "mid"] };
  const statusPill = (st) => { const s = STATUS[st]; return h("span.pill" + (s[2] ? "." + s[2] : ""), _(s[0], s[1])); };
  DQ.statusPill = statusPill;

  function wordTitle(e, big) {
    return h(big ? "div.big-de" : "b", e.art ? h("span." + DQ.artClass(e.art), e.art + " ") : null, e.de);
  }
  DQ.wordTitle = wordTitle;

  // ------------------------------------------------------------- dictionary list
  R.dict = (args, params) => {
    if (args[0] === "add") return addWord();
    if (args[0]) return detail(DQ.entry(args[0]));
    const p = S.profile();
    const st = { q: params.q || "", cat: params.cat || "", status: "", mark: params.mark === "1" };
    const list = h("div.grid.g4");
    const cats = ["", ...new Set(DQ.allEntries().map((e) => (e.personal ? "personal" : e.cat)))];
    const draw = () => {
      list.innerHTML = "";
      const q = DQ.fold(st.q);
      const hit = q ? DQ.forms.get(q) : null;
      let rows = DQ.allEntries().filter((e) => (!st.cat || (st.cat === "personal" ? e.personal : e.cat === st.cat)) &&
        (!q || DQ.fold(e.de).includes(q) || DQ.fold(e.fr).includes(q) || DQ.fold(e.en).includes(q) || (hit && hit.id === e.id)) &&
        (!st.status || DQ.learn.status(e.id) === st.status));
      if (!rows.length) list.append(h("p.muted", _("Aucun mot trouvé. Tu peux l’ajouter à ton dictionnaire personnel.", "No word found. You can add it to your personal dictionary.")));
      rows.slice(0, 400).forEach((e) => {
        const status = DQ.learn.status(e.id);
        const card = h("a.tile", { href: "#/dict/" + e.id, style: { minHeight: "0" } },
          h("div.spread", h("span", { style: { fontSize: "34px" } }, e.emoji || "🔤"), statusPill(status)),
          wordTitle(e), e.pl ? h("span", "die " + e.pl) : null, h("span", DQ.tr(e)));
        if (st.mark && status === "unknown") card.append(h("button.btn.small", { onclick: (ev) => { ev.preventDefault(); DQ.markKnown(e.id); draw(); } }, "✔ " + _("Je connais", "I know it")));
        list.append(card);
      });
    };
    draw();
    return h("div.stack.fade-in",
      h("div.spread", h("h1", _("Dictionnaire illustré", "Picture dictionary")), h("a.btn.small", { href: "#/dict/add" }, "➕ " + _("Ajouter un mot", "Add a word"))),
      st.mark ? DQ.qubiSays(_("Touche « Je connais » pour les mots que tu sais déjà : ils ne te seront plus proposés comme nouveaux.", "Tap “I know it” for words you already know: they won’t be offered as new any more.")) : null,
      h("input", { type: "search", value: st.q, placeholder: _("Chercher un mot, une forme (ex. « isst », « Bücher ») ou une traduction…", "Search a word, a form (e.g. “isst”, “Bücher”) or a translation…"), oninput: (e) => { st.q = e.target.value; draw(); } }),
      h("div.chips", cats.map((c) => h("button.chip" + (st.cat === c ? ".on" : ""), { onclick: (ev) => { st.cat = c; ev.target.parentNode.querySelectorAll(".chip").forEach((x) => x.classList.remove("on")); ev.target.classList.add("on"); draw(); } }, c ? DQ.catName(c) : _("Tout", "All")))),
      h("div.chips", ["", "unknown", "learning", "due", "known", "mastered"].map((s) => h("button.chip" + (st.status === s ? ".on" : ""), { onclick: (ev) => { st.status = s; ev.target.parentNode.querySelectorAll(".chip").forEach((x) => x.classList.remove("on")); ev.target.classList.add("on"); draw(); } }, s ? _(STATUS[s][0], STATUS[s][1]) : _("Tous les statuts", "Any status")))),
      list);
  };

  // ------------------------------------------------------------- word detail
  function detail(e) {
    if (!e) return h("p", _("Mot introuvable.", "Word not found."));
    const p = S.profile();
    const status = DQ.learn.status(e.id);
    const fam = DQ_DATA.families.find((f) => f.members.some((m) => DQ.fold(m[0].replace(/^(der|die|das) /, "")) === DQ.fold(e.de)));
    setTimeout(() => DQ.say(e.say || e.de, { id: e.personal ? null : e.id }), 250);
    return h("div.stack.fade-in",
      h("a.small", { href: "#/dict" }, "← " + _("Dictionnaire", "Dictionary")),
      h("div.card.stack", { style: { textAlign: "center" } },
        h("div.emoji-xl", e.emoji || "🔤"),
        h("div.row", { style: { justifyContent: "center" } }, wordTitle(e, true), DQ.speakBtn(e.say || e.de, e.personal ? null : e.id, true)),
        e.pl ? h("div", _("Pluriel : ", "Plural: "), h("b", "die " + e.pl)) : e.type === "noun" ? h("div.muted", _("Pas de pluriel courant", "No common plural")) : null,
        h("div", { style: { fontSize: "19px" } }, e.fr + " · " + e.en),
        h("div.row", { style: { justifyContent: "center" } }, statusPill(status), h("span.pill", e.lvl || "A1"), h("span.pill", DQ.catName(e.personal ? "personal" : e.cat)),
          e.personal ? h("span.ai-tag", _("ajouté par moi · non vérifié", "added by me · not verified")) : h("span.ref-tag", _("référence vérifiée", "verified reference")))),
      e.ex && e.ex[0] ? h("div.card.stack",
        h("b", _("Exemple", "Example")),
        h("div.row", h("span", { style: { fontSize: "18px" } }, e.ex[0]), DQ.speakBtn(e.ex[0], e.personal ? null : e.id + "_ex", true)),
        p.prefs.showTranslation ? h("div.muted", DQ.lang() === "en" ? e.ex[2] : e.ex[1]) : null) : null,
      e.type === "verb" ? h("div.card.stack", h("b", _("Verbe", "Verb")),
        h("div", _("Auxiliaire : ", "Auxiliary: "), h("b", e.aux), " · Partizip II : ", h("b", e.pp), e.sep ? " · " + _("séparable", "separable") + " (" + e.sep + "-)" : "", e.obj ? " · " + _("complément : ", "object: ") + e.obj : ""),
        h("a.btn.small", { href: "#/conj/" + encodeURIComponent(e.de) }, "🔤 " + _("Voir la conjugaison", "See the conjugation"))) : null,
      e.ant ? h("div.card", _("Contraire : ", "Opposite: "), h("b", e.ant)) : null,
      fam ? h("div.card.stack", h("b", "🌳 " + _("Famille de mots", "Word family") + " (" + fam.root + ")"), h("div.chips", fam.members.map((m) => h("span.chip", m[0])))) : null,
      h("div.row",
        status === "unknown" ? h("button.btn.primary", { onclick: () => { DQ.learn.introduce(e.id); DQ.toast(_("Ajouté à tes révisions", "Added to your reviews")); DQ.render(); } }, "➕ " + _("Apprendre ce mot", "Learn this word")) : null,
        status !== "mastered" ? h("button.btn", { onclick: () => { DQ.markKnown(e.id); DQ.toast(_("Noté comme connu", "Marked as known")); DQ.render(); } }, "✔ " + _("Je le connais déjà", "I already know it")) : null,
        h("a.btn.ghost", { href: "#/tutor?q=" + encodeURIComponent(_("Explique-moi le mot ", "Explain the word ") + e.de) }, "🧑‍🏫 " + _("Demander au tuteur", "Ask the tutor"))));
  }

  // ------------------------------------------------------------- add a personal word, with anti-duplicate check (03)
  function addWord() {
    const p = S.profile();
    const f = { de: "", art: "", pl: "", fr: "", en: "", ex: "", emoji: "" };
    const warn = h("div");
    const check = () => {
      warn.innerHTML = "";
      const k = DQ.fold(f.de.replace(/^(der|die|das) /i, ""));
      if (!k) return null;
      const hit = DQ.forms.get(k) || p.personal.find((w) => DQ.fold(w.de) === k || DQ.fold(w.pl || "") === k);
      if (hit) warn.append(h("div.fb.mid", h("b", _("Ce mot existe déjà", "This word already exists")),
        DQ.fold(hit.de) === k ? _("« " + hit.de + " » est dans le dictionnaire.", "“" + hit.de + "” is in the dictionary.") : _("« " + f.de + " » est une forme de « " + hit.de + " ».", "“" + f.de + "” is a form of “" + hit.de + "”."),
        h("div", h("a.btn.small", { href: "#/dict/" + hit.id }, _("Voir le mot", "See the word")))));
      return hit;
    };
    const inp = (k, label, ph) => h("label.f", label, h("input", { type: "text", placeholder: ph || "", oninput: (e) => { f[k] = e.target.value.trim(); if (k === "de") check(); } }));
    return h("div.stack.fade-in",
      h("a.small", { href: "#/dict" }, "← " + _("Dictionnaire", "Dictionary")),
      h("h1", _("Ajouter un mot", "Add a word")),
      h("div.card.stack",
        inp("de", _("Mot allemand (sans article)", "German word (without article)"), "Regenschirm"), warn,
        h("label.f", _("Article (pour un nom)", "Article (for a noun)"), h("div.chips", ["", "der", "die", "das"].map((a) => h("button.chip" + (a === "" ? ".on" : ""), { onclick: (ev) => { f.art = a; ev.target.parentNode.querySelectorAll(".chip").forEach((x) => x.classList.remove("on")); ev.target.classList.add("on"); } }, a || _("aucun", "none"))))),
        inp("pl", _("Pluriel (facultatif)", "Plural (optional)"), "Regenschirme"),
        inp("fr", _("Traduction française", "French translation"), "le parapluie"),
        inp("en", _("Traduction anglaise", "English translation"), "umbrella"),
        inp("ex", _("Exemple (facultatif)", "Example (optional)"), "Nimm einen Regenschirm mit!"),
        inp("emoji", _("Emoji / image (facultatif)", "Emoji / picture (optional)"), "☂️"),
        h("p.small.muted", _("Les mots ajoutés par toi sont marqués « non vérifiés » : ils ne remplacent pas les références.", "Words you add are marked “not verified”: they don’t replace the references.")),
        h("button.btn.primary", { onclick: () => {
          if (!f.de || !(f.fr || f.en)) return DQ.toast(_("Il faut au moins le mot et une traduction.", "At least the word and one translation are needed."));
          if (check()) return DQ.toast(_("Ce mot existe déjà.", "This word already exists."));
          const id = "p_" + DQ.lex.slug(f.de) + "_" + Date.now().toString(36);
          p.personal.push({ id, type: f.art ? "noun" : "word", lemma: f.de, de: f.de, art: f.art || null, pl: f.pl || null, fr: f.fr || f.en, en: f.en || f.fr,
            emoji: f.emoji || "📝", cat: "personal", lvl: p.level, say: (f.art ? f.art + " " : "") + f.de, ex: f.ex ? [f.ex, "", ""] : null, status: "personal", source: "learner" });
          S.save(); DQ.learn.introduce(id);
          DQ.toast(_("Mot ajouté et programmé dans tes révisions", "Word added and scheduled for review"));
          DQ.go("dict/" + id);
        } }, _("Enregistrer", "Save"))));
  }

  // ------------------------------------------------------------- review engine (05) used by Review and Flashcards (04)
  /** queue item: { id, skill, mode?, isNew? } */
  function session(queue, opts = {}) {
    const box = h("div.stack.fade-in");
    let i = 0, ok = 0, total = queue.length;
    const p = S.profile();
    const next = () => {
      if (i >= queue.length) return end();
      const it = queue[i++];
      const e = DQ.entry(it.id);
      if (!e) return next();
      box.innerHTML = "";
      box.append(h("div.spread", h("span.pill", i + " / " + total), opts.title ? h("span.pill.q", opts.title) : null),
        h("div.bar", h("i", { style: { width: Math.round(((i - 1) / total) * 100) + "%" } })));
      if (it.isNew) return present(e, it);
      ask(e, it);
    };
    const present = (e, it) => {
      DQ.learn.introduce(e.id);
      box.append(h("div.card.stack", { style: { textAlign: "center" } },
        h("span.pill.q", "✨ " + _("Nouveau mot", "New word")),
        h("div.emoji-xl", e.emoji || "🔤"), wordTitle(e, true), e.pl ? h("div", "die " + e.pl) : null,
        h("div", { style: { fontSize: "19px" } }, DQ.tr(e)),
        e.ex && e.ex[0] ? h("div.muted", e.ex[0]) : null,
        h("div.row", { style: { justifyContent: "center" } }, DQ.speakBtn(e.say, e.personal ? null : e.id, true)),
        h("button.btn.primary", { onclick: next }, _("Compris, on continue", "Got it, carry on"))));
      DQ.say(e.say, { id: e.personal ? null : e.id });
    };
    const gradeBtns = (e, skill, after) => h("div.grid", { style: { gridTemplateColumns: "repeat(4, 1fr)", gap: "8px" } },
      [[1, "🔁", _("À revoir", "Again")], [3, "😅", _("Difficile", "Hard")], [4, "🙂", _("Bien", "Good")], [5, "😎", _("Facile", "Easy")]].map(([g, ic, l]) =>
        h("button.btn", { onclick: () => { DQ.learn.grade(e.id, skill, g); if (g >= 3) ok++; else if (opts.requeue !== false) queue.push({ id: e.id, skill }); (after || next)(); } }, ic + " " + l)));
    const ask = (e, it) => {
      const mode = it.mode || (it.skill === "rec" ? "flip" : it.skill === "rcl" ? (e.emoji && Math.random() < 0.4 ? "image" : "type") : (e.type === "noun" ? (e.pl && Math.random() < 0.45 ? "plural" : "article") : "cloze"));
      const card = h("div.card.stack");
      box.append(card);
      if (mode === "flip") {
        const fl = h("div.flash", h("div.inner",
          h("div.face", h("div", h("div.emoji-xl", { style: { fontSize: "54px" } }, "🇩🇪"), wordTitle(e, true), h("p.muted.small", _("Touche la carte pour voir la traduction", "Tap the card to see the translation")))),
          h("div.face.back", h("div", h("div.emoji-xl", e.emoji || ""), h("div", { style: { fontSize: "22px", fontWeight: 700 } }, DQ.tr(e)), e.ex ? h("p.muted", e.ex[0]) : null))));
        const grades = h("div", { hidden: true }, h("p.small.muted", _("Comment ça s’est passé ?", "How did it go?")), gradeBtns(e, "rec"));
        fl.onclick = () => { fl.classList.add("flipped"); grades.hidden = false; };
        card.append(fl, h("div.row", { style: { justifyContent: "center" } }, DQ.speakBtn(e.say, e.personal ? null : e.id, true)), grades);
        DQ.say(e.say, { id: e.personal ? null : e.id });
      } else if (mode === "type" || mode === "image") {
        const inp = h("input", { type: "text", lang: "de", autocomplete: "off", spellcheck: "false", placeholder: e.art ? "der / die / das + …" : "…" });
        const fb = h("div");
        card.append(mode === "image" ? h("div.emoji-xl", { style: { textAlign: "center" } }, e.emoji) : null,
          h("div", { style: { textAlign: "center", fontSize: "21px", fontWeight: 650 } }, mode === "image" ? _("Comment dit-on en allemand ?", "What’s this in German?") : DQ.tr(e)),
          e.art ? h("p.small.muted", { style: { textAlign: "center" } }, _("Écris le nom avec son article.", "Write the noun with its article.")) : null,
          h("form.row", { onsubmit: (ev) => { ev.preventDefault(); check(); } }, inp, h("button.btn.primary", _("Vérifier", "Check"))), fb);
        setTimeout(() => inp.focus(), 50);
        const check = () => {
          const v = inp.value.trim(); if (!v) return;
          const full = (e.art ? e.art + " " : "") + e.de;
          const word = v.replace(/^(der|die|das)\s+/i, ""), art = (/^(der|die|das)\s/i.exec(v) || [])[1];
          const wordOk = DQ.sameGerman(word, e.de), artOk = !e.art || (art && art.toLowerCase() === e.art);
          inp.disabled = true;
          const g = wordOk && artOk ? 4 : wordOk ? 3 : 1;
          if (g === 1) DQ.learn.exercise(false, { module: "review", cat: "vocab", q: DQ.tr(e), given: v, right: full });
          if (wordOk && !artOk) S.logError({ module: "review", cat: "article", q: DQ.tr(e), given: v, right: full, why: _("Le mot est juste, mais l’article est « " + e.art + " ».", "The word is right, but the article is “" + e.art + "”.") });
          fb.append(h("div.fb." + (g === 4 ? "ok" : g === 3 ? "mid" : "bad"),
            h("b", g === 4 ? _("Richtig !", "Richtig!") : g === 3 ? _("Presque : attention à l’article", "Almost: watch the article") : _("Pas encore", "Not yet")), full),
            h("div.row", { style: { marginTop: "10px" } },
              h("button.btn.primary", { onclick: () => { DQ.learn.grade(e.id, "rcl", g); if (g >= 3) ok++; else queue.push({ id: e.id, skill: "rcl" }); next(); } }, _("Continuer", "Continue")),
              g < 4 ? h("button.btn.ghost.small", { onclick: () => { DQ.learn.grade(e.id, "rcl", 4); ok++; next(); } }, _("J’avais raison", "I was right")) : null));
          DQ.sfx(g >= 3 ? "success" : "wrong");
          DQ.say(e.say, { id: e.personal ? null : e.id });
        };
      } else if (mode === "article" || mode === "plural") {
        const right = mode === "article" ? e.art : e.pl;
        let opts2;
        if (mode === "article") opts2 = ["der", "die", "das"];
        else {
          const fakes = new Set([e.de + "s", e.de + "en", e.de + "e", e.de.replace(/([aou])/, (m) => ({ a: "ä", o: "ö", u: "ü" }[m])) + "e", e.de]);
          fakes.delete(e.pl);
          opts2 = DQ.shuffle([e.pl, ...DQ.sample([...fakes], 2)]);
        }
        card.append(h("div.emoji-xl", { style: { textAlign: "center" } }, e.emoji || ""),
          h("div", { style: { textAlign: "center", fontSize: "26px", fontWeight: 700 } }, mode === "article" ? "___ " + e.de : _("Pluriel de ", "Plural of ") + e.art + " " + e.de + " → die ___"),
          h("div.stack", opts2.map((o) => h("button.choice", { onclick: (ev) => {
            const good = o === right;
            card.querySelectorAll(".choice").forEach((b) => { b.disabled = true; if (b.textContent === right) b.classList.add("right"); });
            if (!good) { ev.currentTarget.classList.add("wrong"); S.logError({ module: "review", cat: mode === "article" ? "article" : "plural", q: e.de, given: o, right, why: mode === "article" ? e.art + " " + e.de : "die " + e.pl }); }
            DQ.sfx(good ? "success" : "wrong"); DQ.say(mode === "article" ? e.say : "die " + e.pl, mode === "article" ? { id: e.id } : {});
            DQ.learn.grade(e.id, "use", good ? 4 : 1); if (good) ok++; else queue.push({ id: e.id, skill: "use" });
            setTimeout(next, 1100);
          } }, o))));
      } else { // cloze on the example sentence
        const ex = e.ex && e.ex[0];
        const target = findInSentence(e, ex);
        if (!ex || !target) { ask(e, Object.assign({}, it, { mode: "flip" })); card.remove(); return; }
        const gap = ex.replace(target, "____");
        const others = DQ.sample(DQ.lexicon.filter((x) => x.type === e.type && x.id !== e.id), 2).map((x) => formLike(x, target, e));
        card.append(h("div", { style: { textAlign: "center", fontSize: "22px", fontWeight: 650 } }, gap),
          h("p.muted", { style: { textAlign: "center" } }, DQ.lang() === "en" ? e.ex[2] : e.ex[1]),
          h("div.stack", DQ.shuffle([target, ...others]).map((o) => h("button.choice", { onclick: (ev) => {
            const good = o === target;
            card.querySelectorAll(".choice").forEach((b) => { b.disabled = true; if (b.textContent === target) b.classList.add("right"); });
            if (!good) { ev.currentTarget.classList.add("wrong"); S.logError({ module: "review", cat: e.type === "verb" ? "verb" : "vocab", q: gap, given: o, right: target }); }
            DQ.sfx(good ? "success" : "wrong"); DQ.say(ex, { id: e.id + "_ex" });
            DQ.learn.grade(e.id, "use", good ? 4 : 1); if (good) ok++; else queue.push({ id: e.id, skill: "use" });
            setTimeout(next, 1500);
          } }, o))));
      }
    };
    const end = () => {
      box.innerHTML = "";
      const left = DQ.learn.due().length;
      box.append(h("h1", _("Session terminée !", "Session complete!")),
        DQ.qubiSays(total ? _(ok + " bonnes réponses sur " + Math.max(total, ok) + ". " + (left ? "Il reste " + left + " révisions pour plus tard." : "Tout est à jour, bravo !"),
          ok + " correct out of " + Math.max(total, ok) + ". " + (left ? left + " reviews left for later." : "Everything is up to date, well done!")) : _("Rien à réviser pour l’instant.", "Nothing to review right now."), "happy"),
        h("div.row", h("a.btn.primary", { href: "#/home" }, _("Tableau de bord", "Dashboard")), h("button.btn", { onclick: () => DQ.render() }, _("Encore une session", "Another session"))));
      DQ.sfx("success", 0.4);
    };
    next();
    return box;
  }
  /** Find the word (or one of its forms) inside the example sentence. */
  function findInSentence(e, ex) {
    if (!ex) return null;
    const words = ex.replace(/[.,!?„“]/g, " ").split(/\s+/).filter(Boolean);
    const k = DQ.fold(e.de);
    for (const w of words) { const hit = DQ.forms.get(DQ.fold(w)); if (hit && hit.id === e.id) return w; if (DQ.fold(w) === k) return w; }
    return null;
  }
  function formLike(x, target, e) {
    if (x.type === "verb") { const f = DQ.conj.presentRaw(x.verb); const i = DQ.conj.presentRaw(e.verb).indexOf(target); return f[i >= 0 ? i : 2]; }
    if (x.type === "noun") return target === e.pl ? (x.pl || x.de) : x.de;
    return x.de;
  }

  R.review = () => {
    const p = S.profile();
    const due = DQ.learn.due().slice(0, 40);
    const fresh = DQ.learn.fresh(Math.max(0, p.prefs.newPerSession - Math.floor(due.length / 4)));
    const queue = due.map((d) => ({ id: d.id, skill: d.skill }));
    for (const e of fresh) { queue.push({ id: e.id, skill: "rec", isNew: true }); queue.push({ id: e.id, skill: "rec" }); }
    // new words: the recall and use cards come back in later sessions, not right away
    if (!queue.length) return h("div.stack", h("h1", _("Réviser", "Review")), DQ.qubiSays(_("Tout est à jour ! Reviens plus tard ou apprends de nouveaux mots dans le dictionnaire.", "All caught up! Come back later or learn new words in the dictionary."), "happy"), h("a.btn", { href: "#/dict" }, _("Dictionnaire", "Dictionary")));
    return h("div.stack", h("h1", _("Révisions du jour", "Today’s reviews")),
      h("p.muted", _(due.length + " à revoir · " + fresh.length + " nouveaux mots", due.length + " to review · " + fresh.length + " new words")), session(queue));
  };

  // ------------------------------------------------------------- flashcards (04): choose deck and mode
  R.cards = (args) => {
    const p = S.profile();
    if (args[0]) {
      const [cat, mode] = args;
      let pool = DQ.allEntries().filter((e) => cat === "all" || (cat === "personal" ? e.personal : e.cat === cat));
      if (mode === "article" || mode === "plural") pool = pool.filter((e) => e.type === "noun" && (mode === "article" ? e.art : e.pl));
      if (mode === "image") pool = pool.filter((e) => e.emoji);
      if (mode === "cloze") pool = pool.filter((e) => e.ex && findInSentence(e, e.ex[0]));
      const skill = { flip: "rec", type: "rcl", image: "rcl", article: "use", plural: "use", cloze: "use" }[mode];
      const pick = DQ.sample(pool, 12).map((e) => ({ id: e.id, skill, mode }));
      if (!pick.length) return h("p", _("Pas de cartes pour ce choix.", "No cards for this choice."));
      return h("div.stack", h("a.small", { href: "#/cards" }, "← Flashcards"), session(pick, { title: DQ.catName(cat === "all" ? "" : cat) || _("Tout", "All"), requeue: true }));
    }
    const st = { cat: "all", mode: "flip" };
    const MODES = [["flip", "🔄", "Recto-verso", "Front / back"], ["type", "⌨️", "Écrire le mot", "Type the word"], ["image", "🖼️", "Image → mot", "Picture → word"],
      ["article", "🎨", "Trouver l’article", "Find the article"], ["plural", "👥", "Trouver le pluriel", "Find the plural"], ["cloze", "🕳️", "Phrase à trous", "Gap sentence"]];
    const cats = ["all", ...new Set(DQ.allEntries().map((e) => (e.personal ? "personal" : e.cat)))];
    const go = h("button.btn.primary", { onclick: () => DQ.go("cards/" + st.cat + "/" + st.mode) }, _("Commencer (12 cartes)", "Start (12 cards)"));
    const val = (v) => (Array.isArray(v) ? v[0] : v);
    const chipRow = (list, key, label) => h("div.chips", list.map((v) => h("button.chip" + (st[key] === val(v) ? ".on" : ""), { onclick: (ev) => {
      st[key] = val(v); ev.target.parentNode.querySelectorAll(".chip").forEach((x) => x.classList.remove("on")); ev.target.classList.add("on"); } }, label(v))));
    return h("div.stack.fade-in", h("h1", "Flashcards"),
      DQ.qubiSays(_("Choisis un thème et un type de carte. Tes réponses comptent dans tes révisions espacées.", "Pick a theme and a card type. Your answers count towards your spaced reviews.")),
      h("div.card.stack", h("b", _("Type de carte", "Card type")), chipRow(MODES, "mode", (m) => m[1] + " " + _(m[2], m[3]))),
      h("div.card.stack", h("b", _("Thème", "Theme")), chipRow(cats, "cat", (c) => (c === "all" ? _("Tout", "All") : DQ.catName(c)))),
      go);
  };
})();
