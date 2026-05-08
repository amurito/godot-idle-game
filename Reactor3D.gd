extends Node3D

# ============================================================
# REACTOR 3D — v2.0  "neural"
# Estética HD orgánica: anillos wire finos + tendriles fractales + bloom fuerte
# Inspirado en redes miceliares — el núcleo 3D da profundidad real
# ============================================================

const BASE_SCALE       := 0.35
const SCALE_LOG_FACTOR := 0.07
const MAX_SCALE        := 1.6
const PULSE_DECAY      := 5.0
const PULSE_STRENGTH   := 0.3

var core:         MeshInstance3D
var core_hot:     MeshInstance3D       # punto caliente central — blanco puro
var tendril_mi:   MeshInstance3D
var tendril_mesh: ImmediateMesh
var tendril_mat:  StandardMaterial3D
var particles:    GPUParticles3D
var rings:        Array[MeshInstance3D] = []
var p_mat:        StandardMaterial3D
var core_mat:     StandardMaterial3D
var hot_mat:      StandardMaterial3D

var target_scale:  float = BASE_SCALE
var current_scale: float = BASE_SCALE
var pulse:         float = 0.0
var target_tint:   Color = Color(0.15, 0.65, 1.0)
var anim_time:     float = 0.0

# Anillos wire: outer_radius se multiplica por display_s en _process
# inner = outer * 0.92  →  tubo muy fino, "línea de luz" con bloom
# Los 4 primeros son casi horizontales → elipses concéntricas desde cámara 26°
# Los 2 últimos muy inclinados         → confirman profundidad 3D
const WIRE_RING_DEFS: Array = [
	{"outer": 0.80, "rot": Vector3( 5.0,   0.0,  0.0)},
	{"outer": 1.35, "rot": Vector3( 8.0,  55.0,  0.0)},
	{"outer": 1.95, "rot": Vector3( 6.0, 110.0,  0.0)},
	{"outer": 2.65, "rot": Vector3( 4.0, 165.0,  0.0)},
	{"outer": 2.10, "rot": Vector3(40.0,  40.0,  0.0)},
	{"outer": 3.30, "rot": Vector3(62.0,  20.0, 55.0)},
]

# ---- Ciclo de vida ----

func _ready() -> void:
	_build_environment()
	_build_camera()
	_build_lights()
	_build_core()
	_build_rings()
	_build_tendrils()
	_build_particles()
	_setup_materials()

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode  = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.01, 0.04, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color  = Color(0.03, 0.03, 0.08)
	env.ambient_light_energy = 0.15
	# Bloom fuerte — líneas finas brillan como en el concept art miceliar
	env.glow_enabled       = true
	env.glow_bloom         = 0.40
	env.glow_intensity     = 2.5
	env.glow_strength      = 1.8
	env.glow_hdr_threshold = 0.25
	env.tonemap_mode       = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white      = 1.4
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

func _build_camera() -> void:
	var cam := Camera3D.new()
	cam.position = Vector3(0.0, 3.0, 6.5)
	cam.fov = 50.0
	add_child(cam)
	cam.look_at(Vector3.ZERO, Vector3.UP)

func _build_lights() -> void:
	var key := OmniLight3D.new()
	key.position       = Vector3(3.5, 2.0, 2.0)
	key.light_energy   = 5.0
	key.light_specular = 3.0
	key.omni_range     = 20.0
	add_child(key)
	var fill := OmniLight3D.new()
	fill.position     = Vector3(-2.0, -1.0, 2.0)
	fill.light_energy = 0.5
	fill.omni_range   = 12.0
	add_child(fill)

func _build_core() -> void:
	# Punto caliente: esfera muy pequeña, siempre blanca — el "núcleo ardiente"
	var sh := SphereMesh.new()
	sh.radius = 0.12
	sh.height  = 0.24
	sh.radial_segments = 16
	sh.rings   = 8
	core_hot = MeshInstance3D.new()
	core_hot.mesh = sh
	add_child(core_hot)

	# Core exterior — highlight especular 3D al rotar
	var sm := SphereMesh.new()
	sm.radius = 0.34
	sm.height  = 0.68
	sm.radial_segments = 48
	sm.rings   = 24
	core = MeshInstance3D.new()
	core.mesh = sm
	add_child(core)

