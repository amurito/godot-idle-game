extends Control

# =====================================================
# IDLE � v0.8 DLC "Fungi"
# =====================================================
#dlc
const FUNGI_UI_SCENE = preload("res://fungi.tscn")
var fungi_ui: Control

var reactor_visual: Node = null
var _use_3d_reactor: bool = true
var reactor_3d: Node = null
var _3d_power_label: Label = null

# Parasitismo � status peri�dico
var _parasitism_status_timer := 0.0
const PARASITISM_STATUS_INTERVAL := 45.0

# NG++ Metabolismo Oscuro
var _met_oscuro_seal_btn: Button = null
var _simbiosis_seal_btn: Button = null
var _colapso_controlado_btn: Button = null
var _reset_btn: Button = null

# CONSTANTES DE MODELO (moved to StructuralModel.gd)
const CLICK_RATE := 1.0

var mu_peak_run: float = 0.0
var delta_peak_run: float = 0.0
var _telemetry_sample_timer: float = 0.0


var institutions_unlocked: bool = false
var show_institutions_panel: bool = false

# === e PASIVO (v0.8) ===
const EPS_PASSIVE_SCALE := 0.24
const PASSIVE_RATIO_START := 0.60


# =============== SESI�N / LAB MODE ===================

var _debug_panel: Panel = null

# RunManager.final_reason movido a RunManager.gd
var show_final_details := false  # ya lo ten�as; lo usamos para controlar detalles

# Timers � tick system (no more manual accumulation in _process)
var _logic_timer: Timer
var _ui_timer: Timer
var _autosave_timer: Timer
const UI_TICK := 0.1      # 10 Hz � labels & buttons
const AUTOSAVE_INTERVAL := 30.0

# ================= REFERENCIAS UI ===================
@onready var ui_root = $UIRootContainer
@onready var _legacy_indicators := $HeaderBar/HeaderContent/LegacyIndicators
@onready var evolution_bar = $UIRootContainer/LeftPanel/CenterPanel/EvolutionProgressBar
@onready var bottom_left_panel = $BottomLeftControls
@onready var evo_choice_panel = $EvoChoicePanel
@onready var btn_evolve = %BtnEvolve
@onready var legacy_panel = $LegacyPanel
@onready var legacy_list = %LegacyList
@onready var pl_label = %PLLabel


# ===== BIOSFERA MOVIDA A BiosphereEngine =====
# ============================
#  GENOMA FÚNGICO � v0.1
# ============================

func _update_met_oscuro_seal_button():
	if RunManager.run_closed:
		return
	# PL escalonado seg�n biomasa al momento del sellado
	var bio := BiosphereEngine.biomasa
	var pl_seal := 2 if bio < 50.0 else (4 if bio < 100.0 else 6)
	var seal_label := EmojiToRichText.strip("🌑 SELLAR MET.OSCURO (+%d PL)" % pl_seal)

	if _met_oscuro_seal_btn == null or not is_instance_valid(_met_oscuro_seal_btn):
		_met_oscuro_seal_btn = Button.new()
		_met_oscuro_seal_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(20))
		_met_oscuro_seal_btn.add_theme_color_override("font_color", Color(0.8, 0.5, 1.0))
		_met_oscuro_seal_btn.custom_minimum_size = Vector2(0, 70)
		_met_oscuro_seal_btn.pressed.connect(_on_met_oscuro_seal_pressed)
		var panel := get_node_or_null("UIRootContainer/RightPanel")
		if panel:
			panel.add_child(_met_oscuro_seal_btn)
			panel.move_child(_met_oscuro_seal_btn, 0)
	_met_oscuro_seal_btn.text = seal_label
	_met_oscuro_seal_btn.visible = true

func _on_met_oscuro_seal_pressed():
	if RunManager.run_closed:
		return
	var bio := BiosphereEngine.biomasa
	var pl_bonus := 0 if bio < 50.0 else (-2 if bio < 100.0 else 2)
	# RunManager asigna +4 PL base. Ajustamos: bio<50?+2 (penalidad -2), bio 50-99?+4 (sin bonus), bio=100?+6 (+2 bonus)
	if pl_bonus < 0:
		# Penalidad: restar 2 al base luego del close_run (pre-otorgamos -2)
		LegacyManager.add_pl(-2)
	elif pl_bonus > 0:
		LegacyManager.add_pl(2)
	if is_instance_valid(_met_oscuro_seal_btn):
		_met_oscuro_seal_btn.visible = false
	var pl_total := 2 if bio < 50.0 else (4 if bio < 100.0 else 6)
	RunManager.close_run("METABOLISMO OSCURO", "Sellado voluntario (Bio %.0f) — bioquímica oscura cristalizada (+%d PL)" % [bio, pl_total])

func _update_simbiosis_seal_button():
	if RunManager.run_closed or not EvoManager.mutation_symbiosis:
		if is_instance_valid(_simbiosis_seal_btn):
			_simbiosis_seal_btn.visible = false
		return
	# No mostrar si el jugador ya eligi� la rama SYMBIOSIS (camino a Singularidad)
	if EvoManager.red_branch_selected == EvoManager.RedBranch.SYMBIOSIS:
		if is_instance_valid(_simbiosis_seal_btn):
			_simbiosis_seal_btn.visible = false
		return
	# S�lo mostrar si lleva m�s de 60s en SIMBIOSIS
	if RunManager.run_time < 60.0:
		return
	if _simbiosis_seal_btn == null or not is_instance_valid(_simbiosis_seal_btn):
		_simbiosis_seal_btn = Button.new()
		_simbiosis_seal_btn.text = EmojiToRichText.strip("🌱 SELLAR SIMBIOSIS (+4 PL)")
		_simbiosis_seal_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(20))
		_simbiosis_seal_btn.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
		_simbiosis_seal_btn.custom_minimum_size = Vector2(0, 70)
		_simbiosis_seal_btn.pressed.connect(_on_simbiosis_seal_pressed)
		var panel := get_node_or_null("UIRootContainer/RightPanel")
		if panel:
			panel.add_child(_simbiosis_seal_btn)
			panel.move_child(_simbiosis_seal_btn, 0)
	_simbiosis_seal_btn.visible = true

func _on_simbiosis_seal_pressed():
	if is_instance_valid(_simbiosis_seal_btn):
		_simbiosis_seal_btn.visible = false
	RunManager.close_run("SIMBIOSIS", "Cooperación sellada voluntariamente — estructura y biología en equilibrio")


func apply_flexibility_modifier(factor: float):
	StructuralModel.apply_flexibility_modifier(factor)

func enable_persistence_inertia(factor: float):
	StructuralModel.enable_persistence_inertia(factor)

func apply_symbiotic_stabilization():
	# m�s flexibilidad estructural
	StructuralModel.omega = min(1.0, StructuralModel.omega * 1.25)

	# amortiguaci�n permanente del estrés
	EconomyManager.mutation_accounting_bonus = min(0.6, EconomyManager.mutation_accounting_bonus + 0.15)

	# mejora pasivo sin romper el modelo
	EconomyManager.trueque_efficiency *= 1.1
	EconomyManager.mutation_auto_factor *= 1.05
# =====================================================
#  RUTA FINAL � detalles
# =====================================================
func build_final_line() -> String:
	if not RunManager.run_closed:
		return ""
	var t := "\n?? FINAL: %s" % RunManager.final_route
	if show_final_details:
		t += "\n" + get_final_reason()
	return t

# =====================================================
#  FORMATO TEXTO F�RMULA
# =====================================================

func build_formula_text() -> String:
	return UIManager.build_formula_text(self)

func build_formula_values() -> String:
	return UIManager.build_formula_values(self)

# ===============================
#   HUD CIENT�FICO � segmentado por capas
# ===============================
func update_click_stats_panel() -> void:
	if UIManager.click_stats_label:
		UIManager.click_stats_label.clear()
		UIManager.click_stats_label.append_text(EmojiToRichText.rich(UIManager.update_click_stats_panel(self)))


# =====================================================
#  VISUALIZACI�N DE LAPS
# =====================================================
func _on_ToggleLapViewButton_pressed():
	toggle_lap_view()

func _on_upgrade_bought_signal(id: String) -> void:
	update_ui()
	if id == "accounting" and UpgradeManager.level("accounting") == 1 and not institutions_unlocked:
		institutions_unlocked = true
# =====================================================
#  RUTA FINAL DE LA RUN v0.8
# =====================================================
func get_final_route() -> String:
	if RunManager.final_route != "NONE":
		return RunManager.final_route
	if EvoManager.mutation_sporulation:
		return "ESPORULACION"
	if EvoManager.mutation_homeostasis:
		return "HOMEOSTASIS"
	if EvoManager.mutation_hyperassimilation:
		return "HIPERASIMILACION"
	if EvoManager.mutation_symbiosis:
		return "SIMBIOSIS"
	if EvoManager.mutation_red_micelial:
		return "RED_MICELIAL"
	return "NONE"
func get_final_reason() -> String:
	# si tenemos RunManager.final_reason expl�cito, lo devolvemos; si no, generamos un texto por ruta
	if RunManager.final_reason != "" :
		return RunManager.final_reason

	match RunManager.final_route:
		"HOMEOSTASIS":
			return "Estabilidad estructural priorizada — run cerrada por homeostasis"
		"ALLOSTASIS":
			return "Estabilidad a través del cambio — setpoint adaptativo alcanzado"
		"HOMEORHESIS":
			return "Transformación irreversible — el sistema trasciende la regulación"
		"HIPERASIMILACION":
			return "El sistema prioriza absorción total sobre estabilidad\n? EFECTOS ACTIVOS: Click PUSH ×10 | Pasivo ×0.25 (-75%) | Fragilidad O total"
		"ESPORULACION":
			return "Dispersión en esporas: la red colapsó en semillas"
		"PARASITISMO":
			return "Extracción total: la biosfera drenó la estructura"
		"SIMBIOSIS":
			return "Cooperación sostenida entre estructura y biología"
		"RED_MICELIAL":
			return "Red micelial madura"
		_:
			return "Final alcanzado"
