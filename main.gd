extends Control

# =====================================================
# IDLE — v0.7 — “k_eff · Cognitive Structural Growth”
#HUD limpio y no redundante
#μ movido a bloque único (Capital Cognitivo)
#k_eff(μ) → μ impacta estructura (no solo output)
#convergencia perceptible en pocas upgrades
#export estructurado por capas
#estabilidad del modelo ε
#preserva curva base sin romper progresión
# k_eff = k · (1 + α · (μ − 1))
# fⁿ = c₀ · k_eff^(1 − 1/n)
# ε(modelo) = | fⁿ − cₙ(modelo) |
# =====================================================
#dlc
const FUNGI_UI_SCENE = preload("res://fungi.tscn")
var fungi_ui: Control


# =============== ECONOMÍA BASE =======================

var money: float = 0.0


# --- CLICK (a · b · c) ---
var click_value: float = 1.0
var click_upgrade_cost: float = 5.0

var click_multiplier: float = 1.0
var click_multiplier_upgrade_cost: float = 200.0

# Persistencia base estructural (c₀)
var persistence_base: float = 10.4
# Estado dinámico observado (cₙ)
var persistence_dynamic: float = 1.4


# --- PRODUCTOR d ---
var income_per_second: float = 0.0
var auto_upgrade_cost: float = 10.0


# --- MODIFICADOR md ---
var auto_multiplier: float = 1.0
var auto_multiplier_upgrade_cost: float = 1200.0
const AUTO_MULTIPLIER_SCALE := 1.20
const AUTO_MULTIPLIER_GAIN := 1.06


# --- ESPECIALIZACIÓN DE OFICIO (buff estructural d) v0.6.1---
var manual_specialization: float = 1.0
var specialization_cost := 9000.0
const SPECIALIZATION_GAIN := 1.10
const SPECIALIZATION_SCALE := 1.35
var specialization_level: int = 0


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


# --- PERSISTENCIA estructural — fⁿ (observacional) ---
var structural_upgrades: int = 1
const K_PERSISTENCE := 1.25

# === CAPITAL COGNITIVO (μ) === v0.7
var cognitive_level := 0
var cognitive_mu := 1.0
var cognitive_cost: float = 15000.0
var cognitive_cost_scale: float = 1.45

const COGNITIVE_COST := 15000.0
const COGNITIVE_COST_SCALE := 1.45
const COGNITIVE_MULTIPLIER := 0.05
# μ dinámico observado (bloque unico en HUD)
var mu_structural: float = 1.0
# α constante para k_eff(μ)
const ALPHA_KAPPA := 0.55

## =====================================================
# =====================================================
#  MÉTRICAS ESTRUCTURALES v0.7.2
# =====================================================

var epsilon_runtime: float = 0.0
var epsilon_peak: float = 0.0

var delta_per_sec: float = 0.0
var total_money_generated: float = 0.0

var baseline_delta_structural: float = 0.0
var last_stable_structural_upgrades: int = 0

var pressure := 0.0
var pressure_structural := 0.0

var institutions_unlocked: bool = false
var show_institutions_panel: bool = false

# Cooldown estructural (clave para ε_runtime)
var structural_cooldown := 0.0
const STRUCTURAL_COOLDOWN_TIME := 8.0
var omega := 1.0
var omega_min := 1.0
var institution_accounting_unlocked := false

#	=============================================
#  CAPA 4 — INSTITUCIONES (v0.8)
var accounting_level := 0
var accounting_effect := 0.0
var accounting_base_cost := 50000.0
var accounting_cost_scale := 2.0

#
### DLC FUNGI — constantes 
var FUNGI_MU_BETA := fungi_plasticity # impacto en μ
# =====================================================
var epsilon_effective := 0.0


# =============== SESIÓN / LAB MODE ===================

var run_time: float = 0.0
var lab_mode := true

var lap_events: Array = []
var last_dominance := ""

var RUN_EXPORT_PATH := OS.get_user_data_dir() + "/IDLE_Fungi/runs"

# ========== DESBLOQUEO PROGRESIVO DE FÓRMULA =========

var unlocked_d := false
var unlocked_md := false
var unlocked_e := false
var unlocked_me := false

const CLICK_RATE := 1.0 # clicks / s estimado humano

# === VERSION INFO ===
const VERSION := "0.7"
const CODENAME := "v0.7 — “μ (Capital Cognitivo)”"
const BUILD_CHANNEL := "stable"

# =====================================================
#  ACHIEVEMENTS / LOGROS WIP

var unlocked_tree := false
var unlocked_click_dominance := false
var unlocked_delta_100 := false


# ================= REFERENCIAS UI ===================
# PANEL — SISTEMA / DIAGNÓSTICO
@onready var money_label = $UIRootContainer/RightPanel/ScrollContainer/VBoxContainer/MoneyLabel
@onready var income_label = $UIRootContainer/RightPanel/ScrollContainer/VBoxContainer/IncomeLabel
# nuevo bloque consolidado
@onready var system_state_label = $UIRootContainer/RightPanel/ScrollContainer/VBoxContainer/SystemStateLabel
# logs / laps
@onready var lap_log_label = $UIRootContainer/RightPanel/ScrollContainer/VBoxContainer/LapLogLabel

@onready var export_run_button = $UIRootContainer/RightPanel/ScrollContainer/VBoxContainer/ExportRunButton
#PANEL — PRODUCCIÓN / MODELO
@onready var big_click_button = $UIRootContainer/LeftPanel/CenterPanel/BigClickButton
@onready var formula_label = $UIRootContainer/LeftPanel/CenterPanel/FormulaLabel
@onready var marginal_label = $UIRootContainer/LeftPanel/CenterPanel/MarginalLabel
# HUD científico (scroll)
@onready var click_stats_label = $UIRootContainer/LeftPanel/CenterPanel/ClickStatsScroll/ClickStatsLabel

