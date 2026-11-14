extends CanvasLayer
## All 2D interface, built in code: start screen, objectives, interaction
## prompt, subtitles + dialogue answers, Qubi, feedback, settings, summary.
## The HUD only emits intentions; main.gd decides what happens.

signal start_pressed(resume: bool)
signal option_chosen(index: int)
signal payment_chosen(label: String)
signal free_submitted(text: String)
signal replay_requested(slow: bool)
signal hint_requested
signal model_requested(line_id: String)
signal replay_mission_requested
signal settings_closed

const C_BG := Color(0.07, 0.09, 0.14, 0.86)
const C_PANEL := Color(0.1, 0.13, 0.2, 0.93)
const C_ACCENT := Color(0.37, 0.83, 0.72)
const C_TEXT := Color(0.95, 0.96, 0.95)
const C_MUTED := Color(0.7, 0.74, 0.8)
const C_OK := Color(0.36, 0.78, 0.45)
const C_PART := Color(0.95, 0.7, 0.25)
const C_BAD := Color(0.92, 0.38, 0.35)

var theme_ui: Theme
var root: Control
var start_panel: PanelContainer
var objectives_box: VBoxContainer
var objectives_title: Label
var prompt: Label
var dialogue: PanelContainer
var speaker_lbl: Label
var german_lbl: RichTextLabel
var trans_lbl: Label
var tools_row: HBoxContainer
var options_box: VBoxContainer
var guided_btn: Button
var free_row: HBoxContainer
var free_edit: LineEdit
var feedback: PanelContainer
var feedback_lbl: RichTextLabel
var model_btn: Button
var qubi: Qubi
var qubi_bubble: PanelContainer
var qubi_lbl: Label
var settings_panel: PanelContainer
var result_panel: PanelContainer
var toast: Label

var _model_line := ""
var _show_trans := true
var _current_trans := ""
var _kind := "say"
var _options: Array = []
var _objective_labels := {}
var _mission: Dictionary = {}


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme_ui = _make_theme()
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = theme_ui
	add_child(root)
	_build_objectives()
	_build_prompt()
	_build_dialogue()
	_build_feedback()
	_build_qubi()
	_build_toast()
	var gear := Button.new()
	gear.text = I18n.t("settings") + "  (Esc)"
	gear.custom_minimum_size = Vector2(0, 46)
	gear.anchor_left = 1.0
	gear.anchor_right = 1.0
	gear.offset_right = -16
	gear.offset_top = 16
	gear.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	gear.pressed.connect(func(): show_settings(true))
	root.add_child(gear)


