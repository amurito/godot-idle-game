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
var fungi_influence := 0.0

func apply_fungi_influence(v: float):
	fungi_influence = v

func set_power(p):
	current_power = p

func _ready():
	var parent = get_parent()
	if parent is Control:
		position = parent.size * 0.5
		var base = min(parent.size.x, parent.size.y)
		base_scale = base / 200.0
		scale = Vector2.ONE * base_scale
		
func get_growth_factor(norm: float) -> float:
	# curva lenta al inicio, fuerte cerca de 1
	return clamp(log(1.0 + norm * 4.0), 0.0, 1.4)
func get_norm_power() -> float:
	if max_display_power <= 0.0:
		return 0.0
	return clamp(current_power / max_display_power, 0.0, 1.5)
func set_particle_size(mult: float):
	if particles.process_material and particles.process_material is ParticleProcessMaterial:
		var mat := particles.process_material as ParticleProcessMaterial
		mat.scale_min = 0.6 * mult
		mat.scale_max = 1.2 * mult
	
func _process(delta):
	var norm = get_norm_power()
	var growth = get_growth_factor(norm)
	var particle_growth = lerp(0.8, 2.2, growth)
	set_particle_size(particle_growth)

	var size_growth = lerp(1.0, 1.75, growth)
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
	# Influencia micelial: estabiliza y enfría
	var fungi_tint = Color(0.78, 0.3, 1.0)
	core.modulate = core.modulate.lerp(fungi_tint, fungi_influence * 0.25)

	label.text = "+" + str(snapped(current_power, 0.1))

func hover():
	target_activity = max(target_activity, 0.4)

func unhover():
	if target_activity < 1.0:
		target_activity = 0.0

func click():
	saturation = min(1.0, saturation + 0.15)
