extends Node

# TutorialManager.gd — Autoload
# Fase 1: Tutorial progresivo — welcome overlay, highlights dorados, hints contextuales.
# Fase 2: Tooltips de hover en header (ε/Ω/biomasa) + panel de shortcuts.
# Fase 3: Anti-stuck contextual + panel de objetivos/milestones de la run.

const SAVE_PATH := "user://tutorial_state.json"


# ==================== ESTADO TUTORIAL ====================

var _step: int = 0
var _completed: bool = false
var _main: Node = null


# ==================== CANVAS LAYERS ====================

var _canvas: CanvasLayer = null          # layer 128 — tutorial secuencial
var _tooltip_canvas: CanvasLayer = null  # layer 127 — tooltips y anti-stuck


# ==================== REFS ACTIVAS (tutorial) ====================

var _highlight_panel: Panel = null
var _extra_highlights: Array = []   # highlights adicionales para multi-target
var _extra_tweens: Array[Tween] = []  # tweens de extra highlights — matar en _clear_all
var _hint_container: PanelContainer = null
var _target_node: Control = null
var _tween: Tween = null


# ==================== REFS ACTIVAS (Fase 2-3) ====================

var _tooltip_panel: PanelContainer = null
var _shortcuts_panel: Panel = null
var _objectives_panel: Panel = null
var _antistuck_panel: PanelContainer = null


# ==================== ANTI-STUCK (Fase 3) ====================

var _time_idle: float = 0.0
var _antistuck_cooldown: float = 0.0
var _push_given: bool = false
const ANTISTUCK_THRESHOLD := 50.0   # segundos sin acción para disparar hint
const ANTISTUCK_PUSH      := 60.0   # segundos sin acción para push + regalo
const ANTISTUCK_COOLDOWN  := 150.0  # segundos entre hints consecutivos


# ==================== MILESTONE TOASTS ====================

const TOAST_DURATION := 4.5  # segundos antes del fade-out

const _MUTATION_KEYS: Dictionary = {
	"hiperasimilacion": "TUTO_MUT_HIPERASIMILACION",
	"parasitismo":      "TUTO_MUT_PARASITISMO",
	"red_micelial":     "TUTO_MUT_RED_MICELIAL",
	"esporulacion":     "TUTO_MUT_ESPORULACION",
	"simbiosis":        "TUTO_MUT_SIMBIOSIS",
	"homeostasis":      "TUTO_MUT_HOMEOSTASIS",
	"allostasis":       "TUTO_MUT_ALLOSTASIS",
	"depredador":       "TUTO_MUT_DEPREDADOR",
	"met_oscuro":       "TUTO_MUT_MET_OSCURO",
}
const _UPGRADE_KEYS: Dictionary = {
	"click":          "TUTO_UPG_CLICK",
	"auto":           "TUTO_UPG_AUTO",
	"trueque":        "TUTO_UPG_TRUEQUE",
	"click_mult":     "TUTO_UPG_CLICK_MULT",
	"auto_mult":      "TUTO_UPG_AUTO_MULT",
	"trueque_net":    "TUTO_UPG_TRUEQUE_NET",
	"specialization": "TUTO_UPG_SPECIALIZATION",
	"cognitive":      "TUTO_UPG_COGNITIVE",
	"accounting":     "TUTO_UPG_ACCOUNTING",
}

var _toast_vbox: VBoxContainer = null
var _milestones_seen: Dictionary = {}  # id → true; persistido en JSON
var _mutations_toasted: Dictionary = {}  # per-sesión, no persistido
var _all_mutations_seen: bool = false
var _had_passive_income: bool = false


# ==================== INIT ====================

func _ready() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 128
	add_child(_canvas)

	_tooltip_canvas = CanvasLayer.new()
	_tooltip_canvas.layer = 127
	add_child(_tooltip_canvas)


func _process(dt: float) -> void:
	# Sincronizar highlight con el target (layout puede cambiar en resize)
	if is_instance_valid(_highlight_panel) and is_instance_valid(_target_node):
		var r := _target_node.get_global_rect()
		_highlight_panel.position = r.position - Vector2(4.0, 4.0)
		_highlight_panel.size = r.size + Vector2(8.0, 8.0)
		if is_instance_valid(_hint_container):
			_hint_container.position = Vector2(
				clampf(r.position.x, 8.0, 900.0),
				r.position.y + r.size.y + 14.0
			)

	# Anti-stuck: solo activo cuando ya pasaron los hints del tutorial
	if (_step >= 3 or _completed) and is_instance_valid(_main):
		_time_idle += dt
		_antistuck_cooldown -= dt
		if _time_idle >= ANTISTUCK_PUSH and not _push_given and _antistuck_cooldown <= 0.0:
			_give_idle_push()
		if _time_idle >= ANTISTUCK_THRESHOLD and _antistuck_cooldown <= 0.0:
			_check_antistuck()

	# Detección de milestones y mutaciones
	if is_instance_valid(_main):
		_check_milestones()


