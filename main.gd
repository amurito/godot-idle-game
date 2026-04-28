extends Control

# =====================================================
# IDLE — v0.8 DLC "Fungi"
# =====================================================
#dlc
const FUNGI_UI_SCENE = preload("res://fungi.tscn")
var fungi_ui: Control

var reactor_visual: Node = null

# NG+ Mente Colmena
var mente_colmena_active := false
var mente_colmena_timer := 0.0
var _mente_colmena_buy_timer := 0.0
const MENTE_COLMENA_BUY_INTERVAL := 8.0

# Orden de prioridad de compra de la IA Mente Colmena
# (primero desbloqueos estructurales, luego multiplicadores, click al final)
const MENTE_COLMENA_BUY_PRIORITY: Array = [
	"accounting",     # instituciones + omega boost
	"trueque",        # habilita intercambio
	"auto",           # habilita trabajo manual
	"trueque_net",    # red de intercambio
	"auto_mult",      # ritmo de trabajo
	"cognitive",      # capital cognitivo (μ)
	"persistence",    # memoria operativa
	"specialization", # especialización
	"click_mult",     # memoria numérica
	"click",          # mejorar click (menor prioridad con auto-click activo)
]

# NG+ Depredador
var depredador_tick := 0.0
var _depredador_status_timer := 0.0
const DEPREDADOR_STATUS_INTERVAL := 10.0

# Parasitismo — status periódico
var _parasitism_status_timer := 0.0
const PARASITISM_STATUS_INTERVAL := 45.0

# NG++ Metabolismo Oscuro
var _met_oscuro_income_accum := 0.0  # Acumulador fraccional para ingreso pasivo
var _met_oscuro_status_timer := 0.0
const MET_OSCURO_STATUS_INTERVAL := 12.0
var _met_oscuro_seal_btn: Button = null
var _simbiosis_seal_btn: Button = null

# NG+ Metabolismo Glitch
var _glitch_was_active := false

# CONSTANTES DE MODELO (moved to StructuralModel.gd)
const CLICK_RATE := 1.0

# OBSERVADORES DINÁMICOS (Caché por tick)
var cached_mu: float = 1.0

var delta_per_sec: float = 0.0

var institutions_unlocked: bool = false
var show_institutions_panel: bool = false

# === ε PASIVO (v0.8) ===
const EPS_PASSIVE_SCALE := 0.24
const PASSIVE_RATIO_START := 0.60


# =============== SESIÓN / LAB MODE ===================

var run_time: float = 0.0
var lab_mode := false  # Oculto por defecto — tecla L para toggle

# RunManager.final_reason movido a RunManager.gd
var show_final_details := false  # ya lo tenías; lo usamos para controlar detalles

var RUN_EXPORT_PATH := OS.get_user_data_dir() + "/IDLE_Fungi/runs"

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

# ================= REFERENCIAS UI ===================
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

# =====================================================
# MET.OSCURO — ciclo post-Depredador (bioquímica oscura)
# =====================================================
func met_oscuro_tick(dt: float):
	# 1) Ingreso pasivo = biomasa × 0.8 /s
	var income_rate := BiosphereEngine.biomasa * 0.8
	_met_oscuro_income_accum += income_rate * dt
	if _met_oscuro_income_accum >= 1.0:
		var gain :float = floor(_met_oscuro_income_accum)
		EconomyManager.money += gain
		_met_oscuro_income_accum -= gain
	# 2) Biomasa se autoalimenta suavemente
	BiosphereEngine.biomasa += 0.1 * dt
	# 3) ε_runtime decae (autorregulación emergente)
	StructuralModel.epsilon_runtime = max(0.0, StructuralModel.epsilon_runtime - 0.05 * dt)
	# 4) Ω forzado bajo (fragilidad permanente)
	StructuralModel.omega = 0.10
	# 5) Status periódico
	_met_oscuro_status_timer += dt
	if _met_oscuro_status_timer >= MET_OSCURO_STATUS_INTERVAL:
		_met_oscuro_status_timer = 0.0
		add_lap("🌑 MET.OSCURO — Bio %.1f · Pasivo %.1f/s · $ %.0f" % [BiosphereEngine.biomasa, income_rate, EconomyManager.money])
	# 6) Cierre automático por saturación de biomasa
	if BiosphereEngine.biomasa >= 100.0 and not RunManager.run_closed:
		LegacyManager.add_pl(2)  # +2 bonus (+4 base = 6 total)
		close_run("METABOLISMO OSCURO", "Saturación Oscura: la biomasa rebasó el umbral crítico (+2 PL bonus)")
		return
	# 7) Cierre automático por economía millonaria oscura
	if EconomyManager.money >= 1000000.0 and not RunManager.run_closed:
		close_run("METABOLISMO OSCURO", "Millonario Oscuro: la bioquímica sostenida generó $1M sin infraestructura")
		return
	# 8) Mostrar botón voluntario de sellado
	_update_met_oscuro_seal_button()

func _update_met_oscuro_seal_button():
	if RunManager.run_closed:
		return
	if _met_oscuro_seal_btn == null or not is_instance_valid(_met_oscuro_seal_btn):
		_met_oscuro_seal_btn = Button.new()
		_met_oscuro_seal_btn.text = "🌑 SELLAR METABOLISMO OSCURO (+4 PL)"
		_met_oscuro_seal_btn.add_theme_font_size_override("font_size", 20)
		_met_oscuro_seal_btn.add_theme_color_override("font_color", Color(0.8, 0.5, 1.0))
		_met_oscuro_seal_btn.custom_minimum_size = Vector2(0, 70)
		_met_oscuro_seal_btn.pressed.connect(_on_met_oscuro_seal_pressed)
		var panel := get_node_or_null("UIRootContainer/RightPanel")
		if panel:
			panel.add_child(_met_oscuro_seal_btn)
			panel.move_child(_met_oscuro_seal_btn, 0)
	_met_oscuro_seal_btn.visible = true

func _on_met_oscuro_seal_pressed():
	if is_instance_valid(_met_oscuro_seal_btn):
		_met_oscuro_seal_btn.visible = false
	close_run("METABOLISMO OSCURO", "Sellado voluntario: la bioquímica oscura queda registrada como ruta alternativa")

