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

func _ready():
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
		btn_continue.text = "Continuar"
		btn_continue.pressed.connect(_on_continue_pressed)
	elif post_transcendence:
		btn_continue.text = EmojiToRichText.strip("▶ Nueva Run (buffs cósmicos activos)")
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
		dialog.get_ok_button().text = EmojiToRichText.strip("▶ Iniciar")
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
	title.text = EmojiToRichText.strip("⚡ CICLO #%d -- ELIGE TU RUTA" % (LegacyManager.trascendencia_count + 1))
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

		btn.text = EmojiToRichText.strip("%s  %s\n%s" % [route.icon, route.name, route.desc])
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
	btn_achievements.text = EmojiToRichText.strip("★ LOGROS" if has_new_ach else "Logros")

	var has_new_buff: bool = LegacyManager.has_unseen_buff()
	btn_legacy.text = EmojiToRichText.strip("★ BANCO GENÉTICO" if has_new_buff else "Banco Genético")

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
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	info.add_child(name_label)

	var stats := Label.new()
	stats.add_theme_font_size_override("font_size", 13)
	stats.add_theme_color_override("font_color", Color(0.65, 0.7, 0.78))
	if summary.exists:
		var last := summary.last_ending if summary.last_ending != "" else "—"
		stats.text = "T%d · %d ciclos · Ξ %d · último: %s" % [
			summary.t_count, summary.total_runs, summary.esencia, last,
		]
	else:
		stats.text = "Slot vacío — sin runs registradas"
	info.add_child(stats)

	# Botones (derecha)
	var btn_select := Button.new()
	btn_select.text = "Continuar" if has_save else "Iniciar"
	btn_select.custom_minimum_size = Vector2(110, 60)
	btn_select.pressed.connect(_on_slot_chosen.bind(slot_id))
	hbox.add_child(btn_select)

	var btn_rename := Button.new()
	btn_rename.text = "Renombrar"
	btn_rename.custom_minimum_size = Vector2(100, 60)
	btn_rename.pressed.connect(_on_slot_rename.bind(slot_id))
	hbox.add_child(btn_rename)

	var btn_delete := Button.new()
	btn_delete.text = "Borrar"
	btn_delete.custom_minimum_size = Vector2(80, 60)
	btn_delete.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	btn_delete.pressed.connect(_on_slot_delete.bind(slot_id))
	# No dejar borrar el último slot (regla de SlotManager.delete_slot)
	if SlotManager.list_slots().size() <= 1:
		btn_delete.disabled = true
		btn_delete.tooltip_text = "No se puede borrar el último slot"
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
	info.text = "Slot vacío disponible"
	info.add_theme_font_size_override("font_size", 16)
	info.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(info)

	var btn_create := Button.new()
	btn_create.text = "Crear nuevo"
	btn_create.custom_minimum_size = Vector2(140, 50)
	btn_create.add_theme_color_override("font_color", Color(0.5, 1.0, 0.7))
	btn_create.pressed.connect(_on_slot_create_pressed)
	hbox.add_child(btn_create)

	slot_list_container.add_child(card)

func _add_unlock_hint_label() -> void:
	var label := Label.new()
	label.text = "Comprá 'Slot Adicional' en el Banco Genético / Conocimiento para desbloquear más slots."
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	slot_list_container.add_child(label)

func _on_slot_chosen(slot_id: String) -> void:
	if slot_id == SlotManager.active_slot:
		_show_main_menu()
		return
	SlotManager.switch_slot(slot_id)
	# Recarga el legacy del nuevo slot vía reload de escena (estado limpio)
	SlotManager.skip_selector_once = true
	get_tree().reload_current_scene()

func _on_slot_create_pressed() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Nuevo slot"
	dialog.dialog_hide_on_ok = false
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	var lbl := Label.new()
	lbl.text = "Nombre del slot:"
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
		var name :String = line.text
		var new_id: String = SlotManager.create_slot(name)
		if new_id != "":
			SlotManager.switch_slot(new_id)
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
	dialog.title = "Renombrar slot"
	dialog.dialog_hide_on_ok = false
	var vbox := VBoxContainer.new()
	var lbl := Label.new()
	lbl.text = "Nuevo nombre:"
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
	confirm.title = "Borrar slot"
	confirm.dialog_text = "¿Borrar el slot '%s'?\nEste universo paralelo se perderá: legado, esencia, trascendencias y run actual.\nEsta acción es irreversible." % slot_name
	confirm.get_ok_button().text = "Borrar"
	confirm.get_cancel_button().text = "Cancelar"
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
	var h: int = s / 3600
	var m: int = (s % 3600) / 60
	var sec: int = s % 60
	if h > 0:
		return "%d:%02d:%02d" % [h, m, sec]
	return "%d:%02d" % [m, sec]

