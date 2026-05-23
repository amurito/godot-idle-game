extends Control

@onready var btn_continue = $CenterContainer/VBoxContainer/BtnContinue
@onready var btn_new_game = $CenterContainer/VBoxContainer/BtnNewGame
@onready var btn_achievements = $CenterContainer/VBoxContainer/BtnAchievements
@onready var btn_legacy = $CenterContainer/VBoxContainer/BtnLegacy
@onready var btn_history = $CenterContainer/VBoxContainer/BtnHistory
@onready var achievements_panel = $AchievementsPanel
@onready var achievements_label = $AchievementsPanel/VBoxContainer/ScrollContainer/RichTextLabel

@onready var legacy_panel = $GeneticBankPanel
@onready var pl_counter = $GeneticBankPanel/VBoxContainer/PLCounter
@onready var legacy_list = $GeneticBankPanel/VBoxContainer/ScrollContainer/ItemList

@onready var history_panel = $HistoryPanel
@onready var history_label = $HistoryPanel/VBoxContainer/ScrollContainer/RichTextLabel
@onready var btn_tab_current = $HistoryPanel/VBoxContainer/TabsRow/BtnTabCurrent
@onready var btn_tab_all = $HistoryPanel/VBoxContainer/TabsRow/BtnTabAll

@onready var slot_selector_panel = $SlotSelectorPanel
@onready var slot_list_container = $SlotSelectorPanel/VBoxContainer/ScrollContainer/SlotList
@onready var slot_btn_quit = $SlotSelectorPanel/VBoxContainer/FooterRow/BtnQuit
@onready var center_container = $CenterContainer

# Tab actualmente seleccionada en el panel de historial: "current" o "all"
var _history_tab: String = "current"

# --- TRASCENDENCIA (v0.9.2) ---
# UI creada dinámicamente
var btn_trascendencia: Button = null
var btn_cosmic_bank: Button = null
var trascend_counter_label: Label = null
var trascend_confirm_panel: Panel = null
var cosmic_panel: Panel = null
var first_trascend_overlay: ColorRect = null
var credits_panel: Panel = null
var _credits_close_cb: Callable = Callable()

func _ready():
	# Web: el canvas de Godot tiene su tamaño de render en atributos HTML (canvas.width/height),
	# que Godot gestiona. Nosotros sólo tocamos el CSS display para que se MUESTRE a pantalla
	# completa. No usamos DisplayServer.window_set_size() porque puede leer un innerWidth
	# erróneo y encoger el canvas. CSS !important gana sobre estilos inline del engine.
	if OS.get_name() == "Web":
		# Con canvasResizePolicy=2 (parcheado por fix_web_export.bat post-export),
		# Godot ya redimensiona el canvas al browser nativamente.
		# Este CSS es backup/refuerzo para fondo y overflow.
		JavaScriptBridge.eval("document.body.style.background='#000';document.body.style.overflow='hidden';")

	AudioManager.play_music("ambient")
	if AccessibilityManager.font_scale != 1.0:
		var t := Theme.new()
		t.default_font_size = AccessibilityManager.fs(16)
		self.theme = t
	# Subtitle siempre refleja la versión actual
	$CenterContainer/VBoxContainer/Subtitle.text = "v" + Version.get_version_string()

	# Refrescar UI cuando el usuario cambia idioma
	LocaleManager.locale_changed.connect(_on_locale_changed)

	# Conectar handlers que no dependen del slot
	btn_new_game.pressed.connect(_on_new_game_pressed)
	btn_achievements.pressed.connect(_on_achievements_pressed)
	btn_legacy.pressed.connect(_on_legacy_pressed)
	btn_history.pressed.connect(_on_history_pressed)

	$AchievementsPanel/VBoxContainer/BtnBack.pressed.connect(_on_back_pressed)
	$GeneticBankPanel/VBoxContainer/BtnBackLegacy.pressed.connect(_on_back_pressed)
	$HistoryPanel/VBoxContainer/BtnBack.pressed.connect(_on_back_pressed)
	btn_tab_current.pressed.connect(_on_history_tab_current)
	btn_tab_all.pressed.connect(_on_history_tab_all)
	$CenterContainer/VBoxContainer/BtnQuit.pressed.connect(get_tree().quit)
	slot_btn_quit.pressed.connect(get_tree().quit)

	# Mostrar SlotSelector al arrancar (excepto si veníamos de un reload programático)
	if SlotManager.skip_selector_once:
		SlotManager.skip_selector_once = false
		_show_main_menu()
	else:
		_show_slot_selector()

