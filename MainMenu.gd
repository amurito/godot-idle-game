extends Control

@onready var btn_continue = $CenterContainer/VBoxContainer/BtnContinue
@onready var btn_new_game = $CenterContainer/VBoxContainer/BtnNewGame
@onready var btn_achievements = $CenterContainer/VBoxContainer/BtnAchievements
@onready var btn_legacy = $CenterContainer/VBoxContainer/BtnLegacy
@onready var achievements_panel = $AchievementsPanel
@onready var achievements_label = $AchievementsPanel/VBoxContainer/RichTextLabel

@onready var legacy_panel = $GeneticBankPanel
@onready var pl_counter = $GeneticBankPanel/VBoxContainer/PLCounter
@onready var legacy_list = $GeneticBankPanel/VBoxContainer/ScrollContainer/ItemList

# --- TRASCENDENCIA (v0.9.2) ---
# UI creada dinámicamente
var btn_trascendencia: Button = null
var btn_cosmic_bank: Button = null
var trascend_counter_label: Label = null
var trascend_confirm_panel: Panel = null
var cosmic_panel: Panel = null
var first_trascend_overlay: ColorRect = null

func _ready():
	var has_save := FileAccess.file_exists(SaveManager.SAVE_PATH)
	var post_transcendence := not has_save and LegacyManager.trascendencia_count > 0

	if has_save:
		# Run activa: "Continuar" carga el guardado normalmente
		btn_continue.text = "Continuar"
		btn_continue.pressed.connect(_on_continue_pressed)
	elif post_transcendence:
		# Sin run activa pero con trascendencias: "Continuar" inicia nueva run con buffs cósmicos
		btn_continue.text = "▶ Nueva Run (buffs cósmicos activos)"
		btn_continue.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
		btn_continue.pressed.connect(_start_new_run)
	else:
		# Sin nada: deshabilitar
		btn_continue.disabled = true
		btn_continue.modulate = Color(1, 1, 1, 0.4)
		btn_continue.pressed.connect(_on_continue_pressed)

	btn_new_game.pressed.connect(_on_new_game_pressed)
	btn_achievements.pressed.connect(_on_achievements_pressed)
	btn_legacy.pressed.connect(_on_legacy_pressed)

	$AchievementsPanel/VBoxContainer/BtnBack.pressed.connect(_on_back_pressed)
	$GeneticBankPanel/VBoxContainer/BtnBackLegacy.pressed.connect(_on_back_pressed)
	$CenterContainer/VBoxContainer/BtnQuit.pressed.connect(get_tree().quit)

	# --- TRASCENDENCIA UI ---
	_setup_trascendencia_ui()

	# --- BADGES de notificación ---
	_refresh_nav_badges()

# =====================================================
#  DEBUG — Teclas de testeo rápido (solo en DEBUG build)
# =====================================================
func _input(event: InputEvent) -> void:
	if not OS.is_debug_build(): return
	if not (event is InputEventKey and event.pressed and not event.echo): return
	match event.keycode:
		KEY_F2:
			# Forzar picker de rutas sin trascender
			LegacyManager.trascendencia_count = max(LegacyManager.trascendencia_count, 1)
			_show_post_tras_picker()
			print("🐛 DEBUG: picker de rutas forzado")

func _on_continue_pressed():
	# Cargar la escena principal. SaveManager.load_game se llamará en el _ready de main.gd
	get_tree().change_scene_to_file("res://main.tscn")

func _on_new_game_pressed():
	var has_meta_progress := LegacyManager.legacy_points > 0 \
		or LegacyManager.trascendencia_count > 0 \
		or LegacyManager.total_runs > 0

	if has_meta_progress:
		# Mostrar confirmación que aclara qué se preserva
		var dialog := ConfirmationDialog.new()
		dialog.title = "Iniciar Nueva Run"
		dialog.dialog_text = (
			"¿Iniciás un nuevo ciclo biótico?\n\n"
			+ "✦ Se PRESERVAN:\n  · Banco Cósmico (%d Ξ)\n  · Banco Genético (PL: %d)\n  · Rutas completadas\n\n"
			+ "⚠ Se RESETEAN:\n  · Upgrades, dinero, mutaciones\n  · Progreso de la run actual"
		) % [LegacyManager.esencia, LegacyManager.legacy_points]
		dialog.get_ok_button().text = "▶ Iniciar"
		dialog.get_cancel_button().text = "Volver"
		add_child(dialog)
		dialog.popup_centered(Vector2(420, 280))
		dialog.confirmed.connect(_start_new_run)
		dialog.canceled.connect(dialog.queue_free)
	else:
		_hard_reset()