@onready var upgrade_click_button = $UIRootContainer/ProductionPanel/ClickPanel/UpgradeClickButton
@onready var upgrade_click_multiplier_button = $UIRootContainer/ProductionPanel/ClickPanel/UpgradeClickMultiplierButton
@onready var persistence_upgrade_button = $UIRootContainer/ProductionPanel/ClickPanel/PersistenceUpgradeButton

@onready var upgrade_auto_button = $UIRootContainer/ProductionPanel/AutoPanel/UpgradeAutoButton
@onready var upgrade_auto_multiplier_button = $UIRootContainer/ProductionPanel/AutoPanel/UpgradeAutoMultiplierButton
@onready var specialization_button = $UIRootContainer/ProductionPanel/AutoPanel/UpgradeSpecializationButton

@onready var upgrade_trueque_button = $UIRootContainer/ProductionPanel/TruequePanel/UpgradeTruequeButton
@onready var upgrade_trueque_network_button = $UIRootContainer/ProductionPanel/TruequePanel/UpgradeTruequeNetworkButton

@onready var sys_delta_label = $UIRootContainer/RightPanel/ScrollContainer/VBoxContainer/SystemDeltaLabel

@onready var sys_breakdown_label = $UIRootContainer/RightPanel/ScrollContainer/VBoxContainer/SystemBreakdownLabel

@onready var sys_active_passive_label = $UIRootContainer/RightPanel/ScrollContainer/VBoxContainer/SystemActivePassiveLabel

@onready var session_time_label = $UIRootContainer/RightPanel/ScrollContainer/VBoxContainer/SessionTimeLabel

@onready var lap_markers_label = $UIRootContainer/RightPanel/ScrollContainer/VBoxContainer/LapMarkersLabel

@onready var system_message_label = $UIRootContainer/RightPanel/ScrollContainer/VBoxContainer/SystemMessageLabel

@onready var system_achievements_label = $UIRootContainer/RightPanel/ScrollContainer/VBoxContainer/SystemAchievementsLabel

@onready var upgrade_cognitive_button = $UIRootContainer/ProductionPanel/CapitalProductivoPanel/UpgradeCognitiveButton

@onready var cognitive_mu_label = $UIRootContainer/ProductionPanel/CapitalProductivoPanel/CognitiveMuLabel

@onready var institution_panel_label = $UIRootContainer/RightPanel/ScrollContainer/VBoxContainer/InstitutionPanelLabel
@onready var upgrade_accounting_button = $UIRootContainer/ProductionPanel/CapitalProductivoPanel/UpgradeAccountingButton

@onready var fungi_ui_scene = preload("res://fungi.tscn")
@onready var ui_root = $UIRootContainer

# =====================================================
#  CAPA 1 — MODELO ECONÓMICO
# =====================================================

func get_click_power() -> float:
	return click_value * click_multiplier * persistence_dynamic * get_mu_structural_factor()

func get_auto_income_effective() -> float:
	var base = income_per_second * auto_multiplier * manual_specialization * get_mu_structural_factor() * get_biomass_beta()
	return base * (1.0 + accounting_level * 0.05)
func get_trueque_raw() -> float:
	return trueque_level * trueque_base_income * trueque_efficiency

func get_trueque_income_effective() -> float:
	var base = get_trueque_raw() * trueque_network_multiplier * get_mu_structural_factor() * get_biomass_beta()
	return base * (1.0 + accounting_level * 0.05)

func get_passive_total() -> float:
	return get_auto_income_effective() + get_trueque_income_effective()

func get_delta_total() -> float:
	return get_click_power() + get_passive_total()

func get_mu_structural_factor(n: int = cognitive_level) -> float:
	# μ cognitivo (tu diseño original)
	var mu_base := 1.0
	if n > 0:
		mu_base = 1.0 + log(1.0 + float(n)) * 0.08

	# μ fúngico (biomasa)
	var mu_fungi := 1.0
	if fungi_ui != null and fungi_ui.has_method("get_biomass"):
		var b := float(fungi_ui.get_biomass())
		mu_fungi = 1.0 + log(1.0 + b) * fungi_plasticity

	return mu_base * mu_fungi
# === GENES FÚNGICOS ===
var fungi_absorption := 0.15 # cuánto ε se disipa
var fungi_efficiency := 0.03 # fuerza de get_biomass_beta()
var fungi_plasticity := 0.05 # cuánto afecta a μ
# ===== BIOSFERA =====
var biomasa := 0.0
var nutrientes := 0.0
var hifas := 0.0

func get_biomass_beta() -> float:
	return 1.0 + log(1.0 + biomasa) * fungi_efficiency
#
# =====================================================
#  ACTUALIZACIÓN BIOSFERA v0.8DLC
func update_biosphere(delta):
	if hifas <= 0 or nutrientes <= 0:
		return

	var biomass_gain = hifas * sqrt(nutrientes) * 0.02 * delta
	biomasa += biomass_gain

	nutrientes -= biomass_gain * 0.5
	nutrientes = max(nutrientes, 0)

	var eps_absorbed = biomass_gain * fungi_absorption
	epsilon_effective = max(0.0, epsilon_runtime - eps_absorbed)
# =====================================================
#  CÁLCULO HIFAS v0.8 DLC
func compute_hifas() -> float:
	var passive = get_passive_total()
	if passive <= 0:
		return 0.0
	return pow(passive, 0.6)
# =====================================================
# CÁLCULO NUTRIENTES v0.8 DLC
func update_nutrients(delta):
	var absorbed := float(epsilon_runtime - epsilon_effective)
	nutrientes += absorbed * 5.0 * delta
# ============================
#  GENOMA FÚNGICO — v0.1
# ============================

var genome := {
	"hiperasimilacion": "dormido",
	"parasitismo": "dormido",
	"red_micelial": "dormido",
	"esporulacion": "dormido",
	"simbiosis": "dormido"
}

