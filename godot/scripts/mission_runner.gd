class_name MissionRunner
extends Node
## Data-driven mission logic. Reads a mission JSON file, runs the dialogue
## nodes, evaluates guided and free (typed) answers with offline rules,
## tracks objectives, errors, hints and score, and saves checkpoints.
## It has no UI or 3D dependency: the scene listens to its signals.

signal npc_line(line_id: String, line: Dictionary)
signal choices_ready(node_id: String, options: Array, kind: String)
signal answer_evaluated(result: String, feedback: String, model_line: String, answer: String)
signal objective_completed(objective_id: String)
signal hint_shown(text: String)
signal mission_finished(summary: Dictionary)

var data: Dictionary = {}
var mission_id := ""
var node_id := ""
var vars := {"bread": "roggen", "rolls": 0}
var done_objectives: Array = []
var stats := {"answers": 0, "first_try_correct": 0, "hints": 0, "errors": [], "steps": []}
var finished := false
var active := false
var _tries_on_node := 0
var _rx_cache := {}


func load_mission(path: String) -> bool:
	var txt := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Cannot parse mission " + path)
		return false
	data = parsed
	mission_id = data.id
	return true


func reset() -> void:
	node_id = data.start
	vars = {"bread": "roggen", "rolls": 0}
	done_objectives = []
	stats = {"answers": 0, "first_try_correct": 0, "hints": 0, "errors": [], "steps": []}
	finished = false
	active = false
	_tries_on_node = 0


func restore_checkpoint() -> bool:
	var rec: Dictionary = GameState.mission_record(mission_id)
	var cp: Dictionary = rec.get("checkpoint", {})
	if cp.is_empty() or rec.get("completed", false) and cp.get("node", "") == "":
		return false
	if not data.nodes.has(cp.get("node", "")):
		return false
	node_id = cp.node
	vars = cp.get("vars", vars)
	done_objectives = cp.get("objectives", [])
	stats = cp.get("stats", stats)
	return true


func has_checkpoint() -> bool:
	var cp: Dictionary = GameState.mission_record(mission_id).get("checkpoint", {})
	return not cp.is_empty()


func save_checkpoint() -> void:
	var rec := GameState.mission_record(mission_id)
	rec.checkpoint = {"node": node_id, "vars": vars, "objectives": done_objectives, "stats": stats}
	GameState.save_game()


# ------------------------------------------------------------- objectives
func complete_objective(obj_id: String) -> void:
	if obj_id in done_objectives:
		return
	done_objectives.append(obj_id)
	objective_completed.emit(obj_id)


func _complete_up_to(obj_id: String) -> void:
	## Marks every objective listed before obj_id as done (useful when a free
	## answer skips a step, e.g. greeting + naming the bread at once).
	for o in data.objectives:
		if o.id == obj_id:
			return
		complete_objective(o.id)


# --------------------------------------------------------------- dialogue
func begin_dialogue() -> void:
	if finished:
		return
	active = true
	_present(node_id, false)


func current_node() -> Dictionary:
	return data.nodes.get(node_id, {})


func line_text(line_id: String) -> Dictionary:
	return data.lines.get(line_id, {})


func _resolve_line(template: String) -> String:
	return template.format({"bread": vars.bread, "rolls": str(int(vars.rolls))})


func _present(id: String, retry: bool) -> void:
	node_id = id
	var node := current_node()
	_complete_up_to(node.get("objective", ""))
	var line_id := _resolve_line(node.retry_line if retry and node.has("retry_line") else node.line)
	npc_line.emit(line_id, line_text(line_id))
	if retry and node.get("type", "") == "pay":
		# after "das stimmt nicht ganz", repeat the price itself
		var price_line := _resolve_line(node.line)
		npc_line.emit(price_line, line_text(price_line))
	if node.get("type", "") == "pay":
		choices_ready.emit(node_id, pay_options(), "pay")
	else:
		var opts: Array = []
		for o in node.get("options", []):
			opts.append(o.de)
		choices_ready.emit(node_id, opts, "say")