## Nueva Run: resetea solo la partida actual. Preserva legacy y trascendencia.
func _start_new_run() -> void:
	# Si ya trascendió al menos una vez, mostrar picker de ruta post-trascendencia
	if LegacyManager.trascendencia_count > 0:
		_show_post_tras_picker()
		return
	_do_start_new_run("")

func _show_post_tras_picker() -> void:
	var overlay := ColorRect.new()
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(0.02, 0.01, 0.06, 0.97)
	add_child(overlay)

	var center := CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	overlay.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(720, 0)
	vbox.add_theme_constant_override("separation", 18)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "⚡ CICLO #%d — ELIGE TU RUTA" % (LegacyManager.trascendencia_count + 1)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Cada ruta altera las reglas de esta run. La elección es permanente."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.85))
	vbox.add_child(subtitle)

	vbox.add_child(HSeparator.new())

	const ROUTES := [
		{
			"id": "", "icon": "▶",
			"name": "CICLO ESTÁNDAR",
			"color": Color(0.7, 0.7, 0.7),
			"desc": "Sin modificadores. Mecánicas normales, Banco Genético y Cósmico activos.",
		},
		{
			"id": "vacio", "icon": "🕳️",
			"name": "VACÍO HAMBRIENTO",
			"color": Color(0.55, 0.0, 0.8),
			"desc": "Consume TODOS tus buffs cósmicos activos permanentemente.\nA cambio: producción ×100 durante toda la run.",
		},
		{
			"id": "carnaval", "icon": "🎭",
			"name": "CARNAVAL DE MUTACIONES",
			"color": Color(1.0, 0.4, 0.1),
			"desc": "Al iniciar, 3 mutaciones aleatorias son elegidas.\nRotan automáticamente cada 60 segundos. Sin control manual.",
		},
		{
			"id": "reencarnacion", "icon": "⚱️",
			"name": "REENCARNACIÓN HEREDADA",
			"color": Color(0.3, 0.9, 0.6),
			"desc": "Empezás con todos los upgrades al nivel del ciclo anterior.\nPero cada compra futura escala ×1.5 más caro (deuda kármica).",
		},
	]

	for route in ROUTES:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 70)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var s := StyleBoxFlat.new()
		s.bg_color = Color(route.color.r * 0.12, route.color.g * 0.12, route.color.b * 0.12, 0.95)
		s.set_border_width_all(2)
		s.border_color = route.color
		s.set_corner_radius_all(6)
		s.set_content_margin_all(12)
		btn.add_theme_stylebox_override("normal", s)
		var s_hover := s.duplicate()
		s_hover.bg_color = Color(route.color.r * 0.22, route.color.g * 0.22, route.color.b * 0.22, 0.98)
		btn.add_theme_stylebox_override("hover", s_hover)

		btn.text = "%s  %s\n%s" % [route.icon, route.name, route.desc]
		btn.add_theme_color_override("font_color", route.color)
		btn.add_theme_font_size_override("font_size", 13)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD

		var route_id: String = route.id
		btn.pressed.connect(func():
			overlay.queue_free()
			_do_start_new_run(route_id)
		)
		vbox.add_child(btn)

	var btn_cancel := Button.new()
	btn_cancel.text = "← Volver"
	btn_cancel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_cancel.pressed.connect(overlay.queue_free)
	vbox.add_child(btn_cancel)

func _do_start_new_run(route: String) -> void:
	# 1. Borrar save de run
	if FileAccess.file_exists(SaveManager.SAVE_PATH):
		DirAccess.remove_absolute(SaveManager.SAVE_PATH)
		print("🗑️ Run anterior borrada. Legacy y Trascendencia preservados.")

	# 2. Guardar ruta elegida en legacy (se aplica en main._ready)
	LegacyManager.post_tras_route = route
	if route != "":
		LegacyManager.save_legacy()
		print("🗺️ Ruta post-trascendencia seleccionada: %s" % route)

	# 3. Resetear solo los sistemas de run
	UpgradeManager.reset()
	BiosphereEngine.reset()
	EvoManager.reset()
	LogManager.reset()
	RunManager.reset()                     # run_closed, disturbances, homeostasis_tier, etc.
	AchievementManager.reset_run_state()   # Borra timers/contadores per-run (no toca unlocked)

	# 4. Incrementar contador de ciclos en legacy
	LegacyManager.increment_run()

	# 5. Ir al juego (los buffs cósmicos y la ruta se aplican en _ready de main.gd)
	get_tree().change_scene_to_file("res://main.tscn")

