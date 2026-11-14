extends Node
## Background soundscape and mixing rules:
##  - street ambience + crowd murmur (Ambience bus), café music (Music bus);
##  - three immersion presets (easy / normal / dense);
##  - ducking: ambience and music dip while a pedagogical voice is playing,
##    so dialogues always stay intelligible;
##  - inside the bakery the street is muffled.

var city: AudioStreamPlayer
var crowd: AudioStreamPlayer
var _amp_ambience: AudioEffectAmplify
var _amp_music: AudioEffectAmplify
var _duck_db := 0.0
var _target_duck := 0.0
var _inside := false
var preset := "normal"

const PRESETS := {
	"easy": {"city": -16.0, "crowd": -80.0, "cars": 1, "horn": 0.0},
	"normal": {"city": -7.0, "crowd": -14.0, "cars": 3, "horn": 0.12},
	"dense": {"city": -2.0, "crowd": -6.0, "cars": 6, "horn": 0.35},
}


func _ready() -> void:
	city = _bg("city_ambience_loop")
	crowd = _bg("crowd_murmur_loop")
	_amp_ambience = _amp_on("Ambience")
	_amp_music = _amp_on("Music")


func _bg(file: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = load("res://assets/audio/sfx/%s.wav" % file)
	p.bus = "Ambience"
	add_child(p)
	p.play()
	return p


func _amp_on(bus_name: String) -> AudioEffectAmplify:
	var idx := AudioServer.get_bus_index(bus_name)
	var amp := AudioEffectAmplify.new()
	AudioServer.add_bus_effect(idx, amp)
	return amp


func apply_preset(name: String) -> Dictionary:
	preset = name if PRESETS.has(name) else "normal"
	_refresh()
	return PRESETS[preset]


func set_inside(v: bool) -> void:
	_inside = v
	_refresh()


func duck(on: bool) -> void:
	_target_duck = -9.0 if on else 0.0


func _refresh() -> void:
	var p: Dictionary = PRESETS[preset]
	var muffle := -12.0 if _inside else 0.0
	city.volume_db = p.city + muffle
	crowd.volume_db = p.crowd + muffle


func _process(delta: float) -> void:
	_duck_db = move_toward(_duck_db, _target_duck, delta * 30.0)
	_amp_ambience.volume_db = _duck_db
	_amp_music.volume_db = _duck_db
