extends Node

# SaveManager.gd — Autoload
# Maneja la persistencia del estado del juego en formato JSON.

const SAVE_PATH := "user://savegame.json"

# Flag para detectar si se cargó un save existente (vs run nueva sin archivo).
# Usado por _apply_cosmic_buffs para no duplicar bonuses al recargar.
var _file_existed_on_load: bool = false

func build_save_data(main: Node) -> Dictionary:
	return {
		"economy": {
			"money": EconomyManager.money,
			"persistence_dynamic": StructuralModel.persistence_dynamic,
			"persistence_base": StructuralModel.persistence_base,
			"persistence_upgrade_unlocked": StructuralModel.persistence_upgrade_unlocked,
			"memory_trigger_count": main.memory_trigger_count,
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
			"epsilon_runtime": StructuralModel.epsilon_runtime,
			"epsilon_peak": StructuralModel.epsilon_peak,
			"total_money_generated": EconomyManager.total_money_generated,
			"run_time": main.run_time,
			"baseline_delta_structural": StructuralModel.baseline_delta_structural,
			"omega": StructuralModel.omega,
			"omega_min": StructuralModel.omega_min,
			"institution_accounting_unlocked": StructuralModel.institution_accounting_unlocked,
			"institutions_unlocked": main.institutions_unlocked
		},
		"flags": {
			"unlocked_d": StructuralModel.unlocked_d,
			"unlocked_md": StructuralModel.unlocked_md,
			"unlocked_e": StructuralModel.unlocked_e,
			"unlocked_me": StructuralModel.unlocked_me,
			# Logros viven ahora en legacy_bank.json (AchievementManager).
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
			"mutation_depredador": EvoManager.mutation_depredador,
			"mutation_met_oscuro": EvoManager.mutation_met_oscuro,
			"depredador_timer": EvoManager.depredador_timer,
			"met_oscuro_timer": EvoManager.met_oscuro_timer,
			"met_oscuro_devoured_count": EvoManager.met_oscuro_devoured_count,
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
			"legacy_homeostasis": RunManager.legacy_homeostasis,
			"disturbances_survived": RunManager.disturbances_survived,
			"extreme_shock_survived": RunManager.extreme_shock_survived,
			"homeostasis_tier_reached": RunManager.homeostasis_tier_reached,
			"omega_min_peak": RunManager.omega_min_peak
		},
		"laps": LogManager.get_lap_array()
	}

func save_game(main: Node):
	var data = build_save_data(main)
	var json_string = JSON.stringify(data)
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("💾 [SaveManager] Juego guardado en:", SAVE_PATH)

