extends Node2D

# =========================
# NODOS
# =========================
@onready var core: Node2D = $Core
@onready var ring: Node2D = $Ring

# =========================
# CONFIG
# =========================
# =========================
# CONFIG
# =========================
const BASE_CORE_SCALE := 0.35      # Empieza más chico
const SCALE_LOG_FACTOR := 0.22    # Crecimiento logarítmico para ser más "premium"
const MAX_SCALE := 3.5

const PULSE_DECAY := 5.0
const PULSE_STRENGTH := 0.35

var label_container: Node2D

# =========================
# ESTADO
# =========================
var active_delta := 0.0
var pulse := 0.0
var mutation_state := "default"
var target_tint := Color(1, 1, 1)

# =========================
# API PÚBLICA
# =========================
func set_active_delta(value: float) -> void:
	active_delta = max(value, 0.0)
	pulse = 1.0
	_spawn_floating_text(value)

func set_display_delta(value: float) -> void:
	active_delta = max(value, 0.0)

func set_mutation_state(state: String) -> void:
	mutation_state = state

func set_tint(c: Color) -> void:
	target_tint = c

# =========================
# LOOP
# =========================
func _ready():
	z_index = 10
	label_container = Node2D.new()
	add_child(label_container)

func _process(delta: float) -> void:
	# Crecimiento logarítmico: crece mucho al principio, suave después
	var growth := log(1.0 + active_delta) * SCALE_LOG_FACTOR
	var target_scale := BASE_CORE_SCALE + growth
	target_scale = min(target_scale, MAX_SCALE)

	# Suavizado de la escala
	var pulse_offset := pulse * PULSE_STRENGTH
	var final_scale = lerp(core.scale.x, target_scale + pulse_offset, 0.2)
	core.scale = Vector2.ONE * final_scale

	# Rotación y Pulso
	ring.rotation += delta * (0.4 + growth * 0.2)
	pulse = max(pulse - delta * PULSE_DECAY, 0.0)

	# Colores según mutación
	var color_target := target_tint
	match mutation_state:
		"hyperassimilation": color_target = Color(1.0, 0.2, 0.7) # Rosa fuerte
		"homeostasis": color_target = Color(0.4, 0.8, 1.0) # Celeste puro
		"symbiosis": color_target = Color(0.6, 1.0, 0.4) # Verde vida
		"parasitismo": color_target = Color(1.0, 0.5, 0.2) # Naranja/Cobre (Drenaje)
	
	core.modulate = core.modulate.lerp(color_target, 0.1)

func _spawn_floating_text(val: float) -> void:
	var lbl = Label.new()
	lbl.text = "+%.1f" % val
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Estilo premium
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
	lbl.add_theme_constant_override("shadow_outline_size", 4)
	
	label_container.add_child(lbl)
	lbl.position = Vector2(-50, -20) # Centrado aproximado
	
	# Animación simple
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 60, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.8).set_delay(0.2)
	tw.tween_callback(lbl.queue_free).set_delay(1.0)