# Configura los botones del menú principal según el slot activo. Se llama
# después de que el SlotSelector seleccionó/creó/cambió un slot.
func _setup_main_menu_for_active_slot() -> void:
	# Resetear estado del botón Continuar (puede haberse modificado en setups previos)
	btn_continue.disabled = false
	btn_continue.modulate = Color(1, 1, 1, 1)
	if btn_continue.pressed.is_connected(_on_continue_pressed):
		btn_continue.pressed.disconnect(_on_continue_pressed)
	if btn_continue.pressed.is_connected(_start_new_run):
		btn_continue.pressed.disconnect(_start_new_run)

	var has_save := FileAccess.file_exists(SaveManager.SAVE_PATH)
	var post_transcendence := not has_save and LegacyManager.trascendencia_count > 0

	if has_save:
		btn_continue.text = tr("MM_CONTINUE")
		btn_continue.pressed.connect(_on_continue_pressed)
	elif post_transcendence:
		btn_continue.text = EmojiToRichText.strip(tr("MM_NEW_RUN_POSTRANSCEND"))
		btn_continue.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
		btn_continue.pressed.connect(_start_new_run)
	else:
		btn_continue.disabled = true
		btn_continue.modulate = Color(1, 1, 1, 0.4)
		btn_continue.pressed.connect(_on_continue_pressed)

	# Gate del historial: visible solo si compraron memoria_de_run en el Banco Genético
	_refresh_history_gate()

	# --- TRASCENDENCIA UI (si no fue creada todavía) ---
	if btn_trascendencia == null:
		_setup_trascendencia_ui()

	# --- BOTÓN CRÉDITOS (siempre visible, antes de Ajustes y Salir) ---
	if not is_instance_valid(get_node_or_null("CenterContainer/VBoxContainer/BtnCreditos")):
		var btn_credits := Button.new()
		btn_credits.name = "BtnCreditos"
		btn_credits.custom_minimum_size = Vector2(0, 40)
		btn_credits.text = tr("MM_CREDITS")
		btn_credits.pressed.connect(func(): _show_credits_panel())
		var vbox_c := $CenterContainer/VBoxContainer as VBoxContainer
		vbox_c.add_child(btn_credits)
		vbox_c.move_child(btn_credits, vbox_c.get_child_count() - 2)

	# --- BOTÓN AJUSTES (siempre visible, justo antes de Salir) ---
	if not is_instance_valid(get_node_or_null("CenterContainer/VBoxContainer/BtnSettings")):
		var btn_settings := Button.new()
		btn_settings.name = "BtnSettings"
		btn_settings.custom_minimum_size = Vector2(0, 45)
		btn_settings.text = tr("MM_SETTINGS")
		btn_settings.pressed.connect(func(): AudioManager.show_settings_panel(self))
		var vbox_s = $CenterContainer/VBoxContainer
		vbox_s.add_child(btn_settings)
		vbox_s.move_child(btn_settings, vbox_s.get_child_count() - 2)

	# --- BOTÓN TELEMETRÍA (solo en debug) ---
	if OS.is_debug_build() and not is_instance_valid(get_node_or_null("CenterContainer/VBoxContainer/BtnTools")):
		var btn_tools := Button.new()
		btn_tools.name = "BtnTools"
		btn_tools.custom_minimum_size = Vector2(0, 40)
		btn_tools.text = tr("MM_TOOLS")
		btn_tools.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
		btn_tools.pressed.connect(_on_tools_analyze_pressed)
		var vbox_t = $CenterContainer/VBoxContainer
		vbox_t.add_child(btn_tools)
		vbox_t.move_child(btn_tools, vbox_t.get_child_count() - 2)

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
		dialog.title = tr("MM_NEW_RUN_TITLE")
		dialog.dialog_text = EmojiToRichText.strip(
			tr("MM_NEW_RUN_TEXT") % [LegacyManager.esencia, LegacyManager.legacy_points])
		dialog.get_ok_button().text = EmojiToRichText.strip(tr("MM_NEW_RUN_OK"))
		dialog.get_cancel_button().text = tr("MM_BACK")
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
	title.text = EmojiToRichText.strip("⚡ CICLO #%d -- ELIGE TU RUTA" % (LegacyManager.trascendencia_count + 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", AccessibilityManager.fs(28))
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = tr("MM_ROUTE_PICKER_SUBTITLE")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", AccessibilityManager.fs(13))
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.85))
	vbox.add_child(subtitle)

	vbox.add_child(HSeparator.new())

	var ROUTES := [
		{
			"id": "", "icon": "▶",
			"name": tr("ROUTE_CICLO_ESTANDAR"),
			"color": Color(0.7, 0.7, 0.7),
			"desc": tr("ROUTE_CICLO_DESC"),
		},
		{
			"id": "vacio", "icon": "🕳️",
			"name": tr("ROUTE_VACIO_HAMBRIENTO"),
			"color": Color(0.55, 0.0, 0.8),
			"desc": tr("ROUTE_VACIO_DESC"),
		},
		{
			"id": "carnaval", "icon": "🎭",
			"name": tr("ROUTE_CARNAVAL"),
			"color": Color(1.0, 0.4, 0.1),
			"desc": tr("ROUTE_CARNAVAL_DESC"),
		},
		{
			"id": "reencarnacion", "icon": "⚱️",
			"name": tr("ROUTE_REENCARNACION"),
			"color": Color(0.3, 0.9, 0.6),
			"desc": tr("ROUTE_REENCARNACION_DESC"),
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

		btn.text = EmojiToRichText.strip("%s  %s\n%s" % [route.icon, route.name, route.desc])
		btn.add_theme_color_override("font_color", route.color)
		btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(13))
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD

		var route_id: String = route.id
		btn.pressed.connect(func():
			overlay.queue_free()
			_do_start_new_run(route_id)
		)
		vbox.add_child(btn)

	var btn_cancel := Button.new()
	btn_cancel.text = "← " + tr("MM_BACK")
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
	var ach_name := tr("MM_ACHIEVEMENTS")
	btn_achievements.text = EmojiToRichText.strip("★ " + ach_name.to_upper() if has_new_ach else ach_name)

	var has_new_buff: bool = LegacyManager.has_unseen_buff()
	var legacy_name := tr("MM_LEGACY_BANK")
	btn_legacy.text = EmojiToRichText.strip("★ " + legacy_name.to_upper() if has_new_buff else legacy_name)

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
	history_panel.visible = false
	# Actualizar badges + gate al cerrar (puede haberse comprado memoria_de_run)
	_refresh_nav_badges()
	_refresh_history_gate()

# ===================== SLOT SELECTOR =====================
func _show_slot_selector() -> void:
	slot_selector_panel.visible = true
	center_container.visible = false
	achievements_panel.visible = false
	legacy_panel.visible = false
	history_panel.visible = false
	_refresh_slot_list()

func _show_main_menu() -> void:
	slot_selector_panel.visible = false
	center_container.visible = true
	_setup_main_menu_for_active_slot()

func _refresh_slot_list() -> void:
	for child in slot_list_container.get_children():
		child.queue_free()
	# Renderizar slots existentes
	for s in SlotManager.list_slots():
		_add_slot_card(s)
	# Renderizar slots vacíos disponibles para crear
	var empty_remaining := SlotManager.available_empty_slots()
	for i in range(empty_remaining):
		_add_empty_slot_card()
	# Mensaje si llegó al límite y no tiene más por desbloquear
	if empty_remaining == 0:
		_add_unlock_hint_label()

func _add_slot_card(slot_data: Dictionary) -> void:
	var slot_id: String = slot_data.get("id", "")
	var slot_name: String = slot_data.get("name", slot_id)
	var summary: Dictionary = SlotManager.read_slot_summary(slot_id)
	var has_save: bool = SlotManager.slot_has_savegame(slot_id)
	var is_active: bool = (slot_id == SlotManager.active_slot)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 90)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(hbox)

	# Bloque de info (izquierda)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	hbox.add_child(info)

	var name_label := Label.new()
	name_label.text = slot_name + ("  [activo]" if is_active else "")
	name_label.add_theme_font_size_override("font_size", AccessibilityManager.fs(20))
	name_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	info.add_child(name_label)

	var stats := Label.new()
	stats.add_theme_font_size_override("font_size", AccessibilityManager.fs(13))
	stats.add_theme_color_override("font_color", Color(0.65, 0.7, 0.78))
	if summary.exists:
		var last: String = summary.last_ending if summary.last_ending != "" else "—"
		stats.text = tr("SLOT_STATS_FORMAT") % [
			summary.t_count, summary.total_runs, summary.esencia, last,
		]
	else:
		stats.text = tr("SLOT_STATS_EMPTY")
	info.add_child(stats)

	# Botones (derecha)
	var btn_select := Button.new()
	btn_select.text = tr("MM_CONTINUE") if has_save else tr("SLOT_START")
	btn_select.custom_minimum_size = Vector2(110, 60)
	btn_select.pressed.connect(_on_slot_chosen.bind(slot_id))
	hbox.add_child(btn_select)

	var btn_rename := Button.new()
	btn_rename.text = tr("SLOT_RENAME_BTN")
	btn_rename.custom_minimum_size = Vector2(100, 60)
	btn_rename.pressed.connect(_on_slot_rename.bind(slot_id))
	hbox.add_child(btn_rename)

	var btn_delete := Button.new()
	btn_delete.text = tr("SLOT_DELETE_BTN")
	btn_delete.custom_minimum_size = Vector2(80, 60)
	btn_delete.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	btn_delete.pressed.connect(_on_slot_delete.bind(slot_id))
	# No dejar borrar el último slot (regla de SlotManager.delete_slot)
	if SlotManager.list_slots().size() <= 1:
		btn_delete.disabled = true
		btn_delete.tooltip_text = tr("SLOT_NO_DELETE_LAST")
	hbox.add_child(btn_delete)

	slot_list_container.add_child(card)