## Hard Reset absoluto: borra TODO (legacy, trascendencia, upgrades). Sin vuelta atrás.
func _hard_reset() -> void:
	if FileAccess.file_exists(SaveManager.SAVE_PATH):
		DirAccess.remove_absolute(SaveManager.SAVE_PATH)
	if FileAccess.file_exists(LegacyManager.LEGACY_PATH):
		DirAccess.remove_absolute(LegacyManager.LEGACY_PATH)

	UpgradeManager.reset()
	BiosphereEngine.reset()
	EvoManager.reset()
	LogManager.reset()

	LegacyManager.legacy_points = 0
	LegacyManager.total_runs = 0
	LegacyManager.internal_spores_total = 0.0
	LegacyManager.buffs.clear()
	LegacyManager.mu_peak_achieved = false
	LegacyManager.esencia = 0
	LegacyManager.trascendencia_count = 0
	LegacyManager.first_trascendencia_shown = false
	LegacyManager.endings_achieved = {}
	LegacyManager.cosmic_unlocked = {}
	LegacyManager.achievement_data = {}
	AchievementManager.hard_reset()

	get_tree().change_scene_to_file("res://main.tscn")

func _refresh_nav_badges() -> void:
	var has_new_ach: bool = AchievementManager.has_unseen()
	btn_achievements.text = ("★ LOGROS" if has_new_ach else "Logros")

	var has_new_buff: bool = LegacyManager.has_unseen_buff()
	btn_legacy.text = ("★ BANCO GENÉTICO" if has_new_buff else "Banco Genético")

func _on_achievements_pressed():
	achievements_panel.visible = true
	_update_achievements_view()
	# Los logros se marcan como vistos dentro de _update_achievements_view;
	# refrescamos el badge al volver.

func _on_legacy_pressed():
	legacy_panel.visible = true
	_update_legacy_view()

func _on_back_pressed():
	achievements_panel.visible = false
	legacy_panel.visible = false
	# Actualizar badges al cerrar (ya se marcaron como vistos adentro)
	_refresh_nav_badges()

func _update_legacy_view():
	pl_counter.text = "Legado acumulado: %d PL\nCiclos Bióticos completados: %d" % [LegacyManager.legacy_points, LegacyManager.total_runs]
	for child in legacy_list.get_children():
		child.queue_free()
	call_deferred("_populate_legacy_items")

