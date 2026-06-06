extends Node

# SaveManager.gd — Autoload
# Maneja la persistencia del estado del juego en formato JSON.
# El path del savegame depende del slot activo de SlotManager:
# user://saves/{active_slot}/savegame.json

# SAVE_PATH se mantiene como propiedad dinámica para retrocompat con consumidores
# que la leen como SaveManager.SAVE_PATH (MainMenu, TestRunner, etc.)
var SAVE_PATH: String:
	get:
		return SlotManager.get_active_save_path()

# Flag para detectar si se cargó un save existente (vs run nueva sin archivo).
# Usado por _apply_cosmic_buffs para no duplicar bonuses al recargar.
var _file_existed_on_load: bool = false

func build_save_data(main: Node) -> Dictionary:
	var all_laps := LogManager.get_lap_array()
	var laps_to_save := all_laps.slice(max(0, all_laps.size() - Balance.MAX_LAPS))
	return {
		"save_version": Version.get_version_string(),
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
			"run_time": RunManager.run_time,
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
			"mutation_allostasis": EvoManager.mutation_allostasis,
			"mutation_homeorhesis": EvoManager.mutation_homeorhesis,
			"mutation_depredador": EvoManager.mutation_depredador,
			"mutation_met_oscuro": EvoManager.mutation_met_oscuro,
			"depredador_timer": EvoManager.depredador_timer,
			"depredador_inestabilidad": EvoManager.depredador_inestabilidad,
			"depredador_timer_buys": EvoManager.depredador_timer_buys,
			"met_oscuro_timer": EvoManager.met_oscuro_timer,
			"met_oscuro_devoured_count": EvoManager.met_oscuro_devoured_count,
			"red_micelial_phase": EvoManager.red_micelial_phase,
			"red_branch_selected": EvoManager.red_branch_selected,
			"seta_formada": EvoManager.seta_formada,
			"primordio_active": EvoManager.primordio_active,
			"primordio_timer": EvoManager.primordio_timer,
			"primordio_abort_count": EvoManager.primordio_abort_count,
			"colonizacion_pert_timer": EvoManager.colonizacion_pert_timer,
			"colonizacion_phase_time": EvoManager.colonizacion_phase_time,
			"panspermia_charge": EvoManager.panspermia_charge,
			"panspermia_heat": EvoManager.panspermia_heat,
			"panspermia_misfires": EvoManager.panspermia_misfires,
			"nucleo_sync": EvoManager.nucleo_sync,
			"nucleo_temp": EvoManager.nucleo_temp,
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
			"is_recovering_from_extreme": RunManager.is_recovering_from_extreme,
			"extreme_shocks_recovered": RunManager.extreme_shocks_recovered,
			"homeostasis_tier_reached": RunManager.homeostasis_tier_reached,
			"omega_min_peak": RunManager.omega_min_peak
		},
		"post_tras": {
			"vacio_hambriento_active": RunManager.vacio_hambriento_active,
			"vacio_hambriento_mult": RunManager.vacio_hambriento_mult,
			"ascesis_timer": RunManager.ascesis_timer,
			"carnaval_active": RunManager.carnaval_active,
			"carnaval_mutations": RunManager.carnaval_mutations,
			"carnaval_index": RunManager.carnaval_index,
			"carnaval_timer": RunManager.carnaval_timer,
			"carnaval_total_rotations": RunManager.carnaval_total_rotations,
			"carnaval_peak_money": RunManager.carnaval_peak_money,
			"reencarnacion_active": RunManager.reencarnacion_active
		},
		"laps": laps_to_save
	}