# ------------------------------------------------------------------ theme
func _style(c: Color, radius := 14, pad := 14, border := Color.TRANSPARENT) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(pad)
	if border.a > 0:
		s.set_border_width_all(2)
		s.border_color = border
	return s


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 19
	t.set_stylebox("panel", "PanelContainer", _style(C_PANEL))
	t.set_color("font_color", "Label", C_TEXT)
	t.set_stylebox("normal", "Button", _style(Color(0.17, 0.21, 0.31), 10, 10))
	t.set_stylebox("hover", "Button", _style(Color(0.22, 0.28, 0.4), 10, 10, C_ACCENT))
	t.set_stylebox("pressed", "Button", _style(Color(0.13, 0.4, 0.36), 10, 10, C_ACCENT))
	t.set_stylebox("focus", "Button", _style(Color(0.22, 0.28, 0.4), 10, 10, C_ACCENT))
	t.set_stylebox("disabled", "Button", _style(Color(0.13, 0.15, 0.2), 10, 10))
	t.set_color("font_color", "Button", C_TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_stylebox("normal", "LineEdit", _style(Color(0.05, 0.07, 0.11), 10, 10, Color(0.3, 0.36, 0.5)))
	t.set_stylebox("focus", "LineEdit", _style(Color(0.05, 0.07, 0.11), 10, 10, C_ACCENT))
	t.set_color("font_color", "LineEdit", C_TEXT)
	t.set_color("default_color", "RichTextLabel", C_TEXT)
	return t


func _center(c: Control) -> void:
	c.anchor_left = 0.5
	c.anchor_right = 0.5
	c.anchor_top = 0.5
	c.anchor_bottom = 0.5
	c.offset_left = 0
	c.offset_right = 0
	c.offset_top = 0
	c.offset_bottom = 0
	c.grow_horizontal = Control.GROW_DIRECTION_BOTH
	c.grow_vertical = Control.GROW_DIRECTION_BOTH


func _label(text: String, size := 19, color := C_TEXT, wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _button(text: String, cb: Callable, min_w := 0) -> Button:
	var b := Button.new()
	b.text = text
	if min_w > 0:
		b.custom_minimum_size.x = min_w
	b.pressed.connect(cb)
	return b


# ------------------------------------------------------------- objectives
func _build_objectives() -> void:
	var p := PanelContainer.new()
	p.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 16)
	p.custom_minimum_size = Vector2(360, 0)
	root.add_child(p)
	objectives_box = VBoxContainer.new()
	objectives_box.add_theme_constant_override("separation", 4)
	p.add_child(objectives_box)
	objectives_title = _label("", 21, C_ACCENT)
	objectives_box.add_child(objectives_title)


func set_mission(m: Dictionary, done: Array) -> void:
	_mission = m
	for c in objectives_box.get_children():
		if c != objectives_title:
			c.queue_free()
	_objective_labels.clear()
	objectives_title.text = "%s · %s (%s)" % [I18n.t("objectives"), I18n.pick(m.title), m.title.de]
	for o in m.objectives:
		var l := _label("", 17, C_MUTED, true)
		l.custom_minimum_size.x = 330
		objectives_box.add_child(l)
		_objective_labels[o.id] = [l, I18n.pick(o)]
		mark_objective(o.id, o.id in done)


func mark_objective(id: String, done := true) -> void:
	if not _objective_labels.has(id):
		return
	var l: Label = _objective_labels[id][0]
	l.text = ("✔  " if done else "○  ") + _objective_labels[id][1]
	l.add_theme_color_override("font_color", C_OK if done else C_MUTED)


# ----------------------------------------------------------------- prompt
func _build_prompt() -> void:
	prompt = _label("", 22)
	prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	prompt.add_theme_constant_override("outline_size", 8)
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 0)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.position.y -= 60
	prompt.visible = false
	root.add_child(prompt)


func show_prompt(text: String) -> void:
	prompt.text = "[E]  " + text if text != "" else ""
	prompt.visible = text != ""
	prompt.reset_size()
	prompt.position.x = (root.size.x - prompt.size.x) / 2.0
	prompt.position.y = root.size.y - 90