func _update_simbiosis_seal_button():
	if RunManager.run_closed or not EvoManager.mutation_symbiosis:
		if is_instance_valid(_simbiosis_seal_btn):
			_simbiosis_seal_btn.visible = false
		return
	# No mostrar si el jugador ya eligió la rama SYMBIOSIS (camino a Singularidad)
	if EvoManager.red_branch_selected == EvoManager.RedBranch.SYMBIOSIS:
		if is_instance_valid(_simbiosis_seal_btn):
			_simbiosis_seal_btn.visible = false
		return
	# Sólo mostrar si lleva más de 60s en SIMBIOSIS
	if run_time < 60.0:
		return
	if _simbiosis_seal_btn == null or not is_instance_valid(_simbiosis_seal_btn):
		_simbiosis_seal_btn = Button.new()
		_simbiosis_seal_btn.text = "🌱 SELLAR SIMBIOSIS (+4 PL)"
		_simbiosis_seal_btn.add_theme_font_size_override("font_size", 20)
		_simbiosis_seal_btn.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
		_simbiosis_seal_btn.custom_minimum_size = Vector2(0, 70)
		_simbiosis_seal_btn.pressed.connect(_on_simbiosis_seal_pressed)
		var panel := get_node_or_null("UIRootContainer/RightPanel")
		if panel:
			panel.add_child(_simbiosis_seal_btn)
			panel.move_child(_simbiosis_seal_btn, 0)
	_simbiosis_seal_btn.visible = true

func _on_simbiosis_seal_pressed():
	if is_instance_valid(_simbiosis_seal_btn):
		_simbiosis_seal_btn.visible = false
	close_run("SIMBIOSIS", "Cooperación sellada voluntariamente — estructura y biología en equilibrio")

func _apply_legacy_buffs() -> void:
	# LEGADO METABÓLICO: dinero inicial (150 × level, escala con cost_growth)
	var run_start_money: float = LegacyManager.get_effect_value("run_start_money")
	if run_start_money > 0.0 and not SaveManager._file_existed_on_load:
		EconomyManager.money += run_start_money
		add_lap("✦ [Legado] Legado Metabólico: +$%.0f al inicio" % run_start_money)

	# PLASTICIDAD ADAPTATIVA: omega_min floor 0.30
	if LegacyManager.get_buff_value("plasticidad_adaptativa"):
		var floor_val: float = LegacyManager.get_effect_value("omega_min_floor")
		if StructuralModel.omega_min < floor_val:
			StructuralModel.omega_min = floor_val
			add_lap("✦ [Legado] Plasticidad Adaptativa: Ω_min → %.2f" % floor_val)

	# UMBRAL COGNITIVO / RESONANCIA COGNITIVA: nivel cognitivo inicial +1
	var cog_bonus: float = LegacyManager.get_effect_value("start_nivel_cognitivo_bonus")
	if cog_bonus >= 1.0 and not SaveManager._file_existed_on_load:
		var bonus_int: int = int(cog_bonus)
		if UpgradeManager.states.has("cognitive"):
			UpgradeManager.states["cognitive"].level += bonus_int
			add_lap("✦ [Legado] Bonus Cognitivo: nivel_cognitivo +%d" % bonus_int)

	# NG+ MENTE COLMENA: activa el auto-click permanente si el buff está activo
	if LegacyManager.get_buff_value("mente_colmena"):
		mente_colmena_active = true
		add_lap("🧠 [NG+] Mente Colmena — IA distribuida activa desde el inicio (auto-click ×10)")

	# LEGADO ALOSTASIS: Ω_min garantizado ≥ 0.45
	if LegacyManager.get_buff_value("legado_alostasis"):
		if StructuralModel.omega_min < 0.45:
			StructuralModel.omega_min = 0.45
		add_lap("✦ [NG+] Resiliencia Alostática — Ω_min garantizado ≥ 0.45")

	# LEGADO HOMEORRESIS: Ω_min garantizado ≥ 0.55
	if LegacyManager.get_buff_value("legado_homeorresis"):
		if StructuralModel.omega_min < 0.55:
			StructuralModel.omega_min = 0.55
		add_lap("✦ [NG+] Trascendencia Cristalina — Ω_min garantizado ≥ 0.55")

	# SANGRE NEGRA: biomasa inicial ×1.30 si viene de ruta Parasitismo
	if LegacyManager.get_buff_value("sangre_negra"):
		var parasitism_done: bool = LegacyManager.endings_achieved.get("PARASITISMO", false)
		if parasitism_done and not SaveManager._file_existed_on_load:
			var mult: float = LegacyManager.get_effect_value("parasitism_biomasa_start_mult")
			BiosphereEngine.biomasa *= mult
			add_lap("✦ [Legado] Sangre Negra: Biomasa inicial ×%.2f" % mult)

	# NG+ NOTIFICACIONES al inicio de run
	if LegacyManager.get_buff_value("aura_dorada"):
		add_lap("✦ [NG+] Aura Dorada activa — click ×1.5, pasivo ×1.5")
	if LegacyManager.get_buff_value("semilla_cosmica"):
		add_lap("✦ [NG+] Semilla Cósmica activa — click ×2.0, pasivo ×2.0")
	if LegacyManager.get_buff_value("mente_colmena"):
		add_lap("✦ [NG+] Mente Colmena activa — pasivo ×3.0 (la singularidad se distribuyó)")
	if LegacyManager.get_buff_value("metabolismo_glitch"):
		add_lap("✦ [NG+] Metabolismo Glitch presente — se activa con ε > 0.40 (click ×1.5, pasivo ×1.8)")

func _apply_cosmic_buffs() -> void:
	# Solo aplica si hay trascendencias previas (no afecta runs sin prestige)
	if LegacyManager.trascendencia_count == 0:
		return

	# IMPULSO INICIAL (T1): +$500 al empezar la run
	if LegacyManager.has_cosmic_buff("impulso_inicial"):
		if not SaveManager._file_existed_on_load:
			EconomyManager.money += 500.0
			add_lap("✦ [Cósmico] Impulso Inicial: +$500")

	# OMEGA PRIMORDIAL (T1): Ω_min +0.05
	if LegacyManager.has_cosmic_buff("omega_primordial"):
		StructuralModel.omega_min = max(StructuralModel.omega_min, StructuralModel.omega_min + 0.05)
		add_lap("✦ [Cósmico] Omega Primordial: Ω_min +0.05")

	# RESONANCIA BIÓTICA (T1): Biomasa inicial 1.5
	if LegacyManager.has_cosmic_buff("resonancia_biotica"):
		if BiosphereEngine.biomasa < 1.5:
			BiosphereEngine.biomasa = 1.5
			add_lap("✦ [Cósmico] Resonancia Biótica: Biomasa → 1.5")

	# ECO DE LEGADO (T1): +5 PL al inicio de run
	if LegacyManager.has_cosmic_buff("eco_de_legado"):
		if not SaveManager._file_existed_on_load:
			LegacyManager.add_pl(5)
			add_lap("✦ [Cósmico] Eco de Legado: +5 PL")

	# MEMORIA PERSISTENTE (T2): Accounting y Trueque nivel 1 gratis
	if LegacyManager.has_cosmic_buff("memoria_persistente"):
		if UpgradeManager.level("accounting") == 0:
			UpgradeManager.states["accounting"].level = 1
			var def_acc = UpgradeManager.get_def("accounting")
			if def_acc:
				UpgradeManager.states["accounting"].current_value = def_acc.base_value + def_acc.gain
				UpgradeManager.states["accounting"].unlocked = true
			add_lap("✦ [Cósmico] Memoria Persistente: Contabilidad nivel 1 gratis")
		# Desbloquear dependientes de accounting
		for other_id in UpgradeManager.states.keys():
			var other_def = UpgradeManager.get_def(other_id)
			if other_def and other_def.unlock_requires == "accounting":
				UpgradeManager.states[other_id].unlocked = true