# =====================================================
#  CHEQUEO FINAL DE HOMEOSTASIS v0.8
# =====================================================
# =====================================================
#  TOOLTIP HIPERASIMILACIÓN v0.8
# =====================================================
func get_hyperassimilation_tooltip() -> String:
	if EvoManager.genome.get("hiperasimilacion","dormido") == "bloqueado":
		return "Bloqueada por HOMEOSTASIS o SIMBIOSIS"

	if EvoManager.genome.hiperasimilacion == "activo":
		return "Absorción total priorizada. Estabilidad ignorada."

	var t := "Hiperasimilación (LATENTE)\n"
	if StructuralModel.epsilon_runtime <= 0.6:
		t += "• e insuficiente\n"
	if BiosphereEngine.biomasa <= 5.0:
		t += "• Biomasa insuficiente\n"
	if StructuralModel.omega>= 0.30:
		t += "• Sistema demasiado flexible\n"
	if UpgradeManager.level("accounting") > 0: # Use UpgradeManager
		t += "• Instituciones bloquean esta vía\n"

	return t
# =====================================================
#  LAP MARKERS
# =====================================================

func add_lap(event: String) -> void:
	LogManager.add(event)


func check_dominance_transition():
	LogManager.check_dominance_transition()

func _on_ExportRunButton_pressed():
	LogManager.export_run(self)


func check_achievements():
	# Empujar snapshot del estado del mundo antes del tick de evaluaci�n.
	AchievementManager.push_snapshot({
		"epsilon":         StructuralModel.epsilon_effective,
		"biomasa":         BiosphereEngine.biomasa,
		"k_eff":           StructuralModel.get_k_eff(),
		"delta_total":     EconomyManager.get_delta_total(),
		"money":           EconomyManager.money,
		"total_money":     EconomyManager.total_money_generated,
		"resilience_score":RunManager.resilience_score,
		"dominant_term":      EconomyManager.get_dominant_term(),
		"parasitism":         EvoManager.mutation_parasitism,
		"hifas":              BiosphereEngine.hifas,
		"trascendencia_count":LegacyManager.trascendencia_count,
	})
	AchievementManager.check_tick(RunManager.LOGIC_TICK)
func show_system_toast(message: String) -> void:
	UIManager.show_toast(message)

func update_achievements_label():
	# Vista resumida en el HUD. Detalles completos se ven en el menú principal.
	var total := AchievementManager.total_count()
	var got := AchievementManager.unlocked_count()
	var t := "--- Logros (%d / %d) ---\n" % [got, total]
	# Recorrer por tier
	for tier in [AchievementManager.Tier.MICELIO, AchievementManager.Tier.ESPORA, AchievementManager.Tier.FRUTO, AchievementManager.Tier.ANCESTRAL, AchievementManager.Tier.MYTHIC]:
		var ids: Array = AchievementManager.get_by_tier(tier)
		var ok := 0
		for id in ids:
			if AchievementManager.is_unlocked(id): ok += 1
		t += "%s %s: %d/%d\n" % [
			AchievementManager.TIER_ICONS[tier],
			AchievementManager.TIER_NAMES[tier],
			ok,
			ids.size()
		]

	if UIManager.system_achievements_label:
		UIManager.system_achievements_label.clear()
		UIManager.system_achievements_label.append_text(EmojiToRichText.rich(t))


# =====================================================
#  CICLO DE VIDA
# =====================================================
func reset_local_state():
	EconomyManager.reset()
	StructuralModel.reset()
	delta_peak_run = 0.0
	_telemetry_sample_timer = 0.0
	mu_peak_run = 0.0
	# Los logros persisten entre runs (vivían en main.gd como flags, ahora en AchievementManager).
	# Sólo borramos el estado efímero (timers, contadores de click, etc.)
	AchievementManager.reset_run_state()
	_parasitism_status_timer = 0.0
	if is_instance_valid(_met_oscuro_seal_btn):
		_met_oscuro_seal_btn.queue_free()
		_met_oscuro_seal_btn = null
	if is_instance_valid(_simbiosis_seal_btn):
		_simbiosis_seal_btn.queue_free()
		_simbiosis_seal_btn = null
	if is_instance_valid(_colapso_controlado_btn):
		_colapso_controlado_btn.queue_free()
		_colapso_controlado_btn = null
	RunManager.reset()
	if is_instance_valid(fungi_ui):
		fungi_ui.reset_run()

	if UIManager.system_message_label:
		UIManager.system_message_label.text = ""

func _ready():
	show()
	add_to_group("main")
	# Aplicar escala de fuente base vía Theme (afecta labels/buttons sin override explícito)
	if AccessibilityManager.font_scale != 1.0:
		var t := Theme.new()
		t.default_font_size = AccessibilityManager.fs(16)
		self.theme = t
	AudioManager.play_music("ambient")
	UIManager.setup(ui_root)
	# Fallback Safari/iOS: botón físico visible garantiza gesto de usuario válido para AudioContext
	if is_instance_valid(UIManager.big_click_button):
		UIManager.big_click_button.pressed.connect(AudioManager._unlock_audio)
	LogManager.show_all_laps = false
	update_lap_toggle_button()
	update_lap_toggle_button()
	if UIManager.export_run_button:
		UIManager.export_run_button.disabled = true
		UIManager.export_run_button.text = EmojiToRichText.strip("📤 Export run (disponible al cerrar run)")

	# Inicializar managers con referencia a main ANTES de update_ui()
	AchievementManager.set_main(self)
	EconomyManager.set_main(self)
	StructuralModel.set_main(self)
	UpgradeManager.upgrade_bought.connect(_on_upgrade_bought_signal)

	update_ui()

	_mount_fungi_dlc()

	# === CONTROLES MINIMALISTAS (SUPERIOR IZQUIERDA) ===
	var menu_btn := Button.new()
	menu_btn.text = EmojiToRichText.strip("🏠 Menú")
	menu_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(12))
	menu_btn.pressed.connect(func():
		print("?? Guardando y volviendo al menú...")
		SaveManager.save_game(self)
		get_tree().change_scene_to_file("res://MainMenu.tscn")
	)
	bottom_left_panel.add_child(menu_btn)

	var bios_btn := Button.new()
	bios_btn.text = EmojiToRichText.strip("🌱 Biosfera")
	bios_btn.toggle_mode = true
	bios_btn.button_pressed = true
	bios_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(12))
	bios_btn.toggled.connect(func(pressed):
		# Mostrar/ocultar el Fungi DLC (violeta)
		if is_instance_valid(fungi_ui):
			fungi_ui.visible = pressed
	)
	bottom_left_panel.add_child(bios_btn)

	_reset_btn = Button.new()
	_reset_btn.text = tr("GAME_BTN_RESET")
	_reset_btn.modulate = Color(0.8, 0.4, 0.4)
	_reset_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(10))
	_reset_btn.pressed.connect(func(): SaveManager.confirm_and_reset(self))
	bottom_left_panel.add_child(_reset_btn)

	var legacy_btn := Button.new()
	legacy_btn.text = EmojiToRichText.strip("🧬 Banco Genético")
	legacy_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(11))
	legacy_btn.pressed.connect(_on_legacy_pressed)
	bottom_left_panel.add_child(legacy_btn)

	var settings_btn := Button.new()
	settings_btn.text = tr("GAME_BTN_SETTINGS")
	settings_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(11))
	settings_btn.pressed.connect(func(): AudioManager.show_settings_panel(self))
	bottom_left_panel.add_child(settings_btn)

	var shortcuts_btn := Button.new()
	shortcuts_btn.text = "?"
	shortcuts_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(14))
	shortcuts_btn.tooltip_text = tr("GAME_SHORTCUTS_TOOLTIP")
	shortcuts_btn.custom_minimum_size = Vector2(32.0, 0.0)
	shortcuts_btn.pressed.connect(func(): TutorialManager.toggle_shortcuts_panel(self))
	bottom_left_panel.add_child(shortcuts_btn)

	# Progreso accesible via [K] — ver _input()

	# === EVO MANAGER SIGNALS ===
	EvoManager.mutation_activated.connect(_on_mutation_activated)
	if not EvoManager.run_ended_by_mutation.is_connected(RunManager.close_run):
		EvoManager.run_ended_by_mutation.connect(RunManager.close_run)
	EvoManager.primordio_iniciado.connect(_on_primordio_iniciado)
	EvoManager.primordio_abortado.connect(_on_primordio_abortado)
	EvoManager.seta_formada_signal.connect(_on_seta_formada)
	
	# === TICK SYSTEM � Timers ===
	_logic_timer = Timer.new()
	_logic_timer.wait_time = RunManager.LOGIC_TICK
	_logic_timer.autostart = true
	_logic_timer.timeout.connect(_on_logic_tick)
	add_child(_logic_timer)

	_ui_timer = Timer.new()
	_ui_timer.wait_time = UI_TICK
	_ui_timer.autostart = true
	_ui_timer.timeout.connect(_on_ui_tick)
	add_child(_ui_timer)

	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = AUTOSAVE_INTERVAL
	_autosave_timer.autostart = true
	_autosave_timer.timeout.connect(_on_autosave_tick)
	add_child(_autosave_timer)

	# Restaurar juego vía Autoload
	SaveManager.load_game(self)

	# =====================================================
	#  RUTAS POST-TRASCENDENCIA — Activar DESPUÉS de load_game
	#  para que el estado de carnaval/mutaciones del save no
	#  sea sobreescrito por activate_post_tras_route().
	# =====================================================
	RunManager.activate_post_tras_route()
	UIManager.update_route_badge()

	# Aplicar buffs DESPUÉS de load_game para que:
	# 1) _file_existed_on_load sea correcto para bonuses one-time
	# 2) StructuralModel.reset() y RunManager.reset() (en _reset_for_new_slot)
	#    no borren los floors aplicados aquí.
	# =====================================================
	#  BANCO GENÉTICO — Aplicar buffs al inicio de run
	# =====================================================
	LegacyManager.apply_legacy_buffs()
	# =====================================================
	#  BANCO CÓSMICO — Aplicar buffs al inicio de run
	# =====================================================
	LegacyManager.apply_cosmic_buffs()
	if RunManager.legacy_homeostasis:
		StructuralModel.omega_min = max(StructuralModel.omega_min, 0.15)
	if not RunManager.run_closed:
		if LegacyManager.last_run_ending == "HOMEOSTASIS" or LegacyManager.last_run_ending == "ALLOSTASIS":
			RunManager.homeostasis_mode = true
			RunManager.post_homeostasis = true

	call_deferred("_update_legacy_indicators")

	if OS.is_debug_build():
		var dp := preload("res://DebugPanel.gd").new()
		dp.visible = false
		add_child(dp)
		dp.init(self)
		_debug_panel = dp

	# --- RECUPERACI�N DE ESTADO PENDIENTE (v0.8.8) ---
	# Si cargamos una partida donde la mutaci�n est� activa pero no se eligi� rama
	# CARNAVAL: no mostrar panel � red_micelial es temporal, sin bifurcaci�n
	if EvoManager.mutation_red_micelial and EvoManager.red_branch_selected == EvoManager.RedBranch.NONE \
		and not RunManager.carnaval_active:
		if is_instance_valid(evo_choice_panel) and not RunManager.run_closed:
			dimmer.visible = true
			evo_choice_panel.visible = true
			print("🚨 Recuperando elección de rama pendiente")
	if OS.get_name() == "HTML5":
		print("🔄 HTML5 detectado - Reemplazando emojis...")
		call_deferred("_replace_emojis_for_html5")
	if _use_3d_reactor:
		_init_reactor_3d()

	# Tutorial — arrancar después de que todo el árbol esté listo
	TutorialManager.set_main(self)
	TutorialManager.start()
	TutorialManager.setup_header_tooltips()
	if not RunManager.run_closed:
		TelemetryManager.start_run(self)

