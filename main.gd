extends Control

# === ECONOMÍA BASE ===
var money: float = 0.0

# --- SISTEMA DE CLICK (manual) ---
var click_value: float = 1.0
var click_upgrade_cost: float = 5.0

var click_multiplier: float = 1.0
var click_multiplier_upgrade_cost: float = 200.0

var click_persistence: float = 1.4


# --- PRODUCTOR 1: TRABAJO MANUAL (auto básico) ---
var income_per_second: float = 0.0
var auto_upgrade_cost: float = 10.0


# --- PRODUCTOR 2: TRUEQUE (v0.3) ---
var trueque_level: int = 0
var trueque_base_income: float = 8.0
var trueque_cost: float = 3000.0
const TRUEQUE_COST_SCALE := 1.45
var trueque_efficiency: float = 0.75


# === REFERENCIAS UI ===
@onready var money_label = $VBoxContainer/MoneyLabel
@onready var income_label = $VBoxContainer/IncomeLabel
@onready var big_click_button = $VBoxContainer/BigClickButton
@onready var upgrade_click_button = $VBoxContainer/UpgradeClickButton
@onready var upgrade_auto_button = $VBoxContainer/UpgradeAutoButton
@onready var stats_label = $VBoxContainer/StatsLabel
@onready var formula_label = $VBoxContainer/FormulaLabel
@onready var upgrade_trueque_button = $VBoxContainer/UpgradeTruequeButton
@onready var upgrade_click_multiplier_button = $VBoxContainer/UpgradeClickMultiplierButton


func _ready():
	update_ui()


# === BUCLE PRINCIPAL ===
func _process(delta):
	money += (
		get_auto_income_effective()
		+ get_trueque_income_effective()
	) * delta
	update_ui()


# === CLICK MANUAL ===
func _on_ClickButton_pressed():
	money += get_click_power()
	update_ui()
# puente de compatibilidad para conexiones viejas
func _on_BigClickButton_pressed():
	_on_ClickButton_pressed()



func get_click_power() -> float:
	return click_value * click_multiplier * click_persistence



# === UPGRADES CLICK ===
func _on_UpgradeClickButton_pressed():
	if money >= click_upgrade_cost:
		money -= click_upgrade_cost
		click_value += 1
		click_upgrade_cost *= 1.5
		update_ui()


func _on_UpgradeClickMultiplierButton_pressed():
	if money >= click_multiplier_upgrade_cost:
		money -= click_multiplier_upgrade_cost
		click_multiplier *= 1.06
		click_multiplier_upgrade_cost *= 1.4
		update_ui()


# === PRODUCTOR 1: AUTO ===
func get_auto_income_effective() -> float:
	return income_per_second


func _on_UpgradeAutoButton_pressed():
	if money >= auto_upgrade_cost:
		money -= auto_upgrade_cost
		income_per_second += 1
		auto_upgrade_cost *= 1.6
		update_ui()


# === PRODUCTOR 2: TRUEQUE ===
func get_trueque_income_effective() -> float:
	var raw = trueque_level * trueque_base_income
	return raw * trueque_efficiency


func _on_UpgradeTruequeButton_pressed():
	if money >= trueque_cost:
		money -= trueque_cost
		trueque_level += 1
		trueque_cost *= TRUEQUE_COST_SCALE
		update_ui()


# === UI ===
func update_ui():

	var auto_eff := get_auto_income_effective()
	var trueque_eff := get_trueque_income_effective()

	money_label.text = "Dinero: $" + str(round(money))

	income_label.text ="Ingreso pasivo / s: $" + str(snapped(auto_eff + trueque_eff, 0.01))


	# Fórmula honesta y separada
	formula_label.text = "Δ$ = clicks × (" + str(snapped(click_value, 0.01)) + " × " + str(snapped(click_multiplier, 0.01)) + " × " + str(snapped(click_persistence, 0.01)) + ")"+ "  +  " + str(snapped(auto_eff, 0.01)) + " /s" + "  +  " + str(snapped(trueque_eff, 0.01)) + " /s"



	big_click_button.text = "PUSH\n(+" + str(snapped(get_click_power(), 0.01)) + ")"

	upgrade_click_button.text = "Conteo\nCosto: $" + str(round(click_upgrade_cost))

	upgrade_click_multiplier_button.text = "Memoria Numérica (×1.06)\nCosto: $" + str(round(click_multiplier_upgrade_cost))

	upgrade_auto_button.text = "Trabajo Manual (+1/s)\nCosto: $" + str(round(auto_upgrade_cost))

	upgrade_trueque_button.text ="Trueque (+1)\nCosto: $" + str(round(trueque_cost))


	# Panel de diagnóstico claro
	stats_label.text = "Click base: +" + str(click_value) + "\nMultiplicador: ×" + str(snapped(click_multiplier, 0.01)) + "\nPersistencia: ×" + str(snapped(click_persistence, 0.01)) + "\nΔ$ por PUSH: +" + str(snapped(get_click_power(), 0.01)) + "\n\nAuto: +" + str(snapped(auto_eff, 0.01)) + "/s"