func apply_flexibility_modifier(factor: float):
	StructuralModel.apply_flexibility_modifier(factor)

func enable_persistence_inertia(factor: float):
	StructuralModel.enable_persistence_inertia(factor)

func apply_symbiotic_stabilization():
	# más flexibilidad estructural
	StructuralModel.omega = min(1.0, StructuralModel.omega * 1.25)

	# amortiguación permanente del estrés
	EconomyManager.mutation_accounting_bonus = min(0.6, EconomyManager.mutation_accounting_bonus + 0.15)

	# mejora pasivo sin romper el modelo
	EconomyManager.trueque_efficiency *= 1.1
	EconomyManager.mutation_auto_factor *= 1.05
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


func apply_dynamic_persistence(delta: float) -> void:
	StructuralModel.apply_dynamic_persistence(delta)


# === Persistencia estructural ===
# c₀  → baseline fijo
# fⁿ  → objetivo teórico según n
# cₙ  → estado dinámico observado

func get_persistence_target() -> float:
	return StructuralModel.get_persistence_target()

# =====================================================
#  MODELO ESTRUCTURAL — v0.6.4
# =====================================================

func get_k_eff() -> float:
	return StructuralModel.get_k_eff()

func register_structural_baseline():
	StructuralModel.register_structural_baseline()

# =====================================================
#  CAPITAL COGNITIVO (μ) — v0.7
# Gestionado vía UpgradeManager
# =====================================================
#  VISUALIZACIÓN DE LAPS
# =====================================================
func _on_ToggleLapViewButton_pressed():
	toggle_lap_view()


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
	StructuralModel.structural_cooldown = StructuralModel.STRUCTURAL_COOLDOWN_TIME
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
				StructuralModel.omega = max(StructuralModel.omega, 0.45) # Subido de 0.38
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
	var banda_estricta = RunManager.get_en_banda_homeostatica()
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
			return "El sistema prioriza absorción total sobre estabilidad\n⚡ EFECTOS ACTIVOS: Click PUSH ×10 | Pasivo ×0.25 (-75%) | Fragilidad Ω total"
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
#  LAP MARKERS
# =====================================================

func add_lap(event: String) -> void:
	LogManager.add(event, self)


func check_dominance_transition():
	LogManager.check_dominance_transition(self)

func _on_ExportRunButton_pressed():
	LogManager.export_run(self)


func check_achievements():
	# Empujar snapshot del estado del mundo antes del tick de evaluación.
	AchievementManager.push_snapshot({
		"epsilon":         StructuralModel.epsilon_effective,
		"biomasa":         BiosphereEngine.biomasa,
		"k_eff":           get_k_eff(),
		"delta_total":     get_delta_total(),
		"money":           EconomyManager.money,
		"total_money":     EconomyManager.total_money_generated,
		"resilience_score":RunManager.resilience_score,
		"dominant_term":   get_dominant_term(),
		"parasitism":      EvoManager.mutation_parasitism,
	})
	AchievementManager.check_tick(LOGIC_TICK)
func show_system_toast(message: String) -> void:
	if UIManager.system_message_label:
		UIManager.system_message_label.text = message

func update_achievements_label():
	# Vista resumida en el HUD. Detalles completos se ven en el menú principal.
	var total := AchievementManager.total_count()
	var got := AchievementManager.unlocked_count()
	var t := "--- Logros (%d / %d) ---\n" % [got, total]
	# Recorrer por tier
	for tier in [AchievementManager.Tier.MICELIO, AchievementManager.Tier.ESPORA, AchievementManager.Tier.FRUTO, AchievementManager.Tier.ANCESTRAL]:
		var ids: Array = AchievementManager.get_by_tier(tier)
		var ok := 0
		for id in ids:
			if AchievementManager.is_unlocked(id): ok += 1
		t += "%s %s: %d/%d\n" % [
			AchievementManager.TIER_ICONS[tier],
			AchievementManager.TIER_NAMES[tier],
			ok,
			ids.size()
		]

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
	# Los logros persisten entre runs (vivían en main.gd como flags, ahora en AchievementManager).
	# Sólo borramos el estado efímero (timers, contadores de click, etc.)
	AchievementManager.reset_run_state()
	_parasitism_status_timer = 0.0
	depredador_tick = 0.0
	_depredador_status_timer = 0.0
	_met_oscuro_income_accum = 0.0
	_met_oscuro_status_timer = 0.0
	if is_instance_valid(_met_oscuro_seal_btn):
		_met_oscuro_seal_btn.queue_free()
		_met_oscuro_seal_btn = null
	if is_instance_valid(_simbiosis_seal_btn):
		_simbiosis_seal_btn.queue_free()
		_simbiosis_seal_btn = null
	mente_colmena_timer = 0.0
	_mente_colmena_buy_timer = 0.0
	_glitch_was_active = false
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

	# Inicializar managers con referencia a main ANTES de update_ui()
	RunManager.set_main(self)
	AchievementManager.set_main(self)
	EconomyManager.set_main(self)
	StructuralModel.set_main(self)

	# =====================================================
	#  BANCO GENÉTICO — Aplicar buffs al inicio de run
	# =====================================================
	_apply_legacy_buffs()

	# =====================================================
	#  BANCO CÓSMICO — Aplicar buffs al inicio de run
	# =====================================================
	_apply_cosmic_buffs()

	# =====================================================
	#  RUTAS POST-TRASCENDENCIA — Activar si corresponde
	# =====================================================
	RunManager.activate_post_tras_route()

	update_ui()

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
		# Mostrar/ocultar el Fungi DLC (violeta)
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
	AchievementManager.on_click()

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
	EconomyManager.time_since_last_click += delta
	_sync_reactor_color()

