extends SubViewportContainer

# ============================================================
# Reactor3DContainer — override crítico
# stretch=true permite que el 3D llene el botón completo,
# pero el _input() nativo reenviaría los clicks al SubViewport
# impidiendo que BigClickButton los reciba.
# Al sobreescribir _input() con pass los clicks pasan al padre.
# NOTIFICATION_RESIZED mantiene el SubViewport en sync con el
# tamaño real del contenedor (sin distorsión).
# ============================================================

func _input(_event: InputEvent) -> void:
	pass  # No reenviar al SubViewport → clicks llegan a BigClickButton

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_sync_vp()

func _ready() -> void:
	_sync_vp()

func _sync_vp() -> void:
	if not is_inside_tree():
		return
	var vp := get_child(0) as SubViewport
	if not is_instance_valid(vp):
		return
	var s := Vector2i(int(size.x), int(size.y))
	if s.x > 0 and s.y > 0:
		vp.size = s
