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
const ANTISTUCK_THRESHOLD := 90.0   # segundos sin acción para disparar hint
const ANTISTUCK_COOLDOWN  := 150.0  # segundos entre hints consecutivos


# ==================== MILESTONE TOASTS ====================

const TOAST_DURATION := 4.5  # segundos antes del fade-out

const MUTATION_HINTS: Dictionary = {
	"hiperasimilacion": "[b]Hiperasimilación[/b] activada.\nAbsorción de recursos aumentada — ingreso pasivo potenciado.",
	"parasitismo":      "[b]Parasitismo[/b] activado.\nEl sistema extrae recursos del entorno con bonos periódicos de dinero.",
	"red_micelial":     "[b]Red Micelial[/b] activada.\nHifas y Micelio se regeneran más rápido.",
	"esporulacion":     "[b]Esporulación[/b] activada.\nBoosts ocasionales de Biomasa por dispersión de esporas.",
	"simbiosis":        "[b]Simbiosis[/b] activada.\nCooperación estructural — las mejoras son más baratas.",
	"homeostasis":      "[b]Homeostasis[/b] activada.\nToda la producción +50% (click y pasivo). Ω_min = 0.35. Banda óptima de ε activa para cerrar la run.",
	"allostasis":       "[b]Allostasis[/b] activada.\nAdaptación proactiva al estrés estructural.",
	"depredador":       "[b]Modo Depredador[/b] activado.\nAlto riesgo, alto retorno — consumís para crecer rápido.",
	"met_oscuro":       "[color=#ff6666][b]Metabolismo Oscuro[/b][/color] activado.\nUpgrades convencionales bloqueados. Potencia rutas no lineales.",
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
		if _time_idle >= ANTISTUCK_THRESHOLD and _antistuck_cooldown <= 0.0:
			_check_antistuck()

	# Detección de milestones y mutaciones
	if is_instance_valid(_main):
		_check_milestones()


# ==================== API PÚBLICA — TUTORIAL ====================

func set_main(m: Node) -> void:
	_main = m


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
	notify_milestone("lab_opened",
		"Modo Laboratorio",
		"Mostrás ε, Ω, μ y la fórmula de persistencia en tiempo real.\nPresioná [b][L][/b] para volver al modo normal.",
		Color(0.4, 0.75, 1.0))


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

const _TOOLTIP_MU := (
	"[b][color=#ff88ff]μ — Capital Cognitivo[/color][/b]\n\n"
	+ "Amplifica la persistencia estructural del sistema.\n"
	+ "Crece con mejoras de [b]Capital Cognitivo[/b]\ny se potencia con [b]Contabilidad[/b].\n\n"
	+ "μ = 1 + ln(1 + n) × 0.08\n\n"
	+ "[color=cyan]Contabilidad: ×1.08 por nivel.[/color]\n"
	+ "[color=#aaaaff]Resiliencia: hasta ×1.30 extra.[/color]"
)
const _TOOLTIP_EPSILON := (
	"[b][color=yellow]ε — Estrés Estructural[/color][/b]\n\n"
	+ "Tensión interna del sistema.\n"
	+ "Sube con cada clic, baja con mejoras.\n\n"
	+ "[color=#88ff88]< 0.35[/color]  Biología y orden disponibles\n"
	+ "[color=#ffaa44]> 0.40[/color]  Hiperasimilación se despierta\n"
	+ "[color=#ff8888]> 0.65[/color]  Expansión micelial bloqueada\n"
	+ "[color=#ff4444]> 0.80[/color]  Ω colapsa hacia 0\n"
)
const _TOOLTIP_OMEGA := (
	"[b][color=cyan]Ω — Flexibilidad Estructural[/color][/b]\n\n"
	+ "Opuesto al estrés. Alta Ω = adaptable.\n"
	+ "Ω = 1 / (1 + ε · k · n)\n\n"
	+ "[color=#88ff88]Mejoras estructurales mantienen Ω alto.[/color]"
)
const _TOOLTIP_BIOMASA := (
	"[b][color=#88ff88]Biomasa[/color][/b]\n\n"
	+ "Recurso del sistema fúngico.\n"
	+ "Crece con el ciclo microbiano, se consume\nen mutaciones y evoluciones.\n\n"
	+ "[color=cyan]Necesaria para evolucionar.[/color]"
)


func setup_header_tooltips() -> void:
	call_deferred("_wire_header_tooltips")


func _wire_header_tooltips() -> void:
	_wire_tooltip(UIManager.header_epsilon_value, _TOOLTIP_EPSILON)
	_wire_tooltip(UIManager.header_epsilon_bar,   _TOOLTIP_EPSILON)
	_wire_tooltip(UIManager.header_omega_value,   _TOOLTIP_OMEGA)
	_wire_tooltip(UIManager.header_omega_bar,     _TOOLTIP_OMEGA)
	_wire_tooltip(UIManager.header_biomasa_value, _TOOLTIP_BIOMASA)
	_wire_tooltip(UIManager.header_biomasa_bar,   _TOOLTIP_BIOMASA)
	# μ: tooltip solo disponible cuando Capital Cognitivo está activo
	var fl: Variant = UIManager.formula_label
	if fl != null and is_instance_valid(fl) and fl is Control:
		var fctrl := fl as Control
		fctrl.mouse_filter = Control.MOUSE_FILTER_PASS
		fctrl.mouse_entered.connect(func():
			if UpgradeManager.level("cognitive") > 0:
				_show_tooltip(fctrl, _TOOLTIP_MU)
		)
		fctrl.mouse_exited.connect(func(): _hide_tooltip())


func _wire_tooltip(node: Variant, text: String) -> void:
	if node == null or not is_instance_valid(node):
		return
	if not node is Control:
		return
	var ctrl := node as Control
	ctrl.mouse_filter = Control.MOUSE_FILTER_PASS
	ctrl.mouse_entered.connect(func(): _show_tooltip(ctrl, text))
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

	var title := Label.new()
	title.text = "? Atajos de Teclado"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", AccessibilityManager.fs(22))
	title.add_theme_color_override("font_color", Color(0.5, 0.82, 1.0))
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
	btn_close.text = "Cerrar"
	btn_close.custom_minimum_size = Vector2(0.0, 40.0)
	btn_close.pressed.connect(func():
		if is_instance_valid(_shortcuts_panel):
			_shortcuts_panel.queue_free()
			_shortcuts_panel = null
	)
	vbox.add_child(btn_close)


func _build_shortcuts_bbcode() -> String:
	var t := ""
	t += "[color=cyan][b]General[/b][/color]\n"
	t += _shortcut_row("[L]", "Activar / desactivar Modo Laboratorio")
	t += _shortcut_row("[K]", "Ver progreso de la run")
	t += "\n"
	t += "[color=cyan][b]Upgrades rápidos (teclas 1–9)[/b][/color]\n"
	var pairs := [
		["[1]", "Mejorar clic"],
		["[2]", "Trabajo Manual"],
		["[3]", "Trueque"],
		["[4]", "Mult. clic"],
		["[5]", "Mult. auto"],
		["[6]", "Red de trueque"],
		["[7]", "Especialización"],
		["[8]", "Capital cognitivo (μ)"],
		["[9]", "Contabilidad"],
	]
	for pair in pairs:
		t += _shortcut_row(pair[0], pair[1])
	t += "\n"
	t += "[color=cyan][b]Indicadores del header (hover para tooltip)[/b][/color]\n"
	t += "  [color=yellow][b]ε[/b][/color]   Estrés Estructural — sube con clics, baja con mejoras\n"
	t += "  [color=cyan][b]Ω[/b][/color]   Flexibilidad — colapsa si ε es muy alto\n"
	t += "  [color=#88ff88][b]Bio[/b][/color] Biomasa — recurso del sistema fúngico\n"
	return t


func _shortcut_row(key: String, desc: String) -> String:
	return "  [b][color=#aaddff]" + key + "[/color][/b]  " + desc + "\n"


# ==================== FASE 3 — ANTI-STUCK ====================

func _reset_idle() -> void:
	_time_idle = 0.0


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
	const NAMES := {
		"click":          "Mejorar Clic",
		"auto":           "Trabajo Manual",
		"trueque":        "Trueque",
		"click_mult":     "Mult. Clic",
		"auto_mult":      "Mult. Auto",
		"trueque_net":    "Red de Trueque",
		"specialization": "Especialización",
		"cognitive":      "Capital Cognitivo (μ)",
		"accounting":     "Contabilidad",
	}
	for id in ORDER:
		if UpgradeManager.can_buy(id, money):
			return ("Podés comprar [b]" + NAMES[id] + "[/b] ahora mismo.\n"
				+ "Usá las teclas [b][1–9][/b] para compras rápidas.")

	# 2. Epsilon peligroso — a 0.65 ya bloquea expansión micelial
	var eps := StructuralModel.epsilon_effective
	if eps > 0.65:
		return ("[color=yellow]ε = %.2f[/color] — nivel alto.\n" % eps
			+ "Comprá mejoras estructurales para bajar ε.\n"
			+ "[color=#ff8888]Por encima de 0.65 la Red Micelial se bloquea.[/color]")

	# 3. Sin automatización todavía
	if UpgradeManager.level("auto") == 0:
		return ("Sin [b]Trabajo Manual[/b] el ingreso solo viene de clics.\n"
			+ "Seguí acumulando para desbloquearlo.")

	# 4. Biomasa alta con mutaciones disponibles
	if BiosphereEngine.biomasa >= 10.0 and not EvoManager.mutation_sporulation:
		return ("[color=#88ff88]Biomasa suficiente[/color] para una mutación.\n"
			+ "Revisá el panel de [b]Genoma Fúngico[/b].")

	# 5. Cerca de Homeostasis
	if EvoManager.mutation_homeostasis and not RunManager.post_homeostasis:
		return ("Estás en ruta hacia [color=cyan]Homeostasis[/color].\n"
			+ "Mantenés ε en banda (0.03–0.30) para avanzar de tier.")

	return ""


func _show_antistuck_hint(hint_text: String) -> void:
	_antistuck_panel = _make_hint_bubble(
		"[color=#aaaaff]Sugerencia[/color]\n" + hint_text,
		func():
			_dismiss_antistuck()
	)
	_tooltip_canvas.add_child(_antistuck_panel)
	_antistuck_panel.position = Vector2(16.0, 460.0)


func _dismiss_antistuck() -> void:
	if is_instance_valid(_antistuck_panel):
		_antistuck_panel.queue_free()
		_antistuck_panel = null


func _check_milestones() -> void:
	# Primer ingreso pasivo ($/s > 0)
	if not _had_passive_income and _main.has_method("get_passive_total"):
		if (_main as Node).call("get_passive_total") > 0.1:
			_had_passive_income = true
			notify_milestone("first_passive_income",
				"¡Ingreso Pasivo activo!",
				"Trabajo Manual genera [b]$/s[/b] sin hacer clic.\nSeguí comprando mejoras para aumentarlo.",
				Color(0.3, 0.85, 0.4))

	# Homeostasis alcanzada
	if not _milestones_seen.has("homeostasis_reached") and RunManager.homeostasis_mode:
		notify_milestone("homeostasis_reached",
			"¡Homeostasis alcanzada!",
			"Mantenés ε en la banda óptima (0.03–0.30)\npara avanzar al siguiente tier del sistema.",
			Color(0.3, 0.8, 1.0))

	# Primera Trascendencia
	if not _milestones_seen.has("first_trascendencia") and LegacyManager.trascendencia_count > 0:
		notify_milestone("first_trascendencia",
			"¡Primera Trascendencia!",
			"Ganaste [b]Puntos de Legado[/b].\nEl sistema reinicia pero los buffs permanentes se conservan.",
			Color(0.8, 0.4, 1.0))

	# Detección de nuevas mutaciones
	if not _all_mutations_seen:
		var all_seen := true
		for m_id: String in MUTATION_HINTS:
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
		t_lbl.text = "[b]" + title + "[/b]"
		inner.add_child(t_lbl)

	if body != "":
		var b_lbl := RichTextLabel.new()
		b_lbl.bbcode_enabled = true
		b_lbl.fit_content = true
		b_lbl.custom_minimum_size = Vector2(276.0, 0.0)
		b_lbl.add_theme_font_size_override("font_size", AccessibilityManager.fs(11))
		b_lbl.add_theme_color_override("default_color", Color(0.82, 0.82, 0.82))
		b_lbl.text = body
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
	var hint: String = MUTATION_HINTS.get(m_id, "")
	if hint == "":
		return
	_show_toast("Nueva Mutación", hint, Color(0.35, 0.92, 0.45))


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
	title.text = "Progreso de la Run"
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
	btn_close.text = "Cerrar"
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
		["Inicio", [
			[true,                                                        "Run iniciada"],
			[_any_upgrade_purchased(),                                    "Primera mejora comprada"],
			[_had_passive_income or UpgradeManager.level("auto") > 0,    "Ingreso pasivo activo ($/s)"],
		]],
		["Crecimiento", [
			[UpgradeManager.level("trueque") > 0,                        "Red de produccion establecida"],
			[UpgradeManager.level("cognitive") > 0,                      "Capital Cognitivo activado (u)"],
			[UpgradeManager.level("trueque_net") > 0,                    "Red de trueque expandida"],
			[UpgradeManager.level("specialization") > 0,                 "Especializacion funcional"],
			[UpgradeManager.level("accounting") > 0,                     "Institucion de Contabilidad"],
			[UpgradeManager.level("persistence") > 0,                    "Persistencia del sistema activa"],
		]],
		["Evolucion", [
			[_any_mutation_active(),                                      "Primera mutacion activada"],
			[_mutation_count() >= 2,                                      "Mutaciones multiples (x2+)"],
			[EvoManager.mutation_homeostasis,                             "Homeostasis iniciada"],
			[RunManager.homeostasis_mode or RunManager.post_homeostasis,  "Homeostasis alcanzada"],
			[RunManager.post_homeostasis,                                 "Limite de Homeostasis superado"],
		]],
		["Trascendencia", [
			[_milestones_seen.has("lab_opened"),                          "Modo Laboratorio descubierto"],
			[LegacyManager.trascendencia_count > 0,                      "Primera Trascendencia completada"],
			[LegacyManager.legacy_points > 0,                            "Legado acumulado"],
			[LegacyManager.post_tras_route != "",                         "Ruta post-trascendencia activa"],
			[LegacyManager.trascendencia_count >= 2,                     "Segunda Trascendencia"],
		]],
	]

	var done_count := 0
	var total := 0
	var next_text := ""
	var t := ""

	for sec in sections:
		var sec_name: String = sec[0]
		var ms_list: Array = sec[1]
		t += "[color=#556677]-- " + sec_name + " --[/color]\n"
		for ms in ms_list:
			var done: bool = ms[0]
			var label: String = ms[1]
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
	t += "[color=#888888]Progreso: %d / %d  (%d%%)[/color]\n" % [done_count, total, pct]

	if next_text != "" and not RunManager.run_closed:
		t += "\n[color=cyan]Proximo objetivo:[/color]\n  " + next_text

	return t


