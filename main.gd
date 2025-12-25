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


# --- MODIFICADOR d — Ritmo de Trabajo ---
var auto_multiplier: float = 1.0
var auto_multiplier_upgrade_cost: float = 1200.0
const AUTO_MULTIPLIER_SCALE := 1.22
const AUTO_MULTIPLIER_GAIN := 1.05


# --- MODIFICADOR e — Red de Intercambio ---
var trueque_network_multiplier: float = 1.0
var trueque_network_upgrade_cost: float = 6000.0
const TRUEQUE_NETWORK_GAIN := 1.12
const TRUEQUE_NETWORK_SCALE := 1.35


# === REFERENCIAS UI ===

# RIGHT SIDE
@onready var money_label = $RightPanel/MoneyLabel
@onready var income_label = $RightPanel/IncomeLabel
@onready var stats_label = $RightPanel/StatsLabel
# LEFT SIDE
@onready var big_click_button = $LeftPanel/BigClickButton
@onready var formula_label = $LeftPanel/FormulaLabel
@onready var click_stats_label = $LeftPanel/ClickStatsLabel
# PANEL PRINCIPAL


# CLICK PANEL
@onready var upgrade_click_button =$ProductionPanel/ClickPanel/UpgradeClickButton

@onready var upgrade_click_multiplier_button =$ProductionPanel/ClickPanel/UpgradeClickMultiplierButton

# AUTO PANEL
@onready var upgrade_auto_button = $ProductionPanel/AutoPanel/UpgradeAutoButton

@onready var upgrade_auto_multiplier_button =$ProductionPanel/AutoPanel/UpgradeAutoMultiplierButton

# TRUEQUE PANEL
@onready var upgrade_trueque_button = $ProductionPanel/TruequePanel/UpgradeTruequeButton

@onready var upgrade_trueque_network_button = $ProductionPanel/TruequePanel/UpgradeTruequeNetworkButton


# === CICLO DE VIDA ===
func _ready():
	update_ui()


func _process(delta):
	money += (get_auto_income_effective() + get_trueque_income_effective()) * delta
	update_ui()


# === CLICK ===
func _on_ClickButton_pressed():
	money += get_click_power()
	update_ui()

func _on_BigClickButton_pressed():
	_on_ClickButton_pressed()

func get_click_power() -> float:
	return click_value * click_multiplier * click_persistence


# === CLICK UPGRADES ===
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


# === AUTO ===
func get_auto_income_effective() -> float:
	return income_per_second * auto_multiplier

func _on_UpgradeAutoButton_pressed():
	if money >= auto_upgrade_cost:
		money -= auto_upgrade_cost
		income_per_second += 1
		auto_upgrade_cost *= 1.6
		update_ui()

func _on_UpgradeAutoMultiplierButton_pressed():
	if money >= auto_multiplier_upgrade_cost:
		money -= auto_multiplier_upgrade_cost
		auto_multiplier *= AUTO_MULTIPLIER_GAIN
		auto_multiplier_upgrade_cost *= AUTO_MULTIPLIER_SCALE
		update_ui()


# === TRUEQUE ===
func get_trueque_income_effective() -> float:
	var base := trueque_level * trueque_base_income
	var eff := base * trueque_efficiency
	return eff * trueque_network_multiplier

func _on_UpgradeTruequeButton_pressed():
	if money >= trueque_cost:
		money -= trueque_cost
		trueque_level += 1
		trueque_cost *= TRUEQUE_COST_SCALE
		update_ui()

func _on_UpgradeTruequeNetworkButton_pressed():
	if money >= trueque_network_upgrade_cost:
		money -= trueque_network_upgrade_cost
		trueque_network_multiplier *= TRUEQUE_NETWORK_GAIN
		trueque_network_upgrade_cost *= TRUEQUE_NETWORK_SCALE
		update_ui()


# === UI ===
func update_ui():

	var auto_eff := get_auto_income_effective()

	var trueque_base := trueque_level * trueque_base_income
	var trueque_eff_raw := trueque_base * trueque_efficiency
	var trueque_eff_final := get_trueque_income_effective()

	var passive_total := auto_eff + trueque_eff_final


	# HEADER
	money_label.text = "Dinero: $" + str(round(money))
	income_label.text = "Ingreso pasivo / s: $" + str(snapped(passive_total, 0.01))


	# FÓRMULA HONESTA
	formula_label.text = "Δ$ = clicks × (a × b × c)  +  d × md  +  e × me"




	# BOTÓN PRINCIPAL
	big_click_button.text = "PUSH\n(+" + str(snapped(get_click_power(), 0.01)) + ")"


	# CLICK
	upgrade_click_button.text = "Conteo\nCosto: $" + str(round(click_upgrade_cost))

	upgrade_click_multiplier_button.text = "Memoria Numérica (×1.06)\nCosto: $" + str(round(click_multiplier_upgrade_cost))


	# AUTO
	upgrade_auto_button.text = "Trabajo Manual (+1/s)\nCosto: $" + str(round(auto_upgrade_cost))

	upgrade_auto_multiplier_button.text = "Ritmo de Trabajo (×" + str(snapped(AUTO_MULTIPLIER_GAIN, 0.01)) + ")\n" + "Costo: $" + str(round(auto_multiplier_upgrade_cost))


	# TRUEQUE
	upgrade_trueque_button.text = "Trueque (+1)\nCosto: $" + str(round(trueque_cost))

	upgrade_trueque_network_button.text = "Red de Intercambio (×" + str(snapped(TRUEQUE_NETWORK_GAIN, 0.01)) + ")\n" + "Costo: $" + str(round(trueque_network_upgrade_cost))


	# PANEL DE DIAGNÓSTICO

	click_stats_label.text = ("a = " + str(snapped(click_value, 0.01)) + "    Click base\n" + "b = " + str(snapped(click_multiplier, 0.01)) + "    Multiplicador\n" + "c = " + str(snapped(click_persistence, 0.01)) + "    Persistencia\n\n" + "d = " + str(snapped(income_per_second, 0.01)) + "/s    Trabajo Manual\n" + 	"md = " + str(snapped(auto_multiplier, 0.01)) + "    Ritmo de trabajo\n\n" + "e = " + str(snapped(trueque_efficiency * trueque_level * trueque_base_income, 0.01)) + "/s    Trueque corregido\n" + "me = " + str(snapped(trueque_network_multiplier, 0.01)) + "Red de intercambio"
)
	stats_label.text = ( "Auto multiplicador: ×" + str(snapped(auto_multiplier, 0.01)) + "\nAuto efectivo: +" + str(snapped(auto_eff, 0.01)) + "/s" +
	"\n\nTrueque x" + str(trueque_level) + "\nBase: +" + str(snapped(trueque_base, 0.01)) + "/s" + "\nIneficiencia: ×" + str(snapped(trueque_efficiency, 0.01)) + "\nEficiencia aplicada: +" + str(snapped(trueque_eff_raw, 0.01)) + "/s" + "\nRed de intercambio: ×" + str(snapped(trueque_network_multiplier, 0.01)) + "\nTrueque efectivo: +" + str(snapped(trueque_eff_final, 0.01)) + "/s"
)