# --------------------------------------------------------------- dialogue
func _build_dialogue() -> void:
	dialogue = PanelContainer.new()
	dialogue.anchor_left = 0.5
	dialogue.anchor_right = 0.5
	dialogue.anchor_top = 1.0
	dialogue.anchor_bottom = 1.0
	dialogue.offset_left = -380      # shifted right so Qubi (centre-left) never covers it
	dialogue.offset_right = 540
	dialogue.offset_bottom = -18
	dialogue.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dialogue.visible = false
	root.add_child(dialogue)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	dialogue.add_child(v)
	speaker_lbl = _label("", 16, C_ACCENT)
	v.add_child(speaker_lbl)
	german_lbl = RichTextLabel.new()
	german_lbl.bbcode_enabled = true
	german_lbl.fit_content = true
	german_lbl.scroll_active = false
	german_lbl.add_theme_font_size_override("normal_font_size", 27)
	german_lbl.add_theme_font_size_override("bold_font_size", 27)
	v.add_child(german_lbl)
	trans_lbl = _label("", 17, C_MUTED, true)
	v.add_child(trans_lbl)

	tools_row = HBoxContainer.new()
	tools_row.add_theme_constant_override("separation", 8)
	v.add_child(tools_row)
	tools_row.add_child(_button(I18n.t("replay"), func(): replay_requested.emit(false)))
	tools_row.add_child(_button(I18n.t("slow"), func(): replay_requested.emit(true)))
	tools_row.add_child(_button(I18n.t("hint"), func(): hint_requested.emit()))
	tools_row.add_child(_button(I18n.t("translate"), _toggle_translation))

	v.add_child(HSeparator.new())
	options_box = VBoxContainer.new()
	options_box.add_theme_constant_override("separation", 6)
	v.add_child(options_box)
	guided_btn = _button(I18n.t("guided"), func():
		options_box.visible = true
		guided_btn.visible = false)
	v.add_child(guided_btn)
	free_row = HBoxContainer.new()
	free_row.add_theme_constant_override("separation", 8)
	v.add_child(free_row)
	free_edit = LineEdit.new()
	free_edit.placeholder_text = I18n.t("your_answer")
	free_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	free_edit.text_submitted.connect(func(_t): _send_free())
	free_row.add_child(free_edit)
	free_row.add_child(_button(I18n.t("send"), _send_free))
	# Characters missing on many keyboards
	for ch in ["ä", "ö", "ü", "ß"]:
		var b := _button(ch, func():
			free_edit.insert_text_at_caret(ch)
			free_edit.grab_focus())
		b.custom_minimum_size.x = 38
		free_row.add_child(b)


func _send_free() -> void:
	var t := free_edit.text.strip_edges()
	if t == "":
		return
	free_edit.text = ""
	free_submitted.emit(t)


func _toggle_translation() -> void:
	_show_trans = not _show_trans
	trans_lbl.text = _current_trans if _show_trans else ""
	trans_lbl.visible = _show_trans and _current_trans != ""


func show_line(speaker: String, german: String, translation: String) -> void:
	dialogue.visible = true
	speaker_lbl.text = speaker
	var subs: bool = GameState.get_setting("subtitles")
	german_lbl.text = german if subs else "( … )"
	_current_trans = translation
	trans_lbl.text = translation if _show_trans else ""
	trans_lbl.visible = _show_trans and translation != ""


func reset_translation_default() -> void:
	_show_trans = GameState.get_setting("translation") and GameState.get_setting("mode") != "real"


func show_answers(options: Array, kind: String) -> void:
	_kind = kind
	_options = options
	for c in options_box.get_children():
		c.queue_free()
	if kind == "pay":
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		var q := _label(I18n.t("how_much"), 18, C_MUTED)
		options_box.add_child(q)
		for o in options:
			var b := _button(o, func(): payment_chosen.emit(o), 120)
			hb.add_child(b)
		options_box.add_child(hb)
	else:
		var letters := ["A", "B", "C", "D", "E"]
		for i in range(options.size()):
			var b := _button("%s   %s" % [letters[i], options[i]], func(): option_chosen.emit(i))
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			options_box.add_child(b)
	var real: bool = GameState.get_setting("mode") == "real"
	options_box.visible = not real or kind == "pay"
	guided_btn.visible = real and kind != "pay"
	free_row.visible = true
	tools_row.visible = true
	if real:
		free_edit.grab_focus()


func hide_answers() -> void:
	for c in options_box.get_children():
		c.queue_free()
	guided_btn.visible = false
	free_row.visible = false


func end_dialogue_ui() -> void:
	hide_answers()
	tools_row.visible = false


func hide_dialogue() -> void:
	dialogue.visible = false


