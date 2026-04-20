extends Node

# RunManager.gd — Autoload
# Gestiona el ciclo de vida de la run: cierres, chequeos finales, homeostasis, perturbaciones.

var main: Node = null

# ==================== ESTADO DE RUN ====================
var run_closed := false
var final_route := "NONE"
var final_reason := ""
var homeostasis_mode := false
var post_homeostasis := false
var homeostasis_timer := 0.0
const HOMEOSTASIS_TIME_REQUIRED := 18.0

var resilience_score := 0.0
var disturbance_timer := 0.0
const DISTURBANCE_INTERVAL := 20.0

var legacy_homeostasis := false
var disturbances_survived: int = 0
var is_recovering_from_shock: bool = false
var extreme_shock_survived: bool = false

var evolution_button: Button = null
var target_evolution: String = ""

# ==================== INICIALIZACIÓN ====================
func set_main(m: Node):
	main = m

func reset():
	run_closed = false
	final_route = "NONE"
	final_reason = ""
	homeostasis_mode = false
	post_homeostasis = false
	resilience_score = 0.0
	homeostasis_timer = 0.0
	homeostasis_tier_reached = 0
	disturbances_survived = 0
	is_recovering_from_shock = false
	extreme_shock_survived = false
	legacy_homeostasis = false

# ==================== HELPERS ====================
func get_en_banda_homeostatica() -> bool:
	return StructuralModel.epsilon_effective >= 0.03 and StructuralModel.epsilon_effective <= 0.30

# ==================== CIERRE DE RUN ====================
func close_run(route: String, reason: String):
	if run_closed: return
	run_closed = true
	final_route = route
	final_reason = reason
	main.add_lap("🚩 RUN CERRADA: " + route)

	LegacyManager.last_run_ending = route
	LegacyManager.mark_ending_achieved(route) # Tracking persistente para gate de Trascendencia
	LegacyManager.save_legacy()

	var pl_to_add := 0
	match route:
		"HOMEOSTASIS": pl_to_add = 3
		"ALLOSTASIS": pl_to_add = 4
		"HOMEORHESIS": pl_to_add = 8
		"SIMBIOSIS": pl_to_add = 4
		# SINGULARIDAD: PL variable (6 + bonus épsilon) ya otorgado en main.gd antes de close_run()
		# No agregar aquí para evitar doble award
		"ESPORULACION", "ESPORULACIÓN", "ESPORULACION TOTAL": pl_to_add = 5
		"PARASITISMO": pl_to_add = 2
		"HIPERASIMILACION", "HIPERASIMILACIÓN": pl_to_add = 1
		"MUTACION_FINAL", "METABOLISMO OSCURO": pl_to_add = 4
		"MENTE COLMENA DISTRIBUIDA": pl_to_add = 8
		"DEPREDADOR DE REALIDADES": pl_to_add = 12
		"PANSPERMIA NEGRA": pl_to_add = 0 # PL ya otorgado explícitamente en main.gd
		"COLAPSO CONTROLADO": pl_to_add = 6 # Fractura Epistémica (Banco Cósmico T3)

	if pl_to_add > 0:
		LegacyManager.add_pl(pl_to_add)
		main.show_system_toast("LEGADO — Ganaste " + str(pl_to_add) + " PL por " + route)

	# Resetear estado de run ANTES de guardar para no heredar shocks/perturbaciones
	disturbances_survived = 0
	is_recovering_from_shock = false
	extreme_shock_survived = false
	homeostasis_tier_reached = 0

	SaveManager.save_game(main)

func enter_post_homeostasis():
	post_homeostasis = true
	main.add_lap("⚖️ Iniciando fase de Post-Homeostasis")

# ==================== CHEQUEOS FINALES ====================
# HOMEOSTASIS → ALLOSTASIS → HOMEORHESIS son tiers progresivos EN LA MISMA RUN.
# El jugador activa HOMEOSTASIS una sola vez y decide cuándo sellar el final.
# Cada tier desbloquea el botón de cierre correspondiente; cuanto más aguanta, mejor ending.

