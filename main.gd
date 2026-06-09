extends Control

# =====================================================
# IDLE � v0.8 DLC "Fungi"
# =====================================================
#dlc
const FUNGI_UI_SCENE = preload("res://fungi.tscn")
var fungi_ui: Control

var reactor_visual: Node = null
var _use_3d_reactor: bool = true  # overridden by AccessibilityManager in _ready()
var reactor_3d: Node = null
var _3d_power_label: Label = null

# Parasitismo � status peri�dico
var _parasitism_status_timer := 0.0
const PARASITISM_STATUS_INTERVAL := 45.0


# CONSTANTES DE MODELO (CLICK_RATE vive en EconomyManager.gd)

var mu_peak_run: float = 0.0
var delta_peak_run: float = 0.0
var _telemetry_sample_timer: float = 0.0


var institutions_unlocked: bool = false
var show_institutions_panel: bool = false


# =============== SESIÓN / LAB MODE ===================

var _debug_panel: Panel = null
var _reset_btn: Button = null
var _colapso_controlado_btn: Button = null

# Timers — tick system (no more manual accumulation in _process)
var _logic_timer: Timer
var _ui_timer: Timer
var _autosave_timer: Timer
var _last_ui_tick_ms: int = 0  # debounce: evita update_ui() doble en click + tick simultáneos
const UI_TICK := 0.1                  # 10 Hz — labels & buttons (desktop)
const UI_TICK_WEB := 0.25             # 4 Hz  — web: reduce callUserCallback overhead
const AUTOSAVE_INTERVAL := 30.0

# ================= REFERENCIAS UI ===================
@onready var ui_root = $UIRootContainer
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




# =====================================================
#  VISUALIZACI�N DE LAPS
# =====================================================
func _on_ToggleLapViewButton_pressed():
	LogManager.toggle_view()
	LogManager.update_toggle_button()

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
	var t := tr("UI_ACHIEVEMENTS_HDR") % [got, total] + "\n"
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
	UIManager.reset_ng_plus_buttons()
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
	LogManager.update_toggle_button()
	if UIManager.export_run_button:
		UIManager.export_run_button.disabled = true
		UIManager.export_run_button.text = EmojiToRichText.strip("📤 Export run " + tr("UI_EXPORT_PENDING"))

	# Inicializar managers con referencia a main ANTES de update_ui()
	AchievementManager.set_main(self)
	EconomyManager.set_main(self)
	StructuralModel.set_main(self)
	UpgradeManager.upgrade_bought.connect(_on_upgrade_bought_signal)

	update_ui()

	_mount_fungi_dlc()

	# === CONTROLES MINIMALISTAS (SUPERIOR IZQUIERDA) ===
	var menu_btn := Button.new()
	menu_btn.text = EmojiToRichText.strip("🏠 " + tr("GAME_BTN_MENU"))
	menu_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(12))
	menu_btn.pressed.connect(func():
		SaveManager.save_game(self)
		get_tree().change_scene_to_file("res://MainMenu.tscn")
	)
	bottom_left_panel.add_child(menu_btn)

	_reset_btn = Button.new()
	_reset_btn.text = tr("GAME_BTN_RESET")
	_reset_btn.modulate = Color(0.8, 0.4, 0.4)
	_reset_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(10))
	_reset_btn.pressed.connect(func(): SaveManager.confirm_and_reset(self))
	bottom_left_panel.add_child(_reset_btn)

	var legacy_btn := Button.new()
	legacy_btn.text = EmojiToRichText.strip("🧬 " + tr("BTN_BANCO_GENETICO"))
	legacy_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(11))
	legacy_btn.pressed.connect(UIManager.open_legacy_panel)
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
	_ui_timer.wait_time = UI_TICK_WEB if OS.has_feature("web") else UI_TICK
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

	UIManager.update_legacy_indicators.call_deferred()

	if OS.is_debug_build():
		var dp_script := load("res://DebugPanel.gd")
		if dp_script:
			var dp: Node = dp_script.new()
			dp.visible = false
			add_child(dp)
			dp.init(self)
			_debug_panel = dp

	# --- RECUPERACI�N DE ESTADO PENDIENTE (v0.8.8) ---
	# Si cargamos una partida donde la mutaci�n est� activa pero no se eligi� rama
	# CARNAVAL: no mostrar panel � red_micelial es temporal, sin bifurcaci�n
	if EvoManager.mutation_red_micelial and EvoManager.red_branch_selected == EvoManager.RedBranch.NONE \
		and RouteManager.allows_bifurcation():
		if is_instance_valid(evo_choice_panel) and not RunManager.run_closed:
			dimmer.visible = true
			evo_choice_panel.visible = true
	_use_3d_reactor = AccessibilityManager.reactor_3d_enabled
	if _use_3d_reactor:
		_init_reactor_3d()

	# Tutorial — arrancar después de que todo el árbol esté listo
	TutorialManager.set_main(self)
	TutorialManager.start()
	TutorialManager.setup_header_tooltips()
	if not RunManager.run_closed:
		TelemetryManager.start_run(self)


