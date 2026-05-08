extends Node3D

# ============================================================
# REACTOR 3D — v1.3  "orbital"
# Cámara 26° arriba → anillos = elipses claras → 3D obvio
# Sin esfera-halo: el bloom del core da el glow sin tapar los anillos
# API pública: set_active_delta(power), set_tint(color)
# ============================================================

const BASE_SCALE       := 0.35
const SCALE_LOG_FACTOR := 0.07
const MAX_SCALE        := 1.6
const PULSE_DECAY      := 5.0
const PULSE_STRENGTH   := 0.3

var core:      MeshInstance3D
var particles: GPUParticles3D
var rings:     Array[MeshInstance3D] = []
var p_mat:     StandardMaterial3D

var core_mat: StandardMaterial3D

var target_scale:  float = BASE_SCALE
var current_scale: float = BASE_SCALE
var pulse:         float = 0.0
var target_tint:   Color = Color(0.15, 0.65, 1.0)

# Anillos: factores relativos al display_s del core
# La cámara está 26° arriba → los anillos horizontales se ven como elipses claras
const RING_SCALE_FACTORS: Array[float] = [2.2, 3.5, 5.0]

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
	env.ambient_light_color = Color(0.05, 0.05, 0.12)
	env.ambient_light_energy = 0.3
	# Bloom moderado — da glow al core sin ahogar los anillos
	env.glow_enabled = true
	env.glow_bloom = 0.12
	env.glow_intensity = 0.9
	env.glow_strength = 1.0
	env.glow_hdr_threshold = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

func _build_camera() -> void:
	# 26° arriba → los anillos horizontales se ven como elipses (claramente 3D)
	var cam := Camera3D.new()
	cam.position = Vector3(0.0, 3.0, 6.5)
	cam.fov = 50.0
	add_child(cam)
	cam.look_at(Vector3.ZERO, Vector3.UP)

func _build_lights() -> void:
	# Luz lateral fuerte → highlight especular que se mueve al rotar el core
	var key := OmniLight3D.new()
	key.position = Vector3(3.5, 2.0, 2.0)
	key.light_energy = 4.0
	key.light_specular = 2.0
	key.omni_range = 18.0
	add_child(key)
	# Relleno suave
	var fill := OmniLight3D.new()
	fill.position = Vector3(-2.0, -1.0, 2.0)
	fill.light_energy = 0.6
	fill.omni_range = 10.0
	add_child(fill)

func _build_meshes() -> void:
	# Core — esfera central con shading PER_PIXEL para el highlight 3D
	var sm := SphereMesh.new()
	sm.radius = 0.45
	sm.height = 0.9
	sm.radial_segments = 48
	sm.rings = 24
	core = MeshInstance3D.new()
	core.mesh = sm
	add_child(core)

	# Tres anillos toro — orientaciones para verse bien desde 26° arriba:
	# Ring1: casi horizontal → elipse clara
	# Ring2: 30° de tilt → elipse inclinada
	# Ring3: 55° de tilt → elipse estrecha para variedad
	var ring_defs: Array = [
		{"inner": 0.65, "outer": 0.90, "rot": Vector3( 8.0,   0.0,  0.0)},
		{"inner": 0.65, "outer": 0.90, "rot": Vector3(30.0,  60.0,  0.0)},
		{"inner": 0.65, "outer": 0.90, "rot": Vector3(55.0,  20.0, 45.0)},
	]
	for d: Dictionary in ring_defs:
		var t := TorusMesh.new()
		t.inner_radius = d["inner"]
		t.outer_radius = d["outer"]
		t.rings = 64
		t.ring_segments = 32
		var r := MeshInstance3D.new()
		r.mesh = t
		r.rotation_degrees = d["rot"]
		add_child(r)
		rings.append(r)

func _build_particles() -> void:
	p_mat = StandardMaterial3D.new()
	p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p_mat.emission_enabled = true
	p_mat.emission = target_tint
	p_mat.emission_energy_multiplier = 3.0
	p_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	p_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	p_mat.vertex_color_use_as_albedo = true

	var quad := QuadMesh.new()
	quad.size = Vector2(0.22, 0.22)
	quad.material = p_mat

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.5
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 70.0
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 4.0
	pm.gravity = Vector3(0.0, 0.3, 0.0)
	pm.scale_min = 0.5
	pm.scale_max = 1.5
	pm.color = target_tint

	particles = GPUParticles3D.new()
	particles.amount = 60
	particles.lifetime = 2.0
	particles.explosiveness = 0.0
	particles.draw_passes = 1
	particles.draw_pass_1 = quad
	particles.process_material = pm
	add_child(particles)

func _setup_materials() -> void:
	# Core: PER_PIXEL con metallic → highlight especular visible al rotar
	core_mat = StandardMaterial3D.new()
	core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	core_mat.metallic = 0.7
	core_mat.roughness = 0.15
	core_mat.emission_enabled = true
	core_mat.emission_energy_multiplier = 0.8
	core.material_override = core_mat

	# Anillos: opacos UNSHADED con alta emisión → cortan el bloom, siempre visibles
	for ring: MeshInstance3D in rings:
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		mat.emission_energy_multiplier = 4.0
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
	target_tint = EvoManager.get_reactor_color()

	# Escala suave
	current_scale = lerp(current_scale, target_scale * seta_bonus, 0.12)
	var display_s: float = current_scale + pulse * PULSE_STRENGTH + epsilon * 0.08

	core.scale = Vector3(display_s, display_s, display_s)

	# Anillos: escalan mucho más que el core → siempre fuera del bloom central
	for i: int in rings.size():
		var rs: float = display_s * RING_SCALE_FACTORS[i]
		rings[i].scale = Vector3(rs, rs, rs)

	# Core rota lentamente → el highlight especular se desplaza (efecto 3D obvio)
	core.rotate_y(delta * 0.6)

	pulse = max(pulse - delta * PULSE_DECAY, 0.0)

	# Color con estrés
	var stress: float = clamp(epsilon * 1.5, 0.0, 1.0)
	var final_color := target_tint.lerp(Color(1.0, 0.2, 0.2), stress)
	_apply_color(final_color)

	# Core: emisión baja para que el specular sea visible; sube con pulso y estrés
	core_mat.emission_energy_multiplier = 0.8 + pulse * 4.0 + epsilon * 1.2

	# Partículas
	var ratio: float = clamp(biomasa * 0.1 + epsilon * 0.7 + 0.15, 0.08, 1.0)
	particles.amount_ratio = ratio
	particles.speed_scale = 0.9 + epsilon * 1.2 + pulse * 0.8

	# Rotación de anillos — el más interno rota más rápido (like planetas)
	for i: int in rings.size():
		var spd: float = delta * (0.8 - i * 0.2) * (1.0 + current_scale * 0.3)
		rings[i].rotate_y(spd)

# ---- Internals ----

func _apply_color(c: Color) -> void:
	core_mat.albedo_color = c
	core_mat.emission = c
	p_mat.emission = c
	p_mat.albedo_color = c
	(particles.process_material as ParticleProcessMaterial).color = c
	for ring: MeshInstance3D in rings:
		var mat := ring.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = c
			mat.emission = c
