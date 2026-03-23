extends Control

# =====================================================
# IDLE — v0.8 DLC "Fungi"
# =====================================================
#dlc
const FUNGI_UI_SCENE = preload("res://fungi.tscn")
var fungi_ui: Control

var reactor_visual: Node = null

var money: float = 0.0

# --- PERSISTENCIA estructural ---
# c₀: Valor base (1.4). fⁿ: Objetivo dinámico. cₙ: Estado actual.
var persistence_dynamic: float = 1.4
var persistence_base: float = 1.4

# VARIABLES DE DINÁMICA ECONÓMICA (pueden ser modificadas por mutaciones)
var trueque_base_income := 8.0
var trueque_efficiency := 0.75
var mutation_auto_factor := 1.0
var mutation_trueque_factor := 1.0
var mutation_accounting_bonus := 0.0

# CONSTANTES DE MODELO
const K_PERSISTENCE := 1.25
const ALPHA_KAPPA := 0.55
const COGNITIVE_MULTIPLIER := 0.05
const CLICK_RATE := 1.0

# OBSERVADORES DINÁMICOS (Caché por tick)
var cached_mu: float = 1.0
var mu_structural: float = 1.0

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
# === ε DEBUG X FRAME  (v0.8.2) ===
var epsilon_debug := false
var epsilon_debug_throttle := 0.0
const EPSILON_DEBUG_INTERVAL := 0.25  # segundos
# Cooldown estructural (clave para ε_runtime)
var structural_cooldown := 0.0
const STRUCTURAL_COOLDOWN_TIME := 8.0
var omega := 1.0
var omega_min := 1.0
var institution_accounting_unlocked := false

# === ε PASIVO (v0.8) ===
const EPS_PASSIVE_SCALE := 0.24
const PASSIVE_RATIO_START := 0.60
# === ε desglosado (HUD / debug) ===
var epsilon_active: float = 0.0
var epsilon_passive: float = 0.0
var epsilon_complex: float = 0.0

# === HOMEOSTASIS TRACKING ===
var homeostasis_timer := 0.0
const HOMEOSTASIS_TIME_REQUIRED := 18.0  # segundos estables
# === CIERRE DE RUN / RUTA FINAL ===
var run_closed := false
var final_route := "NONE"
# === POST-HOMEOSTASIS MODE ===
var homeostasis_mode := false
var post_homeostasis := false
var resilience_score := 0.0
var disturbance_timer := 0.0
const DISTURBANCE_INTERVAL := 20.0

var legacy_homeostasis := false

# =====================================================
var epsilon_effective := 0.0


# =============== SESIÓN / LAB MODE ===================

var run_time: float = 0.0
var lab_mode := true

# estado final
var final_reason := ""           # guardamos la razón textual del cierre
var show_final_details := false  # ya lo tenías; lo usamos para controlar detalles

var RUN_EXPORT_PATH := OS.get_user_data_dir() + "/IDLE_Fungi/runs"

# ========== DESBLOQUEO PROGRESIVO DE FÓRMULA =========

var unlocked_d := false
var unlocked_md := false
var unlocked_e := false
var unlocked_me := false


# === VERSION INFO ===
const VERSION := "0.8"
const CODENAME := "v0.8 — “Fungi Evolution”"
const BUILD_CHANNEL := "stable"

const SAVE_PATH := "user://savegame.json"
# Timers — tick system (no more manual accumulation in _process)
var _logic_timer: Timer
var _ui_timer: Timer
var _autosave_timer: Timer
const LOGIC_TICK := 0.2   # 5 Hz — economy, epsilon, evolution
const UI_TICK := 0.1      # 10 Hz — labels & buttons
const AUTOSAVE_INTERVAL := 30.0

# =====================================================
#  ACHIEVEMENTS / LOGROS WIP

var unlocked_tree := false
var unlocked_click_dominance := false
var unlocked_delta_100 := false
var achievement_homeostasis := false
var achievement_homeostasis_perfect := false
var achievement_hyperassimilation := false
var achievement_symbiosis := false
var achievement_red_micelial := false
var achievement_sporulation := false
var achievement_parasitism := false


# === GENES FÚNGICOS ===
# Movidos a BiosphereEngine
# ===== BIOSFERA =====
# Movidos a BiosphereEngine
# === MUTACIONES ACTIVAS (flags reales) ===
# Movidas a EvoManager
# ================= REFERENCIAS UI ===================
# La mayoría movidas a UIManager.gd
@onready var fungi_ui_scene = preload("res://fungi.tscn")
@onready var ui_root = $UIRootContainer


# =====================================================
#  CAPA 1 — MODELO ECONÓMICO
# =====================================================

func get_click_power() -> float:
	return EcoModel.get_click_power(
		UpgradeManager.value("click"), 
		UpgradeManager.value("click_mult"), 
		persistence_dynamic, 
		cached_mu
	)

func get_auto_income_effective() -> float:
	return EcoModel.get_auto_income_effective(
		UpgradeManager.value("auto"), 
		UpgradeManager.value("auto_mult") * mutation_auto_factor, 
		UpgradeManager.value("specialization"), 
		cached_mu, 
		BiosphereEngine.get_biomass_beta(), 
		UpgradeManager.level("accounting")
	)

func get_trueque_raw() -> float:
	return EcoModel.get_trueque_raw(
		UpgradeManager.level("trueque"), 
		trueque_base_income, 
		trueque_efficiency
	)

func get_trueque_income_effective() -> float:
	return EcoModel.get_trueque_income_effective(
		get_trueque_raw(), 
		UpgradeManager.value("trueque_net") * mutation_trueque_factor, 
		cached_mu, 
		BiosphereEngine.get_biomass_beta(), 
		UpgradeManager.level("accounting")
	)

func get_passive_total() -> float:
	return get_auto_income_effective() + get_trueque_income_effective()

func get_delta_total() -> float:
	return get_click_power() + get_passive_total()

func get_mu_structural_factor() -> float:
	var n = UpgradeManager.level("cognitive")
	var mu_base := 1.0
	if n > 0:
		mu_base = 1.0 + log(1.0 + float(n)) * 0.08

	var mu_fungi := BiosphereEngine.get_mu_fungi_multiplier(EvoManager.mutation_hyperassimilation, EvoManager.mutation_homeostasis)
	var mu_total = mu_base * mu_fungi

	return mu_total



func get_biomass_beta() -> float:
	return BiosphereEngine.get_biomass_beta()

# ===== BIOSFERA MOVIDA A BiosphereEngine =====
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
# =====================================================
# EVOLUCIÓN BIOLÓGICA v0.8 DLC
# =====================================================
func update_genome():
	EvoManager.update_genome(self)

# === FUNCIONES DE LOGROS Y CICLO DE VIDA (Restauradas) ===
func close_run(route: String, reason: String):
	run_closed = true
	final_route = route
	final_reason = reason
	add_lap("🚩 RUN CERRADA: " + route)
	SaveManager.save_game(self)

func unlock_hyperassimilation_achievement():
	if achievement_hyperassimilation: return
	achievement_hyperassimilation = true
	show_system_toast("LOGRO: Hiperasimilación Desbloqueada")

func unlock_sporulation_achievement():
	if achievement_sporulation: return
	achievement_sporulation = true
	show_system_toast("LOGRO: Esporulación Irreversible")

func unlock_red_micelial_achievement():
	if achievement_red_micelial: return
	achievement_red_micelial = true
	show_system_toast("LOGRO: Red Micelial Alcanzada")

func enter_post_homeostasis():
	post_homeostasis = true
	add_lap("⚖️ Iniciando fase de Post-Homeostasis")

func activate_sporulation():
	EvoManager.activate_mutation("esporulacion")

func activate_homeostasis():
	EvoManager.activate_mutation("homeostasis")

	