# ==================== API PÚBLICA — TUTORIAL ====================

func set_main(m: Node) -> void:
	_main = m
	m.tree_exiting.connect(_on_main_exiting)


func _on_main_exiting() -> void:
	_main = null
	_dismiss_antistuck()


func start() -> void:
	_load()
	if _completed:
		return
	call_deferred("_run_step", _step)


func notify_reactor_clicked() -> void:
	_reset_idle()
	if _step == 1:
		_advance()


func notify_upgrade_bought() -> void:
	_reset_idle()
	if _step == 2:
		_advance()


func skip_tutorial() -> void:
	_completed = true
	_save()
	_clear_all()


## Llamar cuando se activa una mutación (desde EvoManager o cualquier site).
## Muestra un toast explicativo la primera vez por mutación.
func notify_mutation_activated(mutation_id: String) -> void:
	if _mutations_toasted.has(mutation_id):
		return
	_mutations_toasted[mutation_id] = true
	_show_mutation_toast(mutation_id)


## Llamar la primera vez que el jugador abre el Modo Laboratorio.
func notify_lab_opened() -> void:
	notify_milestone("lab_opened", tr("TUTO_MT_LAB_TITLE"), tr("TUTO_MT_LAB_BODY"), Color(0.4, 0.75, 1.0))


func reset_tutorial() -> void:
	_step = 0
	_completed = false
	_time_idle = 0.0
	_mutations_toasted.clear()
	_all_mutations_seen = false
	_had_passive_income = false
	_save()
	_clear_all()
	_dismiss_antistuck()
	if is_instance_valid(_toast_vbox):
		_toast_vbox.queue_free()
		_toast_vbox = null
	if is_instance_valid(_main):
		call_deferred("_run_step", 0)


# ==================== FASE 2 — TOOLTIPS DE HEADER ====================

const _TOOLTIP_KEY_EPSILON  := "TUTO_TIP_EPSILON"
const _TOOLTIP_KEY_OMEGA    := "TUTO_TIP_OMEGA"
const _TOOLTIP_KEY_BIOMASA  := "TUTO_TIP_BIOMASA"
const _TOOLTIP_KEY_MU       := "TUTO_TIP_MU"


func setup_header_tooltips() -> void:
	call_deferred("_wire_header_tooltips")


func _wire_header_tooltips() -> void:
	_wire_tooltip(UIManager.header_epsilon_value, _TOOLTIP_KEY_EPSILON)
	_wire_tooltip(UIManager.header_epsilon_bar,   _TOOLTIP_KEY_EPSILON)
	_wire_tooltip(UIManager.header_omega_value,   _TOOLTIP_KEY_OMEGA)
	_wire_tooltip(UIManager.header_omega_bar,     _TOOLTIP_KEY_OMEGA)
	_wire_tooltip(UIManager.header_biomasa_value, _TOOLTIP_KEY_BIOMASA)
	_wire_tooltip(UIManager.header_biomasa_bar,   _TOOLTIP_KEY_BIOMASA)
	# μ: tooltip solo disponible cuando Capital Cognitivo está activo
	var fl: Variant = UIManager.formula_label
	if fl != null and is_instance_valid(fl) and fl is Control:
		var fctrl := fl as Control
		fctrl.mouse_filter = Control.MOUSE_FILTER_PASS
		fctrl.mouse_entered.connect(func():
			if UpgradeManager.level("cognitive") > 0:
				_show_tooltip(fctrl, tr(_TOOLTIP_KEY_MU))
		)
		fctrl.mouse_exited.connect(func(): _hide_tooltip())


func _wire_tooltip(node: Variant, key: String) -> void:
	if node == null or not is_instance_valid(node):
		return
	if not node is Control:
		return
	var ctrl := node as Control
	ctrl.mouse_filter = Control.MOUSE_FILTER_PASS
	ctrl.mouse_entered.connect(func(): _show_tooltip(ctrl, tr(key)))
	ctrl.mouse_exited.connect(func(): _hide_tooltip())


