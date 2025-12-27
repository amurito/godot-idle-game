extends Control

# =====================================================
#  IDLE — v0.5.1 "The Lab"
#  Propósito de esta versión:
#  • Separar economía / análisis / UI
#  • Evitar cálculos redundantes por frame
#  • Convertir el juego en laboratorio matemático
# =====================================================


# =============== ECONOMÍA BASE =======================

var money: float = 0.0


# --- CLICK (a · b · c) ---
var click_value: float = 1.0
var click_upgrade_cost: float = 5.0

var click_multiplier: float = 1.0
var click_multiplier_upgrade_cost: float = 200.0

var click_persistence: float = 1.4


# --- PRODUCTOR d ---
var income_per_second: float = 0.0
var auto_upgrade_cost: float = 10.0


# --- MODIFICADOR md ---
var auto_multiplier: float = 1.0
var auto_multiplier_upgrade_cost: float = 1200.0
const AUTO_MULTIPLIER_SCALE := 1.22
const AUTO_MULTIPLIER_GAIN := 1.05


# --- PRODUCTOR e ---
var trueque_level: int = 0
var trueque_base_income: float = 8.0
var trueque_cost: float = 3000.0
const TRUEQUE_COST_SCALE := 1.45
var trueque_efficiency: float = 0.75


# --- MODIFICADOR me ---
var trueque_network_multiplier: float = 1.0
var trueque_network_upgrade_cost: float = 6000.0
const TRUEQUE_NETWORK_GAIN := 1.12
const TRUEQUE_NETWORK_SCALE := 1.35



# ========== DESBLOQUEO PROGRESIVO DE FÓRMULA =========

var unlocked_d := false
var unlocked_md := false
var unlocked_e := false
var unlocked_me := false

const CLICK_RATE := 1.0   # clicks / s estimado humano



# ================= REFERENCIAS UI ===================

# =============== RIGHT PANEL =======================

@onready var money_label = $UIRootContainer/RightPanel/MoneyLabel
@onready var income_label = $UIRootContainer/RightPanel/IncomeLabel
@onready var stats_label = $UIRootContainer/RightPanel/StatsLabel


# =============== LEFT PANEL ========================

@onready var big_click_button = $UIRootContainer/LeftPanel/CenterPanel/BigClickButton
@onready var formula_label   = $UIRootContainer/LeftPanel/CenterPanel/FormulaLabel
@onready var click_stats_label = $UIRootContainer/LeftPanel/CenterPanel/ClickStatsLabel
@onready var marginal_label = $UIRootContainer/LeftPanel/CenterPanel/MarginalLabel


# =============== PRODUCTION PANEL ==================

@onready var upgrade_click_button = $UIRootContainer/ProductionPanel/ClickPanel/UpgradeClickButton

@onready var upgrade_click_multiplier_button = $UIRootContainer/ProductionPanel/ClickPanel/UpgradeClickMultiplierButton


@onready var upgrade_auto_button = $UIRootContainer/ProductionPanel/AutoPanel/UpgradeAutoButton

@onready var upgrade_auto_multiplier_button = $UIRootContainer/ProductionPanel/AutoPanel/UpgradeAutoMultiplierButton


@onready var upgrade_trueque_button = $UIRootContainer/ProductionPanel/TruequePanel/UpgradeTruequeButton

@onready var upgrade_trueque_network_button = $UIRootContainer/ProductionPanel/TruequePanel/UpgradeTruequeNetworkButton



# =====================================================
#  CAPA 1 — MODELO ECONÓMICO
#  (no sabe nada de UI ni texto)
# =====================================================

func get_click_power() -> float:
	return click_value * click_multiplier * click_persistence


func get_auto_income_effective() -> float:
	return income_per_second * auto_multiplier


func get_trueque_raw() -> float:
	return trueque_level * trueque_base_income * trueque_efficiency


func get_trueque_income_effective() -> float:
	return get_trueque_raw() * trueque_network_multiplier


func get_passive_total() -> float:
	return get_auto_income_effective() + get_trueque_income_effective()


func get_delta_total() -> float:
	return get_click_power() + get_passive_total()



# =====================================================
#  CAPA 2 — ANÁLISIS MATEMÁTICO DEL SISTEMA
# =====================================================