# --------------------------------------------------------------- feedback
func _build_feedback() -> void:
	feedback = PanelContainer.new()
	feedback.anchor_left = 0.5
	feedback.anchor_right = 0.5
	feedback.offset_left = -420
	feedback.offset_right = 420
	feedback.offset_top = 90
	feedback.visible = false
	root.add_child(feedback)
	var v := VBoxContainer.new()
	feedback.add_child(v)
	feedback_lbl = RichTextLabel.new()
	feedback_lbl.bbcode_enabled = true
	feedback_lbl.fit_content = true
	feedback_lbl.scroll_active = false
	v.add_child(feedback_lbl)
	model_btn = _button(I18n.t("hear_model"), func(): model_requested.emit(_model_line))
	model_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(model_btn)


func show_feedback(result: String, text: String, answer: String, model_line: String) -> void:
	var col: Color = {"correct": C_OK, "partial": C_PART, "wrong": C_BAD}.get(result, C_PART)
	var head := I18n.t(result) if result in ["correct", "partial", "wrong"] else "?"
	feedback.add_theme_stylebox_override("panel", _style(Color(0.08, 0.1, 0.15, 0.95), 14, 14, col))
	feedback_lbl.text = "[b][color=#%s]%s[/color][/b]   [color=#b4bccc]%s : « %s »[/color]\n%s" % [
		col.to_html(false), head, I18n.t("you_said"), answer, text]
	_model_line = model_line
	model_btn.visible = model_line != "" and result != "correct"
	feedback.visible = true
	var tw := create_tween()
	tw.tween_interval(6.0 if result != "correct" else 3.5)
	tw.tween_callback(func(): feedback.visible = false)


# ------------------------------------------------------------------- Qubi
func _build_qubi() -> void:
	var box := HBoxContainer.new()
	box.anchor_top = 0.42
	box.anchor_bottom = 0.42
	box.offset_left = 16
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)
	qubi = Qubi.new()
	box.add_child(qubi)
	qubi_bubble = PanelContainer.new()
	qubi_bubble.add_theme_stylebox_override("panel", _style(Color(0.97, 0.97, 0.94, 0.96), 16, 12))
	qubi_bubble.custom_minimum_size.x = 280
	qubi_bubble.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	box.add_child(qubi_bubble)
	qubi_lbl = _label("", 16, Color(0.1, 0.12, 0.18), true)
	qubi_lbl.custom_minimum_size.x = 260
	qubi_bubble.add_child(qubi_lbl)
	qubi_bubble.visible = false


func qubi_say(text: String, mood := "happy", seconds := 7.0) -> void:
	qubi.set_mood(mood)
	qubi_lbl.text = text
	qubi_bubble.visible = true
	var tw := create_tween()
	tw.tween_interval(seconds)
	tw.tween_callback(func():
		if qubi_lbl.text == text:
			qubi_bubble.visible = false
			qubi.set_mood("happy"))


func set_qubi_visible(v: bool) -> void:
	qubi.get_parent().visible = v


# ------------------------------------------------------------------ toast
func _build_toast() -> void:
	toast = _label("", 18)
	toast.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	toast.add_theme_constant_override("outline_size", 6)
	toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 24)
	toast.visible = false
	root.add_child(toast)


func show_toast(text: String) -> void:
	toast.text = text
	toast.visible = true
	toast.reset_size()
	toast.position.x = (root.size.x - toast.size.x) / 2.0
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.tween_callback(func(): toast.visible = false)


