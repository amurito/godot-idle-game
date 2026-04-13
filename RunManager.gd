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
	disturbances_survived = 0
	is_recovering_from_shock = false
	extreme_shock_survived = false
	legacy_homeostasis = false

# ==================== HELPERS ====================
func get_en_banda_homeostatica() -> bool:
	return main.epsilon_effective >= 0.03 and main.epsilon_effective <= 0.30

# ==================== CIERRE DE RUN ====================
func close_run(route: String, reason: String):
	if run_closed: return
	run_closed = true
	final_route = route
	final_reason = reason
	main.add_lap("🚩 RUN CERRADA: " + route)

	LegacyManager.last_run_ending = route
	LegacyManager.save_legacy()

	var pl_to_add := 0
	match route:
		"HOMEOSTASIS": pl_to_add = 3
		"ALLOSTASIS": pl_to_add = 4
		"HOMEORHESIS": pl_to_add = 6
		"SIMBIOSIS", "SINGULARIDAD": pl_to_add = 4
		"ESPORULACION", "ESPORULACION TOTAL": pl_to_add = 5
		"PARASITISMO": pl_to_add = 2
		"HIPERASIMILACION": pl_to_add = 1
		"MUTACION_FINAL", "METABOLISMO OSCURO": pl_to_add = 4
		"MENTE COLMENA DISTRIBUIDA": pl_to_add = 8
		"DEPREDADOR DE REALIDADES": pl_to_add = 12

	if pl_to_add > 0:
		LegacyManager.add_pl(pl_to_add)
		main.show_system_toast("LEGADO — Ganaste " + str(pl_to_add) + " PL por " + route)

	SaveManager.save_game(main)

func enter_post_homeostasis():
	post_homeostasis = true
	main.add_lap("⚖️ Iniciando fase de Post-Homeostasis")

# ==================== CHEQUEOS FINALES ====================
func check_homeostasis_final(delta: float):
	if run_closed or LegacyManager.last_run_ending == "HOMEOSTASIS":
		return

	if not EvoManager.mutation_homeostasis:
		homeostasis_timer = max(homeostasis_timer - delta * 2.0, 0.0)
		return

	var banda_estricta = get_en_banda_homeostatica()
	var flexibilidad_minima = main.omega > 0.25
	var control_activo = UpgradeManager.level("accounting") >= 1
	var metabolismo_activo = main.delta_per_sec > 30.0
	var crecimiento_controlado = BiosphereEngine.biomasa < 12.0
	var redundancia = main.unlocked_d and main.unlocked_e

	if banda_estricta and flexibilidad_minima and control_activo and metabolismo_activo and crecimiento_controlado and redundancia:
		homeostasis_timer += delta
	else:
		if main.epsilon_effective > 0.35:
			homeostasis_timer = 0.0
		else:
			homeostasis_timer = max(homeostasis_timer - delta, 0.0)

	if homeostasis_timer >= HOMEOSTASIS_TIME_REQUIRED:
		close_run("HOMEOSTASIS", "Estabilidad estructural sostenida en banda homeostática")
		enter_post_homeostasis()

func check_allostasis_final(_delta: float):
	if run_closed or LegacyManager.last_run_ending != "HOMEOSTASIS":
		return

	if not get_en_banda_homeostatica() and main.epsilon_effective > 0.45:
		return

	if disturbances_survived >= 3 and main.omega_min >= 0.40 and resilience_score >= 150.0 and UpgradeManager.level("accounting") >= 2 and main.delta_per_sec > 200.0:
		_show_evolution_button("ALLOSTASIS")

func check_homeorhesis_final(_delta: float):
	if run_closed or LegacyManager.last_run_ending != "ALLOSTASIS":
		return

	if extreme_shock_survived and resilience_score >= 400.0 and main.omega_min >= 0.55 and BiosphereEngine.hifas >= 15.0 and main.run_time >= 1800.0:
		_show_evolution_button("HOMEORHESIS")

