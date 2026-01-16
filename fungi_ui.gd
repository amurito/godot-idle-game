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


var hifas_unlocked := false
var nutrients := 0.0
var biomass := 0.0

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
			l.set("theme_override_colors/font_color", fungi_color)
			l.set("theme_override_colors/font_outline_color", Color(0.05, 0.0, 0.08))
			l.set("theme_override_constants/outline_size", 1)



func _ready():
	print("🍄 Biosfera online")
	apply_fungi_color()

	if btn_hifas.pressed.is_connected(_on_DesbloquearHifas_pressed):
		btn_hifas.pressed.disconnect(_on_DesbloquearHifas_pressed)

	btn_hifas.pressed.connect(_on_DesbloquearHifas_pressed)

	update_ui()


func _process(delta):
	if main == null:
		return
	if not hifas_unlocked:
		return
	var eps := float(main.epsilon_runtime)
	var mu  := float(main.get_mu_structural_factor())


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
	if hifas_unlocked:
		lbl_status.text = "Hifas: ACTIVAS"
		btn_hifas.text = "Hifas activas"
		btn_hifas.disabled = true
	else:
		lbl_status.text = "Hifas: BLOQUEADAS"
		btn_hifas.text = "Desbloquear Hifas"
		btn_hifas.disabled = false

	lbl_nutrients.text = "Nutrientes: " + str(snapped(nutrients, 0.1))
	lbl_biomass.text   = "Biomasa: " + str(snapped(biomass, 0.1))
	$Panel/VBoxContainer/Metabolismo.text = "Metabolismo: " + str(snapped(metabolism, 0.001))
	$Panel/VBoxContainer/EpsilonEff.text = "ε efectivo: " + str(snapped(epsilon_effective, 0.01))
