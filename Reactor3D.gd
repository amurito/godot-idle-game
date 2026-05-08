extends Node3D

# ============================================================
# REACTOR 3D — v3.0  "core"
# El núcleo ES el reactor — esfera que crece con el poder
# Core PER_PIXEL (specular 3D) + halo aditivo suave + partículas
# ============================================================

const BASE_SCALE       := 0.10   # empieza muy pequeño → crecimiento visible de 1→1000
const SCALE_LOG_FACTOR := 0.30   # crecimiento más agresivo que el 2D
const MAX_SCALE        := 4.0
const PULSE_DECAY      := 5.0
const PULSE_STRENGTH   := 0.35

var core:      MeshInstance3D
var glow_halo: MeshInstance3D    # esfera difusa aditiva — el resplandor alrededor
var particles: GPUParticles3D
var p_mat:     StandardMaterial3D
var core_mat:  StandardMaterial3D
var halo_mat:  StandardMaterial3D

var target_scale:  float = BASE_SCALE
var current_scale: float = BASE_SCALE
var pulse:         float = 0.0
var target_tint:   Color = Color(0.15, 0.65, 1.0)

# ---- Ciclo de vida ----

func _ready() -> void:
	_build_environment()
	_build_camera()
	_build_lights()
	_build_core()
	_build_particles()
	_setup_materials()

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode  = Environment.BG_COLOR
	env.background_color = Color(0.0, 0.0, 0.0, 0.0)  # transparente
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color  = Color(0.04, 0.04, 0.12)
	env.ambient_light_energy = 0.25
	env.glow_enabled       = true
	env.glow_bloom         = 0.35
	env.glow_intensity     = 2.2
	env.glow_strength      = 1.6
	env.glow_hdr_threshold = 0.3
	env.tonemap_mode       = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white      = 1.3
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

func _build_camera() -> void:
	# Cerca y fov amplio → esfera ocupa la mayor parte del viewport cuando crece
	var cam := Camera3D.new()
	cam.position = Vector3(0.0, 1.8, 4.2)
	cam.fov = 58.0
	add_child(cam)
	cam.look_at(Vector3.ZERO, Vector3.UP)

func _build_lights() -> void:
	# Luz asimétrica fuerte — el highlight especular se mueve al rotar
	var key := OmniLight3D.new()
	key.position       = Vector3(3.5, 2.0, 2.0)
	key.light_energy   = 6.0
	key.light_specular = 3.5
	key.omni_range     = 20.0
	add_child(key)
	# Contraluz suave — el lado oscuro no es negro puro
	var fill := OmniLight3D.new()
	fill.position     = Vector3(-2.0, -1.0, 2.0)
	fill.light_energy = 0.7
	fill.omni_range   = 12.0
	add_child(fill)
	# Luz inferior tenue — más richeza de color
	var rim := OmniLight3D.new()
	rim.position     = Vector3(0.0, -3.0, 1.0)
	rim.light_energy = 0.4
	rim.omni_range   = 10.0
	add_child(rim)

func _build_core() -> void:
	# Halo difuso — esfera grande aditiva, da el "resplandor de calor"
	var gs := SphereMesh.new()
	gs.radius = 0.85
	gs.height  = 1.70
	gs.radial_segments = 20
	gs.rings   = 10
	glow_halo = MeshInstance3D.new()
	glow_halo.mesh = gs
	add_child(glow_halo)

	# Core — esfera alta resolución con highlight especular 3D
	var sm := SphereMesh.new()
	sm.radius = 0.65
	sm.height  = 1.30
	sm.radial_segments = 64
	sm.rings   = 32
	core = MeshInstance3D.new()
	core.mesh = sm
	add_child(core)