func request_hint() -> String:
	var h := I18n.pick(current_node().get("hint", {}))
	if h != "":
		stats.hints += 1
		hint_shown.emit(h)
	return h


# ----------------------------------------------------------------- paying
func total_cents() -> int:
	var p: Dictionary = data.prices
	return int(round((float(p[vars.bread]) + float(p.broetchen) * int(vars.rolls)) * 100.0))


static func format_eur(cents: int) -> String:
	return "%d,%02d €" % [cents / 100, cents % 100]


func pay_options() -> Array:
	## Correct total plus "listening traps": swapped digits, the other
	## euro amount, and a tens confusion (vierzig / vierzehn style).
	var c := total_cents()
	var e := c / 100
	var ct := c % 100
	var cand := [c]
	var swapped := (ct / 10) * 100 + e * 10 + ct % 10    # 3,40 -> 4,30
	cand.append(swapped)
	cand.append((5 - e) * 100 + ct)                      # 2 <-> 3 euros
	cand.append(e * 100 + (ct / 10 + 1) % 10 * 10)       # wrong tens of cents
	var out: Array = []
	for v in cand:
		if v > 0 and v != c and not out.has(format_eur(v)) and out.size() < 3:
			out.append(format_eur(v))
	while out.size() < 3:
		out.append(format_eur(c + 100 * (out.size() + 1)))
	out.append(format_eur(c))
	out.shuffle()
	return out


# ------------------------------------------------------------- evaluation
func choose_option(index: int) -> void:
	var node := current_node()
	if node.get("type", "") == "pay":
		return
	var opts: Array = node.get("options", [])
	if index < 0 or index >= opts.size():
		return
	var o: Dictionary = opts[index]
	_apply(o, o.de)


func choose_payment(label: String) -> void:
	var node := current_node()
	var ok := label == format_eur(total_cents())
	var fb := ""
	if ok:
		fb = {"fr": "Exact : %s.", "en": "Right: %s."}[I18n.lang()] % format_eur(total_cents())
		_apply({"result": "correct", "next": node.next}, label, fb)
	else:
		var hint := I18n.pick(node.get("hint", {}))
		_apply({"result": "wrong", "error": node.get("error", {})}, label, hint)


func submit_free(text: String) -> void:
	var node := current_node()
	var norm := normalize(text)
	if norm.is_empty():
		return
	if node.get("type", "") == "pay":
		var digits := norm.replace(" euro", "").replace("eur", "").strip_edges()
		var cents := _parse_amount(digits)
		if cents >= 0:
			choose_payment(format_eur(cents))
			return
	for rule in node.get("free", {}).get("rules", []):
		if _rule_matches(rule, norm):
			var merged: Dictionary = {}
			if rule.has("ref"):
				merged = node.options[int(rule.ref)].duplicate(true)
			if rule.has("feedback_ref"):
				merged.feedback = node.options[int(rule.feedback_ref)].feedback
			for k in rule:
				if k not in ["all", "ref", "feedback_ref"]:
					merged[k] = rule[k]
			_apply(merged, text)
			return
	# nothing recognised: the shop assistant asks again, no error logged
	stats.answers += 1
	_tries_on_node += 1
	answer_evaluated.emit("unknown", I18n.t("not_understood"), "", text)
	var retry := _resolve_line(node.get("retry_line", node.line))
	npc_line.emit(retry, line_text(retry))


func _rule_matches(rule: Dictionary, norm: String) -> bool:
	for pat in rule.get("all", []):
		if not _rx(pat).search(norm):
			return false
	return true


func _rx(pat: String) -> RegEx:
	if not _rx_cache.has(pat):
		var r := RegEx.new()
		r.compile("\\b(?:" + pat + ")\\b")
		_rx_cache[pat] = r
	return _rx_cache[pat]