func save_game(main: Node):
	var data := build_save_data(main)
	var json_string := JSON.stringify(data)
	var tmp_path := SAVE_PATH + ".tmp"
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if not f:
		push_error("[SaveManager] No se pudo abrir archivo temporal para guardar.")
		return
	f.store_string(json_string)
	f.close()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(SAVE_PATH, SAVE_PATH + ".bak")
	var err := DirAccess.rename_absolute(tmp_path, SAVE_PATH)
	if err != OK:
		push_error("[SaveManager] rename .tmp → .json falló: " + str(err))
		return
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
		RunManager.run_time = s.get("run_time", RunManager.run_time)
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

	if data.has("evolution"):
		var ev = data.evolution
		EvoManager.genome = ev.get("genome", EvoManager.genome)
		EvoManager.mutation_homeostasis = ev.get("mutation_homeostasis", EvoManager.mutation_homeostasis)
		EvoManager.mutation_hyperassimilation = ev.get("mutation_hyperassimilation", EvoManager.mutation_hyperassimilation)
		EvoManager.mutation_symbiosis = ev.get("mutation_symbiosis", EvoManager.mutation_symbiosis)
		EvoManager.mutation_red_micelial = ev.get("mutation_red_micelial", EvoManager.mutation_red_micelial)
		EvoManager.mutation_sporulation = ev.get("mutation_sporulation", EvoManager.mutation_sporulation)
		EvoManager.mutation_parasitism = ev.get("mutation_parasitism", EvoManager.mutation_parasitism)
		EvoManager.mutation_allostasis = ev.get("mutation_allostasis", EvoManager.mutation_allostasis)
		EvoManager.mutation_homeorhesis = ev.get("mutation_homeorhesis", EvoManager.mutation_homeorhesis)
		EvoManager.mutation_depredador = ev.get("mutation_depredador", EvoManager.mutation_depredador)
		EvoManager.mutation_met_oscuro = ev.get("mutation_met_oscuro", EvoManager.mutation_met_oscuro)
		EvoManager.depredador_timer = ev.get("depredador_timer", EvoManager.depredador_timer)
		EvoManager.depredador_inestabilidad = ev.get("depredador_inestabilidad", EvoManager.depredador_inestabilidad)
		EvoManager.depredador_timer_buys = int(ev.get("depredador_timer_buys", EvoManager.depredador_timer_buys))
		EvoManager.met_oscuro_timer = ev.get("met_oscuro_timer", EvoManager.met_oscuro_timer)
		EvoManager.met_oscuro_devoured_count = ev.get("met_oscuro_devoured_count", EvoManager.met_oscuro_devoured_count)
		EvoManager.red_micelial_phase = ev.get("red_micelial_phase", EvoManager.red_micelial_phase)
		EvoManager.red_branch_selected = ev.get("red_branch_selected", EvoManager.red_branch_selected)
		EvoManager.seta_formada = ev.get("seta_formada", EvoManager.seta_formada)
		EvoManager.primordio_active = ev.get("primordio_active", EvoManager.primordio_active)
		EvoManager.primordio_timer = ev.get("primordio_timer", EvoManager.primordio_timer)
		EvoManager.primordio_abort_count = ev.get("primordio_abort_count", EvoManager.primordio_abort_count)
		EvoManager.colonizacion_pert_timer = ev.get("colonizacion_pert_timer", EvoManager.colonizacion_pert_timer)
		EvoManager.colonizacion_phase_time = ev.get("colonizacion_phase_time", EvoManager.colonizacion_phase_time)
		EvoManager.panspermia_charge = ev.get("panspermia_charge", EvoManager.panspermia_charge)
		EvoManager.panspermia_heat = ev.get("panspermia_heat", EvoManager.panspermia_heat)
		EvoManager.panspermia_misfires = ev.get("panspermia_misfires", EvoManager.panspermia_misfires)
		EvoManager.nucleo_sync = ev.get("nucleo_sync", EvoManager.nucleo_sync)
		EvoManager.nucleo_temp = ev.get("nucleo_temp", EvoManager.nucleo_temp)

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
		RunManager.is_recovering_from_extreme = h.get("is_recovering_from_extreme", RunManager.is_recovering_from_extreme)
		RunManager.extreme_shocks_recovered = h.get("extreme_shocks_recovered", RunManager.extreme_shocks_recovered)
		RunManager.homeostasis_tier_reached = h.get("homeostasis_tier_reached", RunManager.homeostasis_tier_reached)
		RunManager.omega_min_peak = h.get("omega_min_peak", RunManager.omega_min_peak)

	if data.has("post_tras"):
		var pt = data.post_tras
		RunManager.vacio_hambriento_active = pt.get("vacio_hambriento_active", RunManager.vacio_hambriento_active)
		RunManager.vacio_hambriento_mult = pt.get("vacio_hambriento_mult", RunManager.vacio_hambriento_mult)
		RunManager.ascesis_timer = pt.get("ascesis_timer", RunManager.ascesis_timer)
		RunManager.carnaval_active = pt.get("carnaval_active", RunManager.carnaval_active)
		RunManager.carnaval_mutations = pt.get("carnaval_mutations", RunManager.carnaval_mutations)
		RunManager.carnaval_index = pt.get("carnaval_index", RunManager.carnaval_index)
		RunManager.carnaval_timer = pt.get("carnaval_timer", RunManager.carnaval_timer)
		RunManager.carnaval_total_rotations = pt.get("carnaval_total_rotations", RunManager.carnaval_total_rotations)
		RunManager.carnaval_peak_money = pt.get("carnaval_peak_money", RunManager.carnaval_peak_money)
		RunManager.reencarnacion_active = pt.get("reencarnacion_active", RunManager.reencarnacion_active)
		# Re-aplicar mutación activa del carnaval luego de cargar índice+lista
		if RunManager.carnaval_active and not RunManager.carnaval_mutations.is_empty():
			EvoManager.carnaval_set_mutation(RunManager.carnaval_mutations[RunManager.carnaval_index])

	# Bitácora de eventos
	if data.has("laps"):
		LogManager.load_laps(data["laps"])

	main.update_ui()