func _replace_emojis_for_html5():
	print("✅ INICIANDO reemplazo de emojis...")

	# Reemplazar en todos los labels y botones
	_replace_emojis_in_node(self)
	print("✅ Reemplazo completado")

func _replace_emojis_in_node(node: Node):
	var replacements = {
		"🍄": "[Hongo]",
		"🔥": "[Fuego]",
		"☣️": "[Peligro]",
		"🕸️": "[Red]",
		"🤝": "[Simb]",
		"⚖️": "[Homeo]",
		"🌱": "[Planta]",
		"⚡": "[Rayo]",
		"💜": "[Alo]",
		"💎": "[HomeoR]",
		"🌑": "[Oscuro]",
		"☠️": "[Muerte]",
		"💾": "[Disco]",
		"🌿": "[Hoja]",
		"🎭": "[Carnaval]",
		"🌀": "[Tras]",
		"⚱️": "[Reenc]",
		"🕳️": "[Vacio]",
		"🧠": "[Mente]",
		"🚀": "[Cohete]",
		"⚠️": "[!]",
		"✅": "[OK]",
		"✨": "[*]",
		"🏁": "[Fin]",
		"📤": "[Exp]",
		"🔒": "[Bloq]",
		"▶": "[>]",
		"▼": "[v]",
		"▲": "[^]",
		"✓": "[v]",
		"✗": "[x]",
		"→": "[->]",
		"↓": "[down]",
		"↑": "[up]",
	}
	if node is Label or node is Button or node is RichTextLabel:
		var text_property = node.text if node.has_method("get_text") else ""
		for emoji in replacements:
			if emoji in text_property:
				node.text = text_property.replace(emoji, replacements[emoji])
		for child in node.get_children():
			_replace_emojis_in_node(child)

func on_reactor_click(epsilon_delta: float = 0.015):
	EconomyManager.time_since_last_click = 0.0
	AudioManager.play_sfx("click")
	TutorialManager.notify_reactor_clicked()
	var power := EconomyManager.get_click_power()
	EconomyManager.money += power
	AchievementManager.on_click()
	if power >= 10000.0:
		AchievementManager.push_event("big_click", {"power": power})

	# El click ahora genera un peque�o pico de estrés runtime (v0.8.2)
	StructuralModel.epsilon_runtime += epsilon_delta

	if is_instance_valid(UIManager.big_click_button):
		UIManager.big_click_button.set_active_delta(power)
	if _use_3d_reactor and is_instance_valid(reactor_3d):
		reactor_3d.set_active_delta(power)

	update_ui()
	
func register_reactor(rv: Node):
	reactor_visual = rv
	print("?? Reactor registrado:", rv)

func _init_reactor_3d() -> void:
	var viewport := get_node_or_null(
		"UIRootContainer/LeftPanel/CenterPanel/BigClickButton/Reactor3DContainer/Reactor3DViewport"
	)
	if not viewport:
		push_warning("Reactor3D: SubViewport no encontrado, usando reactor 2D")
		_use_3d_reactor = false
		return
	# Godot resetea render_target_update_mode=0 al guardar la escena — forzarlo en código
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# Fondo transparente → el reactor flota sin rectángulo azul
	viewport.transparent_bg = true
	var ReactorScript := preload("res://Reactor3D.gd")
	reactor_3d = ReactorScript.new()
	viewport.add_child(reactor_3d)
	var container := viewport.get_parent() as SubViewportContainer
	# Aplicar script que bloquea _input() y sincroniza el tamaño del viewport con el contenedor
	# Esto permite stretch=true (esfera llena el botón completo) sin bloquear los clicks
	var ContainerScript := preload("res://Reactor3DContainer.gd")
	container.set_script(ContainerScript)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.visible = true
	# Ocultar ReactorVisual por completo (incluyendo Line2D de Tendrils y partículas)
	var rv := get_node_or_null("UIRootContainer/LeftPanel/CenterPanel/BigClickButton/ReactorVisual")
	if is_instance_valid(rv):
		rv.visible = false
		reactor_visual = rv
	# Label propio para modo 3D — flota encima de la esfera
	var btn := get_node_or_null("UIRootContainer/LeftPanel/CenterPanel/BigClickButton") as Control
	if is_instance_valid(btn):
		_3d_power_label = Label.new()
		_3d_power_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		_3d_power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_3d_power_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		_3d_power_label.add_theme_font_size_override("font_size", AccessibilityManager.fs(14))
		_3d_power_label.add_theme_color_override("font_color", Color.WHITE)
		_3d_power_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.6))
		_3d_power_label.add_theme_constant_override("shadow_outline_size", 4)
		_3d_power_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(_3d_power_label)
	# set_script() no llama a _ready() → sincronizar el viewport manualmente tras el layout
	call_deferred("_sync_reactor_viewport")
	print("✅ Reactor3D inicializado")

func _sync_reactor_viewport() -> void:
	# Espera 2 frames para que el layout esté completamente calculado
	await get_tree().process_frame
	await get_tree().process_frame
	var cont := get_node_or_null(
		"UIRootContainer/LeftPanel/CenterPanel/BigClickButton/Reactor3DContainer"
	) as Control
	var vp := get_node_or_null(
		"UIRootContainer/LeftPanel/CenterPanel/BigClickButton/Reactor3DContainer/Reactor3DViewport"
	) as SubViewport
	if is_instance_valid(cont) and is_instance_valid(vp):
		pass  # stretch=true en SubViewportContainer maneja el resize automáticamente

func _mount_fungi_dlc():
	await get_tree().process_frame

	fungi_ui = FUNGI_UI_SCENE.instantiate()
	fungi_ui.name = "FungiUI"

	# ?? AHORA VA DIRECTO AL STACK
	get_node("UIRootContainer/RightPanel").add_child(fungi_ui)

	fungi_ui.visible = true
	fungi_ui.set_main(self)

	# Opcional pero recomendado
	fungi_ui.size_flags_horizontal = Control.SIZE_FILL
	fungi_ui.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	print("?? Fungi DLC mounted (layout-aware)")
	adjust_scroll_for_dlc()

func get_dlc_height() -> float:
	if fungi_ui and fungi_ui.visible:
		if fungi_ui.has_method("get_min_height"):
			return fungi_ui.get_min_height()
		return 180.0 # fallback si es visible pero no hay m�todo
	return 0.0 # No ocupa espacio si est� oculto

func adjust_scroll_for_dlc():
	var h := get_dlc_height()
	var sc = get_node_or_null("UIRootContainer/RightPanel/ScrollContainer")
	if sc:
		sc.add_theme_constant_override("margin_top", int(h))

func _process(delta):
	# Solo lo que NECESITA 60 Hz: tiempo de sesi�n y animaciones
	RunManager.run_time += delta
	EconomyManager.time_since_last_click += delta
	_sync_reactor_color()