func _add_empty_slot_card() -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 70)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(hbox)

	var info := Label.new()
	info.text = tr("SLOT_EMPTY_LABEL")
	info.add_theme_font_size_override("font_size", AccessibilityManager.fs(16))
	info.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(info)

	var btn_create := Button.new()
	btn_create.text = tr("SLOT_CREATE_BTN")
	btn_create.custom_minimum_size = Vector2(140, 50)
	btn_create.add_theme_color_override("font_color", Color(0.5, 1.0, 0.7))
	btn_create.pressed.connect(_on_slot_create_pressed)
	hbox.add_child(btn_create)

	slot_list_container.add_child(card)

func _add_unlock_hint_label() -> void:
	var label := Label.new()
	label.text = tr("SLOT_UNLOCK_HINT")
	label.add_theme_font_size_override("font_size", AccessibilityManager.fs(13))
	label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	slot_list_container.add_child(label)

func _on_slot_chosen(slot_id: String) -> void:
	if slot_id == SlotManager.active_slot:
		_show_main_menu()
		return
	SlotManager.switch_slot(slot_id)
	# Recargar Legacy en memoria para el nuevo slot (los autoloads persisten entre reloads)
	LegacyManager.reload_for_slot()
	SlotManager.skip_selector_once = true
	get_tree().reload_current_scene()

func _on_slot_create_pressed() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = tr("SLOT_NEW_TITLE")
	dialog.dialog_hide_on_ok = false
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	var lbl := Label.new()
	lbl.text = tr("SLOT_NEW_NAME_LABEL")
	vbox.add_child(lbl)
	var line := LineEdit.new()
	line.placeholder_text = "Ej: Run de prueba"
	line.custom_minimum_size = Vector2(280, 0)
	vbox.add_child(line)
	dialog.add_child(vbox)
	dialog.register_text_enter(line)
	add_child(dialog)
	dialog.popup_centered(Vector2(360, 140))
	line.grab_focus.call_deferred()
	dialog.confirmed.connect(func():
		var slot_name: String = line.text
		var new_id: String = SlotManager.create_slot(slot_name)
		if new_id != "":
			SlotManager.switch_slot(new_id)
			LegacyManager.reload_for_slot()
			SlotManager.skip_selector_once = true
			dialog.queue_free()
			get_tree().reload_current_scene()
		else:
			dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)

func _on_slot_rename(slot_id: String) -> void:
	var current_name := ""
	for s in SlotManager.list_slots():
		if s.get("id", "") == slot_id:
			current_name = s.get("name", "")
			break
	var dialog := AcceptDialog.new()
	dialog.title = tr("SLOT_RENAME_TITLE")
	dialog.dialog_hide_on_ok = false
	var vbox := VBoxContainer.new()
	var lbl := Label.new()
	lbl.text = tr("SLOT_RENAME_NAME_LABEL")
	vbox.add_child(lbl)
	var line := LineEdit.new()
	line.text = current_name
	line.custom_minimum_size = Vector2(280, 0)
	vbox.add_child(line)
	dialog.add_child(vbox)
	dialog.register_text_enter(line)
	add_child(dialog)
	dialog.popup_centered(Vector2(360, 140))
	line.grab_focus.call_deferred()
	line.select_all.call_deferred()
	dialog.confirmed.connect(func():
		SlotManager.rename_slot(slot_id, line.text)
		dialog.queue_free()
		_refresh_slot_list()
	)
	dialog.canceled.connect(dialog.queue_free)

func _on_slot_delete(slot_id: String) -> void:
	var slot_name := slot_id
	for s in SlotManager.list_slots():
		if s.get("id", "") == slot_id:
			slot_name = s.get("name", slot_id)
			break
	var confirm := ConfirmationDialog.new()
	confirm.title = tr("SLOT_DELETE_TITLE")
	confirm.dialog_text = tr("SLOT_DELETE_TEXT") % slot_name
	confirm.get_ok_button().text = tr("SLOT_DELETE_OK")
	confirm.get_cancel_button().text = tr("BTN_CANCEL")
	add_child(confirm)
	confirm.popup_centered(Vector2(440, 200))
	confirm.confirmed.connect(func():
		var was_active := slot_id == SlotManager.active_slot
		var deleted := SlotManager.delete_slot(slot_id)
		confirm.queue_free()
		if not deleted:
			return
		if was_active:
			# El slot activo cambió: reload para refrescar legacy en memoria
			SlotManager.skip_selector_once = false  # Volver a mostrar selector
			get_tree().reload_current_scene()
		else:
			_refresh_slot_list()
	)
	confirm.canceled.connect(confirm.queue_free)