func _populate_legacy_items():
	var cat_colors: Dictionary = {
		"economia":     Color(0.9,  0.85, 0.4),
		"estructura":   Color(0.5,  0.8,  1.0),
		"biologia":     Color(0.4,  0.9,  0.5),
		"conocimiento": Color(0.8,  0.6,  1.0),
		"ruta":         Color(1.0,  0.65, 0.2),
		"ng_plus":      Color(0.9,  0.3,  0.9),
		"secreto":      Color(0.5,  0.5,  0.5),
	}

	for cat in LegacyManager.CAT_ORDER:
		var cat_header_added: bool = false

		for id in LegacyManager.LEGACY_DEFS:
			var def: Dictionary = LegacyManager.LEGACY_DEFS[id]
			if def.get("cat", "") != cat:
				continue
			if not LegacyManager.is_revealed(id):
				continue

			# Header de categoría (solo la primera vez)
			if not cat_header_added:
				cat_header_added = true
				var hdr: Label = Label.new()
				hdr.text = "── %s ──" % LegacyManager.CAT_NAMES.get(cat, cat.to_upper())
				hdr.add_theme_font_size_override("font_size", 12)
				hdr.modulate = cat_colors.get(cat, Color.WHITE)
				hdr.custom_minimum_size.y = 28
				legacy_list.add_child(hdr)

			var lvl: int = LegacyManager.get_buff_level(id)
			var max_lvl: int = int(def.get("max_level", 1))
			var is_maxed: bool = lvl >= max_lvl
			var unlockable: bool = LegacyManager.is_unlockable(id)
			var cost: int = LegacyManager.get_current_cost(id)
			var affordable: bool = LegacyManager.legacy_points >= cost
			var is_new: bool = lvl > 0 and not (LegacyManager.buffs.get(id, {}) as Dictionary).get("seen", true)

			var container: HBoxContainer = HBoxContainer.new()
			container.custom_minimum_size.y = 58

			# Info column
			var info: VBoxContainer = VBoxContainer.new()
			info.size_flags_horizontal = SIZE_EXPAND_FILL

			# Nombre + badge de nivel
			var name_str: String = def.get("name", id)
			if max_lvl > 1:
				name_str += "  [%d/%d]" % [lvl, max_lvl]
			if is_new:
				name_str += "  ★ NUEVO"

			var name_lbl: Label = Label.new()
			name_lbl.text = name_str
			if is_maxed:
				name_lbl.modulate = Color(0.3, 1.0, 0.5)
			elif lvl > 0:
				name_lbl.modulate = Color(0.6, 1.0, 0.7)
			elif unlockable and affordable:
				name_lbl.modulate = Color(1.0, 1.0, 0.6)
			elif not unlockable:
				name_lbl.modulate = Color(0.45, 0.45, 0.45)
			else:
				name_lbl.modulate = Color(0.65, 0.65, 0.65)

			# Flavor text (cursiva pequeña)
			var flavor_lbl: Label = Label.new()
			flavor_lbl.text = def.get("flavor", "")
			flavor_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			flavor_lbl.add_theme_font_size_override("font_size", 10)
			flavor_lbl.modulate = Color(0.55, 0.55, 0.55)

			info.add_child(name_lbl)
			info.add_child(flavor_lbl)

			# Botón
			var buy_btn: Button = Button.new()
			buy_btn.custom_minimum_size.x = 110
			if is_maxed:
				buy_btn.text = "MÁXIMO"
				buy_btn.disabled = true
			elif not unlockable:
				buy_btn.text = "BLOQUEADO"
				buy_btn.disabled = true
			elif lvl == 0:
				var btn_cost: int = cost if def.get("cost", 0) > 0 else 0
				buy_btn.text = "ADQUIRIR" if btn_cost == 0 else "ADQUIRIR  %d PL" % btn_cost
				buy_btn.disabled = (def.get("cost", 0) > 0 and not affordable)
			else:
				buy_btn.text = "NIVEL %d  %d PL" % [lvl + 1, cost]
				buy_btn.disabled = not affordable

			buy_btn.pressed.connect(_on_buy_legacy.bind(id))

			container.add_child(info)
			container.add_child(buy_btn)
			legacy_list.add_child(container)

			# Marcar como visto al mostrarse
			if is_new:
				LegacyManager.mark_buff_seen(id)

func _on_buy_legacy(id: String):
	if LegacyManager.purchase_legacy(id):
		_update_legacy_view()