var homeostasis_tier_reached := 0  # 0=ninguno, 1=homeostasis, 2=allostasis, 3=homeorhesis

func check_homeostasis_final(delta: float):
	if run_closed or not EvoManager.mutation_homeostasis:
		if not EvoManager.mutation_homeostasis:
			homeostasis_timer = max(homeostasis_timer - delta * 2.0, 0.0)
		return

	var banda_estricta = get_en_banda_homeostatica()
	var flexibilidad_minima = StructuralModel.omega > 0.25
	var control_activo = UpgradeManager.level("accounting") >= 1
	var metabolismo_activo = main.delta_per_sec > 30.0
	var crecimiento_controlado = BiosphereEngine.biomasa < 12.0
	var redundancia = StructuralModel.unlocked_d and StructuralModel.unlocked_e

	if banda_estricta and flexibilidad_minima and control_activo and metabolismo_activo and crecimiento_controlado and redundancia:
		homeostasis_timer += delta
	else:
		if StructuralModel.epsilon_effective > 0.35:
			homeostasis_timer = 0.0
		else:
			homeostasis_timer = max(homeostasis_timer - delta, 0.0)

	# Tier 1: HOMEOSTASIS — 18s en banda
	if homeostasis_timer >= HOMEOSTASIS_TIME_REQUIRED and homeostasis_tier_reached < 1:
		homeostasis_tier_reached = 1
		post_homeostasis = true
		main.add_lap("⚖️ Tier 1 desbloqueado: HOMEOSTASIS — podés cerrar la run o seguir")
		main.show_system_toast("HOMEOSTASIS alcanzada — aguantá para evolucionar a ALLOSTASIS")

	# Tier 2: ALLOSTASIS — más perturbaciones, metabolismo mayor
	if homeostasis_tier_reached >= 1 and homeostasis_tier_reached < 2:
		var delta_real :float = EconomyManager.get_contribution_breakdown().total
		var ok = disturbances_survived >= 3 and StructuralModel.omega_min >= 0.40 \
			and resilience_score >= 150.0 and UpgradeManager.level("accounting") >= 2 \
			and delta_real > 200.0
		if ok:
			homeostasis_tier_reached = 2
			if not LegacyManager.unlocked_legacies.get("legado_alostasis", false):
				LegacyManager.unlocked_legacies["legado_alostasis"] = true
				LegacyManager.save_legacy()
			main.add_lap("💜 Tier 2 desbloqueado: ALLOSTASIS — podés cerrar o seguir por HOMEORHESIS")
			main.show_system_toast("ALLOSTASIS alcanzada — aguantá 30min + shock extremo para HOMEORHESIS")

	# Tier 3: HOMEORHESIS — shock extremo + larga duración
	if homeostasis_tier_reached >= 2 and homeostasis_tier_reached < 3:
		var delta_real :float = EconomyManager.get_contribution_breakdown().total
		var ok = extreme_shock_survived and resilience_score >= 400.0 \
			and StructuralModel.omega_min >= 0.50 and disturbances_survived >= 5 \
			and delta_real > 300.0 and main.run_time >= 1200.0
		if ok:
			homeostasis_tier_reached = 3
			if not LegacyManager.unlocked_legacies.get("legado_homeorresis", false):
				LegacyManager.unlocked_legacies["legado_homeorresis"] = true
				LegacyManager.save_legacy()
			main.add_lap("💎 Tier 3 desbloqueado: HOMEORHESIS — el sistema trasciende la regulación basal")
			main.show_system_toast("HOMEORHESIS alcanzada — cerrá la run para sellarlo")

	# Mostrar el botón del tier más alto alcanzado
	if homeostasis_tier_reached == 3:
		_show_evolution_button("HOMEORHESIS")
	elif homeostasis_tier_reached == 2:
		_show_evolution_button("ALLOSTASIS")
	elif homeostasis_tier_reached == 1:
		_show_evolution_button("HOMEOSTASIS")

