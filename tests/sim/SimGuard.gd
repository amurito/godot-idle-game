extends RefCounted
## SimGuard — utilidades compartidas por las escenas de test y simulación.
##
## REGLA: ninguna escena de tests/ toca estado de juego antes de que assert_sandbox() devuelva
## true. Las escenas se ejecutan vía tools/sim/run_sandboxed.ps1, que corre una COPIA del proyecto
## con otro application/config/name → otro user://. Si alguien abre una escena de tests/ desde el
## editor sobre el proyecto real, el guard aborta antes de leer o escribir nada.
##
## Sin class_name a propósito: las escenas de test se referencian con preload() y no ensucian el
## registro global de clases del juego.

const SANDBOX_TAG := "HYPHAE_SIM_SANDBOX"


static func assert_sandbox() -> bool:
	var user_dir := OS.get_user_data_dir()
	if not user_dir.contains(SANDBOX_TAG):
		printerr("[SimGuard] ABORTADO: user:// = '%s' no es el sandbox." % user_dir)
		printerr("[SimGuard] Ejecutá las escenas de tests/ con tools/sim/run_sandboxed.ps1")
		return false
	# Doble seguro: aunque un user:// virgen ya arranca con telemetría deshabilitada,
	# se fuerza en memoria para que ninguna run simulada pueda llegar al hub.
	TelemetryManager.enabled = false
	print("[SimGuard] sandbox OK · user:// = %s · telemetría OFF" % user_dir)
	return true


## Argumentos de usuario (después de `--`) con formato --clave=valor o --flag.
static func parse_args() -> Dictionary:
	var out := {}
	for raw in OS.get_cmdline_user_args():
		var arg: String = raw
		if not arg.begins_with("--"):
			continue
		var body := arg.substr(2)
		var eq_pos := body.find("=")
		if eq_pos < 0:
			out[body] = "true"
		else:
			out[body.substr(0, eq_pos)] = body.substr(eq_pos + 1)
	return out


static func arg_bool(args: Dictionary, key: String, default_value: bool) -> bool:
	if not args.has(key):
		return default_value
	var v: String = str(args[key]).to_lower()
	return v in ["1", "true", "yes", "si", "sí"]


## JSON canónico para goldens y reportes: claves ordenadas y floats con precisión completa,
## así dos estados iguales producen exactamente el mismo texto.
static func to_canonical_json(v: Variant, indent: String = "\t") -> String:
	return JSON.stringify(v, indent, true, true)


static func write_text(path: String, text: String) -> bool:
	var dir := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		printerr("[SimGuard] no se pudo escribir %s (err %d)" % [path, FileAccess.get_open_error()])
		return false
	f.store_string(text)
	f.close()
	return true


static func read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var json := JSON.new()
	var err := json.parse(f.get_as_text())
	f.close()
	if err != OK:
		printerr("[SimGuard] JSON inválido en %s: %s" % [path, json.get_error_message()])
		return null
	return json.data


## Estadísticas de una serie de duraciones en microsegundos.
static func perf_stats(samples: PackedInt64Array) -> Dictionary:
	if samples.is_empty():
		return {"n": 0}
	var sorted := Array(samples)
	sorted.sort()
	var total := 0
	for v in sorted:
		total += int(v)
	var n := sorted.size()
	return {
		"n": n,
		"mean_us": snappedf(float(total) / n, 0.1),
		"p50_us": sorted[n / 2],
		"p95_us": sorted[mini(n - 1, int(n * 0.95))],
		"max_us": sorted[n - 1],
		"total_ms": snappedf(total / 1000.0, 0.1),
	}
