/* Onboarding (§2), dashboard (10, 16), placement test (11), profile & settings (01, 07, 17, 18). */
(function () {
  "use strict";
  const DQ = window.DQ;
  const { h, _ } = DQ;
  const S = DQ.store;
  const R = DQ.routes = DQ.routes || {};
  const L = () => DQ.learn;

  // ------------------------------------------------------------- onboarding
  R.onboarding = () => {
    const st = { name: "", lang: (navigator.language || "fr").startsWith("en") ? "en" : "fr", daily: 15, session: 10, notif: false, test: true };
    DQ.uiLang = st.lang;
    const box = h("div.stack.fade-in");
    const draw = () => {
      DQ.uiLang = st.lang;
      box.innerHTML = "";
      box.append(
        h("div.row", DQ.qubiFace("happy", 64), h("div", h("h1", "DeepQ Deutsch Trainer"), h("p.muted", _("Bienvenue ! Je suis Qubi. On prépare ton espace en une minute.", "Welcome! I’m Qubi. Let’s set up your space in a minute.")))),
        h("div.card.stack",
          h("label.f", _("Ton prénom", "Your first name"), h("input", { type: "text", value: st.name, placeholder: _("ex. Maseim", "e.g. Alex"), oninput: (e) => (st.name = e.target.value) })),
          h("label.f", _("Langue de l’interface", "Interface language"),
            h("div.chips", [["fr", "Français"], ["en", "English"]].map(([v, l]) => h("button.chip" + (st.lang === v ? ".on" : ""), { type: "button", onclick: () => { st.lang = v; draw(); } }, l)))),
          h("label.f", _("Temps d’étude par jour", "Study time per day"),
            h("div.chips", [5, 10, 15, 20, 30, 45].map((m) => h("button.chip" + (st.daily === m ? ".on" : ""), { type: "button", onclick: () => { st.daily = m; draw(); } }, m + " min")))),
          h("label.f", _("Durée d’une session", "Length of one session"),
            h("div.chips", [5, 10, 15, 20, 30].map((m) => h("button.chip" + (st.session === m ? ".on" : ""), { type: "button", onclick: () => { st.session = m; draw(); } }, m + " min")))),
          h("p.small.muted", _("Tu pourras tout changer à tout moment, sans perdre tes acquis.", "You can change all of this at any time without losing progress.")),
          h("label.check", h("input", { type: "checkbox", checked: st.notif, onchange: (e) => (st.notif = e.target.checked) }), _("Recevoir un nouveau mot de temps en temps (rappels doux, réglables)", "Get a new word now and then (gentle, adjustable reminders)")),
          h("label.check", h("input", { type: "checkbox", checked: st.test, onchange: (e) => (st.test = e.target.checked) }), _("Faire le test de niveau maintenant (facultatif, 10–15 min)", "Take the placement test now (optional, 10–15 min)"))),
        h("button.btn.primary.block", { onclick: finish }, _("C’est parti !", "Let’s go!")));
    };
    async function finish() {
      const p = S.create(st.name.trim() || _("Moi", "Me"), st.lang);
      p.time.daily = st.daily; p.time.session = st.session;
      if (st.notif && "Notification" in window) {
        try { const r = await Notification.requestPermission(); p.notif.enabled = r === "granted"; } catch (e) { p.notif.enabled = false; }
      }
      S.save();
      DQ.go(st.test ? "test" : "home");
    }
    draw();
    return box;
  };

  // ------------------------------------------------------------- dashboard
  R.home = () => {
    const p = S.profile();
    const now = new Date();
    const due = L().due();
    const counts = L().counts();
    const today = S.day(p);
    const goal = p.time.daily * 60;
    const pct = Math.min(100, Math.round((today.sec / goal) * 100));
    const cefr = L().cefr();
    const hour = now.getHours();
    const hello = hour < 11 ? "Guten Morgen" : hour < 18 ? "Guten Tag" : "Guten Abend";
    const recos = L().recommendations();
    const sim = p.missions.brot_kaufen || readSim();
    const weekDay = now.getDay();
    const showWeekly = weekDay === 0 || weekDay === 1 ? p.weekly.lastShown !== S.today() : false;

    const msg = due.length
      ? _("Tu as " + due.length + " révisions qui t’attendent. Quelques minutes suffisent !", "You have " + due.length + " reviews waiting. A few minutes is enough!")
      : today.sec > goal ? _("Objectif du jour atteint. Wunderbar ! Tout ce que tu fais en plus est un bonus.", "Today’s goal reached. Wunderbar! Anything extra is a bonus.")
      : _("Prêt pour quelques mots nouveaux ? Je t’en ai choisi " + p.prefs.newPerSession + ".", "Ready for a few new words? I picked " + p.prefs.newPerSession + " for you.");

    return h("div.stack.fade-in",
      h("h1", hello + ", " + p.name + "!"),
      DQ.qubiSays(msg, today.sec > goal ? "happy" : ""),
      h("div.grid.g3",
        h("div.card.stack",
          h("div.spread", h("b", _("Objectif du jour", "Today’s goal")), h("span.pill.q", Math.floor(today.sec / 60) + " / " + p.time.daily + " min")),
          h("div.bar", h("i", { style: { width: pct + "%" } })),
          h("div.row", h("a.btn.primary", { href: "#/review" }, due.length ? "🔁 " + _("Réviser", "Review") + " (" + due.length + ")" : "✨ " + _("Apprendre des mots", "Learn new words")))),
        h("div.card.stack",
          h("b", _("Niveau A1 — progression évaluée", "Level A1 — assessed progress")),
          h("div.bar.amber", h("i", { style: { width: cefr.progress + "%" } })),
          h("div.small.muted", cefr.progress + " % · " + (p.placement ? _("test de niveau : ", "placement test: ") + p.placement.level : _("test de niveau pas encore fait", "placement test not taken yet"))),
          h("a.btn.small", { href: "#/stats" }, _("Détails", "Details"))),
        h("div.card.stack",
          h("b", "🥨 Life Simulator"),
          h("div.small.muted", sim && sim.completed ? _("Brot kaufen réussi · meilleur score ", "Brot kaufen done · best score ") + (sim.best || 0) + " %" : _("Mission « Brot kaufen » : achète du pain en allemand.", "Mission “Brot kaufen”: buy bread in German.")),
          h("a.btn.small", { href: "sim/index.html" }, _("Jouer la mission", "Play the mission")))),
      h("div.grid.g4",
        kpi(counts.learning + counts.due, _("mots en cours", "words in progress")),
        kpi(counts.known, _("mots connus", "words known")),
        kpi(counts.mastered, _("mots maîtrisés", "words mastered")),
        kpi(DQ.allEntries().length, _("mots dans le dictionnaire", "words in the dictionary"))),
      showWeekly ? h("a.card.row", { href: "#/stats/week", style: { textDecoration: "none" } }, DQ.qubiFace("cheer", 40), h("b", _("Ton bilan de la semaine est prêt", "Your weekly review is ready"))) : null,
      recos.length ? h("div.card.stack", h("b", _("Qubi te conseille", "Qubi suggests")),
        recos.map((r) => h("div.spread", h("div", h("b", r.label), h("div.small.muted", r.why)),
          h("div.row", r.lesson ? h("a.btn.small", { href: "#/grammar/" + r.lesson }, _("Leçon", "Lesson")) : null, r.quiz ? h("a.btn.small", { href: "#/quiz/" + r.quiz }, _("Quiz", "Quiz")) : null)))) : null,
      h("div.grid.g3",
        tile("dict", "📖"), tile("grammar", "📘"), tile("quiz", "🎮"), tile("conj", "🔤"), tile("read", "📰"), tile("tutor", "🧑‍🏫")));
  };
  function kpi(n, label) { return h("div.card.kpi", h("b", String(n)), h("span", label)); }
  function tile(r, ic) {
    const n = DQ.NAV.find((x) => x[0] === r);
    return h("a.tile", { href: "#/" + r }, h("div.ic", ic), h("b", _(n[2], n[3])), h("span", _(...DQ.MODULE_INFO[r])));
  }
  /** Mission progress saved by the simulator (sim/ writes dqdt.progress). */
  function readSim() {
    try { const v = JSON.parse(localStorage.getItem("dqdt.progress") || "{}"); return (v.missions || {}).brot_kaufen || null; } catch (e) { return null; }
  }
  DQ.readSim = readSim;

  // ------------------------------------------------------------- placement test (module 11)
  R.test = () => {
    const items = DQ_DATA.placement;
    const LEVELS = ["A1", "A2", "B1", "B2", "C1"];
    const box = h("div.stack.fade-in");
    let lvl = 1, asked = [], perLevel = {}, step = 0, start = Date.now();
    const pickNext = () => {
      const pool = items.filter((it) => it[0] === LEVELS[lvl] && !asked.includes(it));
      return pool[Math.floor(Math.random() * pool.length)];
    };
    const intro = () => {
      box.innerHTML = "";
      box.append(h("h1", _("Test de niveau", "Placement test")),
        DQ.qubiSays(_("Environ 20 à 30 questions qui s’adaptent à tes réponses : vocabulaire, grammaire et lecture. Le résultat est une estimation, pas un certificat. Tu peux arrêter à tout moment.",
          "About 20 to 30 questions that adapt to your answers: vocabulary, grammar and reading. The result is an estimate, not a certificate. You can stop at any time.")),
        h("div.row", h("button.btn.primary", { onclick: next }, _("Commencer", "Start")), h("a.btn.ghost", { href: "#/home" }, _("Plus tard", "Later"))));
    };
    function next() {
      const it = pickNext();
      const done = asked.length >= 24 || !it;
      if (done) return result();
      asked.push(it); step++;
      box.innerHTML = "";
      const [, skill, q, opts, a] = it;
      const skillName = { V: _("Vocabulaire", "Vocabulary"), G: _("Grammaire", "Grammar"), L: _("Lecture", "Reading") }[skill];
      box.append(h("div.spread", h("span.pill", _("Question ", "Question ") + step), h("span.pill.q", skillName)),
        h("div.card.stack", h("div.big-de", { style: { fontSize: "24px" } }, q),
          DQ.shuffle(opts.map((o, i) => [o, i])).map(([o, i]) => h("button.choice", { onclick: () => answer(it, i === a) }, o))),
        h("button.btn.ghost.small", { onclick: result }, _("Arrêter et voir mon niveau", "Stop and see my level")));
    }
    function answer(it, ok) {
      const L0 = it[0];
      perLevel[L0] = perLevel[L0] || { n: 0, ok: 0 };
      perLevel[L0].n++; if (ok) perLevel[L0].ok++;
      const pl = perLevel[L0];
      // staircase: move up after 3 right at a level, down after 2 wrong
      if (pl.ok >= 3 && lvl < LEVELS.length - 1 && pl.n <= 5) lvl++;
      else if (pl.n - pl.ok >= 2 && lvl > 0 && !(perLevel[LEVELS[lvl - 1]] && perLevel[LEVELS[lvl - 1]].n >= 4)) lvl--;
      else if (pl.n >= 6) { if (pl.ok >= 4 && lvl < LEVELS.length - 1) lvl++; else return result(); }
      next();
    }
    function result() {
      let level = "A1";
      for (const L1 of LEVELS) { const r = perLevel[L1]; if (r && r.n >= 3 && r.ok / r.n >= 0.6) level = L1; }
      const p = S.profile();
      const total = Object.values(perLevel).reduce((a, r) => a + r.n, 0), ok = Object.values(perLevel).reduce((a, r) => a + r.ok, 0);
      p.placement = { level, date: Date.now(), score: total ? Math.round((100 * ok) / total) : 0, min: Math.round((Date.now() - start) / 60000), detail: perLevel };
      p.level = level;
      S.save();
      box.innerHTML = "";
      box.append(h("h1", _("Ton niveau estimé : ", "Your estimated level: ") + level),
        DQ.qubiSays(level === "A1" ? _("Parfait pour commencer avec le contenu A1 : tu ne refais rien d’inutile, les mots que tu connais passeront vite.", "Perfect to start with the A1 content: you won’t redo anything useless, words you know will go fast.")
          : _("Bravo ! Le contenu disponible pour l’instant est A1–A2 : marque comme « connus » les mots déjà sus, ils ne reviendront pas inutilement. D’autres niveaux arrivent.",
            "Well done! Content available for now is A1–A2: mark words you already know as “known”, they won’t come back needlessly. More levels are coming."), "happy"),
        h("div.card", h("table.t", h("tr", h("th", _("Niveau", "Level")), h("th", _("Réponses justes", "Correct answers"))),
          LEVELS.filter((x) => perLevel[x]).map((x) => h("tr", h("td", x), h("td", perLevel[x].ok + " / " + perLevel[x].n))))),
        h("p.small.muted", _("Estimation non certifiante. Tu peux refaire le test quand tu veux.", "Non-certifying estimate. You can retake the test whenever you like.")),
        h("div.row", h("a.btn.primary", { href: "#/home" }, _("Aller au tableau de bord", "Go to the dashboard")), level !== "A1" ? h("a.btn", { href: "#/dict?mark=1" }, _("Marquer les mots connus", "Mark known words")) : null));
    }
    intro();
    return box;
  };

  // ------------------------------------------------------------- profile & settings
  R.profile = () => {
    const p = S.profile();
    const box = h("div.stack.fade-in");
    const save = (msg) => { S.save(); DQ.toast(msg || _("Enregistré ✔", "Saved ✔")); };
    const num = (v, f) => h("input", { type: "number", min: 1, max: 240, value: v, onchange: (e) => { f(Math.max(1, parseInt(e.target.value, 10) || 1)); save(); } });
    const days = [_("dim", "Sun"), _("lun", "Mon"), _("mar", "Tue"), _("mer", "Wed"), _("jeu", "Thu"), _("ven", "Fri"), _("sam", "Sat")];
    box.append(
      h("h1", _("Profil & réglages", "Profile & settings")),
      h("div.grid.g2",
        h("div.card.stack",
          h("h2", "👤 " + _("Profil", "Profile")),
          h("label.f", _("Nom", "Name"), h("input", { type: "text", value: p.name, onchange: (e) => { p.name = e.target.value || p.name; save(); } })),
          h("label.f", _("Langue de l’interface", "Interface language"), h("select", { onchange: (e) => { p.lang = e.target.value; save(); DQ.render(); } },
            [["fr", "Français"], ["en", "English"]].map(([v, l]) => h("option", { value: v, selected: p.lang === v }, l)))),
          h("label.f", _("Niveau actuel", "Current level"), h("select", { onchange: (e) => { p.level = e.target.value; save(); } },
            ["A1", "A2", "B1", "B2", "C1"].map((l) => h("option", { selected: p.level === l }, l)))),
          h("div.small.muted", _("Créé le ", "Created on ") + new Date(p.created).toLocaleDateString())),
        h("div.card.stack",
          h("h2", "⏱ " + _("Gestion du temps", "Time management")),
          h("label.f", _("Minutes par jour", "Minutes per day"), h("div.chips", [5, 10, 15, 20, 30, 45].map((m) => h("button.chip" + (p.time.daily === m ? ".on" : ""), { onclick: () => { p.time.daily = m; save(); DQ.render(); } }, m)))),
          h("label.f", _("Ou personnalisé", "Or custom"), num(p.time.daily, (v) => (p.time.daily = v))),
          h("label.f", _("Durée d’une session (min)", "Session length (min)"), num(p.time.session, (v) => (p.time.session = v))),
          h("label.f", _("Nouveaux mots par session", "New words per session"), num(p.prefs.newPerSession, (v) => (p.prefs.newPerSession = Math.min(30, v)))),
          h("label.check", h("input", { type: "checkbox", checked: p.prefs.timer, onchange: (e) => { p.prefs.timer = e.target.checked; save(); DQ.render(); } }), _("Afficher le chrono de session", "Show the session timer")),
          h("button.btn.small", { onclick: () => { DQ.resetSession(); DQ.toast(_("Nouvelle session", "New session")); DQ.render(); } }, _("Démarrer une nouvelle session", "Start a new session")))),
      h("div.grid.g2",
        h("div.card.stack",
          h("h2", "🔔 " + _("Rappels et nouveaux mots", "Reminders and new words")),
          h("label.check", h("input", { type: "checkbox", checked: p.notif.enabled, onchange: async (e) => {
            if (e.target.checked && "Notification" in window && Notification.permission !== "granted") {
              const r = await Notification.requestPermission().catch(() => "denied");
              if (r !== "granted") { e.target.checked = false; DQ.toast(_("Notifications refusées par le navigateur.", "Notifications blocked by the browser.")); return; }
            }
            p.notif.enabled = e.target.checked; save();
          } }), _("Activer les rappels", "Enable reminders")),
          h("label.f", _("Un nouveau mot toutes les", "A new word every"), h("div.chips", [1, 2, 3].map((n) => h("button.chip" + (p.notif.every === n ? ".on" : ""), { onclick: () => { p.notif.every = n; save(); DQ.render(); } }, n + " h")))),
          h("div.row", h("label.f", _("Silence de", "Quiet from"), h("input", { type: "time", value: p.notif.quietFrom, onchange: (e) => { p.notif.quietFrom = e.target.value; save(); } })),
            h("label.f", _("à", "to"), h("input", { type: "time", value: p.notif.quietTo, onchange: (e) => { p.notif.quietTo = e.target.value; save(); } }))),
          h("label.f", _("Jours de repos", "Rest days"), h("div.chips", days.map((d, i) => h("button.chip" + (p.notif.restDays.includes(i) ? ".on" : ""), { onclick: () => {
            p.notif.restDays = p.notif.restDays.includes(i) ? p.notif.restDays.filter((x) => x !== i) : p.notif.restDays.concat(i); save(); DQ.render(); } }, d)))),
          h("label.f", _("Maximum par jour", "Maximum per day"), num(p.notif.maxPerDay, (v) => (p.notif.maxPerDay = Math.min(12, v)))),
          h("p.small.muted", _("Les rappels arrivent pendant que l’application est ouverte ou installée et active. Sur Android, le système peut les retarder pour économiser la batterie.",
            "Reminders arrive while the app is open, or installed and active. On Android the system may delay them to save battery."))),
        h("div.card.stack",
          h("h2", "🤖 Qubi & " + _("sons", "sounds")),
          h("label.check", h("input", { type: "checkbox", checked: p.prefs.qubi, onchange: (e) => { p.prefs.qubi = e.target.checked; save(); } }), _("Afficher Qubi (conseils et encouragements)", "Show Qubi (tips and encouragement)")),
          h("label.check", h("input", { type: "checkbox", checked: p.prefs.sfx, onchange: (e) => { p.prefs.sfx = e.target.checked; save(); } }), _("Effets sonores", "Sound effects")),
          h("label.check", h("input", { type: "checkbox", checked: p.prefs.showTranslation, onchange: (e) => { p.prefs.showTranslation = e.target.checked; save(); } }), _("Afficher les traductions des exemples", "Show translations of examples")),
          h("label.f", _("Vitesse de la voix allemande", "German voice speed"), h("select", { onchange: (e) => { p.prefs.audioRate = parseFloat(e.target.value); save(); DQ.say("Guten Tag! Wie geht es Ihnen?", { id: "w_guten_tag" }); } },
            [[0.8, _("Lente", "Slow")], [1, _("Normale", "Normal")], [1.15, _("Rapide", "Fast")]].map(([v, l]) => h("option", { value: v, selected: p.prefs.audioRate === v }, l)))))),
      h("div.card.stack",
        h("h2", "💾 " + _("Profils, sauvegarde et données", "Profiles, backup and data")),
        h("div.chips", S.profiles().map((q) => h("button.chip" + (q.id === p.id ? ".on" : ""), { onclick: () => { S.switchTo(q.id); DQ.resetSession(); DQ.render(); } }, q.name))),
        h("div.row",
          h("button.btn.small", { onclick: () => { const n = prompt(_("Nom du nouveau profil", "Name of the new profile")); if (n) { S.create(n, p.lang); DQ.resetSession(); DQ.go("home"); } } }, "➕ " + _("Nouveau profil", "New profile")),
          h("button.btn.small", { onclick: exportData }, "⬇️ " + _("Exporter mes données", "Export my data")),
          h("label.btn.small", "⬆️ " + _("Restaurer une sauvegarde", "Restore a backup"), h("input", { type: "file", accept: ".json,application/json", hidden: true, onchange: importData })),
          h("button.btn.small", { style: { color: "var(--bad)" }, onclick: () => {
            if (confirm(_("Supprimer définitivement le profil « " + p.name + " » et toutes ses données ?", "Permanently delete the profile “" + p.name + "” and all its data?"))) { S.remove(p.id); location.hash = "#/" + (S.profile() ? "home" : "onboarding"); DQ.render(); }
          } }, "🗑 " + _("Supprimer ce profil", "Delete this profile"))),
        h("p.small.muted", _("Tes données restent sur cet appareil. Aucun compte, aucun envoi. Pour passer d’un appareil à l’autre, exporte puis restaure le fichier.",
          "Your data stays on this device. No account, nothing is sent. To move between devices, export and then restore the file."))),
      h("div.card.stack",
        h("h2", "📲 " + _("Installer l’application", "Install the app")),
        h("p.small", _("Ouvre l’application depuis son adresse web dans Chrome ou Edge (Windows, Android), puis « Installer l’application » / « Ajouter à l’écran d’accueil ». Elle fonctionne ensuite hors ligne.",
          "Open the app from its web address in Chrome or Edge (Windows, Android), then “Install app” / “Add to home screen”. It then works offline."))));
    return box;
  };
  function exportData() {
    const blob = new Blob([S.exportJSON()], { type: "application/json" });
    const a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = "deepq-sauvegarde-" + S.today() + ".json";
    a.click();
    setTimeout(() => URL.revokeObjectURL(a.href), 2000);
    try { navigator.clipboard.writeText(S.exportJSON()); } catch (e) { /* ignore */ }
  }
  function importData(e) {
    const f = e.target.files[0];
    if (!f) return;
    f.text().then((t) => {
      try { const r = S.importJSON(t); DQ.toast(_("Restauré : " + r.added + " profil(s), " + r.kept + " plus récent(s) conservé(s)", "Restored: " + r.added + " profile(s), " + r.kept + " newer kept")); DQ.render(); }
      catch (err) { DQ.toast(_("Fichier non reconnu.", "File not recognised.")); }
    });
  }
})();