func _update_achievements_view():
	# v0.9.4: panel de logros con progreso, badge NUEVO y toast por tier.
	var total: int = AchievementManager.total_count()
	var got: int = AchievementManager.unlocked_count()

	var t: String = "[center][b]─── HISTORIAL DE LOGROS ───[/b]\n"
	t += "[color=#ffcc00]%d / %d desbloqueados[/color][/center]\n\n" % [got, total]

	var tier_order := [
		AchievementManager.Tier.MICELIO,
		AchievementManager.Tier.ESPORA,
		AchievementManager.Tier.FRUTO,
		AchievementManager.Tier.ANCESTRAL,
	]
	var tier_colors := {
		AchievementManager.Tier.MICELIO:   "#b77841",
		AchievementManager.Tier.ESPORA:    "#e0e0e5",
		AchievementManager.Tier.FRUTO:     "#ffcc40",
		AchievementManager.Tier.ANCESTRAL: "#d93a4d",
	}

	for tier in tier_order:
		var ids: Array = AchievementManager.get_by_tier(tier)
		var tier_name: String = AchievementManager.TIER_NAMES[tier]
		var tier_icon: String = AchievementManager.TIER_ICONS[tier]
		var color: String = tier_colors[tier]
		var ok: int = 0
		for id in ids:
			if AchievementManager.is_unlocked(id): ok += 1

		t += "[color=%s][b]%s %s[/b][/color]  [color=#aaaaaa]%d / %d[/color]\n" \
			% [color, tier_icon, tier_name, ok, ids.size()]

		for id in ids:
			var def: Dictionary = AchievementManager.DEFS[id]
			var unlocked_one: bool = AchievementManager.is_unlocked(id)
			var is_secret: bool = def.get("secret", false)
			var name_str: String = def.get("name", id)
			var desc_str: String = def.get("desc", "")

			if unlocked_one:
				# Badge NUEVO si todavía no fue visto
				var entry: Dictionary = AchievementManager.unlocked.get(id, {})
				var is_new: bool = not entry.get("seen", true)
				var new_badge: String = " [color=#ffdd00][b]★ NUEVO[/b][/color]" if is_new else ""
				t += "  [color=#00ff88]✓ %s[/color]%s\n" % [name_str, new_badge]
				t += "    [color=#777777]%s[/color]\n" % desc_str
				# Marcar como visto
				if is_new:
					AchievementManager.mark_seen(id)
			elif is_secret:
				t += "  [color=#444444]? ??? [i](logro oculto)[/i][/color]\n"
			else:
				# Progreso si el logro lo trackea
				var progress_str: String = _build_progress_str(id, def)
				t += "  [color=#666666][ ] %s[/color]%s\n" % [name_str, progress_str]
				t += "    [color=#444444]%s[/color]\n" % desc_str

		t += "\n"

	achievements_label.text = t

func _build_progress_str(id: String, def: Dictionary) -> String:
	var trigger: String = def.get("trigger", "")
	# Solo mostrar progreso en logros que tienen target trackeable
	if trigger not in ["event_count"] and not def.has("progress_format"):
		return ""
	var prog: Dictionary = AchievementManager.get_progress(id)
	var current: float = prog.get("current", 0.0)
	var target: float = prog.get("target", 1.0)
	if current <= 0.0:
		return ""
	var ratio: float = prog.get("ratio", 0.0)
	# Barra de texto (8 segmentos)
	var filled: int = int(ratio * 8.0)
	var bar: String = "▓".repeat(filled) + "░".repeat(8 - filled)
	# Label con formato si existe
	var fmt: String = def.get("progress_format", "{current} / {target}")
	var label: String = fmt.replace("{current}", str(int(current))).replace("{target}", str(int(target)))
	return "  [color=#888888][%s] %s[/color]" % [bar, label]

# =====================================================
#  TRASCENDENCIA — UI (v0.9.2)
# =====================================================

func _setup_trascendencia_ui() -> void:
	# Actualizar texto del botón Nueva Partida según estado del jugador
	var has_meta_progress := LegacyManager.legacy_points > 0 \
		or LegacyManager.trascendencia_count > 0 \
		or LegacyManager.total_runs > 0
	if has_meta_progress:
		btn_new_game.text = "Nueva Run"
		btn_new_game.tooltip_text = "Inicia una nueva run preservando tu Banco Genético y Banco Cósmico."
	else:
		btn_new_game.text = "Nueva Partida"
		btn_new_game.tooltip_text = ""

	# 1. Actualizar Subtitle con título cósmico (si aplica)
	var subtitle = $CenterContainer/VBoxContainer/Subtitle
	var title_cosmic = LegacyManager.get_trascendencia_title()
	if title_cosmic != "":
		subtitle.text = "✦ " + title_cosmic + " ✦  ·  Antigravity Simulation"
		subtitle.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))

	# 2. Contador de Esencia (visible solo si ya trascendió alguna vez)
	if LegacyManager.trascendencia_count > 0:
		trascend_counter_label = Label.new()
		trascend_counter_label.text = "Ξ %d   ·   Trascendencias: %d" % [LegacyManager.esencia, LegacyManager.trascendencia_count]
		trascend_counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		trascend_counter_label.add_theme_color_override("font_color", Color(0.85, 0.55, 1.0))
		trascend_counter_label.add_theme_font_size_override("font_size", 14)
		var vbox = $CenterContainer/VBoxContainer
		vbox.add_child(trascend_counter_label)
		vbox.move_child(trascend_counter_label, 3) # Después del HSeparator

	# 3. Botón TRASCENDER (entre Legacy y Quit)
	btn_trascendencia = Button.new()
	btn_trascendencia.custom_minimum_size = Vector2(0, 45)
	btn_trascendencia.text = "⚡ TRASCENDER"
	btn_trascendencia.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	btn_trascendencia.add_theme_font_size_override("font_size", 16)
	btn_trascendencia.pressed.connect(_on_trascender_pressed)
	var vbox2 = $CenterContainer/VBoxContainer
	vbox2.add_child(btn_trascendencia)
	vbox2.move_child(btn_trascendencia, vbox2.get_child_count() - 2) # Antes de Quit

	# Gate visual: si no se puede, opacidad baja
	if not LegacyManager.can_transcend():
		btn_trascendencia.modulate = Color(0.6, 0.6, 0.6, 0.8)

	# 4. Botón BANCO CÓSMICO (solo si trascendió al menos una vez)
	if LegacyManager.trascendencia_count > 0:
		btn_cosmic_bank = Button.new()
		btn_cosmic_bank.custom_minimum_size = Vector2(0, 45)
		btn_cosmic_bank.text = "✦ Banco Cósmico"
		btn_cosmic_bank.add_theme_color_override("font_color", Color(0.85, 0.55, 1.0))
		btn_cosmic_bank.pressed.connect(_on_cosmic_bank_pressed)
		vbox2.add_child(btn_cosmic_bank)
		vbox2.move_child(btn_cosmic_bank, vbox2.get_child_count() - 2)