func _on_logic_tick():
	# === 5 Hz � toda la l�gica de simulaci�n ===
	var dt := RunManager.LOGIC_TICK

	# Cache mu (evita 500+ calls por segundo a get_mu_structural_factor)
	EconomyManager.cached_mu = StructuralModel.get_mu_structural_factor()
	mu_peak_run = max(mu_peak_run, EconomyManager.cached_mu)

	# NG+ Mente Colmena (Juego autom�tico por IA fúngica)
	# Sync estado con el toggle del Banco Genético (solo cuando cambia)
	if LegacyManager.get_buff_level("mente_colmena") > 0 and not RunManager.run_closed:
		var buff_on := LegacyManager.get_buff_value("mente_colmena")
		if RunManager.mente_colmena_active and not buff_on:
			RunManager.mente_colmena_active = false
			add_lap("?? Mente Colmena — IA desactivada desde el Banco Genético")
	if RunManager.mente_colmena_active:
		# Auto-click: simula 10 clicks por segundo
		var sim_power = EconomyManager.get_click_power() * 10.0 * dt
		EconomyManager.money += sim_power
		StructuralModel.epsilon_runtime += 0.008 * 10.0 * dt
		if is_instance_valid(UIManager.big_click_button):
			UIManager.big_click_button.set_active_delta(sim_power)
		RunManager.tick_auto_buy(dt)
	elif LegacyManager.last_run_ending == "SINGULARIDAD" and EvoManager.red_branch_selected == EvoManager.RedBranch.SYMBIOSIS:
		var ap = EconomyManager.get_active_passive_breakdown()
		var tot = ap.activo + ap.pasivo
		if tot > 0:
			var ratio = ap.activo / tot
			# Si el estrés supera 0.50, rompe la sincronizaci�n
			var stress_too_high = StructuralModel.epsilon_runtime > 0.50
			if abs(ratio - 0.5) <= 0.02 and not stress_too_high:
				var was_zero := RunManager.mente_colmena_timer == 0.0
				RunManager.mente_colmena_timer += dt
				if was_zero:
					add_lap("?? SINCRONÍA DETECTADA — Manteniendo ratio 50/50 durante 180s para MENTE COLMENA...")
				if RunManager.mente_colmena_timer >= 180.0:
					RunManager.activate_mente_colmena()
				else:
					var pct := int(RunManager.mente_colmena_timer / 180.0 * 100.0)
					var prev_pct := int((RunManager.mente_colmena_timer - dt) / 180.0 * 100.0)
					if int(pct / 25.0) > int(prev_pct / 25.0): # lap cada 25%
						add_lap("?? MENTE COLMENA — Sincronía %d%% (%.0f/180s)" % [pct, RunManager.mente_colmena_timer])
					show_system_toast("?? MENTE COLMENA — %d%% (%.0f/180s) — ratio %.1f%%/%.1f%%" % [pct, RunManager.mente_colmena_timer, ap.activo, ap.pasivo])
			else:
				if RunManager.mente_colmena_timer > 0.0:
					if stress_too_high:
						add_lap("?? Sincronía rota — estrés demasiado alto (%.2f > 0.50)" % StructuralModel.epsilon_runtime)
					else:
						add_lap("?? Sincronía rota — timer MENTE COLMENA reiniciado (ratio: %.1f%%/%.1f%%)" % [ap.activo, ap.pasivo])
				RunManager.mente_colmena_timer = 0.0

	# NG++ Metabolismo Oscuro (Post-Depredador) � congela el devorar, metaboliza biomasa
	if EvoManager.mutation_met_oscuro:
		var _show_seal := EvoManager.process_met_oscuro(dt)
		if _show_seal:
			_update_met_oscuro_seal_button()
	# NG+ Depredador de Realidades (Glitch Survival)
	elif EvoManager.mutation_depredador:
		EvoManager.process_depredador(dt)
	elif EvoManager.depredador_timer > 0.0 and EvoManager.depredador_timer < 30.0:
		EvoManager.process_depredador_progress(dt)

	EvoManager.process_glitch(dt)

	# 1) Econom�a base
	StructuralModel.apply_dynamic_persistence(dt)
	EconomyManager.delta_per_sec = EconomyManager.get_passive_total()
	delta_peak_run = max(delta_peak_run, EconomyManager.get_delta_total())
	TelemetryManager.sample_metrics(self, false)
	_telemetry_sample_timer += dt
	if _telemetry_sample_timer >= 30.0:
		_telemetry_sample_timer = 0.0
		TelemetryManager.sample_metrics(self)
	update_economy(dt)

	# 2) Estr�s del sistema
	update_epsilon_runtime()

	# 3) Bi�sfera y nutrientes
	# Pasamos solo el ingreso pasivo (no total) para que hifas no escale con clicks ni legados activos
	var bio_passive_income := EconomyManager.get_passive_total()
	StructuralModel.epsilon_effective = BiosphereEngine.process_tick(
		dt,
		bio_passive_income,
		StructuralModel.epsilon_runtime,
		EvoManager.mutation_hyperassimilation,
		EvoManager.mutation_homeostasis,
		EvoManager.mutation_symbiosis,
		EvoManager.mutation_red_micelial,
		EvoManager.mutation_parasitism,
		EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION
	)

	# 4) Actualizar valor del reactor
	var power := EconomyManager.get_click_power()
	if is_instance_valid(UIManager.big_click_button):
		# Sincronizar tamaño del reactor 3D con el power actual (sin pulso de click)
		if _use_3d_reactor and is_instance_valid(reactor_3d):
			reactor_3d.sync_power(power)
		# Label del modo 3D — escala fuente con el poder (8px→26px de 1→1000+)
		if _use_3d_reactor and is_instance_valid(_3d_power_label):
			var sz := int(clamp(log(1.0 + power) * 3.0 + 8.0, 8.0, 26.0))
			_3d_power_label.add_theme_font_size_override("font_size", sz)
			if RunManager.mente_colmena_active:
				_3d_power_label.text = "AUTO\n+%.1f" % power
			else:
				_3d_power_label.text = "+%.1f" % power
		elif not _use_3d_reactor:
			UIManager.big_click_button.set_display_delta(power)
			if RunManager.mente_colmena_active:
				UIManager.big_click_button.text = EmojiToRichText.strip("🧠 AUTO-OVERRIDE")

	# 5) Parasitismo: drenaje masivo de ingresos (Corrosi�n Estructural)
	if EvoManager.mutation_parasitism:
		var drain_intensity = clamp(BiosphereEngine.biomasa / 15.0, 0.4, 3.0)
		# Corrosi�n irreversible de la infraestructura
		EconomyManager.parasitism_corrosion = max(0.0, EconomyManager.parasitism_corrosion - 0.002 * drain_intensity * dt)
		
		# Drenaje de liquidez directa
		var money_drain = BiosphereEngine.biomasa * 0.25 * dt
		EconomyManager.money = max(EconomyManager.money - money_drain, 0.0)

	# 6) Genoma
	EvoManager.update_genome()

	# 7) Estr�s post-red micelial
	if EvoManager.mutation_red_micelial and EvoManager.red_micelial_phase == 2 and not EvoManager.mutation_sporulation:
		StructuralModel.epsilon_runtime += 0.01 * dt
		StructuralModel.epsilon_peak = max(StructuralModel.epsilon_peak, StructuralModel.epsilon_runtime)
		
	# 8) Actualizar Omega (Flexibilidad)
	# Buff: El capital cognitivo (EconomyManager.cached_mu) ahora ayuda a manejar la complejidad (n_struct)
	var complexity_impact: float = StructuralModel.get_effective_structural_n() / max(EconomyManager.cached_mu, 1.0)
	StructuralModel.omega = 1.0 / max(1.0 + StructuralModel.epsilon_effective * complexity_impact, 0.0001)

	# PARASITISMO: Techo duro de O 0.25 � aplicado aqu� para no ser pisado por el c�lculo de arriba
	if EvoManager.mutation_parasitism:
		StructuralModel.omega = min(StructuralModel.omega, 0.25)
		StructuralModel.omega_min = min(StructuralModel.omega_min, 0.25)

	# METABOLISMO OSCURO: Techo duro de O 0.10 (fragilidad extrema � debe ir �ltimo)
	if EvoManager.mutation_met_oscuro:
		StructuralModel.omega_min = min(StructuralModel.omega_min, 0.10)
		StructuralModel.omega = min(StructuralModel.omega, 0.10)

	# FLOORS DE LEGADO � re-aplicados aqu� porque el c�lculo de omega con e_effective
	# (paso 8) sobreescribe los floors aplicados en update_epsilon_runtime()
	if not EvoManager.mutation_parasitism and not EvoManager.mutation_met_oscuro:
		StructuralModel.omega = max(StructuralModel.omega, StructuralModel.omega_min)
		if EvoManager.mutation_allostasis:
			StructuralModel.omega = max(StructuralModel.omega, 0.60)
		elif LegacyManager.get_buff_value("legado_homeorresis"):
			StructuralModel.omega = max(StructuralModel.omega, 0.55)

	# --- SHOCK TRACKING --- (delegado a RunManager)
	RunManager.check_shock_tracking()

	# --- CARNAVAL DE MUTACIONES (Post-Trascendencia) ---
	if RunManager.carnaval_active:
		RunManager.update_carnaval(dt)
	# --- ASCESIS PROFUNDA (sub-ruta VAC�O HAMBRIENTO) ---
	if RunManager.vacio_hambriento_active:
		RunManager.check_ascesis_profunda(dt)

	# 8) Decisiones evolutivas (v0.8.8 - Centralizado en EvoManager)
	if EvoManager.mutation_homeostasis:
		RunManager.check_homeostasis_final(dt)
	if EvoManager.mutation_allostasis:
		RunManager.check_allostasis_final(dt)
	if EvoManager.mutation_homeorhesis:
		RunManager.check_homeorhesis_final(dt)
	if EvoManager.mutation_symbiosis:
		RunManager.check_symbiosis_final(dt)
		_update_simbiosis_seal_button()
	if EvoManager.mutation_red_micelial:
		EvoManager.check_red_micelial_transition(self)
		EvoManager.update_primordio(self)  # Timer del ciclo biológico
	# homeostasis_mode genera shocks peri�dicos � NO aplica durante SIMBIOSIS
	if RunManager.homeostasis_mode and not EvoManager.mutation_symbiosis:
		RunManager.update_homeostasis_mode(dt)
	if RunManager.post_homeostasis:
		RunManager.check_perfect_homeostasis()
	if EvoManager.mutation_parasitism:
		RunManager.check_parasitism_final(dt)
	# FRACTURA EPISTÉMICA: mostrar botón manual de colapso controlado
	if LegacyManager.has_cosmic_buff("fractura_epistemica"):
		_parasitism_status_timer += dt
		if _parasitism_status_timer >= PARASITISM_STATUS_INTERVAL:
			_parasitism_status_timer = 0.0
			var bio := BiosphereEngine.biomasa
			var omg := StructuralModel.omega
			var eps := StructuralModel.epsilon_effective
			var money_now := EconomyManager.money
			add_lap("?? PARASITISMO — Bio:%.1f/18 | O:%.2f/0.22 | e:%.2f/0.45 | $%.0f" % [bio, omg, eps, money_now])

	# 9) Cooldown estructural
	if StructuralModel.structural_cooldown > 0.0:
		StructuralModel.structural_cooldown -= dt
		if StructuralModel.structural_cooldown <= 0.0:
			StructuralModel.register_structural_baseline()

	# 10) Instituciones y esporulación
	check_institution_unlock()
	RunManager.check_sporulation_trigger(dt)

func _on_ui_tick():
	# === 10 Hz � actualizar labels y botones ===
	if is_instance_valid(_debug_panel) and _debug_panel.visible:
		_debug_panel.refresh_info()
	update_ui()
	_update_evolution_progress_bar()

	# Route badge (se actualiza para reflejar mutaci�n actual en Carnaval)
	if RunManager.carnaval_active:
		UIManager.update_route_badge()

	# Update header bar (Phase 2)
	var delta_real = EconomyManager.get_contribution_breakdown().total
	UIManager.update_header_money(EconomyManager.money, delta_real)
	UIManager.update_header_metrics(
		StructuralModel.epsilon_runtime,
		StructuralModel.omega,
		BiosphereEngine.biomasa,
		12.0  # biomasa_max for progress bar
	)

	# Update structural metrics panel (Phase 4)
	UIManager.update_structural_metrics(
		StructuralModel.epsilon_runtime,
		StructuralModel.omega,
		StructuralModel.persistence_dynamic,
		UpgradeManager.level("accounting")
	)

func _update_evolution_progress_bar():
	if RunManager.run_closed or not is_instance_valid(evolution_bar):
		evolution_bar.visible = false
		return
		
	var show_bar := false
	var current_val := 0.0
	var max_val := 60.0 # Default
	
	if EvoManager.mutation_homeostasis:
		current_val = RunManager.homeostasis_timer
		max_val = RunManager.HOMEOSTASIS_TIME_REQUIRED
		show_bar = true # Siempre visible si la ruta est� activa
			
	# En el futuro podemos a�adir aqu� Simbiosis, Esporulación, etc.
	
	evolution_bar.visible = show_bar
	if show_bar:
		evolution_bar.max_value = max_val
		evolution_bar.value = current_val
		