func _show_tooltip(anchor: Control, text: String) -> void:
	_hide_tooltip()
	_tooltip_panel = _make_tooltip_panel(text)
	_tooltip_canvas.add_child(_tooltip_panel)
	var r := anchor.get_global_rect()
	_tooltip_panel.position = Vector2(clampf(r.position.x, 8.0, 800.0), r.position.y + r.size.y + 6.0)


func _hide_tooltip() -> void:
	if is_instance_valid(_tooltip_panel):
		_tooltip_panel.queue_free()
		_tooltip_panel = null


# ==================== FASE 2 — PANEL DE SHORTCUTS ====================

func toggle_shortcuts_panel(parent: Node) -> void:
	if is_instance_valid(_shortcuts_panel):
		_shortcuts_panel.queue_free()
		_shortcuts_panel = null
		return

	_shortcuts_panel = Panel.new()
	_shortcuts_panel.anchor_right = 1.0
	_shortcuts_panel.anchor_bottom = 1.0
	_shortcuts_panel.self_modulate = Color(0.04, 0.04, 0.08, 0.96)
	parent.add_child(_shortcuts_panel)

	var center := CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	_shortcuts_panel.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460.0, 0.0)
	panel.add_theme_stylebox_override("panel",
		_make_panel_stylebox(Color(0.05, 0.05, 0.12), Color(0.4, 0.7, 1.0), 2))
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := RichTextLabel.new()
	title.bbcode_enabled = true
	title.fit_content = true
	title.custom_minimum_size = Vector2(420.0, 0.0)
	title.add_theme_font_size_override("normal_font_size", AccessibilityManager.fs(22))
	title.add_theme_color_override("default_color", Color(0.5, 0.82, 1.0))
	title.text = EmojiToRichText.rich("[center]" + tr("TUTO_SC_TITLE") + "[/center]")
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content = true
	body.custom_minimum_size = Vector2(420.0, 0.0)
	body.text = _build_shortcuts_bbcode()
	vbox.add_child(body)

	vbox.add_child(HSeparator.new())

	var btn_close := Button.new()
	btn_close.text = tr("TUTO_BTN_CLOSE")
	btn_close.custom_minimum_size = Vector2(0.0, 40.0)
	btn_close.pressed.connect(func():
		if is_instance_valid(_shortcuts_panel):
			_shortcuts_panel.queue_free()
			_shortcuts_panel = null
	)
	vbox.add_child(btn_close)


func _build_shortcuts_bbcode() -> String:
	var t := ""
	t += "[color=cyan][b]" + tr("TUTO_SC_GENERAL") + "[/b][/color]\n"
	t += _shortcut_row("[L]", tr("TUTO_SC_L"))
	t += _shortcut_row("[K]", tr("TUTO_SC_K"))
	t += _shortcut_row("[B]", tr("TUTO_SC_B"))
	t += "\n"
	t += "[color=cyan][b]" + tr("TUTO_SC_UPGRADES") + "[/b][/color]\n"
	var pairs := [
		["[1]", tr("TUTO_SC_1")],
		["[2]", tr("TUTO_SC_2")],
		["[3]", tr("TUTO_SC_3")],
		["[4]", tr("TUTO_SC_4")],
		["[5]", tr("TUTO_SC_5")],
		["[6]", tr("TUTO_SC_6")],
		["[7]", tr("TUTO_SC_7")],
		["[8]", tr("TUTO_SC_8")],
		["[9]", tr("TUTO_SC_9")],
	]
	for pair in pairs:
		t += _shortcut_row(pair[0], pair[1])
	t += "\n"
	t += "[color=cyan][b]" + tr("TUTO_SC_HEADER_IND") + "[/b][/color]\n"
	t += "  [color=yellow][b]ε[/b][/color]   " + tr("TUTO_SC_EPS") + "\n"
	t += "  [color=cyan][b]Ω[/b][/color]   " + tr("TUTO_SC_OMG") + "\n"
	t += "  [color=#88ff88][b]Bio[/b][/color] " + tr("TUTO_SC_BIO") + "\n"
	return t


func _shortcut_row(key: String, desc: String) -> String:
	return "  [b][color=#aaddff]" + key + "[/color][/b]  " + desc + "\n"


# ==================== FASE 3 — ANTI-STUCK ====================

func _reset_idle() -> void:
	_time_idle = 0.0
	_push_given = false


