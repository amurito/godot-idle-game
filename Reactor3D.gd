extends Node3D

# ============================================================
# REACTOR 3D — v1.0
# Todos los nodos se crean proceduralmente en _ready().
# API pública (compatible con ReactorVisual):
#   set_active_delta(power: float) — pulso + escala
#   set_tint(color: Color)         — color de mutación
# ============================================================

const BASE_SCALE    := 0.8
const SCALE_LOG_FACTOR := 0.22
const MAX_SCALE     := 3.5
const PULSE_DECAY   := 5.0
const PULSE_STRENGTH := 0.45

var core:      MeshInstance3D
var glow:      MeshInstance3D
var particles: GPUParticles3D
var rings:     Array[MeshInstance3D] = []

var core_mat: StandardMaterial3D
var glow_mat: StandardMaterial3D

var target_scale:  float = BASE_SCALE
var current_scale: float = BASE_SCALE
var pulse:         float = 0.0
var target_tint:   Color = Color(0.15, 0.65, 1.0)

# ---- Ciclo de vida ----

func _ready() -> void:
	_build_environment()
	_build_camera()
	_build_meshes()
	_build_particles()
	_setup_materials()

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.05, 1.0)
	env.glow_enabled = true
	env.glow_bloom = 0.25
	env.glow_intensity = 1.4
	env.glow_strength = 1.0
	env.glow_hdr_threshold = 0.4
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

func _build_camera() -> void:
	var cam := Camera3D.new()
	cam.position = Vector3(0.0, 0.3, 4.5)
	cam.fov = 60.0
	add_child(cam)
	cam.look_at(Vector3.ZERO, Vector3.UP)

func _build_meshes() -> void:
	# Núcleo (esfera central)
	var s := SphereMesh.new()
	s.radius = 0.6
	s.height = 1.2
	core = MeshInstance3D.new()
	core.mesh = s
	add_child(core)

	# Halo (esfera más grande, aditiva)
	var gs := SphereMesh.new()
	gs.radius = 0.8
	gs.height = 1.6
	glow = MeshInstance3D.new()
	glow.mesh = gs
	add_child(glow)

	# Anillos (tres toros en ángulos distintos)
	var ring_defs := [
		{"inner": 0.85, "outer": 1.05, "rot": Vector3(45.0,  0.0,  0.0)},
		{"inner": 1.20, "outer": 1.45, "rot": Vector3(60.0, 30.0,  0.0)},
		{"inner": 1.60, "outer": 1.90, "rot": Vector3(20.0, 75.0, 45.0)},
	]
	for d in ring_defs:
		var t := TorusMesh.new()
		t.inner_radius = d["inner"]
		t.outer_radius = d["outer"]
		var r := MeshInstance3D.new()
		r.mesh = t
		r.rotation_degrees = d["rot"]
		add_child(r)
		rings.append(r)

func _build_particles() -> void:
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.7
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 90.0
	pm.initial_velocity_min = 0.8
	pm.initial_velocity_max = 2.5
	pm.gravity = Vector3(0.0, 0.3, 0.0)
	pm.scale_min = 0.05
	pm.scale_max = 0.15
	pm.color = target_tint

	particles = GPUParticles3D.new()
	particles.amount = 120
	particles.lifetime = 1.2
	particles.explosiveness = 0.05
	particles.process_material = pm
	add_child(particles)

func _setup_materials() -> void:
	# Núcleo: unshaded para que el glow del WorldEnvironment lo recoja
	core_mat = StandardMaterial3D.new()
	core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core_mat.emission_enabled = true
	core_mat.emission_energy_multiplier = 2.0
	core.material_override = core_mat

	# Halo: aditivo semitransparente
	glow_mat = StandardMaterial3D.new()
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_mat.emission_enabled = true
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow_mat.emission_energy_multiplier = 0.7
	glow.material_override = glow_mat

	# Anillos: aditivos semitransparentes
	for ring in rings:
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.emission_energy_multiplier = 0.9
		ring.material_override = mat

	_apply_color(target_tint)

# ---- API pública ----

func set_active_delta(power: float) -> void:
	pulse = 1.0
	target_scale = BASE_SCALE + log(max(power, 1.0)) * SCALE_LOG_FACTOR
	target_scale = clamp(target_scale, BASE_SCALE, MAX_SCALE)

func set_tint(color: Color) -> void:
	target_tint = color

# ---- Proceso ----

func _process(delta: float) -> void:
	var epsilon: float = StructuralModel.epsilon_runtime
	var biomasa: float = BiosphereEngine.biomasa
	var seta_bonus: float = 1.25 if EvoManager.seta_formada else 1.0

	# Escala suave con bonus de seta y pulso
	current_scale = lerp(current_scale, target_scale * seta_bonus, 0.15)
	var display_s := current_scale + pulse * PULSE_STRENGTH + epsilon * 0.25
	core.scale = Vector3(display_s, display_s, display_s)
	glow.scale = Vector3(display_s * 1.35, display_s * 1.35, display_s * 1.35)

	# Decay del pulso
	pulse = max(pulse - delta * PULSE_DECAY, 0.0)

	# Color con estrés (rojo con epsilon alto)
	var stress: float = clamp(epsilon * 1.5, 0.0, 1.0)
	var final_color := target_tint.lerp(Color(1.0, 0.2, 0.2), stress)
	_apply_color(final_color)

	# Intensidad de emisión
	core_mat.emission_energy_multiplier = 2.0 + pulse * 3.5 + epsilon * 2.5
	glow_mat.emission_energy_multiplier = 0.5 + pulse * 1.5 + epsilon * 1.2

	# Partículas escalan con biomasa y epsilon (usando amount_ratio para no reiniciar el sistema)
	var ratio: float = clamp((biomasa * 0.08 + epsilon * 0.8 + 0.1), 0.05, 1.0)
	particles.amount_ratio = ratio
	particles.speed_scale = 0.6 + epsilon * 1.5 + pulse * 1.0

	# Rotación de anillos (velocidades y ejes distintos)
	for i in rings.size():
		var speed := delta * (0.35 + current_scale * 0.25) * (1.0 + i * 0.45)
		rings[i].rotate_y(speed)
		rings[i].rotate_x(speed * 0.35 * (1 if i % 2 == 0 else -1))

# ---- Internals ----

func _apply_color(c: Color) -> void:
	core_mat.albedo_color = c
	core_mat.emission = c
	glow_mat.albedo_color = Color(c.r, c.g, c.b, 0.12)
	glow_mat.emission = c
	(particles.process_material as ParticleProcessMaterial).color = c
	for ring in rings:
		var mat := ring.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = Color(c.r, c.g, c.b, 0.55)
			mat.emission = c