func _on_logic_tick():
	# === 5 Hz — toda la lógica de simulación ===
	var dt := LOGIC_TICK

	# Cache mu (evita 500+ calls por segundo a get_mu_structural_factor)
	cached_mu = get_mu_structural_factor()

	# NG+ Mente Colmena (Juego automático por IA fúngica)
	# Sync estado con el toggle del Banco Genético (solo cuando cambia)
	if LegacyManager.get_buff_level("mente_colmena") > 0 and not RunManager.run_closed:
		var buff_on := LegacyManager.get_buff_value("mente_colmena")
		if mente_colmena_active and not buff_on:
			mente_colmena_active = false
			add_lap("🧠 Mente Colmena — IA desactivada desde el Banco Genético")
	if mente_colmena_active:
		# Auto-click: simula 10 clicks por segundo
		var sim_power = get_click_power() * 10.0 * dt
		EconomyManager.money += sim_power
		StructuralModel.epsilon_runtime += 0.008 * 10.0 * dt
		if is_instance_valid(UIManager.big_click_button):
			UIManager.big_click_button.set_active_delta(sim_power)
		# Auto-buy: compra upgrades según prioridad cada MENTE_COLMENA_BUY_INTERVAL segundos
		_mente_colmena_buy_timer += dt
		if _mente_colmena_buy_timer >= MENTE_COLMENA_BUY_INTERVAL:
			_mente_colmena_buy_timer = 0.0
			_mente_colmena_auto_buy()
	elif LegacyManager.last_run_ending == "SINGULARIDAD" and EvoManager.red_branch_selected == EvoManager.RedBranch.SYMBIOSIS:
		var ap = get_active_passive_breakdown()
		var tot = ap.activo + ap.pasivo
		if tot > 0:
			var ratio = ap.activo / tot
			# Si el estrés supera 0.50, rompe la sincronización
			var stress_too_high = StructuralModel.epsilon_runtime > 0.50
			if abs(ratio - 0.5) <= 0.02 and not stress_too_high:
				var was_zero := mente_colmena_timer == 0.0
				mente_colmena_timer += dt
				if was_zero:
					add_lap("🧠 SINCRONÍA DETECTADA — Manteniendo ratio 50/50 durante 180s para MENTE COLMENA...")
				if mente_colmena_timer >= 180.0:
					activate_mente_colmena()
				else:
					var pct := int(mente_colmena_timer / 180.0 * 100.0)
					var prev_pct := int((mente_colmena_timer - dt) / 180.0 * 100.0)
					if pct / 25 > prev_pct / 25: # lap cada 25%
						add_lap("🧠 MENTE COLMENA — Sincronía %d%% (%.0f/180s)" % [pct, mente_colmena_timer])
					show_system_toast("🧠 MENTE COLMENA — %d%% (%.0f/180s) — ratio %.1f%%/%.1f%%" % [pct, mente_colmena_timer, ap.activo, ap.pasivo])
			else:
				if mente_colmena_timer > 0.0:
					if stress_too_high:
						add_lap("⚠️ Sincronía rota — estrés demasiado alto (%.2f > 0.50)" % StructuralModel.epsilon_runtime)
					else:
						add_lap("⚠️ Sincronía rota — timer MENTE COLMENA reiniciado (ratio: %.1f%%/%.1f%%)" % [ap.activo, ap.pasivo])
				mente_colmena_timer = 0.0

	# NG++ Metabolismo Oscuro (Post-Depredador) — congela el devorar, metaboliza biomasa
	if EvoManager.mutation_met_oscuro:
		met_oscuro_tick(dt)
	# NG+ Depredador de Realidades (Glitch Survival)
	elif EvoManager.mutation_depredador:
		depredador_tick += dt
		if depredador_tick >= 1.5:
			depredador_tick = 0.0
			var devoured = UpgradeManager.devour_random_upgrade()
			if devoured:
				BiosphereEngine.biomasa += 15.0 # Massive biomassa growth
				EvoManager.met_oscuro_devoured_count += 1
				show_system_toast("⚠️ GLITCH: El hongo ha digerido memoria estructural (%d)." % EvoManager.met_oscuro_devoured_count)
				if is_instance_valid(UIManager.big_click_button):
					UIManager.big_click_button.modulate = Color(randf(), randf(), randf())
			else:
				close_run("DEPREDADOR DE REALIDADES", "El hongo ha consumido todo tu código fuente. Ya no existes. (+12 PL)")
	# DEPREDADOR EN PROGRESO — Mostrar barra de progreso cada 10s
	elif EvoManager.depredador_timer > 0.0 and EvoManager.depredador_timer < 30.0:
		_depredador_status_timer += dt
		if _depredador_status_timer >= DEPREDADOR_STATUS_INTERVAL:
			_depredador_status_timer = 0.0
			var pct := int((EvoManager.depredador_timer / 30.0) * 100.0)
			var bar_len := int(pct / 5.0)  # 20 caracteres para 100%
			var bar := ""
			for i in range(20):
				bar += "█" if i < bar_len else "░"
			add_lap("☠️ DEPREDADOR — ε %.2f/0.95 | Progreso: %s %d%% (%.0f/30s)" % [
				StructuralModel.epsilon_runtime, bar, pct, EvoManager.depredador_timer
			])
			show_system_toast("☠️ DEPREDADOR EN PROGRESO — %d%% (%.0f/30s)" % [pct, EvoManager.depredador_timer])

	# NG+ Metabolismo Glitch — notificación cuando el umbral de estrés cambia
	if LegacyManager.get_buff_value("metabolismo_glitch"):
		var glitch_now := StructuralModel.epsilon_runtime > 0.40
		if glitch_now and not _glitch_was_active:
			add_lap("🦠 GLITCH ACTIVO — El sustrato parasitario prospera en el caos (click ×1.5, pasivo ×1.8)")
			show_system_toast("🦠 Metabolismo Glitch ACTIVO — ε > 0.40")
		elif not glitch_now and _glitch_was_active:
			show_system_toast("🦠 Metabolismo Glitch inactivo")
		_glitch_was_active = glitch_now

	# 1) Economía base
	apply_dynamic_persistence(dt)
	delta_per_sec = get_passive_total()
	update_economy(dt)

	# 2) Estrés del sistema
	update_epsilon_runtime()

	# 3) Biósfera y nutrientes
	# Pasamos solo el ingreso pasivo (no total) para que hifas no escale con clicks ni legados activos
	var bio_passive_income := EconomyManager.get_passive_total()
	StructuralModel.epsilon_effective = BiosphereEngine.process_tick(
		dt,
		bio_passive_income,
		StructuralModel.epsilon_runtime,
		EvoManager.mutation_hyperassimilation,
		EvoManager.mutation_homeostasis,
		EvoManager.mutation_symbiosis,
		EvoManager.mutation_red_micelial,
		EvoManager.mutation_parasitism,
		EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION
	)

	# 4) Actualizar valor del reactor
	var power := get_click_power()
	if is_instance_valid(UIManager.big_click_button):
		UIManager.big_click_button.set_display_delta(power)
		if mente_colmena_timer > 0.0 and not mente_colmena_active:
			UIManager.big_click_button.text = "🧠 %d%%" % int(mente_colmena_timer / 180.0 * 100.0)
		else:
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
	var complexity_impact: float = get_effective_structural_n() / max(cached_mu, 1.0)
	StructuralModel.omega = 1.0 / max(1.0 + StructuralModel.epsilon_effective * complexity_impact, 0.0001)

	# PARASITISMO: Techo duro de Ω 0.25 — aplicado aquí para no ser pisado por el cálculo de arriba
	if EvoManager.mutation_parasitism:
		StructuralModel.omega = min(StructuralModel.omega, 0.25)
		StructuralModel.omega_min = min(StructuralModel.omega_min, 0.25)

	# --- SHOCK TRACKING --- (delegado a RunManager)
	RunManager.check_shock_tracking()

	# --- CARNAVAL DE MUTACIONES (Post-Trascendencia) ---
	if RunManager.carnaval_active:
		RunManager.update_carnaval(dt)

	# 8) Decisiones evolutivas (v0.8.8 - Centralizado en EvoManager)
	if EvoManager.mutation_homeostasis:
		RunManager.check_homeostasis_final(dt)
	if EvoManager.mutation_allostasis:
		RunManager.check_allostasis_final(dt)
	if EvoManager.mutation_homeorhesis:
		RunManager.check_homeorhesis_final(dt)
	if EvoManager.mutation_symbiosis:
		RunManager.check_symbiosis_final(dt)
		_update_simbiosis_seal_button()
	if EvoManager.mutation_red_micelial:
		EvoManager.check_red_micelial_transition(self)
		EvoManager.update_primordio(self)  # Timer del ciclo biológico
	# homeostasis_mode genera shocks periódicos — NO aplica durante SIMBIOSIS
	if RunManager.homeostasis_mode and not EvoManager.mutation_symbiosis:
		RunManager.update_homeostasis_mode(dt)
	if RunManager.post_homeostasis:
		RunManager.check_perfect_homeostasis()
	if EvoManager.mutation_parasitism:
		RunManager.check_parasitism_final(dt)
	# FRACTURA EPISTÉMICA: siempre chequear si está habilitada
	if LegacyManager.has_cosmic_buff("fractura_epistemica"):
		RunManager.check_fractura_epistemica(dt)
		_parasitism_status_timer += dt
		if _parasitism_status_timer >= PARASITISM_STATUS_INTERVAL:
			_parasitism_status_timer = 0.0
			var bio := BiosphereEngine.biomasa
			var omg := StructuralModel.omega
			var eps := StructuralModel.epsilon_effective
			var money_now := EconomyManager.money
			add_lap("🦠 PARASITISMO — Bio:%.1f/18 | Ω:%.2f/0.22 | ε:%.2f/0.45 | $%.0f" % [bio, omg, eps, money_now])

	# 9) Cooldown estructural
	if StructuralModel.structural_cooldown > 0.0:
		StructuralModel.structural_cooldown -= dt
		if StructuralModel.structural_cooldown <= 0.0:
			register_structural_baseline()

	# 10) Instituciones y esporulación
	check_institution_unlock()
	RunManager.check_sporulation_trigger(dt)