## Aplica migraciones de formato a data antes de deserializar.
## Cada migración es idempotente: si el campo ya existe, no lo toca.
func _migrate(data: Dictionary) -> Dictionary:
	# v0.9.3 — logros viejos embebidos en flags/achievements → AchievementManager
	var flags: Dictionary = data.get("flags", {})
	var old_achievements: Dictionary = data.get("achievements", {})
	if flags.has("unlocked_tree") or flags.has("achievement_millionaire") or not old_achievements.is_empty():
		AchievementManager.migrate_from_legacy_save(flags, old_achievements)

	# v0.9.x — genome anterior sin claves NG+ → rellena con "dormido"
	var ev: Dictionary = data.get("evolution", {})
	var genome: Dictionary = ev.get("genome", {})
	for key in ["allostasis", "homeorhesis", "depredador"]:
		if not genome.has(key):
			genome[key] = "dormido"
	if not genome.is_empty():
		ev["genome"] = genome
		data["evolution"] = ev

	# v0.9.x — saves con mutaciones finales activas sin run_closed
	if flags.has("run_closed") and not flags["run_closed"]:
		var hyper: bool = data.get("evolution", {}).get("mutation_hyperassimilation", false)
		var spor: bool = data.get("evolution", {}).get("mutation_sporulation", false)
		if hyper or spor:
			flags["run_closed"] = true
			if flags.get("final_route", "") == "":
				flags["final_route"] = "MUTACION_FINAL"
			data["flags"] = flags

	return data

func load_game(main: Node):
	var path := SAVE_PATH
	if not FileAccess.file_exists(path):
		print("ℹ️ [SaveManager] No se encontró archivo de guardado en:", path)
		_file_existed_on_load = false
		# Slot sin savegame: resetear todos los managers para no heredar estado del slot anterior.
		_reset_for_new_slot(main)
		return
	_file_existed_on_load = true

	var data = _try_load_json(SAVE_PATH)
	if data == null:
		print("⚠️ [SaveManager] Save corrupto o vacío — intentando restaurar desde .bak")
		data = _try_load_json(SAVE_PATH + ".bak")
	if data == null:
		print("❌ [SaveManager] No se pudo cargar ni el save ni el backup. Iniciando run limpia.")
		return

	data = _migrate(data)
	apply_save_data(main, data)
	print("📂 [SaveManager] Juego cargado con éxito.")

## Resetea todos los managers de runtime al estado inicial cuando un slot no tiene savegame.
## Evita que el slot nuevo herede el estado en memoria del slot anterior.
func _reset_for_new_slot(main: Node) -> void:
	RunManager.reset()
	EvoManager.reset()
	BiosphereEngine.reset()
	UpgradeManager.reset()
	LogManager.reset()
	AchievementManager.reset_run_state()
	main.reset_local_state()
	print("🆕 [SaveManager] Estado reseteado para slot sin savegame.")

func _try_load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return null
	var text := f.get_as_text()
	f.close()
	if text.strip_edges().is_empty():
		return null
	var json := JSON.new()
	if json.parse(text) != OK:
		return null
	if not json.data is Dictionary:
		return null
	return json.data