# ===================== HISTORIAL DE CICLOS =====================
func _refresh_history_gate() -> void:
	var unlocked: bool = LegacyManager.has_run_history_unlocked()
	btn_history.visible = unlocked

func _on_history_pressed() -> void:
	history_panel.visible = true
	_history_tab = "current"
	btn_tab_current.button_pressed = true
	btn_tab_all.button_pressed = false
	_update_history_view()

func _on_history_tab_current() -> void:
	_history_tab = "current"
	btn_tab_current.button_pressed = true
	btn_tab_all.button_pressed = false
	_update_history_view()

func _on_history_tab_all() -> void:
	_history_tab = "all"
	btn_tab_current.button_pressed = false
	btn_tab_all.button_pressed = true
	_update_history_view()

# Familia de la ruta → color del card. Reusa LegacyManager.ENDING_FAMILIES.
const _HISTORY_FAMILY_COLORS := {
	"orden":    {"card": "#0e1a2e", "title": "#7ad6ff"},
	"biologia": {"card": "#0e2418", "title": "#7affae"},
	"colapso":  {"card": "#2e0e14", "title": "#ff7a8a"},
}
const _HISTORY_DEFAULT_COLORS := {"card": "#1a1a22", "title": "#cccccc"}

func _format_run_time(seconds: float) -> String:
	var s: int = int(seconds)
	var h: int = int(s / 3600.0)
	var m: int = int((s % 3600) / 60.0)
	var sec: int = s % 60
	if h > 0:
		return "%d:%02d:%02d" % [h, m, sec]
	return "%d:%02d" % [m, sec]

func _update_history_view() -> void:
	var entries: Array
	var header_label: String
	if _history_tab == "current":
		entries = LegacyManager.current_cycle_history
		header_label = tr("HIST_CURRENT_CYCLE") % LegacyManager.trascendencia_count
	else:
		entries = LegacyManager.all_time_history
		header_label = tr("HIST_HEADER_ALL")

	var t: String = "[center][color=#9adfff][b]═══ %s ═══[/b][/color]\n" % header_label
	t += "[color=#888888]" + tr("HIST_CYCLE_COUNT") % entries.size() + "[/color][/center]\n\n"

	if entries.is_empty():
		t += "[center][color=#666666][i]" + tr("HIST_EMPTY") + "[/i][/color][/center]"
		history_label.clear()
		history_label.append_text(EmojiToRichText.rich(t))
		return

	# Mostrar más reciente arriba
	for i in range(entries.size() - 1, -1, -1):
		var e: Dictionary = entries[i]
		var route: String = e.get("route", "NONE")
		var reason: String = e.get("reason", "")
		var run_time: float = e.get("run_time", 0.0)
		var mu_peak: float = e.get("mu_peak", 0.0)
		var eps_peak: float = e.get("eps_peak", 0.0)
		var pl_gained: int = e.get("pl_gained", 0)
		var cycle_index: int = e.get("cycle_index", 0)
		var t_tier: int = e.get("trascendencia_tier", 0)

		var family: String = LegacyManager.ENDING_FAMILIES.get(route, "")
		var colors: Dictionary = _HISTORY_FAMILY_COLORS.get(family, _HISTORY_DEFAULT_COLORS)

		var tier_badge: String = ""
		if _history_tab == "all":
			tier_badge = "  [color=#888888][T%d][/color]" % t_tier

		t += "[table=1]"
		var cycle_title: String = tr("HIST_CYCLE_ENTRY") % [cycle_index, route]
		t += "[cell bgcolor=%s][b][color=%s]%s[/color][/b]%s\n" % \
			[colors.card, colors.title, cycle_title, tier_badge]
		if reason != "":
			t += "[color=#aaaaaa][i]%s[/i][/color]\n" % reason
		t += "[color=#888888]⏱ %s · μ_peak %.2f · ε_peak %.2f · +%d PL[/color][/cell]" % \
			[_format_run_time(run_time), mu_peak, eps_peak, pl_gained]
		t += "[/table]\n\n"

	history_label.clear()
	history_label.append_text(EmojiToRichText.rich(t))

func _update_legacy_view():
	pl_counter.text = tr("BANK_LEGACY_COUNTER") % [LegacyManager.legacy_points, LegacyManager.total_runs]
	for child in legacy_list.get_children():
		child.queue_free()
	call_deferred("_populate_legacy_items")

