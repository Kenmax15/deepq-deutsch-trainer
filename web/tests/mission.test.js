// Headless test of the web mission engine (same scenarios as godot/tests/test_mission.gd).
// Run:  node web/tests/mission.test.js
const path = require("path");
const fs = require("fs");
const MissionEngine = require("../sim/js/mission.js");

const data = JSON.parse(fs.readFileSync(path.join(__dirname, "../sim/data/brot_kaufen.json"), "utf8"));
let failures = 0;
const check = (cond, msg) => { if (cond) console.log("  ok   " + msg); else { failures++; console.error("  FAIL " + msg); } };

let saved = {};
const store = { load: () => JSON.parse(JSON.stringify(saved)), save: (v) => { saved = JSON.parse(JSON.stringify(v)); } };
let events = [];
function engine() {
  const e = new MissionEngine(data, { lang: () => "fr", store });
  e.on("npcLine", (id) => events.push("npc:" + id));
  e.on("evaluated", (r) => events.push("ans:" + r));
  e.on("objective", (o) => events.push("obj:" + o));
  return e;
}
const N = MissionEngine.normalize;

console.log("Normalisation");
check(N("Guten Morgen! Zwei Brötchen, bitte.") === "guten morgen zwei broetchen bitte", "umlauts and punctuation folded");
check(N("zwei BROTCHEN") === "zwei broetchen", "missing umlaut accepted");
check(N("Ein Weißbrot") === "ein weissbrot", "ß folded");
check(N("2,60 €") === "2 60", "amount normalised");

console.log("Guided path (perfect run)");
let r = engine();
r.begin();
check(events.includes("npc:s_greet"), "seller greets first");
r.choose(0);
check(r.nodeId === "bread", "goes to bread choice");
r.choose(0);
check(r.vars.bread === "roggen", "bread = roggen");
r.choose(0);
check(r.nodeId === "pay" && r.vars.rolls === 2, "two rolls, now paying");
check(r.totalCents() === 340, "total 3,40 €");
check(events.includes("npc:s_total_roggen_2"), "price line matches order");
const opts = r.payOptions();
check(opts.length === 4 && opts.includes("3,40 €") && new Set(opts).size === 4, "4 distinct payment options incl. 3,40 €");
r.pay("3,40 €");
check(r.nodeId === "bag", "payment accepted");
r.choose(0);
r.choose(0);
check(r.finished, "mission finished");
check(r.stats.firstTryCorrect === 6 && r.stats.steps.length === 6, "6/6 first-try correct");
check(saved.missions.brot_kaufen.completed && saved.missions.brot_kaufen.best === 100, "completion and best score saved");

console.log("Errors, retries and free answers");
events = []; saved = {};
r = engine();
r.begin();
r.choose(3);
check(r.nodeId === "order" && events.includes("ans:wrong"), "wrong greeting keeps the step");
check(events.includes("npc:s_pardon"), "seller asks again (Wie bitte?)");
check(r.stats.errors.length === 1 && r.stats.errors[0].cat === "greeting", "error logged");
r.submitFree("guten tag, ich hätte gern ein vollkornbrot");
check(r.nodeId === "extras" && r.vars.bread === "vollkorn", "free answer with bread skips to extras");
check(r.done.includes("bread"), "skipped objective marked done");
r.submitFree("ja zwei brötchens bitte");
check(r.nodeId === "extras" && r.stats.errors[r.stats.errors.length - 1].cat === "plural", "wrong plural detected");
r.submitFree("Nein danke, das ist alles");
check(r.nodeId === "pay" && r.totalCents() === 290, "no rolls: 2,90 €");
r.pay("3,90 €");
check(r.nodeId === "pay" && r.stats.errors[r.stats.errors.length - 1].cat === "numbers", "wrong amount logged (numbers)");
r.submitFree("2,90");
check(r.nodeId === "bag", "typed amount accepted");
r.submitFree("nein bitte");
check(r.nodeId === "bag", "'Nein, bitte' rejected");
r.submitFree("Nein, danke");
r.submitFree("blabla");
check(events.includes("ans:unknown"), "unrecognised answer handled");
r.submitFree("Danke, Ihnen auch. Tschüss!");
check(r.finished, "finished with free answers");
const sc = Math.round((100 * r.stats.firstTryCorrect) / r.stats.steps.length);
console.log("  score: " + sc + " %  (" + r.stats.firstTryCorrect + "/" + r.stats.steps.length + ")");
check(sc === 0 && r.stats.steps.length === 5, "score counts only first-try answers (5 steps, bread skipped)");
check(saved.errors.length === 4, "errors kept in the journal");

console.log("Typed bread names (compound words)");
saved = {};
for (const [txt, want] of [["Ein Roggenbrot, bitte.", "roggen"], ["ein vollkornbrot", "vollkorn"], ["Weißbrot bitte", "weiss"]]) {
  const e = engine(); e.begin(); e.choose(1); e.submitFree(txt);
  check(e.nodeId === "extras" && e.vars.bread === want, "'" + txt + "' accepted at the bread step");
}
const ew = engine(); ew.begin(); ew.choose(1); ew.submitFree("Einen Weißbrot, bitte");
check(ew.nodeId === "bread" && ew.stats.errors[0].cat === "article", "'Einen Weißbrot' flagged as article error");

console.log("Hints and checkpoint");
saved = {};
r = engine();
r.begin();
const h = r.hint();
check(h.includes("Ich hätte gern"), "hint text in French");
r.choose(1);
const r2 = engine();
check(r2.hasCheckpoint() && r2.restoreCheckpoint() && r2.nodeId === "bread", "checkpoint restores the bread step");

console.log("");
if (failures === 0) console.log("ALL TESTS PASSED");
else { console.error(failures + " TEST(S) FAILED"); process.exit(1); }