func on_reactor_click(epsilon_delta: float = 0.015):
	EconomyManager.time_since_last_click = 0.0
	AudioManager.play_sfx("click")
	TutorialManager.notify_reactor_clicked()
	var power := EconomyManager.get_click_power()
	EconomyManager.money += power
	AchievementManager.on_click()
	EvoManager.colonizacion_pulse()  # RAMA VERDE: el click manual empuja la frontera micelial
	if power >= 10000.0:
		AchievementManager.push_event("big_click", {"power": power})

	# El click ahora genera un peque�o pico de estrés runtime (v0.8.2)
	StructuralModel.epsilon_runtime += epsilon_delta

	if is_instance_valid(UIManager.big_click_button):
		UIManager.big_click_button.set_active_delta(power)
	if _use_3d_reactor and is_instance_valid(reactor_3d):
		reactor_3d.set_active_delta(power)

	# Web: debounce — evita update_ui() doble si el tick acaba de correr (<80ms)
	var ms_since_tick := Time.get_ticks_msec() - _last_ui_tick_ms
	if not OS.has_feature("web") or ms_since_tick > 80:
		update_ui()
	
func register_reactor(rv: Node):
	reactor_visual = rv

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

func toggle_reactor_mode(use_3d: bool) -> void:
	if use_3d == _use_3d_reactor:
		return
	_use_3d_reactor = use_3d
	var container := get_node_or_null("UIRootContainer/LeftPanel/CenterPanel/BigClickButton/Reactor3DContainer")
	var rv := get_node_or_null("UIRootContainer/LeftPanel/CenterPanel/BigClickButton/ReactorVisual")
	if use_3d:
		if not is_instance_valid(reactor_3d):
			_init_reactor_3d()
		else:
			if is_instance_valid(container): container.visible = true
			if is_instance_valid(rv): rv.visible = false
			if is_instance_valid(_3d_power_label): _3d_power_label.visible = true
	else:
		if is_instance_valid(container): container.visible = false
		if is_instance_valid(rv): rv.visible = true
		if is_instance_valid(_3d_power_label): _3d_power_label.visible = false


func _mount_fungi_dlc():
	await get_tree().process_frame

	fungi_ui = FUNGI_UI_SCENE.instantiate()
	fungi_ui.name = "FungiUI"

	# ?? AHORA VA DIRECTO AL STACK
	get_node("UIRootContainer/RightPanel").add_child(fungi_ui)

	fungi_ui.visible = false
	fungi_ui.set_main(self)

	# Opcional pero recomendado
	fungi_ui.size_flags_horizontal = Control.SIZE_FILL
	fungi_ui.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	adjust_scroll_for_dlc()

