extends Control

# =====================================================
# IDLE — v0.8 DLC "Fungi"
# =====================================================
#dlc
const FUNGI_UI_SCENE = preload("res://fungi.tscn")
var fungi_ui: Control

var reactor_visual: Node = null

# --- PERSISTENCIA ESTRUCTURAL (moved to StructuralModel.gd)
# VARIABLES DE DINÁMICA ECONÓMICA (moved to EconomyManager)

# NG+ Mente Colmena
var mente_colmena_active := false
var mente_colmena_timer := 0.0

# NG+ Depredador
var depredador_tick := 0.0

# CONSTANTES DE MODELO (moved to StructuralModel.gd)
const CLICK_RATE := 1.0

# OBSERVADORES DINÁMICOS (Caché por tick)
var cached_mu: float = 1.0
var mu_structural: float = 1.0

## =====================================================
# MÉTRICAS ESTRUCTURALES (moved to StructuralModel.gd)
# =====================================================

var delta_per_sec: float = 0.0

var pressure := 0.0
var pressure_structural := 0.0

var institutions_unlocked: bool = false
var show_institutions_panel: bool = false

# === ε PASIVO (v0.8) ===
const EPS_PASSIVE_SCALE := 0.24
const PASSIVE_RATIO_START := 0.60


# =============== SESIÓN / LAB MODE ===================

var run_time: float = 0.0
var lab_mode := true

# RunManager.final_reason movido a RunManager.gd
var show_final_details := false  # ya lo tenías; lo usamos para controlar detalles

var RUN_EXPORT_PATH := OS.get_user_data_dir() + "/IDLE_Fungi/runs"

# ========== DESBLOQUEO PROGRESIVO DE FÓRMULA (moved to StructuralModel.gd)

# === VERSION INFO ===
const VERSION := "0.8.2"
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
# Achievements moved to AchievementManager.gd


# === GENES FÚNGICOS ===
# Movidos a BiosphereEngine
# ===== BIOSFERA =====
# Movidos a BiosphereEngine
# === MUTACIONES ACTIVAS (flags reales) ===
# Movidas a EvoManager
# ================= REFERENCIAS UI ===================
# La mayoría movidas a UIManager.gd
@onready var ui_root = $UIRootContainer
@onready var evolution_bar = $UIRootContainer/LeftPanel/CenterPanel/EvolutionProgressBar
@onready var bottom_left_panel = $BottomLeftControls
@onready var evo_choice_panel = $EvoChoicePanel
@onready var btn_colonization = %BtnColonization
@onready var btn_symbiosis = %BtnSymbiosis
@onready var btn_homeostasis = %BtnHomeostasis
@onready var btn_evolve = %BtnEvolve
@onready var opt_homeostasis = %OptHomeostasis
@onready var opt_colonization = %OptColonization
@onready var opt_symbiosis = %OptSymbiosis
@onready var legacy_panel = $LegacyPanel
@onready var legacy_list = %LegacyList
@onready var pl_label = %PLLabel


# =====================================================
#  CAPA 1 — MODELO ECONÓMICO
# =====================================================

func get_click_power() -> float:
	return EconomyManager.get_click_power()

func get_auto_income_effective() -> float:
	return EconomyManager.get_auto_income_effective()

func get_trueque_raw() -> float:
	return EconomyManager.get_trueque_raw()

func get_trueque_income_effective() -> float:
	return EconomyManager.get_trueque_income_effective()

func get_passive_total() -> float:
	return EconomyManager.get_passive_total()

func get_delta_total() -> float:
	return EconomyManager.get_delta_total()

func get_mu_structural_factor() -> float:
	return StructuralModel.get_mu_structural_factor()



func get_biomass_beta() -> float:
	return BiosphereEngine.get_biomass_beta()

# ===== BIOSFERA MOVIDA A BiosphereEngine =====
# ============================
#  GENOMA FÚNGICO — v0.1
# ============================

# =====================================================
# EVOLUCIÓN BIOLÓGICA v0.8 DLC
# =====================================================
func update_genome():
	EvoManager.update_genome(self)

# === FUNCIONES DE LOGROS Y CICLO DE VIDA (Restauradas) ===
func close_run(route: String, reason: String):
	RunManager.close_run(route, reason)

func unlock_hyperassimilation_achievement():
	AchievementManager.unlock_hyperassimilation_achievement()

func unlock_sporulation_achievement():
	AchievementManager.unlock_sporulation_achievement()

func unlock_red_micelial_achievement():
	AchievementManager.unlock_red_micelial_achievement()

func enter_post_homeostasis():
	RunManager.enter_post_homeostasis()

func activate_sporulation():
	EvoManager.activate_mutation("esporulacion")

func activate_homeostasis():
	EvoManager.activate_mutation("homeostasis")

	
# =====================================================
# RUTA EVOLUTIVA - SEÑALES DE EVOMANAGER
# =====================================================

# === EFECTOS DE MUTACIÓN ===

var StructuralModel.persistence_inertia := 1.0

func apply_flexibility_modifier(factor: float):
	StructuralModel.apply_flexibility_modifier(factor)

func enable_StructuralModel.persistence_inertia(factor: float):
	StructuralModel.enable_StructuralModel.persistence_inertia(factor)

func apply_symbiotic_stabilization():
	# más flexibilidad estructural
	StructuralModel.omega = min(1.0, StructuralModel.omega * 1.25)

	# amortiguación permanente del estrés
	mutation_accounting_bonus = min(0.6, mutation_accounting_bonus + 0.15)

	# mejora pasivo sin romper el modelo
	trueque_efficiency *= 1.1
	mutation_auto_factor *= 1.05
# =====================================================
#  RUTA FINAL — detalles
# =====================================================
func build_final_line() -> String:
	if not RunManager.run_closed:
		return ""
	var t := "\n🏁 FINAL: %s" % RunManager.final_route
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
	return EconomyManager.get_dominant_term()

func get_contribution_breakdown() -> Dictionary:
	return EconomyManager.get_contribution_breakdown()

func get_active_passive_breakdown() -> Dictionary:
	return EconomyManager.get_active_passive_breakdown()


# =====================================================
#  CAPA 3 — fⁿ (OBSERVACIONAL) v0.6.2
# =====================================================


func get_n_log() -> float:
	return StructuralModel.get_n_log()

func get_n_power() -> float:
	return StructuralModel.get_n_power()


# =====================================================
#  FUNCIÓN SIGMOIDE fⁿ α V0.6.2
# =====================================================
func f_n_alpha(n: float) -> float:
	return 1.0 / (1.0 + exp(-0.35 * (n - 6.0)))

func apply_dynamic_persistence(delta: float) -> void:
	StructuralModel.apply_dynamic_persistence(delta)


# === Persistencia estructural ===
# c₀  → baseline fijo
# fⁿ  → objetivo teórico según n
# cₙ  → estado dinámico observado

func get_persistence_target() -> float:
	return StructuralModel.get_persistence_target()

func get_cognitive_mu() -> float:
	return StructuralModel.get_cognitive_mu()


# =====================================================
#  MODELO ESTRUCTURAL — v0.6.4
#  fⁿ(teórico), cₙ(teórico), ε(modelo)
# =====================================================

func compute_structural_model() -> Dictionary:
	return StructuralModel.compute_structural_model()

func get_structural_epsilon() -> float:
	return StructuralModel.get_structural_epsilon()

func get_k_eff() -> float:
	return StructuralModel.get_k_eff()

func register_structural_baseline():
	StructuralModel.register_structural_baseline()

func get_omega(epsilon: float, k_mu: float, n: float) -> float:
	return StructuralModel.get_omega(epsilon, k_mu, n)

# -----------------------------------------------------
#  RUNTIME — contraste observacional (secundario)
# -----------------------------------------------------
func compute_structural_runtime() -> float:
	return StructuralModel.compute_structural_runtime()

func update_structural_hud_model_block() -> Dictionary:
	return StructuralModel.update_structural_hud_model_block()

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
	return StructuralModel.get_structural_pressure()

func get_accounting_effect() -> float:
	return StructuralModel.get_accounting_effect()

func get_structural_upgrades() -> int:
	return StructuralModel.get_structural_upgrades()

func get_effective_structural_n() -> float:
	return StructuralModel.get_effective_structural_n()

func purchase_upgrade(id: String) -> void:
	var cost = UpgradeManager.cost(id)
	if EconomyManager.money >= cost:
		if UpgradeManager.buy(id, EconomyManager.money):
			EconomyManager.money -= cost
			_on_upgrade_bought_actions(id)
			update_ui()
			add_lap("Comprado: " + UpgradeManager.get_def(id).label)

func _on_upgrade_bought_actions(id: String) -> void:
	StructuralModel.structural_cooldown = STRUCTURAL_COOLDOWN_TIME
	match id:
		"auto":
			if not StructuralModel.unlocked_d:
				StructuralModel.unlocked_d = true
				add_lap("🟢 Desbloqueado d (Trabajo Manual)")
		"auto_mult":
			if not StructuralModel.unlocked_md:
				StructuralModel.unlocked_md = true
				add_lap("🟢 Desbloqueado md (Ritmo de Trabajo)")
		"trueque":
			if not StructuralModel.unlocked_e:
				StructuralModel.unlocked_e = true
				add_lap("🔵 Desbloqueado e (Trueque)")
		"trueque_net":
			if not StructuralModel.unlocked_me:
				StructuralModel.unlocked_me = true
				add_lap("🔵 Desbloqueado me (Red de Intercambio)")
		"specialization":
			if UpgradeManager.level("specialization") == 1:
				add_lap("🎓 Especialización de Oficio Activa")
		"cognitive":
			pass
		"persistence":
			StructuralModel.persistence_base = UpgradeManager.value("persistence") 
			if not StructuralModel.persistence_upgrade_unlocked:
				StructuralModel.persistence_upgrade_unlocked = true
				add_lap("💾 Memoria Operativa: c₀ incrementado un 25% (1.75)")
		"accounting":
			if UpgradeManager.level("accounting") == 1:
				omega = max(omega, 0.45) # Subido de 0.38
				StructuralModel.omega_min = max(StructuralModel.omega_min, 0.45) # Limpiamos historial de errores previos
				institutions_unlocked = true
				StructuralModel.institution_accounting_unlocked = true
				add_lap("⚖️ Ventana institucional — arquitectura reorganizada")
			StructuralModel.epsilon_runtime *= 0.85
			StructuralModel.epsilon_peak = max(StructuralModel.epsilon_peak * 0.9, StructuralModel.epsilon_runtime)