func get_dominant_term() -> String:
	var push := get_click_power()
	var d_eff := get_auto_income_effective()
	var e_eff := get_trueque_income_effective()
	var max_val: float = max(max(push, d_eff), e_eff)


	if max_val == push:
		return "CLICK domina el sistema"
	elif max_val == d_eff:
		return "Trabajo Manual domina el sistema"
	return "Trueque domina el sistema"


func get_contribution_breakdown() -> Dictionary:

	var push_ps := get_click_power() * CLICK_RATE
	var d_eff := get_auto_income_effective()
	var e_eff := get_trueque_income_effective()

	var total := push_ps + d_eff + e_eff
	if total == 0: total = 0.00001

	return {
		"click": push_ps / total * 100.0,
		"d": d_eff / total * 100.0,
		"e": e_eff / total * 100.0,
		"total": total
	}



# =====================================================
#  CAPA 3 — REPRESENTACIÓN SIMBÓLICA DE LA FÓRMULA
# =====================================================

func build_formula_text() -> String:
	var t := "Δ$ = clicks × (a × b × c)"

	# --- término d ---
	if unlocked_d:
		t += "  +  d"
		if unlocked_md:
			t += " × md"
	else:
		t += "  +  d"

	# --- término e ---
	if unlocked_e:
		t += "  +  e"
		if unlocked_me:
			t += " × me"
	else:
		t += "  +  e"

	return t



func build_formula_values() -> String:
	var t := "= clicks × (" + str(snapped(click_value, 0.01)) + " × " + str(snapped(click_multiplier, 0.01)) + " × " + str(snapped(click_persistence, 0.01)) + ")"
	if unlocked_d: t += "  +  " + str(snapped(income_per_second, 0.01)) + "/s"
	if unlocked_md: t += " × " + str(snapped(auto_multiplier, 0.01))
	if unlocked_e: t += "  +  " + str(snapped(get_trueque_raw(), 0.01)) + "/s"
	if unlocked_me: t += " × " + str(snapped(trueque_network_multiplier, 0.01))
	return t

func build_marginal_contribution() -> String:

	var t := "Aporte actual:\n"

	t += "• Click PUSH = +" + str(snapped(get_click_power(), 0.01)) + "\n"

	if unlocked_d:
		t += "• Trabajo Manual = +" +str(snapped(get_auto_income_effective(), 0.01)) + " /s\n"

	if unlocked_e:
		t += "• Trueque = +" + str(snapped(get_trueque_income_effective(), 0.01)) + " /s\n"

	t += "\nΔ$ total = +" + str(snapped(get_delta_total(), 0.01))
	t += "\n" + get_dominant_term()

	t += "\n\nUnidades:\n• Δ$ / s   tasa de crecimiento del sistema\n• d / s    trabajo manual\n• e / s    trueque corregido"


	return t



# =====================================================
#  CAPA 4 — CICLO DE VIDA
# =====================================================

func _ready():
	DisplayServer.window_set_title("IDLE — The Lab v0.5.1")
	update_ui()



func _process(delta):
	money += get_passive_total() * delta
	update_ui()



# =====================================================
#  INPUT & UPGRADES
# =====================================================

func _on_ClickButton_pressed():
	money += get_click_power()
	update_ui()

func _on_BigClickButton_pressed():
	money += get_click_power()
	big_click_button.scale = Vector2(0.95, 0.95)
	await get_tree().create_timer(0.05).timeout
	big_click_button.scale = Vector2(1, 1)
	update_ui()


# --- CLICK ---
func _on_UpgradeClickButton_pressed():
	if money < click_upgrade_cost: return
	money -= click_upgrade_cost
	click_value += 1
	click_upgrade_cost *= 1.5
	update_ui()


func _on_UpgradeClickMultiplierButton_pressed():
	if money < click_multiplier_upgrade_cost: return
	money -= click_multiplier_upgrade_cost
	click_multiplier *= 1.06
	click_multiplier_upgrade_cost *= 1.4
	update_ui()


# --- AUTO (d + md) ---
func _on_UpgradeAutoButton_pressed():
	if money < auto_upgrade_cost: return
	money -= auto_upgrade_cost
	income_per_second += 1
	auto_upgrade_cost *= 1.6
	unlocked_d = true
	update_ui()


func _on_UpgradeAutoMultiplierButton_pressed():
	if money < auto_multiplier_upgrade_cost: return
	money -= auto_multiplier_upgrade_cost
	auto_multiplier *= AUTO_MULTIPLIER_GAIN
	auto_multiplier_upgrade_cost *= AUTO_MULTIPLIER_SCALE
	unlocked_md = true
	update_ui()