func get_dlc_height() -> float:
	if fungi_ui and fungi_ui.visible:
		if fungi_ui.has_method("get_min_height"):
			return fungi_ui.get_min_height()
		return 180.0 # fallback si es visible pero no hay método
	return 0.0 # No ocupa espacio si está oculto

func adjust_scroll_for_dlc():
	var h := get_dlc_height()
	var sc = get_node_or_null("UIRootContainer/RightPanel/ScrollContainer")
	if sc:
		sc.add_theme_constant_override("margin_top", int(h))

func _process(delta):
	# Solo lo que NECESITA 60 Hz: contadores de tiempo
	RunManager.run_time += delta
	EconomyManager.time_since_last_click += delta
	# _sync_reactor_color() movido a _on_ui_tick — no necesita 60 Hz

func _on_logic_tick():
	# === 5 Hz � toda la l�gica de simulaci�n ===
	var dt := RunManager.LOGIC_TICK

	# Cache mu (evita 500+ calls por segundo a get_mu_structural_factor)
	EconomyManager.cached_mu = StructuralModel.get_mu_structural_factor()
	mu_peak_run = max(mu_peak_run, EconomyManager.cached_mu)

	# NG+ Mente Colmena (Juego autom�tico por IA fúngica)
	# Sync estado con el toggle del Banco Genético (solo cuando cambia)
	RunManager.tick_mc_burst(dt)  # IA = ráfaga activable con cooldown (no permanente)
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
			var eps_ok := StructuralModel.epsilon_runtime >= Balance.MC_GATE_EPS_LO and StructuralModel.epsilon_runtime <= Balance.MC_GATE_EPS_HI
			var flow_ok := EconomyManager.get_delta_total() >= Balance.MC_GATE_DELTA_MIN
			if abs(ratio - 0.5) <= Balance.MC_GATE_RATIO_TOL and eps_ok and flow_ok:
				var was_zero := RunManager.mente_colmena_timer == 0.0
				RunManager.mente_colmena_timer += dt
				if was_zero:
					add_lap(tr("LAP_MC_SINCRONIA") % Balance.MC_GATE_HOLD)
				if RunManager.mente_colmena_timer >= Balance.MC_GATE_HOLD:
					RunManager.activate_mente_colmena()
				else:
					var pct := int(RunManager.mente_colmena_timer / Balance.MC_GATE_HOLD * 100.0)
					var prev_pct := int((RunManager.mente_colmena_timer - dt) / Balance.MC_GATE_HOLD * 100.0)
					if int(pct / 25.0) > int(prev_pct / 25.0): # lap cada 25%
						add_lap(tr("LAP_MC_SYNC_PCT") % [pct, RunManager.mente_colmena_timer, Balance.MC_GATE_HOLD])
					show_system_toast("?? MENTE COLMENA — %d%% (%.0f/%.0fs) — ratio %.1f%%/%.1f%%" % [pct, RunManager.mente_colmena_timer, Balance.MC_GATE_HOLD, ap.activo, ap.pasivo])
			else:
				if RunManager.mente_colmena_timer > 0.0:
					if stress_too_high:
						add_lap(tr("LAP_MC_BROKEN_STRESS") % StructuralModel.epsilon_runtime)
					else:
						add_lap(tr("LAP_MC_BROKEN_RATIO") % [ap.activo, ap.pasivo])
				RunManager.mente_colmena_timer = 0.0

	# NG++ Metabolismo Oscuro (Post-Depredador) — congela el devorar, metaboliza biomasa
	if EvoManager.mutation_met_oscuro:
		EvoManager.process_met_oscuro(dt)
		if EvoManager.mutation_autolisis:
			EvoManager.process_autolisis(dt)
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

	# 2) Estrés del sistema
	StructuralModel.update_runtime()

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
				_3d_power_label.text = "AUTO\n+%d" % int(power)
			else:
				_3d_power_label.text = "+%d" % int(power)
		elif not _use_3d_reactor and is_instance_valid(reactor_visual):
			reactor_visual.set_display_delta(power)

	# 5) Parasitismo: drenaje masivo de ingresos (Corrosi�n Estructural)
	if EvoManager.mutation_parasitism:
		var drain_intensity = clamp(BiosphereEngine.biomasa / 15.0, 0.4, 3.0)
		# Corrosi�n irreversible de la infraestructura
		EconomyManager.parasitism_corrosion = max(0.0, EconomyManager.parasitism_corrosion - 0.002 * drain_intensity * dt)
		
		# Drenaje de liquidez directa
		var money_drain = BiosphereEngine.biomasa * 0.25 * dt
		EconomyManager.money = max(EconomyManager.money - money_drain, 0.0)

	# FRACTURA EPISTÉMICA: interceptar antes de update_genome para ganarle al timeout de HIPER
	if LegacyManager.has_cosmic_buff("fractura_epistemica"):
		RunManager.check_fractura_epistemica(dt)
		if RunManager.run_closed: return

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
	# (paso 8) sobreescribe los floors aplicados en StructuralModel.update_runtime()
	if not EvoManager.mutation_parasitism and not EvoManager.mutation_met_oscuro:
		StructuralModel.omega = max(StructuralModel.omega, StructuralModel.omega_min)
		if EvoManager.mutation_allostasis:
			StructuralModel.omega = max(StructuralModel.omega, 0.60)
		elif LegacyManager.get_buff_value("legado_homeorresis"):
			StructuralModel.omega = max(StructuralModel.omega, 0.55)

	# --- SHOCK TRACKING --- (delegado a RunManager)
	RunManager.check_shock_tracking()
	RunManager.check_ng_cap()

	# --- TICK DE RUTA POST-TRASCENDENCIA ---
	RouteManager.tick(dt)

	# 8) Decisiones evolutivas (v0.8.8 - Centralizado en EvoManager)
	if EvoManager.mutation_homeostasis:
		RunManager.check_homeostasis_final(dt)
	if EvoManager.mutation_allostasis:
		RunManager.check_allostasis_final(dt)
	if EvoManager.mutation_homeorhesis:
		RunManager.check_homeorhesis_final(dt)
	if EvoManager.mutation_symbiosis:
		RunManager.check_symbiosis_final(dt)
	if EvoManager.mutation_red_micelial:
		EvoManager.check_red_micelial_transition(self)
		EvoManager.process_colonizacion(dt)  # Retracciones de la frontera (anti-AFK)
		EvoManager.update_primordio(self)  # Timer del ciclo biológico
		EvoManager.process_panspermia(dt)  # Disipa el calor del lanzamiento (Fase 3)
	# homeostasis_mode genera shocks peri�dicos � NO aplica durante SIMBIOSIS
	if RunManager.homeostasis_mode and not EvoManager.mutation_symbiosis:
		RunManager.update_homeostasis_mode(dt)
	if RunManager.post_homeostasis:
		RunManager.check_perfect_homeostasis()
	if EvoManager.mutation_parasitism and RouteManager.allows_bifurcation():
		RunManager.check_parasitism_final(dt)
		# Status periódico de PARASITISMO (Bio/Ω/ε/$)
		_parasitism_status_timer += dt
		if _parasitism_status_timer >= PARASITISM_STATUS_INTERVAL:
			_parasitism_status_timer = 0.0
			var bio := BiosphereEngine.biomasa
			var omg := StructuralModel.omega
			var eps := StructuralModel.epsilon_effective
			var money_now := EconomyManager.money
			add_lap(tr("LAP_PARASITISMO") % [bio, omg, eps, money_now])

	# 9) Cooldown estructural
	if StructuralModel.structural_cooldown > 0.0:
		StructuralModel.structural_cooldown -= dt
		if StructuralModel.structural_cooldown <= 0.0:
			StructuralModel.register_structural_baseline()

	# 10) Instituciones y esporulación
	check_institution_unlock()
	RunManager.check_sporulation_trigger(dt)

