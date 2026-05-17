extends Node

# AudioManager.gd — Autoload
# SFX pool + música de fondo + persistencia de settings.
#
# Web: el AudioContext del navegador suele estar suspendido hasta el primer
# input del usuario. Por eso la música arranca silenciada y se "despierta"
# (start + fade) tras el primer InputEvent global.

const SETTINGS_PATH := "user://audio_settings.json"
const AUDIO_DIR := "res://audio/"
const SFX_POOL_SIZE := 6

# Volúmenes 0.0–1.0. Se aplican a buses Music y SFX en dB.
var music_volume: float = 0.5
var sfx_volume: float = 0.7
var music_muted: bool = false
var sfx_muted: bool = false

# IDs → nombre de archivo en res://audio/
const SFX_FILES := {
	"click":       "click.ogg",
	"upgrade":     "upgrade.ogg",
	"achievement": "achievement.ogg",
	"transcend":   "transcend.ogg",
	"run_close":   "run_close.ogg",
	"mutation":    "mutation.ogg",
}
const MUSIC_FILES := {
	"ambient": "ambient_loop.ogg",
}

# Atenuación per-SFX (dB extra restados al volumen del bus). El click se dispara
# muchísimo, así que va más bajo que el resto.
const SFX_TRIM_DB := {
	"click": -8.0,
}

var _sfx_streams: Dictionary = {}     # id → AudioStream
var _music_streams: Dictionary = {}   # id → AudioStream
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_next: int = 0
var _music_player: AudioStreamPlayer = null
var _current_music_id: String = ""

# Web autoplay gate
var _audio_unlocked: bool = false
var _pending_music_id: String = ""

# Bus indices (cacheados)
var _bus_music: int = -1
var _bus_sfx: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # sigue funcionando si el árbol se pausa
	_setup_buses()
	_load_settings()
	_load_streams()
	_build_sfx_pool()
	_build_music_player()
	_apply_volumes()


# ---------------------------------------------------------------
#  BUSES
# ---------------------------------------------------------------
func _setup_buses() -> void:
	# Crea buses Music y SFX si no existen, ruteados a Master.
	_bus_music = AudioServer.get_bus_index("Music")
	if _bus_music == -1:
		AudioServer.add_bus()
		_bus_music = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_bus_music, "Music")
		AudioServer.set_bus_send(_bus_music, "Master")
	_bus_sfx = AudioServer.get_bus_index("SFX")
	if _bus_sfx == -1:
		AudioServer.add_bus()
		_bus_sfx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_bus_sfx, "SFX")
		AudioServer.set_bus_send(_bus_sfx, "Master")


# ---------------------------------------------------------------
#  ASSETS
# ---------------------------------------------------------------
func _load_streams() -> void:
	for id in SFX_FILES:
		var path: String = AUDIO_DIR + SFX_FILES[id]
		if ResourceLoader.exists(path):
			_sfx_streams[id] = load(path)
	for id in MUSIC_FILES:
		var path: String = AUDIO_DIR + MUSIC_FILES[id]
		if ResourceLoader.exists(path):
			var stream: AudioStream = load(path)
			# Forzar loop si el .ogg no lo trae marcado.
			if stream is AudioStreamOggVorbis:
				(stream as AudioStreamOggVorbis).loop = true
			_music_streams[id] = stream


func _build_sfx_pool() -> void:
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)


func _build_music_player() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)


# ---------------------------------------------------------------
#  WEB AUTOPLAY UNLOCK
#  En navegadores, AudioContext está suspendido hasta el primer input.
#  Capturamos el primer InputEvent global y arrancamos la música pendiente.
# ---------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if _audio_unlocked:
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_unlock_audio()
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		_unlock_audio()
	elif event is InputEventKey and (event as InputEventKey).pressed:
		_unlock_audio()


func _unlock_audio() -> void:
	if _audio_unlocked:
		return
	_audio_unlocked = true
	if _pending_music_id != "":
		_start_music(_pending_music_id)
		_pending_music_id = ""


