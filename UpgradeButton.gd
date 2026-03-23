extends Button
class_name UpgradeButton

## ID de la mejora definida en UpgradeManager (ej: "click", "auto")
@export var upgrade_id: String = ""

func _ready() -> void:
	add_to_group("upgrade_buttons")
	
	if upgrade_id == "":
		var n = name.to_lower()
		var cleaned = n.replace("button", "").replace("upgrade", "")
		if cleaned == "clickmultiplier": cleaned = "click_mult"
		elif cleaned == "automultiplier": cleaned = "auto_mult"
		elif cleaned == "truequenetwork": cleaned = "trueque_net"
		elif cleaned == "persistence": cleaned = "persistence"
		upgrade_id = cleaned
	
	if upgrade_id == "" or not UpgradeManager.states.has(upgrade_id):
		# Intento final: ver si el nombre del nodo coincide directo con algún id
		var n = name.to_lower()
		for id in UpgradeManager.states.keys():
			if n.contains(id):
				upgrade_id = id
				break
	
	if upgrade_id == "":
		push_warning("UpgradeButton en [%s] no tiene upgrade_id asignado." % get_path())
		return
	
	pressed.connect(_on_pressed)
	update_appearance(0.0) # Inicial sin dinero para solo poner el texto

func _on_pressed() -> void:
	var main = get_tree().get_first_node_in_group("main")
	if not main: return
	
	if main.has_method("purchase_upgrade"):
		main.purchase_upgrade(upgrade_id)

## Actualiza el texto y estado del botón basándose en el manager y dinero actual
func update_appearance(current_money: float) -> void:
	if upgrade_id == "" or not UpgradeManager.states.has(upgrade_id):
		# visible = false # Ocultar si no existe la def
		return
		
	var def = UpgradeManager.get_def(upgrade_id)
	var state = UpgradeManager.get_state(upgrade_id)
	
	if not def or state.is_empty(): return
	
	# Visibilidad basada en desbloqueo
	visible = state.unlocked
	
	# Caso especial para one-shot ya comprados
	if def.one_shot and state.level > 0:
		text = def.label + "\n[ ADQUIRIDO ]"
		disabled = true
		return

	# Texto dinámico
	var cost = state.current_cost
	var cost_str = str(round(cost))
	
	# Usar el label de la definición
	text = "%s\nCosto: $%s" % [def.label, cost_str]
	
	# Desactivar si no alcanza el dinero
	disabled = current_money < cost
