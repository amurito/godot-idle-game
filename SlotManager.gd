extends Node

# SlotManager.gd — Autoload
# Gestiona los slots de save (universos paralelos completos).
# Cada slot tiene su propio savegame.json + legacy_bank.json en user://saves/{id}/
# Este manager mantiene meta global: lista de slots, slot activo, conteo desbloqueado.

const META_PATH := "user://meta_slots.json"
const SAVES_DIR := "user://saves"
const LEGACY_SAVE_PATH := "user://savegame.json"     # path antiguo para migración
const LEGACY_BANK_PATH := "user://legacy_bank.json"  # path antiguo para migración

# Slot ID por defecto (se crea al migrar o en primer arranque)
const DEFAULT_SLOT := "default"

# Estado en memoria
var slots: Array = []          # Array of {id, name, created_at}
var active_slot: String = ""   # ID del slot activo
var unlocked_count: int = 1    # Cuántos slots están desbloqueados (default 1)

func _ready():
	_ensure_dir(SAVES_DIR)
	_load_meta()
	_migrate_legacy_save_if_needed()
	if slots.is_empty():
		# Primer arranque sin slots: crear default vacío
		_create_slot_internal(DEFAULT_SLOT, "Run principal")
		active_slot = DEFAULT_SLOT
		_save_meta()

# =====================================================
#  PERSISTENCIA DE META GLOBAL
# =====================================================