func _give_idle_push() -> void:
	_push_given = true
	var passive: float = EconomyManager.get_passive_total()
	var gift: float = 10.0 * max(1.0, passive)
	EconomyManager.money += gift
	# Mismo tratamiento que _check_antistuck: resetear idle y armar cooldown para que
	# descartar el push no dispare otro hint en el mismo frame.
	_antistuck_cooldown = ANTISTUCK_COOLDOWN
	_time_idle = 0.0
	_show_antistuck_hint(tr("TUTO_AS_IDLE_PUSH") % gift)


func _check_antistuck() -> void:
	# No mostrar si ya hay algún panel de tutorial/antistuck activo
	if is_instance_valid(_antistuck_panel):
		return
	if is_instance_valid(_hint_container):
		return
	if not is_instance_valid(_main):
		return
	if RunManager.run_closed:
		return

	var hint := _build_contextual_hint()
	if hint == "":
		_time_idle = 0.0
		return

	_antistuck_cooldown = ANTISTUCK_COOLDOWN
	_time_idle = 0.0
	_show_antistuck_hint(hint)


func _build_contextual_hint() -> String:
	var money := EconomyManager.money

	# 1. Upgrade costeable → acción más obvia disponible
	const ORDER := ["click", "auto", "trueque", "click_mult", "auto_mult",
		"trueque_net", "specialization", "cognitive", "accounting"]
	for id in ORDER:
		if UpgradeManager.can_buy(id, money):
			return tr("TUTO_AS_BUY") % [tr(_UPGRADE_KEYS[id])]

	# 2. Epsilon peligroso — a 0.65 ya bloquea expansión micelial
	var eps := StructuralModel.epsilon_effective
	if eps > 0.65:
		return tr("TUTO_AS_EPS") % eps

	# 3. Sin automatización todavía
	if UpgradeManager.level("auto") == 0:
		return tr("TUTO_AS_NO_AUTO")

	# 4. Biomasa alta con mutaciones disponibles
	if BiosphereEngine.biomasa >= 10.0 and not EvoManager.mutation_sporulation:
		return tr("TUTO_AS_BIO")

	# 5. Cerca de Homeostasis
	if EvoManager.mutation_homeostasis and not RunManager.post_homeostasis:
		return tr("TUTO_AS_HOMEO")

	return ""


func _show_antistuck_hint(hint_text: String) -> void:
	# Garantizar un único panel: liberar cualquiera previo antes de crear el nuevo.
	# Sin esto, un push (60s) que pisa un hint contextual (50s) deja el anterior
	# huérfano en el canvas y su botón "Entendido" no lo puede cerrar.
	_dismiss_antistuck()
	_antistuck_panel = _make_hint_bubble(
		tr("TUTO_AS_HEADER") + "\n" + hint_text,
		func():
			_dismiss_antistuck()
	)
	_tooltip_canvas.add_child(_antistuck_panel)
	_antistuck_panel.position = Vector2(16.0, 460.0)


func _dismiss_antistuck() -> void:
	if is_instance_valid(_antistuck_panel):
		_antistuck_panel.queue_free()
		_antistuck_panel = null

## API pública — llamar al abrir cualquier panel de pantalla completa (logros, banco, historial).
## Limpia hints contextuales que de otro modo quedan sobrevolando el UI del main menu.
func hide_gameplay_hints() -> void:
	_dismiss_antistuck()
	_hide_tooltip()


func _check_milestones() -> void:
	# Primer ingreso pasivo ($/s > 0)
	if not _had_passive_income and _main.has_method("get_passive_total"):
		if (_main as Node).call("get_passive_total") > 0.1:
			_had_passive_income = true
			notify_milestone("first_passive_income", tr("TUTO_MT_PASSIVE_TITLE"), tr("TUTO_MT_PASSIVE_BODY"), Color(0.3, 0.85, 0.4))

	# Homeostasis alcanzada
	if not _milestones_seen.has("homeostasis_reached") and RunManager.homeostasis_mode:
		notify_milestone("homeostasis_reached", tr("TUTO_MT_HOMEO_TITLE"), tr("TUTO_MT_HOMEO_BODY"), Color(0.3, 0.8, 1.0))

	# Primera Trascendencia
	if not _milestones_seen.has("first_trascendencia") and LegacyManager.trascendencia_count > 0:
		notify_milestone("first_trascendencia", tr("TUTO_MT_TRAS_TITLE"), tr("TUTO_MT_TRAS_BODY"), Color(0.8, 0.4, 1.0))

	# Rutas post-trascendencia (ayuda al entrar por primera vez)
	var _active_route_id: String = RouteManager.get_active_id()
	if _active_route_id != "":
		var _milestone_id := "route_" + _active_route_id
		if not _milestones_seen.has(_milestone_id):
			var _def: Dictionary = RouteManager.ROUTE_DEFS.get(_active_route_id, {})
			var _tk: String = _def.get("milestone_title_key", "")
			var _bk: String = _def.get("milestone_body_key", "")
			if _tk != "" and _bk != "":
				notify_milestone(_milestone_id, tr(_tk), tr(_bk),
					_def.get("milestone_color", Color(1.0, 0.82, 0.1)))

	# Detección de nuevas mutaciones
	if not _all_mutations_seen:
		var all_seen := true
		for m_id: String in _MUTATION_KEYS:
			if not _mutations_toasted.has(m_id):
				all_seen = false
				var val: Variant = EvoManager.get("mutation_" + m_id)
				if val is bool and (val as bool):
					_mutations_toasted[m_id] = true
					_show_mutation_toast(m_id)
		if all_seen:
			_all_mutations_seen = true