func _populate_legacy_items():
	var col_groups: Array = [
		["economia"],
		["estructura"],
		["biologia", "conocimiento"],
		["ruta"],
		["ng_plus", "secreto"],
	]
	var cat_colors: Dictionary = {
		"economia": Color(0.9, 0.85, 0.4), "estructura": Color(0.5, 0.8, 1.0),
		"biologia": Color(0.4, 0.9, 0.5),  "conocimiento": Color(0.8, 0.6, 1.0),
		"ruta": Color(1.0, 0.65, 0.2),     "ng_plus": Color(0.9, 0.3, 0.9),
		"secreto": Color(0.5, 0.5, 0.5),
	}

	var h_cols: HBoxContainer = HBoxContainer.new()
	h_cols.add_theme_constant_override("separation", 10)
	h_cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	legacy_list.add_child(h_cols)

	for group in col_groups:
		var col: VBoxContainer = VBoxContainer.new()
		col.custom_minimum_size.x = 300
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 3)
		var col_has_items: bool = false

		for cat in group:
			var cat_ids: Array = []
			for id in LegacyManager.LEGACY_DEFS:
				var def: Dictionary = LegacyManager.LEGACY_DEFS[id]
				if def.get("cat", "") == cat and LegacyManager.is_revealed(id):
					cat_ids.append(id)
			if cat_ids.is_empty():
				continue
			if col_has_items:
				col.add_child(HSeparator.new())
			var hdr: Label = Label.new()
			hdr.text = "-- %s --" % tr("LEGACY_CAT_" + cat.to_upper())
			hdr.add_theme_font_size_override("font_size", AccessibilityManager.fs(12))
			hdr.modulate = cat_colors.get(cat, Color.WHITE)
			hdr.custom_minimum_size.y = 26
			col.add_child(hdr)

			for id in cat_ids:
				var def: Dictionary = LegacyManager.LEGACY_DEFS[id]
				var lvl: int = LegacyManager.get_buff_level(id)
				var max_lvl: int = int(def.get("max_level", 1))
				var is_maxed: bool = lvl >= max_lvl
				var unlockable: bool = LegacyManager.is_unlockable(id)
				var cost: int = LegacyManager.get_current_cost(id)
				var affordable: bool = LegacyManager.legacy_points >= cost
				var is_new: bool = lvl > 0 and not (LegacyManager.buffs.get(id, {}) as Dictionary).get("seen", true)

				var container: VBoxContainer = VBoxContainer.new()
				container.add_theme_constant_override("separation", 1)

				var name_str: String = tr("LEGACY_" + id.to_upper() + "_NAME")
				if max_lvl > 1:
					name_str += "  [%d/%d]" % [lvl, max_lvl]
				if is_new:
					name_str += "  " + tr("ACH_BADGE_NEW")

				var name_lbl: Label = Label.new()
				name_lbl.text = name_str
				name_lbl.add_theme_font_size_override("font_size", AccessibilityManager.fs(11))
				name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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

				var flavor_lbl: Label = Label.new()
				flavor_lbl.text = tr("LEGACY_" + id.to_upper() + "_FLAVOR")
				flavor_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				flavor_lbl.add_theme_font_size_override("font_size", AccessibilityManager.fs(9))
				flavor_lbl.modulate = Color(0.55, 0.55, 0.55)

				container.add_child(name_lbl)
				container.add_child(flavor_lbl)

				var buy_btn: Button = Button.new()
				buy_btn.custom_minimum_size.y = 22
				if is_maxed:
					buy_btn.text = tr("BANK_BTN_MAX")
					buy_btn.disabled = true
				elif not unlockable:
					buy_btn.text = tr("BANK_BTN_LOCKED")
					buy_btn.disabled = true
				elif lvl == 0:
					buy_btn.text = tr("BANK_BTN_ACQUIRE") if def.get("cost", 0) == 0 else "%d PL" % cost
					buy_btn.disabled = (def.get("cost", 0) > 0 and not affordable)
				else:
					buy_btn.text = tr("BANK_BTN_LEVEL") % [lvl + 1, cost]
					buy_btn.disabled = not affordable
				buy_btn.pressed.connect(_on_buy_legacy.bind(id))

				container.add_child(buy_btn)
				container.add_child(HSeparator.new())
				col.add_child(container)

				if is_new:
					LegacyManager.mark_buff_seen(id)

			col_has_items = true

		if col_has_items:
			h_cols.add_child(col)
		else:
			col.queue_free()

	var wip_lbl := Label.new()
	wip_lbl.text = tr("BANK_WIP_NOTICE")
	wip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wip_lbl.add_theme_font_size_override("font_size", AccessibilityManager.fs(10))
	wip_lbl.modulate = Color(0.5, 0.5, 0.6)
	legacy_list.add_child(wip_lbl)

func _on_buy_legacy(id: String):
	if LegacyManager.purchase_legacy(id):
		_update_legacy_view()