# =====================================================
# RUTA EVOLUTIVA - SEÑALES DE EVOMANAGER
# =====================================================
func _on_mutation_activated(mutation_id: String, display_name: String):
	add_lap("🧬 Mutación irreversible — " + display_name)
	show_system_toast("RUTA EVOLUTIVA — " + display_name)

	match mutation_id:
		"hiperasimilacion":
			unlock_hyperassimilation_achievement()
			apply_flexibility_modifier(0.75)
			enable_persistence_inertia(0.20)
		"homeostasis":
			# --- efectos inmediatos ---
			epsilon_runtime *= 0.85
			epsilon_peak = min(epsilon_peak, 1.0)
			omega_min = max(omega_min, 0.35)
			mutation_accounting_bonus += 0.05
			if UIManager.system_message_label:
				UIManager.system_message_label.text = "El sistema entra en HOMEOSTASIS: estabilidad estructural priorizada"
		"red_micelial":
			# efectos estructurales suaves (no agresivos)
			omega = min(1.0, omega * 1.20)
			mutation_accounting_bonus += 0.05
			trueque_efficiency *= 1.15
			mutation_auto_factor *= 1.10
		"esporulacion":
			# Pico final de estrés por ruptura estructural (la biologia la reduce BiosphereEngine)
			epsilon_runtime = min(epsilon_runtime + 0.35, 2.0)
			epsilon_peak = max(epsilon_peak, epsilon_runtime)
			unlock_sporulation_achievement()
		"parasitismo":
			# efectos inmediatos
			mutation_accounting_bonus -= 0.10
			omega = min(omega, 0.25)
			BiosphereEngine.apply_parasitism_buffs()
		"simbiosis":
			# --- efectos estructurales ---
			omega = min(1.0, omega * 1.15)
			mutation_accounting_bonus += 0.02
			BiosphereEngine.absorption *= 1.3
			trueque_efficiency *= 1.1
			mutation_auto_factor *= 1.05
# === EFECTOS DE MUTACIÓN ===

var persistence_inertia := 1.0

func apply_flexibility_modifier(factor: float):
	omega *= factor
	omega_min *= factor

func enable_persistence_inertia(factor: float):
	persistence_inertia = factor

func apply_symbiotic_stabilization():
	# más flexibilidad estructural
	omega = min(1.0, omega * 1.25)

	# amortiguación permanente del estrés
	mutation_accounting_bonus = min(0.6, mutation_accounting_bonus + 0.15)

	# mejora pasivo sin romper el modelo
	trueque_efficiency *= 1.1
	mutation_auto_factor *= 1.05
# =====================================================
#  RUTA FINAL — detalles
# =====================================================
func build_final_line() -> String:
	if not run_closed:
		return ""
	var t := "\n🏁 FINAL: %s" % final_route
	if show_final_details:
		t += "\n" + get_final_reason()
	return t

# =====================================================
#  FORMATO TEXTO FÓRMULA
# =====================================================

func build_formula_text() -> String:
	return UIManager.build_formula_text(self)

func build_formula_values() -> String:
	return UIManager.build_formula_values(self)

func build_marginal_contribution() -> String:
	return UIManager.build_marginal_contribution(self)
# ===============================
#   HUD CIENTÍFICO — segmentado por capas
# ===============================
func update_click_stats_panel() -> void:
	if UIManager.click_stats_label:
		UIManager.click_stats_label.text = UIManager.update_click_stats_panel(self)


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
	return 1.0 + log(1.0 + float(get_structural_upgrades()))

func get_n_power() -> float:
	return pow(float(get_structural_upgrades()) + 1.0, 0.35)


# =====================================================
#  FUNCIÓN SIGMOIDE fⁿ α V0.6.2
# =====================================================
func f_n_alpha(n: float) -> float:
	return 1.0 / (1.0 + exp(-0.35 * (n - 6.0)))

func apply_dynamic_persistence(delta: float) -> void:
	var n_struct := float(get_structural_upgrades())

	# valor teórico esperado
	var target := get_persistence_target()

	# peso sigmoide — transición suave
	var a := f_n_alpha(n_struct)

	# converge sin overshoot
	persistence_dynamic = lerp(
	persistence_dynamic,
	target,
	clamp(a * delta * 0.4 * persistence_inertia, 0.0, 0.25)
)


# === Persistencia estructural ===
# c₀  → baseline fijo
# fⁿ  → objetivo teórico según n
# cₙ  → estado dinámico observado

func get_persistence_target() -> float:
	var n_struct := get_effective_structural_n()
	var k_eff := get_k_eff()
	return EcoModel.get_persistence_target(persistence_base, k_eff, n_struct)

func get_cognitive_mu() -> float:
	var mu = 1.0 + log(1.0 + float(UpgradeManager.level("cognitive"))) * COGNITIVE_MULTIPLIER
	return snapped(mu, 0.01)


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
	var mu := cached_mu
	return EcoModel.get_k_eff(K_PERSISTENCE, ALPHA_KAPPA, mu)

func register_structural_baseline():
	baseline_delta_structural = delta_per_sec
	last_stable_structural_upgrades = get_structural_upgrades()

func get_omega(epsilon: float, k_mu: float, n: float) -> float:
	var denom := 1.0 + epsilon * k_mu * n
	return 1.0 / max(denom, 0.0001)

# -----------------------------------------------------
#  RUNTIME — contraste observacional (secundario)
# -----------------------------------------------------
func compute_structural_runtime() -> float:
	return persistence_dynamic



# Alias estable — ahora SOLO devuelve el modelo
func update_structural_hud_model_block() -> Dictionary:
	return compute_structural_model()

# =====================================================
#  CAPITAL COGNITIVO (μ) — v0.7
# Gestionado vía UpgradeManager
# =====================================================
#  VISUALIZACIÓN DE LAPS
# =====================================================
func _on_ToggleLapViewButton_pressed():
	toggle_lap_view()

# Redundant, UI is updated via UIManager
# func update_cognitive_button():
# 	upgrade_cognitive_button.text = "Capital Cognitivo (μ) (+1 nivel)\n" + "Costo: $" + str(snapped(cognitive_cost, 0.01)) + "\n" + "μ = " + str(snapped(mu_structural, 0.01))

#====================================
# INSTITUCIONES V0.8
func get_structural_pressure() -> float:
	return EcoModel.get_structural_pressure(epsilon_effective, epsilon_peak, get_structural_upgrades(), get_accounting_effect())
#====================================
# CAPITAL COGNITIVO EFECTIVO (n ajustado por contabilidad) v0.8
func get_accounting_effect() -> float:
	var base = float(UpgradeManager.level("accounting")) * 0.05
	return base + mutation_accounting_bonus + (0.05 if legacy_homeostasis else 0.0)

func get_structural_upgrades() -> int:
	return UpgradeManager.level("click") + UpgradeManager.level("auto") + UpgradeManager.level("trueque") + (1 if persistence_upgrade_unlocked else 0)

func get_effective_structural_n() -> float:
	return EcoModel.get_effective_structural_n(get_structural_upgrades(), UpgradeManager.level("accounting"))

func purchase_upgrade(id: String) -> void:
	var cost = UpgradeManager.cost(id)
	if money >= cost:
		if UpgradeManager.buy(id, money):
			money -= cost
			_on_upgrade_bought_actions(id)
			update_ui()
			add_lap("Comprado: " + UpgradeManager.get_def(id).label)