# ---------------------------------------------------------------
#  API PÚBLICA
# ---------------------------------------------------------------
func play_sfx(id: String) -> void:
	if sfx_muted:
		return
	if not _sfx_streams.has(id):
		return  # asset todavía no agregado
	var player: AudioStreamPlayer = _sfx_players[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx_players.size()
	player.stream = _sfx_streams[id]
	player.volume_db = float(SFX_TRIM_DB.get(id, 0.0))
	player.play()


func play_music(id: String) -> void:
	# Si ya está sonando lo mismo, no reiniciar.
	if _current_music_id == id and _music_player.playing:
		return
	if not _music_streams.has(id):
		# Asset no presente: recordar para cuando aparezca/se cargue.
		_pending_music_id = id
		_current_music_id = id
		return
	if not _audio_unlocked:
		# Web: esperar al primer input.
		_pending_music_id = id
		_current_music_id = id
		return
	_start_music(id)


func _start_music(id: String) -> void:
	if not _music_streams.has(id):
		return
	_music_player.stop()
	_music_player.stream = _music_streams[id]
	_music_player.play()
	_current_music_id = id


func stop_music() -> void:
	_music_player.stop()
	_current_music_id = ""
	_pending_music_id = ""


# ---------------------------------------------------------------
#  SETTINGS
# ---------------------------------------------------------------
func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	_apply_volumes()
	_save_settings()


func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	_apply_volumes()
	_save_settings()


func set_music_muted(b: bool) -> void:
	music_muted = b
	_apply_volumes()
	_save_settings()


func set_sfx_muted(b: bool) -> void:
	sfx_muted = b
	_apply_volumes()
	_save_settings()


func _apply_volumes() -> void:
	# Convertir 0–1 a dB. 0 → -80 dB (silencio efectivo).
	AudioServer.set_bus_mute(_bus_music, music_muted or music_volume <= 0.001)
	AudioServer.set_bus_mute(_bus_sfx, sfx_muted or sfx_volume <= 0.001)
	if music_volume > 0.001:
		AudioServer.set_bus_volume_db(_bus_music, linear_to_db(music_volume))
	if sfx_volume > 0.001:
		AudioServer.set_bus_volume_db(_bus_sfx, linear_to_db(sfx_volume))


func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if not file:
		return
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return
	var data: Dictionary = json.data
	music_volume = float(data.get("music_volume", music_volume))
	sfx_volume = float(data.get("sfx_volume", sfx_volume))
	music_muted = bool(data.get("music_muted", music_muted))
	sfx_muted = bool(data.get("sfx_muted", sfx_muted))


func _save_settings() -> void:
	var data := {
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"music_muted": music_muted,
		"sfx_muted": sfx_muted,
	}
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()


# ---------------------------------------------------------------
#  PANEL DE SETTINGS — construido por código, reutilizable.
#  Llamar AudioManager.show_settings_panel(parent_node).
# ---------------------------------------------------------------
var _settings_panel: Panel = null


func show_settings_panel(parent: Node) -> void:
	if is_instance_valid(_settings_panel):
		_settings_panel.queue_free()

	_settings_panel = Panel.new()
	_settings_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.04, 0.04, 0.08, 1.0)
	_settings_panel.add_theme_stylebox_override("panel", bg_style)
	parent.add_child(_settings_panel)

	# ScrollContainer para contenido largo
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_settings_panel.add_child(scroll)

	# Fila horizontal para centrar el VBox
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(row)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(440, 0)
	vbox.add_theme_constant_override("separation", 14)
	row.add_child(vbox)

	# Espaciado superior
	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 24)
	vbox.add_child(top_spacer)

	var title := Label.new()
	title.text = EmojiToRichText.strip(tr("SET_TITLE"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", AccessibilityManager.fs(28))
	title.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	_build_volume_row(vbox, tr("SET_MUSIC"), music_volume, music_muted,
		Callable(self, "set_music_volume"),
		Callable(self, "set_music_muted"),
		"")  # sin SFX de prueba (la música ya suena)

	_build_volume_row(vbox, tr("SET_SFX"), sfx_volume, sfx_muted,
		Callable(self, "set_sfx_volume"),
		Callable(self, "set_sfx_muted"),
		"click")

	vbox.add_child(HSeparator.new())
	_build_locale_row(vbox)
	vbox.add_child(HSeparator.new())
	_build_telemetry_row(vbox)
	vbox.add_child(HSeparator.new())
	_build_accessibility_row(vbox)
	vbox.add_child(HSeparator.new())

	# ── Exportar / Importar save ──────────────────────────────────────
	var btn_export := Button.new()
	btn_export.text = tr("SET_EXPORT_SAVE")
	btn_export.custom_minimum_size = Vector2(0, 36)
	btn_export.pressed.connect(func():
		var main_node: Node = get_tree().get_first_node_in_group("main")
		SaveManager.export_save_json(main_node)
	)
	vbox.add_child(btn_export)

	if OS.get_name() == "Web":
		# En web también ofrecemos importar (para cargar un save exportado desde desktop)
		var btn_import := Button.new()
		btn_import.text = tr("SET_IMPORT_SAVE")
		btn_import.custom_minimum_size = Vector2(0, 36)
		btn_import.add_theme_color_override("font_color", Color(0.6, 1.0, 0.75))
		btn_import.pressed.connect(func():
			_close_settings_panel()
			SaveManager.import_save_json()
		)
		vbox.add_child(btn_import)

		var import_hint := Label.new()
		import_hint.text = tr("SET_IMPORT_HINT")
		import_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		import_hint.add_theme_font_size_override("font_size", AccessibilityManager.fs(11))
		import_hint.add_theme_color_override("font_color", Color(0.5, 0.62, 0.58))
		vbox.add_child(import_hint)
	else:
		var export_hint := Label.new()
		export_hint.text = tr("SET_EXPORT_HINT")
		export_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		export_hint.add_theme_font_size_override("font_size", AccessibilityManager.fs(11))
		export_hint.add_theme_color_override("font_color", Color(0.62, 0.68, 0.78))
		vbox.add_child(export_hint)

	vbox.add_child(HSeparator.new())

	var btn_tutorial := Button.new()
	btn_tutorial.text = tr("SET_RESET_TUTORIAL")
	btn_tutorial.custom_minimum_size = Vector2(0, 36)
	btn_tutorial.pressed.connect(func():
		_close_settings_panel()
		TutorialManager.reset_tutorial()
	)
	vbox.add_child(btn_tutorial)

	var btn_reset := Button.new()
	btn_reset.text = tr("SET_RESET_RUN")
	btn_reset.custom_minimum_size = Vector2(0, 36)
	btn_reset.add_theme_color_override("font_color", Color(1.0, 0.55, 0.55))
	btn_reset.pressed.connect(func():
		var parent_ref := parent
		_close_settings_panel()
		SaveManager.confirm_and_reset(parent_ref)
	)
	vbox.add_child(btn_reset)

	var btn_close := Button.new()
	btn_close.text = tr("SET_CLOSE")
	btn_close.custom_minimum_size = Vector2(0, 40)
	btn_close.pressed.connect(_close_settings_panel)
	vbox.add_child(btn_close)

	# Espaciado inferior para que el scroll no corte el último botón
	var bot_spacer := Control.new()
	bot_spacer.custom_minimum_size = Vector2(0, 32)
	vbox.add_child(bot_spacer)


func _build_volume_row(parent: VBoxContainer, label_text: String,
		initial_value: float, initial_muted: bool,
		on_value_change: Callable, on_mute_change: Callable,
		preview_sfx_id: String) -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", AccessibilityManager.fs(14))
	row.add_child(lbl)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	row.add_child(hbox)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = initial_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(220, 0)
	hbox.add_child(slider)

	var pct := Label.new()
	pct.text = "%d%%" % int(initial_value * 100)
	pct.custom_minimum_size = Vector2(48, 0)
	hbox.add_child(pct)

	var mute_btn := CheckBox.new()
	mute_btn.text = "Mute"
	mute_btn.button_pressed = initial_muted
	hbox.add_child(mute_btn)

	slider.value_changed.connect(func(v: float):
		on_value_change.call(v)
		pct.text = "%d%%" % int(v * 100)
		if preview_sfx_id != "":
			play_sfx(preview_sfx_id))
	mute_btn.toggled.connect(func(pressed: bool):
		on_mute_change.call(pressed))


func _build_locale_row(parent: VBoxContainer) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	parent.add_child(box)

	var lbl := Label.new()
	lbl.text = tr("SET_LANGUAGE")
	lbl.add_theme_font_size_override("font_size", AccessibilityManager.fs(14))
	lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	box.add_child(lbl)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)

	var btn_es := Button.new()
	btn_es.text = tr("SET_LANG_ES")
	btn_es.custom_minimum_size = Vector2(0, 34)
	btn_es.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_es.toggle_mode = true
	btn_es.button_pressed = LocaleManager.current_locale == "es"

	var btn_en := Button.new()
	btn_en.text = tr("SET_LANG_EN")
	btn_en.custom_minimum_size = Vector2(0, 34)
	btn_en.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_en.toggle_mode = true
	btn_en.button_pressed = LocaleManager.current_locale == "en"

	btn_es.pressed.connect(func():
		LocaleManager.set_locale("es")
		btn_es.button_pressed = true
		btn_en.button_pressed = false
		# Rebuild para reflejar el cambio inmediato
		var parent_ref := _settings_panel.get_parent()
		_close_settings_panel()
		show_settings_panel(parent_ref))

	btn_en.pressed.connect(func():
		LocaleManager.set_locale("en")
		btn_es.button_pressed = false
		btn_en.button_pressed = true
		var parent_ref := _settings_panel.get_parent()
		_close_settings_panel()
		show_settings_panel(parent_ref))

	row.add_child(btn_es)
	row.add_child(btn_en)


func _build_telemetry_row(parent: VBoxContainer) -> void:
	var telemetry_box := VBoxContainer.new()
	telemetry_box.add_theme_constant_override("separation", 4)
	parent.add_child(telemetry_box)

	var checkbox := CheckBox.new()
	checkbox.text = "Enviar datos anonimos de uso (ayuda a mejorar el juego)"
	checkbox.button_pressed = TelemetryManager.is_enabled()
	checkbox.toggled.connect(func(pressed: bool):
		TelemetryManager.set_enabled(pressed))
	telemetry_box.add_child(checkbox)

	var hint := Label.new()
	hint.text = "Local y opt-in: guarda JSON anonimos en user://telemetry/runs al cerrar una run."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", AccessibilityManager.fs(11))
	hint.add_theme_color_override("font_color", Color(0.62, 0.68, 0.78))
	telemetry_box.add_child(hint)

	var open_btn := Button.new()
	open_btn.text = "Abrir carpeta de telemetria"
	open_btn.custom_minimum_size = Vector2(0, 34)
	open_btn.disabled = OS.get_name() == "HTML5"
	open_btn.pressed.connect(func():
		TelemetryManager.open_runs_dir())
	telemetry_box.add_child(open_btn)


func _build_accessibility_row(parent: VBoxContainer) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	parent.add_child(box)

	var sec_lbl := Label.new()
	sec_lbl.text = "Accesibilidad"
	sec_lbl.add_theme_font_size_override("font_size", AccessibilityManager.fs(14))
	sec_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	box.add_child(sec_lbl)

	# ── Escala de texto ──────────────────────────────
	var scale_row := HBoxContainer.new()
	scale_row.add_theme_constant_override("separation", 10)
	box.add_child(scale_row)

	var scale_lbl := Label.new()
	scale_lbl.text = "Tamaño de texto:"
	scale_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scale_row.add_child(scale_lbl)

	var scale_opt := OptionButton.new()
	scale_opt.add_item("85%",  0)
	scale_opt.add_item("Normal (100%)", 1)
	scale_opt.add_item("115%", 2)
	scale_opt.add_item("130%", 3)
	# Seleccionar el índice correspondiente al scale actual
	var scale_map := {0.85: 0, 1.0: 1, 1.15: 2, 1.30: 3}
	scale_opt.selected = scale_map.get(AccessibilityManager.font_scale, 1)
	scale_opt.custom_minimum_size = Vector2(150, 0)
	scale_opt.item_selected.connect(func(idx: int):
		var vals := [0.85, 1.0, 1.15, 1.30]
		AccessibilityManager.set_font_scale(vals[idx])
		# set_font_scale hace reload_current_scene automáticamente
	)
	scale_row.add_child(scale_opt)

	var scale_hint := Label.new()
	scale_hint.text = "Requiere reinicio de escena al cambiar."
	scale_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scale_hint.add_theme_font_size_override("font_size", AccessibilityManager.fs(10))
	scale_hint.add_theme_color_override("font_color", Color(0.45, 0.50, 0.60))
	box.add_child(scale_hint)

	# ── Reducir movimiento ───────────────────────────
	var motion_cb := CheckBox.new()
	motion_cb.text = "Reducir movimiento (sin animaciones)"
	motion_cb.button_pressed = AccessibilityManager.reduce_motion
	motion_cb.toggled.connect(func(pressed: bool):
		AccessibilityManager.set_reduce_motion(pressed))
	box.add_child(motion_cb)

	# ── Alto contraste ───────────────────────────────
	var contrast_cb := CheckBox.new()
	contrast_cb.text = "Alto contraste"
	contrast_cb.button_pressed = AccessibilityManager.high_contrast
	contrast_cb.toggled.connect(func(pressed: bool):
		AccessibilityManager.set_high_contrast(pressed))
	box.add_child(contrast_cb)

	# ── Modo daltonismo ──────────────────────────────
	var cb_row := HBoxContainer.new()
	cb_row.add_theme_constant_override("separation", 10)
	box.add_child(cb_row)

	var cb_lbl := Label.new()
	cb_lbl.text = "Daltonismo:"
	cb_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cb_row.add_child(cb_lbl)

	var cb_opt := OptionButton.new()
	cb_opt.add_item("Desactivado", 0)
	cb_opt.add_item("Deuteranopia (R-G)", 1)
	cb_opt.add_item("Protanopia (R-G)", 2)
	cb_opt.add_item("Tritanopia (B-A)", 3)
	cb_opt.selected = AccessibilityManager.colorblind_mode
	cb_opt.custom_minimum_size = Vector2(170, 0)
	cb_opt.item_selected.connect(func(idx: int):
		AccessibilityManager.set_colorblind_mode(idx))
	cb_row.add_child(cb_opt)


func _close_settings_panel() -> void:
	if is_instance_valid(_settings_panel):
		_settings_panel.queue_free()
		_settings_panel = null