# ------------- Handler: click en TRASCENDER -------------
func _on_trascender_pressed() -> void:
	_show_trascend_confirm_panel()

func _show_trascend_confirm_panel() -> void:
	if is_instance_valid(trascend_confirm_panel):
		trascend_confirm_panel.queue_free()

	trascend_confirm_panel = Panel.new()
	trascend_confirm_panel.anchor_right = 1.0
	trascend_confirm_panel.anchor_bottom = 1.0
	trascend_confirm_panel.self_modulate = Color(0.05, 0.02, 0.12, 0.97)
	add_child(trascend_confirm_panel)

	var margin := MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 60)
	trascend_confirm_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "⚡ TRASCENDENCIA ⚡"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	vbox.add_child(title)

	var subtitle_lbl := Label.new()
	subtitle_lbl.text = "Disolvé el ciclo actual para absorberlo como Esencia (Ξ)."
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_lbl.add_theme_font_size_override("font_size", 14)
	subtitle_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	vbox.add_child(subtitle_lbl)

	vbox.add_child(HSeparator.new())

	var gate_title := Label.new()
	gate_title.text = "Requisitos:"
	gate_title.add_theme_font_size_override("font_size", 18)
	gate_title.add_theme_color_override("font_color", Color(0.85, 0.85, 1.0))
	vbox.add_child(gate_title)

	var gate_status := Label.new()
	gate_status.text = LegacyManager.get_transcend_gate_status()
	gate_status.add_theme_font_size_override("font_size", 13)
	vbox.add_child(gate_status)

	vbox.add_child(HSeparator.new())

	var reward_title := Label.new()
	reward_title.text = "Recompensa al trascender:"
	reward_title.add_theme_font_size_override("font_size", 18)
	reward_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(reward_title)

	var can := LegacyManager.can_transcend()
	var esencia_gain := LegacyManager.calculate_esencia_gain() if can else 0

	var reward := Label.new()
	if can:
		reward.text = "Ganás +%d Ξ (Esencia)\nPL actual: %d → convertido\nRutas únicas: %d × 5 Ξ\nTier bonus: +%d Ξ" % [
			esencia_gain,
			LegacyManager.legacy_points,
			LegacyManager.unique_endings_count(),
			LegacyManager.trascendencia_count * 2
		]
		reward.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	else:
		reward.text = "Requisitos no cumplidos.\nCompletá al menos 1 cierre en cada familia y acumulá %d PL." % LegacyManager.TRASCENDENCIA_PL_GATE
		reward.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	reward.add_theme_font_size_override("font_size", 13)
	vbox.add_child(reward)

	vbox.add_child(HSeparator.new())

	var warn := Label.new()
	warn.text = "⚠ Al trascender se RESETEAN: upgrades, mutaciones, PL, buffs del Banco Genético.\n✦ Se PRESERVAN: Esencia (Ξ), Banco Cósmico, rutas ya completadas."
	warn.autowrap_mode = TextServer.AUTOWRAP_WORD
	warn.add_theme_font_size_override("font_size", 12)
	warn.add_theme_color_override("font_color", Color(0.85, 0.7, 0.5))
	vbox.add_child(warn)

	vbox.add_child(Control.new()) # Spacer

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	var btn_cancel := Button.new()
	btn_cancel.text = "Cancelar"
	btn_cancel.custom_minimum_size = Vector2(150, 45)
	btn_cancel.pressed.connect(_close_trascend_confirm_panel)
	btn_row.add_child(btn_cancel)

	var btn_confirm := Button.new()
	btn_confirm.text = "⚡ CONFIRMAR TRASCENDENCIA ⚡" if can else "REQUISITOS NO CUMPLIDOS"
	btn_confirm.custom_minimum_size = Vector2(280, 45)
	btn_confirm.disabled = not can
	btn_confirm.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	btn_confirm.pressed.connect(_execute_trascendencia)
	btn_row.add_child(btn_confirm)