func _update_history_view() -> void:
	var entries: Array
	var header_label: String
	if _history_tab == "current":
		entries = LegacyManager.current_cycle_history
		header_label = "Ciclo de trascendencia actual (T%d)" % LegacyManager.trascendencia_count
	else:
		entries = LegacyManager.all_time_history
		header_label = "Histórico completo de ciclos"

	var t: String = "[center][color=#9adfff][b]═══ %s ═══[/b][/color]\n" % header_label
	t += "[color=#888888]%d ciclo(s) registrado(s)[/color][/center]\n\n" % entries.size()

	if entries.is_empty():
		t += "[center][color=#666666][i]Todavía no hay ciclos registrados en esta vista.[/i][/color][/center]"
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
		t += "[cell bgcolor=%s][b][color=%s]CICLO BIÓTICO %d: %s[/color][/b]%s\n" % \
			[colors.card, colors.title, cycle_index, route, tier_badge]
		if reason != "":
			t += "[color=#aaaaaa][i]%s[/i][/color]\n" % reason
		t += "[color=#888888]⏱ %s · μ_peak %.2f · ε_peak %.2f · +%d PL[/color][/cell]" % \
			[_format_run_time(run_time), mu_peak, eps_peak, pl_gained]
		t += "[/table]\n\n"

	history_label.clear()
	history_label.append_text(EmojiToRichText.rich(t))

func _update_legacy_view():
	pl_counter.text = "Legado acumulado: %d PL\nCiclos Bióticos completados: %d" % [LegacyManager.legacy_points, LegacyManager.total_runs]
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
			hdr.text = "-- %s --" % LegacyManager.CAT_NAMES.get(cat, cat.to_upper())
			hdr.add_theme_font_size_override("font_size", 12)
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

				var name_str: String = def.get("name", id)
				if max_lvl > 1:
					name_str += "  [%d/%d]" % [lvl, max_lvl]
				if is_new:
					name_str += "  NUEVO"

				var name_lbl: Label = Label.new()
				name_lbl.text = name_str
				name_lbl.add_theme_font_size_override("font_size", 11)
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
				flavor_lbl.text = def.get("flavor", "")
				flavor_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				flavor_lbl.add_theme_font_size_override("font_size", 9)
				flavor_lbl.modulate = Color(0.55, 0.55, 0.55)

				container.add_child(name_lbl)
				container.add_child(flavor_lbl)

				var buy_btn: Button = Button.new()
				buy_btn.custom_minimum_size.y = 22
				if is_maxed:
					buy_btn.text = "MAXIMO"
					buy_btn.disabled = true
				elif not unlockable:
					buy_btn.text = "BLOQUEADO"
					buy_btn.disabled = true
				elif lvl == 0:
					buy_btn.text = "ADQUIRIR" if def.get("cost", 0) == 0 else "%d PL" % cost
					buy_btn.disabled = (def.get("cost", 0) > 0 and not affordable)
				else:
					buy_btn.text = "Nv%d  %d PL" % [lvl + 1, cost]
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

func _on_buy_legacy(id: String):
	if LegacyManager.purchase_legacy(id):
		_update_legacy_view()

func _update_achievements_view():
	var total: int = AchievementManager.total_count()
	var got: int = AchievementManager.unlocked_count()

	var t: String = "[center][color=#ffcc00][b]═══ HISTORIAL DE LOGROS ═══[/b][/color]\n"
	t += "[color=#888888]%d / %d desbloqueados[/color][/center]\n\n" % [got, total]

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
			var name_str: String = def.get("name", id)
			var desc_str: String = def.get("desc", "")

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
				var new_badge: String = "  [color=#ffdd00][b]★ NUEVO[/b][/color]" if is_new else ""
				t += "[cell bgcolor=%s][b][color=%s]%s[/color]%s[/b]\n[color=%s][i]%s[/i][/color][/cell]" % \
					[card_bg, title_color, name_str, new_badge, desc_color, desc_str]
				if is_new:
					AchievementManager.mark_seen(id)
			elif is_secret:
				t += "[cell bgcolor=%s][b][color=%s]??? [i](logro oculto)[/i][/color][/b][/cell]" % \
					[card_bg, title_color]
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
	btn_trascendencia.text = EmojiToRichText.strip("⚡ TRASCENDER")
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
	title.text = EmojiToRichText.strip("⚡ TRASCENDENCIA ⚡")
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
	gate_status.text = EmojiToRichText.strip(LegacyManager.get_transcend_gate_status())
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
		reward.text = "Ganás +%d Ξ (Esencia)\nPL actual: %d -> convertido\nRutas únicas: %d × 5 Ξ\nTier bonus: +%d Ξ" % [
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
	warn.text = EmojiToRichText.strip("[!] Al trascender se RESETEAN: upgrades, mutaciones, PL, buffs del Banco Genético.\n* Se PRESERVAN: Esencia (Ξ), Banco Cósmico, rutas ya completadas.")
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
	btn_confirm.text = EmojiToRichText.strip("⚡ CONFIRMAR TRASCENDENCIA ⚡" if can else "REQUISITOS NO CUMPLIDOS")
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
