extends Control

# === ECONOMÍA BASE ===
var money: float = 0.0
var income_per_second: float = 0.0
var click_value: float = 1.0
var click_upgrade_cost: float = 5.0
# AUTOMÁTICO
var auto_upgrade_cost: float = 10.0
# === CLICK ESTRUCTURAL (v0.2) ===
var click_multiplier: float = 1.0
var click_multiplier_upgrade_cost: float = 100.0


# === REFERENCIAS UI (SOLO LAS QUE USAMOS) ===
@onready var money_label = $VBoxContainer/MoneyLabel
@onready var income_label = $VBoxContainer/IncomeLabel
@onready var click_button = $VBoxContainer/BigClickButton
@onready var upgrade_click_button = $VBoxContainer/UpgradeClickButton
@onready var upgrade_auto_button = $VBoxContainer/UpgradeAutoButton
@onready var stats_label = $VBoxContainer/StatsLabel
@onready var formula_label = $VBoxContainer/FormulaLabel
@onready var upgrade_click_multiplier_button = \
$VBoxContainer/UpgradeClickMultiplierButton


func _ready():
	update_ui()

func _process(delta):
	money += income_per_second * delta
	update_ui()

# === CLICK MANUAL ===
func _on_ClickButton_pressed():
	money += click_value
	update_ui()

# === MEJORAR CLICK ===
func _on_UpgradeClickButton_pressed():
	if money >= click_upgrade_cost:
		money -= click_upgrade_cost
		click_value += 1
		click_upgrade_cost *= 1.5
		update_ui()

# === MEJORAR INGRESO AUTOMÁTICO ===
func _on_UpgradeAutoButton_pressed():
	if money >= auto_upgrade_cost:
		money -= auto_upgrade_cost
		income_per_second += 1
		auto_upgrade_cost *= 1.6
		update_ui()

# === UI ===
func update_ui():
	money_label.text = "Dinero: $" + str(round(money))
	income_label.text = "Ingreso / s: $" + str(round(income_per_second))
	formula_label.text = \
	"Δ$ = clicks × (" + \
	str(snapped(click_value, 0.01)) + " × " + \
	str(snapped(click_multiplier, 0.01)) + \
	") + " + str(snapped(income_per_second, 0.01)) + " / s"

	upgrade_click_button.text = \
		"Mejorar Click (+1)\nCosto: $" + str(round(click_upgrade_cost))

	upgrade_auto_button.text = \
		"Mejorar Auto (+1/s)\nCosto: $" + str(round(auto_upgrade_cost))

	stats_label.text = \
	"Click base: +" + str(click_value) + \
	"\nMultiplicador: ×" + str(snapped(click_multiplier, 0.01)) + \
	"\nΔ$ por PUSH: +" + str(snapped(get_click_power(), 0.01))

	click_button.text = \
	"PUSH\n(+" + str(snapped(get_click_power(), 0.01)) + ")"
	upgrade_click_multiplier_button.text = \
	"Mejorar Nivel Click (×1.08)\nCosto: $" + \
	str(round(click_multiplier_upgrade_cost))

	


		


func _on_BigClickButton_pressed():
	money += get_click_power()
	update_ui()

func get_click_power() -> float:
	return click_value * click_multiplier

func _on_UpgradeClickMultiplierButton_pressed():
	if money >= click_multiplier_upgrade_cost:
		money -= click_multiplier_upgrade_cost
		click_multiplier *= 1.08
		click_multiplier_upgrade_cost *= 1.4
		update_ui()
		


func _on_upgrade_click_multiplier_button_pressed() -> void:
	pass # Replace with function body.