func delete_save_and_restart():
	# Incrementar contador de ciclos persistentes antes de borrar la run actual
	LegacyManager.increment_run()

	var path := SAVE_PATH
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("🗑️ [SaveManager] Archivo de run eliminado. Iniciando nuevo ciclo.")
	
	# Resetear Autoloads persistentes (solo los de la sesión actual)
	UpgradeManager.reset()
	BiosphereEngine.reset()
	EvoManager.reset()
	LogManager.reset()
	RunManager.reset()
	AchievementManager.reset_run_state()

	# Si hay una instancia de main, forzar su reset local
	var main = get_tree().get_first_node_in_group("main")
	if main:
		# Detener timers para evitar autosaves parásitos
		if main.get("_logic_timer"): main._logic_timer.stop()
		if main.get("_autosave_timer"): main._autosave_timer.stop()
		
		if main.has_method("reset_local_state"):
			main.reset_local_state()

	get_tree().reload_current_scene()


## Muestra un ConfirmationDialog antes de borrar el slot activo.
## Mantiene Legacy y Trascendencia — solo borra la run actual.
func confirm_and_reset(parent: Node) -> void:
	var dlg := ConfirmationDialog.new()
	if RunManager.run_closed:
		dlg.title = tr("DLG_NEW_RUN_TITLE")
		dlg.dialog_text = tr("DLG_NEW_RUN_TEXT")
		dlg.ok_button_text = tr("DLG_NEW_RUN_OK")
	else:
		dlg.title = tr("DLG_RESET_TITLE")
		dlg.dialog_text = tr("DLG_RESET_TEXT")
		dlg.ok_button_text = tr("DLG_RESET_OK")
	dlg.get_cancel_button().text = tr("MM_CANCEL")
	parent.add_child(dlg)
	dlg.confirmed.connect(func():
		dlg.queue_free()
		delete_save_and_restart())
	dlg.canceled.connect(func():
		dlg.queue_free())
	dlg.popup_centered()


## Exporta el save actual como JSON descargable.
## Incluye tanto los datos de run (savegame) como el legacy (banco genético + trascendencias).
## Formato: { "run": {...}, "legacy": {...} }
## Web: usa JavaScriptBridge para forzar descarga. Desktop: escribe en user:// y abre carpeta.
## main_node puede ser null — en ese caso lee los archivos de disco directamente.
func export_save_json(main_node: Node) -> void:
	# ── Datos de run ────────────────────────────────────────
	var run_dict: Dictionary = {}
	if main_node != null:
		run_dict = build_save_data(main_node)
	else:
		var path: String = SAVE_PATH
		if FileAccess.file_exists(path):
			var file := FileAccess.open(path, FileAccess.READ)
			if file:
				var json := JSON.new()
				if json.parse(file.get_as_text()) == OK:
					run_dict = json.data
				file.close()

	# ── Datos de legacy ──────────────────────────────────────
	var legacy_dict: Dictionary = LegacyManager.get_save_dict()

	if run_dict.is_empty() and legacy_dict.is_empty():
		push_warning("[SaveManager] export_save_json: no hay datos para exportar.")
		return

	var export_data := {"run": run_dict, "legacy": legacy_dict}
	var json_str: String = JSON.stringify(export_data, "\t")

	if OS.get_name() == "Web":
		var js_literal: String = JSON.stringify(json_str)
		var js_code: String = "(function(){var d=%s;var b=new Blob([d],{type:'application/json'});var u=URL.createObjectURL(b);var a=document.createElement('a');a.href=u;a.download='hyphae_genesis_save.json';document.body.appendChild(a);a.click();document.body.removeChild(a);setTimeout(function(){URL.revokeObjectURL(u);},200);})();" % js_literal
		JavaScriptBridge.eval(js_code)
	else:
		var export_path: String = "user://hyphae_genesis_save.json"
		var file := FileAccess.open(export_path, FileAccess.WRITE)
		if file:
			file.store_string(json_str)
			file.close()
			print("[SaveManager] Save exportado a: ", ProjectSettings.globalize_path(export_path))
		OS.shell_open(ProjectSettings.globalize_path("user://"))


# Timer interno usado por el polling de importación web
var _import_timer: Timer = null

## Importa un save desde archivo JSON (run + legacy).
## Web: abre file picker via JS y lee el archivo con FileReader.
## Desktop: abre FileDialog nativo para seleccionar el archivo.
func import_save_json() -> void:
	if OS.get_name() == "Web":
		_import_save_json_web()
	else:
		_import_save_json_desktop()


# ── Web ─────────────────────────────────────────────────────────────────────