func update_genome():
	# HIPERASIMILACIÓN
	if epsilon_runtime > 0.6 and biomasa > 5.0:
		genome.hiperasimilacion = "activo"
	elif epsilon_runtime > 0.3:
		genome.hiperasimilacion = "latente"
	else:
		genome.hiperasimilacion = "dormido"

	# PARASITISMO (biomasa alta drenando economía)
	if biomasa > 15.0 and get_delta_total() > 0:
		genome.parasitismo = "activo"
	elif biomasa > 5.0:
		genome.parasitismo = "latente"
	else:
		genome.parasitismo = "dormido"

	# RED MICELIAL (estructura pasiva estable)
	if hifas > 8.0 and epsilon_runtime < 0.25:
		genome.red_micelial = "activo"
	elif hifas > 3.0:
		genome.red_micelial = "latente"
	else:
		genome.red_micelial = "dormido"

	# ESPORULACIÓN (sistema bajo estrés)
	var bio_pressure := get_structural_pressure()
	if bio_pressure > 20.0:
		genome.esporulacion = "activo"
	elif bio_pressure > 8.0:
		genome.esporulacion = "latente"
	else:
		genome.esporulacion = "dormido"

	# SIMBIOSIS (contabilidad + hifas)
	if accounting_level > 0 and hifas > 5.0:
		genome.simbiosis = "activo"
	elif accounting_level > 0:
		genome.simbiosis = "latente"
	else:
		genome.simbiosis = "dormido"

# =====================================================
#  FORMATO TEXTO FÓRMULA
# =====================================================

func build_formula_text() -> String:
	var t := "∫$ = clicks · (a · b · cₙ )"

	# --- d (Trabajo Manual)
	if unlocked_d:
		t += "  +  d"
		
		# md aparece solo cuando está desbloqueado
		if unlocked_md:
			t += " · md"
		
		# so aparece solo si hay especialización real
		if specialization_level > 0:
			t += " · so"

	# --- e (Trueque)
	if unlocked_e:
		t += "  +  e"

		# me aparece solo si existe red
		if unlocked_me:
			t += " · me"

	t += "\nfⁿ = c₀ · κμ^(1 − 1/n)"
	t += "\n\nκμ = k · (1 + α · (μ − 1))"

	return t

# formula con valores
func build_formula_values() -> String:
	var c0 := float(snapped(persistence_base, 0.01))
	var cn = float(snapped(persistence_dynamic, 0.01))
	var mu = float(snapped(get_mu_structural_factor(), 0.01))
	var n_struct = float(structural_upgrades)

	return "c₀ = %s   cₙ = %s   μ = %s   n = %d" % [c0, cn, mu, n_struct]


func build_marginal_contribution() -> String:
	var t := "Aporte actual:\n"
	t += "• Click PUSH = +" + str(snapped(get_click_power(), 0.01)) + "\n"
	if unlocked_d: t += "• Trabajo Manual = +" + str(snapped(get_auto_income_effective(), 0.01)) + " /s\n"
	if unlocked_e: t += "• Trueque = +" + str(snapped(get_trueque_income_effective(), 0.01)) + " /s\n"

	t += "\nΔ$ total = +" + str(snapped(get_delta_total(), 0.01))
	t += "\n" + get_dominant_term()
	return t
# ===============================
#   HUD CIENTÍFICO — segmentado por capas
# ===============================
func update_click_stats_panel() -> void:
	var hud := ""

	# ===== CAPA 1 - PRODUCCIÓN ACTIVA =====
	hud += "=== Producción activa ===\n"
	hud += "a = %s    Click base\n" % snapped(click_value, 0.01)
	hud += "b = %s    Multiplicador\n" % snapped(click_multiplier, 0.01)
	hud += "cₙ(actual) = %s\n\n" % snapped(persistence_dynamic, 0.01)

	# ===== CAPA 2 - PRODUCTORES =====
	if unlocked_d:
		hud += "d = %s/s    Trabajo Manual\n" % snapped(income_per_second, 0.01)
	else:
		hud += "d = — (no descubierto)\n"

	if unlocked_md:
		hud += "md = %s    Ritmo de Trabajo\n" % snapped(auto_multiplier, 0.01)
	elif unlocked_d:
		hud += "md = — (estructura latente)\n"

	if specialization_level > 0:
		hud += "so = %s    Especialización de Oficio\n" % snapped(manual_specialization, 0.01)

	hud += "\n"

	if unlocked_e:
		hud += "e = %s/s    Trueque corregido\n" % snapped(get_trueque_raw(), 0.01)
	else:
			hud += "e = — (no descubierto)\n"
			
	if unlocked_me:
				hud += "me = %s    Red de intercambio\n" % snapped(trueque_network_multiplier, 0.01)
	elif unlocked_e:
		hud += "me = — (estructura latente)\n"
	

	# ===== HUD ROSA(modelo) =====
	var m = update_structural_hud_model_block()

	var k_eff = m.k_eff

	hud += "\n--- MODELO ESTRUCTURAL ---\n"
	hud += "\nμ = %s\n" % snapped(get_mu_structural_factor(), 0.01)
	hud += "k = %s\n" % snapped(K_PERSISTENCE, 0.01)
	hud += "α = %s\n" % ALPHA_KAPPA
	hud += "κμ = %s\n" % snapped(k_eff, 0.01)
	hud += "n = %d\n" % int(m.n)

	hud += "\n--- Capital Cognitivo ---\n"
	hud += "μ = %s\n" % snapped(get_mu_structural_factor(), 0.01)
	hud += "Nivel cognitivo = %d\n" % cognitive_level
	hud += "\n--- Modelo estructural ---\n"
	hud += "cₙ(modelo) = %s\n" % snapped(m.c_n_model, 0.01)
	hud += "ε(modelo) = %s\n" % snapped(m.eps_model, 0.001)

	# 🚨 SIN ESTO EL PANEL NO MUESTRA NADA
	click_stats_label.text = hud