func apply_save_data(main: Node, data: Dictionary) -> void:
	if data.has("upgrades"):
		UpgradeManager.deserialize(data.upgrades)

	if data.has("economy"):
		var e = data.economy
		EconomyManager.money = e.get("money", EconomyManager.money)
		StructuralModel.persistence_dynamic = e.get("persistence_dynamic", StructuralModel.persistence_dynamic)
		StructuralModel.persistence_base = e.get("persistence_base", StructuralModel.persistence_base)
		StructuralModel.persistence_upgrade_unlocked = e.get("persistence_upgrade_unlocked", StructuralModel.persistence_upgrade_unlocked)
		main.memory_trigger_count = e.get("memory_trigger_count", main.memory_trigger_count)
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
		StructuralModel.epsilon_runtime = s.get("epsilon_runtime", StructuralModel.epsilon_runtime)
		StructuralModel.epsilon_peak = s.get("epsilon_peak", StructuralModel.epsilon_peak)
		EconomyManager.total_money_generated = s.get("total_money_generated", EconomyManager.total_money_generated)
		main.run_time = s.get("run_time", main.run_time)
		StructuralModel.baseline_delta_structural = s.get("baseline_delta_structural", StructuralModel.baseline_delta_structural)
		StructuralModel.omega = s.get("omega", StructuralModel.omega)
		StructuralModel.omega_min = s.get("omega_min", StructuralModel.omega_min)
		StructuralModel.institution_accounting_unlocked = s.get("institution_accounting_unlocked", StructuralModel.institution_accounting_unlocked)
		main.institutions_unlocked = s.get("institutions_unlocked", main.institutions_unlocked)

	if data.has("flags"):
		var f = data.flags
		StructuralModel.unlocked_d = f.get("unlocked_d", StructuralModel.unlocked_d)
		StructuralModel.unlocked_md = f.get("unlocked_md", StructuralModel.unlocked_md)
		StructuralModel.unlocked_e = f.get("unlocked_e", StructuralModel.unlocked_e)
		StructuralModel.unlocked_me = f.get("unlocked_me", StructuralModel.unlocked_me)
		RunManager.run_closed = f.get("run_closed", RunManager.run_closed)
		RunManager.final_route = f.get("final_route", RunManager.final_route)
		RunManager.final_reason = f.get("final_reason", RunManager.final_reason)
		# MIGRACIÓN v0.9.3: importar logros viejos del savegame al nuevo sistema.
		# Si f tiene flags legacy (unlocked_tree, achievement_*), los pasamos al AchievementManager.
		var has_legacy_flags :bool = f.has("unlocked_tree") or f.has("achievement_millionaire")
		var old_achievements: Dictionary = data.get("achievements", {})
		if has_legacy_flags or not old_achievements.is_empty():
			AchievementManager.migrate_from_legacy_save(f, old_achievements)

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
		EvoManager.mutation_depredador = ev.get("mutation_depredador", EvoManager.mutation_depredador)
		EvoManager.mutation_met_oscuro = ev.get("mutation_met_oscuro", EvoManager.mutation_met_oscuro)
		EvoManager.depredador_timer = ev.get("depredador_timer", EvoManager.depredador_timer)
		EvoManager.met_oscuro_timer = ev.get("met_oscuro_timer", EvoManager.met_oscuro_timer)
		EvoManager.met_oscuro_devoured_count = ev.get("met_oscuro_devoured_count", EvoManager.met_oscuro_devoured_count)
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
		RunManager.disturbances_survived = h.get("disturbances_survived", RunManager.disturbances_survived)
		RunManager.extreme_shock_survived = h.get("extreme_shock_survived", RunManager.extreme_shock_survived)
		RunManager.homeostasis_tier_reached = h.get("homeostasis_tier_reached", RunManager.homeostasis_tier_reached)
		RunManager.omega_min_peak = h.get("omega_min_peak", RunManager.omega_min_peak)

	# Los logros ahora viven en legacy_bank.json y se cargan desde LegacyManager.load_legacy().
	# Si el save viejo tenía data["achievements"], ya se migró en el bloque de flags de arriba.

	# Bitácora de eventos
	if data.has("laps"):
		LogManager.load_laps(data["laps"])

	# Migración
	if not RunManager.run_closed and (EvoManager.mutation_hyperassimilation or EvoManager.mutation_sporulation):
		RunManager.run_closed = true
		RunManager.final_route = RunManager.final_route if RunManager.final_route != "" else "MUTACION_FINAL"

	main.update_ui()

func load_game(main: Node):
	if not FileAccess.file_exists(SAVE_PATH):
		print("ℹ️ [SaveManager] No se encontró archivo de guardado.")
		_file_existed_on_load = false
		return
	_file_existed_on_load = true

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		print("❌ [SaveManager] Error al parsear el guardado:", json.get_error_message())
		return

	var data = json.data
	apply_save_data(main, data)
	print("📂 [SaveManager] Juego cargado con éxito.")

func delete_save_and_restart():
	# Incrementar contador de ciclos persistentes antes de borrar la run actual
	LegacyManager.increment_run()
	
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("🗑️ [SaveManager] Archivo de run eliminado. Iniciando nuevo ciclo.")
	
	# Resetear Autoloads persistentes (solo los de la sesión actual)
	UpgradeManager.reset()
	BiosphereEngine.reset()
	EvoManager.reset()
	LogManager.reset()

	# Si hay una instancia de main, forzar su reset local
	var main = get_tree().get_first_node_in_group("main")
	if main:
		# Detener timers para evitar autosaves parásitos
		if main.get("_logic_timer"): main._logic_timer.stop()
		if main.get("_autosave_timer"): main._autosave_timer.stop()
		
		if main.has_method("reset_local_state"):
			main.reset_local_state()
	
	get_tree().reload_current_scene()
