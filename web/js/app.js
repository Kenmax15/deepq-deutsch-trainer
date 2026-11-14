/* DeepQ Deutsch Trainer — app shell: data, routing, layout, session time, reminders. */
(function () {
  "use strict";
  const DQ = window.DQ;
  const { h, _ } = DQ;
  const S = DQ.store;

  // ------------------------------------------------------------- data
  const D = window.DQ_DATA;
  DQ.lexicon = DQ.lex.build(D);
  DQ.byId = new Map(DQ.lexicon.map((e) => [e.id, e]));
  DQ.forms = DQ.lex.indexForms(DQ.lexicon, DQ.conj);
  DQ.verbIndex = DQ.conj.index(D.verbs);
  /** All entries including the learner's personal words. */
  DQ.allEntries = () => {
    const p = S.profile();
    return DQ.lexicon.concat(((p && p.personal) || []).map((w) => Object.assign({ personal: true }, w)));
  };
  DQ.entry = (id) => DQ.byId.get(id) || (((S.profile() || {}).personal || []).find((w) => w.id === id));
  DQ.CATS = {
    people: ["Personnes & famille", "People & family"], food: ["Manger & boire", "Food & drink"], bakery: ["Boulangerie", "Bakery"],
    shopping: ["Courses & argent", "Shopping & money"], home: ["Logement", "Home"], town: ["Ville & transports", "Town & transport"],
    time: ["Temps & calendrier", "Time & calendar"], body: ["Corps & santé", "Body & health"], clothes: ["Vêtements", "Clothes"],
    work: ["Travail & école", "Work & school"], leisure: ["Loisirs", "Leisure"], nature: ["Nature & météo", "Nature & weather"],
    animals: ["Animaux", "Animals"], communication: ["Communication", "Communication"], verbs: ["Verbes", "Verbs"],
    adjectives: ["Adjectifs", "Adjectives"], colours: ["Couleurs", "Colours"], adverbs: ["Adverbes", "Adverbs"],
    phrases: ["Expressions", "Phrases"], numbers: ["Nombres", "Numbers"], personal: ["Mes mots", "My words"],
  };
  DQ.catName = (c) => { const n = DQ.CATS[c] || [c, c]; return _(n[0], n[1]); };

  // ------------------------------------------------------------- routes & navigation
  DQ.routes = DQ.routes || {};
  const NAV = [
    ["sep", "Aujourd’hui", "Today"],
    ["home", "🏠", "Accueil", "Home"], ["review", "🔁", "Réviser", "Review"],
    ["sep", "Apprendre", "Learn"],
    ["dict", "📖", "Dictionnaire illustré", "Picture dictionary"], ["cards", "🃏", "Flashcards", "Flashcards"],
    ["grammar", "📘", "Grammatikbuch", "Grammar book"], ["conj", "🔤", "Conjugaison", "Conjugation"],
    ["build", "🧩", "Construire des phrases", "Build sentences"], ["families", "🌳", "Familles de mots", "Word families"],
    ["read", "📰", "Lecture intelligente", "Smart reading"], ["think", "💭", "Penser en allemand", "Think in German"],
    ["pron", "🎙️", "Prononciation", "Pronunciation"],
    ["sep", "Pratiquer", "Practise"],
    ["quiz", "🎮", "Quiz Arena", "Quiz Arena"], ["sim", "🥨", "Life Simulator", "Life Simulator"], ["tutor", "🧑‍🏫", "DeepQ Tutor", "DeepQ Tutor"],
    ["sep", "Suivi", "Progress"],
    ["stats", "📊", "Progression", "Progress"], ["journal", "📒", "Journal des erreurs", "Error journal"],
    ["test", "🎯", "Test de niveau", "Placement test"], ["profile", "⚙️", "Profil & réglages", "Profile & settings"],
  ];
  DQ.NAV = NAV;
  const TABS = [["home", "🏠", "Accueil", "Home"], ["learn", "📚", "Apprendre", "Learn"], ["review", "🔁", "Réviser", "Review"], ["quiz", "🎮", "Jouer", "Play"], ["profile", "👤", "Moi", "Me"]];

  function parseHash() {
    const raw = location.hash.replace(/^#\/?/, "");
    const [path, query] = raw.split("?");
    const parts = path.split("/").filter(Boolean);
    const params = Object.fromEntries(new URLSearchParams(query || ""));
    return { route: parts[0] || "home", args: parts.slice(1).map(decodeURIComponent), params };
  }
  DQ.go = (r) => { location.hash = "#/" + r; };

  let pageCleanup = null;
  function render() {
    DQ.stop();
    if (pageCleanup) { try { pageCleanup(); } catch (e) { /* ignore */ } pageCleanup = null; }
    const p = S.profile();
    const { route, args, params } = parseHash();
    if (!p && route !== "onboarding") { DQ.go("onboarding"); return; }
    document.documentElement.lang = (p && p.lang) || "fr";
    const app = document.getElementById("app");
    app.innerHTML = "";
    if (route === "onboarding") { app.appendChild(h("main.page", { style: { maxWidth: "640px" } }, DQ.routes.onboarding(args, params))); return; }
    const mod = DQ.routes[route] || DQ.routes.home;
    const navItem = NAV.find((n) => n[0] === route);
    const title = navItem ? _(navItem[2], navItem[3]) : route === "learn" ? _("Apprendre", "Learn") : "";
    const page = h("section.page");
    const layout = h("div.layout",
      h("aside.side",
        h("div.brand", DQ.qubiFace("", 30), "DeepQ Deutsch Trainer"),
        h("nav", NAV.map((n) => n[0] === "sep" ? h("div.sep", _(n[1], n[2])) :
          h("a" + (n[0] === route ? ".on" : ""), { href: "#/" + n[0] }, h("span", n[1]), _(n[2], n[3]))))),
      h("main.main",
        h("header.top", h("div.title", title), sessionPill(), h("button.icon-btn", { title: _("Profil", "Profile"), onclick: () => DQ.go("profile") }, "👤")),
        page),
      h("nav.tabs", TABS.map((t) => h("a" + (t[0] === route || (t[0] === "learn" && !["home", "review", "quiz", "profile"].includes(route)) ? ".on" : ""), { href: "#/" + t[0] }, h("span", t[1]), _(t[2], t[3])))));
    app.appendChild(layout);
    try {
      const out = mod(args, params, (fn) => { pageCleanup = fn; });
      if (out) page.appendChild(out);
    } catch (err) {
      console.error(err);
      page.appendChild(h("div.card", h("b", _("Oups, une erreur est survenue.", "Oops, something went wrong.")), h("pre.small", String(err && err.message))));
    }
    window.scrollTo(0, 0);
  }
  DQ.render = render;

  // learn hub (mobile tab) — every module as a tile
  DQ.MODULE_INFO = {
    dict: ["Mots illustrés, articles, pluriels, audio", "Pictures, articles, plurals, audio"],
    cards: ["Recto-verso, article, pluriel, phrases à trous", "Front/back, article, plural, gap sentences"],
    grammar: ["13 leçons A1 avec tableaux et exercices", "13 A1 lessons with tables and exercises"],
    conj: ["Tous les temps, cherche aussi une forme conjuguée", "All tenses, also search a conjugated form"],
    build: ["Remets les mots dans l’ordre", "Put the words in order"],
    families: ["Mots de la même famille", "Words from the same family"],
    read: ["Textes cliquables et questions", "Clickable texts and questions"],
    think: ["Décris, raconte, réponds en allemand", "Describe, tell, answer in German"],
    pron: ["Écoute, enregistre-toi, compare", "Listen, record yourself, compare"],
    quiz: ["Mini-jeux rapides, chrono, duel avec Qubi", "Quick games, timer, duel with Qubi"],
    sim: ["Missions en images et en sons", "Missions in pictures and sound"],
    tutor: ["Pose tes questions, fais-toi corriger", "Ask questions, get corrected"],
    stats: ["Ta progression et ton bilan de la semaine", "Your progress and weekly review"],
    journal: ["Tes erreurs et des exercices ciblés", "Your mistakes and targeted practice"],
    test: ["Trouve ton niveau (A1–C1)", "Find your level (A1–C1)"],
    review: ["Révisions espacées du jour", "Today’s spaced reviews"],
    profile: ["Profils, temps, rappels, sauvegarde", "Profiles, time, reminders, backup"],
    home: ["Tableau de bord", "Dashboard"],
  };
  DQ.routes.learn = () => h("div.stack",
    h("h1", _("Apprendre", "Learn")),
    h("div.grid.g3", NAV.filter((n) => n[0] !== "sep" && n[0] !== "home").map((n) =>
      h("a.tile", { href: "#/" + n[0] }, h("div.ic", n[1]), h("b", _(n[2], n[3])), h("span", _(...(DQ.MODULE_INFO[n[0]] || ["", ""])))))));

  // ------------------------------------------------------------- session time (module 18)
  let lastActivity = Date.now(), paused = false, sessionSec = 0, sessionNotified = false;
  ["pointerdown", "keydown", "scroll", "touchstart"].forEach((ev) => addEventListener(ev, () => { lastActivity = Date.now(); }, { passive: true }));
  function sessionPill() {
    const p = S.profile();
    if (!p || !p.prefs.timer) return null;
    const b = h("button.pill.session-timer", { title: _("Pause / reprise du chrono de session", "Pause / resume the session timer") });
    const upd = () => {
      const m = Math.floor(sessionSec / 60), goal = p.time.session;
      b.textContent = (paused ? "⏸ " : "⏱ ") + m + " / " + goal + " min";
    };
    b.onclick = () => { paused = !paused; upd(); DQ.toast(paused ? _("Session en pause — tout est sauvegardé.", "Session paused — everything is saved.") : _("C’est reparti !", "Off we go again!")); };
    upd();
    DQ._updPill = upd;
    return b;
  }
  setInterval(() => {
    const p = S.profile();
    if (!p || paused || document.hidden || Date.now() - lastActivity > 120000) return;
    sessionSec += 15;
    S.day(p).sec += 15;
    S.save();
    if (DQ._updPill) DQ._updPill();
    if (!sessionNotified && sessionSec >= p.time.session * 60) {
      sessionNotified = true;
      DQ.toast(_("🎉 Session de " + p.time.session + " min terminée ! Tu peux continuer ou faire une pause.", "🎉 " + p.time.session + "-minute session done! Carry on or take a break."), 4500);
    }
  }, 15000);
  DQ.resetSession = () => { sessionSec = 0; sessionNotified = false; };

  // ------------------------------------------------------------- reminders (module 07)
  function inQuiet(n, from, to) {
    const m = n.getHours() * 60 + n.getMinutes();
    const toMin = (s) => { const [a, b] = s.split(":").map(Number); return a * 60 + b; };
    const f = toMin(from), t = toMin(to);
    return f <= t ? m >= f && m < t : m >= f || m < t;
  }
  DQ.reminderAllowed = (p, now = new Date()) => {
    const n = p.notif;
    if (!n.enabled) return false;
    if (n.restDays.includes(now.getDay())) return false;
    if (inQuiet(now, n.quietFrom, n.quietTo)) return false;
    if (n.sentDay === S.today(now) && n.sentToday >= n.maxPerDay) return false;
    if (n.last && now - n.last < n.every * 3600000) return false;
    return true;
  };
  async function notify() {
    const p = S.profile();
    if (!p || !("Notification" in window) || Notification.permission !== "granted" || !DQ.reminderAllowed(p)) return;
    const pool = DQ.lexicon.filter((e) => e.type === "noun" && !p.cards[e.id]);
    const e = pool[Math.floor(Math.random() * pool.length)];
    if (!e) return;
    const title = "Qubi · " + (e.art ? e.art + " " : "") + e.de + " " + (e.emoji || "");
    const body = DQ.tr(e) + (e.pl ? " · " + _("pluriel", "plural") + " : die " + e.pl : "") + "\n" + e.ex[0];
    const n = p.notif;
    if (n.sentDay !== S.today()) { n.sentDay = S.today(); n.sentToday = 0; }
    n.sentToday += 1; n.last = Date.now(); S.save();
    const reg = navigator.serviceWorker && (await navigator.serviceWorker.getRegistration());
    const actions = [{ action: "know", title: _("Je connais", "I know it") }, { action: "learn", title: _("Apprendre", "Learn") }];
    if (reg && reg.showNotification) reg.showNotification(title, { body, tag: "dq-word", data: { id: e.id }, actions, icon: "icons/icon-192.png" });
    else new Notification(title, { body, tag: "dq-word" });
  }
  setInterval(notify, 60000);
  DQ.markKnown = (id) => {
    const p = S.profile(); const now = Date.now();
    p.cards[id] = p.cards[id] || {};
    for (const k of DQ.srs.SKILLS) p.cards[id][k] = Object.assign(DQ.srs.newCard(now), { int: 7, reps: 2, due: now + 7 * DQ.srs.DAY, last: now });
    p.introduced[id] = p.introduced[id] || now;
    S.save();
  };
  if (navigator.serviceWorker) {
    navigator.serviceWorker.addEventListener("message", (ev) => {
      const { action, id } = ev.data || {};
      if (action === "know" && id) { DQ.markKnown(id); DQ.toast(_("Noté comme connu ✔", "Marked as known ✔")); }
      if (action === "learn" && id) DQ.go("dict/" + id);
    });
  }

  // ------------------------------------------------------------- boot
  S.load();
  if (location.protocol.startsWith("http") && "serviceWorker" in navigator) navigator.serviceWorker.register("sw.js").catch(() => {});
  addEventListener("hashchange", render);
  render();
})();
