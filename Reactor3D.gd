extends Node3D

# ============================================================
# REACTOR 3D — v3.1  "core"
# Esfera que crece con el poder — cámara cerca, sin halo (bloom natural)
# ============================================================

const BASE_SCALE       := 0.10
const SCALE_LOG_FACTOR := 0.30
const MAX_SCALE        := 4.0
const PULSE_DECAY      := 4.0
const PULSE_STRENGTH   := 0.28

var core:      MeshInstance3D
var particles: GPUParticles3D
var cam:       Camera3D
var p_mat:     StandardMaterial3D
var core_mat:  StandardMaterial3D

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
	env.background_color = Color(0.0, 0.0, 0.0, 0.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color  = Color(0.08, 0.08, 0.18)
	env.ambient_light_energy = 0.5   # más ambiente → color visible aunque emisión sea baja
	env.glow_enabled       = true
	env.glow_bloom         = 0.30
	env.glow_intensity     = 1.8
	env.glow_strength      = 1.4
	env.glow_hdr_threshold = 0.35
	env.tonemap_mode       = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white      = 1.6     # más headroom → tints no se saturan a blanco
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

func _build_camera() -> void:
	# Cámara dinámica — se aleja con la esfera para que nunca sea cortada
	cam = Camera3D.new()
	cam.position = Vector3(0.0, 0.6, 2.0)
	cam.fov = 68.0
	add_child(cam)
	cam.look_at(Vector3.ZERO, Vector3.UP)

func _build_lights() -> void:
	# Key moderada — suficiente para el highlight 3D sin saturar a blanco
	var key := OmniLight3D.new()
	key.position       = Vector3(3.0, 1.5, 1.5)
	key.light_energy   = 2.5
	key.light_specular = 1.2
	key.omni_range     = 16.0
	add_child(key)
	# Fill suave
	var fill := OmniLight3D.new()
	fill.position     = Vector3(-2.0, -1.0, 1.5)
	fill.light_energy = 0.6
	fill.omni_range   = 10.0
	add_child(fill)
	# Rim inferior — evita negro puro en la parte de abajo
	var rim := OmniLight3D.new()
	rim.position     = Vector3(0.0, -2.5, 0.8)
	rim.light_energy = 0.35
	rim.omni_range   = 8.0
	add_child(rim)

func _build_core() -> void:
	var sm := SphereMesh.new()
	sm.radius = 0.85
	sm.height  = 1.70
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
	pm.emission_sphere_radius = 0.9
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
	# PER_PIXEL con metallic moderado — highlight 3D visible, tint de color dominante
	core_mat = StandardMaterial3D.new()
	core_mat.shading_mode              = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	core_mat.metallic                  = 0.25
	core_mat.roughness                 = 0.40
	core_mat.emission_enabled          = true
	core_mat.emission_energy_multiplier = 0.9  # bajo → el albedo/diffuse domina el color
	core.material_override             = core_mat
	_apply_color(target_tint)

# ---- API pública ----

func set_active_delta(power: float) -> void:
	pulse = 1.0
	target_scale = BASE_SCALE + log(1.0 + power) * SCALE_LOG_FACTOR
	target_scale = clamp(target_scale, BASE_SCALE, MAX_SCALE)

func sync_power(power: float) -> void:
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
	var display_s: float = current_scale + pulse * PULSE_STRENGTH + epsilon * 0.06

	core.scale = Vector3(display_s, display_s, display_s)

	# Cámara dinámica: se aleja cuando la esfera crece → nunca se corta
	# target_z = display_s * 2.5 garantiza que la esfera ocupa ~70% del alto del viewport
	var target_z: float = max(display_s * 2.0, 1.8)
	var new_cam_pos := Vector3(0.0, target_z * 0.30, target_z)
	cam.position = cam.position.lerp(new_cam_pos, 0.08)
	cam.look_at(Vector3.ZERO, Vector3.UP)

	# Rotar → highlight especular se mueve = confirma 3D
	core.rotate_y(delta * 0.55)

	pulse = max(pulse - delta * PULSE_DECAY, 0.0)

	# Núcleo: siempre el color de la mutación, sin influencia del estrés
	if core_mat:
		core_mat.albedo_color = target_tint
		core_mat.emission     = target_tint

	# Partículas: se tiñen de rojo con el estrés (epsilon)
	var stress: float    = clamp(epsilon * 1.5, 0.0, 1.0)
	var stress_color     := target_tint.lerp(Color(1.0, 0.2, 0.2), stress)
	if p_mat:
		p_mat.emission     = stress_color
		p_mat.albedo_color = stress_color
		(particles.process_material as ParticleProcessMaterial).color = stress_color

	# Emisión sube POCO con el pulso — así no satura a blanco
	core_mat.emission_energy_multiplier = 0.9 + pulse * 1.8 + epsilon * 1.2

	# Partículas orbitan justo fuera de la esfera
	var pm := particles.process_material as ParticleProcessMaterial
	pm.emission_sphere_radius = 0.88 * display_s
	var ratio: float = clamp(biomasa * 0.1 + epsilon * 0.7 + 0.15, 0.08, 1.0)
	particles.amount_ratio = ratio
	particles.speed_scale  = 0.9 + epsilon * 1.2 + pulse * 0.6

# ---- Internals ----

# Solo para setup inicial — en _process se aplican por separado
func _apply_color(c: Color) -> void:
	if core_mat:
		core_mat.albedo_color = c
		core_mat.emission     = c
	if p_mat:
		p_mat.emission     = c
		p_mat.albedo_color = c
		(particles.process_material as ParticleProcessMaterial).color = c