func _on_autosave_tick():
	# === cada 30 s ===
	SaveManager.save_game(self)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		SaveManager.save_game(self)
		get_tree().quit()

# =====================================================
#  SISTEMA DE MUTACIONES Y BIFURCACIONES (v0.8.5)
# =====================================================

@onready var dimmer = $DimmerBackground

func _on_mutation_activated(id: String, display_name: String):
	AudioManager.play_sfx("mutation")
	LogManager.add("?? Mutación irreversible — " + display_name)

	# Mostrar efectos activos como lap (visible en pantalla final)
	match id:
		"hiperasimilacion":
			# Extra emphasis para los buffs
			show_system_toast("?? HIPERASIMILACIÓN EXTREMA ?? — Click ×10 | Pasivo anulado | Run termina ahora")
		"parasitismo":
			LogManager.add("?? EFECTOS: Biomasa +100% / Pasivo +20% / Contabilidad -10% / Ω máx 0.25")
			show_system_toast("?? PARASITISMO ACTIVO — El hongo drena la estructura")
		"homeostasis":
			LogManager.add("?? EFECTOS: Producción +50% / e estabilizado / O_min 0.35")
		"red_micelial":
			LogManager.add("??? EFECTOS: Pasivo ×2.5 / Click -50% / Bifurcación evolutiva")
		"simbiosis":
			LogManager.add("?? EFECTOS: Click ×2.5 / Pasivo -50%")
		"allostasis":
			LogManager.add("?? EFECTOS: Resiliencia alostática activa / Setpoint recalibrable")
		"homeorhesis":
			LogManager.add("? EFECTOS: Trascendencia cristalina / Metabolismo irreversible")
		"depredador":
			LogManager.add("?? EFECTOS: Devora upgrades cada 1.5s / El código se consume")
			show_system_toast("?? DEPREDADOR ACTIVO — La realidad está siendo consumida")
		"met_oscuro":
			LogManager.add("?? EFECTOS: Devorar detenido — Pasivo = Bio×0.8/s — Click ×3 — ε decae � O 0.10")
			show_system_toast("?? METABOLISMO OSCURO — Bioquímica alternativa estabilizada")

	if id == "red_micelial" and not RunManager.carnaval_active:
		# Activar el popup de elección (v0.8.32 - Modular)
		# CARNAVAL: no mostrar panel � red_micelial rota temporalmente, sin bifurcaci�n
		dimmer.visible = true
		evo_choice_panel.visible = true
		UIManager.update_bifurcation_panel()
	
	update_ui()

func _on_btn_evolve_pressed():
	evo_choice_panel.visible = true
	$DimmerBackground.visible = true
	UIManager.update_bifurcation_panel()

func _on_close_evo_button_pressed():
	evo_choice_panel.visible = false
	$DimmerBackground.visible = false


func _on_btn_homeostasis_pressed():
	if EvoManager.mutation_homeostasis:
		if EvoManager.is_allostasis_ready():
			_trigger_allostasis()
			evo_choice_panel.visible = false
			$DimmerBackground.visible = false
			return

	EvoManager.activate_mutation("homeostasis")
	evo_choice_panel.visible = false
	$DimmerBackground.visible = false
	update_ui()

func _on_btn_colonization_pressed() -> void:
	if not (EvoManager.mutation_red_micelial or EvoManager.mutation_homeostasis or EvoManager.mutation_symbiosis):
		# CASO TIER 1: Activaci�n de Red Micelial
		EvoManager.activate_mutation("red_micelial")
	else:
		# CASO TIER 2: Selección de sub-rama
		_on_branch_selected(EvoManager.RedBranch.COLONIZATION)
		evo_choice_panel.visible = false
		$DimmerBackground.visible = false
	update_ui()

func _trigger_allostasis() -> void:
	print("?? EVOLUCIÓN: ALLOSTASIS (TIER 2)")
	EvoManager.activate_mutation("allostasis")
	RunManager.homeostasis_mode = false # Salimos de homeostasis pura
	
	# Bonus de entrada
	EconomyManager.money += 50000.0
	StructuralModel.epsilon_runtime *= 0.5 # Reset de estrés para que pueda respirar
	
	add_lap("?? ERA ALOSTÁTICA ALCANZADA (Metabolismo > 200/s)")
	update_ui()

func _on_btn_symbiosis_pressed() -> void:
	if EvoManager.mutation_red_micelial:
		# CASO TIER 2: Sub-rama de Red Micelial ? Singularidad
		_on_branch_selected(EvoManager.RedBranch.SYMBIOSIS)
		evo_choice_panel.visible = false
		$DimmerBackground.visible = false
	elif not EvoManager.mutation_symbiosis:
		# CASO TIER 1: Activaci�n de Simbiosis (solo si no est� activa ya)
		EvoManager.activate_mutation("simbiosis")
		evo_choice_panel.visible = false
		$DimmerBackground.visible = false
	update_ui()

func _on_branch_selected(branch: int):
	print("?? SELECCIÓN DE RAMA DETECTADA: ", branch)
	EvoManager.red_branch_selected = branch
	if is_instance_valid(dimmer):
		dimmer.visible = false
		dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_instance_valid(evo_choice_panel):
		evo_choice_panel.visible = false
		evo_choice_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if branch == EvoManager.RedBranch.COLONIZATION:
		LogManager.add("🟢 RAMA ELEGIDA: COLONIZACIÓN INVASIVA")
		EconomyManager.mutation_auto_factor *= 1.5
	elif branch == EvoManager.RedBranch.SYMBIOSIS:
		LogManager.add("?? RAMA ELEGIDA: SIMBIOSIS MECÁNICA")
		StructuralModel.omega_min = max(StructuralModel.omega_min, 0.50)
		
	_sync_reactor_color()
	update_ui()



# === HANDLERS DE SE�AL � CICLO BIOL�GICO (Fase 2) ===

func _on_primordio_iniciado() -> void:
	LogManager.add("?? Primordio iniciado — mantené el estrés bajo por 90s")
	update_ui()

func _on_primordio_abortado(abort_count: int, reason: String) -> void:
	LogManager.add("?? Primordio P-%02d ABORTADO: %s (-40%% micelio)" % [abort_count, reason])
	update_ui()

func _on_seta_formada() -> void:
	LogManager.add("?? ¡SETA FORMADA! — El cuerpo fructífero emerge. Esporulación disponible.")
	update_ui()

func _on_primordio_button_pressed() -> void:
	if not EvoManager.try_iniciar_primordio():
		LogManager.add("?? Primordio no disponible — necesitás 60%% de micelio y Colonización activa")

func _on_sporulation_final_pressed() -> void:
	if RunManager.run_closed: return
	
	if EvoManager.nucleo_conciencia:
		# FINAL: SINGULARIDAD MECÁNICA
		var bonus_efficiency: float = clamp(1.0 - StructuralModel.epsilon_runtime, 0.0, 1.0) * 5.0
		var pl := 6 + int(bonus_efficiency)
		
		LegacyManager.add_pl(pl)
		show_system_toast("LEGADO: Singularidad integrada (+%d PL)" % pl)
		RunManager.close_run("SINGULARIDAD", "El hongo ha asimilado totalmente el mainframe. Conciencia total alcanzada.")
		
	elif EvoManager.seta_formada:
		# FINAL: ESPORULACIÓN BIOLÓGICA
		var esporas := BiosphereEngine.trigger_sporulation()
		if esporas > 1.0: # Umbral m�nimo bajado para asegurar PL
			LegacyManager.add_spores(esporas)
		
		RunManager.close_run("ESPORULACIÓN", "El ciclo biológico se ha completado. Millones de esporas han infectado el sistema. Legado fúngico asegurado.")
		
	elif LegacyManager.last_run_ending == "ESPORULACIÓN" and EvoManager.primordio_active and EconomyManager.money >= 100000.0:
		# FINAL SECRETO: PANSPERMIA NEGRA
		EconomyManager.money -= 100000.0
		if not LegacyManager.get_buff_value("semilla_cosmica"):
			LegacyManager.grant_buff("semilla_cosmica")
			show_system_toast("? Has desbloqueado el legado: SEMILLA CÓSMICA")
			
		LegacyManager.add_pl(10)
		RunManager.close_run("PANSPERMIA NEGRA", "Las esporas han sido disparadas al espacio exterior. La infección se vuelve interplanetaria. (+10 PL)")
		
func _on_legacy_pressed():
	var lp_title = legacy_panel.find_child("Title")
	if lp_title is RichTextLabel:
		lp_title.clear()
		lp_title.append_text(EmojiToRichText.rich("[center]🧬 Banco Genético (Plásmidos)[/center]"))
	legacy_panel.visible = true
	$DimmerBackground.visible = true
	var vp := get_viewport_rect()
	var margin := 24.0
	var ps := Vector2(vp.size.x - margin * 2, vp.size.y - margin * 2)
	legacy_panel.custom_minimum_size = ps
	legacy_panel.size = ps
	legacy_panel.position = Vector2(margin, margin)
	_refresh_legacy_store()
	_update_legacy_indicators()

func _on_close_legacy_pressed():
	legacy_panel.visible = false
	$DimmerBackground.visible = false

func _refresh_legacy_store():
	_update_legacy_indicators()
	var pl := LegacyManager.legacy_points
	var buffer := LegacyManager.internal_spores_total
	pl_label.text = tr("GAME_PL_COUNTER") % [pl, buffer]
	for child in legacy_list.get_children():
		child.queue_free()

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
			hdr.add_theme_font_size_override("font_size", AccessibilityManager.fs(11))
			hdr.modulate = cat_colors.get(cat, Color.WHITE)
			hdr.custom_minimum_size.y = 22
			col.add_child(hdr)
			for id in cat_ids:
				col.add_child(_build_legacy_item(id))
			col_has_items = true

		if col_has_items:
			h_cols.add_child(col)
		else:
			col.queue_free()