# ==================== TOAST SYSTEM ====================

func _get_toast_vbox() -> VBoxContainer:
	if is_instance_valid(_toast_vbox):
		return _toast_vbox
	var vp_w: float = get_viewport().get_visible_rect().size.x
	_toast_vbox = VBoxContainer.new()
	_toast_vbox.add_theme_constant_override("separation", 6)
	_toast_vbox.position = Vector2(maxf(vp_w - 316.0, 4.0), 76.0)
	_tooltip_canvas.add_child(_toast_vbox)
	return _toast_vbox


func _show_toast(title: String, body: String, border_color: Color = Color(1.0, 0.82, 0.1)) -> void:
	var vbox: VBoxContainer = _get_toast_vbox()

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.13, 0.97)
	sb.border_color = border_color
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(300.0, 0.0)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 3)
	panel.add_child(inner)

	if title != "":
		var t_lbl := RichTextLabel.new()
		t_lbl.bbcode_enabled = true
		t_lbl.fit_content = true
		t_lbl.custom_minimum_size = Vector2(276.0, 0.0)
		t_lbl.add_theme_font_size_override("font_size", AccessibilityManager.fs(13))
		t_lbl.text = "[b]" + EmojiToRichText.rich(title) + "[/b]"
		inner.add_child(t_lbl)

	if body != "":
		var b_lbl := RichTextLabel.new()
		b_lbl.bbcode_enabled = true
		b_lbl.fit_content = true
		b_lbl.custom_minimum_size = Vector2(276.0, 0.0)
		b_lbl.add_theme_font_size_override("font_size", AccessibilityManager.fs(11))
		b_lbl.add_theme_color_override("default_color", Color(0.82, 0.82, 0.82))
		b_lbl.text = EmojiToRichText.rich(body)
		inner.add_child(b_lbl)

	vbox.add_child(panel)

	# Fade-out automático
	var tw := create_tween()
	tw.tween_interval(TOAST_DURATION)
	tw.tween_property(panel, "modulate:a", 0.0, 0.6)
	tw.tween_callback(func():
		if is_instance_valid(panel):
			panel.queue_free()
	)


## Muestra un toast de hito (solo una vez por id). border_color opcional.
func notify_milestone(id: String, title: String, body: String, border_color: Color = Color(1.0, 0.82, 0.1)) -> void:
	if _milestones_seen.has(id):
		return
	_milestones_seen[id] = true
	_save()
	_show_toast(title, body, border_color)


func _show_mutation_toast(m_id: String) -> void:
	var key: String = _MUTATION_KEYS.get(m_id, "")
	if key == "":
		return
	if not _milestones_seen.has("first_mutation"):
		notify_milestone("first_mutation",
			tr("TUTO_MT_FIRST_MUT_TITLE"),
			tr("TUTO_MT_FIRST_MUT_BODY"),
			Color(0.35, 0.92, 0.45))
	_show_toast(tr("TUTO_TOAST_MUT_TITLE"), tr(key), Color(0.35, 0.92, 0.45))


# ==================== FASE 3 — PANEL DE OBJETIVOS ====================