func check_allostasis_final(_delta: float):
	pass # Integrado en check_homeostasis_final como tiers progresivos

func check_homeorhesis_final(_delta: float):
	pass # Integrado en check_homeostasis_final como tiers progresivos

func check_symbiosis_final(_delta: float):
	if run_closed or not EvoManager.mutation_symbiosis:
		return

	var stable_band: bool = (
		StructuralModel.epsilon_effective >= 0.12
		and StructuralModel.epsilon_effective <= 0.55
		and StructuralModel.omega > 0.30
		and UpgradeManager.level("accounting") >= 1
	)

	# Auto-cierre: 5 minutos en banda estable (antes 15 min)
	if stable_band and main.run_time > 300.0:
		close_run("SIMBIOSIS", "Cooperación sostenida entre estructura y biología")
		return

	# Cierre de emergencia: si omega > 0.50 (rama Simbiosis Mecánica activa) por 60s
	if EvoManager.red_branch_selected == EvoManager.RedBranch.SYMBIOSIS \
		and StructuralModel.omega >= 0.50 \
		and main.run_time > 60.0:
		close_run("SIMBIOSIS", "Simbiosis Mecánica consolidada — hardware y biología unificados")

func check_fractura_epistemica(_delta: float):
	# FRACTURA EPISTÉMICA (Banco Cósmico T3): nueva ruta de cierre
	if run_closed or not LegacyManager.has_cosmic_buff("fractura_epistemica"):
		return
	# Condición: ε_effective > 0.90 Y Ω > 0.30 (colapso controlado)
	if StructuralModel.epsilon_effective > 0.90 and StructuralModel.omega > 0.30:
		close_run("COLAPSO CONTROLADO", "El sistema absorbió su propio colapso. La fractura epistémica fue superada.")

func check_parasitism_final(_delta: float):
	if run_closed or not EvoManager.mutation_parasitism:
		return

	# Opción A: Colapso estructural clásico
	if BiosphereEngine.biomasa > 18.0 and StructuralModel.omega < 0.22 and StructuralModel.epsilon_effective > 0.45:
		close_run("PARASITISMO", "La biosfera drenó la estructura hasta el colapso")
		return

	# Opción B: Bancarrota — el hongo drenó toda la liquidez
	if BiosphereEngine.biomasa >= 15.0 and EconomyManager.money < 1000.0:
		close_run("PARASITISMO", "Bancarrota Biológica: el hongo drenó toda la liquidez del sistema")
		return

	# Opción C: Masa crítica — crecimiento descontrolado
	if BiosphereEngine.biomasa >= 25.0:
		close_run("PARASITISMO", "Colapso por Masa Crítica: la biosfera reemplazó la infraestructura")

func check_sporulation_trigger(_delta: float):
	if run_closed or EvoManager.mutation_sporulation:
		return

	if not EvoManager.mutation_red_micelial or EvoManager.red_micelial_phase != 2:
		return
	if EvoManager.mutation_homeostasis or EvoManager.mutation_hyperassimilation:
		return

	var _structural_pressure: float = main.get_structural_pressure()

	if (
		StructuralModel.epsilon_peak >= 0.75
		and StructuralModel.epsilon_effective <= 0.35
		and StructuralModel.omega <= 0.30
		and BiosphereEngine.biomasa >= 10.0
		and BiosphereEngine.hifas >= 12.0
		and main.run_time >= 900.0
	):
		main.activate_sporulation()

