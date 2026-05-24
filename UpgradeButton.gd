extends Button
class_name UpgradeButton

## ID de la mejora definida en UpgradeManager (ej: "click", "auto")
@export var upgrade_id: String = ""

## Teclas de acceso rápido 1-9 asignadas por el usuario
const HOTKEY_MAP := {
	"click": 1, "auto": 2, "trueque": 3,
	"click_mult": 4, "auto_mult": 5, "trueque_net": 6,
	"specialization": 7, "cognitive": 8, "accounting": 9
}

func _ready() -> void:
	add_to_group("upgrade_buttons")

	# Botones compactos: bajar el font_size permite reducir la altura del botón
	# sin que el label de 2 líneas (texto + costo) se salga del rectángulo.
	# NO usar clip_text: sin texto los botones colapsan a ancho 0 en GridContainer.
	add_theme_font_size_override("font_size", AccessibilityManager.fs(11))

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
	UpgradeManager.purchase_upgrade(upgrade_id)

## Actualiza el texto y estado del botón basándose en el manager y dinero actual
func update_appearance(current_money: float) -> void:
	if upgrade_id == "" or not UpgradeManager.states.has(upgrade_id):
		return
		
	var def: UpgradeDef  = UpgradeManager.get_def(upgrade_id)
	var state :Dictionary= UpgradeManager.get_state(upgrade_id)
	
	if not def or state.is_empty(): return
	
	# Visibilidad basada en desbloqueo
	visible = state.unlocked
	
	var _label := tr("UPG_" + upgrade_id.to_upper())
	if def.one_shot and state.level > 0:
		text = EmojiToRichText.strip(_label + "\n" + tr("UPG_ACQUIRED"))
		disabled = true
		_apply_acquired_style()
		return

	# Texto dinámico
	var gain_str := ""
	if def.is_multiplicative:
		gain_str = "×%.2f" % def.gain
	else:
		gain_str = "+%.1f" % def.gain

	var cost :float= state.current_cost
	var cost_str: String
	if cost >= 1_000_000_000.0:
		cost_str = "$%.2fB" % (cost / 1_000_000_000.0)
	elif cost >= 1_000_000.0:
		cost_str = "$%.2fM" % (cost / 1_000_000.0)
	elif cost >= 1_000.0:
		cost_str = "$%.1fK" % (cost / 1_000.0)
	else:
		cost_str = "$%d" % int(cost)

	var lvl :int= state.level
	var level_str := " [Nv.%d]" % lvl if lvl > 0 else ""

	var hk_prefix := ""
	if upgrade_id in HOTKEY_MAP:
		hk_prefix = "[%d] " % HOTKEY_MAP[upgrade_id]

	if def.one_shot:
		text = EmojiToRichText.strip("%s%s\n%s" % [hk_prefix, _label, cost_str])
	else:
		text = EmojiToRichText.strip("%s%s%s (%s)\n%s" % [hk_prefix, _label, level_str, gain_str, cost_str])
	
	# Desactivar si no alcanza el dinero
	var can_afford = current_money >= cost
	disabled = not can_afford

	# Aplicar estilos visuales basados en affordability (Phase 6 — Visual Affordability Indicators)
	_apply_affordability_style(can_afford)

## Aplica estilos visuales basados en si el upgrade es asequible
func _apply_affordability_style(can_afford: bool) -> void:
	if AccessibilityManager.high_contrast:
		_apply_affordability_style_hc(can_afford)
		return
	if can_afford:
		var ok_c: Color = AccessibilityManager.cok()
		# Normal — fondo oscuro fijo, borde con el color accesible
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.06, 0.08, 0.06, 0.95)
		s.set_border_width_all(2)
		s.border_color = Color(ok_c.r, ok_c.g, ok_c.b, 0.85)
		s.set_corner_radius_all(4)
		s.set_content_margin_all(2)
		add_theme_stylebox_override("normal", s)
		# Hover
		var h := s.duplicate() as StyleBoxFlat
		h.bg_color = Color(0.09, 0.12, 0.09, 0.98)
		h.border_color = ok_c
		add_theme_stylebox_override("hover", h)
		# Pressed
		var p := s.duplicate() as StyleBoxFlat
		p.bg_color = Color(0.04, 0.06, 0.04, 1.0)
		p.border_color = Color(ok_c.r, ok_c.g, ok_c.b, 0.7)
		add_theme_stylebox_override("pressed", p)
		remove_theme_color_override("font_color")
	else:
		# Normal — apagado
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.07, 0.06, 0.09, 0.55)
		s.set_border_width_all(1)
		s.border_color = Color(0.35, 0.30, 0.40, 0.45)  # gris
		s.set_corner_radius_all(4)
		s.set_content_margin_all(2)
		add_theme_stylebox_override("normal", s)
		add_theme_stylebox_override("hover", s)
		add_theme_stylebox_override("pressed", s)
		add_theme_color_override("font_color", Color(0.38, 0.33, 0.42, 0.65))

## Alto contraste: blanco/negro en lugar de verde/gris
func _apply_affordability_style_hc(can_afford: bool) -> void:
	if can_afford:
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.0, 0.0, 0.0, 1.0)
		s.set_border_width_all(3)
		s.border_color = Color(1.0, 1.0, 1.0, 1.0)
		s.set_corner_radius_all(3)
		s.set_content_margin_all(2)
		add_theme_stylebox_override("normal", s)
		var h := s.duplicate()
		h.bg_color = Color(0.15, 0.15, 0.15, 1.0)
		add_theme_stylebox_override("hover", h)
		var p := s.duplicate()
		p.bg_color = Color(0.25, 0.25, 0.25, 1.0)
		add_theme_stylebox_override("pressed", p)
		add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	else:
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.08, 0.08, 0.08, 1.0)
		s.set_border_width_all(1)
		s.border_color = Color(0.45, 0.45, 0.45, 0.7)
		s.set_corner_radius_all(3)
		s.set_content_margin_all(2)
		add_theme_stylebox_override("normal", s)
		add_theme_stylebox_override("hover", s)
		add_theme_stylebox_override("pressed", s)
		add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.75))

## Estilo para upgrade one-shot ya adquirido
func _apply_acquired_style() -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.05, 0.07, 0.05, 0.5)
	s.set_border_width_all(1)
	s.border_color = Color(0.25, 0.55, 0.25, 0.45)  # verde apagado
	s.set_corner_radius_all(4)
	s.set_content_margin_all(2)
	add_theme_stylebox_override("normal", s)
	add_theme_stylebox_override("hover", s)
	add_theme_stylebox_override("disabled", s)
	add_theme_color_override("font_color", Color(0.4, 0.7, 0.4, 0.6))