func toggle_objectives_panel(parent: Node) -> void:
	if is_instance_valid(_objectives_panel):
		_objectives_panel.queue_free()
		_objectives_panel = null
		return

	_objectives_panel = Panel.new()
	_objectives_panel.anchor_right = 1.0
	_objectives_panel.anchor_bottom = 1.0
	_objectives_panel.self_modulate = Color(0.04, 0.04, 0.08, 0.96)
	parent.add_child(_objectives_panel)

	var center := CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	_objectives_panel.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420.0, 0.0)
	panel.add_theme_stylebox_override("panel",
		_make_panel_stylebox(Color(0.04, 0.10, 0.06), Color(0.3, 0.85, 0.45), 2))
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = tr("TUTO_OBJ_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", AccessibilityManager.fs(22))
	title.add_theme_color_override("font_color", Color(0.4, 0.92, 0.55))
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content = true
	body.custom_minimum_size = Vector2(380.0, 0.0)
	body.text = _build_milestones_bbcode()
	vbox.add_child(body)

	vbox.add_child(HSeparator.new())

	var btn_close := Button.new()
	btn_close.text = tr("TUTO_BTN_CLOSE")
	btn_close.custom_minimum_size = Vector2(0.0, 40.0)
	btn_close.pressed.connect(func():
		if is_instance_valid(_objectives_panel):
			_objectives_panel.queue_free()
			_objectives_panel = null
	)
	vbox.add_child(btn_close)


func _build_milestones_bbcode() -> String:
	# Secciones: [nombre, [[done_bool, label], ...]]
	var sections: Array = [
		["TUTO_SEC_START", [
			[true,                                                        "TUTO_MS_RUN_STARTED"],
			[_any_upgrade_purchased(),                                    "TUTO_MS_FIRST_UPGRADE"],
			[_had_passive_income or UpgradeManager.level("auto") > 0,    "TUTO_MS_PASSIVE"],
		]],
		["TUTO_SEC_GROWTH", [
			[UpgradeManager.level("trueque") > 0,                        "TUTO_MS_PROD_NET"],
			[UpgradeManager.level("cognitive") > 0,                      "TUTO_MS_COGNITIVE"],
			[UpgradeManager.level("trueque_net") > 0,                    "TUTO_MS_BARTER_NET"],
			[UpgradeManager.level("specialization") > 0,                 "TUTO_MS_SPECIALIZATION"],
			[UpgradeManager.level("accounting") > 0,                     "TUTO_MS_ACCOUNTING"],
			[UpgradeManager.level("persistence") > 0,                    "TUTO_MS_PERSISTENCE"],
		]],
		["TUTO_SEC_EVOLUTION", [
			[_any_mutation_active(),                                      "TUTO_MS_FIRST_MUT"],
			[_mutation_count() >= 2,                                      "TUTO_MS_MULTI_MUT"],
			[EvoManager.mutation_homeostasis,                             "TUTO_MS_HOMEO_START"],
			[RunManager.homeostasis_mode or RunManager.post_homeostasis,  "TUTO_MS_HOMEO_REACHED"],
			[RunManager.post_homeostasis,                                 "TUTO_MS_HOMEO_SURPASSED"],
		]],
		["TUTO_SEC_TRANSCEND", [
			[_milestones_seen.has("lab_opened"),                          "TUTO_MS_LAB"],
			[LegacyManager.trascendencia_count > 0,                      "TUTO_MS_TRAS1"],
			[LegacyManager.legacy_points > 0,                            "TUTO_MS_LEGACY"],
			[LegacyManager.post_tras_route != "",                         "TUTO_MS_ROUTE"],
			[LegacyManager.trascendencia_count >= 2,                     "TUTO_MS_TRAS2"],
		]],
	]

	var done_count := 0
	var total := 0
	var next_text := ""
	var t := ""

	for sec in sections:
		var sec_name: String = tr(sec[0])
		var ms_list: Array = sec[1]
		t += "[color=#556677]-- " + sec_name + " --[/color]\n"
		for ms in ms_list:
			var done: bool = ms[0]
			var label: String = tr(ms[1])
			total += 1
			if done:
				done_count += 1
				t += "[color=#44dd66][+][/color] " + label + "\n"
			else:
				t += "[color=#444444][ ][/color] [color=#666666]" + label + "[/color]\n"
				if next_text == "":
					next_text = label
		t += "\n"

	var pct := int(100.0 * done_count / total)
	t += tr("TUTO_OBJ_PROGRESS") % [done_count, total, pct]

	if next_text != "" and not RunManager.run_closed:
		t += "\n[color=cyan]" + tr("TUTO_OBJ_NEXT") + "[/color]\n  " + next_text

	return t


func _any_upgrade_purchased() -> bool:
	for id in ["click", "auto", "trueque", "click_mult", "auto_mult",
			"trueque_net", "specialization", "cognitive", "accounting", "persistence"]:
		if UpgradeManager.level(id) > 0:
			return true
	return false