# ------------------------------------------------------------ start screen
func show_start(mission: Dictionary, can_resume: bool) -> void:
	if start_panel:
		start_panel.queue_free()
	start_panel = PanelContainer.new()
	start_panel.add_theme_stylebox_override("panel", _style(Color(0.06, 0.08, 0.13, 0.94), 22, 30, C_ACCENT))
	_center(start_panel)
	start_panel.custom_minimum_size = Vector2(760, 0)
	root.add_child(start_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	start_panel.add_child(v)
	var head := HBoxContainer.new()
	var q := Qubi.new()
	head.add_child(q)
	var tv := VBoxContainer.new()
	tv.add_child(_label(I18n.t("app_title"), 36, C_TEXT))
	tv.add_child(_label(I18n.t("app_sub"), 18, C_ACCENT))
	head.add_child(tv)
	v.add_child(head)
	v.add_child(_label("%s — %s  ·  %s" % [mission.title.de, I18n.pick(mission.title), mission.level], 24, C_TEXT))
	v.add_child(_label(I18n.pick(mission.goal), 18, C_MUTED, true))

	v.add_child(_label(I18n.t("mode"), 17, C_ACCENT))
	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 10)
	v.add_child(modes)
	var mode_desc := _label("", 16, C_MUTED, true)
	var group := ButtonGroup.new()
	for m in ["learning", "mission", "real"]:
		var b := Button.new()
		b.text = I18n.t("mode_" + m)
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = GameState.get_setting("mode") == m
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func():
			GameState.set_setting("mode", m)
			mode_desc.text = I18n.t("mode_" + m + "_d"))
		modes.add_child(b)
	mode_desc.text = I18n.t("mode_" + GameState.get_setting("mode") + "_d")
	v.add_child(mode_desc)

	var langs := HBoxContainer.new()
	langs.add_child(_label(I18n.t("ui_lang") + " :  ", 16, C_MUTED))
	for l in [["fr", "Français"], ["en", "English"]]:
		langs.add_child(_button(l[1], func():
			GameState.set_setting("ui_lang", l[0])
			rebuild_requested()))
	v.add_child(langs)

	v.add_child(_label(I18n.t("controls"), 15, C_MUTED, true))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_END
	if can_resume:
		row.add_child(_button(I18n.t("restart"), func(): _start(false), 200))
		var r := _button(I18n.t("resume"), func(): _start(true), 240)
		row.add_child(r)
	else:
		row.add_child(_button(I18n.t("start"), func(): _start(false), 280))
	v.add_child(row)


func _start(resume: bool) -> void:
	start_panel.queue_free()
	start_panel = null
	start_pressed.emit(resume)


## Rebuilding the whole HUD is the simplest way to switch UI language.
func rebuild_requested() -> void:
	var main := get_parent()
	if main and main.has_method("rebuild_hud"):
		main.rebuild_hud()


# --------------------------------------------------------------- settings
func show_settings(open: bool) -> void:
	if settings_panel:
		settings_panel.queue_free()
		settings_panel = null
	if not open:
		get_tree().paused = false
		settings_closed.emit()
		return
	get_tree().paused = true
	settings_panel = PanelContainer.new()
	settings_panel.add_theme_stylebox_override("panel", _style(Color(0.06, 0.08, 0.13, 0.97), 20, 26, C_ACCENT))
	_center(settings_panel)
	settings_panel.custom_minimum_size = Vector2(640, 0)
	root.add_child(settings_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	settings_panel.add_child(v)
	v.add_child(_label(I18n.t("settings"), 28, C_TEXT))
	v.add_child(_label(I18n.t("audio"), 17, C_ACCENT))
	for key in ["vol_master", "vol_voice", "vol_sfx", "vol_ambience", "vol_music"]:
		var row := HBoxContainer.new()
		var l := _label(I18n.t(key), 17)
		l.custom_minimum_size.x = 200
		row.add_child(l)
		var s := HSlider.new()
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.05
		s.value = GameState.get_setting(key)
		s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		s.value_changed.connect(func(val): GameState.set_setting(key, val))
		row.add_child(s)
		v.add_child(row)
	v.add_child(_choice_row("immersion", ["easy", "normal", "dense"], ["imm_easy", "imm_normal", "imm_dense"]))
	v.add_child(_choice_row("mode", ["learning", "mission", "real"], ["mode_learning", "mode_mission", "mode_real"]))
	v.add_child(_choice_row("quality", ["low", "medium", "high"], ["q_low", "q_medium", "q_high"]))
	v.add_child(_choice_row("ui_lang", ["fr", "en"], ["", ""], ["Français", "English"]))
	for key in ["subtitles", "translation"]:
		var cb := CheckBox.new()
		cb.text = I18n.t(key)
		cb.button_pressed = GameState.get_setting(key)
		cb.toggled.connect(func(on): GameState.set_setting(key, on))
		v.add_child(cb)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 10)
	row2.add_child(_button(I18n.t("save"), _on_save))
	row2.add_child(_button(I18n.t("reset"), _on_reset))
	row2.add_child(_button(I18n.t("quit"), _on_quit))
	var back := _button(I18n.t("back"), func(): show_settings(false), 240)
	row2.add_child(back)
	v.add_child(row2)