func _update_achievements_view():
	var total: int = AchievementManager.total_count()
	var got: int = AchievementManager.unlocked_count()

	var t: String = "[center][color=#ffcc00][b]═══ " + tr("ACH_PANEL_TITLE") + " ═══[/b][/color]\n"
	t += "[color=#888888]" + tr("ACH_PANEL_UNLOCKED") % [got, total] + "[/color][/center]\n\n"

	var tier_order := [
		AchievementManager.Tier.MICELIO,
		AchievementManager.Tier.ESPORA,
		AchievementManager.Tier.FRUTO,
		AchievementManager.Tier.ANCESTRAL,
		AchievementManager.Tier.MYTHIC,
	]
	var tier_colors := {
		AchievementManager.Tier.MICELIO:   "#b77841",
		AchievementManager.Tier.ESPORA:    "#e0e0e5",
		AchievementManager.Tier.FRUTO:     "#ffcc40",
		AchievementManager.Tier.ANCESTRAL: "#d93a4d",
		AchievementManager.Tier.MYTHIC:    "#8c1ad9",
	}

	for tier in tier_order:
		var ids: Array = AchievementManager.get_by_tier(tier)
		var tier_name: String = AchievementManager.TIER_NAMES[tier]
		var tier_icon: String = AchievementManager.TIER_ICONS[tier]
		var color: String = tier_colors[tier]
		var ok: int = 0
		for id in ids:
			if AchievementManager.is_unlocked(id): ok += 1

		t += "[color=%s][b]%s %s[/b][/color]  [color=#555555]%d / %d[/color]\n\n" \
			% [color, tier_icon, tier_name, ok, ids.size()]

		for id in ids:
			var def: Dictionary = AchievementManager.DEFS[id]
			var unlocked_one: bool = AchievementManager.is_unlocked(id)
			var is_secret: bool = def.get("secret", false)
			var name_str: String = AchievementManager.get_display_name(id)
			var desc_str: String = AchievementManager.get_display_desc(id)

			var icon_char: String
			var title_color: String
			var desc_color: String
			var card_bg: String
			var icon_bg: String

			if unlocked_one:
				icon_char = tier_icon
				title_color = "#ffcc44"
				desc_color = "#aaaaaa"
				card_bg = "#111a2e"
				icon_bg = "#1e3050"
			elif is_secret:
				icon_char = "?"
				title_color = "#3a3a3a"
				desc_color = "#2a2a2a"
				card_bg = "#090d15"
				icon_bg = "#0d1220"
			else:
				icon_char = tier_icon
				title_color = "#666666"
				desc_color = "#444444"
				card_bg = "#0c1422"
				icon_bg = "#101828"

			t += "[table=2]"
			t += "[cell bgcolor=%s][center][font_size=30]%s[/font_size][/center][/cell]" % [icon_bg, icon_char]

			if unlocked_one:
				var entry: Dictionary = AchievementManager.unlocked.get(id, {})
				var is_new: bool = not entry.get("seen", true)
				var new_badge: String = "  [color=#ffdd00][b]" + tr("ACH_BADGE_NEW") + "[/b][/color]" if is_new else ""
				t += "[cell bgcolor=%s][b][color=%s]%s[/color]%s[/b]\n[color=%s][i]%s[/i][/color][/cell]" % \
					[card_bg, title_color, name_str, new_badge, desc_color, desc_str]
				if is_new:
					AchievementManager.mark_seen(id)
			elif is_secret:
				t += "[cell bgcolor=%s][b][color=%s]??? [i](%s)[/i][/color][/b][/cell]" % \
					[card_bg, title_color, tr("ACH_PANEL_HIDDEN")]
			else:
				var progress_str: String = _build_progress_str(id, def)
				t += "[cell bgcolor=%s][b][color=%s]%s[/color][/b]%s\n[color=%s][i]%s[/i][/color][/cell]" % \
					[card_bg, title_color, name_str, progress_str, desc_color, desc_str]

			t += "[/table]\n\n"

		t += "\n"

	achievements_label.clear()
	achievements_label.append_text(EmojiToRichText.rich(t))

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
	var fmt: String = tr(def["progress_key"]) if def.has("progress_key") else "{current} / {target}"
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
		btn_new_game.text = tr("MM_NEW_RUN")
		btn_new_game.tooltip_text = tr("MM_NEW_RUN_TOOLTIP")
	else:
		btn_new_game.text = tr("MM_NEW_GAME")
		btn_new_game.tooltip_text = ""

	# 1. Actualizar Subtitle con título cósmico (si aplica)
	var subtitle = $CenterContainer/VBoxContainer/Subtitle
	var title_cosmic = LegacyManager.get_trascendencia_title()
	if title_cosmic != "":
		subtitle.text = EmojiToRichText.strip("✦ " + title_cosmic + " ✦  ·  v" + Version.get_version_string())
		subtitle.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))

	# 2. Contador de Esencia (visible solo si ya trascendió alguna vez)
	if LegacyManager.trascendencia_count > 0:
		trascend_counter_label = Label.new()
		trascend_counter_label.text = tr("MM_TRANSCEND_COUNTER") % [LegacyManager.esencia, LegacyManager.trascendencia_count]
		trascend_counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		trascend_counter_label.add_theme_color_override("font_color", Color(0.85, 0.55, 1.0))
		trascend_counter_label.add_theme_font_size_override("font_size", AccessibilityManager.fs(14))
		var vbox = $CenterContainer/VBoxContainer
		vbox.add_child(trascend_counter_label)
		vbox.move_child(trascend_counter_label, 3) # Después del HSeparator

	# 3. Botón TRASCENDER (entre Legacy y Quit)
	btn_trascendencia = Button.new()
	btn_trascendencia.custom_minimum_size = Vector2(0, 45)
	btn_trascendencia.text = EmojiToRichText.strip(tr("MM_TRANSCEND_BTN"))
	btn_trascendencia.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	btn_trascendencia.add_theme_font_size_override("font_size", AccessibilityManager.fs(16))
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
		btn_cosmic_bank.text = EmojiToRichText.strip("✦ " + tr("MM_COSMIC_BANK"))
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
	title.text = EmojiToRichText.strip("⚡ TRASCENDENCIA ⚡")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", AccessibilityManager.fs(36))
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	vbox.add_child(title)

	var subtitle_lbl := Label.new()
	subtitle_lbl.text = tr("TRAS_SUBTITLE")
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_lbl.add_theme_font_size_override("font_size", AccessibilityManager.fs(14))
	subtitle_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	vbox.add_child(subtitle_lbl)

	vbox.add_child(HSeparator.new())

	var gate_title := Label.new()
	gate_title.text = tr("TRAS_GATE_TITLE")
	gate_title.add_theme_font_size_override("font_size", AccessibilityManager.fs(18))
	gate_title.add_theme_color_override("font_color", Color(0.85, 0.85, 1.0))
	vbox.add_child(gate_title)

	var gate_status := Label.new()
	gate_status.text = EmojiToRichText.strip(LegacyManager.get_transcend_gate_status())
	gate_status.add_theme_font_size_override("font_size", AccessibilityManager.fs(13))
	vbox.add_child(gate_status)

	vbox.add_child(HSeparator.new())

	var reward_title := Label.new()
	reward_title.text = tr("TRAS_REWARD_TITLE")
	reward_title.add_theme_font_size_override("font_size", AccessibilityManager.fs(18))
	reward_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(reward_title)

	var can := LegacyManager.can_transcend()
	var esencia_gain := LegacyManager.calculate_esencia_gain() if can else 0

	var reward := Label.new()
	if can:
		reward.text = tr("TRAS_REWARD_TEXT") % [
			esencia_gain,
			LegacyManager.legacy_points,
			LegacyManager.unique_endings_count(),
			LegacyManager.trascendencia_count * 2
		]
		reward.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	else:
		reward.text = tr("TRAS_LOCKED_TEXT") % LegacyManager.TRASCENDENCIA_PL_GATE
		reward.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	reward.add_theme_font_size_override("font_size", AccessibilityManager.fs(13))
	vbox.add_child(reward)

	vbox.add_child(HSeparator.new())

	var warn := Label.new()
	warn.text = EmojiToRichText.strip(tr("TRAS_WARN"))
	warn.autowrap_mode = TextServer.AUTOWRAP_WORD
	warn.add_theme_font_size_override("font_size", AccessibilityManager.fs(12))
	warn.add_theme_color_override("font_color", Color(0.85, 0.7, 0.5))
	vbox.add_child(warn)

	vbox.add_child(Control.new()) # Spacer

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	var btn_cancel := Button.new()
	btn_cancel.text = tr("BTN_CANCEL")
	btn_cancel.custom_minimum_size = Vector2(150, 45)
	btn_cancel.pressed.connect(_close_trascend_confirm_panel)
	btn_row.add_child(btn_cancel)

	var btn_confirm := Button.new()
	btn_confirm.text = EmojiToRichText.strip(tr("MM_TRANSCEND_CONFIRM") if can else tr("MM_TRANSCEND_LOCKED_BTN"))
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
	AudioManager.play_sfx("transcend")

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

	if AccessibilityManager.reduce_motion:
		first_trascend_overlay.modulate.a = 1.0
	else:
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
	title.text = EmojiToRichText.strip("⚡ HAS TRASCENDIDO ⚡")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", AccessibilityManager.fs(56))
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	vbox.add_child(title)

	var narrative := Label.new()
	narrative.text = tr("TRAS_FIRST_NARRATIVE")
	narrative.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	narrative.autowrap_mode = TextServer.AUTOWRAP_WORD
	narrative.add_theme_font_size_override("font_size", AccessibilityManager.fs(18))
	narrative.add_theme_color_override("font_color", Color(0.85, 0.85, 1.0))
	vbox.add_child(narrative)

	var reward := Label.new()
	reward.text = EmojiToRichText.strip("✦ +%d Ξ (Esencia) ✦" % esencia_gain)
	reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward.add_theme_font_size_override("font_size", AccessibilityManager.fs(32))
	reward.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	vbox.add_child(reward)

	var hint := Label.new()
	hint.text = tr("TRAS_FIRST_HINT")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", AccessibilityManager.fs(14))
	hint.add_theme_color_override("font_color", Color(0.7, 0.6, 0.9))
	vbox.add_child(hint)

	var continue_button := Button.new()
	continue_button.text = tr("MM_CONTINUE")
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
	_show_credits_panel(func(): get_tree().reload_current_scene())