func _any_mutation_active() -> bool:
	for m_id: String in _MUTATION_KEYS:
		var v: Variant = EvoManager.get("mutation_" + m_id)
		if v is bool and (v as bool):
			return true
	return false


func _mutation_count() -> int:
	var n := 0
	for m_id: String in _MUTATION_KEYS:
		var v: Variant = EvoManager.get("mutation_" + m_id)
		if v is bool and (v as bool):
			n += 1
	return n


# ==================== FLUJO DEL TUTORIAL ====================

func _advance() -> void:
	_clear_all()
	_run_step(_step + 1)


func _run_step(step: int) -> void:
	_step = step
	_save()

	match step:
		0:
			var is_new := (LegacyManager.trascendencia_count == 0
				and LegacyManager.legacy_points == 0)
			if is_new:
				_show_welcome_overlay()
			else:
				_run_step(1)

		1:
			var target := UIManager.big_click_button as Control
			if is_instance_valid(target):
				_show_highlight(target, tr("TUTO_STEP1"))
			else:
				_run_step(2)

		2:
			var target := _find_first_affordable_upgrade()
			if is_instance_valid(target):
				_show_highlight(target, tr("TUTO_STEP2"))
			else:
				_run_step(3)

		3:
			_show_floating_hint(tr("TUTO_STEP3"))

		4:
			_show_floating_hint(tr("TUTO_STEP4"))

		5:
			var auto_btn := _find_upgrade_button("auto")
			var trueque_btn := _find_upgrade_button("trueque")
			var hint_text := tr("TUTO_STEP5")
			if is_instance_valid(auto_btn):
				_show_highlight(auto_btn, hint_text)
				if is_instance_valid(trueque_btn):
					_add_extra_highlight(trueque_btn)
			elif is_instance_valid(trueque_btn):
				_show_highlight(trueque_btn, hint_text)
			else:
				_show_floating_hint(hint_text)

		6:
			_show_floating_hint(tr("TUTO_STEP6"))

		7:
			_show_floating_hint(tr("TUTO_STEP7"))

		_:
			_completed = true
			_save()
			_clear_all()


# ==================== WELCOME OVERLAY ====================

func _show_welcome_overlay() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.02, 0.88)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	_canvas.add_child(overlay)

	var center := CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(500.0, 0.0)
	panel.add_theme_stylebox_override("panel",
		_make_panel_stylebox(Color(0.05, 0.05, 0.12), Color(1.0, 0.82, 0.1), 2))
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = tr("TUTO_WELCOME_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", AccessibilityManager.fs(30))
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.1))
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content = true
	body.custom_minimum_size = Vector2(460.0, 0.0)
	body.text = tr("TUTO_WELCOME_BODY")
	vbox.add_child(body)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	var btn_skip := Button.new()
	btn_skip.text = tr("TUTO_BTN_SKIP")
	btn_skip.add_theme_font_size_override("font_size", AccessibilityManager.fs(13))
	btn_skip.modulate = Color(0.65, 0.65, 0.65)
	btn_skip.pressed.connect(func(): skip_tutorial())
	btn_row.add_child(btn_skip)

	var btn_start := Button.new()
	btn_start.text = tr("TUTO_BTN_START")
	btn_start.custom_minimum_size = Vector2(0.0, 48.0)
	btn_start.add_theme_font_size_override("font_size", AccessibilityManager.fs(20))
	btn_start.pressed.connect(func(): _advance())
	btn_row.add_child(btn_start)


# ==================== HIGHLIGHT DORADO ====================

func _show_highlight(target: Control, hint_text: String) -> void:
	_target_node = target

	_highlight_panel = Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	sb.border_color = Color(1.0, 0.82, 0.1)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(5)
	_highlight_panel.add_theme_stylebox_override("panel", sb)
	_canvas.add_child(_highlight_panel)

	var r := target.get_global_rect()
	_highlight_panel.position = r.position - Vector2(4.0, 4.0)
	_highlight_panel.size = r.size + Vector2(8.0, 8.0)

	_tween = create_tween()
	_tween.set_loops()
	_tween.tween_property(_highlight_panel, "modulate:a", 0.25, 0.65)
	_tween.tween_property(_highlight_panel, "modulate:a", 1.0, 0.65)

	_hint_container = _make_hint_bubble(hint_text)
	_canvas.add_child(_hint_container)
	_hint_container.position = Vector2(clampf(r.position.x, 8.0, 900.0), r.position.y + r.size.y + 14.0)