# =====================================================
#  HOMEOSTASIS TRACKING helper v0.8
# =====================================================
func is_homeostasis_candidate(_delta: float) -> bool:
	# Retorna TRUE si las condiciones actuales se cumplen (para habilitar el botón)
	var banda_estricta = get_en_banda_homeostatica()
	var flexibilidad_minima = StructuralModel.omega> 0.25
	var control_activo = UpgradeManager.level("accounting") >= 1
	var metabolismo_activo = delta_per_sec > 30.0
	var crecimiento_controlado = BiosphereEngine.biomasa < 12.0
	var redundancia = StructuralModel.unlocked_d and StructuralModel.unlocked_e
	
	var no_hyper := not EvoManager.mutation_hyperassimilation
	# 🔒 BLOQUEO: Red Micelial madura no puede homeostasiar
	var red_blocks_homeostasis := EvoManager.mutation_red_micelial and EvoManager.red_micelial_phase == 2

	return banda_estricta and flexibilidad_minima and control_activo and metabolismo_activo and crecimiento_controlado and redundancia and no_hyper and not red_blocks_homeostasis
# =====================================================
#  RUTA FINAL DE LA RUN v0.8
# =====================================================
func get_final_route() -> String:
	if RunManager.final_route != "NONE":
		return RunManager.final_route
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
	# si tenemos RunManager.final_reason explícito, lo devolvemos; si no, generamos un texto por ruta
	if RunManager.final_reason != "" :
		return RunManager.final_reason

	match RunManager.final_route:
		"HOMEOSTASIS":
			return "Estabilidad estructural priorizada — run cerrada por homeostasis"
		"ALLOSTASIS":
			return "Estabilidad a través del cambio — setpoint adaptativo alcanzado"
		"HOMEORHESIS":
			return "Transformación irreversible — el sistema trasciende la regulación"
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
func get_en_banda_homeostatica() -> bool:
	return RunManager.get_en_banda_homeostatica()

func check_homeostasis_final(delta: float):
	RunManager.check_homeostasis_final(delta)

func check_allostasis_final(delta: float):
	RunManager.check_allostasis_final(delta)

func check_homeorhesis_final(delta: float):
	RunManager.check_homeorhesis_final(delta)

func check_symbiosis_final(delta: float):
	RunManager.check_symbiosis_final(delta)

func check_parasitism_final(delta: float):
	RunManager.check_parasitism_final(delta)

func check_sporulation_trigger(delta: float):
	RunManager.check_sporulation_trigger(delta)

func update_homeostasis_mode(delta: float):
	RunManager.update_homeostasis_mode(delta)

func trigger_disturbance():
	RunManager.trigger_disturbance()

func check_perfect_homeostasis():
	RunManager.check_perfect_homeostasis()