func _on_ui_tick():
	# === 4/10 Hz — actualizar labels y botones ===
	_sync_reactor_color()  # movido desde _process: no necesita 60 Hz
	_last_ui_tick_ms = Time.get_ticks_msec()
	if is_instance_valid(_debug_panel) and _debug_panel.visible:
		_debug_panel.refresh_info()
	update_ui()
	_update_evolution_progress_bar()
	UIManager.update_ng_plus_buttons()

	# Route badge (se actualiza para reflejar mutación actual en Carnaval)
	if RouteManager.is_active("carnaval"):
		UIManager.update_route_badge()

	# Update header bar (Phase 2)
	var delta_real = EconomyManager.get_contribution_breakdown().total
	UIManager.update_header_money(EconomyManager.money, delta_real)
	UIManager.update_header_metrics(
		StructuralModel.epsilon_runtime,
		StructuralModel.omega,
		BiosphereEngine.biomasa,
		12.0,
		BiosphereEngine.hifas,
		BiosphereEngine.nutrientes
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
		max_val = Balance.HOMEOSTASIS_TIME_REQUIRED
		show_bar = true # Siempre visible si la ruta está activa
			
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
	LogManager.add(tr("LOG_MUT_IRREVERSIBLE") % display_name)

	# Mostrar efectos activos como lap (visible en pantalla final)
	match id:
		"hiperasimilacion":
			show_system_toast(tr("MUT_TOAST_HIPERAS"))
		"parasitismo":
			LogManager.add(tr("LOG_MUT_PARASITISMO"))
			show_system_toast(tr("MUT_TOAST_PARASIT"))
		"homeostasis":
			LogManager.add(tr("LOG_MUT_HOMEOSTASIS"))
		"red_micelial":
			LogManager.add(tr("LOG_MUT_RED"))
		"simbiosis":
			LogManager.add(tr("LOG_MUT_SIMBIOSIS"))
		"allostasis":
			LogManager.add(tr("LOG_MUT_ALLOSTASIS"))
		"homeorhesis":
			LogManager.add(tr("LOG_MUT_HOMEORHESIS"))
		"depredador":
			LogManager.add(tr("LOG_MUT_DEPREDADOR"))
			show_system_toast(tr("MUT_TOAST_DEP"))
		"met_oscuro":
			LogManager.add(tr("LOG_MUT_MET_OSCURO"))
			show_system_toast(tr("MUT_TOAST_MO"))

	if id == "red_micelial" and RouteManager.allows_bifurcation():
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


func _on_close_legacy_pressed() -> void:
	UIManager.close_legacy_panel()


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
	EvoManager.activate_mutation("allostasis")
	RunManager.homeostasis_mode = false # Salimos de homeostasis pura
	
	# Bonus de entrada
	EconomyManager.money += 50000.0
	StructuralModel.epsilon_runtime *= 0.5 # Reset de estrés para que pueda respirar
	
	add_lap(tr("LAP_ERA_ALOSTATICA"))
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
	EvoManager.red_branch_selected = branch
	if is_instance_valid(dimmer):
		dimmer.visible = false
		dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_instance_valid(evo_choice_panel):
		evo_choice_panel.visible = false
		evo_choice_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if branch == EvoManager.RedBranch.COLONIZATION:
		LogManager.add(tr("LOG_RAMA_COLONIZACION"))
		EconomyManager.mutation_auto_factor *= 1.5
	elif branch == EvoManager.RedBranch.SYMBIOSIS:
		LogManager.add(tr("LOG_RAMA_SIMBIOSIS"))
		StructuralModel.omega_min = max(StructuralModel.omega_min, 0.50)
		
	_sync_reactor_color()
	update_ui()



# === HANDLERS DE SE�AL � CICLO BIOL�GICO (Fase 2) ===

func _on_primordio_iniciado() -> void:
	LogManager.add(tr("LOG_PRIMORDIO_START"))
	update_ui()

func _on_primordio_abortado(abort_count: int, reason: String) -> void:
	LogManager.add(tr("LOG_PRIMORDIO_ABORT") % [abort_count, reason])
	update_ui()

func _on_seta_formada() -> void:
	LogManager.add(tr("LOG_SETA"))
	update_ui()

func _on_colonize_pulse_pressed() -> void:
	# RAMA VERDE · Empuje de Frontera: el botón dedicado empuja la frontera micelial.
	EvoManager.colonizacion_pulse()
	UIManager.update_fungal_cycle_bar()

func _on_primordio_button_pressed() -> void:
	# Durante el primordio el botón es la acción activa de la rama; antes, inicia el primordio (verde).
	if EvoManager.primordio_active:
		EvoManager.primordio_regar()   # rama verde: regar el primordio (la rama azul sincroniza por condiciones, sin botón)
		UIManager.update_fungal_cycle_bar()
		return
	if not EvoManager.try_iniciar_primordio():
		LogManager.add(tr("LOG_PRIMORDIO_NA"))

func _on_sporulation_final_pressed() -> void:
	if RunManager.run_closed: return
	
	if EvoManager.nucleo_conciencia:
		# FINAL: SINGULARIDAD MECÁNICA
		var bonus_efficiency: float = clamp(1.0 - StructuralModel.epsilon_runtime, 0.0, 1.0) * 5.0
		var pl := 6 + int(bonus_efficiency)
		
		LegacyManager.add_pl(pl)
		LogManager.add(tr("LOG_PL_SINGULARIDAD") % [pl, pl - 6])  # split 6 base + bonus por estabilidad ε
		show_system_toast(tr("TOAST_SINGULARIDAD_PL") % pl)
		RunManager.close_run("SINGULARIDAD", tr("CLOSE_SINGULARIDAD"))
		
	elif EvoManager.seta_formada and EvoManager.is_panspermia_window():
		# FINAL SECRETO: PANSPERMIA NEGRA — secuencia de lanzamiento (Fase 3)
		if EvoManager.panspermia_pulse():
			# Velocidad de escape alcanzada → lanzamiento exitoso.
			if not LegacyManager.get_buff_value("semilla_cosmica"):
				LegacyManager.grant_buff("semilla_cosmica")
				show_system_toast(tr("TOAST_SEMILLA_COSMICA"))
			# El PL (+10) lo otorga y loguea close_run vía Balance.PL_REWARDS (consistencia lore/log).
			RunManager.close_run("PANSPERMIA NEGRA", tr("CLOSE_PANSPERMIA"))
		else:
			update_ui()  # refresca el contador de eyección del botón

	elif EvoManager.seta_formada:
		# FINAL: ESPORULACIÓN BIOLÓGICA
		var esporas := BiosphereEngine.trigger_sporulation()
		if esporas > 1.0: # Umbral mínimo bajado para asegurar PL
			LegacyManager.add_spores(esporas)

		RunManager.close_run("ESPORULACIÓN", tr("CLOSE_ESPORULACION"))
		
# ESTRUCTURALES v0.7.3

func _input(event):
	if event.is_action_pressed("ui_debug"):
		StructuralModel.epsilon_debug = !StructuralModel.epsilon_debug
		print("e DEBUG =", StructuralModel.epsilon_debug)

	# ESC — cerrar panel activo (Settings > Banco Genético > EvoChoice)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if is_instance_valid(AudioManager._settings_panel):
				AudioManager._close_settings_panel()
				get_viewport().set_input_as_handled()
				return
			if is_instance_valid(legacy_panel) and legacy_panel.visible:
				UIManager.close_legacy_panel()
				get_viewport().set_input_as_handled()
				return
			if is_instance_valid(evo_choice_panel) and evo_choice_panel.visible:
				evo_choice_panel.visible = false
				get_viewport().set_input_as_handled()
				return

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
				LogManager.toggle_view()
				LogManager.update_toggle_button()
			if UIManager.lab_mode:
				TutorialManager.notify_lab_opened()

		if event.keycode == KEY_K:
			TutorialManager.toggle_objectives_panel(self)

		if event.keycode == KEY_B:
			if is_instance_valid(fungi_ui):
				fungi_ui.visible = not fungi_ui.visible

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
					show_system_toast("?? DEBUG: Carnaval activado — %s" % str(RouteManager.get_extra_state().get("mutations", [])))
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
	add_lap(tr("LAP_INSTITUCION"))
	if UIManager.system_message_label:
		UIManager.system_message_label.text = tr("MSG_INSTITUTIONS_UNLOCKED")
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
	UIManager.epsilon_sticky_label.text = EmojiToRichText.strip(UITextBuilders.build_epsilon_sticky_text(self))

func get_system_phase() -> String:
	return UIManager.get_system_phase(StructuralModel.omega)

# =====================================================
# DLC � INTERFAZ FÚNGICA v0.8
func _on_Biosfera_pressed() -> void:
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
	show_institutions_panel = true
	StructuralModel.epsilon_runtime *= 0.85 # baja 15% el estrés
	StructuralModel.epsilon_peak = max(StructuralModel.epsilon_peak * 0.9, StructuralModel.epsilon_runtime)

	add_lap(tr("LAP_CONTABILIDAD") % UpgradeManager.level("accounting"))

# =====================================================
# UI HELPERS � v0.8
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
	reactor_visual.set_tint(UIManager.get_reactor_color())
	if _use_3d_reactor and is_instance_valid(reactor_3d):
		reactor_3d.set_tint(UIManager.get_reactor_color())
func update_ui():
	update_epsilon_sticky()
	UIManager.update_bifurcation_panel()
	UIManager.update_fungal_cycle_bar() # Barra de Micelio (Ciclo Biológico)

	check_dominance_transition()
	check_achievements()
	update_achievements_label()
	UIManager.update_core_labels()
	UIManager.update_buttons()

	# Header bar
	UIManager.update_header_money(EconomyManager.money, EconomyManager.delta_per_sec)
	UIManager.update_header_metrics(
		StructuralModel.epsilon_runtime,
		StructuralModel.omega,
		BiosphereEngine.biomasa,
		20.0,
		BiosphereEngine.hifas,
		BiosphereEngine.nutrientes
	)


	# Panel de mutaci�n en columna central (siempre visible si hay contenido)
	UIManager.update_mutation_center_panel(self)

	if institutions_unlocked or UpgradeManager.level("accounting") >= 1:
		if UIManager.institution_panel_label:
			UIManager.institution_panel_label.visible = true
			UIManager.institution_panel_label.clear()
			UIManager.institution_panel_label.append_text(EmojiToRichText.rich(UIManager.build_institution_panel_text(self)))

	if StructuralModel.institution_accounting_unlocked:
		pass # Los botones genéricos se encargan de visibilidad
	else:
		pass

	UIManager.update_lab_metrics()
	LogManager.update_log_label()

	if is_instance_valid(btn_evolve):
		if RunManager.run_closed:
			btn_evolve.visible = false
		elif EvoManager.mutation_parasitism:
			btn_evolve.visible = true
			btn_evolve.disabled = true
			btn_evolve.text = EmojiToRichText.strip("🔒 " + tr("BTN_MUTATION_LOCKED"))
			btn_evolve.modulate = Color(1.0, 0.4, 0.2) # Naranja parásito
		else:
			var any_tier1 = EvoManager.is_any_latent_tier1()
			var any_tier2 = EvoManager.mutation_homeostasis and not EvoManager.mutation_allostasis and EvoManager.is_allostasis_ready()

			btn_evolve.visible = any_tier1 or any_tier2
			btn_evolve.disabled = false
			btn_evolve.text = EmojiToRichText.strip("🧬 " + tr("BTN_MUTATION_START"))
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