# ==================== HOMEOSTASIS DINÁMICA ====================
func update_homeostasis_mode(delta: float):
	var n_struct: float = main.get_effective_structural_n()
	var complexity_impact: float = n_struct / max(main.cached_mu, 1.0)
	StructuralModel.omega = 1.0 / max(1.0 + StructuralModel.epsilon_effective * complexity_impact, 0.0001)
	var stability: float = clamp(1.0 - StructuralModel.epsilon_effective, 0.0, 1.0)
	resilience_score += stability * delta

	disturbance_timer += delta
	if disturbance_timer >= DISTURBANCE_INTERVAL:
		disturbance_timer = 0.0
		trigger_disturbance()

	StructuralModel.epsilon_runtime = lerp(
		StructuralModel.epsilon_runtime,
		StructuralModel.epsilon_effective,
		0.05 * delta
	)

func trigger_disturbance():
	var shock := randf_range(0.1, 0.4)
	var is_extreme := false
	# Shock extremo disponible una vez alcanzado Tier 2 (ALLOSTASIS) en la run actual
	if homeostasis_tier_reached >= 2 and randf() < 0.2:
		shock = randf_range(0.8, 1.0)
		is_extreme = true
		main.add_lap("🌋 SHOCK EXTREMO DETECTADO — ε +" + str(snapped(shock, 0.01)))
	else:
		main.add_lap("🌪️ Perturbación externa — shock ε +" + str(snapped(shock, 0.01)))

	StructuralModel.epsilon_runtime += shock
	is_recovering_from_shock = true

	# Shocks extremos tienen consecuencias: drenan omega_min y dinero
	if is_extreme:
		var penalty_omega := 0.15 if not LegacyManager.get_buff_value("legado_homeorresis") else 0.05
		StructuralModel.omega_min = max(0.0, StructuralModel.omega_min - penalty_omega)
		var money_drain := EconomyManager.money * 0.20
		EconomyManager.money = max(0.0, EconomyManager.money - money_drain)
		main.add_lap("💸 Shock drenó Ω_min (-%s) y $%.0f" % [snapped(penalty_omega, 0.01), money_drain])

func check_perfect_homeostasis():
	if not post_homeostasis or AchievementManager.achievement_homeostasis_perfect:
		return

	if resilience_score >= 300.0:
		AchievementManager.achievement_homeostasis_perfect = true
		main.add_lap("🏆 LOGRO — HOMEOSTASIS PERFECTA")
		main.show_system_toast("LOGRO — HOMEOSTASIS PERFECTA: resiliencia máxima")
		legacy_homeostasis = true
		post_homeostasis = false

# ==================== UI EVOLUCIÓN ====================
func _show_evolution_button(target: String):
	if target_evolution == target:
		return
	target_evolution = target

	if not is_instance_valid(evolution_button):
		evolution_button = Button.new()
		evolution_button.add_theme_font_size_override("font_size", 22)
		evolution_button.custom_minimum_size = Vector2(0, 80)
		evolution_button.pressed.connect(_on_evolution_button_pressed)
		main.get_node("UIRootContainer/RightPanel").add_child(evolution_button)
		main.get_node("UIRootContainer/RightPanel").move_child(evolution_button, 0)

	evolution_button.text = "🧬 SELLAR FINAL (" + target + ")"
	match target:
		"HOMEOSTASIS":
			evolution_button.add_theme_color_override("font_color", Color.CYAN)
		"ALLOSTASIS":
			evolution_button.add_theme_color_override("font_color", Color.AQUAMARINE)
		"HOMEORHESIS":
			evolution_button.add_theme_color_override("font_color", Color.GOLD)
	evolution_button.visible = true

func _on_evolution_button_pressed():
	match target_evolution:
		"HOMEOSTASIS":
			close_run("HOMEOSTASIS", "Estabilidad estructural sostenida en banda homeostática")
		"ALLOSTASIS":
			UIManager.big_click_button.modulate = Color(0.2, 0.9, 1.0)
			close_run("ALLOSTASIS", "El sistema aprendió a tolerar el cambio calibrando un nuevo setpoint")
		"HOMEORHESIS":
			UIManager.big_click_button.modulate = Color(1.0, 0.8, 0.2)
			close_run("HOMEORHESIS", "Evolución irreversible: el metabolismo trasciende la regulación basal")
	evolution_button.visible = false