func _on_ui_tick():
	# === 10 Hz — actualizar labels y botones ===
	update_ui()
	_update_evolution_progress_bar()

	# Update header bar (Phase 2)
	var delta_real = EconomyManager.get_contribution_breakdown().total
	UIManager.update_header_money(EconomyManager.money, delta_real)
	UIManager.update_header_metrics(
		StructuralModel.epsilon_runtime,
		StructuralModel.omega,
		BiosphereEngine.biomasa,
		12.0  # biomasa_max for progress bar
	)

	# Update structural metrics panel (Phase 4)
	UIManager.update_structural_metrics(
		StructuralModel.epsilon_runtime,
		StructuralModel.omega,
		StructuralModel.persistence_dynamic,
		UpgradeManager.level("accounting")
	)

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

	# Mostrar efectos activos como lap (visible en pantalla final)
	match id:
		"hiperasimilacion":
			# Extra emphasis para los buffs
			show_system_toast("🔥 HIPERASIMILACIÓN EXTREMA 🔥 — Click ×10 | Pasivo anulado | Run termina ahora")
		"parasitismo":
			LogManager.add("🦠 EFECTOS: Biomasa +100% / Pasivo +20% / Contabilidad -10% / Ω máx 0.25", self)
			show_system_toast("🦠 PARASITISMO ACTIVO — El hongo drena la estructura")
		"homeostasis":
			LogManager.add("⚖️ EFECTOS: Producción +50% / ε estabilizado / Ω_min 0.35", self)
		"red_micelial":
			LogManager.add("🕸️ EFECTOS: Pasivo ×2.5 / Click -50% / Bifurcación evolutiva", self)
		"simbiosis":
			LogManager.add("🌱 EFECTOS: Click ×2.5 / Pasivo -50%", self)
		"allostasis":
			LogManager.add("🔬 EFECTOS: Resiliencia alostática activa / Setpoint recalibrable", self)
		"homeorhesis":
			LogManager.add("✨ EFECTOS: Trascendencia cristalina / Metabolismo irreversible", self)
		"depredador":
			LogManager.add("☠️ EFECTOS: Devora upgrades cada 1.5s / El código se consume", self)
			show_system_toast("☠️ DEPREDADOR ACTIVO — La realidad está siendo consumida")
		"met_oscuro":
			LogManager.add("🌑 EFECTOS: Devorar detenido · Pasivo = Bio×0.8/s · Click ×3 · ε decae · Ω 0.10", self)
			show_system_toast("🌑 METABOLISMO OSCURO — Bioquímica alternativa estabilizada")

	if id == "red_micelial":
		# Activar el popup de elección (v0.8.32 - Modular)
		dimmer.visible = true
		evo_choice_panel.visible = true
		update_bifurcation_panel()
	
	update_ui()