# ------------- Pantalla simple (trascendencias posteriores) -------------
func _show_trascendencia_result(esencia_gain: int) -> void:
	var popup := AcceptDialog.new()
	popup.title = "Trascendencia #%d" % LegacyManager.trascendencia_count
	popup.dialog_text = EmojiToRichText.strip("⚡ Ciclo disuelto ⚡\n\n+%d Ξ (Esencia)\n\nTotal acumulado: %d Ξ" % [esencia_gain, LegacyManager.esencia])
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
	title.text = EmojiToRichText.strip("✦ " + tr("COSMIC_BANK_TITLE") + " ✦")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", AccessibilityManager.fs(30))
	title.add_theme_color_override("font_color", Color(0.85, 0.55, 1.0))
	vbox.add_child(title)

	var counter := Label.new()
	counter.text = tr("COSMIC_BANK_COUNTER") % [LegacyManager.esencia, LegacyManager.trascendencia_count]
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter.add_theme_font_size_override("font_size", AccessibilityManager.fs(16))
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
		var acquired_str := " (" + tr("COSMIC_ACQUIRED") + ")" if is_unlocked else " [%d Ξ]" % info.cost
		name_lbl.text = tr("COSMIC_" + id.to_upper() + "_NAME") + tier_str + acquired_str
		name_lbl.add_theme_font_size_override("font_size", AccessibilityManager.fs(15))
		if is_unlocked:
			name_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
		elif LegacyManager.esencia >= info.cost:
			name_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
		else:
			name_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))

		var desc_lbl := Label.new()
		desc_lbl.text = tr("COSMIC_" + id.to_upper() + "_DESC")
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_lbl.add_theme_font_size_override("font_size", AccessibilityManager.fs(11))
		desc_lbl.modulate = Color(0.75, 0.75, 0.8)

		info_box.add_child(name_lbl)
		info_box.add_child(desc_lbl)

		var buy := Button.new()
		buy.text = tr("BANK_BTN_ACQUIRE")
		buy.custom_minimum_size = Vector2(120, 40)
		buy.disabled = is_unlocked or not LegacyManager.can_afford_cosmic(id)
		buy.pressed.connect(_on_buy_cosmic.bind(id))

		row.add_child(info_box)
		row.add_child(buy)
		list.add_child(row)

	vbox.add_child(HSeparator.new())

	var placeholder := Label.new()
	placeholder.text = tr("COSMIC_COMING_SOON")
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.add_theme_font_size_override("font_size", AccessibilityManager.fs(11))
	placeholder.modulate = Color(0.5, 0.5, 0.6)
	vbox.add_child(placeholder)

	var btn_back := Button.new()
	btn_back.text = tr("MM_BACK")
	btn_back.custom_minimum_size = Vector2(0, 40)
	btn_back.pressed.connect(_close_cosmic_panel)
	vbox.add_child(btn_back)

# =====================================================
#  TOOLS — Telemetría (solo debug)
# =====================================================

func _on_tools_analyze_pressed() -> void:
	var btn_tools := get_node_or_null("CenterContainer/VBoxContainer/BtnTools")
	if not is_instance_valid(btn_tools):
		return

	var script_path := ProjectSettings.globalize_path("res://tools/analyze_telemetry.py")
	var runs_dir    := OS.get_user_data_dir() + "/telemetry/runs"
	const URL       := "http://localhost:8421/"

	btn_tools.text = "Iniciando..."
	btn_tools.disabled = true

	# Lanza el servidor en proceso separado (no bloquea — queda corriendo en background).
	# Si el puerto ya está ocupado, el script lo detecta y no rompe.
	OS.create_process("python", [script_path, runs_dir, "--serve"])

	# Abrir browser después de 2.5 s (startup del servidor)
	get_tree().create_timer(2.5).timeout.connect(func():
		if is_instance_valid(btn_tools):
			btn_tools.text = "Telemetria"
			btn_tools.disabled = false
		OS.shell_open(URL)
	)


func _on_buy_cosmic(id: String) -> void:
	if LegacyManager.purchase_cosmic(id):
		_show_cosmic_bank_panel() # refresh

func _close_cosmic_panel() -> void:
	if is_instance_valid(cosmic_panel):
		cosmic_panel.queue_free()
		cosmic_panel = null


# =====================================================
#  CRÉDITOS — scroll animado (estilo película)
# =====================================================