func _build_particles() -> void:
	p_mat = StandardMaterial3D.new()
	p_mat.shading_mode              = BaseMaterial3D.SHADING_MODE_UNSHADED
	p_mat.emission_enabled          = true
	p_mat.emission                  = target_tint
	p_mat.emission_energy_multiplier = 4.0
	p_mat.transparency              = BaseMaterial3D.TRANSPARENCY_ALPHA
	p_mat.billboard_mode            = BaseMaterial3D.BILLBOARD_ENABLED
	p_mat.vertex_color_use_as_albedo = true

	var quad := QuadMesh.new()
	quad.size = Vector2(0.12, 0.12)
	quad.material = p_mat

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape         = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.7
	pm.direction              = Vector3(0.0, 1.0, 0.0)
	pm.spread                 = 65.0
	pm.initial_velocity_min   = 0.3
	pm.initial_velocity_max   = 2.5
	pm.gravity                = Vector3(0.0, 0.05, 0.0)
	pm.scale_min              = 0.4
	pm.scale_max              = 1.3
	pm.color                  = target_tint

	particles = GPUParticles3D.new()
	particles.amount           = 60
	particles.lifetime         = 2.5
	particles.explosiveness    = 0.0
	particles.draw_passes      = 1
	particles.draw_pass_1      = quad
	particles.process_material = pm
	add_child(particles)

func _setup_materials() -> void:
	# Halo: UNSHADED aditivo, muy transparente — solo emisión suave
	halo_mat = StandardMaterial3D.new()
	halo_mat.shading_mode              = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo_mat.emission_enabled          = true
	halo_mat.emission_energy_multiplier = 0.4
	halo_mat.transparency              = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_mat.blend_mode                = BaseMaterial3D.BLEND_MODE_ADD
	glow_halo.material_override        = halo_mat

	# Core: PER_PIXEL metallic — el highlight especular confirma que es 3D
	core_mat = StandardMaterial3D.new()
	core_mat.shading_mode              = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	core_mat.metallic                  = 0.65
	core_mat.roughness                 = 0.15
	core_mat.emission_enabled          = true
	core_mat.emission_energy_multiplier = 2.0
	core.material_override             = core_mat

	_apply_color(target_tint)

# ---- API pública ----

func set_active_delta(power: float) -> void:
	pulse = 1.0
	target_scale = BASE_SCALE + log(1.0 + power) * SCALE_LOG_FACTOR
	target_scale = clamp(target_scale, BASE_SCALE, MAX_SCALE)

func set_tint(color: Color) -> void:
	target_tint = color

# ---- Proceso ----

func _process(delta: float) -> void:
	var epsilon: float    = StructuralModel.epsilon_runtime
	var biomasa: float    = BiosphereEngine.biomasa
	var seta_bonus: float = 1.25 if EvoManager.seta_formada else 1.0
	target_tint = EvoManager.get_reactor_color()

	current_scale = lerp(current_scale, target_scale * seta_bonus, 0.12)
	var display_s: float = current_scale + pulse * PULSE_STRENGTH + epsilon * 0.08

	# Escalar — el core crece, el halo lo rodea siempre 1.3×
	core.scale      = Vector3(display_s, display_s, display_s)
	glow_halo.scale = Vector3(display_s * 1.30, display_s * 1.30, display_s * 1.30)

	# Rotar core — el highlight especular se mueve → se confirma 3D
	core.rotate_y(delta * 0.6)
	glow_halo.rotate_y(delta * 0.15)

	pulse = max(pulse - delta * PULSE_DECAY, 0.0)

	var stress: float  = clamp(epsilon * 1.5, 0.0, 1.0)
	var final_color := target_tint.lerp(Color(1.0, 0.2, 0.2), stress)
	_apply_color(final_color)

	# Emisión crece con pulso y estrés
	core_mat.emission_energy_multiplier = 2.0 + pulse * 8.0  + epsilon * 2.0
	halo_mat.emission_energy_multiplier = 0.4 + pulse * 2.0  + epsilon * 0.8

	# Partículas — escalan el radio de emisión con el core
	var pm := particles.process_material as ParticleProcessMaterial
	pm.emission_sphere_radius = 0.68 * display_s
	var ratio: float = clamp(biomasa * 0.1 + epsilon * 0.7 + 0.15, 0.08, 1.0)
	particles.amount_ratio = ratio
	particles.speed_scale  = 0.9 + epsilon * 1.2 + pulse * 0.8

# ---- Internals ----

func _apply_color(c: Color) -> void:
	if core_mat:
		core_mat.albedo_color = c
		core_mat.emission     = c
	if halo_mat:
		halo_mat.albedo_color = Color(c.r, c.g, c.b, 0.08)
		halo_mat.emission     = c
	if p_mat:
		p_mat.emission     = c
		p_mat.albedo_color = c
		(particles.process_material as ParticleProcessMaterial).color = c
