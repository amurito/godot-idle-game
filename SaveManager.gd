extends Node

# SaveManager.gd — Autoload
# Maneja la persistencia del estado del juego en formato JSON.

const SAVE_PATH := "user://savegame.json"

func save_game(main: Control):
	var data = main.get_save_data()
	var json_string = JSON.stringify(data)
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("💾 [SaveManager] Juego guardado en:", SAVE_PATH)

func load_game(main: Control):
	if not FileAccess.file_exists(SAVE_PATH):
		print("ℹ️ [SaveManager] No se encontró archivo de guardado.")
		return

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
	main._apply_save_data(data)
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