func _show_credits_panel(on_close: Callable = Callable()) -> void:
	if is_instance_valid(credits_panel):
		credits_panel.queue_free()
	_credits_close_cb = on_close

	# Fondo completamente opaco, sin transparencia
	credits_panel = Panel.new()
	credits_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.02, 0.02, 0.05, 1.0)
	credits_panel.add_theme_stylebox_override("panel", bg)
	add_child(credits_panel)

	# Contenedor con clipping (oculta el texto fuera de pantalla)
	var clip := Control.new()
	clip.set_anchors_preset(Control.PRESET_FULL_RECT)
	clip.clip_children = Control.CLIP_CHILDREN_ONLY
	credits_panel.add_child(clip)

	# VBox que se va a desplazar hacia arriba
	var content := VBoxContainer.new()
	content.custom_minimum_size.x = 540
	content.add_theme_constant_override("separation", 6)
	clip.add_child(content)

	# ── Contenido de los créditos ──────────────────────

	_credits_spacer(content, 100)

	var title_lbl := Label.new()
	title_lbl.text = "AntiIDLE"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", AccessibilityManager.fs(52))
	title_lbl.add_theme_color_override("font_color", Color(0.25, 0.82, 1.0))
	content.add_child(title_lbl)

	var ver_lbl := Label.new()
	ver_lbl.text = Version.TITLE
	ver_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver_lbl.add_theme_font_size_override("font_size", AccessibilityManager.fs(14))
	ver_lbl.add_theme_color_override("font_color", Color(0.3, 0.4, 0.55))
	content.add_child(ver_lbl)

	_credits_spacer(content, 80)

	_credits_row(content, "DESARROLLO")
	_credits_name(content, "Nicolás Maure", 22)
	_credits_detail(content, "Diseño · Programación · Arte")

	_credits_spacer(content, 50)

	_credits_row(content, "AUDIO")
	_credits_name(content, "ElevenLabs Sound Effects", 18)
	_credits_detail(content, "elevenlabs.io", Color(0.35, 0.6, 1.0))

	_credits_spacer(content, 50)

	_credits_row(content, "MOTOR")
	_credits_name(content, "Godot Engine 4.x", 18)
	_credits_detail(content, "godotengine.org  ·  MIT License", Color(0.35, 0.6, 1.0))

	_credits_spacer(content, 50)

	_credits_row(content, "FUENTES")
	_credits_name(content, "Noto Color Emoji", 18)
	_credits_detail(content, "Google Fonts  ·  SIL Open Font License 1.1")

	_credits_spacer(content, 50)

	_credits_row(content, "EMOJIS")
	_credits_name(content, "Twemoji — Twitter / X Corp.", 18)
	_credits_detail(content, "Creative Commons Attribution 4.0")

	_credits_spacer(content, 100)

	var thanks_lbl := Label.new()
	thanks_lbl.text = tr("CREDITS_THANKS")
	thanks_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	thanks_lbl.add_theme_font_size_override("font_size", AccessibilityManager.fs(24))
	thanks_lbl.add_theme_color_override("font_color", Color(0.5, 0.78, 0.5))
	content.add_child(thanks_lbl)

	_credits_spacer(content, 140)  # cola final para que el texto salga por arriba

	# ── Botón saltar (siempre visible, esquina inferior derecha) ──
	var skip_btn := Button.new()
	skip_btn.text = EmojiToRichText.strip(tr("MM_CREDITS_SKIP"))
	skip_btn.anchor_left   = 1.0
	skip_btn.anchor_right  = 1.0
	skip_btn.anchor_top    = 1.0
	skip_btn.anchor_bottom = 1.0
	skip_btn.offset_left   = -130.0
	skip_btn.offset_right  = -16.0
	skip_btn.offset_top    = -52.0
	skip_btn.offset_bottom = -12.0
	skip_btn.pressed.connect(_close_credits_panel)
	credits_panel.add_child(skip_btn)

	# ── Iniciar animación de scroll tras dos frames (tamaños ya calculados) ──
	await get_tree().process_frame
	await get_tree().process_frame

	var screen_h: float = credits_panel.size.y
	var screen_w: float = credits_panel.size.x
	# Forzar ancho y centrar horizontalmente
	content.size = Vector2(540.0, content.size.y)
	content.position = Vector2((screen_w - 540.0) * 0.5, screen_h)

	if AccessibilityManager.reduce_motion:
		# Sin animación: mostrar contenido estático al tope, usuario cierra con el botón
		content.position = Vector2(content.position.x, screen_h * 0.05)
	else:
		var total_dist: float = screen_h + content.size.y
		var duration: float   = total_dist / 72.0  # ~72 px/s
		var tween: Tween = credits_panel.create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(content, "position:y", -content.size.y, duration)
		tween.tween_callback(_close_credits_panel)


func _credits_row(parent: VBoxContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", AccessibilityManager.fs(10))
	lbl.add_theme_color_override("font_color", Color(0.28, 0.45, 0.72))
	parent.add_child(lbl)


func _credits_name(parent: VBoxContainer, text: String, font_size: int = 18) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	parent.add_child(lbl)


func _credits_detail(parent: VBoxContainer, text: String, color: Color = Color(0.48, 0.55, 0.68)) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", AccessibilityManager.fs(12))
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)


func _credits_spacer(parent: VBoxContainer, height: int) -> void:
	var c := Control.new()
	c.custom_minimum_size.y = height
	parent.add_child(c)


func _close_credits_panel() -> void:
	if is_instance_valid(credits_panel):
		credits_panel.queue_free()
		credits_panel = null
	if _credits_close_cb.is_valid():
		_credits_close_cb.call()
		_credits_close_cb = Callable()


# ─────────────────────────────────────────────────────────────
# LOCALE — refrescar UI cuando cambia el idioma
# ─────────────────────────────────────────────────────────────
func _on_locale_changed(_new_locale: String) -> void:
	# Los botones estáticos de la escena se auto-traducen vía NOTIFICATION_TRANSLATION_CHANGED
	# (auto_translate_mode = ALWAYS por defecto). Sólo necesitamos re-asignar el texto en los
	# botones creados dinámicamente desde código.
	if is_instance_valid(btn_continue):
		var has_save := FileAccess.file_exists(SaveManager.SAVE_PATH)
		var post_transcendence := not has_save and LegacyManager.trascendencia_count > 0
		if has_save:
			btn_continue.text = tr("MM_CONTINUE")
		elif post_transcendence:
			btn_continue.text = EmojiToRichText.strip(tr("MM_NEW_RUN_POSTRANSCEND"))

	if is_instance_valid(btn_new_game):
		var has_meta := LegacyManager.legacy_points > 0 or LegacyManager.trascendencia_count > 0 or LegacyManager.total_runs > 0
		btn_new_game.text = tr("MM_NEW_RUN") if has_meta else tr("MM_NEW_GAME")
		btn_new_game.tooltip_text = tr("MM_NEW_RUN_TOOLTIP") if has_meta else ""

	_refresh_nav_badges()

	if is_instance_valid(btn_trascendencia):
		btn_trascendencia.text = EmojiToRichText.strip(tr("MM_TRANSCEND_BTN"))

	if is_instance_valid(trascend_counter_label):
		trascend_counter_label.text = tr("MM_TRANSCEND_COUNTER") % [LegacyManager.esencia, LegacyManager.trascendencia_count]

	var btn_credits := get_node_or_null("CenterContainer/VBoxContainer/BtnCreditos")
	if is_instance_valid(btn_credits):
		btn_credits.text = tr("MM_CREDITS")

	var btn_settings := get_node_or_null("CenterContainer/VBoxContainer/BtnSettings")
	if is_instance_valid(btn_settings):
		btn_settings.text = tr("MM_SETTINGS")

	var btn_tools := get_node_or_null("CenterContainer/VBoxContainer/BtnTools")
	if is_instance_valid(btn_tools):
		btn_tools.text = tr("MM_TOOLS")