static func normalize(s: String) -> String:
	## Lower-case, fold umlauts/ß (so "Brotchen", "Broetchen" and "Brötchen"
	## all match), drop punctuation and squeeze spaces.
	var t := s.to_lower()
	for pair in [["ä", "ae"], ["ö", "oe"], ["ü", "ue"], ["ß", "ss"]]:
		t = t.replace(pair[0], pair[1])
	var out := ""
	for ch in t:
		out += ch if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") or ch == " " or ch == "," or ch == "." else " "
	out = out.replace(",", " , ").replace(".", " . ")
	while out.find("  ") >= 0:
		out = out.replace("  ", " ")
	# "broetchen" typed as "brotchen" (no umlaut key) is folded too
	out = out.replace("brotchen", "broetchen").replace("weisbrot", "weissbrot")
	return out.replace(" , ", " ").replace(" . ", " ").strip_edges()


func _parse_amount(s: String) -> int:
	var rx := RegEx.new()
	rx.compile("^(\\d+)(?:[ ,.](\\d{1,2}))?$")
	var m := rx.search(s.strip_edges())
	if m == null:
		return -1
	var euros := int(m.get_string(1))
	var cents := 0
	if m.get_string(2) != "":
		cents = int(m.get_string(2)) * (10 if m.get_string(2).length() == 1 else 1)
	return euros * 100 + cents


func _apply(o: Dictionary, answer: String, fb_override := "") -> void:
	var result: String = o.get("result", "wrong")
	stats.answers += 1
	if not stats.steps.has(node_id):
		stats.steps.append(node_id)
		if result == "correct" and _tries_on_node == 0:
			stats.first_try_correct += 1
	_tries_on_node += 1
	var fb := fb_override if fb_override != "" else I18n.pick(o.get("feedback", {}))
	if o.has("error") and result != "correct":
		var err: Dictionary = o.error
		var entry := {"mission": mission_id, "node": node_id, "cat": err.get("cat", "other"),
			"label": I18n.pick(err.get("label", {})), "given": answer, "explanation": fb}
		stats.errors.append(entry)
		GameState.log_error(entry.duplicate())
	for k in o.get("set", {}):
		vars[k] = o.set[k]
	answer_evaluated.emit(result, fb, o.get("model", ""), answer)
	if o.has("next") and result != "wrong":
		_advance(o.next)
	else:
		var node := current_node()
		var retry := _resolve_line(node.get("retry_line", node.line))
		npc_line.emit(retry, line_text(retry))
		if node.get("type", "") == "pay":
			var price_line := _resolve_line(node.line)
			npc_line.emit(price_line, line_text(price_line))
			choices_ready.emit(node_id, pay_options(), "pay")


func _advance(next_id: String) -> void:
	complete_objective(current_node().get("objective", ""))
	_tries_on_node = 0
	if next_id == "end":
		_finish()
		return
	node_id = next_id
	save_checkpoint()
	_present(next_id, false)


func _finish() -> void:
	finished = true
	active = false
	for o in data.objectives:
		complete_objective(o.id)
	var score := 0
	if stats.steps.size() > 0:
		score = int(round(100.0 * stats.first_try_correct / stats.steps.size()))
	var rec := GameState.mission_record(mission_id)
	rec.completed = true
	rec.attempts = int(rec.get("attempts", 0)) + 1
	rec.best_score = max(int(rec.get("best_score", 0)), score)
	rec.checkpoint = {}
	for v in data.get("vocabulary", []):
		GameState.add_vocab(v)
	GameState.save_game()
	npc_line.emit("s_closing", line_text("s_closing"))
	mission_finished.emit({"score": score, "hints": stats.hints, "errors": stats.errors,
		"vocabulary": data.get("vocabulary", []), "grammar": data.get("grammar", []),
		"best": rec.best_score, "attempts": rec.attempts})
