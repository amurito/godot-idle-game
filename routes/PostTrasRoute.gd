class_name PostTrasRoute extends RefCounted

## Clase base para todas las rutas post-trascendencia.
## Cada ruta concreta extiende esta clase e implementa los métodos que necesita.
## Las rutas son RefCounted (no Nodes): se instancian por RouteManager y viven
## mientras dure la run activa.

## Llamado una vez al activar la ruta (justo después de trascender).
func activate() -> void:
	pass

## Tick de lógica de ruta. Llamado desde RouteManager.tick(delta).
## Puede llamar RunManager.close_run() si se cumplen las condiciones de cierre.
func tick(_delta: float) -> void:
	pass

## Multiplicador de producción que aplica esta ruta (default = 1.0 = sin efecto).
func production_mult() -> float:
	return 1.0

## false si la ruta bloquea la bifurcación de mutaciones (ej: Carnaval rota el genoma
## automáticamente y no debe permitir que el jugador elija rama).
func allows_bifurcation() -> bool:
	return true

## Estado serializable para guardar mid-run. Debe ser un dict JSON-safe.
func serialize() -> Dictionary:
	return {}

## Restaurar estado desde un dict cargado del save.
func deserialize(_d: Dictionary) -> void:
	pass

## Dict de estado extra para consumidores externos (UIManager, close_run NG+, debug).
## Las claves dependen de la ruta concreta; los consumidores usan .get(key, default).
func get_extra_state() -> Dictionary:
	return {}
