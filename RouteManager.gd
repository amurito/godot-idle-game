extends Node

## RouteManager — Autoload
## Registry único de rutas post-trascendencia.
##
## Responsabilidades:
##   - Definición centralizada de metadata (tier, gating, icon, color, claves de locale)
##   - Instancia y ciclo de vida de la ruta activa (PostTrasRoute)
##   - API pública para consumers (UIManager, EvoManager, EconomyManager, etc.)
##   - Serialize/deserialize del estado de la ruta activa
##
## Orden en [autoload]: después de RunManager (las rutas llaman RunManager.close_run).

# ──────────────────────────────────────────────────────────────────
#  REGISTRO DE RUTAS
# ──────────────────────────────────────────────────────────────────
## Metadata de cada ruta. Campos:
##   tier       String  — "basica" | "avanzada" | "fantasma" | "secreta"
##   min_tras   int     — trascendencias mínimas para aparecer
##   consumable bool    — true = se borra tras el run; false = re-elegible
##   icon       String  — emoji (strip en web)
##   name_key   String  — clave de tr() para nombre
##   desc_key   String  — clave de tr() para descripción
##   color      Color   — color temático para la UI
const ROUTE_DEFS: Dictionary = {
	"vacio": {
		"tier": "basica", "min_tras": 1, "consumable": true,
		"icon": "🕳️", "name_key": "ROUTE_VACIO_HAMBRIENTO", "desc_key": "ROUTE_VACIO_DESC",
		"color": Color(0.55, 0.0, 0.8),
	},
	"carnaval": {
		"tier": "basica", "min_tras": 1, "consumable": true,
		"icon": "🎭", "name_key": "ROUTE_CARNAVAL", "desc_key": "ROUTE_CARNAVAL_DESC",
		"color": Color(1.0, 0.4, 0.1),
	},
	"reencarnacion": {
		"tier": "basica", "min_tras": 1, "consumable": true,
		"icon": "⚱️", "name_key": "ROUTE_REENCARNACION", "desc_key": "ROUTE_REENCARNACION_DESC",
		"color": Color(0.3, 0.9, 0.6),
	},
}

# ──────────────────────────────────────────────────────────────────
#  ESTADO RUNTIME
# ──────────────────────────────────────────────────────────────────
var _active_route: PostTrasRoute = null
var _active_id: String = ""

# ──────────────────────────────────────────────────────────────────
#  CICLO DE VIDA
# ──────────────────────────────────────────────────────────────────

## Instancia y activa la ruta con el id dado.
## Llamado desde RunManager.activate_post_tras_route() (que a su vez lo llama main._ready).
func activate(id: String) -> void:
	_active_id = id
	match id:
		"vacio":
			_active_route = RouteVacio.new()
		"carnaval":
			_active_route = RouteCarnaval.new()
		"reencarnacion":
			_active_route = RouteReencarnacion.new()
		_:
			push_warning("[RouteManager] activate: id desconocido '%s'" % id)
			_active_route = null
			_active_id = ""
			return
	_active_route.activate()

## Tick delegado. Llamado desde main._process_game_loop() en lugar del par
## update_carnaval / check_ascesis_profunda anterior.
func tick(delta: float) -> void:
	if _active_route != null:
		_active_route.tick(delta)

## Limpiar la ruta activa (al reset de run o al inicio de una nueva).
func reset() -> void:
	_active_route = null
	_active_id = ""

# ──────────────────────────────────────────────────────────────────
#  API PÚBLICA
# ──────────────────────────────────────────────────────────────────

## true si la ruta con ese id está activa en la run actual.
func is_active(id: String) -> bool:
	return _active_id == id

## true si hay alguna ruta activa (cualquiera).
func has_active_route() -> bool:
	return _active_route != null

## Id de la ruta activa, o "" si no hay ninguna.
func get_active_id() -> String:
	return _active_id

## Multiplicador de producción de la ruta activa (1.0 si no hay ruta).
func production_mult() -> float:
	if _active_route == null:
		return 1.0
	return _active_route.production_mult()

