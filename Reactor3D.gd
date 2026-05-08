extends Node3D

# ============================================================
# REACTOR 3D — v1.1
# API pública: set_active_delta(power), set_tint(color)
# ============================================================

# Escala: BASE + log(power) * FACTOR — clampeada a MAX
# Con factor pequeño evitamos que powers altos destruyan la vista
const BASE_SCALE       := 0.35
const SCALE_LOG_FACTOR := 0.07   # reducido para que no se coma la pantalla
const MAX_SCALE        := 1.8
const PULSE_DECAY      := 5.0
const PULSE_STRENGTH   := 0.25

var core:      MeshInstance3D
var glow:      MeshInstance3D
var particles: GPUParticles3D
var rings:     Array[MeshInstance3D] = []
var light:     OmniLight3D

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
	_build_light()
	_build_meshes()
	_build_particles()
	_setup_materials()

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.06, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.05, 0.05, 0.1)
	env.ambient_light_energy = 0.3
	env.glow_enabled = true
	env.glow_bloom = 0.3
	env.glow_intensity = 1.6
	env.glow_strength = 1.2
	env.glow_hdr_threshold = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

func _build_camera() -> void:
	var cam := Camera3D.new()
	cam.position = Vector3(0.0, 0.2, 5.0)
	cam.fov = 55.0
	add_child(cam)
	cam.look_at(Vector3.ZERO, Vector3.UP)

func _build_light() -> void:
	# Luz principal — da profundidad 3D al core
	light = OmniLight3D.new()
	light.position = Vector3(2.5, 3.0, 2.5)
	light.light_energy = 2.5
	light.light_specular = 1.0
	light.omni_range = 12.0
	add_child(light)
	# Luz de relleno suave desde abajo
	var fill := OmniLight3D.new()
	fill.position = Vector3(-1.5, -2.0, 1.5)
	fill.light_energy = 0.6
	fill.omni_range = 8.0
	add_child(fill)

func _build_meshes() -> void:
	# Core esférico — material PER_PIXEL para mostrar iluminación 3D
	var sm := SphereMesh.new()
	sm.radius = 0.55
	sm.height = 1.1
	sm.radial_segments = 32
	sm.rings = 16
	core = MeshInstance3D.new()
	core.mesh = sm
	add_child(core)

	# Halo difuso (esfera grande, blending aditivo)
	var gs := SphereMesh.new()
	gs.radius = 0.7
	gs.height = 1.4
	gs.radial_segments = 16
	gs.rings = 8
	glow = MeshInstance3D.new()
	glow.mesh = gs
	add_child(glow)

	# Tres anillos toro — se escalan con current_scale en _process
	var ring_defs: Array = [
		{"inner": 0.65, "outer": 0.80, "rot": Vector3(80.0,  0.0,  0.0)},
		{"inner": 0.90, "outer": 1.10, "rot": Vector3(55.0, 25.0,  0.0)},
		{"inner": 1.20, "outer": 1.45, "rot": Vector3(20.0, 70.0, 40.0)},
	]
	for d: Dictionary in ring_defs:
		var t := TorusMesh.new()
		t.inner_radius = d["inner"]
		t.outer_radius = d["outer"]
		t.rings = 32
		t.ring_segments = 16
		var r := MeshInstance3D.new()
		r.mesh = t
		r.rotation_degrees = d["rot"]
		add_child(r)
		rings.append(r)

func _build_particles() -> void:
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.6
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 80.0
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 3.5
	pm.gravity = Vector3(0.0, 0.5, 0.0)
	pm.scale_min = 0.08
	pm.scale_max = 0.22
	pm.color = target_tint

	particles = GPUParticles3D.new()
	particles.amount = 80
	particles.lifetime = 1.5
	particles.explosiveness = 0.0
	particles.process_material = pm
	add_child(particles)

func _setup_materials() -> void:
	# Core: iluminado (PER_PIXEL) para ver profundidad 3D, con emisión para bloom
	core_mat = StandardMaterial3D.new()
	core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	core_mat.metallic = 0.6
	core_mat.roughness = 0.25
	core_mat.emission_enabled = true
	core_mat.emission_energy_multiplier = 1.8
	core.material_override = core_mat

	# Halo: aditivo semitransparente
	glow_mat = StandardMaterial3D.new()
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_mat.emission_enabled = true
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow_mat.emission_energy_multiplier = 0.5
	glow.material_override = glow_mat

	# Anillos: aditivos, se ven a través del halo
	for ring: MeshInstance3D in rings:
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.emission_energy_multiplier = 1.2
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

	# Escala suave
	current_scale = lerp(current_scale, target_scale * seta_bonus, 0.12)
	var display_s: float = current_scale + pulse * PULSE_STRENGTH + epsilon * 0.15

	core.scale = Vector3(display_s, display_s, display_s)
	# Halo ligeramente mayor que el core
	var glow_s: float = display_s * 1.15
	glow.scale = Vector3(glow_s, glow_s, glow_s)

	# Anillos escalan con el core para no quedar ocultos detrás del halo
	for i: int in rings.size():
		var rs: float = display_s * (1.0 + i * 0.15)
		rings[i].scale = Vector3(rs, rs, rs)

	# Rotación lenta del core — hace obvia la geometría 3D
	core.rotate_y(delta * 0.4)

	# Decay del pulso
	pulse = max(pulse - delta * PULSE_DECAY, 0.0)

	# Color con estrés
	var stress: float = clamp(epsilon * 1.5, 0.0, 1.0)
	var final_color := target_tint.lerp(Color(1.0, 0.2, 0.2), stress)
	_apply_color(final_color)

	# Emisión sube con pulso y estrés
	core_mat.emission_energy_multiplier = 1.8 + pulse * 4.0 + epsilon * 2.0
	glow_mat.emission_energy_multiplier = 0.4 + pulse * 1.2 + epsilon * 0.8

	# La luz de acento cambia con el color de mutación
	light.light_color = final_color

	# Partículas
	var ratio: float = clamp(biomasa * 0.1 + epsilon * 0.7 + 0.15, 0.08, 1.0)
	particles.amount_ratio = ratio
	particles.speed_scale = 0.7 + epsilon * 1.2 + pulse * 0.8

	# Rotación de anillos (cada uno gira diferente)
	for i: int in rings.size():
		var spd: float = delta * (0.3 + current_scale * 0.2) * (1.0 + i * 0.5)
		rings[i].rotate_y(spd)
		rings[i].rotate_x(spd * 0.4 * (1 if i % 2 == 0 else -1))

# ---- Internals ----

func _apply_color(c: Color) -> void:
	core_mat.albedo_color = c
	core_mat.emission = c
	glow_mat.albedo_color = Color(c.r, c.g, c.b, 0.10)
	glow_mat.emission = c
	(particles.process_material as ParticleProcessMaterial).color = c
	for ring: MeshInstance3D in rings:
		var mat := ring.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = Color(c.r, c.g, c.b, 0.6)
			mat.emission = c
