global.window = global;
for (const f of ["vocab_a1_1","vocab_a1_2","vocab_a1_3","verbs_a1","words_a1","grammar_a1","placement","extras_a1"]) require(require("path").join(__dirname, "../web/data/"+f+".js"));
const L = require(require("path").join(__dirname, "../web/js/core/lexicon.js"));
const C = require(require("path").join(__dirname, "../web/js/core/conjugate.js"));
const lex = L.build(DQ_DATA);
const items = [];
for (const e of lex) { items.push([e.id, e.say]); if (e.ex && e.ex[0]) items.push([e.id + "_ex", e.ex[0]]); }
DQ_DATA.sentences.forEach((s, i) => items.push(["s_" + i, s[0]]));
DQ_DATA.texts.forEach((t) => items.push(["text_" + t.id, t.de]));
DQ_DATA.grammar.forEach((g) => g.examples.forEach((x, i) => items.push(["g_" + g.id + "_" + i, x[0]])));
const counts = {}; lex.forEach(e => counts[e.type] = (counts[e.type]||0)+1);
console.error(JSON.stringify(counts), "lexicon", lex.length, "audio items", items.length);
// sanity: duplicate lemmas
const seen = {}; lex.forEach(e => { const k = e.lemma.toLowerCase(); if (seen[k]) console.error("DUP", e.lemma, seen[k]); seen[k] = e.id; });
process.stdout.write(JSON.stringify(items));
