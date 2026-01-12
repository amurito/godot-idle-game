extends Control

# ============================
# BIOSFERA — DLC FÚNGICO
# ============================

@onready var main = get_tree().root.get_node("Main")

@onready var lbl_status    = $Panel/VBoxContainer/HifasStatus
@onready var lbl_nutrients = $Panel/VBoxContainer/Nutrientes
@onready var lbl_biomass   = $Panel/VBoxContainer/Biomasa
@onready var btn_hifas     = $Panel/VBoxContainer/DesbloquearHifas

var hifas_unlocked := false
var nutrients := 0.0
var biomass := 0.0

const NUTRIENT_FROM_EPS := 5.0
const GROWTH_RATE := 0.25


func _ready():
	print("🍄 Biosfera online")

	if btn_hifas.pressed.is_connected(_on_DesbloquearHifas_pressed):
		btn_hifas.pressed.disconnect(_on_DesbloquearHifas_pressed)

	btn_hifas.pressed.connect(_on_DesbloquearHifas_pressed)

	update_ui()


func _process(delta):
	if not hifas_unlocked:
		return

	var eps := float(main.epsilon_runtime)
	var mu  := float(main.get_mu_structural_factor())

	var nutrient_flow := eps * NUTRIENT_FROM_EPS
	nutrients += nutrient_flow * delta

	var growth := float(nutrients * GROWTH_RATE * mu * delta)
	biomass += growth
	nutrients -= growth

	update_ui()


func _on_DesbloquearHifas_pressed():
	print("🧬 BOTÓN HIFAS OK")
	hifas_unlocked = true
	update_ui()


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
