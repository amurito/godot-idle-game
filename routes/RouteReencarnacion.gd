class_name RouteReencarnacion extends PostTrasRoute

## REENCARNACIÓN HEREDADA — ruta post-trascendencia.
## Aplica el snapshot de upgrades guardado en LegacyManager al inicio de la run,
## restaurando el estado de compras del ciclo anterior.

func activate() -> void:
	AchievementManager.push_event("post_tras_route", {"route": "reencarnacion"})
	UpgradeManager.apply_reencarnacion_snapshot(LegacyManager.reencarnacion_snapshot)
	print("⚱️ [REENCARNACIÓN] Snapshot aplicado")
	LogManager.add(tr("LOG_REENCARNACION"))

# serialize/deserialize: no hay estado runtime propio — la instancia activa ya indica
# que la ruta está activada.
func serialize() -> Dictionary:
	return {}

func deserialize(_d: Dictionary) -> void:
	pass
