/* Smart reading (23), thinking in German (27), pronunciation (22), error journal & difficulties (08, 24),
 * progress & weekly review (10, 16, 26), Life Simulator entry (19), object recognition (25, later phase). */
(function () {
  "use strict";
  const DQ = window.DQ;
  const { h, _ } = DQ;
  const S = DQ.store;
  const R = DQ.routes = DQ.routes || {};

  // ------------------------------------------------------------- smart reading
  R.read = (args) => {
    const p = S.profile();
    if (args[0] === "mine") return reader({ id: "mine", title: _("Mon texte", "My text"), de: sessionStorage.getItem("dq.mytext") || "", q: [], gloss: {} }, true);
    if (args[0]) return reader(DQ_DATA.texts.find((t) => t.id === args[0]));
    const ta = h("textarea", { placeholder: _("Colle ici un texte allemand (article, message, chanson…)", "Paste a German text here (article, message, song…)") });
    return h("div.stack.fade-in", h("h1", _("Lecture intelligente", "Smart reading")),
      DQ.qubiSays(_("Touche un mot pour voir sa traduction, son article et l’ajouter à ton dictionnaire.", "Tap a word to see its translation and article and add it to your dictionary.")),
      h("div.grid.g3", DQ_DATA.texts.map((t) => h("a.tile", { href: "#/read/" + t.id }, h("div.ic", "📰"), h("b", t.title), h("span", t.level + " · " + t.q.length + " " + _("questions", "questions"))))),
      h("div.card.stack", h("b", _("Importer mon propre texte", "Import my own text")), ta,
        h("button.btn", { onclick: () => { try { sessionStorage.setItem("dq.mytext", ta.value); } catch (e) { /* ignore */ } DQ.go("read/mine"); } }, _("Lire ce texte", "Read this text")),
        h("p.small.muted", _("Format accepté : texte brut collé. Les mots hors du dictionnaire A1 peuvent être expliqués par le tuteur IA si Ollama est installé.", "Accepted format: pasted plain text. Words outside the A1 dictionary can be explained by the AI tutor if Ollama is installed."))));
  };
  function reader(t, mine) {
    if (!t) return h("p", "—");
    const p = S.profile();
    const info = h("div.card.stack", h("p.muted", _("Touche un mot du texte.", "Tap a word in the text.")));
    const text = h("div.reader");
    t.de.split(/(\s+)/).forEach((tok) => {
      if (/^\s+$/.test(tok)) return text.append(tok);
      const clean = tok.replace(/[.,!?;:„“"()«»]/g, "");
      const e = DQ.forms.get(DQ.fold(clean));
      const sp = h("span.w" + (e && p.introduced[e.id] ? ".known" : ""), tok);
      sp.onclick = () => showWord(clean, e);
      text.append(sp);
    });
    function showWord(w, e) {
      info.innerHTML = "";
      DQ.say(w);
      if (e) {
        info.append(h("div.spread", h("div", h("div", { style: { fontSize: "30px" } }, e.emoji || ""), DQ.wordTitle(e), e.pl ? h("div.small", "die " + e.pl) : null), DQ.speakBtn(e.say, e.id)),
          DQ.fold(w) !== DQ.fold(e.de) ? h("div.pill.q", "« " + w + " » → " + e.de) : null,
          h("div", DQ.tr(e)),
          e.type === "verb" ? h("a.small", { href: "#/conj/" + encodeURIComponent(e.de) }, _("Conjugaison", "Conjugation") + " →") : null,
          h("div.row", h("button.btn.small", { onclick: () => { DQ.learn.introduce(e.id); DQ.toast(_("Ajouté aux révisions", "Added to reviews")); } }, "➕ " + _("Réviser ce mot", "Review this word")),
            h("a.btn.small.ghost", { href: "#/dict/" + e.id }, _("Fiche", "Entry"))));
      } else {
        const g = (t.gloss || {})[w];
        info.append(h("b", w), g ? h("div", DQ.lang() === "en" ? g[1] : g[0]) : h("div.muted", _("Pas dans le dictionnaire A1.", "Not in the A1 dictionary.")),
          h("div.row", h("a.btn.small", { href: "#/dict/add" }, "➕ " + _("Ajouter à mon dictionnaire", "Add to my dictionary")),
            h("a.btn.small.ghost", { href: "#/tutor?q=" + encodeURIComponent(_("Que veut dire « " + w + " » ?", "What does “" + w + "” mean?")) }, "🧑‍🏫 " + _("Demander au tuteur", "Ask the tutor"))));
      }
    }
    const qs = h("div.stack");
    (t.q || []).forEach(([q, opts, a], i) => {
      const c = h("div.card.stack", h("b", (i + 1) + ". " + q));
      opts.forEach((o, k) => c.append(h("button.choice", { onclick: (ev) => {
        const ok = k === a; c.querySelectorAll(".choice").forEach((b, j) => { b.disabled = true; if (j === a) b.classList.add("right"); });
        if (!ok) ev.currentTarget.classList.add("wrong");
        DQ.sfx(ok ? "success" : "wrong"); DQ.learn.exercise(ok, { module: "read", cat: "vocab", q, given: o, right: opts[a] });
      } }, o)));
      qs.append(c);
    });
    return h("div.stack.fade-in", h("a.small", { href: "#/read" }, "← " + _("Lecture", "Reading")),
      h("div.spread", h("h1", t.title), mine ? null : DQ.speakBtn(t.de, "text_" + t.id, true)),
      h("div.grid.g2", h("div.card", text), info),
      t.q && t.q.length ? h("h2", _("Questions de compréhension", "Comprehension questions")) : null, qs);
  }

  // ------------------------------------------------------------- think in German
  R.think = () => {
    const box = h("div.stack.fade-in");
    let i = Math.floor(Math.random() * DQ_DATA.think.length);
    const draw = () => {
      const t = DQ_DATA.think[i % DQ_DATA.think.length];
      const ta = h("textarea", { lang: "de", spellcheck: "false", placeholder: _("Écris directement en allemand…", "Write directly in German…") });
      const out = h("div.stack");
      box.innerHTML = "";
      box.append(h("h1", _("Penser en allemand", "Think in German")),
        DQ.qubiSays(_("Pas de traduction : regarde, imagine, et réponds en allemand avec tes mots. Les petites phrases comptent !", "No translation: look, imagine and answer in German in your own words. Short sentences count!")),
        h("div.card.stack", { style: { textAlign: "center" } }, h("div.emoji-xl", t.scene), h("div.big-de", { style: { fontSize: "24px" } }, t.q), DQ.speakBtn(t.q)),
        h("div.card.stack", h("div.chips", t.hint.map((x) => h("button.chip", { onclick: () => { ta.value += (ta.value ? " " : "") + x; ta.focus(); } }, x))), ta,
          h("div.row",
            h("button.btn.primary", { onclick: async () => {
              out.innerHTML = "";
              if (!ta.value.trim()) return;
              out.append(h("div.fb.mid", h("b", _("Un exemple de réponse", "A sample answer")), t.model, h("div", DQ.speakBtn(t.model))));
              const words = ta.value.split(/\s+/).length;
              DQ.learn.exercise(true);
              out.append(h("p.small.muted", _(words + " mots écrits. Compare avec l’exemple : verbe en 2e position ? articles ?", words + " words written. Compare with the sample: verb in 2nd position? articles?")));
              const fb = await DQ.tutor.correct(ta.value, t.q);
              if (fb) out.append(fb);
            } }, _("Comparer / corriger", "Compare / correct")),
            h("button.btn", { onclick: () => { i++; draw(); } }, _("Autre situation", "Another situation")))), out);
    };
    draw();
    return box;
  };

  // ------------------------------------------------------------- pronunciation (comparative listening; advanced phase)
  R.pron = (args, params, onCleanup) => {
    const p = S.profile();
    const pool = DQ.lexicon.filter((e) => e.ex && e.ex[0] && (p.introduced[e.id] || e.cat === "phrases"));
    let e = DQ.sample(pool.length ? pool : DQ.lexicon, 1)[0];
    let rec = null, stream = null, url = null;
    const zone = h("div.stack");
    onCleanup(() => { if (stream) stream.getTracks().forEach((t) => t.stop()); });
    const draw = () => {
      zone.innerHTML = "";
      const mine = h("div.row");
      const recBtn = h("button.btn.primary", { onclick: async () => {
        if (rec && rec.state === "recording") { rec.stop(); return; }
        try {
          stream = stream || await navigator.mediaDevices.getUserMedia({ audio: true });
          const chunks = [];
          rec = new MediaRecorder(stream);
          rec.ondataavailable = (ev) => chunks.push(ev.data);
          rec.onstop = () => { if (url) URL.revokeObjectURL(url); url = URL.createObjectURL(new Blob(chunks, { type: rec.mimeType }));
            recBtn.textContent = "🎙️ " + _("Recommencer", "Record again"); mine.innerHTML = "";
            mine.append(h("button.btn", { onclick: () => new Audio(url).play() }, "▶ " + _("Ma voix", "My voice")), h("button.btn", { onclick: () => DQ.say(e.ex[0], { id: e.id + "_ex" }) }, "▶ " + _("Modèle", "Model"))); };
          rec.start(); recBtn.textContent = "⏹ " + _("Arrêter", "Stop");
          setTimeout(() => { if (rec && rec.state === "recording") rec.stop(); }, 8000);
        } catch (err) { DQ.toast(_("Micro indisponible ou refusé.", "Microphone unavailable or refused.")); }
      } }, "🎙️ " + _("M’enregistrer", "Record myself"));
      zone.append(h("div.card.stack", { style: { textAlign: "center" } }, h("div.emoji-xl", e.emoji || "🗣️"), h("div.big-de", { style: { fontSize: "26px" } }, e.ex[0]),
        h("div.muted", DQ.lang() === "en" ? e.ex[2] : e.ex[1]), h("div.row", { style: { justifyContent: "center" } }, DQ.speakBtn(e.ex[0], e.id + "_ex", true)),
        h("div.row", { style: { justifyContent: "center" } }, recBtn), mine,
        h("button.btn.ghost.small", { onclick: () => { e = DQ.sample(pool.length ? pool : DQ.lexicon, 1)[0]; draw(); } }, _("Autre phrase", "Another sentence"))));
    };
    draw();
    return h("div.stack.fade-in", h("h1", _("Prononciation", "Pronunciation")),
      DQ.qubiSays(_("Écoute le modèle, enregistre-toi, puis compare les deux. L’enregistrement reste sur ton appareil.", "Listen to the model, record yourself, then compare. The recording stays on your device.")),
      zone,
      h("p.small.muted", _("Phase avancée prévue : transcription et entraînement phonétique. La comparaison à l’oreille ne remplace pas une évaluation phonétique fiable.", "Planned advanced phase: transcription and phonetic training. Comparing by ear is not a reliable phonetic assessment.")));
  };

  // ------------------------------------------------------------- error journal & difficulties
  R.journal = () => {
    const p = S.profile();
    const st = { cat: "" };
    const list = h("div.stack");
    const cats = [...new Set(p.journal.map((e) => e.cat || "grammar"))];
    const draw = () => {
      list.innerHTML = "";
      const rows = p.journal.filter((e) => !st.cat || (e.cat || "grammar") === st.cat).slice().reverse().slice(0, 150);
      if (!rows.length) list.append(DQ.qubiSays(_("Ton journal est vide pour l’instant. Les erreurs sont utiles : elles me disent quoi te proposer.", "Your journal is empty for now. Mistakes are useful: they tell me what to suggest."), "happy"));
      rows.forEach((e) => list.append(h("div.card",
        h("div.spread", h("span.pill.bad", _(DQ.learn.CATS[e.cat] || DQ.learn.CATS.grammar)), h("span.small.muted", new Date(e.t).toLocaleDateString() + " · " + (e.module || ""))),
        h("div", e.q || ""), e.given ? h("div.small", _("Ta réponse : ", "Your answer: "), h("s", e.given)) : null,
        e.right ? h("div.small", _("Correct : ", "Correct: "), h("b", e.right)) : null, e.why ? h("div.small.muted", e.why) : null)));
    };
    draw();
    const recos = DQ.learn.recommendations(p, 30);
    return h("div.stack.fade-in", h("h1", _("Journal des erreurs", "Error journal")),
      recos.length ? h("div.card.stack", h("b", "🎯 " + _("Difficultés détectées", "Difficulties detected")),
        recos.map((r) => h("div.spread", h("div", h("b", r.label), h("div.small.muted", r.why)),
          h("div.row", r.lesson ? h("a.btn.small", { href: "#/grammar/" + r.lesson }, _("Revoir la leçon", "Review the lesson")) : null, r.quiz ? h("a.btn.small.primary", { href: "#/quiz/" + r.quiz }, _("Exercices ciblés", "Targeted practice")) : null))),
        h("p.small.muted", _("Ces suggestions viennent uniquement de tes erreurs des 30 derniers jours ; tu es libre de les suivre ou non.", "These suggestions only come from your mistakes in the last 30 days; you’re free to follow them or not."))) : null,
      cats.length ? h("div.chips", ["", ...cats].map((c) => h("button.chip" + (st.cat === c ? ".on" : ""), { onclick: (ev) => { st.cat = c; ev.target.parentNode.querySelectorAll(".chip").forEach((x) => x.classList.remove("on")); ev.target.classList.add("on"); draw(); } }, c ? _(DQ.learn.CATS[c] || DQ.learn.CATS.grammar) : _("Toutes", "All")))) : null,
      list);
  };

  // ------------------------------------------------------------- progress & weekly review
  R.stats = (args) => {
    const p = S.profile();
    const c = DQ.learn.cefr();
    const counts = DQ.learn.counts();
    const week = DQ.learn.activeDays(7);
    const sum = (k, list = week) => list.reduce((a, d) => a + ((d.v && d.v[k]) || 0), 0);
    const prevWeek = DQ.learn.activeDays(14).slice(0, 7);
    const min = Math.round(sum("sec") / 60), prevMin = Math.round(sum("sec", prevWeek) / 60);
    const active = sum("sec") + sum("reviews") + sum("ex") > 0;
    const minTxt = sum("sec") > 0 && min < 1 ? "< 1" : String(min);
    const acc = sum("reviews") + sum("ex") ? Math.round(100 * (sum("correct") + sum("exOk")) / (sum("reviews") + sum("ex"))) : null;
    const maxSec = Math.max(60, ...week.map((d) => (d.v ? d.v.sec : 0)));
    const recos = DQ.learn.recommendations(p, 7);
    const weekly = args[0] === "week";
    if (weekly) { p.weekly.lastShown = S.today(); S.save(); }
    const bars = (label, v, cls) => h("div.stack", { style: { gap: "4px" } }, h("div.spread", h("span", label), h("b", Math.round(v * 100) + " %")), h("div.bar" + (cls ? "." + cls : ""), h("i", { style: { width: Math.round(v * 100) + "%" } })));
    return h("div.stack.fade-in",
      h("h1", weekly ? _("Ton bilan de la semaine", "Your weekly review") : _("Progression", "Progress")),
      DQ.qubiSays(active ? _("Cette semaine : " + minTxt + " minutes d’allemand" + (prevMin ? (min >= prevMin ? ", plus que la semaine dernière" : ", un peu moins que la semaine dernière — c’est normal, chaque semaine est différente") : "") + ". " + (acc !== null ? acc + " % de bonnes réponses." : ""),
        "This week: " + minTxt + " minutes of German" + (prevMin ? (min >= prevMin ? ", more than last week" : ", a little less than last week — that’s fine, every week is different") : "") + ". " + (acc !== null ? acc + "% correct answers." : ""))
        : _("Pas encore d’activité cette semaine. Une session de " + p.time.session + " minutes suffit pour démarrer.", "No activity yet this week. One " + p.time.session + "-minute session is enough to start."), active ? "happy" : ""),
      h("div.card.stack", h("b", _("Activité des 7 derniers jours (minutes)", "Activity over the last 7 days (minutes)")),
        h("div", { style: { display: "grid", gridTemplateColumns: "repeat(7, 1fr)", alignItems: "end", gap: "8px", height: "120px" } },
          week.map((d) => h("div", { style: { display: "grid", gap: "4px", justifyItems: "center" } },
            h("div", { style: { width: "100%", height: Math.max(4, Math.round(((d.v ? d.v.sec : 0) / maxSec) * 90)) + "px", background: d.v && d.v.sec ? "var(--qubi)" : "var(--line)", borderRadius: "6px" } }),
            h("span.small.muted", d.d.toLocaleDateString(DQ.lang(), { weekday: "short" })))))),
      h("div.grid.g4",
        h("div.card.kpi", h("b", minTxt + " min"), h("span", _("cette semaine", "this week"))),
        h("div.card.kpi", h("b", String(sum("reviews"))), h("span", _("révisions", "reviews"))),
        h("div.card.kpi", h("b", String(sum("newWords"))), h("span", _("nouveaux mots", "new words"))),
        h("div.card.kpi", h("b", acc === null ? "—" : acc + " %"), h("span", _("réponses justes", "correct answers")))),
      h("div.grid.g2",
        h("div.card.stack", h("b", _("Maîtrise par compétence (évaluée)", "Mastery by skill (assessed)")),
          bars(_("Vocabulaire", "Vocabulary"), c.skills.vocab), bars(_("Verbes", "Verbs"), c.skills.verbs, "blue"), bars(_("Grammaire (leçons validées)", "Grammar (lessons passed)"), c.skills.grammar, "amber"),
          bars(_("Précision des réponses", "Answer accuracy"), c.skills.accuracy, "pink"), bars(_("Mission Brot kaufen", "Brot kaufen mission"), c.skills.listening)),
        h("div.card.stack", h("b", "A1 : " + c.progress + " %"), h("div.bar.amber", h("i", { style: { width: c.progress + "%" } })),
          h("p.small.muted", _("Calculé à partir de tes évaluations (révisions réussies, leçons validées, exercices, mission), pas seulement du nombre de mots vus.", "Calculated from your assessments (successful reviews, lessons passed, exercises, mission), not just the number of words seen.")),
          h("table.t", [["unknown", "nouveaux", "new"], ["learning", "en cours", "learning"], ["due", "à réviser", "to review"], ["known", "connus", "known"], ["mastered", "maîtrisés", "mastered"]].map(([k, fr, en]) => h("tr", h("td", _(fr, en)), h("td", h("b", String(counts[k])))))),
          h("div.small.muted", _("Activité ≠ maîtrise : un mot n’est « maîtrisé » qu’après plusieurs rappels réussis espacés.", "Activity ≠ mastery: a word is only “mastered” after several successful spaced recalls.")))),
      recos.length ? h("div.card.stack", h("b", _("À travailler cette semaine", "To work on this week")), recos.map((r) => h("div", "• ", h("b", r.label), " — ", h("span.small.muted", r.why)))) : null,
      h("div.card.stack", h("b", _("Objectif réaliste pour la semaine prochaine", "A realistic goal for next week")),
        h("p", _("Environ " + Math.max(p.time.daily * 5, 30) + " minutes au total, " + p.prefs.newPerSession * 4 + " nouveaux mots et une leçon de grammaire. Ajuste librement dans ton profil.",
          "About " + Math.max(p.time.daily * 5, 30) + " minutes in total, " + p.prefs.newPerSession * 4 + " new words and one grammar lesson. Adjust freely in your profile."))),
      h("a.btn", { href: "#/journal" }, "📒 " + _("Historique des erreurs", "Error history")));
  };

  // ------------------------------------------------------------- Life Simulator (missions in pictures and sound)
  R.sim = () => {
    const rec = DQ.readSim();
    const p = S.profile();
    if (rec) { p.missions.brot_kaufen = { completed: !!rec.completed, best: rec.best || 0, attempts: rec.attempts || 0 }; S.save(); }
    const MISSIONS = [
      ["brot_kaufen", "🥨", "Brot kaufen", _("Acheter du pain à la boulangerie", "Buy bread at the bakery"), "A1", true],
      ["bahnhof", "🚉", "Am Bahnhof", _("Acheter un billet de train", "Buy a train ticket"), "A1", false],
      ["supermarkt", "🛒", "Im Supermarkt", _("Trouver des produits, payer", "Find products, pay"), "A1", false],
      ["cafe", "☕", "Im Café", _("Commander et payer", "Order and pay"), "A1", false],
      ["apotheke", "💊", "In der Apotheke", _("Expliquer un symptôme", "Describe a symptom"), "A2", false],
      ["arzt", "🩺", "Beim Arzt", _("Prendre rendez-vous, consultation", "Book and attend an appointment"), "A2", false],
    ];
    return h("div.stack.fade-in", h("h1", "DeepQ Life Simulator"),
      DQ.qubiSays(_("Des situations de la vie réelle en photos, voix et ambiances sonores : ferme presque les yeux et imagine-toi sur place.", "Real-life situations in photos, voices and soundscapes: almost close your eyes and picture yourself there.")),
      h("div.grid.g3", MISSIONS.map(([id, ic, de, desc, lvl, ready]) => {
        const m = p.missions[id];
        return h(ready ? "a.tile" : "div.tile", ready ? { href: "sim/index.html" } : { style: { opacity: 0.6 } }, h("div.ic", ic), h("b", de), h("span", desc),
          h("div.row", h("span.pill", lvl), ready ? (m && m.completed ? h("span.pill.ok", _("réussie · ", "done · ") + m.best + " %") : h("span.pill.q", _("disponible", "available"))) : h("span.pill", _("bientôt", "coming soon"))));
      })),
      h("div.card.stack", h("b", "📷 " + _("Reconnaissance d’objets", "Object recognition")),
        h("p.small.muted", _("Phase avancée : photographier un objet pour obtenir son nom, son article et son pluriel. Sa faisabilité hors ligne sur Android est à l’étude.", "Advanced phase: photograph an object to get its name, article and plural. Offline feasibility on Android is being studied."))));
  };
})();