func update_bifurcation_panel():
	if not is_instance_valid(evo_choice_panel) or not evo_choice_panel.visible:
		return

	var data := UIManager.build_bifurcation_data(self)

	# Asignar header
	evo_choice_panel.get_node("Margin/VBox/TopBar/Header").text = data["header"]

	# MODO TIER 1: Selección inicial
	if data["tier_mode"] == "tier1":
		opt_homeostasis.visible = true
		opt_colonization.visible = true
		opt_symbiosis.visible = true

		opt_homeostasis.find_child("Desc").text = data["homeostasis_text"]
		btn_homeostasis.text = "Equilibrar"
		btn_homeostasis.disabled = not data["homeostasis_ready"]

		evo_choice_panel.find_child("OptColonization", true, false).find_child("Icon").text = "🕸️"
		evo_choice_panel.find_child("OptColonization", true, false).find_child("Desc").text = data["red_micelial_text"]
		btn_colonization.text = "Ramificar"
		btn_colonization.disabled = not data["red_micelial_ready"]

		evo_choice_panel.find_child("OptSymbiosis", true, false).find_child("Icon").text = "🌱"
		evo_choice_panel.find_child("OptSymbiosis", true, false).find_child("Desc").text = data["simbiosis_text"]
		btn_symbiosis.text = "Fusionar"
		btn_symbiosis.disabled = not data["simbiosis_ready"]

	# MODO TIER 2: Homeostasis
	elif data["tier_mode"] == "tier2_homeostasis":
		opt_homeostasis.visible = true
		opt_colonization.visible = false
		opt_symbiosis.visible = false

		opt_homeostasis.find_child("Desc").text = data["allostasis_text"]
		btn_homeostasis.text = "¡EVOLUCIONAR!" if data["allostasis_ready"] else "[REQUISITOS NO MET]"
		btn_homeostasis.disabled = not data["allostasis_ready"]
		btn_homeostasis.modulate = Color(0, 1, 1)  # Cyan

	# MODO TIER 2: Sub-ramas de Red Micelial
	else:
		opt_homeostasis.visible = false
		opt_colonization.visible = true
		opt_symbiosis.visible = true

		evo_choice_panel.find_child("OptColonization", true, false).find_child("Icon").text = "🌿"
		evo_choice_panel.find_child("OptColonization", true, false).find_child("Desc").text = data["colonization_text"]
		btn_colonization.text = "Colonizar"
		btn_colonization.disabled = not data["colonization_ready"]

		evo_choice_panel.find_child("OptSymbiosis", true, false).find_child("Icon").text = "💾"
		evo_choice_panel.find_child("OptSymbiosis", true, false).find_child("Desc").text = data["symbiosis_text"]
		btn_symbiosis.disabled = not data["symbiosis_ready"]
		btn_symbiosis.text = "Integrar Hardware [req. Cont. 2]" if not data["symbiosis_ready"] else "Integrar Hardware"

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
	if EvoManager.mutation_red_micelial:
		# CASO TIER 2: Sub-rama de Red Micelial → Singularidad
		_on_branch_selected(EvoManager.RedBranch.SYMBIOSIS)
		evo_choice_panel.visible = false
		$DimmerBackground.visible = false
	elif not EvoManager.mutation_symbiosis:
		# CASO TIER 1: Activación de Simbiosis (solo si no está activa ya)
		EvoManager.activate_mutation("simbiosis")
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
		EconomyManager.mutation_auto_factor *= 1.5 
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
			LegacyManager.grant_buff("semilla_cosmica")
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
		LegacyManager.grant_buff("mente_colmena")
		show_system_toast("✨ Has desbloqueado el legado: MENTE COLMENA DISTRIBUIDA")

	close_run("MENTE COLMENA DISTRIBUIDA", "Tus patrones psicomotores han sido asimilados. El administrador es obsoleto. (+8 PL)")