# ==================== FLOATING HINT ====================

func _show_floating_hint(hint_text: String) -> void:
	_hint_container = _make_hint_bubble(hint_text)
	_canvas.add_child(_hint_container)
	_hint_container.position = Vector2(16.0, 350.0)


# ==================== HELPERS UI ====================

## dismiss_fn: Callable opcional. Si es válido, el botón usa esa fn en vez de _advance().
func _make_hint_bubble(hint_text: String, dismiss_fn: Callable = Callable()) -> PanelContainer:
	var container := PanelContainer.new()
	container.add_theme_stylebox_override("panel",
		_make_panel_stylebox(Color(0.04, 0.04, 0.10, 0.96), Color(1.0, 0.82, 0.1, 0.85), 1))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	container.add_child(vbox)

	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.custom_minimum_size = Vector2(290.0, 0.0)
	label.text = hint_text
	vbox.add_child(label)

	var btn := Button.new()
	btn.text = EmojiToRichText.strip(tr("TUTO_BTN_UNDERSTOOD"))
	btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(11))
	if dismiss_fn.is_valid():
		btn.pressed.connect(dismiss_fn)
	else:
		btn.pressed.connect(func(): _advance())
	vbox.add_child(btn)

	return container


func _make_tooltip_panel(text: String) -> PanelContainer:
	var container := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.04, 0.10, 0.97)
	sb.border_color = Color(0.45, 0.55, 0.9, 0.9)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	container.add_theme_stylebox_override("panel", sb)

	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.custom_minimum_size = Vector2(200.0, 0.0)
	label.add_theme_font_size_override("font_size", AccessibilityManager.fs(12))
	label.text = text
	container.add_child(label)

	return container


func _make_panel_stylebox(bg: Color, border: Color, border_w: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(7)
	sb.content_margin_left = 20.0
	sb.content_margin_right = 20.0
	sb.content_margin_top = 18.0
	sb.content_margin_bottom = 18.0
	return sb


# ==================== CLEAR ====================

func _clear_all() -> void:
	if is_instance_valid(_tween):
		_tween.kill()
		_tween = null
	for tw in _extra_tweens:
		if is_instance_valid(tw):
			tw.kill()
	_extra_tweens.clear()
	for child in _canvas.get_children():
		child.queue_free()
	_highlight_panel = null
	_extra_highlights.clear()
	_hint_container = null
	_target_node = null


## Crea un highlight dorado adicional sobre un target extra (sin hint bubble ni tween)
func _add_extra_highlight(target: Control) -> void:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	sb.border_color = Color(1.0, 0.82, 0.1)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(5)
	p.add_theme_stylebox_override("panel", sb)
	var r := target.get_global_rect()
	p.position = r.position - Vector2(4.0, 4.0)
	p.size = r.size + Vector2(8.0, 8.0)
	_canvas.add_child(p)
	_extra_highlights.append(p)
	# Pulso sincronizado con el highlight principal
	var tw: Tween = create_tween()
	tw.set_loops()
	tw.tween_property(p, "modulate:a", 0.25, 0.65)
	tw.tween_property(p, "modulate:a", 1.0, 0.65)
	_extra_tweens.append(tw)


## Busca un UpgradeButton por su upgrade_id
func _find_upgrade_button(id: String) -> Control:
	if not is_instance_valid(_main):
		return null
	var btns := _main.get_tree().get_nodes_in_group("upgrade_buttons")
	for b in btns:
		if b.has_method("get") and b.get("upgrade_id") == id and (b as Button).visible:
			return b as Control
	return null


# ==================== HELPERS JUEGO ====================

func _find_first_affordable_upgrade() -> Control:
	if not is_instance_valid(_main):
		return null
	var btns := _main.get_tree().get_nodes_in_group("upgrade_buttons")
	for b in btns:
		if b is Button and not (b as Button).disabled and (b as Button).visible:
			return b as Button
	var fallback: Control = UIManager.upgrade_click_button as Control
	if is_instance_valid(fallback) and not (fallback as Button).disabled:
		return fallback
	return null


# ==================== PERSISTENCIA ====================

func _save() -> void:
	var data := {
		"step": _step,
		"completed": _completed,
		"milestones": _milestones_seen,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return
	var data: Dictionary = json.data
	_step = int(data.get("step", 0))
	_completed = bool(data.get("completed", false))
	_milestones_seen = data.get("milestones", {})