## false si la ruta activa bloquea la bifurcación de mutaciones.
func allows_bifurcation() -> bool:
	if _active_route == null:
		return true
	return _active_route.allows_bifurcation()

## Dict de estado extra de la ruta activa (claves dependen de la ruta concreta).
## Usá .get(key, default) — no asumir presencia de claves.
func get_extra_state() -> Dictionary:
	if _active_route == null:
		return {}
	return _active_route.get_extra_state()

## Lista de ids de rutas que el jugador puede elegir en la pantalla post-trascendencia.
## Único lugar con lógica de gating.
func get_selectable_routes() -> Array:
	var out: Array = []
	var tras: int = LegacyManager.trascendencia_count
	for id in ROUTE_DEFS:
		var d: Dictionary = ROUTE_DEFS[id]
		if tras < d.min_tras:
			continue
		if d.has("requires") and not _meets_requires(d.requires):
			continue
		out.append(id)
	return out

func _meets_requires(req: Dictionary) -> bool:
	if req.has("transmutacion"):
		# Placeholder para rutas avanzadas futuras
		return LegacyManager.get_buff_value(req.transmutacion)
	return true

# ──────────────────────────────────────────────────────────────────
#  SERIALIZE / DESERIALIZE
# ──────────────────────────────────────────────────────────────────

## Devuelve un dict JSON-safe con el estado completo de la ruta activa.
func serialize() -> Dictionary:
	if _active_route == null:
		return {"active_route_id": ""}
	return {
		"active_route_id": _active_id,
		"route_state": _active_route.serialize(),
	}

## Restaura el estado desde un dict de save.
## Maneja tanto el formato nuevo ("active_route_id") como el formato legacy
## (campos individuales "carnaval_active", "vacio_hambriento_active", etc.)
func deserialize(d: Dictionary) -> void:
	# ── Formato nuevo ──────────────────────────────────────────────
	if d.has("active_route_id"):
		var id: String = d.get("active_route_id", "")
		if id == "":
			reset()
			return
		_active_id = id
		match id:
			"vacio":
				_active_route = RouteVacio.new()
			"carnaval":
				_active_route = RouteCarnaval.new()
			"reencarnacion":
				_active_route = RouteReencarnacion.new()
			_:
				push_warning("[RouteManager] deserialize: id desconocido '%s'" % id)
				reset()
				return
		_active_route.deserialize(d.get("route_state", {}))
		# Carnaval: re-aplicar la mutación activa tras restaurar el índice
		if id == "carnaval":
			var rc: RouteCarnaval = _active_route as RouteCarnaval
			if rc != null and not rc.mutations.is_empty():
				EvoManager.carnaval_set_mutation(rc.mutations[rc.index])
		return

	# ── Formato legacy (saves anteriores al refactor) ──────────────
	if d.get("carnaval_active", false):
		_active_id = "carnaval"
		_active_route = RouteCarnaval.new()
		_active_route.deserialize({
			"mutations": d.get("carnaval_mutations", []),
			"index": d.get("carnaval_index", 0),
			"timer": d.get("carnaval_timer", 0.0),
			"total_rotations": d.get("carnaval_total_rotations", 0),
			"peak_money": d.get("carnaval_peak_money", 0.0),
		})
		var rc: RouteCarnaval = _active_route as RouteCarnaval
		if rc != null and not rc.mutations.is_empty():
			EvoManager.carnaval_set_mutation(rc.mutations[rc.index])
		return

	if d.get("vacio_hambriento_active", false):
		_active_id = "vacio"
		_active_route = RouteVacio.new()
		_active_route.deserialize({
			"mult": d.get("vacio_hambriento_mult", Balance.VACIO_HAMBRIENTO_MULT),
			"ascesis_timer": d.get("ascesis_timer", 0.0),
		})
		return

	if d.get("reencarnacion_active", false):
		_active_id = "reencarnacion"
		_active_route = RouteReencarnacion.new()
		return

	# Ninguna ruta activa
	reset()