# =====================================================
#  CAPA 2 — ANÁLISIS MATEMÁTICO
# =====================================================

func get_dominant_term() -> String:
	var p := get_click_power()
	var d := get_auto_income_effective()
	var e := get_trueque_income_effective()
	var m: float = float(max(max(p, d), e))

	if m == p: return "CLICK domina el sistema"
	if m == d: return "Trabajo Manual domina el sistema"
	return "Trueque domina el sistema"


func get_contribution_breakdown() -> Dictionary:
	var push := get_click_power() * CLICK_RATE
	var d := get_auto_income_effective()
	var e := get_trueque_income_effective()

	var total := push + d + e
	if total == 0: total = 0.00001

	return {
		"click": push / total * 100.0,
		"d": d / total * 100.0,
		"e": e / total * 100.0,
		"total": total
	}


func get_active_passive_breakdown() -> Dictionary:
	var push := get_click_power() * CLICK_RATE
	var passive := get_auto_income_effective() + get_trueque_income_effective()

	var total := push + passive
	if total == 0: total = 0.00001

	return {
		"activo": push / total * 100.0,
		"pasivo": passive / total * 100.0,
		"push_abs": push,
		"passive_abs": passive,
		"total": total
	}


# =====================================================
#  CAPA 3 — fⁿ (OBSERVACIONAL) v0.6.2
# =====================================================


func get_n_log() -> float:
	return 1.0 + log(1.0 + structural_upgrades)

func get_n_power() -> float:
	return pow(structural_upgrades + 1.0, 0.35)


# =====================================================
#  FUNCIÓN SIGMOIDE fⁿ α V0.6.2
# =====================================================
func f_n_alpha(n: float) -> float:
	return 1.0 / (1.0 + exp(-0.35 * (n - 6.0)))

func apply_dynamic_persistence(delta: float) -> void:
	var n_struct := float(structural_upgrades)

	# valor teórico esperado
	var target := get_persistence_target()

	# peso sigmoide — transición suave
	var a := f_n_alpha(n_struct)

	# converge sin overshoot
	persistence_dynamic = lerp(
		persistence_dynamic,
		target,
		clamp(a * delta * 0.4, 0.0, 0.25)
	)


# === Persistencia estructural ===
# c₀  → baseline fijo
# fⁿ  → objetivo teórico según n
# cₙ  → estado dinámico observado

func get_persistence_target() -> float:
	if structural_upgrades <= 1:
		return persistence_base

	var n_struct := get_effective_structural_n()
	var k_eff := get_k_eff()
	return persistence_base * pow(k_eff, (1.0 - 1.0 / n_struct))

func get_cognitive_mu() -> float:
	cognitive_mu = 1.0 + log(1.0 + cognitive_level) * COGNITIVE_MULTIPLIER
	return snapped(cognitive_mu, 0.01)


# =====================================================
#  MODELO ESTRUCTURAL — v0.6.4
#  fⁿ(teórico), cₙ(teórico), ε(modelo)
# =====================================================

func compute_structural_model() -> Dictionary:
	var n_struct := get_effective_structural_n()


	# k ajustado por μ
	var k_eff := get_k_eff()

	# fⁿ(teórico) — sigue alineado al target de persistencia
	var f_n_model := persistence_base * pow(k_eff, (1.0 - 1.0 / max(n_struct, 1.0)))

	# cₙ(modelo) — misma estructura formal
	var c_n_model := persistence_base * pow(k_eff, (1.0 - 1.0 / max(n_struct, 1.0)))

	# ε(modelo) = | fⁿ − cₙ |
	var eps_model := float(abs(f_n_model - c_n_model))

	return {
		"f_n": f_n_model,
		"c_n_model": c_n_model,
		"eps_model": eps_model,
		"k": K_PERSISTENCE,
		"k_eff": k_eff,
		"n": n_struct,
		"n_log": get_n_log(),
		"n_power": get_n_power()
	}
# ε(modelo) — distancia estructural del modelo (no runtime)
func get_structural_epsilon() -> float:
	var m := compute_structural_model()
	return m.eps_model
# k_eff v0.7
func get_k_eff() -> float:
	var mu := get_mu_structural_factor()
	return K_PERSISTENCE * (1.0 + ALPHA_KAPPA * (mu - 1.0))

func register_structural_baseline():
	baseline_delta_structural = delta_per_sec
	last_stable_structural_upgrades = structural_upgrades

func get_omega(epsilon: float, k_mu: float, n: float) -> float:
	var denom := 1.0 + epsilon * k_mu * n
	return 1.0 / max(denom, 0.0001)

# -----------------------------------------------------
#  RUNTIME — contraste observacional (secundario)
# -----------------------------------------------------
func compute_structural_runtime() -> float:
	return persistence_dynamic

func get_structural_state() -> String:
	var e := get_structural_epsilon()

	if e < 0.02:
		return "🟢 Sistema estable — transmisión eficiente"
	elif e < 0.08:
		return "🟡 Zona de transición — reconfiguración estructural"
	else:
		return "🔴 Zona crítica — fricción sistémica"

# Alias estable — ahora SOLO devuelve el modelo
func update_structural_hud_model_block() -> Dictionary:
	return compute_structural_model()

# =====================================================
#  CAPITAL COGNITIVO (μ) — v0.7
func _on_UpgradeCognitiveButton_pressed():
	if money < cognitive_cost:
		return

	money -= cognitive_cost
	cognitive_level += 1
	cognitive_cost *= cognitive_cost_scale

	structural_upgrades += 1
	structural_cooldown = STRUCTURAL_COOLDOWN_TIME

	add_lap("Upgrade estructural → Capital Cognitivo (μ ↑ nivel %d)" % cognitive_level)

	update_cognitive_button()
	update_ui()