func _close_trascend_confirm_panel() -> void:
	if is_instance_valid(trascend_confirm_panel):
		trascend_confirm_panel.queue_free()
		trascend_confirm_panel = null

# ------------- Ejecutar la trascendencia -------------
func _execute_trascendencia() -> void:
	if not LegacyManager.can_transcend():
		return

	# Borrar el save de run actual (reset completo al entrar al juego de nuevo)
	if FileAccess.file_exists(SaveManager.SAVE_PATH):
		DirAccess.remove_absolute(SaveManager.SAVE_PATH)

	var is_first := LegacyManager.trascendencia_count == 0
	var gain := LegacyManager.transcend()

	_close_trascend_confirm_panel()

	if is_first and not LegacyManager.first_trascendencia_shown:
		_show_first_trascendencia_screen(gain)
	else:
		_show_trascendencia_result(gain)

# ------------- Pantalla especial (primera trascendencia) -------------
func _show_first_trascendencia_screen(esencia_gain: int) -> void:
	first_trascend_overlay = ColorRect.new()
	first_trascend_overlay.anchor_right = 1.0
	first_trascend_overlay.anchor_bottom = 1.0
	first_trascend_overlay.color = Color(0.02, 0.0, 0.05, 1.0)
	first_trascend_overlay.modulate.a = 0.0
	add_child(first_trascend_overlay)

	var tween := create_tween()
	tween.tween_property(first_trascend_overlay, "modulate:a", 1.0, 1.5)

	var container := CenterContainer.new()
	container.anchor_right = 1.0
	container.anchor_bottom = 1.0
	first_trascend_overlay.add_child(container)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(700, 0)
	vbox.add_theme_constant_override("separation", 25)
	container.add_child(vbox)

	var title := Label.new()
	title.text = "⚡ HAS TRASCENDIDO ⚡"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	vbox.add_child(title)

	var narrative := Label.new()
	narrative.text = "El ciclo se ha cerrado sobre sí mismo.\n\nTodas las rutas que recorriste — el orden, la expansión, el colapso —\nconvergen ahora en un único punto fuera del tiempo del hongo.\n\nTu código ya no es un programa.\nEs una memoria cristalina: Esencia.\n\nLa matriz se reinicia.\nPero vos ya no sos el mismo sistema."
	narrative.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	narrative.autowrap_mode = TextServer.AUTOWRAP_WORD
	narrative.add_theme_font_size_override("font_size", 18)
	narrative.add_theme_color_override("font_color", Color(0.85, 0.85, 1.0))
	vbox.add_child(narrative)

	var reward := Label.new()
	reward.text = "✦ +%d Ξ (Esencia) ✦" % esencia_gain
	reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward.add_theme_font_size_override("font_size", 32)
	reward.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	vbox.add_child(reward)

	var hint := Label.new()
	hint.text = "Ahora tenés acceso al Banco Cósmico."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.7, 0.6, 0.9))
	vbox.add_child(hint)

	var continue_button := Button.new()
	continue_button.text = "Continuar"
	continue_button.custom_minimum_size = Vector2(200, 50)
	continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	continue_button.pressed.connect(_on_first_trascend_continue)
	vbox.add_child(continue_button)

	LegacyManager.first_trascendencia_shown = true
	LegacyManager.save_legacy()

