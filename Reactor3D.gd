extends Node3D

# ============================================================
# REACTOR 3D — v1.2
# API pública: set_active_delta(power), set_tint(color)
# ============================================================

const BASE_SCALE       := 0.35
const SCALE_LOG_FACTOR := 0.07
const MAX_SCALE        := 1.8
const PULSE_DECAY      := 5.0
const PULSE_STRENGTH   := 0.25

var core:      MeshInstance3D
var glow:      MeshInstance3D
var particles: GPUParticles3D
var rings:     Array[MeshInstance3D] = []
var p_mat:     StandardMaterial3D     # material de partículas (necesita actualizar color)

var core_mat: StandardMaterial3D
var glow_mat: StandardMaterial3D

var target_scale:  float = BASE_SCALE
var current_scale: float = BASE_SCALE
var pulse:         float = 0.0
var target_tint:   Color = Color(0.15, 0.65, 1.0)

# Factores de escala de anillos — siempre mayores que el halo (glow = core * 1.15)
# para que no queden ocultos dentro de él
const RING_SCALE_FACTORS: Array = [1.4, 1.9, 2.5]

# ---- Ciclo de vida ----

func _ready() -> void:
	_build_environment()
	_build_camera()
	_build_lights()
	_build_meshes()
	_build_particles()
	_setup_materials()

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.06, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.08, 0.08, 0.15)
	env.ambient_light_energy = 0.4
	env.glow_enabled = true
	env.glow_bloom = 0.3
	env.glow_intensity = 1.8
	env.glow_strength = 1.3
	env.glow_hdr_threshold = 0.4
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

func _build_camera() -> void:
	var cam := Camera3D.new()
	cam.position = Vector3(0.2, 0.5, 5.5)
	cam.fov = 52.0
	add_child(cam)
	cam.look_at(Vector3.ZERO, Vector3.UP)

func _build_lights() -> void:
	# Luz principal — offset para que el highlight sea visible al rotar el core
	var main_light := OmniLight3D.new()
	main_light.position = Vector3(3.0, 3.5, 2.0)
	main_light.light_energy = 3.0
	main_light.light_specular = 1.5
	main_light.omni_range = 15.0
	add_child(main_light)
	# Relleno suave desde el lado opuesto
	var fill := OmniLight3D.new()
	fill.position = Vector3(-2.0, -1.5, 1.5)
	fill.light_energy = 0.5
	fill.omni_range = 10.0
	add_child(fill)

func _build_meshes() -> void:
	# Core — esfera de alta resolución con shading PER_PIXEL para ver highlight 3D
	var sm := SphereMesh.new()
	sm.radius = 0.55
	sm.height = 1.1
	sm.radial_segments = 48
	sm.rings = 24
	core = MeshInstance3D.new()
	core.mesh = sm
	add_child(core)

	# Halo difuso — esfera grande aditiva
	var gs := SphereMesh.new()
	gs.radius = 0.72
	gs.height = 1.44
	gs.radial_segments = 16
	gs.rings = 8
	glow = MeshInstance3D.new()
	glow.mesh = gs
	add_child(glow)

	# Anillos — su scale en _process será display_s * RING_SCALE_FACTORS[i]
	# así siempre están fuera del halo (glow = core * 1.15)
	var ring_defs: Array = [
		# {inner, outer, rot_degrees} — tubo grueso para que se vea bien
		{"inner": 0.60, "outer": 0.90, "rot": Vector3(80.0,  0.0,  0.0)},
		{"inner": 0.60, "outer": 0.90, "rot": Vector3(50.0, 30.0,  0.0)},
		{"inner": 0.60, "outer": 0.90, "rot": Vector3(15.0, 70.0, 40.0)},
	]
	for d: Dictionary in ring_defs:
		var t := TorusMesh.new()
		t.inner_radius = d["inner"]
		t.outer_radius = d["outer"]
		t.rings = 48
		t.ring_segments = 24
		var r := MeshInstance3D.new()
		r.mesh = t
		r.rotation_degrees = d["rot"]
		add_child(r)
		rings.append(r)