func update_cognitive_button():
	upgrade_cognitive_button.text = "Capital Cognitivo (μ) (+1 nivel)\n" + "Costo: $" + str(snapped(cognitive_cost, 0.01)) + "\n" + "μ = " + str(snapped(mu_structural, 0.01))

#====================================
# INSTITUCIONES V0.8
func get_structural_pressure() -> float:
	var base := epsilon_runtime * (1.0 + epsilon_peak) * float(structural_upgrades)
	var mitigated := base * (1.0 - accounting_effect)
	return mitigated
#====================================
# CAPITAL COGNITIVO EFECTIVO (n ajustado por contabilidad) v0.8
func get_effective_structural_n() -> float:
	return structural_upgrades * (1.0 + accounting_level * 0.1)
# =====================================================
#  LAP MARKERS
# =====================================================

func add_lap(event: String) -> void:
	lap_events.append({
		"time": format_time(run_time),
		"event": event,
		"click": snapped(get_click_power(), 0.01),
		"activo_ps": snapped(get_click_power() * CLICK_RATE, 0.01),
		"pasivo_ps": snapped(get_passive_total(), 0.01),
		"dominante": get_dominant_term(),
		"mu": snapped(get_mu_structural_factor(), 0.01),
		"mu_level": cognitive_level,

	})


func check_dominance_transition():
	var d := get_dominant_term()
	if d != last_dominance:
		add_lap("Transición de dominio → " + d)
		last_dominance = d

func get_run_filename() -> String:
	var t = Time.get_datetime_dict_from_system()

	return "run_%02d-%02d-%02d_%02d-%02d" % [
		t.day,
		t.month,
		t.year % 100,
		t.hour,
		t.minute
	]
# LEGACY — snapshot analítico (no usado en v0.6 export)
func build_run_snapshot() -> Dictionary:
	var ap := get_active_passive_breakdown()
	var c := get_contribution_breakdown()

	return {
		"version": Version.get_version_string(),
		"session_time": format_time(run_time),

		"economy": {
			"a": click_value,
		"b": click_multiplier,
		"c_n": persistence_dynamic,

		"n_structural": structural_upgrades,
		"f_n": get_persistence_target(),

		"n_log": get_n_log(),
		"n_power": get_n_power(),

		"auto_income": get_auto_income_effective(),
		"trueque_income": get_trueque_income_effective()
		},

		"distribution": {
			"click_%": c.click,
			"manual_%": c.d,
			"trueque_%": c.e,
			"activo_%": ap.activo,
			"pasivo_%": ap.pasivo
		},

		"deltas": {
			"activo_ps": ap.push_abs,
			"pasivo_ps": ap.passive_abs,
			"total_ps": c.total
		},

		"formula_text": build_formula_text(),
		"formula_eval": build_formula_values(),

		"laps": lap_events,
		"build": {"version": VERSION, "codename": CODENAME, "channel": BUILD_CHANNEL},
	}
func get_build_string() -> String:
	return "v%s — %s (%s)" % [VERSION, CODENAME, BUILD_CHANNEL]


func ensure_export_dir() -> void:
	DirAccess.make_dir_recursive_absolute(RUN_EXPORT_PATH)


func _get_timestamp_meta() -> Dictionary:
	var now := Time.get_datetime_dict_from_system()

	var dd := str(now.day).pad_zeros(2)
	var mm := str(now.month).pad_zeros(2)
	var yyyy := str(now.year)

	var hh := str(now.hour).pad_zeros(2)
	var mi := str(now.minute).pad_zeros(2)

	return {
		"fecha_humana": "%s/%s/%s" % [dd, mm, yyyy],
		"hora_humana": "%s:%s" % [hh, mi],
		"filename_stamp": "%s-%s-%s_%s-%s" % [dd, mm, yyyy, hh, mi]
	}
func _ensure_runs_dir():
	var path = "user://runs"
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_absolute(path)


func _build_run_json(meta: Dictionary) -> Dictionary:
	return {
		"version": VERSION,
		"fecha": meta.fecha_humana,
		"hora": meta.hora_humana,
		"tiempo_sesion": session_time_label.text,
		"delta_total_s": sys_delta_label.text,
		"activo_vs_pasivo": sys_active_passive_label.text,
		"distribucion_aporte": sys_breakdown_label.text,
		"produccion_jugador": click_stats_label.text,
		"lap_markers": lap_markers_label.text,
		"dominio": get_dominant_term()
	}
func _build_run_csv(meta: Dictionary) -> String:
	var csv := ""
	csv += "fecha;hora;tiempo_sesion;delta_total;dominio\n"
	csv += "%s;%s;%s;%s;%s\n" % [
		meta.fecha_humana,
		meta.hora_humana,
		session_time_label.text,
		sys_delta_label.text,
		get_dominant_term()
	]
	return csv
func _build_clipboard_text(meta: Dictionary) -> String:
	var t := ""
	t += "IDLE — Modelo Económico Evolutivo\n"
	t += "Run exportada — %s %s\n" % [meta.fecha_humana, meta.hora_humana]
	t += "Versión: %s\n" % VERSION
	t += "--------------------------------\n\n"

	t += "--- Producción activa (jugador) ---\n"
	t += click_stats_label.text + "\n\n"

	t += "--- Sistema — Δ$ y dinámica ---\n"
	t += sys_delta_label.text + "\n\n"
	t += sys_active_passive_label.text + "\n\n"
	t += sys_breakdown_label.text + "\n\n"
	t += session_time_label.text + "\n\n"

	t += lap_markers_label.text

	return t