# IA Mente Colmena — compra automática de upgrades cada MENTE_COLMENA_BUY_INTERVAL segundos.
# Primero revisa la lista de prioridades; si ninguno es asequible, compra el más barato disponible.
func _mente_colmena_auto_buy() -> void:
	if RunManager.run_closed:
		return

	var bought_id: String = ""
	var bought_cost: float = 0.0

	# Fase 1 — recorrer lista de prioridades (solo si el upgrade es asequible Y desbloqueado)
	for id in MENTE_COLMENA_BUY_PRIORITY:
		if not UpgradeManager.can_buy(id, EconomyManager.money):
			continue
		var c := UpgradeManager.cost(id)
		if UpgradeManager.buy(id, EconomyManager.money):
			EconomyManager.money -= c
			bought_id = id
			bought_cost = c
			_on_upgrade_bought_actions(id)
			break

	# Fase 2 — fallback: compra el upgrade disponible más barato
	if bought_id == "":
		var best_id := ""
		var best_cost := INF
		for id in UpgradeManager.states.keys():
			var c := UpgradeManager.cost(id)
			if c > 0.0 and c < best_cost and UpgradeManager.can_buy(id, EconomyManager.money):
				best_cost = c
				best_id = id
		if best_id != "":
			if UpgradeManager.buy(best_id, EconomyManager.money):
				EconomyManager.money -= best_cost
				bought_id = best_id
				bought_cost = best_cost
				_on_upgrade_bought_actions(best_id)

	# Log + toast si se compró algo
	if bought_id != "":
		var def := UpgradeManager.get_def(bought_id)
		var label_str := def.label if def else bought_id
		add_lap("🧠 IA: Comprado [%s] ($%.0f)" % [label_str, bought_cost])
		show_system_toast("🧠 IA compró: %s" % label_str)
		update_ui()

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
		
	# Iterar sobre las mejoras disponibles (solo reveladas)
	for id in LegacyManager.LEGACY_DEFS:
		if not LegacyManager.is_revealed(id):
			continue
		var def: Dictionary = LegacyManager.LEGACY_DEFS[id]
		var lvl: int = LegacyManager.get_buff_level(id)
		var max_lvl: int = int(def.get("max_level", 1))
		var is_maxed: bool = lvl >= max_lvl
		var cost: int = LegacyManager.get_current_cost(id)

		var h_box: HBoxContainer = HBoxContainer.new()
		h_box.custom_minimum_size = Vector2(0, 50)

		var v_info: VBoxContainer = VBoxContainer.new()
		v_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var l_title: Label = Label.new()
		var lvl_str: String = (" [%d/%d]" % [lvl, max_lvl]) if max_lvl > 1 else ""
		l_title.text = def.get("name", id) + lvl_str + (" [MÁXIMO]" if is_maxed else " (%d PL)" % cost if def.get("cost", 0) > 0 else " [GRATIS]")
		l_title.add_theme_font_size_override("font_size", 13)
		var is_enabled: bool = LegacyManager.buff_enabled.get(id, true)
		if lvl > 0 and not is_enabled:
			l_title.modulate = Color(0.45, 0.45, 0.45)  # Desactivado → gris
		elif is_maxed:
			l_title.modulate = Color.GREEN
		elif lvl > 0:
			l_title.modulate = Color(0.5, 0.9, 0.6)

		var l_desc: Label = Label.new()
		l_desc.text = def.get("flavor", "")
		l_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l_desc.add_theme_font_size_override("font_size", 10)
		l_desc.modulate = Color(0.7, 0.7, 0.7)

		v_info.add_child(l_title)
		v_info.add_child(l_desc)

		if lvl > 0:
			# Buff ya comprado → mostrar toggle ACTIVO / INACTIVO
			var is_on: bool = LegacyManager.buff_enabled.get(id, true)
			var toggle_btn: Button = Button.new()
			toggle_btn.custom_minimum_size = Vector2(100, 30)
			toggle_btn.text = "✓ ACTIVO" if is_on else "✗ INACTIVO"
			toggle_btn.modulate = Color(0.4, 1.0, 0.5) if is_on else Color(0.6, 0.6, 0.6)
			toggle_btn.pressed.connect(func():
				var new_state: bool = LegacyManager.toggle_buff_enabled(id)
				# Mente Colmena: sincronizar el flag de IA en tiempo real
				if id == "mente_colmena" and not RunManager.run_closed:
					mente_colmena_active = new_state
					add_lap("🧠 Mente Colmena — IA %s manualmente" % ("activada" if new_state else "desactivada"))
				_refresh_legacy_store()
				show_system_toast(def.get("name", id) + (": ACTIVADO ✓" if new_state else ": DESACTIVADO ✗"))
				update_ui()
			)
			h_box.add_child(v_info)
			h_box.add_child(toggle_btn)
		else:
			# Buff no comprado → botón de compra normal
			var btn: Button = Button.new()
			btn.text = "COMPRAR"
			btn.custom_minimum_size = Vector2(100, 30)
			btn.disabled = not LegacyManager.can_afford(id)
			btn.pressed.connect(func():
				if LegacyManager.purchase_legacy(id):
					_refresh_legacy_store()
					show_system_toast("Banco: Compraste " + def.get("name", id))
			)
			h_box.add_child(v_info)
			h_box.add_child(btn)

		var sep: HSeparator = HSeparator.new()
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
	var decay_factor = clamp(1.0 - (EconomyManager.time_since_last_click / 5.0), 0.0, 1.0)
	StructuralModel.epsilon_active = (epsilon_prod + epsilon_comp) * decay_factor

	# =================================================
	# 2) ε_pasivo — rigidez / cristalización
	# =================================================
	StructuralModel.epsilon_passive = 0.0

	if passive_ratio > PASSIVE_RATIO_START:
		var excess := passive_ratio - PASSIVE_RATIO_START
		var rigidity := (1.0 - StructuralModel.omega)
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
	StructuralModel.omega = EcoModel.get_omega(StructuralModel.epsilon_runtime, k_eff, n_struct)
	# omega_min sube lentamente cuando omega está por encima (siempre, incluso en homeostasis)
	if StructuralModel.omega > StructuralModel.omega_min:
		StructuralModel.omega_min = move_toward(StructuralModel.omega_min, StructuralModel.omega, 0.002)
	# En homeostasis: piso mínimo de seguridad estructural
	if EvoManager.mutation_homeostasis:
		StructuralModel.omega_min = max(StructuralModel.omega_min, 0.35)
	# CRÍTICO: omega_min no solo registra el mínimo, PROTEGE el piso real de Ω
	StructuralModel.omega = max(StructuralModel.omega, StructuralModel.omega_min)

	# ALOSTASIS: Piso de estabilidad adaptativo (Ω >= 0.60)
	if EvoManager.mutation_allostasis:
		StructuralModel.omega = max(StructuralModel.omega, 0.60)
	elif LegacyManager.get_buff_value("legado_homeorresis"):
		StructuralModel.omega = max(StructuralModel.omega, 0.55) # Trascendencia: Ω permanente superior
	elif LegacyManager.get_buff_value("legado_alostasis"):
		StructuralModel.omega = max(StructuralModel.omega, 0.45) # Beneficio persistente del legado

	# RAMA SIMBIOSIS: Piso de omega 0.50 (v0.8.5)
	if EvoManager.red_branch_selected == EvoManager.RedBranch.SYMBIOSIS:
		StructuralModel.omega = max(StructuralModel.omega, 0.50)

	# PARASITISMO: Techo de omega 0.25 — el hongo degrada la flexibilidad estructural
	if EvoManager.mutation_parasitism:
		StructuralModel.omega = min(StructuralModel.omega, 0.25)
		StructuralModel.omega_min = min(StructuralModel.omega_min, 0.25)
		
	# HIPERASIMILACIÓN: Colapso Estructural y Fragilidad
	if EvoManager.mutation_hyperassimilation:
		StructuralModel.omega = min(StructuralModel.omega, 0.75) # Cap de fragilidad
		# Decaimiento de persistencia (Inercia negativa)
		StructuralModel.persistence_dynamic = lerp(StructuralModel.persistence_dynamic, 1.0, 0.001)

	# ====================================================
	#  6) DEBUG EPSILON OUTPUT v0.8.2
	# =====================================================
	if StructuralModel.epsilon_debug:
		print("ε breakdown:",
		"act=", StructuralModel.epsilon_active,
		"pas=", StructuralModel.epsilon_passive,
		"cmp=", StructuralModel.epsilon_complex,
		"Ω=", StructuralModel.omega
	)