# --- TRUEQUE (e + me) ---
func _on_UpgradeTruequeButton_pressed():
	if money < trueque_cost: return
	money -= trueque_cost
	trueque_level += 1
	trueque_cost *= TRUEQUE_COST_SCALE
	unlocked_e = true
	update_ui()


func _on_UpgradeTruequeNetworkButton_pressed():
	if money < trueque_network_upgrade_cost: return
	money -= trueque_network_upgrade_cost
	trueque_network_multiplier *= TRUEQUE_NETWORK_GAIN
	trueque_network_upgrade_cost *= TRUEQUE_NETWORK_SCALE
	unlocked_me = true
	update_ui()



# =====================================================
#  UI — SOLO LEE RESULTADOS (NO CALCULA)
# =====================================================

func update_ui():

	var auto_eff := get_auto_income_effective()
	var trueque_eff := get_trueque_income_effective()
	var passive_total := auto_eff + trueque_eff

	# HEADER
	money_label.text = "Dinero: $" + str(round(money))
	income_label.text = "Ingreso pasivo / s: $" + str(snapped(passive_total, 0.01))

	# BOTÓN TheLab
	#big_click_button.text = "PUSH\n(+" + str(snapped(get_click_power(), 0.01)) + ")"
	big_click_button.text = "PUSH\n(+" + str(snapped(get_click_power(), 0.01)) + ") "
	big_click_button.add_theme_color_override("font_color", Color.WHITE)

	# FÓRMULA
	formula_label.text = build_formula_text() + "\n" + build_formula_values()
	marginal_label.text = build_marginal_contribution()


	# CLICK PANEL
	click_stats_label.text = "a = " + str(snapped(click_value, 0.01)) + "    Click base\n" + "b = " + str(snapped(click_multiplier, 0.01)) + "    Multiplicador\n" + "c = " + str(snapped(click_persistence, 0.01)) + "    Persistencia\n\n" + "d = " + str(snapped(income_per_second, 0.01)) + "/s    Trabajo Manual\n" + "md = " + str(snapped(auto_multiplier, 0.01)) + "    Ritmo de trabajo\n\n" + "e = " + str(snapped(get_trueque_raw(), 0.01)) + "/s    Trueque corregido\n" + "me = " + str(snapped(trueque_network_multiplier, 0.01)) + "    Red de intercambio"

	stats_label.text = "IDLE — The Lab (v0.5.1)\n\n" + "--- Distribución de aporte ---\n"


	# BREAKDOWN
	var c := get_contribution_breakdown()

	stats_label.text = "--- Distribución de aporte ---\n" + "Click: " + str(snapped(c.click, 0.1)) + "%\n" + "Trabajo Manual: " + str(snapped(c.d, 0.1)) + "%\n" + "Trueque: " + str(snapped(c.e, 0.1)) + "%\n\n" +"Δ$ estimado / s = +" + str(snapped(c.total, 0.01))
# =====================================================

#  CORRECCIONES DE CÓDIGO AUTOMÁTICO
# =====================================================
# === CLICK PANEL ===
	upgrade_click_button.text = "Mejorar click (+" + str(snapped(click_value + 1, 0.01)) + ")\nCosto: $" + str(round(click_upgrade_cost))

	upgrade_click_multiplier_button.text = "Memoria Numérica (×1.06)\nCosto: $" + str(round(click_multiplier_upgrade_cost))


# === AUTO PANEL ===
	upgrade_auto_button.text = "Trabajo Manual (+1/s)\nCosto: $" + str(round(auto_upgrade_cost))

	upgrade_auto_multiplier_button.text = "Ritmo de Trabajo (×" + str(snapped(AUTO_MULTIPLIER_GAIN, 0.01)) + ")\nCosto: $" + str(round(auto_multiplier_upgrade_cost))


# === TRUEQUE PANEL ===
	upgrade_trueque_button.text = "Trueque (+1)\nCosto: $" + str(round(trueque_cost))

	upgrade_trueque_network_button.text = "Red de Intercambio (×" + str(snapped(TRUEQUE_NETWORK_GAIN, 0.01)) + ")\nCosto: $" + str(round(trueque_network_upgrade_cost))