func _on_ExportRunButton_pressed():
	_ensure_runs_dir()

	var meta := _get_timestamp_meta()

	print("EXPORT RUN —", meta.filename_stamp)
	

	# === JSON ===
	var json_data := _build_run_json(meta)
	var json_path := "user://runs/run_%s.json" % meta.filename_stamp
	var json_file := FileAccess.open(json_path, FileAccess.WRITE)
	json_file.store_string(JSON.stringify(json_data, "\t"))
	json_file.close()

	# === CSV ===
	var csv_path := "user://runs/run_%s.csv" % meta.filename_stamp
	var csv_file := FileAccess.open(csv_path, FileAccess.WRITE)
	csv_file.store_string(_build_run_csv(meta))
	csv_file.close()

	# === Clipboard ===
	DisplayServer.clipboard_set(_build_clipboard_text(meta))

	print("EXPORT OK →", json_path)
	print("✔ RUN EXPORTADA —", meta.fecha_humana, meta.hora_humana)
	print("   JSON:", json_path)
	print("   CSV :", csv_path)
	print("   📋 Copiada al portapapeles")

	# === Feedback in-game ===
	system_message_label.text = "Run exportada — %s %s\nGuardada en /runs" % [meta.fecha_humana, meta.hora_humana]

	print("EXPORT OK →", json_path)


func check_achievements():
	# Árbol completo
	if not unlocked_tree \
	and unlocked_d and unlocked_md and specialization_level > 0 \
	and unlocked_e and unlocked_me:
		unlocked_tree = true
		add_lap("🏁 Logro — Árbol productivo completo")
		show_system_toast("LOGRO ESTRUCTURAL — Sistema productivo completo")
	# Dominancia click
	if not unlocked_click_dominance:
		var d := get_dominant_term()
		if d == "CLICK domina el sistema":
			unlocked_click_dominance = true
			add_lap("🏁 Logro — Dominancia CLICK alcanzada")
			show_system_toast("LOGRO — Dominancia CLICK alcanzada")
	# Δ$ 100 / s
	if not unlocked_delta_100:
		var delta := get_delta_total()
		if delta >= 100.0:
			unlocked_delta_100 = true
			add_lap("🏁 Logro — Δ$ 100 / s alcanzado")
			show_system_toast("LOGRO — Δ$ 100 / s alcanzado")
func show_system_toast(message: String) -> void:
	system_message_label.text = message

func update_achievements_label():
	var t := "--- Logros estructurales ---\n"
	if unlocked_tree: t += "✓ Árbol productivo completo\n"
	if unlocked_click_dominance: t += "✓ CLICK domina el sistema\n"
	if unlocked_delta_100: t += "✓ Δ$ ≥ 100 alcanzado\n"
	system_achievements_label.text = t


# =====================================================
#  CICLO DE VIDA
# =====================================================

func _ready():
	update_ui()
	_mount_fungi_dlc()

func _mount_fungi_dlc():
	await get_tree().process_frame # ⬅️ clave: esperar que todo exista

	fungi_ui = FUNGI_UI_SCENE.instantiate()
	get_node("DLCOverlay").add_child(fungi_ui)

	fungi_ui.name = "FungiUI"
	fungi_ui.visible = true
	fungi_ui.set_main(self)

	big_click_button.set_main(self)

	print("🍄 Fungi DLC mounted")


func _process(delta):
	# 1) economía base
	apply_dynamic_persistence(delta)
	delta_per_sec = get_passive_total()
	run_time += delta
	update_economy(delta)

	# 2) calcular estrés real del sistema
	update_epsilon_runtime()

	if fungi_ui:
		fungi_ui.absorb_epsilon(epsilon_runtime)
		epsilon_effective = fungi_ui.epsilon_effective
	else:
		epsilon_effective = epsilon_runtime

	update_nutrients(delta)
	update_biosphere(delta)
	hifas = compute_hifas()
	update_genome()


	# 6) cooldown estructural
	if structural_cooldown > 0.0:
		structural_cooldown -= delta
		if structural_cooldown <= 0.0:
			register_structural_baseline()

	# 7) instituciones miran ε efectivo
	check_institution_unlock()

	# 8) UI
	update_ui()


# ESTRUCTURALES v0.7.3
func update_epsilon_runtime():
	if baseline_delta_structural <= 0.0 or delta_per_sec <= 0.0:
		epsilon_effective = 0.0
		return

	# -------------------------
	# 1) ε_producción
	# -------------------------
	var n_struct := get_effective_structural_n()
	var expected_delta := baseline_delta_structural * pow(
		get_k_eff(),
		1.0 - (1.0 / n_struct)
	)

	var epsilon_prod := 0.0
	if expected_delta > 0.0:
		epsilon_prod = max(0.0, (delta_per_sec / expected_delta) - 1.0)

	# -------------------------
	# 2) ε_composición
	# -------------------------
	var active: float = get_click_power()
	var total: float = delta_per_sec

	var active_ratio := 0.0
	if total > 0.0:
		active_ratio = active / total

	# target dinámico: sistema joven tolera click, sistema maduro no
	var t: float = clamp(n_struct / 40.0, 0.0, 1.0)
	var target_ratio: float = lerp(0.8, 0.4, t)

	var epsilon_comp := float(abs(active_ratio - target_ratio))
	epsilon_comp *= (1.0 - accounting_effect)

	# -------------------------
	# 3) Mezcla y memoria
	# -------------------------
	var epsilon_raw := epsilon_prod + epsilon_comp

	var epsilon_complexity := 0.002 * n_struct * get_k_eff()
	epsilon_raw += epsilon_complexity

	# transición suave (inercia macroeconómica)
	epsilon_runtime = lerp(epsilon_runtime, epsilon_raw, 0.08)

	# límites de estabilidad
	epsilon_runtime = clamp(epsilon_runtime, 0.0, 2.0)

	epsilon_peak = max(epsilon_peak, epsilon_runtime)
	# -------------------------
	# 4) Cálculo ω_runtime
	omega = get_omega(epsilon_runtime, get_k_eff(), n_struct)
	omega_min = min(omega_min, omega)
	# ===========================
	# EFECTO INSTITUCIONAL (ω)
	# ===========================
	accounting_effect = 1.0 - exp(-0.3 * accounting_level)
	accounting_effect = clamp(accounting_effect, 0.0, 0.5)