func _on_upgrade_bought_actions(id: String) -> void:
	structural_cooldown = STRUCTURAL_COOLDOWN_TIME
	match id:
		"auto":
			unlocked_d = true
			add_lap("Desbloqueado d (Trabajo Manual)")
		"auto_mult":
			unlocked_md = true
			add_lap("Desbloqueado md (Ritmo de Trabajo)")
		"trueque":
			unlocked_e = true
			add_lap("Desbloqueado e (Trueque)")
		"trueque_net":
			unlocked_me = true
			add_lap("Desbloqueado me (Red de Intercambio)")
		"specialization":
			add_lap("Especialización de Oficio → x%s" % str(snapped(UpgradeManager.value("specialization"), 0.01)))
		"cognitive":
			add_lap("Upgrade estructural → Capital Cognitivo (μ ↑ nivel %d)" % UpgradeManager.level("cognitive"))
		"persistence":
			persistence_dynamic = UpgradeManager.value("persistence")
			persistence_upgrade_unlocked = true
			add_lap("Memoria Operativa del Sistema Activada")
		"accounting":
			if UpgradeManager.level("accounting") == 1:
				omega = max(omega, 0.38)
				add_lap("⚖️ Ventana institucional — flexibilidad restaurada")
			epsilon_runtime *= 0.85
			epsilon_peak = max(epsilon_peak * 0.9, epsilon_runtime)
			add_lap("🏛️ Contabilidad — Nivel %d (ε amortiguado)" % UpgradeManager.level("accounting"))
# =====================================================
#  HOMEOSTASIS TRACKING helper v0.8
# =====================================================
func is_homeostasis_candidate(delta: float) -> bool:
	# condiciones suaves, no ideales
	var stable_epsilon := epsilon_effective < 0.35
	var not_crystallized := omega > 0.25
	var enough_biomass := BiosphereEngine.biomasa > 2.5
	var institutionalized := UpgradeManager.level("accounting") >= 1 # Use UpgradeManager
	var no_hyper := not EvoManager.mutation_hyperassimilation
	# 🔒 BLOQUEO: Red Micelial madura no puede homeostasiar
	var red_blocks_homeostasis := EvoManager.mutation_red_micelial and EvoManager.red_micelial_phase == 2

	if stable_epsilon and not_crystallized and enough_biomass and institutionalized and no_hyper and not red_blocks_homeostasis:
		homeostasis_timer += delta
	else:
		homeostasis_timer -= delta * 0.8
		homeostasis_timer = clamp(homeostasis_timer, 0.0, HOMEOSTASIS_TIME_REQUIRED)

	return homeostasis_timer >= HOMEOSTASIS_TIME_REQUIRED
# =====================================================
#  RUTA FINAL DE LA RUN v0.8
# =====================================================
func get_final_route() -> String:
	if final_route != "NONE":
		return final_route
	if EvoManager.mutation_sporulation:
		return "ESPORULACION"
	if EvoManager.mutation_homeostasis:
		return "HOMEOSTASIS"
	if EvoManager.mutation_hyperassimilation:
		return "HIPERASIMILACION"
	if EvoManager.mutation_symbiosis:
		return "SIMBIOSIS"
	if EvoManager.mutation_red_micelial:
		return "RED_MICELIAL"
	return "NONE"
func get_final_reason() -> String:
	# si tenemos final_reason explícito, lo devolvemos; si no, generamos un texto por ruta
	if final_reason != "" :
		return final_reason

	match final_route:
		"HOMEOSTASIS":
			return "Estabilidad estructural priorizada — run cerrada por homeostasis"
		"HIPERASIMILACION":
			return "El sistema prioriza absorción total sobre estabilidad"
		"ESPORULACION":
			return "Dispersión en esporas: la red colapsó en semillas"
		"PARASITISMO":
			return "Extracción total: la biosfera drenó la estructura"
		"SIMBIOSIS":
			return "Cooperación sostenida entre estructura y biología"
		"RED_MICELIAL":
			return "Red micelial madura"
		_:
			return "Final alcanzado"
# =====================================================
#  CHEQUEO FINAL DE HOMEOSTASIS v0.8
# =====================================================
func check_homeostasis_final(delta: float):
	var omega_threshold := float (max(0.24, omega_min + 0.04))
	if run_closed:
		return

	if EvoManager.mutation_homeostasis \
	and epsilon_effective < 0.30 \
	and omega > omega_threshold \
	and UpgradeManager.level("accounting") >= 1 \
	and BiosphereEngine.biomasa > 3.0:
		homeostasis_timer += delta
	else:
		homeostasis_timer = max(homeostasis_timer - delta * 1.2, 0.0)

	if homeostasis_timer >= HOMEOSTASIS_TIME_REQUIRED:
		close_run(
			"HOMEOSTASIS",
			"Estabilidad estructural sostenida sin colapso"
		)
		enter_post_homeostasis()
# =====================================================
#  CHEQUEO FINAL DE SIMBIOSIS v0.8 helper

func check_symbiosis_final(_delta: float):
	if run_closed or not EvoManager.mutation_symbiosis:
		return

	var stable_band := (
		epsilon_effective >= 0.18
		and epsilon_effective <= 0.40
		and omega > 0.35
		and UpgradeManager.level("accounting") >= 1
	)

	if stable_band and run_time > 900.0: # ~15 min
		close_run(
			"SIMBIOSIS",
			"Cooperación sostenida entre estructura y biología"
		)
# =====================================================
#  CHEQUEO FINAL DE PARASITISMO v0.8 helper
func check_parasitism_final(_delta: float):
	if run_closed or not EvoManager.mutation_parasitism:
		return

	# colapso por extracción sostenida
	if BiosphereEngine.biomasa > 18.0 \
	and omega < 0.22 \
	and epsilon_effective > 0.45:
		close_run(
			"PARASITISMO",
			"La biosfera drenó la estructura hasta el colapso"
		)
# =====================================================
#  CHEQUEO FINAL DE RED MICELIAL v0.8 helper
# =====================================================
func check_red_micelial_final(_delta: float):
	if not EvoManager.mutation_red_micelial or EvoManager.red_micelial_phase != 2:
		return

	# solo logro + estado estable, NO final
	if not achievement_red_micelial \
	and epsilon_effective < 0.22 \
	and omega > 0.45 \
	and BiosphereEngine.hifas > 10.0 \
	and UpgradeManager.level("accounting") >= 1:
		unlock_red_micelial_achievement()
# =====================================================
# CHEQUEO TRANSICIÓN RED MICELIAL A FASE B v0.8 helper
# =====================================================
func check_red_micelial_transition(_delta: float):
	# Si no hay red activa o ya en fase B, nada que hacer
	if not EvoManager.mutation_red_micelial or EvoManager.red_micelial_phase != 1:
		return

	# Condiciones para mover A -> B (pauta: estabilidad distribuida + tiempo)
	if BiosphereEngine.hifas > 10.0 \
	and BiosphereEngine.biomasa >= 5.0 \
	and epsilon_effective < 0.22 \
	and omega > 0.45 \
	and UpgradeManager.level("accounting") >= 1 \
	and run_time > 200.0:
		
		EvoManager.red_micelial_phase = 2
		add_lap("🔀 Red Micelial → Fase B (transición)")
		show_system_toast("RED MICELIAL — Fase B: red en transición")
		# desbloqueo del logro (no cierra la run aún)
		unlock_red_micelial_achievement()
func check_sporulation_trigger(_delta: float):
	if run_closed or EvoManager.mutation_sporulation:
		return

	if not EvoManager.mutation_red_micelial or EvoManager.red_micelial_phase != 2:
		return
	if EvoManager.mutation_homeostasis or EvoManager.mutation_hyperassimilation:
		return

	var _structural_pressure := get_structural_pressure()

	if (
		epsilon_peak >= 0.75
		and epsilon_effective <= 0.35
		and omega <= 0.30
		and BiosphereEngine.biomasa >= 10.0
		and BiosphereEngine.hifas >= 12.0
		and run_time >= 900.0
	):
		activate_sporulation()