func _build_rings() -> void:
	for d: Dictionary in WIRE_RING_DEFS:
		var outer: float = float(d["outer"])
		var inner: float = outer * 0.92   # tubo muy fino = "wire"
		var t := TorusMesh.new()
		t.inner_radius  = inner
		t.outer_radius  = outer
		t.rings         = 96
		t.ring_segments = 12
		var r := MeshInstance3D.new()
		r.mesh = t
		r.rotation_degrees = d["rot"]
		add_child(r)
		rings.append(r)

func _build_tendrils() -> void:
	tendril_mat = StandardMaterial3D.new()
	tendril_mat.shading_mode              = BaseMaterial3D.SHADING_MODE_UNSHADED
	tendril_mat.emission_enabled          = true
	tendril_mat.emission_energy_multiplier = 10.0
	# Sin TRANSPARENCY_ALPHA — opacos + emisión + bloom = línea de luz

	tendril_mesh = ImmediateMesh.new()
	tendril_mi   = MeshInstance3D.new()
	tendril_mi.mesh = tendril_mesh
	tendril_mi.material_override = tendril_mat
	add_child(tendril_mi)

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
	quad.size = Vector2(0.10, 0.10)
	quad.material = p_mat

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape         = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.4
	pm.direction              = Vector3(0.0, 1.0, 0.0)
	pm.spread                 = 75.0
	pm.initial_velocity_min   = 0.5
	pm.initial_velocity_max   = 3.5
	pm.gravity                = Vector3(0.0, 0.1, 0.0)
	pm.scale_min              = 0.3
	pm.scale_max              = 1.2
	pm.color                  = target_tint

	particles = GPUParticles3D.new()
	particles.amount           = 80
	particles.lifetime         = 2.5
	particles.explosiveness    = 0.0
	particles.draw_passes      = 1
	particles.draw_pass_1      = quad
	particles.process_material = pm
	add_child(particles)

func _setup_materials() -> void:
	# Punto caliente: blanco puro, emisión extrema
	hot_mat = StandardMaterial3D.new()
	hot_mat.shading_mode              = BaseMaterial3D.SHADING_MODE_UNSHADED
	hot_mat.emission_enabled          = true
	hot_mat.emission                  = Color.WHITE
	hot_mat.emission_energy_multiplier = 20.0
	hot_mat.albedo_color              = Color.WHITE
	core_hot.material_override        = hot_mat

	# Core: PER_PIXEL con metallic — highlight especular visible al rotar
	core_mat = StandardMaterial3D.new()
	core_mat.shading_mode              = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	core_mat.metallic                  = 0.7
	core_mat.roughness                 = 0.12
	core_mat.emission_enabled          = true
	core_mat.emission_energy_multiplier = 3.0
	core.material_override             = core_mat

	# Anillos wire: UNSHADED alta emisión
	for ring: MeshInstance3D in rings:
		var mat := StandardMaterial3D.new()
		mat.shading_mode              = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled          = true
		mat.emission_energy_multiplier = 6.0
		ring.material_override        = mat

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
	anim_time += delta
	var epsilon: float    = StructuralModel.epsilon_runtime
	var biomasa: float    = BiosphereEngine.biomasa
	var seta_bonus: float = 1.25 if EvoManager.seta_formada else 1.0
	target_tint = EvoManager.get_reactor_color()

	current_scale = lerp(current_scale, target_scale * seta_bonus, 0.12)
	var display_s: float = current_scale + pulse * PULSE_STRENGTH + epsilon * 0.08

	# Núcleo — hot siempre proporcional, core exterior escala con power
	core.scale     = Vector3(display_s, display_s, display_s)
	core_hot.scale = Vector3(display_s * 0.36, display_s * 0.36, display_s * 0.36)

	# Anillos escalan uniformemente con display_s
	for ring: MeshInstance3D in rings:
		ring.scale = Vector3(display_s, display_s, display_s)

	# Rotación del core → highlight especular se mueve → efecto 3D obvio
	core.rotate_y(delta * 0.65)
	core_hot.rotate_y(delta * -0.9)

	pulse = max(pulse - delta * PULSE_DECAY, 0.0)

	var stress: float  = clamp(epsilon * 1.5, 0.0, 1.0)
	var final_color := target_tint.lerp(Color(1.0, 0.2, 0.2), stress)
	_apply_color(final_color)

	# Emisiones reactivas al pulso y estrés
	core_mat.emission_energy_multiplier = 3.0  + pulse * 10.0 + epsilon * 2.5
	hot_mat.emission_energy_multiplier  = 20.0 + pulse * 30.0 + epsilon * 8.0

	# Tendriles fractales — se reconstruyen cada frame (O(1), muy rápido)
	_update_tendrils(display_s, final_color)

	# Partículas
	var ratio: float = clamp(biomasa * 0.1 + epsilon * 0.7 + 0.15, 0.08, 1.0)
	particles.amount_ratio = ratio
	particles.speed_scale  = 0.9 + epsilon * 1.2 + pulse * 0.8

	# Rotación diferencial de anillos — alternando dirección
	for i: int in rings.size():
		var spd: float = delta * (0.45 + float(i) * 0.07) * (1.0 + current_scale * 0.25)
		if i % 2 == 0:
			rings[i].rotate_y(spd)
		else:
			rings[i].rotate_y(-spd)
			rings[i].rotate_x(spd * 0.28)