func _import_save_json_web() -> void:
	# Limpiar resultado anterior
	JavaScriptBridge.eval("window._antigravity_import_json = null;")

	# Crear input[type=file] invisible, disparar click
	JavaScriptBridge.eval("""
(function(){
  var input = document.createElement('input');
  input.type = 'file';
  input.accept = '.json';
  input.style.display = 'none';
  input.onchange = function(e){
    var file = e.target.files[0];
    if(!file){ window._antigravity_import_json='__CANCEL__'; return; }
    var reader = new FileReader();
    reader.onload = function(ev){ window._antigravity_import_json = ev.target.result; };
    reader.onerror = function(){ window._antigravity_import_json = '__ERROR__'; };
    reader.readAsText(file);
  };
  document.body.appendChild(input);
  input.click();
  setTimeout(function(){ document.body.removeChild(input); }, 10000);
})();
""")

	# Polling cada 200ms hasta recibir el resultado
	if is_instance_valid(_import_timer):
		_import_timer.queue_free()
	_import_timer = Timer.new()
	_import_timer.wait_time = 0.2
	_import_timer.autostart = true
	_import_timer.timeout.connect(_poll_import_result)
	add_child(_import_timer)


func _poll_import_result() -> void:
	var result: String = str(JavaScriptBridge.eval("window._antigravity_import_json || ''"))
	if result == "":
		return  # todavía esperando

	# Limpiar timer y variable JS
	if is_instance_valid(_import_timer):
		_import_timer.queue_free()
		_import_timer = null
	JavaScriptBridge.eval("window._antigravity_import_json = null;")

	if result in ["__CANCEL__", "__ERROR__"]:
		push_warning("[SaveManager] Importación cancelada o fallida.")
		return

	# Parsear el JSON exportado
	var json := JSON.new()
	if json.parse(result) != OK:
		push_warning("[SaveManager] JSON de importación inválido.")
		return

	_apply_import_data(json.data)


# ── Desktop ──────────────────────────────────────────────────────────────────

func _import_save_json_desktop() -> void:
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.json ; Archivo de save JSON"])
	dialog.title = "Importar save — seleccionar archivo .json"
	dialog.min_size = Vector2i(600, 400)
	dialog.file_selected.connect(func(path: String):
		dialog.queue_free()
		_on_import_file_selected(path))
	dialog.canceled.connect(func(): dialog.queue_free())
	get_tree().root.add_child(dialog)
	dialog.popup_centered()


func _on_import_file_selected(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("[SaveManager] No se pudo abrir el archivo: " + path)
		return
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(text) != OK:
		push_warning("[SaveManager] JSON de importación inválido: " + path)
		return

	if not json.data is Dictionary:
		push_warning("[SaveManager] El archivo no contiene un objeto JSON válido.")
		return

	_apply_import_data(json.data)


# ── Lógica común de aplicación ───────────────────────────────────────────────

## Escribe run + legacy al slot activo y recarga la escena.
## Soporta formato nuevo { "run": {...}, "legacy": {...} } y formato viejo (solo run).
func _apply_import_data(data: Dictionary) -> void:
	var run_data: Dictionary = data.get("run", data)
	var legacy_data: Dictionary = data.get("legacy", {})

	if run_data.is_empty() and legacy_data.is_empty():
		push_warning("[SaveManager] _apply_import_data: datos vacíos, abortando.")
		return

	# Asegurar que el directorio del slot existe
	var slot_dir: String = SlotManager.get_slot_dir(SlotManager.active_slot)
	if not DirAccess.dir_exists_absolute(slot_dir):
		DirAccess.make_dir_recursive_absolute(slot_dir)

	# Escribir savegame
	if not run_data.is_empty():
		var save_file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if save_file:
			save_file.store_string(JSON.stringify(run_data))
			save_file.close()
			print("[SaveManager] Run importada a: ", SAVE_PATH)

	# Escribir legacy
	if not legacy_data.is_empty():
		var legacy_file := FileAccess.open(LegacyManager.LEGACY_PATH, FileAccess.WRITE)
		if legacy_file:
			legacy_file.store_string(JSON.stringify(legacy_data))
			legacy_file.close()
			print("[SaveManager] Legacy importado a: ", LegacyManager.LEGACY_PATH)

	# Recargar y reiniciar escena
	LegacyManager.reload_for_slot()
	get_tree().reload_current_scene()