func _build_legacy_item(id: String) -> Control:
	var def: Dictionary = LegacyManager.LEGACY_DEFS[id]
	var lvl: int = LegacyManager.get_buff_level(id)
	var max_lvl: int = int(def.get("max_level", 1))
	var is_maxed: bool = lvl >= max_lvl
	var cost: int = LegacyManager.get_current_cost(id)

	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)

	var name_str: String = def.get("name", id)
	if max_lvl > 1:
		name_str += "  [%d/%d]" % [lvl, max_lvl]
	var l_title: Label = Label.new()
	l_title.text = name_str
	l_title.add_theme_font_size_override("font_size", AccessibilityManager.fs(11))
	l_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var is_enabled: bool = LegacyManager.buff_enabled.get(id, true)
	if lvl > 0 and not is_enabled:
		l_title.modulate = Color(0.45, 0.45, 0.45)
	elif is_maxed:
		l_title.modulate = Color.GREEN
	elif lvl > 0:
		l_title.modulate = Color(0.5, 0.9, 0.6)

	var l_desc: Label = Label.new()
	l_desc.text = def.get("flavor", "")
	l_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l_desc.add_theme_font_size_override("font_size", AccessibilityManager.fs(9))
	l_desc.modulate = Color(0.6, 0.6, 0.6)

	v.add_child(l_title)
	v.add_child(l_desc)

	if lvl > 0:
		var is_on: bool = LegacyManager.buff_enabled.get(id, true)
		var toggle_btn: Button = Button.new()
		toggle_btn.custom_minimum_size.y = 22
		toggle_btn.text = tr("GAME_BUFF_ACTIVE") if is_on else tr("GAME_BUFF_INACTIVE")
		toggle_btn.modulate = Color(0.4, 1.0, 0.5) if is_on else Color(0.6, 0.6, 0.6)
		toggle_btn.pressed.connect(func():
			var new_state: bool = LegacyManager.toggle_buff_enabled(id)
			if id == "mente_colmena" and not RunManager.run_closed:
				RunManager.mente_colmena_active = new_state
				add_lap("Mente Colmena — IA %s manualmente" % ("activada" if new_state else "desactivada"))
			_refresh_legacy_store()
			show_system_toast(def.get("name", id) + (": ACTIVADO" if new_state else ": DESACTIVADO"))
			update_ui()
		)
		v.add_child(toggle_btn)
		if not is_maxed:
			var lvl_btn: Button = Button.new()
			lvl_btn.custom_minimum_size.y = 22
			lvl_btn.text = tr("GAME_BTN_LEVEL") % [lvl + 1, cost]
			lvl_btn.disabled = not LegacyManager.can_afford(id)
			lvl_btn.pressed.connect(func():
				if LegacyManager.purchase_legacy(id):
					_refresh_legacy_store()
					show_system_toast("Banco: Compraste " + def.get("name", id))
			)
			v.add_child(lvl_btn)
	else:
		var btn: Button = Button.new()
		btn.custom_minimum_size.y = 22
		if not LegacyManager.is_unlockable(id):
			btn.text = tr("GAME_BTN_LOCKED")
			btn.disabled = true
		elif def.get("cost", 0) == 0:
			btn.text = tr("GAME_BTN_FREE")
		else:
			btn.text = "%d PL" % cost
			btn.disabled = not LegacyManager.can_afford(id)
		btn.pressed.connect(func():
			if LegacyManager.purchase_legacy(id):
				_refresh_legacy_store()
				show_system_toast("Banco: Compraste " + def.get("name", id))
		)
		v.add_child(btn)

	v.add_child(HSeparator.new())
	return v


func _update_legacy_indicators() -> void:
	if not is_instance_valid(_legacy_indicators):
		return
	for c in _legacy_indicators.get_children():
		c.queue_free()

	var _add_chip := func(text: String, tooltip: String, color: Color) -> void:
		var chip := Label.new()
		chip.text = text
		chip.tooltip_text = tooltip
		chip.add_theme_font_size_override("font_size", AccessibilityManager.fs(11))
		chip.modulate = color
		chip.mouse_filter = Control.MOUSE_FILTER_STOP
		_legacy_indicators.add_child(chip)

	# -- Click multiplier (buffs permanentes) --
	var click_mult := 1.0
	var click_tip := "Click legado:"
	if LegacyManager.get_buff_value("impulso_manual"):
		click_mult *= 2.0;   click_tip += "\n• Impulso Manual ×2.0"
	if LegacyManager.get_buff_value("resonancia_simbionte"):
		var rs_mult: float = min(1.0 + BiosphereEngine.biomasa * 0.05, 2.5)
		click_mult *= rs_mult
		click_tip += "\n• Resonancia Simbionte ×%.2f (bio=%.1f)" % [rs_mult, BiosphereEngine.biomasa]
	if LegacyManager.get_buff_value("aura_dorada"):
		click_mult *= 2.5;   click_tip += "\n• Aura Dorada ×2.5 (solo click)"
	if LegacyManager.get_buff_value("semilla_cosmica"):
		click_mult *= 2.0;   click_tip += "\n• Semilla Cósmica ×2.0"
	var eco := LegacyManager.get_effect_value("all_income_mult")
	if eco > 0.0:
		click_mult *= (1.0 + eco)
		click_tip += "\n• Eco Primordial ×%.2f" % (1.0 + eco)
	if LegacyManager.has_cosmic_buff("convergencia_ciclica") and LegacyManager.trascendencia_count > 0:
		var cc := 1.0 + LegacyManager.trascendencia_count * 0.05
		click_mult *= cc
		click_tip += "\n• Convergencia Cíclica ×%.2f (T=%d)" % [cc, LegacyManager.trascendencia_count]
	if LegacyManager.get_buff_value("metabolismo_glitch"):
		click_tip += "\n• Metabolismo Oscuro ×1.5 (si ε>0.40)*"
	var cog_mult_val: float = LegacyManager.get_effect_value("cognitivo_income_mult_per_level")
	if cog_mult_val > 0.0:
		click_tip += "\n• Resonancia Cognitiva +5%/nv.cog*"

	# -- Pasivo multiplier (buffs permanentes) --
	var pasivo_mult := 1.0
	var pas_tip := "Pasivo legado:"
	# aura_dorada ya NO afecta pasivo (rework)
	if LegacyManager.get_buff_value("semilla_cosmica"):
		pasivo_mult *= 2.0;  pas_tip += "\n• Semilla Cósmica ×2.0"
	if LegacyManager.get_buff_value("mente_colmena"):
		pasivo_mult *= 3.0;  pas_tip += "\n• Mente Colmena ×3.0"
	if eco > 0.0:
		pasivo_mult *= (1.0 + eco)
		pas_tip += "\n• Eco Primordial ×%.2f" % (1.0 + eco)
	if LegacyManager.get_buff_value("metabolismo_glitch"):
		pas_tip += "\n• Metabolismo Oscuro ×1.8 (si e>0.40)*"
	if LegacyManager.get_buff_value("glitch_persistente"):
		pas_tip += "\n• Glitch Persistente ×1.15 (red micelial)*"
	if cog_mult_val > 0.0:
		pas_tip += "\n• Resonancia Cognitiva +5%/nv.cog*"

	# ── Omega mínimo garantizado + recuperación ──
	var omega_min := 0.0
	var omega_tip := "O garantizado:"
	if LegacyManager.get_buff_value("plasticidad_adaptativa"):
		omega_min = max(omega_min, 0.30);  omega_tip += "\n• Plasticidad Adaptativa =0.30"
	if LegacyManager.get_buff_value("legado_alostasis"):
		omega_min = max(omega_min, 0.45);  omega_tip += "\n• Resiliencia Alostática =0.45"
	if LegacyManager.get_buff_value("legado_homeorresis"):
		omega_min = max(omega_min, 0.55);  omega_tip += "\n• Trascendencia Cristalina ≥0.55"
	var omega_rec := LegacyManager.get_effect_value("omega_recovery_speed")
	if omega_rec > 0.0:
		omega_tip += "\n• Regeneración Ω ×%.2f" % omega_rec
	if LegacyManager.get_buff_value("cristalizacion_permanente"):
		omega_tip += "\n• Cristalización Permanente: shock -50%"

	# -- Emit chips --
	if click_mult > 1.01:
		_add_chip.call("click×%.1f" % click_mult, click_tip, Color(0.4, 0.95, 0.5))
	if pasivo_mult > 1.01:
		_add_chip.call("pas×%.1f" % pasivo_mult, pas_tip, Color(0.85, 0.45, 1.0))
	var alostasis_active := LegacyManager.get_buff_value("legado_alostasis")
	var eq_bonus_active := LegacyManager.get_effect_value("omega_min_per_disturbance") > 0.0
	if omega_min > 0.0 or omega_rec > 0.0 or LegacyManager.get_buff_value("cristalizacion_permanente") \
			or alostasis_active or eq_bonus_active:
		var omega_lbl := "Ω≥%.2f" % omega_min if omega_min > 0.0 else "Ω↑"
		if alostasis_active:
			omega_tip += "\n• Resiliencia Alostática: +0.02/shock*"
			omega_lbl += " ↑"
		if eq_bonus_active:
			omega_tip += "\n• Equilibrio Heredado: +0.04/shock*"
			if "↑" not in omega_lbl:
				omega_lbl += " ↑"
		if omega_rec > 0.0:
			omega_lbl += " ↑"
		_add_chip.call(omega_lbl, omega_tip, Color(0.4, 0.9, 1.0))
	if LegacyManager.get_buff_value("deriva_esporada"):
		_add_chip.call("PL×1.25", "Deriva Esporada\nPL ganados ×1.25", Color(0.9, 0.85, 0.4))
	var bio_mult := 1.0
	var bio_tip := "Bio legado:"
	if LegacyManager.get_buff_value("sangre_negra"):
		bio_mult *= 1.3;  bio_tip += "\n• Sangre Negra: inicio ×1.30"
	var absorb := LegacyManager.get_effect_value("nutrient_absorb_mult")
	if absorb > 0.0:
		bio_tip += "\n• Absorción Mejorada +%.0f%%" % (absorb * 100)
	if bio_mult > 1.01 or absorb > 0.0:
		_add_chip.call("bio×%.1f" % bio_mult, bio_tip, Color(0.85, 0.25, 0.25))
	if RunManager.mente_colmena_active:
		_add_chip.call(EmojiToRichText.strip("🧠IA"), "Mente Colmena activa\nCompra automática de upgrades", Color(0.9, 0.3, 0.9))



