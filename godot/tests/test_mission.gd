extends Node
## Headless test of the "Brot kaufen" mission logic.
## Run:  godot --headless --path godot res://tests/test_mission.tscn

var failures := 0
var events: Array = []


func check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok   ", msg)
	else:
		failures += 1
		printerr("  FAIL ", msg)


func runner() -> MissionRunner:
	var r := MissionRunner.new()
	add_child(r)
	r.load_mission("res://data/missions/brot_kaufen.json")
	r.reset()
	r.npc_line.connect(func(id, _l): events.append("npc:" + id))
	r.answer_evaluated.connect(func(res, _fb, _m, _a): events.append("ans:" + res))
	r.objective_completed.connect(func(o): events.append("obj:" + o))
	return r


func _ready() -> void:
	await get_tree().process_frame
	var gs = get_node_or_null("/root/GameState")
	check(gs != null, "GameState autoload available")
	gs.settings.ui_lang = "fr"
	gs.reset_progress()

	print("Normalisation")
	check(MissionRunner.normalize("Guten Morgen! Zwei Brötchen, bitte.") == "guten morgen zwei broetchen bitte", "umlauts and punctuation folded")
	check(MissionRunner.normalize("zwei BROTCHEN") == "zwei broetchen", "missing umlaut accepted")
	check(MissionRunner.normalize("Ein Weißbrot") == "ein weissbrot", "ß folded")

	print("Guided path (perfect run)")
	var r := runner()
	r.begin_dialogue()
	check(events.has("npc:s_greet"), "seller greets first")
	r.choose_option(0)                      # Guten Morgen! Ich hätte gern ein Brot
	check(r.node_id == "bread", "goes to bread choice")
	r.choose_option(0)                      # Roggenbrot
	check(r.vars.bread == "roggen", "bread = roggen")
	r.choose_option(0)                      # zwei Brötchen
	check(r.node_id == "pay" and r.vars.rolls == 2, "two rolls, now paying")
	check(r.total_cents() == 340, "total 3,40 €")
	check(events.has("npc:s_total_roggen_2"), "price line matches order")
	var opts := r.pay_options()
	check(opts.size() == 4 and opts.has("3,40 €"), "4 payment options incl. 3,40 €")
	r.choose_payment("3,40 €")
	check(r.node_id == "bag", "payment accepted")
	r.choose_option(0)
	r.choose_option(0)
	check(r.finished, "mission finished")
	check(r.stats.first_try_correct == 6 and r.stats.steps.size() == 6, "6/6 first-try correct")
	check(gs.progress.missions.brot_kaufen.completed, "completion saved")
	check(gs.progress.vocab.has("das Brötchen"), "vocabulary stored")

	print("Errors, retries and free answers")
	events.clear()
	gs.reset_progress()
	r = runner()
	r.begin_dialogue()
	r.choose_option(3)                      # Gute Nacht! -> wrong
	check(r.node_id == "order" and events.has("ans:wrong"), "wrong greeting keeps the step")
	check(events.has("npc:s_pardon"), "seller asks again (Wie bitte?)")
	check(gs.progress.errors.size() == 1 and gs.progress.errors[0].cat == "greeting", "error logged in journal")
	r.submit_free("guten tag, ich hätte gern ein vollkornbrot")
	check(r.node_id == "extras" and r.vars.bread == "vollkorn", "free answer with bread skips to extras")
	check("bread" in r.done_objectives, "skipped objective marked done")
	r.submit_free("ja zwei brötchens bitte")
	check(r.node_id == "extras" and gs.progress.errors[-1].cat == "plural", "wrong plural detected")
	r.submit_free("Nein danke, das ist alles")
	check(r.node_id == "pay" and r.total_cents() == 290, "no rolls: 2,90 €")
	r.choose_payment("3,90 €")
	check(r.node_id == "pay" and gs.progress.errors[-1].cat == "numbers", "wrong amount logged (numbers)")
	r.submit_free("2,90")
	check(r.node_id == "bag", "typed amount accepted")
	r.submit_free("nein bitte")
	check(r.node_id == "bag", "'Nein, bitte' rejected")
	r.submit_free("Nein, danke")
	r.submit_free("blabla")
	check(events.has("ans:unknown"), "unrecognised answer handled")
	r.submit_free("Danke, Ihnen auch. Tschüss!")
	check(r.finished, "finished with free answers")
	check(r.stats.hints == 0, "no hints counted")
	var sc: int = int(round(100.0 * r.stats.first_try_correct / r.stats.steps.size()))
	print("  score: ", sc, " %  (", r.stats.first_try_correct, "/", r.stats.steps.size(), ")")
	check(sc == 0 and r.stats.steps.size() == 5, "score counts only first-try answers (5 steps, bread skipped)")

	print("Hints and checkpoint")
	gs.reset_progress()
	r = runner()
	r.begin_dialogue()
	var h: String = r.request_hint()
	check(h.contains("Ich hätte gern"), "hint text in French")
	r.choose_option(1)
	var r2 := runner()
	check(r2.restore_checkpoint() and r2.node_id == "bread", "checkpoint restores the bread step")

	print("")
	if failures == 0:
		print("ALL TESTS PASSED")
	else:
		printerr("%d TEST(S) FAILED" % failures)
	get_tree().quit(failures)