# ---- Tendriles ----

func _update_tendrils(display_s: float, color: Color) -> void:
	tendril_mesh.clear_surfaces()
	tendril_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var base_len: float = display_s * 3.4
	var branches: int   = 6                    # simetría 6 como redes miceliares
	var anim_off: float = anim_time * 0.22

	for i: int in range(branches):
		var angle: float = float(i) * TAU / float(branches) + anim_off
		var dir := Vector3(cos(angle), 0.0, sin(angle))

		# Tendril principal: desde el borde del core hasta la punta
		var p0 := dir * display_s * 0.37
		var p1 := dir * base_len
		tendril_mesh.surface_add_vertex(p0)
		tendril_mesh.surface_add_vertex(p1)

		# Sub-ramas: nacen al 55% del tendril principal
		var mid := dir * base_len * 0.55
		var a_l: float = angle + 0.50
		var a_r: float = angle - 0.50
		var sub_len: float = base_len * 0.44
		var d_l := Vector3(cos(a_l), 0.04, sin(a_l))
		var d_r := Vector3(cos(a_r), -0.04, sin(a_r))

		tendril_mesh.surface_add_vertex(mid)
		tendril_mesh.surface_add_vertex(mid + d_l * sub_len)
		tendril_mesh.surface_add_vertex(mid)
		tendril_mesh.surface_add_vertex(mid + d_r * sub_len)

		# Tercer nivel: ramifica al 60% de las sub-ramas
		var sl2: float = sub_len * 0.50
		var m_l := mid + d_l * sub_len * 0.60
		var m_r := mid + d_r * sub_len * 0.60

		for a_off: float in [0.48, -0.48]:
			var a3l: float = a_l + a_off
			var a3r: float = a_r + a_off
			tendril_mesh.surface_add_vertex(m_l)
			tendril_mesh.surface_add_vertex(m_l + Vector3(cos(a3l), 0.0, sin(a3l)) * sl2)
			tendril_mesh.surface_add_vertex(m_r)
			tendril_mesh.surface_add_vertex(m_r + Vector3(cos(a3r), 0.0, sin(a3r)) * sl2)

	tendril_mesh.surface_end()

# ---- Internals ----

func _apply_color(c: Color) -> void:
	if core_mat:
		core_mat.albedo_color = c
		core_mat.emission     = c
	# hot_mat permanece blanco puro — el punto ardiente siempre blanco
	if p_mat:
		p_mat.emission     = c
		p_mat.albedo_color = c
		(particles.process_material as ParticleProcessMaterial).color = c
	if tendril_mat:
		tendril_mat.emission     = c
		tendril_mat.albedo_color = c
	for ring: MeshInstance3D in rings:
		var mat := ring.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = c
			mat.emission     = c
