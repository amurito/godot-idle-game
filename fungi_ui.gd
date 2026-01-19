extends Control

# ============================
# BIOSFERA — DLC FÚNGICO
# ============================
func set_main(m):
	main = m
var main : Node = null


@onready var lbl_status    = $Panel/VBoxContainer/HifasStatus
@onready var lbl_nutrients = $Panel/VBoxContainer/Nutrientes
@onready var lbl_biomass   = $Panel/VBoxContainer/Biomasa
@onready var btn_hifas     = $Panel/VBoxContainer/DesbloquearHifas
@export var fungi_color : Color = Color(0.78, 0.3, 1.0) # violeta micelial
@export var fungi_color_active   = Color(0.78, 0.3, 1.0)
@export var fungi_color_blocked  = Color(0.35, 0.2, 0.45)


var hifas_unlocked := false
var nutrients := 0.0
var biomass := 0.0
var pulse := 0.0
var mutation_hyperassimilation := false
const BIOMASS_MIN := 500.0


# --- Salidas físicas hacia el sistema ---
var epsilon_effective := 0.0
var metabolism := 0.0

const NUTRIENT_FROM_EPS := 5.0
const GROWTH_RATE := 0.25

func apply_fungi_color():
	var labels = [
		lbl_status,
		lbl_nutrients,
		lbl_biomass,
		$Panel/VBoxContainer/Metabolismo,
		$Panel/VBoxContainer/EpsilonEff
	]

	for l in labels:
		if l:
			l.add_theme_color_override("font_color", fungi_color)
			l.add_theme_color_override("font_outline_color", Color(0.1, 0.0, 0.15))
			l.add_theme_constant_override("outline_size", 2)
func activate_hyperassimilation():
	mutation_hyperassimilation = true
	print("🧬 MUTACIÓN ACTIVADA: HIPERASIMILACIÓN")


func _ready():
	print("🍄 Biosfera online")
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
		if main.epsilon_runtime > 0.4 \
		and main.get_delta_total() > 5.0 \
		and main.get_mu_structural_factor() < 1.2:
			hifas_unlocked = true
			update_ui()
		return  # ⬅️ todavía no procesamos metabolismo

	# --- A partir de acá, hifas activas ---
	var eps := float(main.epsilon_runtime)
	var mu  := float(main.get_mu_structural_factor())
	if not mutation_hyperassimilation:
		if main.epsilon_runtime > 0.6 and main.get_flexibility() < 0.05 and biomass > BIOMASS_MIN:
			activate_hyperassimilation()

		# 1) Nutrientes = entropía económica
	var nutrient_flow := eps * NUTRIENT_FROM_EPS
	nutrients += nutrient_flow * delta
		# 2) Biomasa = entropía fijada
	var growth := float(nutrients * GROWTH_RATE * mu * delta)
	biomass += growth
	nutrients -= growth
	# 3) Termodinámica del sistema
	
	epsilon_effective = eps / (1.0 + biomass)

	# metabolismo = qué tan bien el sistema digiere su propia producción
	var delta_money := float(main.get_delta_total())
	if delta_money > 0:
		metabolism = biomass / delta_money
	else:
		metabolism = 0.0
	pulse += delta * 2.0
	var breathe = 0.5 + sin(pulse) * 0.05

	$Panel.modulate = Color(1, 1, 1, breathe)
	update_ui()


func _on_DesbloquearHifas_pressed():
	print("🧬 BOTÓN HIFAS OK")
	hifas_unlocked = true
	update_ui()
func get_biomass() -> float:
	return biomass

func absorb_epsilon(epsilon_runtime):
	var absorption = clamp(epsilon_runtime * 0.4, 0.0, epsilon_runtime)
	epsilon_effective = epsilon_runtime - absorption
	main.nutrientes += absorption * 5.0
func get_visual_strength() -> float:
	return clamp(log(1.0 + biomass) / 3.0, 0.0, 1.0)

func update_ui():
	
	btn_hifas.visible = false
	if hifas_unlocked:
		lbl_status.text = "🟣 Hifas: ACTIVAS"
		lbl_status.modulate = fungi_color
	else:
		lbl_status.text = "⚫ Hifas: BLOQUEADAS"
		lbl_status.modulate = Color(fungi_color, 0.6)

	lbl_nutrients.text = "Nutrientes: " + str(snapped(nutrients, 0.1))
	lbl_biomass.text   = "Biomasa: " + str(snapped(biomass, 0.1))
	$Panel/VBoxContainer/Metabolismo.text = "Metabolismo: " + str(snapped(metabolism, 0.001))
	$Panel/VBoxContainer/EpsilonEff.text = "ε efectivo: " + str(snapped(epsilon_effective, 0.01))
	if mutation_hyperassimilation:
		lbl_status.text = "Hifas: HIPERASIMILACIÓN"