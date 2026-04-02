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
		var all_ids = UpgradeManager.states.keys()
		# Ordenar por longitud descendente para evitar que 'trueque' coincida antes que 'trueque_allo'
		all_ids.sort_custom(func(a, b): return a.length() > b.length())
		for id in all_ids:
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
	
	if def.one_shot and state.level > 0:
		text = def.label + "\n[ ADQUIRIDO ]"
		disabled = true
		return

	# Texto dinámico
	var gain_str := ""
	if def.is_multiplicative:
		gain_str = "(×%.2f)" % def.gain
	else:
		gain_str = "(+%.1f)" % def.gain
		
	var cost = state.current_cost
	var cost_str = str(round(cost))
	
	if def.one_shot:
		text = "%s\nCosto: $%s" % [def.label, cost_str]
	else:
		text = "%s %s\nCosto: $%s" % [def.label, gain_str, cost_str]
	
	# Desactivar si no alcanza el dinero
	disabled = current_money < cost