func _on_save() -> void:
	GameState.save_game()
	show_toast(I18n.t("saved"))


func _on_reset() -> void:
	GameState.reset_progress()
	show_toast("✔")


func _on_quit() -> void:
	GameState.save_game()
	get_tree().quit()


func _choice_row(key: String, values: Array, label_keys: Array, raw_labels: Array = []) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var l := _label(I18n.t(key), 17)
	l.custom_minimum_size.x = 200
	row.add_child(l)
	var group := ButtonGroup.new()
	for i in range(values.size()):
		var b := Button.new()
		b.text = raw_labels[i] if raw_labels.size() > i else I18n.t(label_keys[i])
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = GameState.get_setting(key) == values[i]
		var val = values[i]
		b.pressed.connect(func():
			GameState.set_setting(key, val)
			if key == "ui_lang":
				rebuild_requested())
		row.add_child(b)
	return row


# ---------------------------------------------------------------- results
func show_results(s: Dictionary) -> void:
	if result_panel:
		result_panel.queue_free()
	result_panel = PanelContainer.new()
	result_panel.add_theme_stylebox_override("panel", _style(Color(0.06, 0.08, 0.13, 0.96), 22, 28, C_OK))
	_center(result_panel)
	result_panel.custom_minimum_size = Vector2(820, 0)
	root.add_child(result_panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(800, 600)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	result_panel.add_child(scroll)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 10)
	scroll.add_child(v)
	var stars := "★★★" if s.score >= 85 else ("★★☆" if s.score >= 50 else "★☆☆")
	v.add_child(_label(I18n.t("result_title") + "   " + stars, 30, C_TEXT))
	v.add_child(_label("%s : %d %%   ·   %s : %d" % [I18n.t("score"), s.score, I18n.t("hints_used"), s.hints], 19, C_ACCENT))
	v.add_child(_label(I18n.t("errors"), 20, C_PART))
	if s.errors.is_empty():
		v.add_child(_label(I18n.t("no_errors"), 17, C_OK))
	for e in s.errors:
		v.add_child(_label("• [%s] « %s » — %s" % [e.label, e.given, e.explanation], 16, C_TEXT, true))
	v.add_child(_label(I18n.t("vocab"), 20, C_ACCENT))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 30)
	for w in s.vocabulary:
		grid.add_child(_label(w.de + ((" (Pl. " + w.pl.replace("die ", "") + ")") if w.has("pl") else ""), 16, C_TEXT))
		grid.add_child(_label(I18n.pick(w), 16, C_MUTED))
	v.add_child(grid)
	v.add_child(_label(I18n.t("grammar"), 20, C_ACCENT))
	for g in s.grammar:
		v.add_child(_label("• " + I18n.pick(g), 16, C_TEXT, true))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 12)
	row.add_child(_button(I18n.t("explore"), _close_results, 220))
	row.add_child(_button(I18n.t("replay_mission"), _replay_from_results, 240))
	v.add_child(row)


func _close_results() -> void:
	if result_panel:
		result_panel.queue_free()
		result_panel = null


func _replay_from_results() -> void:
	_close_results()
	replay_mission_requested.emit()