# =====================================================
#  MODO HOMEOSTASIS v0.8
# =====================================================
func update_homeostasis_mode(delta: float):
	# 1) El sistema intenta mantenerse
	var stability :float = clamp(1.0 - epsilon_effective, 0.0, 1.0)
	resilience_score += stability * delta

	# 2) Perturbaciones externas
	disturbance_timer += delta
	if disturbance_timer >= DISTURBANCE_INTERVAL:
		disturbance_timer = 0.0
		trigger_disturbance()
	# Homeostasis intenta corregir sola
	epsilon_runtime = lerp(
		epsilon_runtime,
		epsilon_effective,
		0.05 * delta
	)
func trigger_disturbance():
	var shock := randf_range(0.1, 0.4)
	epsilon_runtime += shock
	add_lap("🌪️ Perturbación externa — shock ε +" + str(snapped(shock, 0.01)))
func check_perfect_homeostasis():
	if not post_homeostasis or achievement_homeostasis_perfect:
		return

	if resilience_score >= 300.0:
		achievement_homeostasis_perfect = true
		add_lap("🏆 LOGRO — HOMEOSTASIS PERFECTA")
		show_system_toast("LOGRO — HOMEOSTASIS PERFECTA: resiliencia máxima")
		legacy_homeostasis = true
		post_homeostasis = false
# =====================================================
#  TOOLTIP HIPERASIMILACIÓN v0.8
# =====================================================
func get_hyperassimilation_tooltip() -> String:
	if genome.hiperasimilacion == "bloqueado":
		return "Bloqueada por HOMEOSTASIS o SIMBIOSIS"

	if EvoManager.genome.hiperasimilacion == "activo":
		return "Absorción total priorizada. Estabilidad ignorada."

	var t := "Hiperasimilación (LATENTE)\n"
	if epsilon_runtime <= 0.6:
		t += "• ε insuficiente\n"
	if BiosphereEngine.biomasa <= 5.0:
		t += "• Biomasa insuficiente\n"
	if omega >= 0.30:
		t += "• Sistema demasiado flexible\n"
	if UpgradeManager.level("accounting") > 0: # Use UpgradeManager
		t += "• Instituciones bloquean esta vía\n"

	return t
# =====================================================
#  FLAGS VISUALES EPSILON helper
# =====================================================
func epsilon_flag(v: float, limit: float) -> String:
	return UIManager.epsilon_flag(v, limit)
# =====================================================
#  LAP MARKERS
# =====================================================

func add_lap(event: String) -> void:
	LogManager.add(event, self)


func check_dominance_transition():
	LogManager.check_dominance_transition(self)

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
			"a": UpgradeManager.value("click"),
		"b": UpgradeManager.value("click_mult"),
		"c_n": persistence_dynamic,

		"n_structural": get_structural_upgrades(),
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

		"laps": LogManager.lap_events,
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
		"tiempo_sesion": UIManager.session_time_label.text if UIManager.session_time_label else "",
		"delta_total_s": UIManager.sys_delta_label.text if UIManager.sys_delta_label else "",
		"activo_vs_pasivo": UIManager.sys_active_passive_label.text if UIManager.sys_active_passive_label else "",
		"distribucion_aporte": UIManager.sys_breakdown_label.text if UIManager.sys_breakdown_label else "",
		"produccion_jugador": UIManager.click_stats_label.text if UIManager.click_stats_label else "",
		"lap_markers": UIManager.lap_markers_label.text if UIManager.lap_markers_label else "",
		"dominio": get_dominant_term(),
		"evolution": {
	"final_route": get_final_route(),
	"mutation_flags": {
		"homeostasis": EvoManager.mutation_homeostasis,
		"hyperassimilation": EvoManager.mutation_hyperassimilation,
		"symbiosis": EvoManager.mutation_symbiosis,
		"red_micelial": EvoManager.mutation_red_micelial

	},
	"structural_state": {
		"epsilon_runtime": epsilon_runtime,
		"epsilon_peak": epsilon_peak,
		"omega": omega,
		"omega_min": omega_min,
		"biomasa": BiosphereEngine.biomasa,
		"hifas": BiosphereEngine.hifas,
		"accounting_level": UpgradeManager.level("accounting")
	},
	"post_final": {
		"homeostasis_mode": homeostasis_mode,
		"resilience_score": resilience_score,
		"legacy_homeostasis": legacy_homeostasis
	},
	"achievements": {
		"homeostasis": achievement_homeostasis,
		"homeostasis_perfect": achievement_homeostasis_perfect
	},
	"legacy": {
	"type": "ESPORULATION",
	"spores": BiosphereEngine.biomasa,
	"epsilon_peak": epsilon_peak,
	"hifas": BiosphereEngine.hifas,
	"run_time": run_time
}
}
	}