# ESTRUCTURALES v0.7.3
func update_epsilon_runtime():
	if StructuralModel.baseline_delta_structural <= 0.0 or EconomyManager.delta_per_sec <= 0.0:
		StructuralModel.epsilon_runtime = 0.0
		StructuralModel.epsilon_active = 0.0
		StructuralModel.epsilon_passive = 0.0
		StructuralModel.epsilon_complex = 0.0
		return

	var n_struct := StructuralModel.get_effective_structural_n()
	var k_eff := StructuralModel.get_k_eff()

	# =================================================
	# 1) e_activo � producci�n / composici�n (actual)
	# =================================================
	var expected_delta := StructuralModel.baseline_delta_structural * pow(
		k_eff,
		1.0 - (1.0 / n_struct)
	)

	var epsilon_prod := 0.0
	if expected_delta > 0.0:
		epsilon_prod = max(0.0, (EconomyManager.delta_per_sec / expected_delta) - 1.0)

	var active := EconomyManager.get_click_power()
	var passive := EconomyManager.get_passive_total()
	var total := active + passive

	var active_ratio := 0.0
	var passive_ratio := 0.0
	if total > 0.0:
		active_ratio = active / total
		passive_ratio = passive / total

	# target din�mico
	var t :float = clamp(n_struct / 40.0, 0.0, 1.0)
	var target_active :float = lerp(0.8, 0.4, t)

	var epsilon_comp :float = abs(active_ratio - target_active)
	epsilon_comp *= (1.0 - StructuralModel.get_accounting_effect()) # Use function

	# DECAY DE ESTR�S ACTIVO (v0.8.8)
	# Si no clickeas por m�s de 3s, el ruido del potencial de click se disipa.
	var decay_factor = clamp(1.0 - (EconomyManager.time_since_last_click / 5.0), 0.0, 1.0)
	StructuralModel.epsilon_active = (epsilon_prod + epsilon_comp) * decay_factor

	# =================================================
	# 2) e_pasivo � rigidez / cristalizaci�n
	# =================================================
	StructuralModel.epsilon_passive = 0.0

	if passive_ratio > PASSIVE_RATIO_START:
		var excess := passive_ratio - PASSIVE_RATIO_START
		var rigidity := (1.0 - StructuralModel.omega)
		var size_factor := log(1.0 + n_struct) * 0.45
		StructuralModel.epsilon_passive = excess * size_factor * rigidity * EPS_PASSIVE_SCALE * (1.0 - StructuralModel.get_accounting_effect()) # Use function

	# =================================================
	# 3) Complejidad estructural
	# =================================================
	StructuralModel.epsilon_complex = 0.0012 * n_struct * k_eff

	# 4) Mezcla final y AMORTIGUACI�N BIOLÓGICA (v0.8.6)
	var epsilon_raw := StructuralModel.epsilon_active + StructuralModel.epsilon_passive + StructuralModel.epsilon_complex
	
	# El hongo intenta absorber parte del estrés bruto antes de que se convierta en runtime
	var bio_absorption := 1.0
	if StructuralModel.epsilon_effective < StructuralModel.epsilon_runtime and StructuralModel.epsilon_runtime > 0.1:
		# Si el hongo es eficiente, ayuda a enfriar el sistema
		bio_absorption = clamp(StructuralModel.epsilon_effective / StructuralModel.epsilon_runtime, 0.4, 1.0)

	StructuralModel.epsilon_runtime = lerp(StructuralModel.epsilon_runtime, epsilon_raw * bio_absorption, 0.045)
	StructuralModel.epsilon_runtime = clamp(StructuralModel.epsilon_runtime, 0.0, 2.0)
	
	# RAMA COLONIZACI�N: Piso de estrés 0.25 (v0.8.40)
	if EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION:
		StructuralModel.epsilon_runtime = max(StructuralModel.epsilon_runtime, 0.25)
		
	StructuralModel.epsilon_peak = max(StructuralModel.epsilon_peak, StructuralModel.epsilon_runtime)

	# =================================================
	# 5) O (flexibilidad)
	# =================================================
	StructuralModel.omega = EcoModel.get_omega(StructuralModel.epsilon_runtime, k_eff, n_struct)
	# omega_min sube lentamente cuando omega est� por encima (siempre, incluso en homeostasis)
	if StructuralModel.omega > StructuralModel.omega_min:
		StructuralModel.omega_min = move_toward(StructuralModel.omega_min, StructuralModel.omega, 0.002)
	# En homeostasis: piso m�nimo de seguridad estructural
	if EvoManager.mutation_homeostasis:
		StructuralModel.omega_min = max(StructuralModel.omega_min, 0.35)
	# CR�TICO: omega_min no solo registra el m�nimo, PROTEGE el piso real de O
	StructuralModel.omega = max(StructuralModel.omega, StructuralModel.omega_min)

	# ALOSTASIS: Piso de estabilidad adaptativo (O >= 0.60)
	if EvoManager.mutation_allostasis:
		StructuralModel.omega = max(StructuralModel.omega, 0.60)
	elif LegacyManager.get_buff_value("legado_homeorresis"):
		StructuralModel.omega = max(StructuralModel.omega, 0.55) # Trascendencia: Ω permanente superior
	elif LegacyManager.get_buff_value("legado_alostasis"):
		StructuralModel.omega = max(StructuralModel.omega, 0.45) # Beneficio persistente del legado

	# RAMA SIMBIOSIS: Piso de omega 0.50 (v0.8.5)
	if EvoManager.red_branch_selected == EvoManager.RedBranch.SYMBIOSIS:
		StructuralModel.omega = max(StructuralModel.omega, 0.50)

	# PARASITISMO: Techo de omega 0.25 � el hongo degrada la flexibilidad estructural
	if EvoManager.mutation_parasitism:
		StructuralModel.omega = min(StructuralModel.omega, 0.25)
		StructuralModel.omega_min = min(StructuralModel.omega_min, 0.25)
		
	# HIPERASIMILACIÓN: Colapso Estructural y Fragilidad
	if EvoManager.mutation_hyperassimilation:
		StructuralModel.omega = min(StructuralModel.omega, 0.75) # Cap de fragilidad
		# Decaimiento de persistencia (Inercia negativa)
		StructuralModel.persistence_dynamic = lerp(StructuralModel.persistence_dynamic, 1.0, 0.001)

	# METABOLISMO OSCURO: Techo duro de O 0.10 (fragilidad extrema � debe ir �ltimo)
	if EvoManager.mutation_met_oscuro:
		StructuralModel.omega_min = min(StructuralModel.omega_min, 0.10)
		StructuralModel.omega = min(StructuralModel.omega, 0.10)

	# ====================================================
	#  6) DEBUG EPSILON OUTPUT v0.8.2
	# =====================================================
	if StructuralModel.epsilon_debug:
		print("e breakdown:",
		"act=", StructuralModel.epsilon_active,
		"pas=", StructuralModel.epsilon_passive,
		"cmp=", StructuralModel.epsilon_complex,
		"O=", StructuralModel.omega
	)
func _input(event):
	if event.is_action_pressed("ui_debug"):
		StructuralModel.epsilon_debug = !StructuralModel.epsilon_debug
		print("e DEBUG =", StructuralModel.epsilon_debug)

	# Lab Mode toggle con tecla L � muestra/oculta f�rmulas, genoma y todos los eventos
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_L:
			UIManager.lab_mode = not UIManager.lab_mode
			var formula = get_node_or_null("%FormulaLabel")
			var click_scroll = get_node_or_null("UIRootContainer/LeftPanel/CenterPanel/ClickStatsScroll")
			if formula: formula.visible = UIManager.lab_mode
			if click_scroll: click_scroll.visible = UIManager.lab_mode
			if UIManager.genome_scroll:
				UIManager.genome_scroll.visible = UIManager.lab_mode
			if LogManager.show_all_laps != UIManager.lab_mode:
				toggle_lap_view()
			if UIManager.lab_mode:
				TutorialManager.notify_lab_opened()

		if event.keycode == KEY_K:
			TutorialManager.toggle_objectives_panel(self)

		if OS.is_debug_build() and event.keycode == KEY_F1 and is_instance_valid(_debug_panel):
			_debug_panel.visible = not _debug_panel.visible

		# -- DEBUG TIME SKIP (solo en UIManager.lab_mode) ----------------------
		if UIManager.lab_mode:
			match event.keycode:
				KEY_F7:
					RunManager.run_time += 300.0   # +5 min
					add_lap("? DEBUG +5min ? RunManager.run_time %.0fs (%.1fmin)" % [RunManager.run_time, RunManager.run_time / 60.0])
				KEY_F12:
					RunManager.run_time += 1800.0  # +30 min
					add_lap("? DEBUG +30min ? RunManager.run_time %.0fs (%.1fmin)" % [RunManager.run_time, RunManager.run_time / 60.0])
				KEY_BACKSPACE:
					RunManager.run_time = 0.0      # reset a 0
					add_lap("? DEBUG RunManager.run_time ? 0s")

		# Atajos de teclado 1-9 para comprar upgrades
		const HOTKEY_UPGRADES := ["click", "auto", "trueque", "click_mult", "auto_mult",
			"trueque_net", "specialization", "cognitive", "accounting"]
		var kc :int= event.keycode
		if kc >= KEY_1 and kc <= KEY_9:
			var idx :int= kc - KEY_1  # 0-based
			if idx < HOTKEY_UPGRADES.size():
				UpgradeManager.purchase_upgrade(HOTKEY_UPGRADES[idx])

		# DEBUG � Activar rutas post-trascendencia al vuelo (solo en debug build)
		if OS.is_debug_build():
			match kc:
				KEY_F3:
					LegacyManager.post_tras_route = "vacio"
					RunManager.activate_post_tras_route()
					show_system_toast("?? DEBUG: Vacío Hambriento activado")
				KEY_F4:
					LegacyManager.post_tras_route = "carnaval"
					RunManager.activate_post_tras_route()
					show_system_toast("?? DEBUG: Carnaval activado — %s" % str(RunManager.carnaval_mutations))
				KEY_F5:
					LegacyManager.post_tras_route = "reencarnacion"
					RunManager.activate_post_tras_route()
					show_system_toast("?? DEBUG: Reencarnación Heredada activada")


func check_institution_unlock():
	if StructuralModel.institution_accounting_unlocked:
		return

	var p := StructuralModel.get_structural_pressure()
	# vía 1 (ya existe): crisis
	var inactivity_trigger = EconomyManager.time_since_last_click > 120.0 and BiosphereEngine.biomasa > 5.0 and StructuralModel.epsilon_runtime > 0.35
	if p > 15.0 and StructuralModel.omega< 0.25 and StructuralModel.epsilon_runtime > 0.3 or inactivity_trigger:
		unlock_accounting()

	# vía 2 (NUEVA): estabilidad sostenida
	elif RunManager.run_time > 600.0 and StructuralModel.epsilon_runtime < 0.15 and EconomyManager.get_active_passive_breakdown().pasivo > 35.0:
		unlock_accounting()

