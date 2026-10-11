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
# Cuando delete_save_and_restart() tuvo que usar el fallback de overwrite en lugar de delete,
# este flag fuerza el comportamiento de "run nueva" en load_game().
var _force_new_run: bool = false

static func _sf(v: float, fallback: float = 0.0, min_val: float = -INF) -> float:
	var safe := v if not (is_nan(v) or is_inf(v)) else fallback
	return max(safe, min_val)

func build_save_data(main: Node) -> Dictionary:
	# Qué se guarda y cómo (saneamiento, getters) está declarado en SaveSchema: fuente única
	# de verdad compartida con apply_save_data(). El formato del JSON no cambia.
	SaveSchema.ensure_valid(main)
	var data := {"save_version": Version.get_version_string()}
	for sec in SaveSchema.sections():
		data[sec.name] = SaveSchema.build_section(sec, main)
	return data

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
	# Orden de carga histórico (upgrades primero). La política de cada campo (default literal
	# vs. valor en memoria, saneamiento, casteo) está declarada en SaveSchema.
	SaveSchema.ensure_valid(main)
	for section_name in SaveSchema.LOAD_ORDER:
		if data.has(section_name):
			SaveSchema.apply_section(SaveSchema.section(section_name), main, data[section_name])
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

	# v0.9.x — saves con mutaciones finales activas sin run_closed.
	# IMPORTANTE: en el diseño actual Hiperasimilación NO es terminal — es la puerta a
	# Depredador → Met.Oscuro → Autofagia/Necrosis. mutation_hyperassimilation queda en
	# true durante TODA esa cadena, así que NO debe forzar cierre (eso cerraba cualquier
	# run de la cadena al recargar → "se cierra la run y desaparecen los botones").
	# Solo Esporulación sigue siendo terminal.
	if flags.has("run_closed") and not flags["run_closed"]:
		var spor: bool = data.get("evolution", {}).get("mutation_sporulation", false)
		if spor:
			flags["run_closed"] = true
			if flags.get("final_route", "") == "":
				flags["final_route"] = "MUTACION_FINAL"
			data["flags"] = flags

	return data

func load_game(main: Node):
	var path := SAVE_PATH
	# _force_new_run se activa cuando delete_save no pudo borrar el archivo y usó el fallback.
	# En ese caso tratamos la carga como run nueva aunque el archivo exista (vacío).
	if _force_new_run:
		_force_new_run = false
		_file_existed_on_load = false
		_reset_for_new_slot(main)
		return
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
		var del_err := DirAccess.remove_absolute(path)
		if del_err != OK:
			# Fallback: sobreescribir con JSON vacío para que load_game no cargue datos viejos
			var f := FileAccess.open(path, FileAccess.WRITE)
			if f:
				f.store_string("{}")
				f.close()
			_force_new_run = true
			push_warning("[SaveManager] delete_save falló (err=%d), sobreescrito con vacío." % del_err)
		else:
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
