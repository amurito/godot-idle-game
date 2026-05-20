extends Node2D

# =========================
# NODOS
# =========================
@onready var core: Node2D = $Core
@onready var core_inner: Node2D = $CoreInner
@onready var ring: Node2D = $Ring
@onready var particles: GPUParticles2D = $Particles

# =========================
# CONFIG
# =========================
const BASE_CORE_SCALE := 0.28
const SCALE_LOG_FACTOR := 0.18
const MAX_SCALE := 2.5

const PULSE_DECAY := 5.0
const PULSE_STRENGTH := 0.35

var label_container: Node2D

# =========================
# ESTADO
# =========================
var active_delta := 0.0
var pulse := 0.0
var target_tint := Color(0.15, 0.65, 1.0) # Azul base (EvoManager lo sobreescribe)
var value_label: Label

# =========================
# API PÚBLICA
# =========================
func set_active_delta(value: float) -> void:
	active_delta = max(value, 0.0)
	pulse = 1.0
	_spawn_floating_text(value)

func set_display_delta(value: float) -> void:
	active_delta = max(value, 0.0)
	if is_instance_valid(value_label):
		value_label.text = "+%.1f" % active_delta
		# Tamaño de fuente crece logarítmicamente con el poder (8px→26px de 1→1000+)
		var sz := int(clamp(log(1.0 + active_delta) * 3.0 + 8.0, 8.0, 26.0))
		value_label.add_theme_font_size_override("font_size", sz)

func set_display_text(text: String) -> void:
	if is_instance_valid(value_label):
		value_label.text = text
		value_label.add_theme_font_size_override("font_size", AccessibilityManager.fs(14))

func set_tint(c: Color) -> void:
	target_tint = c

# =========================
# LOOP
# =========================
func _ready():
	z_index = 10
	label_container = Node2D.new()
	add_child(label_container)
	
	# Inicializar tentáculos (v0.8.45)
	var tendrils = get_node_or_null("Tendrils")
	if tendrils:
		for line in tendrils.get_children():
			if line is Line2D:
				line.clear_points()
				for i in range(5):
					line.add_point(Vector2.ZERO)
					
	# Crear label estático
	value_label = Label.new()
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", AccessibilityManager.fs(30))
	value_label.add_theme_color_override("font_color", Color.WHITE)
	value_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	value_label.add_theme_constant_override("shadow_outline_size", 4)
	value_label.position = Vector2(-150, -50)
	value_label.custom_minimum_size = Vector2(300, 100)
	label_container.add_child(value_label)

func _process(delta: float) -> void:
	# Crecimiento logarítmico
	var growth := log(1.0 + active_delta) * SCALE_LOG_FACTOR
	var target_scale := BASE_CORE_SCALE + growth
	
	# Bonus por Seta Formada (v0.8.42)
	if EvoManager.seta_formada:
		target_scale *= 1.25
		
	target_scale = min(target_scale, MAX_SCALE)

	# Suavizado de la escala
	var pulse_offset := pulse * PULSE_STRENGTH
	var final_scale: float = lerp(core.scale.x, target_scale + pulse_offset, 0.2)
	core.scale = Vector2.ONE * final_scale

	# Inner core: más pequeño, pulsa más fuerte
	var inner_scale: float = lerp(core_inner.scale.x, final_scale * 0.38 + pulse * 0.18, 0.35)
	core_inner.scale = Vector2.ONE * inner_scale

	# Rotación y escala del ring (crece con el poder, más pequeño en early)
	ring.rotation += delta * (0.4 + growth * 0.2)
	var ring_target_scale: float = clamp(0.6 + growth * 0.5, 0.6, 1.6)
	ring.scale = ring.scale.lerp(Vector2.ONE * ring_target_scale, 0.05)
	pulse = max(pulse - delta * PULSE_DECAY, 0.0)

	# Color: target_tint viene siempre de EvoManager vía main.gd → set_tint()
	core.modulate = core.modulate.lerp(target_tint, 0.2)

	# Inner core más blanco/brillante — centro caliente
	var inner_tint := target_tint.lerp(Color.WHITE, 0.55)
	core_inner.modulate = core_inner.modulate.lerp(inner_tint, 0.2)

	# Ring semi-transparente + partículas coloreadas
	var ring_color := target_tint
	ring_color.a = 0.5
	ring.modulate = ring.modulate.lerp(ring_color, 0.2)
	particles.modulate = particles.modulate.lerp(target_tint, 0.15)

	# --- Animación de Tentáculos (Hifas / Cables) ---
	_update_tendrils(delta)

func _update_tendrils(_delta: float):
	var tendrils = get_node_or_null("Tendrils")
	if not tendrils: return
	
	var hifas_count = BiosphereEngine.hifas
	var time = Time.get_ticks_msec() / 1000.0
	var is_mech = EvoManager.red_branch_selected == EvoManager.RedBranch.SYMBIOSIS
	var p_active = EvoManager.primordio_active
	var final_stat = EvoManager.seta_formada or EvoManager.nucleo_conciencia
	
	var i = 0
	for line in tendrils.get_children():
		if not line is Line2D: continue
		
		# Solo visibles si desbloqueó nodo final (Nucleo o Seta) O mutó a Simbiosis/RedMicelial explícitamente y tiene suficientes hifas
		var show_tendrils = final_stat or (EvoManager.mutation_symbiosis or EvoManager.mutation_red_micelial)
		line.visible = show_tendrils and hifas_count > (3.0 if is_mech else 5.0)
		if not line.visible: continue
		
		# Color adaptado al reactor (Blanco eléctrico en Singularidad)
		var l_color = target_tint
		if is_mech and final_stat:
			l_color = Color(0.8, 1.0, 1.0, 1.0) # Blanco cian
		elif is_mech:
			l_color = Color(0.2, 0.6, 1.0, 0.7) # Azul eléctrico
			
		line.default_color = line.default_color.lerp(l_color, 0.1)
		
		# Longitud basada en hifas
		var max_len = min(20.0 + hifas_count * 3.5, 230.0)
		var angle_base = (PI * 2 / 4) * i + (time * 0.1)
		
		# --- RAMA MECÁNICA: Vibración Estática ---
		var static_noise := 0.0
		if is_mech and p_active:
			static_noise = randf_range(-5.0, 5.0) * (EvoManager.primordio_timer / 90.0)
		
		for p_idx in range(5):
			var segment_ratio = float(p_idx) / 4.0
			var segment_len = max_len * segment_ratio
			
			var target_pos : Vector2
			if is_mech:
				# Movimiento más rígido (cables de datos)
				var jitter = randf_range(-1.0, 1.0) if final_stat else 0.0
				var base_x = cos(angle_base) * segment_len
				var base_y = sin(angle_base) * segment_len
				target_pos = Vector2(base_x + jitter + static_noise, base_y + jitter + static_noise)
			else:
				# Movimiento orgánico (hifas biológicas)
				var wave = sin(time * 3.0 + segment_ratio * 4.0 + i) * (10.0 * segment_ratio)
				var angle = angle_base + (wave * 0.02)
				target_pos = Vector2(cos(angle), sin(angle)) * segment_len
			
			line.set_point_position(p_idx, target_pos)
			
		i += 1

func _spawn_floating_text(_val: float) -> void:
	pass # El número ahora queda estático en el centro del BigClickButton
