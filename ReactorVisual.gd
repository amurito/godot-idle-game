extends Node2D

@onready var label = $ReactorLabel
@onready var core = $Core
@onready var ring = $Ring
@onready var particles = $Particles

var activity := 0.0
var target_activity := 0.0
var saturation := 0.0

var base_scale := 1.0

var max_display_power := 100.0
var current_power := 0.0

func set_power(p):
	current_power = p

func _ready():
	var parent = get_parent()
	if parent is Control:
		position = parent.size * 0.5
		var base = min(parent.size.x, parent.size.y)
		base_scale = base / 200.0
		scale = Vector2.ONE * base_scale
		
func get_norm_power() -> float:
	# Log-scale: 0 → 1 → 10 → 100 → 1000 produce crecimiento visible
	return log(current_power + 1.0) / log(max_display_power + 1.0)
	
func _process(delta):
	# Normalización 0 → 1
	var norm = get_norm_power()

	# crecimiento estructural
	var size_growth = lerp(0.9, 2.6, pow(norm, 0.7))
	scale = Vector2.ONE * base_scale * size_growth
	if norm > 1.0:
		saturation = min(1.0, saturation + (norm - 1.0) * 0.02)

	target_activity = norm
	saturation = max(saturation, pow(norm, 2.5))

	activity = lerp(activity, target_activity, delta * 6.0)
	saturation = lerp(saturation, 0.0, delta * 0.3)

	# Pulso
	var t = Time.get_ticks_msec() * 0.005
	var pulse = 1.0 + sin(t) * 0.06 * activity
	var chaos = sin(t * 1.7) * 0.04 * saturation
	core.scale = Vector2.ONE * (pulse + chaos)

	ring.rotation += delta * (0.4 + activity * 2.5 + saturation * 1.5)
	particles.amount = int(20 + activity * 80 + saturation * 120)

	var calm = Color(1, 0.4, 1)
	var hot = Color(1, 0.2, 0.8)
	var chaotic = Color(1, 0.6, 1)
	var color = calm.lerp(hot, activity)
	color = color.lerp(chaotic, saturation)
	core.modulate = color

	label.text = "+" + str(snapped(current_power, 0.1))

func hover():
	target_activity = max(target_activity, 0.4)

func unhover():
	if target_activity < 1.0:
		target_activity = 0.0

func click():
	saturation = min(1.0, saturation + 0.15)