func _build_particles() -> void:
	# Material del quad de cada partícula
	p_mat = StandardMaterial3D.new()
	p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p_mat.emission_enabled = true
	p_mat.emission = target_tint
	p_mat.emission_energy_multiplier = 2.0
	p_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	p_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	p_mat.vertex_color_use_as_albedo = true

	# Mesh del quad — cada partícula es un quad con billboard
	var quad := QuadMesh.new()
	quad.size = Vector2(0.18, 0.18)
	quad.material = p_mat

	# Process material — física de las partículas
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.6
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 80.0
	pm.initial_velocity_min = 0.8
	pm.initial_velocity_max = 3.0
	pm.gravity = Vector3(0.0, 0.4, 0.0)
	pm.scale_min = 0.6
	pm.scale_max = 1.4
	pm.color = target_tint

	particles = GPUParticles3D.new()
	particles.amount = 80
	particles.lifetime = 1.8
	particles.explosiveness = 0.0
	particles.draw_passes = 1
	particles.draw_pass_1 = quad          # ← crítico: sin esto no se ven
	particles.process_material = pm
	add_child(particles)

func _setup_materials() -> void:
	# Core: iluminado PER_PIXEL — el highlight de la luz crea el efecto 3D
	core_mat = StandardMaterial3D.new()
	core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	core_mat.metallic = 0.65
	core_mat.roughness = 0.2
	core_mat.emission_enabled = true
	core_mat.emission_energy_multiplier = 1.2
	core.material_override = core_mat

	# Halo: aditivo, muy transparente para no tapar los anillos
	glow_mat = StandardMaterial3D.new()
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_mat.emission_enabled = true
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow_mat.emission_energy_multiplier = 0.35
	glow.material_override = glow_mat

	# Anillos: aditivos y brillantes
	for ring: MeshInstance3D in rings:
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.emission_energy_multiplier = 2.0
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
	var display_s: float = current_scale + pulse * PULSE_STRENGTH + epsilon * 0.12

	core.scale = Vector3(display_s, display_s, display_s)
	var glow_s: float = display_s * 1.15
	glow.scale = Vector3(glow_s, glow_s, glow_s)

	# Anillos escalan con factor mayor que el halo → siempre visibles afuera
	for i: int in rings.size():
		var rs: float = display_s * RING_SCALE_FACTORS[i]
		rings[i].scale = Vector3(rs, rs, rs)

	# Rotación del core — el highlight especular se mueve → efecto 3D obvio
	core.rotate_y(delta * 0.5)

	# Decay del pulso
	pulse = max(pulse - delta * PULSE_DECAY, 0.0)

	# Color con estrés
	var stress: float = clamp(epsilon * 1.5, 0.0, 1.0)
	var final_color := target_tint.lerp(Color(1.0, 0.2, 0.2), stress)
	_apply_color(final_color)

	# Emisión
	core_mat.emission_energy_multiplier = 1.2 + pulse * 3.5 + epsilon * 1.5
	glow_mat.emission_energy_multiplier = 0.3 + pulse * 0.8 + epsilon * 0.5

	# Partículas — amount_ratio requiere Godot 4.1+
	var ratio: float = clamp(biomasa * 0.1 + epsilon * 0.7 + 0.15, 0.08, 1.0)
	particles.amount_ratio = ratio
	particles.speed_scale = 0.8 + epsilon * 1.0 + pulse * 0.6

	# Rotación de anillos — velocidades distintas para cada uno
	for i: int in rings.size():
		var spd: float = delta * (0.5 + current_scale * 0.3) * (1.0 + i * 0.6)
		rings[i].rotate_y(spd)
		rings[i].rotate_x(spd * 0.5 * (1 if i % 2 == 0 else -1))

# ---- Internals ----

func _apply_color(c: Color) -> void:
	core_mat.albedo_color = c
	core_mat.emission = c
	glow_mat.albedo_color = Color(c.r, c.g, c.b, 0.08)
	glow_mat.emission = c
	# Partículas
	p_mat.emission = c
	p_mat.albedo_color = c
	(particles.process_material as ParticleProcessMaterial).color = c
	# Anillos
	for ring: MeshInstance3D in rings:
		var mat := ring.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = Color(c.r, c.g, c.b, 0.7)
			mat.emission = c