func _build_run_csv(meta: Dictionary) -> String:
	var csv := ""
	csv += "fecha;hora;tiempo_sesion;delta_total;dominio\n"
	csv += "%s;%s;%s;%s;%s\n" % [
		meta.fecha_humana,
		meta.hora_humana,
		UIManager.session_time_label.text if UIManager.session_time_label else "",
		UIManager.sys_delta_label.text if UIManager.sys_delta_label else "",
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
	t += (UIManager.click_stats_label.text if UIManager.click_stats_label else "") + "\n\n"

	t += "--- Sistema — Δ$ y dinámica ---\n"
	t += (UIManager.sys_delta_label.text if UIManager.sys_delta_label else "") + "\n\n"
	t += (UIManager.sys_active_passive_label.text if UIManager.sys_active_passive_label else "") + "\n\n"
	t += (UIManager.sys_breakdown_label.text if UIManager.sys_breakdown_label else "") + "\n\n"
	t += (UIManager.session_time_label.text if UIManager.session_time_label else "") + "\n\n"

	t += UIManager.lap_markers_label.text if UIManager.lap_markers_label else ""

	return t
func _on_ExportRunButton_pressed():
	LogManager.export_run(self)


func check_achievements():
	# Árbol completo
	if not unlocked_tree:
		var enough_upgrades = unlocked_d and unlocked_md and UpgradeManager.level("specialization") > 0 and unlocked_e and unlocked_me
		if enough_upgrades:
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
	if UIManager.system_message_label:
		UIManager.system_message_label.text = message

func update_achievements_label():
	var t := "--- Logros estructurales ---\n"
	if unlocked_tree: t += "✓ Árbol productivo completo\n"
	if unlocked_click_dominance: t += "✓ CLICK domina el sistema\n"
	if unlocked_delta_100: t += "✓ Δ$ ≥ 100 alcanzado\n"
	t += "\n--- Logros evolutivos ---\n"
	if achievement_homeostasis: t += "✓ HOMEOSTASIS\n"
	if achievement_homeostasis_perfect: t += "✓ HOMEOSTASIS PERFECTA\n"
	if achievement_symbiosis: t += "✓ SIMBIOSIS ESTRUCTURAL\n"
	if achievement_hyperassimilation: t += "✓ HIPERASIMILACIÓN\n"
	if achievement_red_micelial: t += "✓ RED MICELIAL\n"
	if achievement_sporulation: t += "✓ ESPORULACIÓN\n"
	if achievement_parasitism: t += "✓ PARASITISMO\n"

	if UIManager.system_achievements_label:
		UIManager.system_achievements_label.text = t


# =====================================================
#  CICLO DE VIDA
# =====================================================
func reset_local_state():
	money = 0.0
	persistence_dynamic = 1.4
	persistence_base = 1.4
	trueque_base_income = 8.0
	trueque_efficiency = 0.75
	mutation_auto_factor = 1.0
	mutation_trueque_factor = 1.0
	mutation_accounting_bonus = 0.0
	epsilon_runtime = 0.0
	epsilon_peak = 0.0
	delta_per_sec = 0.0
	total_money_generated = 0.0
	run_time = 0.0
	omega = 1.0
	omega_min = 1.0
	unlocked_d = false
	unlocked_md = false
	unlocked_e = false
	unlocked_me = false
	unlocked_tree = false
	unlocked_click_dominance = false
	unlocked_delta_100 = false
	achievement_homeostasis = false
	achievement_homeostasis_perfect = false
	achievement_hyperassimilation = false
	achievement_symbiosis = false
	achievement_red_micelial = false
	achievement_sporulation = false
	achievement_parasitism = false
	run_closed = false
	final_route = "NONE"
	final_reason = ""
	homeostasis_mode = false
	post_homeostasis = false
	resilience_score = 0.0
	homeostasis_timer = 0.0
	legacy_homeostasis = false
	
	if UIManager.system_message_label:
		UIManager.system_message_label.text = ""

func _ready():
	show()
	add_to_group("main")
	UIManager.setup(ui_root)
	LogManager.show_all_laps = false
	if UIManager.toggle_lap_button:
		UIManager.toggle_lap_button.text = "📜 Ver todos los eventos"
	if legacy_homeostasis:
		omega_min = max(omega_min, 0.15)
		# accounting_effect += 0.05 # This is now handled by get_accounting_effect()
	update_lap_toggle_button()
	if UIManager.export_run_button:
		UIManager.export_run_button.disabled = true
		UIManager.export_run_button.text = "📤 Export run (disponible al cerrar run)"
	update_ui()
	_mount_fungi_dlc()
	
	# === BOTÓN HARD RESET ===
	var reset_btn := Button.new()
	reset_btn.text = "⚠️ HARD RESET (Borrar save y reiniciar)"
	reset_btn.modulate = Color(1.0, 0.4, 0.4)
	reset_btn.pressed.connect(SaveManager.delete_save_and_restart)
	# Moverlo al principio del panel derecho para que sea visible siempre
	var right_panel = get_node("UIRootContainer/RightPanel")
	right_panel.add_child(reset_btn)
	right_panel.move_child(reset_btn, 0) # Lo pone arriba de todo
	# === EVO MANAGER SIGNALS ===
	EvoManager.mutation_activated.connect(_on_mutation_activated)
	EvoManager.run_ended_by_mutation.connect(close_run)

	# === TICK SYSTEM — Timers ===
	_logic_timer = Timer.new()
	_logic_timer.wait_time = LOGIC_TICK
	_logic_timer.autostart = true
	_logic_timer.timeout.connect(_on_logic_tick)
	add_child(_logic_timer)

	_ui_timer = Timer.new()
	_ui_timer.wait_time = UI_TICK
	_ui_timer.autostart = true
	_ui_timer.timeout.connect(_on_ui_tick)
	add_child(_ui_timer)

	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = AUTOSAVE_INTERVAL
	_autosave_timer.autostart = true
	_autosave_timer.timeout.connect(_on_autosave_tick)
	add_child(_autosave_timer)

	# Restaurar juego vía Autoload
	SaveManager.load_game(self)

func on_reactor_click():
	var power := get_click_power()
	money += power
	
	# El click ahora genera un pequeño pico de estrés runtime (v0.8.2)
	epsilon_runtime += 0.008 

	if is_instance_valid(UIManager.big_click_button):
		UIManager.big_click_button.set_active_delta(power)

	update_ui()
	
func register_reactor(rv: Node):
	reactor_visual = rv
	print("🧪 Reactor registrado:", rv)

func _mount_fungi_dlc():
	await get_tree().process_frame

	fungi_ui = FUNGI_UI_SCENE.instantiate()
	fungi_ui.name = "FungiUI"

	# 👇 AHORA VA DIRECTO AL STACK
	get_node("UIRootContainer/RightPanel").add_child(fungi_ui)

	fungi_ui.visible = true
	fungi_ui.set_main(self)

	# Opcional pero recomendado
	fungi_ui.size_flags_horizontal = Control.SIZE_FILL
	fungi_ui.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	print("🍄 Fungi DLC mounted (layout-aware)")
	adjust_scroll_for_dlc()

func get_dlc_height() -> float:
	if fungi_ui and fungi_ui.visible:
		if fungi_ui.has_method("get_min_height"):
			return fungi_ui.get_min_height()
		return 180.0 # fallback si es visible pero no hay método
	return 0.0 # No ocupa espacio si está oculto

func adjust_scroll_for_dlc():
	var h := get_dlc_height()
	var sc = get_node_or_null("UIRootContainer/RightPanel/ScrollContainer")
	if sc:
		sc.add_theme_constant_override("margin_top", int(h))

func _process(delta):
	# Solo lo que NECESITA 60 Hz: tiempo de sesión y animaciones
	run_time += delta
	_sync_reactor_color()
	_sync_reactor_preview()

func _on_logic_tick():
	# === 5 Hz — toda la lógica de simulación ===
	var dt := LOGIC_TICK

	# Cache mu (evita 500+ calls por segundo a get_mu_structural_factor)
	cached_mu = get_mu_structural_factor()

	# 1) Economía base
	apply_dynamic_persistence(dt)
	delta_per_sec = get_passive_total()
	update_economy(dt)

	# 2) Estrés del sistema
	update_epsilon_runtime()

	# 3) Biósfera y nutrientes
	epsilon_effective = BiosphereEngine.process_tick(dt, delta_per_sec, epsilon_runtime, EvoManager.mutation_hyperassimilation, EvoManager.mutation_homeostasis, EvoManager.mutation_symbiosis)

	# 4) Actualizar valor del reactor (sin disparar pulso — eso es solo en click)
	if is_instance_valid(UIManager.big_click_button):
		UIManager.big_click_button.set_display_delta(get_click_power())

	# 5) Parasitismo
	if EvoManager.mutation_parasitism:
		var drain = BiosphereEngine.biomasa * 0.015 * dt
		money = max(money - drain, 0.0)

	# 6) Genoma
	update_genome()

	# 7) Estrés post-red micelial
	if EvoManager.mutation_red_micelial and EvoManager.red_micelial_phase == 2 and not EvoManager.mutation_sporulation:
		epsilon_runtime += 0.01 * dt
		epsilon_peak = max(epsilon_peak, epsilon_runtime)

	# 8) Decisiones evolutivas
	if not EvoManager.mutation_homeostasis and not EvoManager.mutation_hyperassimilation:
		if is_homeostasis_candidate(dt):
			activate_homeostasis()
	if EvoManager.mutation_homeostasis:
		check_homeostasis_final(dt)
	if EvoManager.mutation_symbiosis:
		check_symbiosis_final(dt)
	if EvoManager.mutation_red_micelial:
		check_red_micelial_transition(dt)
		check_red_micelial_final(dt)
	if homeostasis_mode:
		update_homeostasis_mode(dt)
	if post_homeostasis:
		check_perfect_homeostasis()
	if EvoManager.mutation_parasitism:
		check_parasitism_final(dt)

	# 9) Cooldown estructural
	if structural_cooldown > 0.0:
		structural_cooldown -= dt
		if structural_cooldown <= 0.0:
			register_structural_baseline()

	# 10) Instituciones y esporulación
	check_institution_unlock()
	check_sporulation_trigger(dt)

func _on_ui_tick():
	# === 10 Hz — actualizar labels y botones ===
	update_ui()

func _on_autosave_tick():
	# === cada 30 s ===
	SaveManager.save_game(self)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		SaveManager.save_game(self)
		get_tree().quit()


# ESTRUCTURALES v0.7.3
func update_epsilon_runtime():
	if baseline_delta_structural <= 0.0 or delta_per_sec <= 0.0:
		epsilon_runtime = 0.0
		epsilon_active = 0.0
		epsilon_passive = 0.0
		epsilon_complex = 0.0
		return

	var n_struct := get_effective_structural_n()
	var k_eff := get_k_eff()

	# =================================================
	# 1) ε_activo — producción / composición (actual)
	# =================================================
	var expected_delta := baseline_delta_structural * pow(
		k_eff,
		1.0 - (1.0 / n_struct)
	)

	var epsilon_prod := 0.0
	if expected_delta > 0.0:
		epsilon_prod = max(0.0, (delta_per_sec / expected_delta) - 1.0)

	var active := get_click_power()
	var passive := get_passive_total()
	var total := active + passive

	var active_ratio := 0.0
	var passive_ratio := 0.0
	if total > 0.0:
		active_ratio = active / total
		passive_ratio = passive / total

	# target dinámico
	var t :float = clamp(n_struct / 40.0, 0.0, 1.0)
	var target_active :float = lerp(0.8, 0.4, t)

	var epsilon_comp :float = abs(active_ratio - target_active)
	epsilon_comp *= (1.0 - get_accounting_effect()) # Use function

	epsilon_active = epsilon_prod + epsilon_comp

	# =================================================
	# 2) ε_pasivo — rigidez / cristalización
	# =================================================
	epsilon_passive = 0.0

	if passive_ratio > PASSIVE_RATIO_START:
		var excess := passive_ratio - PASSIVE_RATIO_START
		var rigidity := (1.0 - omega)
		var size_factor := log(1.0 + n_struct) * 0.45
		epsilon_passive = excess * size_factor * rigidity * EPS_PASSIVE_SCALE * (1.0 - get_accounting_effect()) # Use function

	# =================================================
	# 3) Complejidad estructural
	# =================================================
	epsilon_complex = 0.0012 * n_struct * k_eff

	# =================================================
	# 4) Mezcla final
	# =================================================
	var epsilon_raw := epsilon_active + epsilon_passive + epsilon_complex


	epsilon_runtime = lerp(epsilon_runtime, epsilon_raw, 0.045)
	epsilon_runtime = clamp(epsilon_runtime, 0.0, 2.0)
	epsilon_peak = max(epsilon_peak, epsilon_runtime)

	# =================================================
	# 5) Ω (flexibilidad)
	# =================================================
	omega = EcoModel.get_omega(epsilon_runtime, k_eff, n_struct)
	if not EvoManager.mutation_homeostasis:
		omega_min = min(omega_min, omega)
	else:
		omega_min = max(omega_min, 0.30)

	# accounting_effect = 1.0 - exp(-0.3 * accounting_level) # Redundant, now a function
	# accounting_effect = clamp(accounting_effect, 0.0, 0.5) # Redundant, now a function
	# ====================================================
	#  6) DEBUG EPSILON OUTPUT v0.8.2
	# =====================================================
	if epsilon_debug:
		print("ε breakdown:",
		"act=", epsilon_active,
		"pas=", epsilon_passive,
		"cmp=", epsilon_complex,
		"Ω=", omega
	)
# =====================================================
#  DEBUG EPSILON PRINTOUT v0.8.2
# =====================================================
func debug_print_epsilon(
	e_act: float,
	e_pas: float,
	e_cmp: float,
	e_run: float,
	omega_val: float,
	n_struct: float,
	k_eff: float
) -> void:
	print(
		"[ε DEBUG]",
		"act=", snapped(e_act, 3),
		"pas=", snapped(e_pas, 3),
		"cmp=", snapped(e_cmp, 3),
		"| ε=", snapped(e_run, 3),
		"| Ω=", snapped(omega_val, 3),
		"| n=", snapped(n_struct, 2),
		"| κμ=", snapped(k_eff, 2)
	)
func _input(event):
	if event.is_action_pressed("ui_debug"):
		epsilon_debug = !epsilon_debug
		print("ε DEBUG =", epsilon_debug)


func check_institution_unlock():
	if institution_accounting_unlocked:
		return

	var p := get_structural_pressure()
	# vía 1 (ya existe): crisis
	if p > 15.0 and omega < 0.25 and epsilon_runtime > 0.3:
		unlock_accounting()

	# vía 2 (NUEVA): estabilidad sostenida
	elif run_time > 600.0 and epsilon_runtime < 0.15 and get_active_passive_breakdown().pasivo > 35.0:
		unlock_accounting()

func unlock_accounting():
	institution_accounting_unlocked = true
	institutions_unlocked = true
	if UpgradeManager.level("accounting") == 0:
		omega_min = max(omega_min, 0.30)
	add_lap("🏛️ Institución desbloqueada — Contabilidad Básica")
	if UIManager.system_message_label:
		UIManager.system_message_label.text = "El sistema se institucionaliza: nace la Contabilidad Básica"
	on_institutions_unlocked()	

# Handled via UpgradeManager now

#
# =====================================================
# 	Acumulación del histórico de dinero generado v0.7.2
func update_economy(delta):
	var delta_money = delta_per_sec * delta
	money += delta_money
	total_money_generated += delta_money


func format_time(t: float) -> String:
	return UIManager.format_time(t)

func update_epsilon_sticky():
	if not UIManager.epsilon_sticky_label: return
	
	var t := ""
	t += "%s ε runtime = %s\n" % [UIManager.epsilon_flag(epsilon_runtime, 0.30), snapped(epsilon_runtime, 0.01)]
	t += "Ω = %s (%s)\n" % [snapped(omega, 0.01), get_system_phase()]
	t += "Presión = %s" % snapped(get_structural_pressure(), 1)

	UIManager.epsilon_sticky_label.text = t

func get_system_phase() -> String:
	return UIManager.get_system_phase(omega)
func get_flexibility() -> float:
	return omega
# =====================================================
# DLC — INTERFAZ FUNGÍCA v0.8
func _on_Biosfera_pressed() -> void:
	print("🍄 Biosfera toggle")
	if fungi_ui:
		fungi_ui.visible = !fungi_ui.visible
		adjust_scroll_for_dlc()
# =====================================================
# UPGRADES CENTRALIZADOS (purchase_upgrade)
# =====================================================


# PERSISTENCIA ÚNICA
var persistence_upgrade_unlocked := false
const PERSISTENCE_NEW_VALUE := 1.6

func _on_BigClickButton_pressed():
	var power := get_click_power()
	money += power
	
	# El click ahora genera un pequeño pico de estrés runtime (v0.8.2)
	epsilon_runtime += 0.008 

	if is_instance_valid(UIManager.big_click_button):
		UIManager.big_click_button.set_active_delta(power)

	update_ui()

# =====================================================
#  DESBLOQUEO INSTITUCIONES v0.7.2
# =====================================================


func on_institutions_unlocked():
	print("Nueva capa estructural detectada: Instituciones")
	show_institutions_panel = true
	epsilon_runtime *= 0.85 # baja 15% el estrés
	epsilon_peak = max(epsilon_peak * 0.9, epsilon_runtime)

	add_lap("🏛️ Contabilidad — Nivel %d (ε amortiguado)" % UpgradeManager.level("accounting"))
# Handled via purchase_upgrade

# =====================================================
# UI HELPERS — v0.8
func update_core_labels():
	UIManager.update_money(money)
	if UIManager.formula_label:
		UIManager.formula_label.text = build_formula_text() + "\n" + build_formula_values()
	if UIManager.marginal_label:
		UIManager.marginal_label.text = build_marginal_contribution()
	
	# Update Reactor Visual Mutation State (Prioritizing active path)
	if reactor_visual:
		if EvoManager.mutation_parasitism:
			reactor_visual.set_mutation_state("parasitismo")
		elif EvoManager.mutation_hyperassimilation:
			reactor_visual.set_mutation_state("hyperassimilation")
		elif EvoManager.mutation_homeostasis:
			reactor_visual.set_mutation_state("homeostasis")
		elif EvoManager.mutation_symbiosis:
			reactor_visual.set_mutation_state("symbiosis")
		else:
			reactor_visual.set_mutation_state("default")
	
	update_click_stats_panel()

func build_institution_panel_text() -> String:
	var t := "--- Contabilidad Básica ---\n"

	t += "\n--- ε desglosado (Homeostasis) ---\n"
	t += "%s ε activo = %s\n" % [epsilon_flag(epsilon_active, 0.15), snapped(epsilon_active, 0.01)]
	t += "%s ε pasivo = %s\n" % [epsilon_flag(epsilon_passive, 0.12), snapped(epsilon_passive, 0.01)]
	t += "%s ε complejidad = %s\n" % [epsilon_flag(epsilon_complex, 0.08), snapped(epsilon_complex, 0.01)]
	
	t += "Ω_min = %s\n" % snapped(omega_min, 0.01)
	t += "Contabilidad = nivel %d\n" % UpgradeManager.level("accounting")
	t += "Amortiguación = %d%%\n" % int(get_accounting_effect() * 100.0)

	t += "\nε_peak = %s\n" % snapped(epsilon_peak, 0.01)
	

	t += build_genome_text()
	t += build_mutation_status_text()
	t += build_final_line()

	if homeostasis_mode:
		t += "\n\n⚖️ HOMEOSTASIS MODE"
		t += "\nResiliencia = %s" % snapped(resilience_score, 1)
		t += "\nPerturbaciones cada %ds" % DISTURBANCE_INTERVAL

	if EvoManager.mutation_red_micelial and EvoManager.red_micelial_phase == 2:
		t += "\n⚠️ La red no puede estabilizarse localmente"

	return t

func update_lab_metrics():
	var contrib := get_contribution_breakdown()
	var ap := get_active_passive_breakdown()

	if UIManager.sys_delta_label:
		UIManager.sys_delta_label.text = "Δ$ estimado / s = +%s" % snapped(contrib.total, 0.01)
	if UIManager.delta_total_label:
		UIManager.delta_total_label.text = "Δ$/s TOTAL  +" + str(snapped(contrib.total, 2))

	UIManager.update_timer(run_time)

	if UIManager.sys_active_passive_label:
		var txt = "--- Activo vs Pasivo ---\n"
		txt += "Activo (CLICK): %s%%\n" % snapped(ap.activo, 0.1)
		txt += "Pasivo (d+e): %s%%\n" % snapped(ap.pasivo, 0.1)
		txt += "Δ$ activo / s = +%s\n" % snapped(ap.push_abs, 0.01)
		txt += "Δ$ pasivo / s = +%s" % snapped(ap.passive_abs, 0.01)
		UIManager.sys_active_passive_label.text = txt

	if UIManager.sys_breakdown_label:
		var txt = "--- Distribución de aporte (productores) ---\n"
		txt += "Click: %s%%\n" % snapped(contrib.click, 0.1)
		txt += "Trabajo Manual: %s%%\n" % snapped(contrib.d, 0.1)
		txt += "Trueque: %s%%" % snapped(contrib.e, 0.1)
		UIManager.sys_breakdown_label.text = txt

func _sync_reactor_preview():
	if not is_instance_valid(reactor_visual):
		return

	# --- Mutación → color base ---
	var state := "neutral"
	if EvoManager.mutation_hyperassimilation:
		state = "hyperassimilation"
	elif EvoManager.mutation_homeostasis:
		state = "homeostasis"
	elif EvoManager.mutation_symbiosis:
		state = "symbiosis"
	elif EvoManager.mutation_parasitism:
		state = "parasitism"

	reactor_visual.set_mutation_state(state)

	# --- Intensidad por Δ$/s ---
	var delta_total := get_delta_total()
	var intensity :float = clamp(delta_total / 200.0, 0.0, 0.6)

	var base := Color(0.75, 0.75, 0.78)
	var final_color := base.lerp(Color.WHITE, intensity)

	reactor_visual.set_tint(final_color)
func _sync_reactor_color() -> void:
	if not is_instance_valid(reactor_visual):
		return

	# prioridad de mutaciones
	var state := "default"
	if EvoManager.mutation_hyperassimilation:
		state = "hyperassimilation"
	elif EvoManager.mutation_homeostasis:
		state = "homeostasis"
	elif EvoManager.mutation_symbiosis:
		state = "symbiosis"
	elif EvoManager.mutation_parasitism:
		state = "parasitism"

	reactor_visual.set_mutation_state(state)

	# Intensidad científica por Δ$/s (log suave)
	var delta_total := get_delta_total()
	var intensity :float = clamp(log(delta_total + 1.0) / 6.0, 0.0, 0.35)

	var base_color :Color = reactor_visual.target_tint
	var final_color :Color = base_color.lerp(Color.WHITE, intensity)

	reactor_visual.set_tint(final_color)
func update_buttons():
	for btn in get_tree().get_nodes_in_group("upgrade_buttons"):
		if btn.has_method("update_appearance"):
			btn.update_appearance(money)

func is_major_lap(event: String) -> bool:
	return LogManager.is_major(event)

func update_lap_log():
	LogManager.update_log_label(self)

func update_lap_toggle_button():
	LogManager.update_toggle_button(self)

func toggle_lap_view():
	LogManager.toggle_view(self)
# =====================================================


# =====================================================
#  UI — SOLO LEE RESULTADOS (v0.6.3 — HUD científico)
# =====================================================


func update_ui():
	update_epsilon_sticky()

	check_dominance_transition()
	check_achievements()
	update_achievements_label()
	update_core_labels()
	update_buttons()

	if institutions_unlocked:
		if UIManager.institution_panel_label:
			UIManager.institution_panel_label.visible = true
			UIManager.institution_panel_label.text = build_institution_panel_text()

	if institution_accounting_unlocked:
		pass # Los botones genéricos se encargan de visibilidad
	else:
		pass

	update_lab_metrics()
	update_lap_log()
	update_buttons()	

	# Habilitar Export Run al cerrar la run
	if run_closed and UIManager.export_run_button:
		UIManager.export_run_button.disabled = false
		UIManager.export_run_button.text = "📤 Export run"

func build_genome_text() -> String:
	var t := "🧬 GENOMA FÚNGICO\n"
	# --- Estado genómico ---
	t += "Hiperasimilación: " + EvoManager.genome.hiperasimilacion + "\n"
	t += "Parasitismo: " + EvoManager.genome.parasitismo + "\n"
	t += "Red micelial: " + EvoManager.genome.red_micelial + "\n"
	t += "Esporulación: " + EvoManager.genome.esporulacion + "\n"
	t += "Simbiosis: " + EvoManager.genome.simbiosis + "\n"

	# --- Ruta evolutiva activa ---
	if EvoManager.mutation_homeostasis:
		t += "\n⚖️ Ruta evolutiva: HOMEOSTASIS"
	elif EvoManager.mutation_hyperassimilation:
		t += "\n⚠️ Ruta evolutiva: HIPERASIMILACIÓN"
	elif EvoManager.mutation_symbiosis:
		t += "\n🌱 Ruta evolutiva: SIMBIOSIS"
	elif EvoManager.mutation_parasitism:
		t += "\n🦠 Ruta evolutiva: PARASITISMO"

	# --- Final de run ---
	if run_closed:
		t += "\n\n🏁 FINAL ALCANZADO: " + final_route

	return t
func build_mutation_status_text() -> String:
	var t := "\n--- Efectos mutacionales (actual) ---\n"

	# HIPERASIMILACIÓN
	if EvoManager.mutation_hyperassimilation:
		t += "⚠️ HIPERASIMILACIÓN: run cerrada — persistence_inertia = %s, Ω mod = ×0.75\n" % str(snapped(persistence_inertia, 2))

	elif EvoManager.genome.hiperasimilacion == "latente":
		t += "• Hiperasimilación (LATENTE)\n"

	# HOMEOSTASIS
	if EvoManager.mutation_homeostasis:
		t += "⚖️ HOMEOSTASIS: limitación biomasa, ε reducido, Ω_min aumentado\n"

	# SIMBIOSIS
	if EvoManager.mutation_symbiosis:
		t += "🌱 SIMBIOSIS: fungi_efficiency ×%s, trueque_efficiency ×%s, auto_mut ×%s\n" % [
			str(snapped(BiosphereEngine.absorption, 0.01)), 
			str(snapped(trueque_efficiency, 0.01)), 
			str(snapped(mutation_auto_factor, 0.01))
		]

	# RED MICELIAL
	if EvoManager.mutation_red_micelial:
		t += "🕸️ RED MICELIAL: Ω ×%s, bonus contabilidad +%s%%\n" % [str(snapped(omega, 0.01)), str(int(mutation_accounting_bonus * 100))]
	
	# PARASITISMO
	if EvoManager.mutation_parasitism:
		t += "🦠 PARASITISMO: Drenaje de biomasa, Ω reducido\n"

	return t

# =====================================================
#  PERSISTENCIA DE DATOS (Save/Load)
# =====================================================

func get_save_data() -> Dictionary:
	return {
		"economy": {
			"money": money,
			"persistence_dynamic": persistence_dynamic,
			"persistence_upgrade_unlocked": persistence_upgrade_unlocked
		},
		"dynamic_vars": {
			"trueque_base_income": trueque_base_income,
			"trueque_efficiency": trueque_efficiency,
			"mutation_auto_factor": mutation_auto_factor,
			"mutation_trueque_factor": mutation_trueque_factor,
			"mutation_accounting_bonus": mutation_accounting_bonus
		},
		"upgrades": UpgradeManager.serialize(),
		"structural": {
			"epsilon_runtime": epsilon_runtime,
			"epsilon_peak": epsilon_peak,
			"total_money_generated": total_money_generated,
			"run_time": run_time,
			"baseline_delta_structural": baseline_delta_structural,
			"omega": omega,
			"omega_min": omega_min,
			"institution_accounting_unlocked": institution_accounting_unlocked,
			"institutions_unlocked": institutions_unlocked
		},
		"flags": {
			"unlocked_d": unlocked_d,
			"unlocked_md": unlocked_md,
			"unlocked_e": unlocked_e,
			"unlocked_me": unlocked_me,
			"unlocked_tree": unlocked_tree,
			"unlocked_click_dominance": unlocked_click_dominance,
			"unlocked_delta_100": unlocked_delta_100,
			"run_closed": run_closed,
			"final_route": final_route,
			"final_reason": final_reason
		},
		"evolution": {
			"genome": EvoManager.genome,
			"mutation_homeostasis": EvoManager.mutation_homeostasis,
			"mutation_hyperassimilation": EvoManager.mutation_hyperassimilation,
			"mutation_symbiosis": EvoManager.mutation_symbiosis,
			"mutation_red_micelial": EvoManager.mutation_red_micelial,
			"mutation_sporulation": EvoManager.mutation_sporulation,
			"mutation_parasitism": EvoManager.mutation_parasitism,
			"red_micelial_phase": EvoManager.red_micelial_phase,
			"biomasa": BiosphereEngine.biomasa,
			"nutrientes": BiosphereEngine.nutrientes,
			"hifas": BiosphereEngine.hifas
		},
		"homeostasis": {
			"homeostasis_mode": homeostasis_mode,
			"post_homeostasis": post_homeostasis,
			"resilience_score": resilience_score,
			"homeostasis_timer": homeostasis_timer,
			"legacy_homeostasis": legacy_homeostasis
		},
		"laps": LogManager.get_lap_array()
	}

func _apply_save_data(data: Dictionary):
	if data.has("upgrades"):
		UpgradeManager.deserialize(data.upgrades)

	if data.has("economy"):
		var e = data.economy
		money = e.get("money", money)
		persistence_dynamic = e.get("persistence_dynamic", persistence_dynamic)
		persistence_upgrade_unlocked = e.get("persistence_upgrade_unlocked", persistence_upgrade_unlocked)
	
	if data.has("dynamic_vars"):
		var d = data.dynamic_vars
		trueque_base_income = d.get("trueque_base_income", trueque_base_income)
		trueque_efficiency = d.get("trueque_efficiency", trueque_efficiency)
		mutation_auto_factor = d.get("mutation_auto_factor", mutation_auto_factor)
		mutation_trueque_factor = d.get("mutation_trueque_factor", mutation_trueque_factor)
		mutation_accounting_bonus = d.get("mutation_accounting_bonus", mutation_accounting_bonus)

	if data.has("structural"):
		var s = data.structural
		epsilon_runtime = s.get("epsilon_runtime", epsilon_runtime)
		epsilon_peak = s.get("epsilon_peak", epsilon_peak)
		total_money_generated = s.get("total_money_generated", total_money_generated)
		run_time = s.get("run_time", run_time)
		baseline_delta_structural = s.get("baseline_delta_structural", baseline_delta_structural)
		omega = s.get("omega", omega)
		omega_min = s.get("omega_min", omega_min)
		institution_accounting_unlocked = s.get("institution_accounting_unlocked", institution_accounting_unlocked)
		institutions_unlocked = s.get("institutions_unlocked", institutions_unlocked)

	if data.has("flags"):
		var f = data.flags
		unlocked_d = f.get("unlocked_d", unlocked_d)
		unlocked_md = f.get("unlocked_md", unlocked_md)
		unlocked_e = f.get("unlocked_e", unlocked_e)
		unlocked_me = f.get("unlocked_me", unlocked_me)
		unlocked_tree = f.get("unlocked_tree", unlocked_tree)
		unlocked_click_dominance = f.get("unlocked_click_dominance", unlocked_click_dominance)
		unlocked_delta_100 = f.get("unlocked_delta_100", unlocked_delta_100)
		run_closed = f.get("run_closed", run_closed)
		final_route = f.get("final_route", final_route)
		final_reason = f.get("final_reason", final_reason)

	if data.has("evolution"):
		var ev = data.evolution
		EvoManager.genome = ev.get("genome", EvoManager.genome)
		EvoManager.mutation_homeostasis = ev.get("mutation_homeostasis", EvoManager.mutation_homeostasis)
		EvoManager.mutation_hyperassimilation = ev.get("mutation_hyperassimilation", EvoManager.mutation_hyperassimilation)
		EvoManager.mutation_symbiosis = ev.get("mutation_symbiosis", EvoManager.mutation_symbiosis)
		EvoManager.mutation_red_micelial = ev.get("mutation_red_micelial", EvoManager.mutation_red_micelial)
		EvoManager.mutation_sporulation = ev.get("mutation_sporulation", EvoManager.mutation_sporulation)
		EvoManager.mutation_parasitism = ev.get("mutation_parasitism", EvoManager.mutation_parasitism)
		EvoManager.red_micelial_phase = ev.get("red_micelial_phase", EvoManager.red_micelial_phase)
		BiosphereEngine.biomasa = ev.get("biomasa", BiosphereEngine.biomasa)
		BiosphereEngine.nutrientes = ev.get("nutrientes", BiosphereEngine.nutrientes)
		BiosphereEngine.hifas = ev.get("hifas", BiosphereEngine.hifas)

	if data.has("homeostasis"):
		var h = data.homeostasis
		homeostasis_mode = h.get("homeostasis_mode", homeostasis_mode)
		post_homeostasis = h.get("post_homeostasis", post_homeostasis)
		resilience_score = h.get("resilience_score", resilience_score)
		homeostasis_timer = h.get("homeostasis_timer", homeostasis_timer)
		legacy_homeostasis = h.get("legacy_homeostasis", legacy_homeostasis)

	# Bitácora de eventos
	if data.has("laps"):
		LogManager.load_laps(data["laps"])

	# Migración
	if not run_closed and (EvoManager.mutation_hyperassimilation or EvoManager.mutation_sporulation):
		run_closed = true
		final_route = final_route if final_route != "" else "MUTACION_FINAL"

	update_ui()
