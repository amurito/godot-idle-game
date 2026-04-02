extends Control

# ============================
# BIOSFERA — DLC FÚNGICO
# ============================
func set_main(m):
	main = m
var main : Node = null
func _propagate_mouse_ignore(node: Node):
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in node.get_children():
		_propagate_mouse_ignore(c)

@onready var lbl_status    = $Panel/VBoxContainer/HifasStatus
@onready var lbl_nutrients = $Panel/VBoxContainer/Nutrientes
@onready var lbl_biomass   = $Panel/VBoxContainer/Biomasa
@onready var btn_hifas     = $Panel/VBoxContainer/DesbloquearHifas
@export var fungi_color : Color = Color(0.78, 0.3, 1.0) # violeta micelial
@export var fungi_color_active   = Color(0.78, 0.3, 1.0)
@export var fungi_color_blocked  = Color(0.35, 0.2, 0.45)


var hifas_unlocked := false
var pulse := 0.0

# --- Salidas físicas hacia el sistema ---
var metabolism := 0.0

func apply_fungi_color():
	var labels = [
		lbl_status,
		lbl_nutrients,
		lbl_biomass,
		$Panel/VBoxContainer/Metabolismo,
		$Panel/VBoxContainer/EpsilonEff,
		$Panel/VBoxContainer/Esporas
	]

	for l in labels:
		if l:
			l.add_theme_color_override("font_color", fungi_color)
			l.add_theme_color_override("font_outline_color", Color(0.1, 0.0, 0.15))
			l.add_theme_constant_override("outline_size", 2)


func _ready():
	print("🍄 Biosfera online")
	# 🔒 FIX DEFENSIVO DE INPUT (CLAVE)
	_propagate_mouse_ignore(self)

	# 🔓 Re-habilitamos SOLO el botón interactivo
	btn_hifas.mouse_filter = Control.MOUSE_FILTER_STOP
	apply_fungi_color()
	btn_hifas.visible = false


	if btn_hifas.pressed.is_connected(_on_DesbloquearHifas_pressed):
		btn_hifas.pressed.disconnect(_on_DesbloquearHifas_pressed)

	btn_hifas.pressed.connect(_on_DesbloquearHifas_pressed)
	lbl_status.add_theme_constant_override("outline_size", 3)
	lbl_status.add_theme_color_override("font_outline_color", Color(0.2, 0.0, 0.3))

	update_ui()


func _process(delta):
	if main == null:
		return

	# 🔓 Emergencia metabólica
	if not hifas_unlocked:
		# Si ya hay biomasa (de un save o por crecimiento invisible), desbloquear
		if BiosphereEngine.biomasa > 0.1:
			hifas_unlocked = true
			update_ui()
			return

		if main.epsilon_runtime > 0.38 \
		and main.get_delta_total() > 5.0:
			hifas_unlocked = true
			update_ui()
		return  # ⬅️ todavía no procesamos metabolismo

	# --- A partir de acá, hifas activas ---
	# La UI solo lee datos de BiosphereEngine, ya no los calcula ella misma
	
	var biomass = BiosphereEngine.biomasa

	# metabolismo = qué tan bien el sistema digiere su propia producción
	var delta_money := float(main.get_delta_total())
	if delta_money > 0:
		metabolism = biomass / delta_money
	else:
		metabolism = 0.0
	pulse += delta * 2.5
	var breathe = 0.6 + sin(pulse) * 0.15
	
	# El panel respira más fuerte si hay mucha biomasa
	var intensity = 0.5 + clamp(BiosphereEngine.biomasa / 10.0, 0.0, 0.5)
	$Panel.modulate = Color(1, 1, 1, breathe * intensity)
	
	# Brillo de los labels
	for l in [lbl_status, lbl_nutrients, lbl_biomass]:
		if l:
			l.modulate.a = 0.8 + sin(pulse * 1.5) * 0.2

	update_ui()


func _on_DesbloquearHifas_pressed():
	print("🧬 BOTÓN HIFAS OK")
	hifas_unlocked = true
	update_ui()
func get_biomass() -> float:
	return BiosphereEngine.biomasa

func absorb_epsilon(_epsilon_runtime):
	# Obsoleto: BiosphereEngine ahora maneja esto directamente
	pass
	
func get_visual_strength() -> float:
	return clamp(log(1.0 + BiosphereEngine.biomasa) / 3.0, 0.0, 1.0)

func get_min_height() -> float:
	return size.y if size.y > 0 else custom_minimum_size.y

func update_ui():
	
	btn_hifas.visible = false
	var current_color = fungi_color
	if EvoManager.mutation_hyperassimilation:
		lbl_status.text = "🟣 HIFAS: %s (H-A)" % snapped(BiosphereEngine.hifas, 0.1)
		current_color = Color(1.0, 0.2, 0.8) # Rosa neón más fuerte
	elif hifas_unlocked:
		lbl_status.text = "🟣 Hifas: %s" % snapped(BiosphereEngine.hifas, 0.1)
		current_color = fungi_color
	else:
		lbl_status.text = "⚫ Hifas: BLOQUEADAS"
		current_color = Color(fungi_color, 0.4)

	lbl_status.modulate = current_color
	
	# Aplicar el color actual a todos los labels del panel
	for l in [lbl_nutrients, lbl_biomass, $Panel/VBoxContainer/Metabolismo, $Panel/VBoxContainer/EpsilonEff, $Panel/VBoxContainer/Esporas]:
		if l:
			l.modulate = current_color

	lbl_nutrients.text = "Nutrientes: " + str(snapped(BiosphereEngine.nutrientes, 0.1))
	lbl_biomass.text   = "Biomasa: " + str(snapped(BiosphereEngine.biomasa, 0.1))
	$Panel/VBoxContainer/Metabolismo.text = "Metabolismo: " + str(snapped(metabolism, 0.001))
	$Panel/VBoxContainer/EpsilonEff.text = "ε efectivo: " + str(snapped(BiosphereEngine.epsilon_effective, 0.01))
	
	# Estimación de esporas
	var est_spores = BiosphereEngine.biomasa * 0.8
	if EvoManager.seta_formada: est_spores *= 3.0
	$Panel/VBoxContainer/Esporas.text = "Esporas est.: " + str(snapped(est_spores, 0.1))
