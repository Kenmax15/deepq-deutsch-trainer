/* DeepQ Tutor (module 15): answers first from validated DeepQ content (dictionary, conjugation, grammar book);
 * if Ollama runs on this computer, a local language model can explain, correct and generate exercises.
 * Every AI answer is labelled as generated and is never stored as reference content. */
(function () {
  "use strict";
  const DQ = window.DQ;
  const { h, _ } = DQ;
  const S = DQ.store;
  const R = DQ.routes = DQ.routes || {};

  const TOPICS = [
    [/akkusativ|accusatif|accusative|einen|\bden\b/i, "g05"], [/dativ|datif|dative|\bmit\b|\bzum\b|\bzur\b/i, "g11"], [/plural|pluriel/i, "g04"],
    [/artikel|article|genre|gender|der die das/i, "g03"], [/perfekt|passé|past|partizip/i, "g12"], [/modal|können|müssen|wollen|möchte/i, "g08"],
    [/trennbar|séparable|separable/i, "g09"], [/negation|négation|nicht|kein/i, "g06"], [/frage|question|ordre|word order|position/i, "g07"],
    [/possessi|mein|dein|sein\b|ihr\b/i, "g10"], [/imperativ|impératif|imperative/i, "g13"], [/präsens|présent|present tense|conjugaison régulière/i, "g02"], [/sein und haben|être|avoir/i, "g01"],
  ];
  const strip = (html) => html.replace(/<[^>]+>/g, "");

  const Tutor = {
    url() { const p = S.profile(); return (p && p.prefs.ollamaUrl) || "http://localhost:11434"; },
    model: "", available: null,
    async detect() {
      try {
        const ctl = new AbortController(); setTimeout(() => ctl.abort(), 1500);
        const r = await fetch(this.url() + "/api/tags", { signal: ctl.signal });
        const j = await r.json();
        const names = (j.models || []).map((m) => m.name);
        const p = S.profile();
        this.models = names;
        this.model = (p.prefs.ollamaModel && names.includes(p.prefs.ollamaModel)) ? p.prefs.ollamaModel : names[0] || "";
        this.available = !!this.model;
      } catch (e) { this.available = false; this.models = []; }
      return this.available;
    },
    /** Validated answer from DeepQ content, or null. */
    validated(q) {
      const out = [];
      const conjAsk = /conjug|konjug|conjugate/i.test(q);
      const tokens = q.replace(/[?!.,;:«»„“"()]/g, " ").split(/\s+/).filter((t) => t.length > 1);
      const hits = [];
      for (const t of tokens) {
        const e = DQ.forms.get(DQ.fold(t));
        if (e && !hits.includes(e) && !["sein", "ihr", "die", "der", "das"].includes(t.toLowerCase())) hits.push(e);
        const v = DQ.verbIndex.get(t.toLowerCase());
        if (conjAsk && v) { const tb = DQ.conj.table(v); out.push(h("div.stack", h("b", v.inf + " — " + v.fr + " / " + v.en), h("table.t", tb.praesens.map((f, i) => h("tr", h("td", f), h("td.small.muted", tb.perfekt[i])))), h("a.small", { href: "#/conj/" + encodeURIComponent(v.inf) }, _("Toutes les formes", "All forms") + " →"))); }
      }
      if (!conjAsk) hits.slice(0, 3).forEach((e) => out.push(h("div.stack",
        h("b", (e.emoji || "") + " " + (e.art ? e.art + " " : "") + e.de + (e.pl ? " · die " + e.pl : "")),
        h("div", e.fr + " · " + e.en), e.ex ? h("div.small", h("i", e.ex[0]), " — ", DQ.lang() === "en" ? e.ex[2] : e.ex[1]) : null,
        e.type === "verb" ? h("div.small", _("Auxiliaire ", "Auxiliary ") + e.aux + " · Partizip II " + e.pp) : null,
        h("a.small", { href: "#/dict/" + e.id }, _("Fiche complète", "Full entry") + " →"))));
      const topic = TOPICS.find(([rx]) => rx.test(q));
      if (topic && !hits.length || topic && /explique|explain|règle|rule|pourquoi|why|quand|when|autrement|differently/i.test(q)) {
        const l = DQ_DATA.grammar.find((x) => x.id === topic[1]);
        const txt = strip(_(l.intro));
        out.push(h("div.stack", h("b", "📘 " + l.de), h("div", txt), h("div.small", h("i", l.examples[0][0]), " — ", DQ.lang() === "en" ? l.examples[0][2] : l.examples[0][1]), h("a.small", { href: "#/grammar/" + l.id }, _("Ouvrir la leçon", "Open the lesson") + " →")));
      }
      return out.length ? out : null;
    },
    /** Ask the local model (Ollama). */
    async ai(messages) {
      const p = S.profile();
      const errs = {};
      if (p.prefs.tutorJournal !== false) p.journal.slice(-60).forEach((e) => (errs[e.cat] = (errs[e.cat] || 0) + 1));
      const diff = Object.entries(errs).sort((a, b) => b[1] - a[1]).slice(0, 3).map(([c]) => c).join(", ");
      const sys = (DQ.lang() === "en"
        ? "You are DeepQ Tutor, a patient German tutor for an English-speaking learner at level " + p.level + ". Answer in English, briefly and clearly, with short German examples and their translation. When asked to correct, give the corrected sentence first, then explain each change. Never invent rules; if unsure, say so."
        : "Tu es DeepQ Tutor, un tuteur d’allemand patient pour un apprenant francophone de niveau " + p.level + ". Réponds en français, brièvement et clairement, avec de courts exemples allemands et leur traduction. Quand on te demande de corriger, donne d’abord la phrase corrigée, puis explique chaque correction. N’invente jamais de règle ; si tu n’es pas sûr, dis-le.")
        + (p.prefs.socratic ? (DQ.lang() === "en" ? " Use the Socratic method: guide with questions and hints instead of giving the answer straight away." : " Utilise la méthode socratique : guide par des questions et des indices au lieu de donner directement la réponse.") : "")
        + (diff ? (DQ.lang() === "en" ? " The learner often struggles with: " : " Difficultés fréquentes de l’apprenant : ") + diff + "." : "");
      const r = await fetch(this.url() + "/api/chat", { method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ model: this.model, stream: false, options: { temperature: 0.3 }, messages: [{ role: "system", content: sys }, ...messages] }) });
      const j = await r.json();
      return (j.message && j.message.content) || "";
    },
    /** Rule-based checks used when no AI is available (and shown alongside AI corrections). */
    rules(text) {
      const notes = [];
      const toks = text.replace(/[.,!?;:]/g, " ").split(/\s+/).filter(Boolean);
      toks.forEach((t, i) => {
        const e = DQ.forms.get(DQ.fold(t));
        if (e && e.type === "noun" && t[0] === t[0].toLowerCase() && i >= 0) notes.push(_("« " + t + " » : les noms prennent une majuscule → " + t[0].toUpperCase() + t.slice(1), "“" + t + "”: nouns are capitalised → " + t[0].toUpperCase() + t.slice(1)));
        const prev = (toks[i - 1] || "").toLowerCase();
        if (e && e.type === "noun" && e.art && DQ.fold(t) === DQ.fold(e.de)) {
          if (prev === "einen" && e.art !== "der") notes.push(_("« einen " + t + " » : einen est seulement masculin ; " + e.art + " " + e.de + " → " + (e.art === "die" ? "eine" : "ein"), "“einen " + t + "”: einen is masculine only; " + e.art + " " + e.de + " → " + (e.art === "die" ? "eine" : "ein")));
          if (prev === "eine" && e.art !== "die") notes.push(_("« eine " + t + " » : " + e.art + " " + e.de + " → ein/einen", "“eine " + t + "”: " + e.art + " " + e.de + " → ein/einen"));
          if (prev === "das" && e.art !== "das") notes.push(_("« das " + t + " » : c’est " + e.art + " " + e.de, "“das " + t + "”: it’s " + e.art + " " + e.de));
        }
      });
      if (/\bbrötchens\b/i.test(text)) notes.push(_("Pluriel : die Brötchen (sans -s)", "Plural: die Brötchen (no -s)"));
      return notes;
    },
    /** Correction block for free writing (module 27). */
    async correct(text, context) {
      const notes = this.rules(text);
      const box = h("div.stack");
      box.append(h("div.fb." + (notes.length ? "mid" : "ok"), h("b", h("span.ref-tag", _("règles DeepQ", "DeepQ rules")), " ", notes.length ? _("Points à vérifier", "Points to check") : _("Aucune erreur détectée par les règles simples", "No mistake found by the simple rules")), notes.map((n) => h("div", "• " + n))));
      if (this.available === null) await this.detect();
      if (this.available) {
        const wait = h("div.small.muted", "🤖 " + _("Le tuteur IA relit ton texte…", "The AI tutor is reading your text…"));
        box.append(wait);
        this.ai([{ role: "user", content: (DQ.lang() === "en" ? "Correct this German text (task: " : "Corrige ce texte allemand (consigne : ") + context + ") :\n" + text }])
          .then((ans) => { wait.replaceWith(h("div.msg.bot", h("span.ai-tag", "🤖 " + _("généré par IA · ", "AI-generated · ") + this.model + _(" · non vérifié", " · not verified")), h("div", { style: { whiteSpace: "pre-wrap", marginTop: "6px" } }, ans))); })
          .catch(() => wait.replaceWith(h("div.small.muted", _("Le tuteur IA ne répond pas.", "The AI tutor isn’t responding."))));
      }
      return box;
    },
  };
  DQ.tutor = Tutor;

  R.tutor = (args, params) => {
    const p = S.profile();
    const chat = h("div.chat");
    const status = h("div.small.muted", _("Recherche d’Ollama sur cet ordinateur…", "Looking for Ollama on this computer…"));
    const history = [];
    const inp = h("input", { type: "text", placeholder: _("Ta question (ex. « Pourquoi einen Kaffee mais ein Brot ? », « conjugue fahren »)", "Your question (e.g. “Why einen Kaffee but ein Brot?”, “conjugate fahren”)") });
    const add = (who, node) => { chat.append(h("div.msg." + who, node)); chat.lastChild.scrollIntoView({ behavior: "smooth", block: "nearest" }); };
    const ask = async (q) => {
      if (!q.trim()) return;
      add("me", q);
      inp.value = "";
      const val = Tutor.validated(q);
      if (val) add("bot", h("div.stack", h("span.ref-tag", "✔ " + _("contenu de référence vérifié", "verified reference content")), val));
      if (Tutor.available) {
        history.push({ role: "user", content: q });
        const wait = h("span.muted", "…");
        add("bot", wait);
        try {
          const ans = await Tutor.ai(history.slice(-8));
          history.push({ role: "assistant", content: ans });
          wait.parentNode.replaceWith(h("div.msg.bot", h("span.ai-tag", "🤖 " + _("généré par IA · ", "AI-generated · ") + Tutor.model + _(" · non vérifié", " · not verified")), h("div", { style: { whiteSpace: "pre-wrap", marginTop: "6px" } }, ans)));
        } catch (e) { wait.textContent = _("Ollama ne répond pas.", "Ollama isn’t responding."); }
      } else if (!val) {
        add("bot", h("div.stack", h("div", _("Je n’ai pas de réponse vérifiée à cette question. Essaie avec un mot allemand précis, « conjugue … », ou un thème (accusatif, pluriel, Perfekt…).",
          "I don’t have a verified answer to that. Try a specific German word, “conjugate …”, or a topic (accusative, plural, Perfekt…).")),
          h("div.small.muted", _("Pour des explications libres et des corrections détaillées, installe Ollama (gratuit) sur ton PC : le tuteur l’utilisera automatiquement.", "For free explanations and detailed corrections, install Ollama (free) on your PC: the tutor will use it automatically."))));
      }
    };
    Tutor.detect().then((ok) => {
      status.innerHTML = "";
      status.append(ok ? h("span", "🟢 " + _("IA locale active : ", "Local AI active: ") + Tutor.model + " (Ollama)") : h("span", "⚪ " + _("Mode hors IA : réponses issues des contenus validés uniquement.", "No-AI mode: answers from validated content only.")));
      if (params.q) ask(params.q);
    });
    add("bot", h("div", _("Hallo ! Je suis DeepQ Tutor. Pose-moi une question sur un mot, une règle, une conjugaison, ou colle une phrase à corriger (« corrige : … »).",
      "Hallo! I’m DeepQ Tutor. Ask me about a word, a rule, a conjugation, or paste a sentence to correct (“correct: …”).")));
    return h("div.stack.fade-in", h("h1", "DeepQ Tutor"), status,
      h("div.card", { style: { minHeight: "300px" } }, chat),
      h("form.row", { onsubmit: (e) => { e.preventDefault(); const q = inp.value; if (/^(corrige|correct)\s*:/i.test(q)) { add("me", q); inp.value = ""; Tutor.correct(q.replace(/^[^:]+:/, ""), "free text").then((n) => add("bot", n)); } else ask(q); } }, inp, h("button.btn.primary", _("Envoyer", "Send"))),
      h("details.card", h("summary", h("b", _("Réglages du tuteur", "Tutor settings"))),
        h("div.stack", { style: { marginTop: "10px" } },
          h("label.check", h("input", { type: "checkbox", checked: !!p.prefs.socratic, onchange: (e) => { p.prefs.socratic = e.target.checked; S.save(); } }), _("Mode socratique (le tuteur guide par des questions)", "Socratic mode (the tutor guides with questions)")),
          h("label.check", h("input", { type: "checkbox", checked: p.prefs.tutorJournal !== false, onchange: (e) => { p.prefs.tutorJournal = e.target.checked; S.save(); } }), _("Autoriser le tuteur à connaître mes difficultés (journal d’erreurs)", "Let the tutor know my difficulties (error journal)")),
          h("label.f", _("Adresse d’Ollama", "Ollama address"), h("input", { type: "text", value: Tutor.url(), onchange: (e) => { p.prefs.ollamaUrl = e.target.value.trim(); S.save(); Tutor.detect(); } })),
          h("label.f", _("Modèle", "Model"), h("input", { type: "text", value: p.prefs.ollamaModel || "", placeholder: "llama3.1:8b, qwen2.5:7b…", onchange: (e) => { p.prefs.ollamaModel = e.target.value.trim(); S.save(); Tutor.detect(); } })),
          h("p.small.muted", _("Installation : ollama.com → installer, puis « ollama pull qwen2.5:7b » (bon en allemand). Si l’application est ouverte depuis un site web, lance Ollama avec OLLAMA_ORIGINS=* pour l’autoriser.",
            "Setup: ollama.com → install, then “ollama pull qwen2.5:7b” (good at German). If the app is opened from a website, start Ollama with OLLAMA_ORIGINS=* to allow it.")))));
  };
})();