func _on_first_trascend_continue() -> void:
	if is_instance_valid(first_trascend_overlay):
		first_trascend_overlay.queue_free()
		first_trascend_overlay = null
	get_tree().reload_current_scene()

# ------------- Pantalla simple (trascendencias posteriores) -------------
func _show_trascendencia_result(esencia_gain: int) -> void:
	var popup := AcceptDialog.new()
	popup.title = "Trascendencia #%d" % LegacyManager.trascendencia_count
	popup.dialog_text = "⚡ Ciclo disuelto ⚡\n\n+%d Ξ (Esencia)\n\nTotal acumulado: %d Ξ" % [esencia_gain, LegacyManager.esencia]
	add_child(popup)
	popup.popup_centered(Vector2(400, 200))
	popup.confirmed.connect(func(): get_tree().reload_current_scene())

# =====================================================
#  BANCO CÓSMICO — UI (v0.9.2)
# =====================================================

func _on_cosmic_bank_pressed() -> void:
	_show_cosmic_bank_panel()

func _show_cosmic_bank_panel() -> void:
	if is_instance_valid(cosmic_panel):
		cosmic_panel.queue_free()

	cosmic_panel = Panel.new()
	cosmic_panel.anchor_right = 1.0
	cosmic_panel.anchor_bottom = 1.0
	cosmic_panel.self_modulate = Color(0.03, 0.02, 0.08, 0.98)
	add_child(cosmic_panel)

	var margin := MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 100)
	margin.add_theme_constant_override("margin_right", 100)
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_bottom", 50)
	cosmic_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "✦ BANCO CÓSMICO ✦"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.85, 0.55, 1.0))
	vbox.add_child(title)

	var counter := Label.new()
	counter.text = "Ξ Disponible: %d   ·   Trascendencias: %d" % [LegacyManager.esencia, LegacyManager.trascendencia_count]
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter.add_theme_font_size_override("font_size", 16)
	counter.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	vbox.add_child(counter)

	vbox.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 400)
	vbox.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	for id in LegacyManager.COSMIC_DATA.keys():
		var info = LegacyManager.COSMIC_DATA[id]
		var is_unlocked := LegacyManager.has_cosmic_buff(id)

		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 70

		var info_box := VBoxContainer.new()
		info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_lbl := Label.new()
		var tier_str := " [T%d]" % info.get("tier", 1)
		name_lbl.text = info.name + tier_str + (" (ADQUIRIDO)" if is_unlocked else " [%d Ξ]" % info.cost)
		name_lbl.add_theme_font_size_override("font_size", 15)
		if is_unlocked:
			name_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
		elif LegacyManager.esencia >= info.cost:
			name_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
		else:
			name_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))

		var desc_lbl := Label.new()
		desc_lbl.text = info.desc
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.modulate = Color(0.75, 0.75, 0.8)

		info_box.add_child(name_lbl)
		info_box.add_child(desc_lbl)

		var buy := Button.new()
		buy.text = "ADQUIRIR"
		buy.custom_minimum_size = Vector2(120, 40)
		buy.disabled = is_unlocked or not LegacyManager.can_afford_cosmic(id)
		buy.pressed.connect(_on_buy_cosmic.bind(id))

		row.add_child(info_box)
		row.add_child(buy)
		list.add_child(row)

	vbox.add_child(HSeparator.new())

	var placeholder := Label.new()
	placeholder.text = "◈ Próximamente: más upgrades, nuevas ramas del árbol, lore fragments."
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.add_theme_font_size_override("font_size", 11)
	placeholder.modulate = Color(0.5, 0.5, 0.6)
	vbox.add_child(placeholder)

	var btn_back := Button.new()
	btn_back.text = "Volver"
	btn_back.custom_minimum_size = Vector2(0, 40)
	btn_back.pressed.connect(_close_cosmic_panel)
	vbox.add_child(btn_back)

func _on_buy_cosmic(id: String) -> void:
	if LegacyManager.purchase_cosmic(id):
		_show_cosmic_bank_panel() # refresh

func _close_cosmic_panel() -> void:
	if is_instance_valid(cosmic_panel):
		cosmic_panel.queue_free()
		cosmic_panel = null