func check_institution_unlock():
	if institution_accounting_unlocked:
		return

	var p := get_structural_pressure()
	if p > 15.0 and omega < 0.25 and epsilon_runtime > 0.3:
		institution_accounting_unlocked = true
		institutions_unlocked = true
		omega = 0.1
		add_lap("🏛️ Institución desbloqueada — Contabilidad Básica")
		system_message_label.text = "El sistema se institucionaliza: nace la Contabilidad Básica"
		on_institutions_unlocked()
func get_accounting_cost() -> float:
	return accounting_base_cost * pow(accounting_cost_scale, accounting_level)

#
# =====================================================
# 	Acumulación del histórico de dinero generado v0.7.2
func update_economy(delta):
	var delta_money = delta_per_sec * delta
	money += delta_money
	total_money_generated += delta_money


func format_time(t: float) -> String:
	var m = float(int(t)) / 60
	var s = int(t) % 60
	return "%02d:%02d" % [m, s]

# =====================================================
#

func get_system_phase() -> String:
	if omega < 0.25:
		return "CRISTALIZANDO"
	elif omega < 0.4:
		return "RÍGIDO"
	elif omega < 0.7:
		return "TENSO"
	else:
		return "FLEXIBLE"

# =====================================================
# DLC — INTERFAZ FUNGÍCA v0.8
func _on_Biosfera_pressed() -> void:
	print("🍄 Biosfera toggle")
	if fungi_ui:
		fungi_ui.visible = !fungi_ui.visible
# =====================================================
#  INPUT & UPGRADES
# =====================================================

func _on_BigClickButton_pressed():
	money += get_click_power()
	big_click_button.scale = Vector2(0.95, 0.95)
	await get_tree().create_timer(0.05).timeout
	big_click_button.scale = Vector2(1, 1)
	update_ui()


# CLICK
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


# PERSISTENCIA ÚNICA
var persistence_upgrade_unlocked := false
var persistence_upgrade_cost := 10000.0
const PERSISTENCE_NEW_VALUE := 1.6

func _on_PersistenceUpgradeButton_pressed():
	if persistence_upgrade_unlocked:
		return
	if money < persistence_upgrade_cost:
		return

	money -= persistence_upgrade_cost
	persistence_upgrade_unlocked = true

	persistence_base = PERSISTENCE_NEW_VALUE
	structural_upgrades += 1
	structural_cooldown = STRUCTURAL_COOLDOWN_TIME

	add_lap("Upgrade estructural → Persistencia (baseline elevado)")

	if persistence_dynamic < persistence_base:
		persistence_dynamic = persistence_base

	update_ui()


# AUTO (d + md)
func _on_UpgradeAutoButton_pressed():
	if money < auto_upgrade_cost: return
	money -= auto_upgrade_cost
	income_per_second += 1
	auto_upgrade_cost *= 1.6
	unlocked_d = true
	structural_upgrades += 1
	add_lap("Desbloqueado d (Trabajo Manual)")
	update_ui()


func _on_UpgradeAutoMultiplierButton_pressed():
	if money < auto_multiplier_upgrade_cost: return
	money -= auto_multiplier_upgrade_cost
	auto_multiplier *= AUTO_MULTIPLIER_GAIN
	auto_multiplier_upgrade_cost *= AUTO_MULTIPLIER_SCALE
	unlocked_md = true
	structural_upgrades += 1
	add_lap("Desbloqueado md (Ritmo de Trabajo)")
	update_ui()
# NUEVO BOTÓN — ESPECIALIZACIÓN DE OFICIO
func _on_UpgradeSpecializationButton_pressed():
	if money < specialization_cost:
		return

	money -= specialization_cost
	specialization_level += 1
	manual_specialization *= SPECIALIZATION_GAIN
	specialization_cost *= SPECIALIZATION_SCALE
	structural_upgrades += 1

	add_lap("Especialización de Oficio → x%s" %
		str(snapped(manual_specialization, 0.01)))

	update_ui()

# TRUEQUE (e + me)
func _on_UpgradeTruequeButton_pressed():
	if money < trueque_cost: return
	money -= trueque_cost
	trueque_level += 1
	trueque_cost *= TRUEQUE_COST_SCALE
	unlocked_e = true
	add_lap("Desbloqueado e (Trueque)")
	update_ui()


func _on_UpgradeTruequeNetworkButton_pressed():
	if money < trueque_network_upgrade_cost: return
	money -= trueque_network_upgrade_cost
	trueque_network_multiplier *= TRUEQUE_NETWORK_GAIN
	trueque_network_upgrade_cost *= TRUEQUE_NETWORK_SCALE
	unlocked_me = true
	add_lap("Desbloqueado me (Red de Intercambio)")
	update_ui()

# =====================================================
#  DESBLOQUEO INSTITUCIONES v0.7.2
# =====================================================


func on_institutions_unlocked():
	print("Nueva capa estructural detectada: Instituciones")
	show_institutions_panel = true
func buy_accounting():
	var cost := get_accounting_cost()
	if money < cost:
		return
	
	money -= cost
	accounting_level += 1

	# Amortiguación estructural real
	epsilon_runtime *= 0.85 # baja 15% el estrés
	epsilon_peak = max(epsilon_peak * 0.9, epsilon_runtime)

	add_lap("🏛️ Contabilidad — Nivel %d (ε amortiguado)" % accounting_level)
func _on_UpgradeAccountingButton_pressed():
	if not institution_accounting_unlocked:
		return
	
	buy_accounting()
	update_ui()


# =====================================================
#  UI — SOLO LEE RESULTADOS (v0.6.3 — HUD científico)
# =====================================================