func _input(event):
	if event.is_action_pressed("ui_debug"):
		StructuralModel.epsilon_debug = !StructuralModel.epsilon_debug
		print("ε DEBUG =", StructuralModel.epsilon_debug)

	# Lab Mode toggle con tecla L — muestra/oculta fórmulas y stats (Phase 5)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_L:
			lab_mode = not lab_mode
			var formula = get_node_or_null("%FormulaLabel")
			var click_scroll = get_node_or_null("UIRootContainer/LeftPanel/CenterPanel/ClickStatsScroll")
			if formula: formula.visible = lab_mode
			if click_scroll: click_scroll.visible = lab_mode
			print("🔬 Lab Mode: %s" % ("ON" if lab_mode else "OFF"))

		# Atajos de teclado 1-9 para comprar upgrades
		const HOTKEY_UPGRADES := ["click", "auto", "trueque", "click_mult", "auto_mult",
								  "trueque_net", "specialization", "cognitive", "accounting"]
		var kc :int= event.keycode
		if kc >= KEY_1 and kc <= KEY_9:
			var idx :int= kc - KEY_1  # 0-based
			if idx < HOTKEY_UPGRADES.size():
				purchase_upgrade(HOTKEY_UPGRADES[idx])

		# DEBUG — Activar rutas post-trascendencia al vuelo (solo en debug build)
		if OS.is_debug_build():
			match kc:
				KEY_F3:
					LegacyManager.post_tras_route = "vacio"
					RunManager.activate_post_tras_route()
					show_system_toast("🐛 DEBUG: Vacío Hambriento activado")
				KEY_F4:
					LegacyManager.post_tras_route = "carnaval"
					RunManager.activate_post_tras_route()
					show_system_toast("🐛 DEBUG: Carnaval activado — %s" % str(RunManager.carnaval_mutations))
				KEY_F5:
					LegacyManager.post_tras_route = "reencarnacion"
					RunManager.activate_post_tras_route()
					show_system_toast("🐛 DEBUG: Reencarnación Heredada activada")


func check_institution_unlock():
	if StructuralModel.institution_accounting_unlocked:
		return

	var p := get_structural_pressure()
	# vía 1 (ya existe): crisis
	var inactivity_trigger = EconomyManager.time_since_last_click > 120.0 and BiosphereEngine.biomasa > 5.0 and StructuralModel.epsilon_runtime > 0.35
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
	if not UIManager.epsilon_sticky_label:
		return
	UIManager.epsilon_sticky_label.text = UIManager.build_epsilon_sticky_text(self)

func get_system_phase() -> String:
	return UIManager.get_system_phase(StructuralModel.omega)

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

# =====================================================
# UI HELPERS — v0.8
func update_core_labels():
	UIManager.update_money(EconomyManager.money)
	if UIManager.formula_label:
		UIManager.formula_label.text = build_formula_text()
	
	update_click_stats_panel()


func update_lab_metrics():
	var contrib :Dictionary= get_contribution_breakdown()
	var ap :Dictionary= get_active_passive_breakdown()

	if UIManager.sys_delta_label:
		UIManager.sys_delta_label.text = "Δ$ estimado / s = +%s" % snapped(contrib.total, 0.01)

	# DeltaTotalLabel — compact with suffix
	if UIManager.delta_total_label:
		var t :float= contrib.total
		var t_str: String
		if t >= 1_000_000_000.0:
			t_str = "+$%.2fB/s" % (t / 1_000_000_000.0)
		elif t >= 1_000_000.0:
			t_str = "+$%.2fM/s" % (t / 1_000_000.0)
		elif t >= 1_000.0:
			t_str = "+$%.1fK/s" % (t / 1_000.0)
		else:
			t_str = "+$%.2f/s" % t
		UIManager.delta_total_label.text = t_str

	UIManager.update_timer(run_time)

	# Activo vs Pasivo — visual bar
	if UIManager.sys_active_passive_label:
		var pct_act := int(ap.activo)
		var pct_pas := int(ap.pasivo)
		var bar_len := 20
		var filled := int(pct_act / 100.0 * bar_len)
		var bar := ""
		for i in range(bar_len):
			if i < filled:
				bar += "[color=#00ff88]█[/color]"
			else:
				bar += "[color=#ffcc00]█[/color]"
		var act_col := "[color=#00ff88]" if pct_act >= pct_pas else "[color=#aaaaaa]"
		var pas_col := "[color=#ffcc00]" if pct_pas > pct_act else "[color=#aaaaaa]"
		var push_str := UIManager.format_compact(ap.push_abs)
		var pass_str := UIManager.format_compact(ap.passive_abs)
		var txt := act_col + "▲ ACT  %d%%  +%s/s[/color]\n" % [pct_act, push_str]
		txt += pas_col + "▼ PAS  %d%%  +%s/s[/color]\n" % [pct_pas, pass_str]
		txt += "[color=#555555][%s][/color]" % bar
		UIManager.sys_active_passive_label.text = txt

	# Distribución por fuente — colored bar
	if UIManager.sys_breakdown_label:
		var c_pct := int(contrib.click)
		var d_pct := int(contrib.d)
		var e_pct := int(contrib.e)
		var bar_len := 20
		var fc := int(c_pct / 100.0 * bar_len)
		var fd := int(d_pct / 100.0 * bar_len)
		var fe :int= max(bar_len - fc - fd, 0)
		var bar := "[color=#ff8844]" + "█".repeat(fc) + "[/color]"
		bar += "[color=#44aaff]" + "█".repeat(fd) + "[/color]"
		bar += "[color=#00ffcc]" + "█".repeat(fe) + "[/color]"
		var click_str := UIManager.format_compact(ap.push_abs)
		var auto_str  := UIManager.format_compact(EconomyManager.get_auto_income_effective())
		var trueq_str := UIManager.format_compact(EconomyManager.get_trueque_income_effective())
		var txt := "[color=#ff8844]● Click %d%% +%s/s[/color]  " % [c_pct, click_str]
		txt += "[color=#44aaff]● Manual %d%% +%s/s[/color]  " % [d_pct, auto_str]
		txt += "[color=#00ffcc]● Trueque %d%% +%s/s[/color]\n" % [e_pct, trueq_str]
		txt += "[color=#555555][%s][/color]" % bar
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

	# Header bar
	UIManager.update_header_money(EconomyManager.money, delta_per_sec)
	UIManager.update_header_metrics(
		StructuralModel.epsilon_runtime,
		StructuralModel.omega,
		BiosphereEngine.biomasa,
		20.0
	)


	# Panel de mutación en columna central (siempre visible si hay contenido)
	UIManager.update_mutation_center_panel(self)

	if institutions_unlocked or UpgradeManager.level("accounting") >= 1:
		if UIManager.institution_panel_label:
			UIManager.institution_panel_label.visible = true
			UIManager.institution_panel_label.text = UIManager.build_institution_panel_text(self)

	if StructuralModel.institution_accounting_unlocked:
		pass # Los botones genéricos se encargan de visibilidad
	else:
		pass

	update_lab_metrics()
	update_lap_log()

	if is_instance_valid(btn_evolve):
		if RunManager.run_closed:
			btn_evolve.visible = false
		elif EvoManager.mutation_parasitism:
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


# =====================================================
#  PERSISTENCIA DE DATOS (Save/Load)
# =====================================================