func check_symbiosis_final(_delta: float):
	if run_closed or not EvoManager.mutation_symbiosis:
		return

	var stable_band := (
		main.epsilon_effective >= 0.12
		and main.epsilon_effective <= 0.45
		and main.omega > 0.35
		and UpgradeManager.level("accounting") >= 1
	)

	if stable_band and main.run_time > 900.0:
		close_run("SIMBIOSIS", "Cooperación sostenida entre estructura y biología")

func check_parasitism_final(_delta: float):
	if run_closed or not EvoManager.mutation_parasitism:
		return

	if BiosphereEngine.biomasa > 18.0 and main.omega < 0.22 and main.epsilon_effective > 0.45:
		close_run("PARASITISMO", "La biosfera drenó la estructura hasta el colapso")

func check_sporulation_trigger(_delta: float):
	if run_closed or EvoManager.mutation_sporulation:
		return

	if not EvoManager.mutation_red_micelial or EvoManager.red_micelial_phase != 2:
		return
	if EvoManager.mutation_homeostasis or EvoManager.mutation_hyperassimilation:
		return

	var _structural_pressure := main.get_structural_pressure()

	if (
		main.epsilon_peak >= 0.75
		and main.epsilon_effective <= 0.35
		and main.omega <= 0.30
		and BiosphereEngine.biomasa >= 10.0
		and BiosphereEngine.hifas >= 12.0
		and main.run_time >= 900.0
	):
		main.activate_sporulation()

# ==================== HOMEOSTASIS DINÁMICA ====================
func update_homeostasis_mode(delta: float):
	var n_struct := main.get_effective_structural_n()
	var complexity_impact: float = n_struct / max(main.cached_mu, 1.0)
	main.omega = 1.0 / max(1.0 + main.epsilon_effective * complexity_impact, 0.0001)
	var stability: float = clamp(1.0 - main.epsilon_effective, 0.0, 1.0)
	resilience_score += stability * delta

	disturbance_timer += delta
	if disturbance_timer >= DISTURBANCE_INTERVAL:
		disturbance_timer = 0.0
		trigger_disturbance()

	main.epsilon_runtime = lerp(
		main.epsilon_runtime,
		main.epsilon_effective,
		0.05 * delta
	)

func trigger_disturbance():
	var shock := randf_range(0.1, 0.4)
	if LegacyManager.last_run_ending == "ALLOSTASIS" and randf() < 0.2:
		shock = randf_range(0.8, 1.0)
		main.add_lap("🌋 SHOCK EXTREMO DETECTADO — ε +" + str(snapped(shock, 0.01)))
	else:
		main.add_lap("🌪️ Perturbación externa — shock ε +" + str(snapped(shock, 0.01)))

	main.epsilon_runtime += shock
	is_recovering_from_shock = true

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

	evolution_button.text = "🧬 TRASCENDER GENOMA (" + target + ")"
	if target == "ALLOSTASIS":
		evolution_button.add_theme_color_override("font_color", Color.AQUAMARINE)
	else:
		evolution_button.add_theme_color_override("font_color", Color.GOLD)
	evolution_button.visible = true

func _on_evolution_button_pressed():
	if target_evolution == "ALLOSTASIS":
		UIManager.big_click_button.modulate = Color(0.2, 0.9, 1.0)
		LegacyManager.unlocked_legacies["legado_alostasis"] = true
		close_run("ALLOSTASIS", "El sistema aprendió a tolerar el cambio calibrando un nuevo setpoint")
	elif target_evolution == "HOMEORHESIS":
		UIManager.big_click_button.modulate = Color(1.0, 0.8, 0.2)
		LegacyManager.unlocked_legacies["legado_homeorresis"] = true
		close_run("HOMEORHESIS", "Evolución irreversible: el metabolismo trasciende la regulación basal")
	evolution_button.visible = false