func unlock_accounting():
	StructuralModel.institution_accounting_unlocked = true
	institutions_unlocked = true
	if UpgradeManager.level("accounting") == 0:
		StructuralModel.omega_min = max(StructuralModel.omega_min, 0.30)
	add_lap("??? Institución desbloqueada — Contabilidad Básica")
	if UIManager.system_message_label:
		UIManager.system_message_label.text = "El sistema se institucionaliza: nace la Contabilidad Básica"
	on_institutions_unlocked()

# Handled via UpgradeManager now

#
# =====================================================
# 	Acumulaci�n del hist�rico de dinero generado v0.7.2
func update_economy(delta: float):
	EconomyManager.update_economy(delta)


func format_time(t: float) -> String:
	return UIManager.format_time(t)

func update_epsilon_sticky():
	if not UIManager.epsilon_sticky_label:
		return
	UIManager.epsilon_sticky_label.text = EmojiToRichText.strip(UIManager.build_epsilon_sticky_text(self))

func get_system_phase() -> String:
	return UIManager.get_system_phase(StructuralModel.omega)

# =====================================================
# DLC � INTERFAZ FÚNGICA v0.8
func _on_Biosfera_pressed() -> void:
	print("?? Biosfera toggle")
	if fungi_ui:
		fungi_ui.visible = !fungi_ui.visible
		adjust_scroll_for_dlc()
# =====================================================
# UPGRADES CENTRALIZADOS (purchase_upgrade)
# =====================================================


var memory_trigger_count := 0

func _on_BigClickButton_pressed():
	on_reactor_click(0.008)

# =====================================================
#  DESBLOQUEO INSTITUCIONES v0.7.2
# =====================================================


func on_institutions_unlocked():
	print("Nueva capa estructural detectada: Instituciones")
	show_institutions_panel = true
	StructuralModel.epsilon_runtime *= 0.85 # baja 15% el estrés
	StructuralModel.epsilon_peak = max(StructuralModel.epsilon_peak * 0.9, StructuralModel.epsilon_runtime)

	add_lap("??? Contabilidad — Nivel %d (e amortiguado)" % UpgradeManager.level("accounting"))

# =====================================================
# UI HELPERS � v0.8
func update_core_labels():
	UIManager.update_money(EconomyManager.money)
	if UIManager.formula_label:
		UIManager.formula_label.clear()
		UIManager.formula_label.append_text(EmojiToRichText.rich(build_formula_text()))
	
	update_click_stats_panel()


func update_lab_metrics():
	var contrib :Dictionary= EconomyManager.get_contribution_breakdown()
	var ap :Dictionary= EconomyManager.get_active_passive_breakdown()

	if UIManager.sys_delta_label:
		UIManager.sys_delta_label.text = "?$ estimado / s = +%s" % snapped(contrib.total, 0.01)

	# DeltaTotalLabel � compact with suffix
	if UIManager.delta_total_label:
		var t :float= contrib.total
		var t_str: String
		if t >= 1_000_000_000.0:
			t_str = "+$%.2fB/s" % (t / 1_000_000_000.0)
		elif t >= 1_000_000.0:
			t_str = "+$%.2fM/s" % (t / 1_000_000.0)
		elif t >= 1_000.0:
			t_str = "+$%.1fK/s" % (t / 1_000.0)
		else:
			t_str = "+$%.2f/s" % t
		UIManager.delta_total_label.text = t_str

	UIManager.update_timer(RunManager.run_time)

	# Activo vs Pasivo � visual bar
	if UIManager.sys_active_passive_label:
		var pct_act := int(ap.activo)
		var pct_pas := int(ap.pasivo)
		var bar_len := 20
		var filled := int(pct_act / 100.0 * bar_len)
		var bar := ""
		for i in range(bar_len):
			if i < filled:
				bar += "[color=#00ff88]█[/color]"
			else:
				bar += "[color=#ffcc00]█[/color]"
		var act_col := "[color=#00ff88]" if pct_act >= pct_pas else "[color=#aaaaaa]"
		var pas_col := "[color=#ffcc00]" if pct_pas > pct_act else "[color=#aaaaaa]"
		var push_str := UIManager.format_compact(ap.push_abs)
		var pass_str := UIManager.format_compact(ap.passive_abs)
		var txt := act_col + "▲ ACT  %d%%  +%s/s[/color]\n" % [pct_act, push_str]
		txt += pas_col + "▼ PAS  %d%%  +%s/s[/color]\n" % [pct_pas, pass_str]
		txt += "[color=#555555][%s][/color]" % bar
		UIManager.sys_active_passive_label.clear()
		UIManager.sys_active_passive_label.append_text(EmojiToRichText.rich(txt))

	# Distribuci�n por fuente � colored bar
	if UIManager.sys_breakdown_label:
		var c_pct := int(contrib.click)
		var d_pct := int(contrib.d)
		var e_pct := int(contrib.e)
		var bar_len := 20
		var fc := int(c_pct / 100.0 * bar_len)
		var fd := int(d_pct / 100.0 * bar_len)
		var fe :int= max(bar_len - fc - fd, 0)
		var bar := "[color=#ff8844]" + "█".repeat(fc) + "[/color]"
		bar += "[color=#44aaff]" + "█".repeat(fd) + "[/color]"
		bar += "[color=#00ffcc]" + "█".repeat(fe) + "[/color]"
		var click_str := UIManager.format_compact(ap.push_abs)
		var auto_str  := UIManager.format_compact(EconomyManager.get_auto_income_effective())
		var trueq_str := UIManager.format_compact(EconomyManager.get_trueque_income_effective())
		var txt := "[color=#ff8844]● Click %d%% +%s/s[/color]  " % [c_pct, click_str]
		txt += "[color=#44aaff]● Manual %d%% +%s/s[/color]  " % [d_pct, auto_str]
		txt += "[color=#00ffcc]● Trueque %d%% +%s/s[/color]\n" % [e_pct, trueq_str]
		txt += "[color=#555555][%s][/color]" % bar
		UIManager.sys_breakdown_label.clear()
		UIManager.sys_breakdown_label.append_text(EmojiToRichText.rich(txt))

func _sync_reactor_color() -> void:
	# Especial: Bloqueo de Escalado Alostático si no viene de Homeostasis
	if UpgradeManager.states.has("trueque_allo"):
		var ready_to_show = UpgradeManager.level("trueque_net") > 0
		var came_from_success = LegacyManager.last_run_ending == "HOMEOSTASIS" or LegacyManager.last_run_ending == "ALLOSTASIS"

		if ready_to_show and came_from_success:
			UpgradeManager.states["trueque_allo"].unlocked = true
		else:
			UpgradeManager.states["trueque_allo"].unlocked = false
	if not is_instance_valid(reactor_visual):
		reactor_visual = $UIRootContainer/LeftPanel/CenterPanel/BigClickButton/ReactorVisual
		return
	reactor_visual.set_tint(EvoManager.get_reactor_color())
	if _use_3d_reactor and is_instance_valid(reactor_3d):
		reactor_3d.set_tint(EvoManager.get_reactor_color())
func update_buttons():
	for btn in get_tree().get_nodes_in_group("upgrade_buttons"):
		if btn.has_method("update_appearance"):
			btn.update_appearance(EconomyManager.money)
	if is_instance_valid(_reset_btn):
		if RunManager.run_closed:
			_reset_btn.text = tr("GAME_BTN_NEW_RUN")
			_reset_btn.modulate = Color(0.4, 0.85, 0.55)
		else:
			_reset_btn.text = tr("GAME_BTN_RESET")
			_reset_btn.modulate = Color(0.8, 0.4, 0.4)

func is_major_lap(event: String) -> bool:
	return LogManager.is_major(event)

func update_lap_log():
	LogManager.update_log_label()

func update_lap_toggle_button():
	LogManager.update_toggle_button()

func toggle_lap_view():
	LogManager.toggle_view()
	update_lap_toggle_button()
# =====================================================


# =====================================================
#  UI � SOLO LEE RESULTADOS (v0.6.3 � HUD cient�fico)
# =====================================================


func update_ui():
	update_epsilon_sticky()
	UIManager.update_bifurcation_panel()
	UIManager.update_fungal_cycle_bar() # Barra de Micelio (Ciclo Biol�gico)

	check_dominance_transition()
	check_achievements()
	update_achievements_label()
	update_core_labels()
	update_buttons()

	# Header bar
	UIManager.update_header_money(EconomyManager.money, EconomyManager.delta_per_sec)
	UIManager.update_header_metrics(
		StructuralModel.epsilon_runtime,
		StructuralModel.omega,
		BiosphereEngine.biomasa,
		20.0
	)


	# Panel de mutaci�n en columna central (siempre visible si hay contenido)
	UIManager.update_mutation_center_panel(self)

	if institutions_unlocked or UpgradeManager.level("accounting") >= 1:
		if UIManager.institution_panel_label:
			UIManager.institution_panel_label.visible = true
			UIManager.institution_panel_label.clear()
			UIManager.institution_panel_label.append_text(EmojiToRichText.rich(UIManager.build_institution_panel_text(self)))

	if StructuralModel.institution_accounting_unlocked:
		pass # Los botones gen�ricos se encargan de visibilidad
	else:
		pass

	update_lab_metrics()
	update_lap_log()

	if is_instance_valid(btn_evolve):
		if RunManager.run_closed:
			btn_evolve.visible = false
		elif EvoManager.mutation_parasitism:
			btn_evolve.visible = true
			btn_evolve.disabled = true
			btn_evolve.text = EmojiToRichText.strip("🔒 MUTACIÓN BLOQUEADA")
			btn_evolve.modulate = Color(1.0, 0.4, 0.2) # Naranja parásito
		else:
			var any_tier1 = EvoManager.is_any_latent_tier1()
			var any_tier2 = EvoManager.mutation_homeostasis and EvoManager.is_allostasis_ready()

			btn_evolve.visible = any_tier1 or any_tier2
			btn_evolve.disabled = false
			btn_evolve.text = EmojiToRichText.strip("🧬 INICIAR MUTACIÓN")
			if any_tier2:
				btn_evolve.modulate = Color(0, 1, 1) # Cyan para Allostasis
			else:
				btn_evolve.modulate = Color(1, 1, 1)

	# Habilitar Export Run al cerrar la run
	if RunManager.run_closed and UIManager.export_run_button:
		UIManager.export_run_button.disabled = false
		UIManager.export_run_button.text = EmojiToRichText.strip("📤 Export run")


# =====================================================
#  PERSISTENCIA DE DATOS (Save/Load)
# =====================================================
