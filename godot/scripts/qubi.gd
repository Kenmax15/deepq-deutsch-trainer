class_name Qubi
extends Control
## Qubi, the mascot: a little Bloch sphere with a face and a state-vector
## antenna. Drawn in code so it scales cleanly; expressions: happy, think,
## cheer, oops. Gently bobs and blinks.

var mood := "happy"
var _t := 0.0
var _blink := 0.0
var _jump := 0.0

const BODY := Color(0.37, 0.83, 0.72)
const INK := Color(0.06, 0.1, 0.17)
const GOLD := Color(0.97, 0.79, 0.27)


func _ready() -> void:
	custom_minimum_size = Vector2(110, 120)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_mood(m: String) -> void:
	mood = m
	if m == "cheer":
		_jump = 0.6


func _process(delta: float) -> void:
	_t += delta
	_jump = max(0.0, _jump - delta)
	_blink -= delta
	if _blink < -3.5:
		_blink = 0.12
	queue_redraw()


func _draw() -> void:
	var r: float = min(size.x, size.y - 20) * 0.38
	var c := Vector2(size.x / 2, size.y / 2 + 8)
	c.y += sin(_t * 2.2) * 3.0 - sin(_jump / 0.6 * PI) * 16.0
	# antenna = state vector pointing to |ψ⟩
	var tip := c + Vector2(sin(_t * 0.9) * r * 0.35, -r * 1.45)
	draw_line(c + Vector2(0, -r * 0.9), tip, BODY, 4.0, true)
	draw_circle(tip, 6.0, GOLD)
	# body
	draw_circle(c + Vector2(0, 4), r, BODY.darkened(0.25))
	draw_circle(c, r, BODY)
	# equator of the Bloch sphere
	var pts := PackedVector2Array()
	for i in range(33):
		var a := TAU * i / 32.0
		pts.append(c + Vector2(cos(a) * r, sin(a) * r * 0.28 + r * 0.05))
	draw_polyline(pts, INK.lerp(BODY, 0.6), 2.0, true)
	# eyes
	var eye_y := c.y - r * 0.18
	for sx in [-1, 1]:
		var e := Vector2(c.x + sx * r * 0.34, eye_y)
		if _blink > 0.0:
			draw_line(e - Vector2(7, 0), e + Vector2(7, 0), INK, 3.0, true)
		elif mood == "oops":
			draw_line(e - Vector2(6, 6), e + Vector2(6, 6), INK, 3.0, true)
			draw_line(e - Vector2(6, -6), e + Vector2(6, -6), INK, 3.0, true)
		else:
			draw_circle(e, r * 0.14, INK)
			draw_circle(e + Vector2(-2, -3), r * 0.05, Color.WHITE)
	# mouth
	var m := Vector2(c.x, c.y + r * 0.3)
	match mood:
		"cheer":
			draw_circle(m, r * 0.2, INK)
			draw_circle(m + Vector2(0, r * 0.08), r * 0.1, Color(0.95, 0.45, 0.45))
		"oops":
			draw_arc(m + Vector2(0, r * 0.15), r * 0.22, PI * 1.15, PI * 1.85, 12, INK, 3.0, true)
		"think":
			draw_line(m - Vector2(r * 0.18, 0), m + Vector2(r * 0.18, -4), INK, 3.0, true)
		_:
			draw_arc(m - Vector2(0, r * 0.1), r * 0.28, PI * 0.15, PI * 0.85, 12, INK, 3.0, true)
