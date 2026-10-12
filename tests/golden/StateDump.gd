extends RefCounted
## StateDump — volcado, captura/restauración y diff de estado de autoloads para golden tests.
##
## Codificación (encode) preserva el TIPO además del valor, porque un refactor que cambia un
## int por un float (p.ej. un nivel de upgrade cargado desde JSON) es un cambio observable:
##   bool        → true / false
##   int         → "i:<n>"
##   float       → número JSON (no finitos: "f:nan", "f:inf", "f:-inf")
##   String      → "s:<texto>"
##   Dictionary  → { "<clave codificada>": valor codificado }
##   Array       → [ ... ]
##   Object      → "o:<clase>"  (no se recorre: refs a nodos/escena)
##   otros       → "v:<var_to_str>"

## Propiedades con getter y sin setter: no se pueden restaurar con set().
const READ_ONLY := {
	"LegacyManager": ["LEGACY_PATH"],
	"SaveManager": ["SAVE_PATH"],
}

## Valores que dependen del reloj de pared (no del tiempo de juego): se reemplazan por
## "volatile" en los volcados para que los goldens no fallen por ruido.
const VOLATILE_KEYS := ["unlocked_at", "timestamp", "created_at", "control_omega_last_ms",
	"_last_ui_tick_ms", "session_id", "_session_started_at", "_run_started_at"]

## Cachés internos (no son estado de juego): se excluyen de los volcados por completo.
## Su corrección se verifica con invariantes explícitos (ver GoldenRunner), no por valor.
const EXCLUDED_VARS := ["_memo", "_memo_depth", "_memo_frame", "_ng_rules", "_reset_defaults",
	"last_exclusive_disabled"]


static func encode(v: Variant) -> Variant:
	match typeof(v):
		TYPE_NIL:
			return "nil"
		TYPE_BOOL:
			return v
		TYPE_INT:
			return "i:%d" % v
		TYPE_FLOAT:
			var f: float = v
			if is_nan(f):
				return "f:nan"
			if is_inf(f):
				return "f:inf" if f > 0.0 else "f:-inf"
			return f
		TYPE_STRING, TYPE_STRING_NAME:
			return "s:" + str(v)
		TYPE_DICTIONARY:
			var out := {}
			var d: Dictionary = v
			for k in d:
				var key := _key(k)
				out[key] = "volatile" if key in VOLATILE_KEYS else encode(d[k])
			return out
		TYPE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_STRING_ARRAY:
			var arr: Array = []
			for item in v:
				arr.append(encode(item))
			return arr
		TYPE_OBJECT:
			if not is_instance_valid(v):
				return "o:null"
			var o: Object = v
			return "o:" + o.get_class()
		TYPE_CALLABLE:
			return "callable"
		_:
			return "v:" + var_to_str(v)


static func _key(k: Variant) -> String:
	if typeof(k) == TYPE_STRING or typeof(k) == TYPE_STRING_NAME:
		return str(k)
	return str(encode(k))


## Nombres de las variables de script de un objeto (incluye heredadas de script).
static func script_vars(obj: Object) -> Array:
	var names: Array = []
	for p in obj.get_property_list():
		if int(p.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			names.append(str(p.name))
	return names


## Variables que forman el estado observable (sin cachés internos).
static func state_vars(obj: Object) -> Array:
	var names: Array = []
	for name in script_vars(obj):
		if not (name in EXCLUDED_VARS):
			names.append(name)
	return names


## Volcado codificado del estado (variables de script sin cachés internos).
static func dump(obj: Object) -> Dictionary:
	var out := {}
	for name in state_vars(obj):
		out[name] = "volatile" if name in VOLATILE_KEYS else encode(obj.get(name))
	return out


## Volcado de varios autoloads por nombre: { "EvoManager": {...}, ... }
static func dump_autoloads(names: Array) -> Dictionary:
	var out := {}
	var root := Engine.get_main_loop().root as Window
	for n in names:
		var node := root.get_node_or_null(NodePath(str(n)))
		if node != null:
			out[str(n)] = dump(node)
	return out


## Captura cruda (valores reales, copias profundas) para restaurar después.
static func capture(obj: Object) -> Dictionary:
	var out := {}
	for name in script_vars(obj):
		var v: Variant = obj.get(name)
		if typeof(v) == TYPE_DICTIONARY or typeof(v) == TYPE_ARRAY:
			v = v.duplicate(true)
		out[name] = v
	return out


static func restore(obj: Object, snapshot: Dictionary, owner_name: String = "") -> void:
	var skip: Array = READ_ONLY.get(owner_name, [])
	for name in snapshot:
		if name in skip:
			continue
		var v: Variant = snapshot[name]
		if typeof(v) == TYPE_DICTIONARY or typeof(v) == TYPE_ARRAY:
			v = v.duplicate(true)
		obj.set(name, v)


static func capture_autoloads(names: Array) -> Dictionary:
	var out := {}
	var root := Engine.get_main_loop().root as Window
	for n in names:
		var node := root.get_node_or_null(NodePath(str(n)))
		if node != null:
			out[str(n)] = capture(node)
	return out


static func restore_autoloads(snapshot: Dictionary) -> void:
	var root := Engine.get_main_loop().root as Window
	for n in snapshot:
		var node := root.get_node_or_null(NodePath(str(n)))
		if node != null:
			restore(node, snapshot[n], str(n))


## Diff estructurado entre dos valores codificados (ya pasados por encode).
## Devuelve una lista de { path, golden, actual } (máx `limit` entradas).
static func diff(golden: Variant, actual: Variant, path: String = "", out: Array = [], limit: int = 40) -> Array:
	if out.size() >= limit:
		return out
	if typeof(golden) == TYPE_DICTIONARY and typeof(actual) == TYPE_DICTIONARY:
		var g: Dictionary = golden
		var a: Dictionary = actual
		var keys := {}
		for k in g:
			keys[k] = true
		for k in a:
			keys[k] = true
		var sorted_keys := keys.keys()
		sorted_keys.sort()
		for k in sorted_keys:
			var sub := (path + "." + str(k)) if path != "" else str(k)
			if not g.has(k):
				out.append({"path": sub, "golden": "<ausente>", "actual": a[k]})
			elif not a.has(k):
				out.append({"path": sub, "golden": g[k], "actual": "<ausente>"})
			else:
				diff(g[k], a[k], sub, out, limit)
			if out.size() >= limit:
				break
		return out
	if typeof(golden) == TYPE_ARRAY and typeof(actual) == TYPE_ARRAY:
		var ga: Array = golden
		var aa: Array = actual
		if ga.size() != aa.size():
			out.append({"path": path + "[]", "golden": "len %d" % ga.size(), "actual": "len %d" % aa.size()})
		for i in mini(ga.size(), aa.size()):
			diff(ga[i], aa[i], "%s[%d]" % [path, i], out, limit)
			if out.size() >= limit:
				break
		return out
	if typeof(golden) == TYPE_FLOAT and typeof(actual) == TYPE_FLOAT:
		if golden != actual:
			out.append({"path": path, "golden": golden, "actual": actual})
		return out
	if typeof(golden) != typeof(actual) or golden != actual:
		out.append({"path": path, "golden": golden, "actual": actual})
	return out