func update_ui():
	check_dominance_transition()
	check_achievements()
	update_achievements_label()
	# Valores principales


	money_label.text = "Dinero: $" + str(round(money))

	formula_label.text = build_formula_text() + "\n" + build_formula_values()
	marginal_label.text = build_marginal_contribution()
	update_cognitive_button()


	update_click_stats_panel()
	if institutions_unlocked:
		institution_panel_label.visible = true

		institution_panel_label.text = "--- Contabilidad Básica ---\n"
		institution_panel_label.text += "ε_runtime = %s\n" % snapped(epsilon_runtime, 0.01)
		institution_panel_label.text += "ε_peak = %s\n" % snapped(epsilon_peak, 0.01)
		institution_panel_label.text += "Presión estructural = %s\n" % snapped(get_structural_pressure(), 0.01)
		institution_panel_label.text += "Ω (flexibilidad) = %s\n" % snapped(omega, 0.01)
		institution_panel_label.text += "Ω_min = %s\n" % snapped(omega_min, 0.01)
		institution_panel_label.text += "\nEstado del sistema = " + get_system_phase()
		institution_panel_label.text += "\nContabilidad = nivel " + str(accounting_level)
		institution_panel_label.text += "\nAmortiguación = " + str(round(accounting_effect * 100.0)) + "%"
		institution_panel_label.text += "\n\n" + build_genome_text()

	# μ sigue existiendo
		upgrade_cognitive_button.visible = true

	# botón de contabilidad
	if institution_accounting_unlocked:
		upgrade_accounting_button.visible = true
		upgrade_accounting_button.text = "Contabilidad (+1)\nCosto: $" + str(round(get_accounting_cost()))
	else:
		upgrade_accounting_button.visible = false

	# =====================================================
	#  MÉTRICAS LABORATORIO
	# =====================================================

	var c := get_contribution_breakdown()
	var ap := get_active_passive_breakdown()
	# Dinámica del sistema

	sys_delta_label.text = "Δ$ estimado / s = +%s" % snapped(c.total, 0.01)
	session_time_label.text = "Tiempo de sesión: " + format_time(run_time)
	# Distribución activo / pasivo
	sys_active_passive_label.text = "--- Activo vs Pasivo ---\n"
	sys_active_passive_label.text += "Activo (CLICK): %s%%\n" % snapped(ap.activo, 0.1)
	sys_active_passive_label.text += "Pasivo (d+e): %s%%\n" % snapped(ap.pasivo, 0.1)
	sys_active_passive_label.text += "Δ$ activo / s = +%s\n" % snapped(ap.push_abs, 0.01)
	sys_active_passive_label.text += "Δ$ pasivo / s = +%s" % snapped(ap.passive_abs, 0.01)
	# Distribución de aporte
	sys_breakdown_label.text = "--- Distribución de aporte (productores) ---\n"
	sys_breakdown_label.text += "Click: %s%%\n" % snapped(c.click, 0.1)
	sys_breakdown_label.text += "Trabajo Manual: %s%%\n" % snapped(c.d, 0.1)
	sys_breakdown_label.text += "Trueque: %s%%" % snapped(c.e, 0.1)

	if lab_mode:
		lap_markers_label.text = "--- Lap markers (historial) ---\n"
		system_state_label.text = "ε_runtime = %s" % snapped(epsilon_runtime, 0.01)

		var start: int = max(0, lap_events.size() - 12)
		for i in range(start, lap_events.size()):
			var lap: Dictionary = lap_events[i]
			lap_markers_label.text += "%s → %s\n" % [lap.time, lap.event]
	else:
		lap_markers_label.text = ""
	
	# === BOTONES CLICK ===

	upgrade_click_button.text = "Mejorar click (+%s)\nCosto: $%s" % [str(snapped(click_value + 1, 0.01)), str(round(click_upgrade_cost))]

	upgrade_click_multiplier_button.text = "Memoria Numérica (×1.06)\nCosto: $%s" % [str(round(click_multiplier_upgrade_cost))]

	persistence_upgrade_button.text = "Memoria Operativa del Sistema (única)\nPersistencia → %s\nCosto: %s" % [str(PERSISTENCE_NEW_VALUE), ("—" if persistence_upgrade_unlocked else "$" + str(round(persistence_upgrade_cost)))
	]

	# === BOTONES AUTO (d + md) ===
	upgrade_auto_button.text = "Trabajo Manual (+1/s)\nCosto: $%s" % [str(round(auto_upgrade_cost))]

	upgrade_auto_multiplier_button.text = "Ritmo de Trabajo (×%s)\nCosto: $%s" % [str(snapped(AUTO_MULTIPLIER_GAIN, 0.01)), str(round(auto_multiplier_upgrade_cost))]

	# === BOTONES ESPECIALIZACIÓN ===
	specialization_button.text = "Especialización de Oficio (×%s)\nCosto: $%s" % [str(snapped(SPECIALIZATION_GAIN, 0.01)), str(round(specialization_cost))]
	
	# === BOTONES TRUEQUE (e + me) ===

	upgrade_trueque_button.text = "Trueque (+1)\nCosto: $%s" % [str(round(trueque_cost))]

	upgrade_trueque_network_button.text = "Red de Intercambio (×%s)\nCosto: $%s" % [str(snapped(TRUEQUE_NETWORK_GAIN, 0.01)), str(round(trueque_network_upgrade_cost))]

	# μ siempre existe, incluso con instituciones
	upgrade_cognitive_button.visible = true

func build_genome_text() -> String:
		var t := "🧬 GENOMA FÚNGICO\n"
		t += "Hiperasimilación: " + genome.hiperasimilacion + "\n"
		t += "Parasitismo: " + genome.parasitismo + "\n"
		t += "Red micelial: " + genome.red_micelial + "\n"
		t += "Esporulación: " + genome.esporulacion + "\n"
		t += "Simbiosis: " + genome.simbiosis
		return t