func _save_meta() -> void:
	var data := {
		"slots": slots,
		"active_slot": active_slot,
		"unlocked_count": unlocked_count,
	}
	var file := FileAccess.open(META_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func _load_meta() -> void:
	if not FileAccess.file_exists(META_PATH):
		return
	var file := FileAccess.open(META_PATH, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return
	var data: Dictionary = json.data
	file.close()
	slots = data.get("slots", [])
	active_slot = data.get("active_slot", "")
	unlocked_count = data.get("unlocked_count", 1)

# =====================================================
#  MIGRACIÓN ONE-TIME
# =====================================================

func _migrate_legacy_save_if_needed() -> void:
	# Si ya hay slots registrados, no migrar
	if not slots.is_empty():
		return
	# Si no existe el savegame ni el bank legacy, no hay nada que migrar
	if not FileAccess.file_exists(LEGACY_SAVE_PATH) and not FileAccess.file_exists(LEGACY_BANK_PATH):
		return

	print("🔄 [SlotManager] Migrando save legacy a slot 'default'")
	var slot_dir := _get_slot_dir(DEFAULT_SLOT)
	_ensure_dir(slot_dir)

	if FileAccess.file_exists(LEGACY_SAVE_PATH):
		_move_file(LEGACY_SAVE_PATH, slot_dir + "/savegame.json")
	if FileAccess.file_exists(LEGACY_BANK_PATH):
		_move_file(LEGACY_BANK_PATH, slot_dir + "/legacy_bank.json")

	_create_slot_internal(DEFAULT_SLOT, "Run principal")
	active_slot = DEFAULT_SLOT
	_save_meta()

func _move_file(from: String, to: String) -> void:
	var src := FileAccess.open(from, FileAccess.READ)
	if not src:
		return
	var content := src.get_as_text()
	src.close()
	var dst := FileAccess.open(to, FileAccess.WRITE)
	if dst:
		dst.store_string(content)
		dst.close()
	DirAccess.remove_absolute(from)

# =====================================================
#  API PÚBLICA
# =====================================================

## Path al directorio de un slot. No garantiza que exista.
func get_slot_dir(slot_id: String) -> String:
	return _get_slot_dir(slot_id)

## Path del savegame del slot activo (consumido por SaveManager).
func get_active_save_path() -> String:
	return get_slot_dir(active_slot) + "/savegame.json"

## Path del legacy_bank del slot activo (consumido por LegacyManager).
func get_active_legacy_path() -> String:
	return get_slot_dir(active_slot) + "/legacy_bank.json"

## Lista todos los slots existentes con su metadata.
func list_slots() -> Array:
	return slots.duplicate(true)

## ¿Cuántos slots puede crear el jugador en total? (1 default + N desbloqueados)
func max_slots() -> int:
	return unlocked_count

## ¿Cuántos slots vacíos quedan disponibles para crear?
func available_empty_slots() -> int:
	return max(0, unlocked_count - slots.size())

## Crea un nuevo slot con el nombre dado. Retorna el ID asignado.
## Falla (string vacío) si ya se alcanzó el máximo o el nombre es inválido.
func create_slot(display_name: String) -> String:
	if slots.size() >= unlocked_count:
		print("⚠️ [SlotManager] No hay slots disponibles. Comprá 'Slot Adicional' en el Banco Genético.")
		return ""
	var clean_name := display_name.strip_edges()
	if clean_name == "":
		clean_name = "Slot %d" % (slots.size() + 1)
	var new_id := _generate_slot_id()
	_create_slot_internal(new_id, clean_name)
	_save_meta()
	return new_id

func _create_slot_internal(slot_id: String, display_name: String) -> void:
	_ensure_dir(_get_slot_dir(slot_id))
	slots.append({
		"id": slot_id,
		"name": display_name,
		"created_at": Time.get_unix_time_from_system(),
	})

## Cambia el slot activo. NO recarga el juego — el llamador debe reload_current_scene.
func switch_slot(slot_id: String) -> bool:
	if not _slot_exists(slot_id):
		return false
	active_slot = slot_id
	_save_meta()
	return true

## Borra un slot (archivos + entrada en meta). No permite borrar el último slot.
func delete_slot(slot_id: String) -> bool:
	if slots.size() <= 1:
		print("⚠️ [SlotManager] No se puede borrar el último slot.")
		return false
	if not _slot_exists(slot_id):
		return false
	# Borrar archivos del slot
	var dir_path := _get_slot_dir(slot_id)
	_remove_dir_recursive(dir_path)
	# Quitar de la lista
	for i in range(slots.size() - 1, -1, -1):
		if slots[i].get("id", "") == slot_id:
			slots.remove_at(i)
			break
	# Si era el activo, fallback al primero
	if active_slot == slot_id:
		active_slot = slots[0].get("id", "")
	_save_meta()
	return true

## Renombra un slot existente.
func rename_slot(slot_id: String, new_name: String) -> bool:
	var clean_name := new_name.strip_edges()
	if clean_name == "":
		return false
	for s in slots:
		if s.get("id", "") == slot_id:
			s["name"] = clean_name
			_save_meta()
			return true
	return false

## Llamado cuando el jugador compra el upgrade slot_extra en el Banco Genético.
## Incrementa el conteo global de slots desbloqueados (monotonic).
func unlock_extra_slot() -> void:
	unlocked_count += 1
	_save_meta()
	print("🔓 [SlotManager] Slot adicional desbloqueado. Total: %d" % unlocked_count)

## Lee la metadata visible de un slot directamente del legacy_bank persistido.
## Devuelve dict con: t_count, total_runs, last_ending, esencia, runtime
func read_slot_summary(slot_id: String) -> Dictionary:
	var path := _get_slot_dir(slot_id) + "/legacy_bank.json"
	var summary := {
		"t_count": 0, "total_runs": 0, "last_ending": "",
		"esencia": 0, "exists": false,
	}
	if not FileAccess.file_exists(path):
		return summary
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return summary
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return summary
	var data: Dictionary = json.data
	file.close()
	summary.exists = true
	summary.t_count = data.get("trascendencia_count", 0)
	summary.total_runs = data.get("total_runs", 0)
	summary.last_ending = data.get("last_run_ending", "")
	summary.esencia = data.get("esencia", 0)
	return summary

## ¿Tiene este slot un savegame (run en progreso)?
func slot_has_savegame(slot_id: String) -> bool:
	return FileAccess.file_exists(_get_slot_dir(slot_id) + "/savegame.json")

# =====================================================
#  HELPERS INTERNOS
# =====================================================

func _get_slot_dir(slot_id: String) -> String:
	return SAVES_DIR + "/" + slot_id

func _slot_exists(slot_id: String) -> bool:
	for s in slots:
		if s.get("id", "") == slot_id:
			return true
	return false

func _generate_slot_id() -> String:
	# IDs incrementales: slot_2, slot_3, etc. (default queda como "default")
	var n := 2
	while true:
		var candidate := "slot_%d" % n
		if not _slot_exists(candidate):
			return candidate
		n += 1
	return ""

func _ensure_dir(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)

func _remove_dir_recursive(path: String) -> void:
	var dir := DirAccess.open(path)
	if not dir:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var full := path + "/" + name
		if dir.current_is_dir():
			_remove_dir_recursive(full)
		else:
			DirAccess.remove_absolute(full)
		name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(path)