func _any_upgrade_purchased() -> bool:
	for id in ["click", "auto", "trueque", "click_mult", "auto_mult",
			"trueque_net", "specialization", "cognitive", "accounting", "persistence"]:
		if UpgradeManager.level(id) > 0:
			return true
	return false


func _any_mutation_active() -> bool:
	for m_id: String in MUTATION_HINTS:
		var v: Variant = EvoManager.get("mutation_" + m_id)
		if v is bool and (v as bool):
			return true
	return false


func _mutation_count() -> int:
	var n := 0
	for m_id: String in MUTATION_HINTS:
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
				_show_highlight(
					target,
					"[b]¡Hacé clic en el reactor![/b]\nCada clic genera energía y aumenta\nel estrés estructural [color=yellow](ε)[/color]."
				)
			else:
				_run_step(2)

		2:
			var target := _find_first_affordable_upgrade()
			if is_instance_valid(target):
				_show_highlight(
					target,
					"[b]¡Primera mejora disponible![/b]\nLas mejoras incrementan tu ingreso\npasivo y la complejidad estructural."
				)
			else:
				_run_step(3)

		3:
			_show_floating_hint(
				"[b][L][/b] activa el [color=cyan]Modo Laboratorio[/color]:\nestadísticas avanzadas de ε, Ω y μ en tiempo real."
			)

		4:
			_show_floating_hint(
				"[color=yellow][b]ε — Estrés Estructural[/b][/color]\n"
				+ "Sube con clics, baja con mejoras.\n\n"
				+ "[color=#88ff88]< 0.35[/color]  biología y orden disponibles\n"
				+ "[color=#ffaa44]> 0.40[/color]  Hiperasimilación se despierta\n"
				+ "[color=#ff8888]> 0.65[/color]  expansión micelial bloqueada\n"
				+ "[color=#ff4444]> 0.80[/color]  Ω colapsa — sistema rígido\n\n"
				+ "[color=#888888]Hover en ε del header para más.[/color]"
			)
			if is_instance_valid(_hint_container):
				_hint_container.position.y = 420.0

		5:
			# Highlight en [2] Trabajo Manual y [3] Trueque simultáneamente
			var auto_btn := _find_upgrade_button("auto")
			var trueque_btn := _find_upgrade_button("trueque")
			var hint_text := (
				"[color=#88ff88][b]Ingreso Pasivo[/b][/color]\n\n"
				+ "[b][2] Trabajo Manual[/b] y [b][3] Trueque[/b]\ngeneran $/s sin hacer clic.\n\n"
				+ "Observá el indicador [b]$/s[/b] en el header."
			)
			if is_instance_valid(auto_btn):
				_show_highlight(auto_btn, hint_text)
				if is_instance_valid(trueque_btn):
					_add_extra_highlight(trueque_btn)
			elif is_instance_valid(trueque_btn):
				_show_highlight(trueque_btn, hint_text)
			else:
				_show_floating_hint(hint_text)

		6:
			_show_floating_hint(
				"[color=#88ff88][b]Genoma Fúngico[/b][/color]\n\n"
				+ "[b]Biomasa[/b] se acumula sola con el tiempo —\nel sistema fúngico la genera en segundo plano.\n"
				+ "Mirá el indicador [color=#88ff88][b]Bio[/b][/color] arriba a la derecha.\n\n"
				+ "[color=#aaaaff]Cuando tengas suficiente, el panel [b]Genoma[/b]\nse ilumina — ahí activás [b]Mutaciones[/b]\nque abren rutas únicas de crecimiento.[/color]"
			)

		7:
			_show_floating_hint(
				"[color=#88ff88][b]Mutación[/b][/color] — el sistema te ofrece caminos.\n\n"
				+ "[color=cyan]El equilibrio[/color]   mantené ε en calma\n"
				+ "[color=#88ff88]La biología[/color]   expandite, crecé, dispersate\n"
				+ "[color=yellow]La cooperación[/color] construí en orden\n\n"
				+ "[color=#ff6666]...o dejás que el caos te domine.[/color]\n\n"
				+ "[color=#888888]La mutación no se elige. Se gana.[/color]"
			)

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
	title.text = "Bienvenido a AntiIDLE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", AccessibilityManager.fs(30))
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.1))
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content = true
	body.custom_minimum_size = Vector2(460.0, 0.0)
	body.text = (
		"[center]Sos una estructura en proceso de evolución.\n\n"
		+ "Hacé clic en el [b]reactor[/b] para generar energía, "
		+ "comprá [b]mejoras[/b] para crecer y vigilá el "
		+ "[color=yellow][b]estrés estructural (ε)[/b][/color] "
		+ "antes de que tu sistema colapse.\n\n"
		+ "[color=cyan]La presión da lugar a la adaptación.[/color][/center]"
	)
	vbox.add_child(body)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	var btn_skip := Button.new()
	btn_skip.text = "Omitir tutorial"
	btn_skip.add_theme_font_size_override("font_size", AccessibilityManager.fs(13))
	btn_skip.modulate = Color(0.65, 0.65, 0.65)
	btn_skip.pressed.connect(func(): skip_tutorial())
	btn_row.add_child(btn_skip)

	var btn_start := Button.new()
	btn_start.text = "  Empezar  "
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
	_hint_container.position = Vector2(16.0, 520.0)


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
	btn.text = EmojiToRichText.strip("Entendido ✓")
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
	var tw := create_tween()
	tw.set_loops()
	tw.tween_property(p, "modulate:a", 0.25, 0.65)
	tw.tween_property(p, "modulate:a", 1.0, 0.65)


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