# =====================================================
#  TOOLTIP HIPERASIMILACIÓN v0.8
# =====================================================
func get_hyperassimilation_tooltip() -> String:
	if EvoManager.genome.get("hiperasimilacion","dormido") == "bloqueado":
		return "Bloqueada por HOMEOSTASIS o SIMBIOSIS"

	if EvoManager.genome.hiperasimilacion == "activo":
		return "Absorción total priorizada. Estabilidad ignorada."

	var t := "Hiperasimilación (LATENTE)\n"
	if StructuralModel.epsilon_runtime <= 0.6:
		t += "• ε insuficiente\n"
	if BiosphereEngine.biomasa <= 5.0:
		t += "• Biomasa insuficiente\n"
	if StructuralModel.omega>= 0.30:
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
		"c_n": StructuralModel.persistence_dynamic,

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
		"epsilon_runtime": StructuralModel.epsilon_runtime,
		"epsilon_peak": StructuralModel.epsilon_peak,
		"omega": StructuralModel.omega,
		"omega_min": StructuralModel.omega_min,
		"biomasa": BiosphereEngine.biomasa,
		"hifas": BiosphereEngine.hifas,
		"accounting_level": UpgradeManager.level("accounting")
	},
	"post_final": {
		"homeostasis_mode": RunManager.homeostasis_mode,
		"resilience_score": RunManager.resilience_score,
		"legacy_homeostasis": RunManager.legacy_homeostasis
	},
	"achievements": AchievementManager.get_achievements_dict(),
	"legacy": {
	"type": "ESPORULATION",
	"spores": BiosphereEngine.biomasa,
	"epsilon_peak": StructuralModel.epsilon_peak,
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
		var enough_upgrades = StructuralModel.unlocked_d and StructuralModel.unlocked_md and UpgradeManager.level("specialization") > 0 and StructuralModel.unlocked_e and StructuralModel.unlocked_me
		if enough_upgrades:
			unlocked_tree = true
			add_lap("🏁 Logro — Árbol productivo completo")
			show_system_toast("LOGRO ESTRUCTURAL — Sistema productivo completo")
	# Dominancia click (Solo si hay algo contra qué competir)
	if not unlocked_click_dominance and (StructuralModel.unlocked_d or StructuralModel.unlocked_e):
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

	# Logros movidos a AchievementManager
	AchievementManager.check_achievements()
func show_system_toast(message: String) -> void:
	if UIManager.system_message_label:
		UIManager.system_message_label.text = message

func update_achievements_label():
	var t := "--- Logros estructurales ---\n"
	if unlocked_tree: t += "✓ Árbol productivo completo\n"
	if unlocked_click_dominance: t += "✓ CLICK domina el sistema\n"
	if unlocked_delta_100: t += "✓ Δ$ ≥ 100 alcanzado\n"
	if AchievementManager.achievement_millionaire: t += "✓ Millonario de Esporas\n"
	if AchievementManager.achievement_fragile_balance: t += "✓ Equilibrio Frágil\n"
	t += "\n--- Logros evolutivos ---\n"
	if AchievementManager.achievement_homeostasis: t += "✓ HOMEOSTASIS\n"
	if AchievementManager.achievement_homeostasis_perfect: t += "✓ HOMEOSTASIS PERFECTA\n"
	if AchievementManager.achievement_symbiosis: t += "✓ SIMBIOSIS ESTRUCTURAL\n"
	if AchievementManager.achievement_hyperassimilation: t += "✓ HIPERASIMILACIÓN\n"
	if AchievementManager.achievement_red_micelial: t += "✓ RED MICELIAL\n"
	if AchievementManager.achievement_sporulation: t += "✓ ESPORULACIÓN\n"
	if AchievementManager.achievement_parasitism: t += "✓ PARASITISMO\n"
	if AchievementManager.achievement_insatiable_parasite: t += "✓ PARÁSITO INSACIABLE\n"

	if UIManager.system_achievements_label:
		UIManager.system_achievements_label.text = t


# =====================================================
#  CICLO DE VIDA
# =====================================================
func reset_local_state():
	EconomyManager.reset()
	StructuralModel.reset()
	delta_per_sec = 0.0
	run_time = 0.0
	unlocked_tree = false
	unlocked_click_dominance = false
	unlocked_delta_100 = false
	AchievementManager.achievement_homeostasis = false
	AchievementManager.achievement_homeostasis_perfect = false
	AchievementManager.achievement_hyperassimilation = false
	AchievementManager.achievement_symbiosis = false
	AchievementManager.achievement_red_micelial = false
	AchievementManager.achievement_sporulation = false
	AchievementManager.achievement_parasitism = false
	AchievementManager.achievement_millionaire = false
	AchievementManager.achievement_fragile_balance = false
	AchievementManager.achievement_insatiable_parasite = false
	RunManager.reset()
	
	if UIManager.system_message_label:
		UIManager.system_message_label.text = ""

func _ready():
	show()
	add_to_group("main")
	UIManager.setup(ui_root)
	LogManager.show_all_laps = false
	update_lap_toggle_button()
	if RunManager.legacy_homeostasis:
		StructuralModel.omega_min = max(StructuralModel.omega_min, 0.15)
	
	if LegacyManager.last_run_ending == "HOMEOSTASIS" or LegacyManager.last_run_ending == "ALLOSTASIS":
		RunManager.homeostasis_mode = true
		RunManager.post_homeostasis = true # Allows perfect homeostasis legacy to proc, or just perturbations
		
	update_lap_toggle_button()
	if UIManager.export_run_button:
		UIManager.export_run_button.disabled = true
		UIManager.export_run_button.text = "📤 Export run (disponible al cerrar run)"
		
	update_ui()

	# Inicializar managers con referencia a main
	RunManager.set_main(self)
	AchievementManager.set_main(self)
	EconomyManager.set_main(self)
	StructuralModel.set_main(self)

	# Hotpatch: Inyectar trueque_allo si no existe (para evitar reinicio)
	if not UpgradeManager.states.has("trueque_allo"):
		var def = load("res://upgrades/trueque_allo.tres")
		if def:
			UpgradeManager._defs.append(def)
			UpgradeManager.states["trueque_allo"] = {
				"level": 0,
				"current_cost": def.base_cost,
				"current_value": def.base_value,
				"unlocked": false
			}

	_mount_fungi_dlc()

	# === CONTROLES MINIMALISTAS (SUPERIOR IZQUIERDA) ===
	var menu_btn := Button.new()
	menu_btn.text = "🏠 Menú"
	menu_btn.add_theme_font_size_override("font_size", 12)
	menu_btn.pressed.connect(func():
		print("💾 Guardando y volviendo al menú...")
		SaveManager.save_game(self)
		get_tree().change_scene_to_file("res://MainMenu.tscn")
	)
	bottom_left_panel.add_child(menu_btn)

	var bios_btn := Button.new()
	bios_btn.text = "🌱 Biosfera"
	bios_btn.toggle_mode = true
	bios_btn.button_pressed = true
	bios_btn.add_theme_font_size_override("font_size", 12)
	bios_btn.toggled.connect(func(pressed):
		# 1. Ocultar estadísticas de ingeniería (grises)
		var bp = get_node_or_null("UIRootContainer/RightPanel/EpsilonStickyPanel")
		if bp: bp.visible = pressed
		
		# 2. Ocultar el Fungi DLC (violeta)
		if is_instance_valid(fungi_ui):
			fungi_ui.visible = pressed
	)
	bottom_left_panel.add_child(bios_btn)

	var reset_btn := Button.new()
	reset_btn.text = "⚠️ Reset"
	reset_btn.modulate = Color(0.8, 0.4, 0.4)
	reset_btn.add_theme_font_size_override("font_size", 10)
	reset_btn.pressed.connect(SaveManager.delete_save_and_restart)
	bottom_left_panel.add_child(reset_btn)
	
	var legacy_btn := Button.new()
	legacy_btn.text = "🧬 Banco Genético"
	legacy_btn.add_theme_font_size_override("font_size", 11)
	legacy_btn.pressed.connect(_on_legacy_pressed)
	bottom_left_panel.add_child(legacy_btn)

	# === EVO MANAGER SIGNALS ===
	EvoManager.mutation_activated.connect(_on_mutation_activated)
	EvoManager.run_ended_by_mutation.connect(close_run)
	EvoManager.primordio_iniciado.connect(_on_primordio_iniciado)
	EvoManager.primordio_abortado.connect(_on_primordio_abortado)
	EvoManager.seta_formada_signal.connect(_on_seta_formada)
	
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

	# --- EMERGENCY RE-OPEN (v0.8.43) ---
	# Si la run se cerró por el bug del Legado, la reabrimos
	if RunManager.run_closed and RunManager.final_route == "ESPORULACION TOTAL" and not EvoManager.mutation_sporulation:
		RunManager.run_closed = false
		RunManager.final_route = "NONE"
		RunManager.final_reason = ""
		print("🛠️ Recuperando run cerrada por bug")

	# --- RECUPERACIÓN DE ESTADO PENDIENTE (v0.8.8) ---
	# Si cargamos una partida donde la mutación está activa pero no se eligió rama
	if EvoManager.mutation_red_micelial and EvoManager.red_branch_selected == EvoManager.RedBranch.NONE:
		if is_instance_valid(evo_choice_panel) and not RunManager.run_closed:
			dimmer.visible = true
			evo_choice_panel.visible = true
			print("🚨 Recuperando elección de rama pendiente")

func on_reactor_click(epsilon_delta: float = 0.015):
	EconomyManager.time_since_last_click = 0.0
	var power := get_click_power()
	EconomyManager.money += power

	# El click ahora genera un pequeño pico de estrés runtime (v0.8.2)
	StructuralModel.epsilon_runtime += epsilon_delta

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
	time_since_last_click += delta
	_sync_reactor_color()

func _on_logic_tick():
	# === 5 Hz — toda la lógica de simulación ===
	var dt := LOGIC_TICK

	# Cache mu (evita 500+ calls por segundo a get_mu_structural_factor)
	cached_mu = get_mu_structural_factor()

	# NG+ Mente Colmena (Juego automático por IA fúngica)
	if mente_colmena_active:
		var sim_power = get_click_power() * 10.0 * dt
		EconomyManager.money += sim_power
		StructuralModel.epsilon_runtime += 0.008 * 10.0 * dt
		if is_instance_valid(UIManager.big_click_button):
			UIManager.big_click_button.set_active_delta(sim_power)
	elif LegacyManager.last_run_ending == "SINGULARIDAD" and EvoManager.red_branch_selected == EvoManager.RedBranch.SYMBIOSIS:
		var ap = get_active_passive_breakdown()
		var tot = ap.activo + ap.pasivo
		if tot > 0:
			var ratio = ap.activo / tot
			if abs(ratio - 0.5) <= 0.02:
				mente_colmena_timer += dt
				if mente_colmena_timer >= 180.0:
					activate_mente_colmena()
			else:
				mente_colmena_timer = 0.0

	# NG+ Depredador de Realidades (Glitch Survival)
	if EvoManager.mutation_depredador:
		depredador_tick += dt
		if depredador_tick >= 1.5:
			depredador_tick = 0.0
			var devoured = UpgradeManager.devour_random_upgrade()
			if devoured:
				BiosphereEngine.biomasa += 15.0 # Massive biomassa growth
				show_system_toast("⚠️ GLITCH: El hongo ha digerido memoria estructural.")
				if is_instance_valid(UIManager.big_click_button):
					UIManager.big_click_button.modulate = Color(randf(), randf(), randf())
			else:
				close_run("DEPREDADOR DE REALIDADES", "El hongo ha consumido todo tu código fuente. Ya no existes. (+12 PL)")

	# 1) Economía base
	apply_dynamic_persistence(dt)
	delta_per_sec = get_passive_total()
	update_economy(dt)

	# 2) Estrés del sistema
	update_epsilon_runtime()

	# 3) Biósfera y nutrientes
	StructuralModel.epsilon_effective = BiosphereEngine.process_tick(
		dt, 
		delta_per_sec, 
		StructuralModel.epsilon_runtime, 
		EvoManager.mutation_hyperassimilation, 
		EvoManager.mutation_homeostasis, 
		EvoManager.mutation_symbiosis,
		EvoManager.mutation_red_micelial,
		EvoManager.mutation_parasitism
	)

	# 4) Actualizar valor del reactor
	var power := get_click_power()
	if is_instance_valid(UIManager.big_click_button):
		UIManager.big_click_button.set_display_delta(power)
		UIManager.big_click_button.text = "+%.1f" % power

	# 5) Parasitismo: drenaje masivo de ingresos (Corrosión Estructural)
	if EvoManager.mutation_parasitism:
		var drain_intensity = clamp(BiosphereEngine.biomasa / 15.0, 0.4, 3.0)
		# Corrosión irreversible de la infraestructura
		EconomyManager.parasitism_corrosion = max(0.0, EconomyManager.parasitism_corrosion - 0.002 * drain_intensity * dt)
		
		# Drenaje de liquidez directa
		var money_drain = BiosphereEngine.biomasa * 0.25 * dt
		EconomyManager.money = max(EconomyManager.money - money_drain, 0.0)

	# 6) Genoma
	update_genome()

	# 7) Estrés post-red micelial
	if EvoManager.mutation_red_micelial and EvoManager.red_micelial_phase == 2 and not EvoManager.mutation_sporulation:
		StructuralModel.epsilon_runtime += 0.01 * dt
		StructuralModel.epsilon_peak = max(StructuralModel.epsilon_peak, StructuralModel.epsilon_runtime)
		
	# 8) Actualizar Omega (Flexibilidad)
	# Buff: El capital cognitivo (cached_mu) ahora ayuda a manejar la complejidad (n_struct)
	var complexity_impact: float	 = get_effective_structural_n() / max(cached_mu, 1.0)
	omega = 1.0 / max(1.0 + StructuralModel.epsilon_effective * complexity_impact, 0.0001)
		
	# --- SHOCK TRACKING ---
	if StructuralModel.epsilon_effective > 0.8:
		# Si superamos 0.8 y el juego no se ha cerrado por colapso, significa que estamos sobreviviendo un shock extremo
		RunManager.extreme_shock_survived = true
		
	if RunManager.is_recovering_from_shock and get_en_banda_homeostatica():
		RunManager.disturbances_survived += 1
		RunManager.is_recovering_from_shock = false
		add_lap("💚 SHOCK ESTABILIZADO. Total: " + str(RunManager.disturbances_survived))

	# 8) Decisiones evolutivas (v0.8.8 - Centralizado en EvoManager)
	if EvoManager.mutation_homeostasis:
		check_homeostasis_final(dt)
	if EvoManager.mutation_allostasis:
		check_allostasis_final(dt)
	if EvoManager.mutation_homeorhesis:
		check_homeorhesis_final(dt)
	if EvoManager.mutation_symbiosis:
		check_symbiosis_final(dt)
	if EvoManager.mutation_red_micelial:
		EvoManager.check_red_micelial_transition(self)
		EvoManager.update_primordio(self)  # Timer del ciclo biológico
	if RunManager.homeostasis_mode:
		update_homeostasis_mode(dt)
	if RunManager.post_homeostasis:
		check_perfect_homeostasis()
	if EvoManager.mutation_parasitism:
		check_parasitism_final(dt)

	# 9) Cooldown estructural
	if StructuralModel.structural_cooldown > 0.0:
		StructuralModel.structural_cooldown -= dt
		if StructuralModel.structural_cooldown <= 0.0:
			register_structural_baseline()

	# 10) Instituciones y esporulación
	check_institution_unlock()
	check_sporulation_trigger(dt)

func _on_ui_tick():
	# === 10 Hz — actualizar labels y botones ===
	update_ui()
	_update_evolution_progress_bar()

func _update_evolution_progress_bar():
	if RunManager.run_closed or not is_instance_valid(evolution_bar):
		evolution_bar.visible = false
		return
		
	var show_bar := false
	var current_val := 0.0
	var max_val := 60.0 # Default
	
	if EvoManager.mutation_homeostasis:
		current_val = RunManager.homeostasis_timer
		max_val = RunManager.HOMEOSTASIS_TIME_REQUIRED
		show_bar = true # Siempre visible si la ruta está activa
			
	# En el futuro podemos añadir aquí Simbiosis, Esporulación, etc.
	
	evolution_bar.visible = show_bar
	if show_bar:
		evolution_bar.max_value = max_val
		evolution_bar.value = current_val
		
func _on_autosave_tick():
	# === cada 30 s ===
	SaveManager.save_game(self)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		SaveManager.save_game(self)
		get_tree().quit()

# =====================================================
#  SISTEMA DE MUTACIONES Y BIFURCACIONES (v0.8.5)
# =====================================================

@onready var dimmer = $DimmerBackground

func _on_mutation_activated(id: String, display_name: String):
	LogManager.add("🧬 Mutación irreversible — " + display_name, self)
	
	if id == "red_micelial":
		# Activar el popup de elección (v0.8.32 - Modular)
		dimmer.visible = true
		evo_choice_panel.visible = true
		update_bifurcation_panel()
	
	update_ui()

func update_bifurcation_panel():
	if not is_instance_valid(evo_choice_panel) or not evo_choice_panel.visible:
		return
		
	var hifas = BiosphereEngine.hifas
	
	# MODO TIER 1: Selección inicial
	if not (EvoManager.mutation_red_micelial or EvoManager.mutation_homeostasis or EvoManager.mutation_symbiosis):
		evo_choice_panel.get_node("Margin/VBox/TopBar/Header").text = "MUTACIÓN DETECTADA (TIER 1)"
		opt_homeostasis.visible = true
		
		var acc_lvl = UpgradeManager.level("accounting")
		var act_domina = get_active_passive_breakdown().activo > get_active_passive_breakdown().pasivo
		
		# Homeostasis (Nuevas reglas Tier 1)
		var h_ok_eps = get_en_banda_homeostatica()
		var h_ok_omega = StructuralModel.omega> 0.25
		var h_ok_delta = delta_per_sec > 30.0
		var h_ok_bio = BiosphereEngine.biomasa < 12.0
		var h_ok_acc = acc_lvl >= 1
		var h_ok_red = StructuralModel.unlocked_d and StructuralModel.unlocked_e
		var h_txt = "[center]HOMEOSTASIS\nOrden administrativo.\n\n"
		h_txt += "[color=%s]%s 0.03 < ε < 0.30[/color]\n" % ["#00ff00" if h_ok_eps else "#ff4444", "[x]" if h_ok_eps else "[ ]"]
		h_txt += "[color=%s]%s Flexibilidad Ω > 0.25[/color]\n" % ["#00ff00" if h_ok_omega else "#ff4444", "[x]" if h_ok_omega else "[ ]"]
		h_txt += "[color=%s]%s Metabolismo > 30/s[/color]\n" % ["#00ff00" if h_ok_delta else "#ff4444", "[x]" if h_ok_delta else "[ ]"]
		h_txt += "[color=%s]%s Biomasa < 12[/color]\n" % ["#00ff00" if h_ok_bio else "#ff4444", "[x]" if h_ok_bio else "[ ]"]
		h_txt += "[color=%s]%s Contabilidad >= 1[/color]\n" % ["#00ff00" if h_ok_acc else "#ff4444", "[x]" if h_ok_acc else "[ ]"]
		h_txt += "[color=%s]%s Trabajo y Trueque (d+e)[/color]\n" % ["#00ff00" if h_ok_red else "#ff4444", "[x]" if h_ok_red else "[ ]"]
		
		# Feedback de cuenta regresiva
		if EvoManager.mutation_homeostasis:
			if RunManager.homeostasis_timer > 0.1:
				var ratio = min(RunManager.homeostasis_timer / RunManager.HOMEOSTASIS_TIME_REQUIRED, 1.0) * 100.0
				h_txt += "\n[color=#ffff00]Estabilizando... %d%%[/color][/center]" % int(ratio)
			else:
				h_txt += "\n[color=#555555]Iniciando estabilización...[/color][/center]"
		else:
			# Si aún no le dió click al botón
			h_txt += "\n[color=#555555]Requiere sostenerse por 18s tras activarse.[/color][/center]"
			
		opt_homeostasis.find_child("Desc").text = h_txt
		btn_homeostasis.text = "Equilibrar"
		btn_homeostasis.disabled = not EvoManager.is_homeostasis_ready()
		
		# Red Micelial
		var r_ok_hifas = hifas >= 11.5
		var r_ok_bio = BiosphereEngine.biomasa >= 5.0
		var r_ok_eps = StructuralModel.epsilon_runtime < 0.65
		var r_ok_acc = acc_lvl >= 1
		var r_ok_dom = not act_domina
		var r_txt = "[center]RED MICELIAL\nExpansión pasiva.\n\n"
		r_txt += "[color=%s]%s Hifas >= 11.5[/color]\n" % ["#00ff00" if r_ok_hifas else "#ff4444", "[x]" if r_ok_hifas else "[ ]"]
		r_txt += "[color=%s]%s Biomasa >= 5.0[/color]\n" % ["#00ff00" if r_ok_bio else "#ff4444", "[x]" if r_ok_bio else "[ ]"]
		r_txt += "[color=%s]%s ε < 0.65[/color]\n" % ["#00ff00" if r_ok_eps else "#ff4444", "[x]" if r_ok_eps else "[ ]"]
		r_txt += "[color=%s]%s Contabilidad >= 1[/color]\n" % ["#00ff00" if r_ok_acc else "#ff4444", "[x]" if r_ok_acc else "[ ]"]
		r_txt += "[color=%s]%s Dominio Pasivo[/color][/center]" % ["#00ff00" if r_ok_dom else "#ff4444", "[x]" if r_ok_dom else "[ ]"]
		evo_choice_panel.find_child("OptColonization", true, false).find_child("Icon").text = "🕸️"
		evo_choice_panel.find_child("OptColonization", true, false).find_child("Desc").text = r_txt
		btn_colonization.text = "Ramificar"
		btn_colonization.disabled = not EvoManager.is_red_micelial_ready()
		
		# Simbiosis
		var s_ok_hifas = hifas >= 5.0
		var s_ok_eps = StructuralModel.epsilon_runtime >= 0.15 and StructuralModel.epsilon_runtime <= 0.45
		var s_ok_acc = acc_lvl >= 1
		var s_ok_dom = act_domina
		var s_txt = "[center]SIMBIOSIS\nFusión activa.\n\n"
		s_txt += "[color=%s]%s Hifas >= 5.0[/color]\n" % ["#00ff00" if s_ok_hifas else "#ff4444", "[x]" if s_ok_hifas else "[ ]"]
		s_txt += "[color=%s]%s ε (0.15 - 0.45)[/color]\n" % ["#00ff00" if s_ok_eps else "#ff4444", "[x]" if s_ok_eps else "[ ]"]
		s_txt += "[color=%s]%s Contabilidad >= 1[/color]\n" % ["#00ff00" if s_ok_acc else "#ff4444", "[x]" if s_ok_acc else "[ ]"]
		s_txt += "[color=%s]%s Dominio Click[/color][/center]" % ["#00ff00" if s_ok_dom else "#ff4444", "[x]" if s_ok_dom else "[ ]"]
		evo_choice_panel.find_child("OptSymbiosis", true, false).find_child("Icon").text = "🌱"
		evo_choice_panel.find_child("OptSymbiosis", true, false).find_child("Desc").text = s_txt
		btn_symbiosis.text = "Fusionar"
		btn_symbiosis.disabled = not EvoManager.is_simbiosis_ready()
		
	# MODO TIER 2: Evolución desde Homeostasis (v0.8.9)
	elif EvoManager.mutation_homeostasis:
		evo_choice_panel.get_node("Margin/VBox/TopBar/Header").text = "TRANSICIÓN ALOSTÁTICA (TIER 2)"
		opt_homeostasis.visible = true
		opt_colonization.visible = false
		opt_symbiosis.visible = false
		
		var works = EvoManager.is_allostasis_ready(self)
		var h_txt = "[center]ALLOSTASIS\nRegulación Dinámica del Sistema.\n\n"
		h_txt += "[color=#00ff00]+ Ingresos Globales x3.0[/color]\n"
		h_txt += "[color=#00ff00]+ Estabilidad Adaptativa (Ω buffer)[/color]\n"
		h_txt += "[color=#ff4444]- Exige Metabolismo > 200/s[/color]\n"
		h_txt += "[color=#ff4444]- Fragilidad por Complejidad[/color][/center]"
		
		opt_homeostasis.find_child("Desc").text = h_txt
		btn_homeostasis.text = "¡EVOLUCIONAR!" if works else "[REQUISITOS NO MET]"
		btn_homeostasis.disabled = not works
		btn_homeostasis.modulate = Color(0, 1, 1) # Cyan
		
	else:
		# MODO TIER 2: Sub-ramas de Red Micelial
		evo_choice_panel.get_node("Margin/VBox/TopBar/Header").text = "BIFURCACIÓN DEL GENOMA"
		opt_homeostasis.visible = false
		opt_colonization.visible = true
		opt_symbiosis.visible = true
		
		# Rama Azul (Simbiosis Mecánica) requiere contabilidad 2
		var has_mechanics = UpgradeManager.level("accounting") >= 2
		if not has_mechanics:
			btn_symbiosis.disabled = true
			btn_symbiosis.text = "[BLOQUEADO: Req. Contabilidad nvl 2]"
		else:
			btn_symbiosis.disabled = false
			btn_symbiosis.text = "Integrar Hardware"

func update_fungal_cycle_bar() -> void:
	var bar = UIManager.fungal_cycle_bar
	var btn_p = get_node_or_null("%PrimordioButton")
	var btn_f = get_node_or_null("%SporulationFinalButton")
	
	if EvoManager.red_branch_selected != EvoManager.RedBranch.NONE:
		# --- Barra de Micelio (Solo en Colonización) ---
		if is_instance_valid(bar):
			bar.visible = (EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION)
			if bar.visible:
				bar.value = BiosphereEngine.micelio
				if EvoManager.seta_formada:
					bar.tooltip_text = "🍄 CICLO COMPLETADO: SETA MADURA"
					bar.value = 100.0
				elif EvoManager.primordio_active:
					var t_left := EvoManager.PRIMORDIO_DURATION - EvoManager.primordio_timer
					bar.tooltip_text = "🟡 PRIMORDIO ACTIVO — %.0fs restantes" % t_left
				else:
					bar.tooltip_text = "Micelio: %d%%  — Ciclo Biológico Activo" % int(BiosphereEngine.micelio)
		
		# --- Botón Primordio (Solo en Colonización) ---
		if is_instance_valid(btn_p):
			if EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION:
				var puede_iniciar := BiosphereEngine.micelio >= 60.0 and not EvoManager.primordio_active and not EvoManager.seta_formada
				btn_p.visible = not EvoManager.seta_formada
				btn_p.disabled = not puede_iniciar
				if EvoManager.primordio_active:
					var t_left := EvoManager.PRIMORDIO_DURATION - EvoManager.primordio_timer
					btn_p.text = "🟡 Primordio activo — %.0fs" % t_left
					btn_p.disabled = true
				elif puede_iniciar:
					var costo := 20.0 * (1.0 + EvoManager.primordio_abort_count * 0.2)
					btn_p.text = "🟡 Iniciar Primordio (%.0f%% micelio)" % costo
				else:
					btn_p.text = "🟡 Iniciar Primordio (micelio < 60%%)"
			else:
				btn_p.visible = false
		
		# --- Botón Final (Seta o Núcleo o Panspermia) ---
		if is_instance_valid(btn_f): 
			var show_panspermia = LegacyManager.last_run_ending == "ESPORULACIÓN" and EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION and EvoManager.primordio_active
			btn_f.visible = EvoManager.seta_formada or EvoManager.nucleo_conciencia or show_panspermia
			btn_f.disabled = false
			
			if EvoManager.nucleo_conciencia:
				btn_f.text = "⚡ CONECTAR SINGULARIDAD (Final)"
				btn_f.modulate = Color(0.1, 1.0, 1.0) # Cian neón
			elif EvoManager.seta_formada:
				btn_f.text = "🔵 DISPERSAR ESPORAS (Final)"
				btn_f.modulate = Color(0.4, 1.0, 0.2) # Verde neón
			elif show_panspermia:
				if EconomyManager.money >= 100000.0:
					btn_f.text = "🚀 PANSPERMIA NEGRA ($100k) (Final)"
					btn_f.modulate = Color(0.8, 0.2, 1.0) # Magenta brillante
				else:
					btn_f.text = "🚀 REQUIERE $100k PARA PANSPERMIA"
					btn_f.disabled = true
					btn_f.modulate = Color(0.4, 0.1, 0.5)
			
	else:
		if is_instance_valid(bar): bar.visible = false
		if is_instance_valid(btn_p): btn_p.visible = false
		if is_instance_valid(btn_f): btn_f.visible = false

func _on_btn_evolve_pressed():
	evo_choice_panel.visible = true
	$DimmerBackground.visible = true
	update_bifurcation_panel()

func _on_close_evo_button_pressed():
	evo_choice_panel.visible = false
	$DimmerBackground.visible = false


func _on_btn_homeostasis_pressed():
	if EvoManager.mutation_homeostasis:
		if EvoManager.is_allostasis_ready(self):
			_trigger_allostasis()
			evo_choice_panel.visible = false
			$DimmerBackground.visible = false
			return

	EvoManager.activate_mutation("homeostasis")
	evo_choice_panel.visible = false
	$DimmerBackground.visible = false
	update_ui()

func _on_btn_colonization_pressed() -> void:
	if not (EvoManager.mutation_red_micelial or EvoManager.mutation_homeostasis or EvoManager.mutation_symbiosis):
		# CASO TIER 1: Activación de Red Micelial
		EvoManager.activate_mutation("red_micelial")
	else:
		# CASO TIER 2: Selección de sub-rama
		_on_branch_selected(EvoManager.RedBranch.COLONIZATION)
		evo_choice_panel.visible = false
		$DimmerBackground.visible = false
	update_ui()

func _trigger_allostasis() -> void:
	print("🟣 EVOLUCIÓN: ALLOSTASIS (TIER 2)")
	EvoManager.activate_mutation("allostasis")
	RunManager.homeostasis_mode = false # Salimos de homeostasis pura
	
	# Bonus de entrada
	EconomyManager.money += 50000.0
	StructuralModel.epsilon_runtime *= 0.5 # Reset de estrés para que pueda respirar
	
	add_lap("🛸 ERA ALOSTÁTICA ALCANZADA (Metabolismo > 200/s)")
	update_ui()

func _on_btn_symbiosis_pressed() -> void:
	if not (EvoManager.mutation_red_micelial or EvoManager.mutation_homeostasis or EvoManager.mutation_symbiosis):
		# CASO TIER 1: Activación de Simbiosis
		EvoManager.activate_mutation("simbiosis")
	else:
		# CASO TIER 2: Selección de sub-rama
		_on_branch_selected(EvoManager.RedBranch.SYMBIOSIS)
		evo_choice_panel.visible = false
		$DimmerBackground.visible = false
	update_ui()

func _on_branch_selected(branch: int):
	print("🟢 SELECCIÓN DE RAMA DETECTADA: ", branch)
	EvoManager.red_branch_selected = branch
	if is_instance_valid(dimmer): 
		dimmer.visible = false
		dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_instance_valid(evo_choice_panel): 
		evo_choice_panel.visible = false
		evo_choice_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if branch == EvoManager.RedBranch.COLONIZATION:
		LogManager.add("🟢 RAMA ELEGIDA: COLONIZACIÓN INVASIVA", self)
		mutation_auto_factor *= 1.5 
	elif branch == EvoManager.RedBranch.SYMBIOSIS:
		LogManager.add("🔵 RAMA ELEGIDA: SIMBIOSIS MECÁNICA", self)
		StructuralModel.omega_min = max(StructuralModel.omega_min, 0.50)
		
	_sync_reactor_color()
	update_ui()



# === HANDLERS DE SEÑAL — CICLO BIOLÓGICO (Fase 2) ===

func _on_primordio_iniciado() -> void:
	LogManager.add("🟡 Primordio iniciado — mantené el estrés bajo por 90s", self)
	update_ui()

func _on_primordio_abortado(abort_count: int, reason: String) -> void:
	LogManager.add("💀 Primordio P-%02d ABORTADO: %s (-40%% micelio)" % [abort_count, reason], self)
	update_ui()

func _on_seta_formada() -> void:
	LogManager.add("🍄 ¡SETA FORMADA! — El cuerpo fructífero emerge. Esporulación disponible.", self)
	update_ui()

func _on_primordio_button_pressed() -> void:
	if not EvoManager.try_iniciar_primordio():
		LogManager.add("⚠️ Primordio no disponible — necesitás 60%% de micelio y Colonización activa", self)

func _on_sporulation_final_pressed() -> void:
	if RunManager.run_closed: return
	
	if EvoManager.nucleo_conciencia:
		# FINAL: SINGULARIDAD MECÁNICA
		var bonus_efficiency: float = clamp(1.0 - StructuralModel.epsilon_runtime, 0.0, 1.0) * 5.0
		var pl := 6 + int(bonus_efficiency)
		
		LegacyManager.add_pl(pl)
		show_system_toast("LEGADO: Singularidad integrada (+%d PL)" % pl)
		close_run("SINGULARIDAD", "El hongo ha asimilado totalmente el mainframe. Conciencia total alcanzada.")
		
	elif EvoManager.seta_formada:
		# FINAL: ESPORULACIÓN BIOLÓGICA
		var esporas := BiosphereEngine.trigger_sporulation()
		if esporas > 1.0: # Umbral mínimo bajado para asegurar PL
			LegacyManager.add_spores(esporas)
		
		close_run("ESPORULACIÓN", "El ciclo biológico se ha completado. Millones de esporas han infectado el sistema. Legado fúngico asegurado.")
		
	elif LegacyManager.last_run_ending == "ESPORULACIÓN" and EvoManager.primordio_active and EconomyManager.money >= 100000.0:
		# FINAL SECRETO: PANSPERMIA NEGRA
		EconomyManager.money -= 100000.0
		if not LegacyManager.get_buff_value("semilla_cosmica"):
			LegacyManager.unlocked_legacies["semilla_cosmica"] = true
			LegacyManager.save_legacy()
			show_system_toast("✨ Has desbloqueado el legado: SEMILLA CÓSMICA")
			
		LegacyManager.add_pl(10)
		close_run("PANSPERMIA NEGRA", "Las esporas han sido disparadas al espacio exterior. La infección se vuelve interplanetaria. (+10 PL)")
		
# --- LÓGICA DEL BANCO GENÉTICO (Legacy) ---
func activate_mente_colmena():
	mente_colmena_active = true
	if is_instance_valid(UIManager.big_click_button):
		UIManager.big_click_button.disabled = true
		UIManager.big_click_button.text = "🧠 AUTO-OVERRIDE"
		UIManager.big_click_button.modulate = Color(0.1, 0.8, 1.0)
	
	if not LegacyManager.get_buff_value("mente_colmena"):
		LegacyManager.unlocked_legacies["mente_colmena"] = true
		LegacyManager.save_legacy()
		show_system_toast("✨ Has desbloqueado el legado: MENTE COLMENA DISTRIBUIDA")
		
	close_run("MENTE COLMENA DISTRIBUIDA", "Tus patrones psicomotores han sido asimilados. El administrador es obsoleto. (+8 PL)")

func _on_legacy_pressed():
	legacy_panel.visible = true
	$DimmerBackground.visible = true
	_refresh_legacy_store()

func _on_close_legacy_pressed():
	legacy_panel.visible = false
	$DimmerBackground.visible = false

func _refresh_legacy_store():
	var pl := LegacyManager.legacy_points
	var buffer := LegacyManager.internal_spores_total
	pl_label.text = "PL Disponibles: %d\nReserva biótica: %.1f / 50 esporas" % [pl, buffer]
	
	for child in legacy_list.get_children():
		child.queue_free()
		
	# Iterar sobre las mejoras disponibles
	var data = LegacyManager.LEGACY_DATA
	for id in data.keys():
		var info = data[id]
		var is_unlocked = LegacyManager.unlocked_legacies[id]
		
		var h_box = HBoxContainer.new()
		h_box.custom_minimum_size = Vector2(0, 50)
		
		var v_info = VBoxContainer.new()
		v_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var l_title = Label.new()
		l_title.text = info.name + (" [DESBLOQUEADO]" if is_unlocked else " (" + str(info.cost) + " PL)")
		l_title.add_theme_font_size_override("font_size", 13)
		if is_unlocked: l_title.modulate = Color.GREEN
		
		var l_desc = Label.new()
		l_desc.text = info.desc
		l_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l_desc.add_theme_font_size_override("font_size", 10)
		l_desc.modulate = Color(0.7, 0.7, 0.7)
		
		v_info.add_child(l_title)
		v_info.add_child(l_desc)
		
		var btn = Button.new()
		btn.text = "COMPRAR"
		btn.custom_minimum_size = Vector2(100, 30)
		btn.disabled = is_unlocked or LegacyManager.legacy_points < info.cost
		btn.pressed.connect(func():
			if LegacyManager.purchase_legacy(id):
				_refresh_legacy_store()
				show_system_toast("Banco: Compraste " + info.name)
		)
		
		h_box.add_child(v_info)
		h_box.add_child(btn)
		
		var sep = HSeparator.new()
		legacy_list.add_child(h_box)
		legacy_list.add_child(sep)



# ESTRUCTURALES v0.7.3
func update_epsilon_runtime():
	if StructuralModel.baseline_delta_structural <= 0.0 or delta_per_sec <= 0.0:
		StructuralModel.epsilon_runtime = 0.0
		StructuralModel.epsilon_active = 0.0
		StructuralModel.epsilon_passive = 0.0
		StructuralModel.epsilon_complex = 0.0
		return

	var n_struct := get_effective_structural_n()
	var k_eff := get_k_eff()

	# =================================================
	# 1) ε_activo — producción / composición (actual)
	# =================================================
	var expected_delta := StructuralModel.baseline_delta_structural * pow(
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

	# DECAY DE ESTRÉS ACTIVO (v0.8.8)
	# Si no clickeas por más de 3s, el ruido del potencial de click se disipa.
	var decay_factor = clamp(1.0 - (time_since_last_click / 5.0), 0.0, 1.0)
	StructuralModel.epsilon_active = (epsilon_prod + epsilon_comp) * decay_factor

	# =================================================
	# 2) ε_pasivo — rigidez / cristalización
	# =================================================
	StructuralModel.epsilon_passive = 0.0

	if passive_ratio > PASSIVE_RATIO_START:
		var excess := passive_ratio - PASSIVE_RATIO_START
		var rigidity := (1.0 - omega)
		var size_factor := log(1.0 + n_struct) * 0.45
		StructuralModel.epsilon_passive = excess * size_factor * rigidity * EPS_PASSIVE_SCALE * (1.0 - get_accounting_effect()) # Use function

	# =================================================
	# 3) Complejidad estructural
	# =================================================
	StructuralModel.epsilon_complex = 0.0012 * n_struct * k_eff

	# 4) Mezcla final y AMORTIGUACIÓN BIOLÓGICA (v0.8.6)
	var epsilon_raw := StructuralModel.epsilon_active + StructuralModel.epsilon_passive + StructuralModel.epsilon_complex
	
	# El hongo intenta absorber parte del estrés bruto antes de que se convierta en runtime
	var bio_absorption := 1.0
	if StructuralModel.epsilon_effective < StructuralModel.epsilon_runtime and StructuralModel.epsilon_runtime > 0.1:
		# Si el hongo es eficiente, ayuda a enfriar el sistema
		bio_absorption = clamp(StructuralModel.epsilon_effective / StructuralModel.epsilon_runtime, 0.4, 1.0)

	StructuralModel.epsilon_runtime = lerp(StructuralModel.epsilon_runtime, epsilon_raw * bio_absorption, 0.045)
	StructuralModel.epsilon_runtime = clamp(StructuralModel.epsilon_runtime, 0.0, 2.0)
	
	# RAMA COLONIZACIÓN: Piso de estrés 0.25 (v0.8.40)
	if EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION:
		StructuralModel.epsilon_runtime = max(StructuralModel.epsilon_runtime, 0.25)
		
	StructuralModel.epsilon_peak = max(StructuralModel.epsilon_peak, StructuralModel.epsilon_runtime)

	# =================================================
	# 5) Ω (flexibilidad)
	# =================================================
	omega = EcoModel.get_omega(StructuralModel.epsilon_runtime, k_eff, n_struct)
	if not EvoManager.mutation_homeostasis:
		# Si StructuralModel.omegaes mejor que el mínimo, el mínimo se recupera lentamente (v0.8.9)
		if StructuralModel.omega> StructuralModel.omega_min:
			StructuralModel.omega_min = move_toward(StructuralModel.omega_min, omega, 0.002) # Recuperación por alivio de estrés
	else:
		StructuralModel.omega_min = max(StructuralModel.omega_min, 0.35)
	# CRÍTICO: StructuralModel.omega_min no solo registra el mínimo, PROTEGE el piso real de Ω
	omega = max(omega, StructuralModel.omega_min)
	
	# ALOSTASIS: Piso de estabilidad adaptativo (Ω >= 0.60)
	if EvoManager.mutation_allostasis:
		omega = max(omega, 0.60)
	elif LegacyManager.get_buff_value("legado_alostasis"):
		omega = max(omega, 0.45) # Beneficio persistente del legado

	# RAMA SIMBIOSIS: Piso de StructuralModel.omega0.50 (v0.8.5)
	if EvoManager.red_branch_selected == EvoManager.RedBranch.SYMBIOSIS:
		omega = max(omega, 0.50)
		
	# HIPERASIMILACIÓN: Colapso Estructural y Fragilidad
	if EvoManager.mutation_hyperassimilation:
		omega = min(omega, 0.75) # Cap de fragilidad
		# Decaimiento de persistencia (Inercia negativa)
		StructuralModel.persistence_dynamic = lerp(StructuralModel.persistence_dynamic, 1.0, 0.001)

	# accounting_effect = 1.0 - exp(-0.3 * accounting_level) # Redundant, now a function
	# accounting_effect = clamp(accounting_effect, 0.0, 0.5) # Redundant, now a function
	# ====================================================
	#  6) DEBUG EPSILON OUTPUT v0.8.2
	# =====================================================
	if StructuralModel.epsilon_debug:
		print("ε breakdown:",
		"act=", StructuralModel.epsilon_active,
		"pas=", StructuralModel.epsilon_passive,
		"cmp=", StructuralModel.epsilon_complex,
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
		StructuralModel.epsilon_debug = !StructuralModel.epsilon_debug
		print("ε DEBUG =", StructuralModel.epsilon_debug)


func check_institution_unlock():
	if StructuralModel.institution_accounting_unlocked:
		return

	var p := get_structural_pressure()
	# vía 1 (ya existe): crisis
	var inactivity_trigger = time_since_last_click > 120.0 and BiosphereEngine.biomasa > 5.0 and StructuralModel.epsilon_runtime > 0.35
	if p > 15.0 and StructuralModel.omega< 0.25 and StructuralModel.epsilon_runtime > 0.3 or inactivity_trigger:
		unlock_accounting()

	# vía 2 (NUEVA): estabilidad sostenida
	elif run_time > 600.0 and StructuralModel.epsilon_runtime < 0.15 and get_active_passive_breakdown().pasivo > 35.0:
		unlock_accounting()

func unlock_accounting():
	StructuralModel.institution_accounting_unlocked = true
	institutions_unlocked = true
	if UpgradeManager.level("accounting") == 0:
		StructuralModel.omega_min = max(StructuralModel.omega_min, 0.30)
	add_lap("🏛️ Institución desbloqueada — Contabilidad Básica")
	if UIManager.system_message_label:
		UIManager.system_message_label.text = "El sistema se institucionaliza: nace la Contabilidad Básica"
	on_institutions_unlocked()	

# Handled via UpgradeManager now

#
# =====================================================
# 	Acumulación del histórico de dinero generado v0.7.2
func update_economy(delta: float):
	EconomyManager.update_economy(delta)


func format_time(t: float) -> String:
	return UIManager.format_time(t)

func update_epsilon_sticky():
	if not UIManager.epsilon_sticky_label: return
	
	var t := ""
	t += "%s ε runtime = %s\n" % [UIManager.epsilon_flag(StructuralModel.epsilon_runtime, 0.30), snapped(StructuralModel.epsilon_runtime, 0.01)]
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
var StructuralModel.persistence_upgrade_unlocked := false
var memory_trigger_count := 0

func _on_BigClickButton_pressed():
	on_reactor_click(0.008)

# =====================================================
#  DESBLOQUEO INSTITUCIONES v0.7.2
# =====================================================


func on_institutions_unlocked():
	print("Nueva capa estructural detectada: Instituciones")
	show_institutions_panel = true
	StructuralModel.epsilon_runtime *= 0.85 # baja 15% el estrés
	StructuralModel.epsilon_peak = max(StructuralModel.epsilon_peak * 0.9, StructuralModel.epsilon_runtime)

	add_lap("🏛️ Contabilidad — Nivel %d (ε amortiguado)" % UpgradeManager.level("accounting"))
# Handled via purchase_upgrade

# =====================================================
# UI HELPERS — v0.8
func update_core_labels():
	UIManager.update_money(EconomyManager.money)
	if UIManager.formula_label:
		UIManager.formula_label.text = build_formula_text()
	
	update_click_stats_panel()

func build_institution_panel_text() -> String:
	var t := "--- Contabilidad Básica ---\n"

	t += "\n--- ε desglosado (Homeostasis) ---\n"
	t += "%s ε activo = %s\n" % [epsilon_flag(StructuralModel.epsilon_active, 0.15), snapped(StructuralModel.epsilon_active, 0.01)]
	t += "%s ε pasivo = %s\n" % [epsilon_flag(StructuralModel.epsilon_passive, 0.12), snapped(StructuralModel.epsilon_passive, 0.01)]
	t += "%s ε complejidad = %s\n" % [epsilon_flag(StructuralModel.epsilon_complex, 0.08), snapped(StructuralModel.epsilon_complex, 0.01)]
	
	t += "Ω_min = %s\n" % snapped(StructuralModel.omega_min, 0.01)
	t += "Contabilidad = nivel %d\n" % UpgradeManager.level("accounting")
	t += "Amortiguación = %d%%\n" % int(get_accounting_effect() * 100.0)

	t += "\nε_peak = %s\n" % snapped(StructuralModel.epsilon_peak, 0.01)
	

	t += build_genome_text()
	t += build_mutation_status_text()

	if RunManager.homeostasis_mode:
		t += "\n\n⚖️ HOMEOSTASIS MODE"
		t += "\nResiliencia = %s" % snapped(RunManager.resilience_score, 1)
		t += "\nPerturbaciones cada %ds" % RunManager.DISTURBANCE_INTERVAL

	if EvoManager.mutation_red_micelial and EvoManager.red_micelial_phase == 2:
		t += "\n⚠️ La red no puede estabilizarse localmente"

	t += UIManager.build_evo_checklist(self)

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

func _sync_reactor_color() -> void:
	# Especial: Bloqueo de Escalado Alostático si no viene de Homeostasis
	if UpgradeManager.states.has("trueque_allo"):
		var ready_to_show = UpgradeManager.level("trueque_net") > 0
		var came_from_success = LegacyManager.last_run_ending == "HOMEOSTASIS" or LegacyManager.last_run_ending == "ALLOSTASIS"

		if ready_to_show and came_from_success:
			UpgradeManager.states["trueque_allo"].unlocked = true
		else:
			UpgradeManager.states["trueque_allo"].unlocked = false
	if not is_instance_valid(reactor_visual):
		reactor_visual = $UIRootContainer/LeftPanel/CenterPanel/BigClickButton/ReactorVisual
		return
	reactor_visual.set_tint(EvoManager.get_reactor_color())
func update_buttons():
	for btn in get_tree().get_nodes_in_group("upgrade_buttons"):
		if btn.has_method("update_appearance"):
			btn.update_appearance(EconomyManager.money)

func is_major_lap(event: String) -> bool:
	return LogManager.is_major(event)

func update_lap_log():
	LogManager.update_log_label(self)

func update_lap_toggle_button():
	LogManager.update_toggle_button(self)

func toggle_lap_view():
	LogManager.toggle_view(self)
	update_lap_toggle_button()
# =====================================================


# =====================================================
#  UI — SOLO LEE RESULTADOS (v0.6.3 — HUD científico)
# =====================================================


func update_ui():
	update_epsilon_sticky()
	update_bifurcation_panel()
	update_fungal_cycle_bar() # Barra de Micelio (Ciclo Biológico)

	check_dominance_transition()
	check_achievements()
	update_achievements_label()
	update_core_labels()
	update_buttons()

	if institutions_unlocked or UpgradeManager.level("accounting") >= 1:
		if UIManager.institution_panel_label:
			UIManager.institution_panel_label.visible = true
			UIManager.institution_panel_label.text = build_institution_panel_text()

	if StructuralModel.institution_accounting_unlocked:
		pass # Los botones genéricos se encargan de visibilidad
	else:
		pass

	update_lab_metrics()
	update_lap_log()

	if is_instance_valid(btn_evolve):
		if EvoManager.mutation_parasitism:
			btn_evolve.visible = true
			btn_evolve.disabled = true
			btn_evolve.text = "🔒 MUTACIÓN BLOQUEADA"
			btn_evolve.modulate = Color(1.0, 0.4, 0.2) # Naranja parásito
		else:
			var any_tier1 = EvoManager.is_any_latent_tier1()
			var any_tier2 = EvoManager.mutation_homeostasis and EvoManager.is_allostasis_ready(self)
			
			btn_evolve.visible = any_tier1 or any_tier2
			btn_evolve.disabled = false
			btn_evolve.text = "🧬 INICIAR MUTACIÓN"
			if any_tier2:
				btn_evolve.modulate = Color(0, 1, 1) # Cyan para Allostasis
			else:
				btn_evolve.modulate = Color(1, 1, 1)

	# Habilitar Export Run al cerrar la run
	if RunManager.run_closed and UIManager.export_run_button:
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
	if EvoManager.mutation_hyperassimilation:
		t += "[b][color=magenta]⚠️ HIPERASIMILACIÓN (Active Rush):[/color][/b]\n"
		t += "[color=#00ff00]+ Sobrecarga Click PUSH x10.0[/color]\n"
		t += "[color=#ff4444]- Producción pasiva atrofiada (-75%)[/color]\n"
		t += "[color=#ff4444]- Colapso persistencia inminente[/color]\n"
	elif EvoManager.genome.hiperasimilacion == "latente":
		t += "\n[color=gray]• Hiperasimilación (LATENTE)[/color]"

	if EvoManager.mutation_homeostasis:
		t += "\n⚖️ Ruta evolutiva: HOMEOSTASIS"
	elif EvoManager.mutation_hyperassimilation:
		t += "\n⚠️ Ruta evolutiva: HIPERASIMILACIÓN"
	elif EvoManager.mutation_symbiosis:
		t += "\n🌱 Ruta evolutiva: SIMBIOSIS"
	elif EvoManager.mutation_parasitism:
		t += "\n🦠 Ruta evolutiva: PARASITISMO"

	# --- Final de run ---
	if RunManager.run_closed:
		t += "\n\n🏁 FINAL ALCANZADO: " + RunManager.final_route

	return t
func build_mutation_status_text() -> String:
	var t := "\n[color=#aaaaaa]--- Efectos mutacionales activos ---[/color]\n"
	var buff := "[color=#00ff00]+"
	var nerf := "[color=#ff4444]-"
	var _end_c := "[/color]"

	# HIPERASIMILACIÓN
	if EvoManager.mutation_hyperassimilation:
		t += "[b][color=magenta]⚠️ HIPERASIMILACIÓN (RUSH):[/color][/b]\n"
		t += buff + " Sobrecarga Click PUSH x10.0[/color]\n"
		t += nerf + " Pasivo -75% / Fragilidad Ω[/color]\n"

	elif EvoManager.genome.hiperasimilacion == "latente":
		t += "[color=gray]• Hiperasimilación (LATENTE)[/color]\n"

	# HOMEOSTASIS
	if EvoManager.mutation_homeostasis:
		t += "[b][color=cyan]⚖️ HOMEOSTASIS:[/color][/b]\n"
		t += buff + " Producción total +50% (Orden Administrativo)[/color]\n"
		t += buff + " Estabilidad ε (runtime reducido)[/color]\n"
		t += buff + " Ω_min 0.35 (Seguridad estructural)[/color]\n"
		t += nerf + " Limitación Biomasa (crecimiento controlado)[/color]\n"

	# SIMBIOSIS
	if EvoManager.mutation_symbiosis:
		t += "[b][color=green]🌱 SIMBIOSIS ESTRUCTURAL:[/color][/b]\n"
		t += buff + " Potencia Click PUSH ×2.5 (Domino Activo)[/color]\n"
		t += nerf + " Producción Pasiva -50% (Atrofia Autómata)[/color]\n"

	# RED MICELIAL
	if EvoManager.mutation_red_micelial:
		t += "[b][color=#9955ff]🕸️ RED MICELIAL:[/color][/b]\n"
		t += buff + " Producción Pasiva TOTAL ×2.5 (Heptasíntesis)[/color]\n"
		t += nerf + " Potencia Click PUSH -50% (Desconexión Motora)[/color]\n"
	
	# PARASITISMO
	if EvoManager.mutation_parasitism:
		t += "[b][color=#ff4400]🦠 PARASITISMO:[/color][/b]\n"
		t += buff + " Generación Biomasa +100% (Descontrol)[/color]\n"
		t += buff + " Ingreso Pasivo +20%[/color]\n"
		t += nerf + " Desprestigio institucional (Contabilidad -10%)[/color]\n"
		t += nerf + " Ω colapsando (Máx 0.25)[/color]\n"

	return t

# =====================================================
#  PERSISTENCIA DE DATOS (Save/Load)
# =====================================================

func get_save_data() -> Dictionary:
	return {
		"economy": {
			"money": EconomyManager.money,
			"StructuralModel.persistence_dynamic": StructuralModel.persistence_dynamic,
			"StructuralModel.persistence_base": StructuralModel.persistence_base,
			"StructuralModel.persistence_upgrade_unlocked": StructuralModel.persistence_upgrade_unlocked,
			"memory_trigger_count": memory_trigger_count,
			"parasitism_corrosion": EconomyManager.parasitism_corrosion
		},
		"dynamic_vars": {
			"trueque_base_income": EconomyManager.trueque_base_income,
			"trueque_efficiency": EconomyManager.trueque_efficiency,
			"mutation_auto_factor": EconomyManager.mutation_auto_factor,
			"mutation_trueque_factor": EconomyManager.mutation_trueque_factor,
			"mutation_accounting_bonus": EconomyManager.mutation_accounting_bonus
		},
		"upgrades": UpgradeManager.serialize(),
		"structural": {
			"StructuralModel.epsilon_runtime": StructuralModel.epsilon_runtime,
			"StructuralModel.epsilon_peak": StructuralModel.epsilon_peak,
			"total_money_generated": EconomyManager.total_money_generated,
			"run_time": run_time,
			"StructuralModel.baseline_delta_structural": StructuralModel.baseline_delta_structural,
			"omega": omega,
			"StructuralModel.omega_min": StructuralModel.omega_min,
			"StructuralModel.institution_accounting_unlocked": StructuralModel.institution_accounting_unlocked,
			"institutions_unlocked": institutions_unlocked
		},
		"flags": {
			"StructuralModel.unlocked_d": StructuralModel.unlocked_d,
			"StructuralModel.unlocked_md": StructuralModel.unlocked_md,
			"StructuralModel.unlocked_e": StructuralModel.unlocked_e,
			"StructuralModel.unlocked_me": StructuralModel.unlocked_me,
			"unlocked_tree": unlocked_tree,
			"unlocked_click_dominance": unlocked_click_dominance,
			"StructuralModel.unlocked_delta_100": StructuralModel.unlocked_delta_100,
			"achievement_millionaire": AchievementManager.achievement_millionaire,
			"achievement_fragile_balance": AchievementManager.achievement_fragile_balance,
			"achievement_insatiable_parasite": AchievementManager.achievement_insatiable_parasite,
			"run_closed": RunManager.run_closed,
			"final_route": RunManager.final_route,
			"final_reason": RunManager.final_reason
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
			"red_branch_selected": EvoManager.red_branch_selected,
			"seta_formada": EvoManager.seta_formada,
			"primordio_active": EvoManager.primordio_active,
			"primordio_timer": EvoManager.primordio_timer,
			"primordio_abort_count": EvoManager.primordio_abort_count,
			"biomasa": BiosphereEngine.biomasa,
			"nutrientes": BiosphereEngine.nutrientes,
			"hifas": BiosphereEngine.hifas,
			"micelio": BiosphereEngine.micelio
		},
		"homeostasis": {
			"homeostasis_mode": RunManager.homeostasis_mode,
			"post_homeostasis": RunManager.post_homeostasis,
			"resilience_score": RunManager.resilience_score,
			"homeostasis_timer": RunManager.homeostasis_timer,
			"legacy_homeostasis": RunManager.legacy_homeostasis
		},
		"laps": LogManager.get_lap_array()
	}

func _apply_save_data(data: Dictionary):
	if data.has("upgrades"):
		UpgradeManager.deserialize(data.upgrades)

	if data.has("economy"):
		var e = data.economy
		EconomyManager.money = e.get("money", EconomyManager.money)
		StructuralModel.persistence_dynamic = e.get("StructuralModel.persistence_dynamic", StructuralModel.persistence_dynamic)
		StructuralModel.persistence_base = e.get("StructuralModel.persistence_base", StructuralModel.persistence_base)
		StructuralModel.persistence_upgrade_unlocked = e.get("StructuralModel.persistence_upgrade_unlocked", StructuralModel.persistence_upgrade_unlocked)
		memory_trigger_count = e.get("memory_trigger_count", memory_trigger_count)
		EconomyManager.parasitism_corrosion = e.get("parasitism_corrosion", EconomyManager.parasitism_corrosion)

	if data.has("dynamic_vars"):
		var d = data.dynamic_vars
		EconomyManager.trueque_base_income = d.get("trueque_base_income", EconomyManager.trueque_base_income)
		EconomyManager.trueque_efficiency = d.get("trueque_efficiency", EconomyManager.trueque_efficiency)
		EconomyManager.mutation_auto_factor = d.get("mutation_auto_factor", EconomyManager.mutation_auto_factor)
		EconomyManager.mutation_trueque_factor = d.get("mutation_trueque_factor", EconomyManager.mutation_trueque_factor)
		EconomyManager.mutation_accounting_bonus = d.get("mutation_accounting_bonus", EconomyManager.mutation_accounting_bonus)

	if data.has("structural"):
		var s = data.structural
		StructuralModel.epsilon_runtime = s.get("StructuralModel.epsilon_runtime", StructuralModel.epsilon_runtime)
		StructuralModel.epsilon_peak = s.get("StructuralModel.epsilon_peak", StructuralModel.epsilon_peak)
		EconomyManager.total_money_generated = s.get("total_money_generated", EconomyManager.total_money_generated)
		run_time = s.get("run_time", run_time)
		StructuralModel.baseline_delta_structural = s.get("StructuralModel.baseline_delta_structural", StructuralModel.baseline_delta_structural)
		omega = s.get("omega", omega)
		StructuralModel.omega_min = s.get("StructuralModel.omega_min", StructuralModel.omega_min)
		StructuralModel.institution_accounting_unlocked = s.get("StructuralModel.institution_accounting_unlocked", StructuralModel.institution_accounting_unlocked)
		institutions_unlocked = s.get("institutions_unlocked", institutions_unlocked)

	if data.has("flags"):
		var f = data.flags
		StructuralModel.unlocked_d = f.get("StructuralModel.unlocked_d", StructuralModel.unlocked_d)
		StructuralModel.unlocked_md = f.get("StructuralModel.unlocked_md", StructuralModel.unlocked_md)
		StructuralModel.unlocked_e = f.get("StructuralModel.unlocked_e", StructuralModel.unlocked_e)
		StructuralModel.unlocked_me = f.get("StructuralModel.unlocked_me", StructuralModel.unlocked_me)
		unlocked_tree = f.get("unlocked_tree", unlocked_tree)
		unlocked_click_dominance = f.get("unlocked_click_dominance", unlocked_click_dominance)
		unlocked_delta_100 = f.get("StructuralModel.unlocked_delta_100", StructuralModel.unlocked_delta_100)
		AchievementManager.achievement_millionaire = f.get("achievement_millionaire", AchievementManager.achievement_millionaire)
		AchievementManager.achievement_fragile_balance = f.get("achievement_fragile_balance", AchievementManager.achievement_fragile_balance)
		AchievementManager.achievement_insatiable_parasite = f.get("achievement_insatiable_parasite", AchievementManager.achievement_insatiable_parasite)
		RunManager.run_closed = f.get("run_closed", RunManager.run_closed)
		RunManager.final_route = f.get("final_route", RunManager.final_route)
		RunManager.final_reason = f.get("final_reason", RunManager.final_reason)

	if data.has("evolution"):
		var ev = data.evolution
		EvoManager.genome = ev.get("genome", EvoManager.genome)
		# Agregar esto para migrar saves viejos:
		for key in ["allostasis", "homeorhesis", "depredador"]:
			if not EvoManager.genome.has(key):
				EvoManager.genome[key] = "dormido"
		EvoManager.mutation_homeostasis = ev.get("mutation_homeostasis", EvoManager.mutation_homeostasis)
		EvoManager.mutation_hyperassimilation = ev.get("mutation_hyperassimilation", EvoManager.mutation_hyperassimilation)
		EvoManager.mutation_symbiosis = ev.get("mutation_symbiosis", EvoManager.mutation_symbiosis)
		EvoManager.mutation_red_micelial = ev.get("mutation_red_micelial", EvoManager.mutation_red_micelial)
		EvoManager.mutation_sporulation = ev.get("mutation_sporulation", EvoManager.mutation_sporulation)
		EvoManager.mutation_parasitism = ev.get("mutation_parasitism", EvoManager.mutation_parasitism)
		EvoManager.red_micelial_phase = ev.get("red_micelial_phase", EvoManager.red_micelial_phase)
		EvoManager.red_branch_selected = ev.get("red_branch_selected", EvoManager.red_branch_selected)
		EvoManager.seta_formada = ev.get("seta_formada", EvoManager.seta_formada)
		EvoManager.primordio_active = ev.get("primordio_active", EvoManager.primordio_active)
		EvoManager.primordio_timer = ev.get("primordio_timer", EvoManager.primordio_timer)
		EvoManager.primordio_abort_count = ev.get("primordio_abort_count", EvoManager.primordio_abort_count)
		
		BiosphereEngine.biomasa = ev.get("biomasa", BiosphereEngine.biomasa)
		BiosphereEngine.nutrientes = ev.get("nutrientes", BiosphereEngine.nutrientes)
		BiosphereEngine.hifas = ev.get("hifas", BiosphereEngine.hifas)
		BiosphereEngine.micelio = ev.get("micelio", BiosphereEngine.micelio)

	if data.has("homeostasis"):
		var h = data.homeostasis
		RunManager.homeostasis_mode = h.get("homeostasis_mode", RunManager.homeostasis_mode)
		RunManager.post_homeostasis = h.get("post_homeostasis", RunManager.post_homeostasis)
		RunManager.resilience_score = h.get("resilience_score", RunManager.resilience_score)
		RunManager.homeostasis_timer = h.get("homeostasis_timer", RunManager.homeostasis_timer)
		RunManager.legacy_homeostasis = h.get("legacy_homeostasis", RunManager.legacy_homeostasis)

	# Cargar achievements
	if data.has("achievements"):
		AchievementManager.load_achievements(data["achievements"])

	# Bitácora de eventos
	if data.has("laps"):
		LogManager.load_laps(data["laps"])

	# Migración
	if not RunManager.run_closed and (EvoManager.mutation_hyperassimilation or EvoManager.mutation_sporulation):
		RunManager.run_closed = true
		RunManager.final_route = RunManager.final_route if RunManager.final_route != "" else "MUTACION_FINAL"

	update_ui()
