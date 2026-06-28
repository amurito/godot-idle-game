class_name NGPlusButtonManager
extends RefCounted

## Botones dinamicos de las rutas NG+ (arbol oscuro, Fusion Catabolica, simbiosis, etc.)
## del Panel Derecho. Extraido de UIManager (2026-06-27) para acotar su tamano y dar lugar
## a las futuras rutas SOMBRA. Mantiene el estado de las refs a botones; UIManager lo
## instancia en setup() y le delega update_ng_plus_buttons() / reset_ng_plus_buttons().
##
## NOTA: extends RefCounted (no Node) -> tr() y create_tween() no existen aqui.
##   - tr("KEY")      -> TranslationServer.translate("KEY")
##   - create_tween()  -> _scene.create_tween()  (_scene es el nodo raiz de la UI)

var _root: Node    # UIRootContainer -- contiene RightPanel
var _scene: Node   # UIRoot (scene root) -- host de overlays flotantes (dado d20, panel de buffs)

func setup(root: Node, scene: Node) -> void:
	_root = root
	_scene = scene

var _met_oscuro_seal_btn: Button = null
var _esclerocio_btn: Button = null
var _autolisis_btn: Button = null
var _mo_subruta_hint: Label = null
var _autofagia_speed_btn: Button = null
var _autofagia_double_btn: Button = null
var _autofagia_colapso_btn: Button = null
var _autofagia_burst_btn: Button = null   # Digestión Masiva (late: ambas mejoras MAX)
var _dice_overlay: Control = null   # Overlay del dado d20 de Fagocitosis Doble (lazy)
var _dice_face: Label = null        # Label del número del dado
var _dice_caption: Label = null     # Label del resultado (+devours)
var _dice_tween: Tween = null
var _necrosis_btn: Button = null
var _necrosis_agent_btn: Button = null
var _necrosis_purge_btn: Button = null
var _necrosis_catalyst_btn: Button = null
var _omega_cero_btn: Button = null
var _omega_cero_seal_btn: Button = null
var _remision_btn: Button = null
var _remision_up_btn: Button = null
var _remision_down_btn: Button = null
var _remision_seal_btn: Button = null
var _remision_wave: Control = null
var _control_omega_up_btn: Button = null
var _control_omega_down_btn: Button = null
var _depredador_buytime_btn: Button = null
var _mc_override_btn: Button = null
var _fusion_burst_btn: Button = null     # Metabolismo Híbrido (ráfaga ×2) de Fusión Catabólica
var _fusion_cd_btn: Button = null        # Reducción de cooldown de la ráfaga (sink de dinero, tecla W)
var _fusion_seal_btn: Button = null      # Sello del final FUSIÓN CATABÓLICA
var _ayuno_burst_btn: Button = null      # [Q] ROMPER EL AYUNO — burst basado en Silencio
var _ayuno_ascesis_btn: Button = null    # [W] ASCESIS — mejora la tasa de S
var _ayuno_seal_btn: Button = null       # Sello del final AYUNO PRIMORDIAL
var _simbiosis_seal_btn: Button = null
var _run_buffs_btn: Button = null        # Botón "Buffs activos (N)" del panel derecho
var _run_buffs_panel: PanelContainer = null  # Panel flotante con la lista de buffs heredados

func _right_panel() -> Node:
	return _root.get_node_or_null("RightPanel")

## Libera los botones dinámicos de NG+ al resetear la run (llamado desde main.reset_local_state).
func reset_ng_plus_buttons() -> void:
	if is_instance_valid(_met_oscuro_seal_btn):
		_met_oscuro_seal_btn.queue_free()
		_met_oscuro_seal_btn = null
	if is_instance_valid(_depredador_buytime_btn):
		_depredador_buytime_btn.queue_free()
		_depredador_buytime_btn = null
	if is_instance_valid(_simbiosis_seal_btn):
		_simbiosis_seal_btn.queue_free()
		_simbiosis_seal_btn = null
	if is_instance_valid(_esclerocio_btn):
		_esclerocio_btn.queue_free()
		_esclerocio_btn = null
	if is_instance_valid(_autolisis_btn):
		_autolisis_btn.queue_free()
		_autolisis_btn = null
	if is_instance_valid(_mo_subruta_hint):
		_mo_subruta_hint.queue_free()
		_mo_subruta_hint = null
	if is_instance_valid(_autofagia_speed_btn):
		_autofagia_speed_btn.queue_free()
		_autofagia_speed_btn = null
	if is_instance_valid(_autofagia_double_btn):
		_autofagia_double_btn.queue_free()
		_autofagia_double_btn = null
	if is_instance_valid(_autofagia_colapso_btn):
		_autofagia_colapso_btn.queue_free()
		_autofagia_colapso_btn = null
	if is_instance_valid(_autofagia_burst_btn):
		_autofagia_burst_btn.queue_free()
		_autofagia_burst_btn = null
	if is_instance_valid(_necrosis_btn):
		_necrosis_btn.queue_free()
		_necrosis_btn = null
	if is_instance_valid(_necrosis_agent_btn):
		_necrosis_agent_btn.queue_free()
		_necrosis_agent_btn = null
	if is_instance_valid(_necrosis_purge_btn):
		_necrosis_purge_btn.queue_free()
		_necrosis_purge_btn = null
	if is_instance_valid(_necrosis_catalyst_btn):
		_necrosis_catalyst_btn.queue_free()
		_necrosis_catalyst_btn = null
	if is_instance_valid(_omega_cero_btn):
		_omega_cero_btn.queue_free()
		_omega_cero_btn = null
	if is_instance_valid(_omega_cero_seal_btn):
		_omega_cero_seal_btn.queue_free()
		_omega_cero_seal_btn = null
	if is_instance_valid(_remision_btn):
		_remision_btn.queue_free()
		_remision_btn = null
	if is_instance_valid(_remision_up_btn):
		_remision_up_btn.queue_free()
		_remision_up_btn = null
	if is_instance_valid(_remision_down_btn):
		_remision_down_btn.queue_free()
		_remision_down_btn = null
	if is_instance_valid(_remision_seal_btn):
		_remision_seal_btn.queue_free()
		_remision_seal_btn = null
	if is_instance_valid(_remision_wave):
		_remision_wave.queue_free()
		_remision_wave = null
	if is_instance_valid(_control_omega_up_btn):
		_control_omega_up_btn.queue_free()
		_control_omega_up_btn = null
	if is_instance_valid(_control_omega_down_btn):
		_control_omega_down_btn.queue_free()
		_control_omega_down_btn = null
	if is_instance_valid(_run_buffs_btn):
		_run_buffs_btn.queue_free()
		_run_buffs_btn = null
	if is_instance_valid(_run_buffs_panel):
		_run_buffs_panel.queue_free()
		_run_buffs_panel = null
	if is_instance_valid(_fusion_burst_btn):
		_fusion_burst_btn.queue_free()
		_fusion_burst_btn = null
	if is_instance_valid(_fusion_cd_btn):
		_fusion_cd_btn.queue_free()
		_fusion_cd_btn = null
	if is_instance_valid(_fusion_seal_btn):
		_fusion_seal_btn.queue_free()
		_fusion_seal_btn = null
	if is_instance_valid(_ayuno_burst_btn):
		_ayuno_burst_btn.queue_free()
		_ayuno_burst_btn = null
	if is_instance_valid(_ayuno_ascesis_btn):
		_ayuno_ascesis_btn.queue_free()
		_ayuno_ascesis_btn = null
	if is_instance_valid(_ayuno_seal_btn):
		_ayuno_seal_btn.queue_free()
		_ayuno_seal_btn = null

## Actualiza todos los botones dinámicos de NG+. Llamar desde _on_ui_tick().
func update_ng_plus_buttons() -> void:
	_update_met_oscuro_seal_button()
	_update_mo_subruta_hint()
	_update_esclerocio_button()
	_update_autolisis_button()
	_update_autofagia_upgrade_buttons()
	_update_necrosis_button()
	_update_necrosis_agent_button()
	_update_necrosis_catalyst_button()
	_update_necrosis_purge_button()
	_reorder_necrosis_buttons()
	_update_omega_cero_button()
	_update_omega_cero_seal_button()
	_update_remision_button()
	_update_remision_control_buttons()
	_update_remision_seal_button()
	_update_control_omega_buttons()
	_update_depredador_buytime_button()
	_update_mc_override_button()
	_update_fusion_buttons()
	_update_ayuno_buttons()
	_update_simbiosis_seal_button()
	_update_run_buffs_button()

## Fuerza el orden visual Q→W→E (Agent→Catalyst→Purge) en el panel derecho.
## Necesario porque cada botón se crea con move_child(0) en orden de creación,
## resultando en E arriba, W medio, Q abajo. El reorder lo corrige cada tick.
func _reorder_necrosis_buttons() -> void:
	if not EvoManager.mutation_necrosis:
		return
	var panel := _right_panel()
	if panel == null:
		return
	if is_instance_valid(_necrosis_agent_btn):
		panel.move_child(_necrosis_agent_btn, 0)
	if is_instance_valid(_necrosis_catalyst_btn):
		panel.move_child(_necrosis_catalyst_btn, 1)
	if is_instance_valid(_necrosis_purge_btn):
		panel.move_child(_necrosis_purge_btn, 2)

func _update_met_oscuro_seal_button() -> void:
	# Ocultar durante autofagia, necrosis y omega-cero: esas sub-rutas tienen su propio cierre.
	if RunManager.run_closed or EvoManager.mutation_autolisis or EvoManager.mutation_necrosis or EvoManager.mutation_omega_cero or EvoManager.mutation_remision:
		if is_instance_valid(_met_oscuro_seal_btn):
			_met_oscuro_seal_btn.visible = false
		return
	var bio := BiosphereEngine.biomasa
	var pl_seal := 2 if bio < 50.0 else (4 if bio < 100.0 else 6)
	var seal_label := EmojiToRichText.strip("🌑 " + TranslationServer.translate("BTN_SEAL_MO") % pl_seal)
	if _met_oscuro_seal_btn == null or not is_instance_valid(_met_oscuro_seal_btn):
		if not EvoManager.mutation_met_oscuro:
			return
		_met_oscuro_seal_btn = Button.new()
		_met_oscuro_seal_btn.clip_text = true
		_met_oscuro_seal_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(15))
		_met_oscuro_seal_btn.add_theme_color_override("font_color", Color(0.8, 0.5, 1.0))
		_met_oscuro_seal_btn.custom_minimum_size = Vector2(0, 70)
		_met_oscuro_seal_btn.pressed.connect(_on_met_oscuro_seal_pressed)
		var panel := _right_panel()
		if panel:
			panel.add_child(_met_oscuro_seal_btn)
			panel.move_child(_met_oscuro_seal_btn, 0)
	if not EvoManager.mutation_met_oscuro or RunManager.run_closed:
		_met_oscuro_seal_btn.visible = false
		return
	_met_oscuro_seal_btn.text = seal_label
	_met_oscuro_seal_btn.visible = true

func _on_met_oscuro_seal_pressed() -> void:
	if RunManager.run_closed:
		return
	var bio := BiosphereEngine.biomasa
	var pl_bonus := 0 if bio < 50.0 else (-2 if bio < 100.0 else 2)
	if pl_bonus < 0:
		LegacyManager.add_pl(-2)
	elif pl_bonus > 0:
		LegacyManager.add_pl(2)
	if is_instance_valid(_met_oscuro_seal_btn):
		_met_oscuro_seal_btn.visible = false
	var pl_total := 2 if bio < 50.0 else (4 if bio < 100.0 else 6)
	RunManager.close_run("METABOLISMO OSCURO", TranslationServer.translate("CLOSE_MO_VOLUNTARIO") % [bio, pl_total])

func _update_mo_subruta_hint() -> void:
	var any_subruta := EvoManager.mutation_autolisis or EvoManager.mutation_necrosis \
		or EvoManager.mutation_omega_cero or EvoManager.mutation_remision
	var show := EvoManager.mutation_met_oscuro and not RunManager.run_closed \
		and not any_subruta and BiosphereEngine.biomasa < 50.0
	if not show:
		if is_instance_valid(_mo_subruta_hint):
			_mo_subruta_hint.visible = false
		return
	if _mo_subruta_hint == null or not is_instance_valid(_mo_subruta_hint):
		_mo_subruta_hint = Label.new()
		_mo_subruta_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_mo_subruta_hint.add_theme_font_size_override("font_size", AccessibilityManager.fs(12))
		_mo_subruta_hint.add_theme_color_override("font_color", Color(0.65, 0.55, 0.70))
		var panel := _right_panel()
		if panel:
			panel.add_child(_mo_subruta_hint)
			panel.move_child(_mo_subruta_hint, 0)
	_mo_subruta_hint.text = "↻ Sub-rutas disponibles con bio ≥ 50 · actual: %.0f" % BiosphereEngine.biomasa
	_mo_subruta_hint.visible = true

func _update_esclerocio_button() -> void:
	if RunManager.run_closed or not EvoManager.mutation_met_oscuro or EvoManager.mutation_autolisis or EvoManager.mutation_necrosis or EvoManager.mutation_omega_cero or EvoManager.mutation_remision:
		if is_instance_valid(_esclerocio_btn):
			_esclerocio_btn.visible = false
		return
	var devoured_ok: bool = EvoManager.met_oscuro_devoured_count >= Balance.ESCLEROCIO_DEVOURED_REQ
	var bio_ok: bool = BiosphereEngine.biomasa >= Balance.ESCLEROCIO_BIO_REQ
	var eps_ok: bool = StructuralModel.epsilon_runtime < Balance.ESCLEROCIO_EPS_MAX
	if not (devoured_ok and bio_ok and eps_ok):
		if is_instance_valid(_esclerocio_btn):
			_esclerocio_btn.visible = false
		return
	if _esclerocio_btn == null or not is_instance_valid(_esclerocio_btn):
		_esclerocio_btn = Button.new()
		_esclerocio_btn.clip_text = true
		_esclerocio_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(15))
		_esclerocio_btn.add_theme_color_override("font_color", Color(0.7, 0.6, 0.75))
		_esclerocio_btn.custom_minimum_size = Vector2(0, 70)
		_esclerocio_btn.pressed.connect(_on_esclerocio_pressed)
		var panel := _right_panel()
		if panel:
			panel.add_child(_esclerocio_btn)
			panel.move_child(_esclerocio_btn, 0)
	var has_access: bool = LegacyManager.get_buff_value("acceso_esclerocio")
	if not has_access:
		_esclerocio_btn.text = EmojiToRichText.strip("🔒 " + TranslationServer.translate("BTN_ESCLEROCIO"))
		_esclerocio_btn.disabled = true
		_esclerocio_btn.tooltip_text = TranslationServer.translate("TOOLTIP_LOCK_ESCLEROCIO")
	else:
		_esclerocio_btn.text = EmojiToRichText.strip("🌑 " + TranslationServer.translate("BTN_ESCLEROCIO"))
		_esclerocio_btn.disabled = false
		_esclerocio_btn.tooltip_text = ""
	_esclerocio_btn.visible = true

func _on_esclerocio_pressed() -> void:
	if RunManager.run_closed:
		return
	if is_instance_valid(_esclerocio_btn):
		_esclerocio_btn.visible = false
	RunManager.close_run("ESCLEROCIO OSCURO", TranslationServer.translate("CLOSE_ESCLEROCIO"))

func _update_autolisis_button() -> void:
	# Ocultar si MO no activo, ya autólisis/necrosis/omega-cero activa (exclusión mutua), o run cerrada
	if RunManager.run_closed or not EvoManager.mutation_met_oscuro or EvoManager.mutation_autolisis or EvoManager.mutation_necrosis or EvoManager.mutation_omega_cero or EvoManager.mutation_remision:
		if is_instance_valid(_autolisis_btn):
			_autolisis_btn.visible = false
		return
	var bio_ok: bool = BiosphereEngine.biomasa >= Balance.AUTOLISIS_BIO_REQ
	var upgrades_ok: bool = UpgradeManager.get_owned_levels_count() >= Balance.AUTOLISIS_UPGRADES_REQ
	if not (bio_ok and upgrades_ok):
		if is_instance_valid(_autolisis_btn):
			_autolisis_btn.visible = false
		return
	if _autolisis_btn == null or not is_instance_valid(_autolisis_btn):
		_autolisis_btn = Button.new()
		_autolisis_btn.clip_text = true
		_autolisis_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(15))
		_autolisis_btn.add_theme_color_override("font_color", Color(0.9, 0.35, 0.45))
		_autolisis_btn.custom_minimum_size = Vector2(0, 70)
		_autolisis_btn.pressed.connect(_on_autolisis_pressed)
		var panel := _right_panel()
		if panel:
			panel.add_child(_autolisis_btn)
			panel.move_child(_autolisis_btn, 0)
	var has_access: bool = LegacyManager.get_buff_value("acceso_autofagia")
	if not has_access:
		_autolisis_btn.text = EmojiToRichText.strip("🔒 " + TranslationServer.translate("BTN_AUTOLISIS"))
		_autolisis_btn.disabled = true
		_autolisis_btn.tooltip_text = TranslationServer.translate("TOOLTIP_LOCK_AUTOFAGIA")
	else:
		_autolisis_btn.text = EmojiToRichText.strip("🔥 " + TranslationServer.translate("BTN_AUTOLISIS"))
		_autolisis_btn.disabled = false
		_autolisis_btn.tooltip_text = ""
	_autolisis_btn.visible = true

func _on_autolisis_pressed() -> void:
	if RunManager.run_closed or EvoManager.mutation_autolisis or EvoManager.mutation_necrosis:
		return
	if is_instance_valid(_autolisis_btn):
		_autolisis_btn.visible = false
	EvoManager.activate_autolisis()

## Formato corto de dinero para etiquetas de botón ($1.2K / $3.4M).
func _fmt_money_short(amount: float) -> String:
	if amount >= 1e6:
		return "$%.2fM" % (amount / 1e6)
	elif amount >= 1e3:
		return "$%.1fK" % (amount / 1e3)
	return "$%.0f" % amount

## Crea un botón de la zona autofagia (estética carmesí) en el RightPanel.
func _make_autofagia_btn(callback: Callable, font_color: Color) -> Button:
	var b := Button.new()
	b.clip_text = true
	b.add_theme_font_size_override("font_size", AccessibilityManager.fs(14))
	b.add_theme_color_override("font_color", font_color)
	b.custom_minimum_size = Vector2(0, 60)
	b.pressed.connect(callback)
	var panel := _right_panel()
	if panel:
		panel.add_child(b)
		panel.move_child(b, 0)
	return b

## Botones de mejoras de autofagia + colapso voluntario (solo durante autólisis activa).
func _update_autofagia_upgrade_buttons() -> void:
	var active: bool = EvoManager.mutation_autolisis and not RunManager.run_closed
	# Enzimas Líticas (acelerar)
	if active:
		if _autofagia_speed_btn == null or not is_instance_valid(_autofagia_speed_btn):
			_autofagia_speed_btn = _make_autofagia_btn(_on_autofagia_speed_pressed, Color(0.95, 0.5, 0.6))
		var cs: Dictionary = EvoManager.autofagia_upgrade_cost("speed")
		if cs.maxed:
			_autofagia_speed_btn.text = EmojiToRichText.strip("[Q] 🧬 " + TranslationServer.translate("BTN_AUTOFAGIA_SPEED_MAX"))
			_autofagia_speed_btn.disabled = true
		else:
			_autofagia_speed_btn.text = EmojiToRichText.strip("[Q] 🧬 " + TranslationServer.translate("BTN_AUTOFAGIA_SPEED") % [cs.level, Balance.AUTOFAGIA_SPEED_MAX_LEVEL, cs.bio, _fmt_money_short(cs.money)])
			_autofagia_speed_btn.disabled = not EvoManager.can_buy_autofagia_upgrade("speed")
		_autofagia_speed_btn.visible = true
	elif is_instance_valid(_autofagia_speed_btn):
		_autofagia_speed_btn.visible = false
	# Fagocitosis Doble
	if active:
		if _autofagia_double_btn == null or not is_instance_valid(_autofagia_double_btn):
			_autofagia_double_btn = _make_autofagia_btn(_on_autofagia_double_pressed, Color(0.95, 0.4, 0.55))
		var cd: Dictionary = EvoManager.autofagia_upgrade_cost("double")
		if cd.maxed:
			_autofagia_double_btn.text = EmojiToRichText.strip("[W] 🦠 " + TranslationServer.translate("BTN_AUTOFAGIA_DOUBLE_MAX"))
			_autofagia_double_btn.disabled = true
		else:
			var gate_req: int = EvoManager.autofagia_double_gate_req()
			if EvoManager.autolisis_devour_count < gate_req:
				# Gateado por devours: aún no se desbloqueó este nivel.
				_autofagia_double_btn.text = EmojiToRichText.strip("[W] 🦠 " + TranslationServer.translate("BTN_AUTOFAGIA_DOUBLE_GATE") % [cd.level, Balance.AUTOFAGIA_DOUBLE_MAX_LEVEL, EvoManager.autolisis_devour_count, gate_req])
				_autofagia_double_btn.disabled = true
			else:
				var next_pct: int = int(min(Balance.AUTOFAGIA_DOUBLE_MAX_CHANCE, (cd.level + 1) * Balance.AUTOFAGIA_DOUBLE_PER_LEVEL) * 100)
				_autofagia_double_btn.text = EmojiToRichText.strip("[W] 🦠 " + TranslationServer.translate("BTN_AUTOFAGIA_DOUBLE") % [cd.level, Balance.AUTOFAGIA_DOUBLE_MAX_LEVEL, next_pct, cd.bio, _fmt_money_short(cd.money)])
				_autofagia_double_btn.disabled = not EvoManager.can_buy_autofagia_upgrade("double")
		_autofagia_double_btn.visible = true
	elif is_instance_valid(_autofagia_double_btn):
		_autofagia_double_btn.visible = false
	# Colapso voluntario (cierre)
	var colapso_ok: bool = active and EvoManager.autolisis_devour_count >= Balance.AUTOFAGIA_COLAPSO_MIN_DEVOURS
	if colapso_ok:
		if _autofagia_colapso_btn == null or not is_instance_valid(_autofagia_colapso_btn):
			_autofagia_colapso_btn = _make_autofagia_btn(_on_autofagia_colapso_pressed, Color(1.0, 0.78, 0.82))
		_autofagia_colapso_btn.text = EmojiToRichText.strip("[E] 💥 " + TranslationServer.translate("BTN_AUTOFAGIA_COLAPSO"))
		_autofagia_colapso_btn.visible = true
	elif is_instance_valid(_autofagia_colapso_btn):
		_autofagia_colapso_btn.visible = false
	# Digestión Masiva (late): disponible con ambas mejoras en MAX
	var burst_available: bool = active and (EvoManager.autofagia_speed_level >= Balance.AUTOFAGIA_SPEED_MAX_LEVEL) and (EvoManager.autofagia_double_level >= Balance.AUTOFAGIA_DOUBLE_MAX_LEVEL)
	if burst_available:
		if _autofagia_burst_btn == null or not is_instance_valid(_autofagia_burst_btn):
			_autofagia_burst_btn = _make_autofagia_btn(_on_autofagia_burst_pressed, Color(1.0, 0.62, 0.2))
		var cd_left: float = EvoManager.autofagia_burst_cooldown
		var levels_left: int = UpgradeManager.get_owned_levels_count()
		var to_eat: int = maxi(1, levels_left / 2)
		if cd_left > 0.0:
			_autofagia_burst_btn.text = EmojiToRichText.strip("[R] ⚡ " + TranslationServer.translate("BTN_AUTOFAGIA_BURST_CD") % [int(cd_left)])
			_autofagia_burst_btn.disabled = true
		else:
			_autofagia_burst_btn.text = EmojiToRichText.strip("[R] ⚡ " + TranslationServer.translate("BTN_AUTOFAGIA_BURST") % [to_eat, Balance.AUTOFAGIA_BURST_BIO_COST, _fmt_money_short(Balance.AUTOFAGIA_BURST_MONEY_COST)])
			_autofagia_burst_btn.disabled = not EvoManager.can_autofagia_digest_burst()
		_autofagia_burst_btn.visible = true
	elif is_instance_valid(_autofagia_burst_btn):
		_autofagia_burst_btn.visible = false

func _on_autofagia_speed_pressed() -> void:
	EvoManager.buy_autofagia_upgrade("speed")

func _on_autofagia_double_pressed() -> void:
	EvoManager.buy_autofagia_upgrade("double")

func _on_autofagia_colapso_pressed() -> void:
	EvoManager.autofagia_colapsar()

func _on_autofagia_burst_pressed() -> void:
	EvoManager.autofagia_digest_burst()

# ── Dado d20 de Fagocitosis Doble ────────────────────────────────────────────
## Color del resultado según devours extra logrados: 0=rojo (falla), 1=verde, 2=dorado (crítico).
func _dice_result_color(extra: int) -> Color:
	if extra >= 2:
		return Color(1.0, 0.82, 0.25)   # dorado — crítico (triple)
	elif extra == 1:
		return Color(0.45, 0.95, 0.5)   # verde — 2º devour
	return Color(0.95, 0.4, 0.4)        # rojo — sin extra

## Crea (lazy) el overlay del dado: PanelContainer centrado con un Label grande.
func _ensure_dice_overlay() -> void:
	if is_instance_valid(_dice_overlay):
		return
	var pc := PanelContainer.new()
	pc.name = "AutofagiaDiceOverlay"
	pc.z_index = 40
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.04, 0.06, 0.92)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.95, 0.4, 0.55, 0.9)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(14)
	pc.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(vb)
	var face := Label.new()
	face.name = "DiceFace"
	face.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	face.add_theme_font_size_override("font_size", AccessibilityManager.fs(40))
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(face)
	var cap := Label.new()
	cap.name = "DiceCaption"
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_theme_font_size_override("font_size", AccessibilityManager.fs(13))
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(cap)
	pc.visible = false  # oculto hasta el primer roll
	_scene.add_child(pc)
	_dice_overlay = pc
	_dice_face = face
	_dice_caption = cap

## Tick del giro del dado (usado por tween_method; evita lambda multilínea con args).
func _dice_spin(_t: float) -> void:
	if is_instance_valid(_dice_face):
		_dice_face.text = str(randi_range(1, 20))

## Recibe la tirada del d20 desde EvoManager y la muestra (animada o directa según ajustes).
func _on_autofagia_dice_rolled(roll: int, success_min: int, extra: int) -> void:
	_ensure_dice_overlay()
	if not is_instance_valid(_dice_overlay) or not is_instance_valid(_dice_face) or not is_instance_valid(_dice_caption):
		return

	# 1. Matar tween anterior primero → siempre ocultar por si el kill canceló _hide_dice_overlay
	if is_instance_valid(_dice_tween):
		_dice_tween.kill()
	_dice_overlay.visible = false

	# 2. Setup texto/caption
	var result_col := _dice_result_color(extra)
	var cap_text: String = TranslationServer.translate("DICE_EXTRA_2") if extra >= 2 else (TranslationServer.translate("DICE_EXTRA_1") if extra == 1 else TranslationServer.translate("DICE_EXTRA_0"))
	_dice_caption.text = "%s  (≥%d)" % [cap_text, success_min]
	_dice_caption.add_theme_color_override("font_color", result_col)

	# 3. Mostrar y posicionar (después del kill, nunca antes)
	_dice_overlay.modulate.a = 1.0
	_dice_overlay.visible = true
	_dice_overlay.reset_size()
	var vp: Vector2 = _root.get_viewport_rect().size
	_dice_overlay.position = Vector2(vp.x * 0.5 - _dice_overlay.size.x * 0.5, vp.y * 0.22)

	var animate: bool = AccessibilityManager.show_dice_animation and not AccessibilityManager.reduce_motion
	if not animate:
		# Solo resultado: número final fijo, fade-out tras una pausa
		_dice_face.text = str(roll)
		_dice_face.add_theme_color_override("font_color", result_col)
		_dice_tween = _scene.create_tween()
		_dice_tween.tween_interval(0.9)
		_dice_tween.tween_property(_dice_overlay, "modulate:a", 0.0, 0.4)
		_dice_tween.tween_callback(_hide_dice_overlay)
		return

	# Animación: giro de caras (~0.7s) → asentado en el resultado → fade-out
	_dice_face.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	_dice_tween = _scene.create_tween()
	_dice_tween.tween_method(_dice_spin, 0.0, 1.0, 0.7)
	_dice_tween.tween_callback(_settle_dice.bind(roll, result_col))
	_dice_tween.tween_interval(0.8)
	_dice_tween.tween_property(_dice_overlay, "modulate:a", 0.0, 0.4)
	_dice_tween.tween_callback(_hide_dice_overlay)

func _settle_dice(roll: int, col: Color) -> void:
	if is_instance_valid(_dice_face):
		_dice_face.text = str(roll)
		_dice_face.add_theme_color_override("font_color", col)
	AudioManager.play_sfx("upgrade")

func _hide_dice_overlay() -> void:
	if is_instance_valid(_dice_overlay):
		_dice_overlay.visible = false

# ── NECROSIS CONTROLADA ──────────────────────────────────────────────────────
## Botón gate [NECROSIS] (verde cadavérico). Aparece en MO con bio + flujo activo.
func _update_necrosis_button() -> void:
	var hidden: bool = RunManager.run_closed or not EvoManager.mutation_met_oscuro \
		or EvoManager.mutation_necrosis or EvoManager.mutation_autolisis or EvoManager.mutation_omega_cero or EvoManager.mutation_remision
	if hidden:
		if is_instance_valid(_necrosis_btn):
			_necrosis_btn.visible = false
		return
	var bio_ok: bool = BiosphereEngine.biomasa >= Balance.NECROSIS_BIO_REQ
	var flow_ok: bool = EconomyManager.get_delta_total() >= Balance.NECROSIS_FLOW_REQ
	if not (bio_ok and flow_ok):
		if is_instance_valid(_necrosis_btn):
			_necrosis_btn.visible = false
		return
	if _necrosis_btn == null or not is_instance_valid(_necrosis_btn):
		_necrosis_btn = Button.new()
		_necrosis_btn.clip_text = true
		_necrosis_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(15))
		_necrosis_btn.add_theme_color_override("font_color", Color(0.55, 0.7, 0.35))
		_necrosis_btn.custom_minimum_size = Vector2(0, 70)
		_necrosis_btn.pressed.connect(_on_necrosis_pressed)
		var panel := _right_panel()
		if panel:
			panel.add_child(_necrosis_btn)
			panel.move_child(_necrosis_btn, 0)
	var has_access: bool = LegacyManager.get_buff_value("acceso_necrosis")
	if not has_access:
		_necrosis_btn.text = EmojiToRichText.strip("🔒 " + TranslationServer.translate("BTN_NECROSIS"))
		_necrosis_btn.disabled = true
		_necrosis_btn.tooltip_text = TranslationServer.translate("TOOLTIP_LOCK_NECROSIS")
	else:
		_necrosis_btn.text = EmojiToRichText.strip("☠️ " + TranslationServer.translate("BTN_NECROSIS"))
		_necrosis_btn.disabled = false
		_necrosis_btn.tooltip_text = ""
	_necrosis_btn.visible = true

func _on_necrosis_pressed() -> void:
	if RunManager.run_closed or EvoManager.mutation_necrosis:
		return
	if is_instance_valid(_necrosis_btn):
		_necrosis_btn.visible = false
	EvoManager.activate_necrosis()

## Botón de compra de Agentes Necróticos (solo durante necrosis activa).
func _update_necrosis_agent_button() -> void:
	var active: bool = EvoManager.mutation_necrosis and not RunManager.run_closed
	if not active:
		if is_instance_valid(_necrosis_agent_btn):
			_necrosis_agent_btn.visible = false
		return
	if _necrosis_agent_btn == null or not is_instance_valid(_necrosis_agent_btn):
		_necrosis_agent_btn = Button.new()
		_necrosis_agent_btn.clip_text = true
		_necrosis_agent_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(14))
		_necrosis_agent_btn.add_theme_color_override("font_color", Color(0.6, 0.75, 0.4))
		_necrosis_agent_btn.custom_minimum_size = Vector2(0, 60)
		_necrosis_agent_btn.pressed.connect(_on_necrosis_agent_pressed)
		var panel := _right_panel()
		if panel:
			panel.add_child(_necrosis_agent_btn)
			panel.move_child(_necrosis_agent_btn, 0)
	var cost: float = EvoManager.necrosis_agent_cost()
	var idx_pct: int = int(EvoManager.necrosis_index() * 100.0)
	var tox_pct: int = int(EvoManager.necrosis_toxicidad * 100.0)
	_necrosis_agent_btn.text = EmojiToRichText.strip("[Q] 🧫 " + TranslationServer.translate("BTN_NECROSIS_AGENT") % [idx_pct, EvoManager.necromasa, cost, tox_pct])
	_necrosis_agent_btn.disabled = not EvoManager.can_buy_necrosis_agent()
	_necrosis_agent_btn.visible = true

func _on_necrosis_agent_pressed() -> void:
	EvoManager.buy_necrosis_agent()

## Botón de Depuración (limpia toxicidad gastando Ν).
func _update_necrosis_purge_button() -> void:
	# Solo visible si hay tox significativa por encima del floor (purgar cuando = floor no sirve)
	var active: bool = EvoManager.mutation_necrosis and not RunManager.run_closed \
		and EvoManager.necrosis_toxicidad > EvoManager.necrosis_tox_floor() + 0.05
	if not active:
		if is_instance_valid(_necrosis_purge_btn):
			_necrosis_purge_btn.visible = false
		return
	if _necrosis_purge_btn == null or not is_instance_valid(_necrosis_purge_btn):
		_necrosis_purge_btn = Button.new()
		_necrosis_purge_btn.clip_text = true
		_necrosis_purge_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(14))
		_necrosis_purge_btn.add_theme_color_override("font_color", Color(0.7, 0.85, 0.5))
		_necrosis_purge_btn.custom_minimum_size = Vector2(0, 60)
		_necrosis_purge_btn.pressed.connect(_on_necrosis_purge_pressed)
		var panel := _right_panel()
		if panel:
			panel.add_child(_necrosis_purge_btn)
			panel.move_child(_necrosis_purge_btn, 0)
	var pcost: float = EvoManager.necrosis_purge_cost()
	var tox_pct: int = int(EvoManager.necrosis_toxicidad * 100.0)
	var tox_after: int = int(maxf(EvoManager.necrosis_tox_floor(), EvoManager.necrosis_toxicidad * Balance.NECROSIS_PURGE_FRACTION) * 100.0)
	_necrosis_purge_btn.text = EmojiToRichText.strip("[E] 💧 " + TranslationServer.translate("BTN_NECROSIS_PURGE") % [tox_pct, tox_after, pcost])
	_necrosis_purge_btn.disabled = not EvoManager.can_purge_necrosis()
	_necrosis_purge_btn.visible = true

func _on_necrosis_purge_pressed() -> void:
	EvoManager.purge_necrosis()

## Botón Catalizador Necrótico: sink de Ν que acelera la generación de Ν (solo durante necrosis).
func _update_necrosis_catalyst_button() -> void:
	var active: bool = EvoManager.mutation_necrosis and not RunManager.run_closed
	if not active:
		if is_instance_valid(_necrosis_catalyst_btn):
			_necrosis_catalyst_btn.visible = false
		return
	if _necrosis_catalyst_btn == null or not is_instance_valid(_necrosis_catalyst_btn):
		_necrosis_catalyst_btn = Button.new()
		_necrosis_catalyst_btn.clip_text = true
		_necrosis_catalyst_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(14))
		_necrosis_catalyst_btn.add_theme_color_override("font_color", Color(0.75, 0.9, 0.45))
		_necrosis_catalyst_btn.custom_minimum_size = Vector2(0, 60)
		_necrosis_catalyst_btn.pressed.connect(_on_necrosis_catalyst_pressed)
		var panel := _right_panel()
		if panel:
			panel.add_child(_necrosis_catalyst_btn)
			panel.move_child(_necrosis_catalyst_btn, 0)
	var ccost: float = EvoManager.necrosis_catalyst_cost()
	var mult_pct: int = int(EvoManager.necrosis_catalyst_mult() * 100.0)
	_necrosis_catalyst_btn.text = EmojiToRichText.strip("[W] ⚗️ " + TranslationServer.translate("BTN_NECROSIS_CATALYST") % [EvoManager.necrosis_catalyst_level, mult_pct, ccost])
	_necrosis_catalyst_btn.disabled = not EvoManager.can_buy_necrosis_catalyst()
	_necrosis_catalyst_btn.visible = true

func _on_necrosis_catalyst_pressed() -> void:
	EvoManager.buy_necrosis_catalyst()

# ── PROTOCOLO OMEGA-CERO ──────────────────────────────────────────────────────
## Botón gate [PROTOCOLO OMEGA-CERO] (gris violáceo). Aparece en MO si el permiso del
## Banco Genético está comprado y el gate en-run se cumple (bio + devours previos).
func _update_omega_cero_button() -> void:
	if not EvoManager.omega_cero_gate_ready():
		if is_instance_valid(_omega_cero_btn):
			_omega_cero_btn.visible = false
		return
	if _omega_cero_btn == null or not is_instance_valid(_omega_cero_btn):
		_omega_cero_btn = Button.new()
		_omega_cero_btn.clip_text = true
		_omega_cero_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(15))
		_omega_cero_btn.add_theme_color_override("font_color", Color(0.72, 0.6, 0.88))
		_omega_cero_btn.custom_minimum_size = Vector2(0, 70)
		_omega_cero_btn.pressed.connect(_on_omega_cero_pressed)
		var panel := _right_panel()
		if panel:
			panel.add_child(_omega_cero_btn)
			panel.move_child(_omega_cero_btn, 0)
	_omega_cero_btn.text = EmojiToRichText.strip("🕳️ " + TranslationServer.translate("BTN_OMEGA_CERO"))
	_omega_cero_btn.visible = true

func _on_omega_cero_pressed() -> void:
	if RunManager.run_closed or EvoManager.mutation_omega_cero:
		return
	if is_instance_valid(_omega_cero_btn):
		_omega_cero_btn.visible = false
	EvoManager.activate_omega_cero()

## Botón SELLAR PROTOCOLO — disponible cuando se alcanzó el target de Φ (eco escleroidal).
func _update_omega_cero_seal_button() -> void:
	var active: bool = EvoManager.mutation_omega_cero and not RunManager.run_closed
	if not active:
		if is_instance_valid(_omega_cero_seal_btn):
			_omega_cero_seal_btn.visible = false
		return
	if _omega_cero_seal_btn == null or not is_instance_valid(_omega_cero_seal_btn):
		_omega_cero_seal_btn = Button.new()
		_omega_cero_seal_btn.clip_text = true
		_omega_cero_seal_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(14))
		_omega_cero_seal_btn.add_theme_color_override("font_color", Color(0.72, 0.6, 0.88))
		_omega_cero_seal_btn.custom_minimum_size = Vector2(0, 60)
		_omega_cero_seal_btn.pressed.connect(_on_omega_cero_seal_pressed)
		var panel := _right_panel()
		if panel:
			panel.add_child(_omega_cero_seal_btn)
			panel.move_child(_omega_cero_seal_btn, 0)
	var pct: int = int(EvoManager.omega_cero_progress() * 100.0)
	_omega_cero_seal_btn.text = EmojiToRichText.strip("[R] 🕳️ " + TranslationServer.translate("BTN_OMEGA_CERO_SEAL") % [EvoManager.omega_cero_phi, Balance.OMEGA_CERO_PHI_TARGET, pct])
	_omega_cero_seal_btn.disabled = not EvoManager.omega_cero_can_seal()
	_omega_cero_seal_btn.visible = true

func _on_omega_cero_seal_pressed() -> void:
	EvoManager.omega_cero_seal()

# ── REMISIÓN METABÓLICA: botón de activación (gate) ───────────────────────────
func _update_remision_button() -> void:
	if not EvoManager.remision_gate_ready():
		if is_instance_valid(_remision_btn):
			_remision_btn.visible = false
		return
	if _remision_btn == null or not is_instance_valid(_remision_btn):
		_remision_btn = Button.new()
		_remision_btn.clip_text = true
		_remision_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(15))
		_remision_btn.add_theme_color_override("font_color", Color(0.27, 0.87, 0.53))
		_remision_btn.custom_minimum_size = Vector2(0, 70)
		_remision_btn.pressed.connect(_on_remision_pressed)
		var panel := _right_panel()
		if panel:
			panel.add_child(_remision_btn)
			panel.move_child(_remision_btn, 0)
	_remision_btn.text = EmojiToRichText.strip("🌱 " + TranslationServer.translate("BTN_REMISION"))
	_remision_btn.visible = true

func _on_remision_pressed() -> void:
	if RunManager.run_closed or EvoManager.mutation_remision:
		return
	if is_instance_valid(_remision_btn):
		_remision_btn.visible = false
	EvoManager.activate_remision()

# ── REMISIÓN METABÓLICA: botones ± de control de Ω (acción inmediata) ──────────
func _update_remision_control_buttons() -> void:
	var active: bool = EvoManager.mutation_remision and not RunManager.run_closed
	if not active:
		if is_instance_valid(_remision_up_btn):
			_remision_up_btn.visible = false
		if is_instance_valid(_remision_down_btn):
			_remision_down_btn.visible = false
		if is_instance_valid(_remision_wave):
			_remision_wave.visible = false
		return
	if _remision_up_btn == null or not is_instance_valid(_remision_up_btn):
		_remision_up_btn = _make_remision_ctl_btn(_on_remision_up_pressed)
	if _remision_down_btn == null or not is_instance_valid(_remision_down_btn):
		_remision_down_btn = _make_remision_ctl_btn(_on_remision_down_pressed)
	var in_band: bool = EvoManager.remision_in_band()
	var band_hint: String = "✓" if in_band else "…"
	_remision_up_btn.text = EmojiToRichText.strip(TranslationServer.translate("BTN_REMISION_UP") + "  " + band_hint)
	_remision_down_btn.text = EmojiToRichText.strip(TranslationServer.translate("BTN_REMISION_DOWN") + "  " + band_hint)
	_remision_up_btn.visible = true
	_remision_down_btn.visible = true
	var panel := _right_panel()
	if panel:
		panel.move_child(_remision_up_btn, 0)
		panel.move_child(_remision_down_btn, 1)
	# Onda senoidal visual (se crea una sola vez, se reusa)
	if _remision_wave == null or not is_instance_valid(_remision_wave):
		_remision_wave = load("res://RemisionWaveControl.gd").new()
		if panel:
			panel.add_child(_remision_wave)
	_remision_wave.visible = true
	if panel and _remision_wave.get_parent() == panel:
		panel.move_child(_remision_wave, 2)

func _make_remision_ctl_btn(cb: Callable) -> Button:
	var b := Button.new()
	b.clip_text = true
	b.add_theme_font_size_override("font_size", AccessibilityManager.fs(15))
	b.add_theme_color_override("font_color", Color(0.27, 0.87, 0.53))
	b.custom_minimum_size = Vector2(0, 56)
	b.pressed.connect(cb)
	var panel := _right_panel()
	if panel:
		panel.add_child(b)
		panel.move_child(b, 0)
	return b

func _on_remision_up_pressed() -> void:
	EvoManager.remision_nudge(1)

func _on_remision_down_pressed() -> void:
	EvoManager.remision_nudge(-1)

# ── REMISIÓN METABÓLICA: botón de sello (Θ) ───────────────────────────────────
func _update_remision_seal_button() -> void:
	var active: bool = EvoManager.mutation_remision and not RunManager.run_closed
	if not active:
		if is_instance_valid(_remision_seal_btn):
			_remision_seal_btn.visible = false
		return
	if _remision_seal_btn == null or not is_instance_valid(_remision_seal_btn):
		_remision_seal_btn = Button.new()
		_remision_seal_btn.clip_text = true
		_remision_seal_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(14))
		_remision_seal_btn.add_theme_color_override("font_color", Color(0.27, 0.87, 0.53))
		_remision_seal_btn.custom_minimum_size = Vector2(0, 60)
		_remision_seal_btn.pressed.connect(_on_remision_seal_pressed)
		var panel := _right_panel()
		if panel:
			panel.add_child(_remision_seal_btn)
			panel.move_child(_remision_seal_btn, 0)
	var pct: int = int(EvoManager.remision_progress() * 100.0)
	_remision_seal_btn.text = EmojiToRichText.strip("🌸 " + TranslationServer.translate("BTN_REMISION_SEAL") % pct)
	_remision_seal_btn.disabled = not EvoManager.remision_can_seal()
	_remision_seal_btn.visible = true

func _on_remision_seal_pressed() -> void:
	EvoManager.remision_seal()

# ── CONTROL DE Ω (buff NG+): botones ± en runs normales ───────────────────────
func _update_control_omega_buttons() -> void:
	if not EvoManager.control_omega_available():
		if is_instance_valid(_control_omega_up_btn):
			_control_omega_up_btn.visible = false
		if is_instance_valid(_control_omega_down_btn):
			_control_omega_down_btn.visible = false
		return
	if _control_omega_up_btn == null or not is_instance_valid(_control_omega_up_btn):
		_control_omega_up_btn = _make_remision_ctl_btn(_on_control_omega_up_pressed)
	if _control_omega_down_btn == null or not is_instance_valid(_control_omega_down_btn):
		_control_omega_down_btn = _make_remision_ctl_btn(_on_control_omega_down_pressed)
	var off: float = StructuralModel.control_omega_offset
	_control_omega_up_btn.text = EmojiToRichText.strip(TranslationServer.translate("BTN_CONTROL_OMEGA_UP") % off)
	_control_omega_down_btn.text = EmojiToRichText.strip(TranslationServer.translate("BTN_CONTROL_OMEGA_DOWN") % off)
	_control_omega_up_btn.visible = true
	_control_omega_down_btn.visible = true
	var panel := _right_panel()
	if panel:
		panel.move_child(_control_omega_up_btn, 0)
		panel.move_child(_control_omega_down_btn, 1)

func _on_control_omega_up_pressed() -> void:
	EvoManager.control_omega_nudge(1)

func _on_control_omega_down_pressed() -> void:
	EvoManager.control_omega_nudge(-1)

## Botón "Buffs activos (N)" — reúne los buffs heredados (Legado/NG+/Cósmico) en un panel
## desplegable en vez de inundar el lap log al inicio de cada run.
func _update_run_buffs_button() -> void:
	var n: int = LegacyManager.active_run_buffs.size()
	if n == 0:
		if is_instance_valid(_run_buffs_btn):
			_run_buffs_btn.visible = false
		return
	var vbox := _root.get_node_or_null("RightPanel/ScrollContainer/VBoxContainer")
	if vbox == null:
		return
	if _run_buffs_btn == null or not is_instance_valid(_run_buffs_btn):
		_run_buffs_btn = Button.new()
		_run_buffs_btn.clip_text = true
		_run_buffs_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(12))
		_run_buffs_btn.add_theme_color_override("font_color", Color(0.78, 0.72, 1.0))
		_run_buffs_btn.pressed.connect(_toggle_run_buffs_panel)
		vbox.add_child(_run_buffs_btn)
		var anchor := vbox.get_node_or_null("SessionTimeLabel")
		if is_instance_valid(anchor):
			vbox.move_child(_run_buffs_btn, anchor.get_index())
	_run_buffs_btn.text = EmojiToRichText.strip(TranslationServer.translate("BTN_RUN_BUFFS") % n)
	_run_buffs_btn.visible = true

func _toggle_run_buffs_panel() -> void:
	if is_instance_valid(_run_buffs_panel):
		_run_buffs_panel.queue_free()
		_run_buffs_panel = null
		return
	var panel := PanelContainer.new()
	panel.name = "RunBuffsPanel"
	panel.z_index = 50
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.11, 0.98)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.6, 0.5, 0.9, 0.9)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 18.0
	sb.content_margin_right = 18.0
	sb.content_margin_top = 14.0
	sb.content_margin_bottom = 14.0
	panel.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)
	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content = true
	body.scroll_active = false
	body.custom_minimum_size = Vector2(AccessibilityManager.fs(30) * 14.0, 0)
	var txt := "[b]✦ " + TranslationServer.translate("RUN_BUFFS_TITLE") + "[/b]\n\n"
	for b in LegacyManager.active_run_buffs:
		txt += "• " + str(b) + "\n"
	body.append_text(EmojiToRichText.rich(txt))
	vb.add_child(body)
	var close := Button.new()
	close.text = TranslationServer.translate("TUTO_BTN_CLOSE")
	close.add_theme_font_size_override("font_size", AccessibilityManager.fs(14))
	close.pressed.connect(_toggle_run_buffs_panel)
	vb.add_child(close)
	_scene.add_child(panel)
	_run_buffs_panel = panel
	# Centrado-superior sobre el viewport.
	var vp: Vector2 = _scene.get_viewport_rect().size
	panel.position = Vector2(vp.x * 0.5 - AccessibilityManager.fs(30) * 7.5, vp.y * 0.16)

func _update_depredador_buytime_button() -> void:
	if RunManager.run_closed or not EvoManager.mutation_depredador or EvoManager.mutation_met_oscuro:
		if is_instance_valid(_depredador_buytime_btn):
			_depredador_buytime_btn.visible = false
		return
	var cost := EvoManager.depredador_time_cost()
	var ext := Balance.DEP_TIME_EXTENSION
	var btn_label := EmojiToRichText.strip("⏳ " + TranslationServer.translate("BTN_DEP_BUYTIME") % [ext, cost])
	if _depredador_buytime_btn == null or not is_instance_valid(_depredador_buytime_btn):
		_depredador_buytime_btn = Button.new()
		_depredador_buytime_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(18))
		_depredador_buytime_btn.add_theme_color_override("font_color", Color(1.0, 0.55, 0.2))
		_depredador_buytime_btn.custom_minimum_size = Vector2(0, 60)
		_depredador_buytime_btn.pressed.connect(_on_depredador_buytime_pressed)
		var panel := _right_panel()
		if panel:
			panel.add_child(_depredador_buytime_btn)
			panel.move_child(_depredador_buytime_btn, 0)
	_depredador_buytime_btn.text = btn_label
	_depredador_buytime_btn.disabled = BiosphereEngine.biomasa < cost
	_depredador_buytime_btn.visible = true

func _on_depredador_buytime_pressed() -> void:
	EvoManager.buy_depredador_time()
	_update_depredador_buytime_button()

func _update_mc_override_button() -> void:
	if RunManager.run_closed or not LegacyManager.get_buff_value("mente_colmena"):
		if is_instance_valid(_mc_override_btn):
			_mc_override_btn.visible = false
		return
	if _mc_override_btn == null or not is_instance_valid(_mc_override_btn):
		_mc_override_btn = Button.new()
		_mc_override_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(16))
		_mc_override_btn.add_theme_color_override("font_color", Color(0.65, 0.45, 1.0))
		_mc_override_btn.custom_minimum_size = Vector2(0, 50)
		_mc_override_btn.pressed.connect(_on_mc_override_pressed)
		var panel := _right_panel()
		if panel:
			panel.add_child(_mc_override_btn)
			panel.move_child(_mc_override_btn, 0)
	if RunManager.mc_burst_timer > 0.0:
		_mc_override_btn.text = EmojiToRichText.strip(TranslationServer.translate("BTN_MC_ACTIVE") % RunManager.mc_burst_timer)
		_mc_override_btn.disabled = true
	elif RunManager.mc_cooldown_timer > 0.0:
		_mc_override_btn.text = EmojiToRichText.strip(TranslationServer.translate("BTN_MC_COOLDOWN") % RunManager.mc_cooldown_timer)
		_mc_override_btn.disabled = true
	else:
		_mc_override_btn.text = EmojiToRichText.strip(TranslationServer.translate("BTN_MC_READY") % Balance.MC_BURST_DURATION)
		_mc_override_btn.disabled = false
	_mc_override_btn.visible = true

func _on_mc_override_pressed() -> void:
	RunManager.activate_mc_burst()
	_update_mc_override_button()

# ── FUSIÓN CATABÓLICA (transmutación): Metabolismo Híbrido + sello ──
func _update_fusion_buttons() -> void:
	_update_fusion_burst_button()
	_update_fusion_cd_button()
	_update_fusion_seal_button()

func _update_fusion_burst_button() -> void:
	if RunManager.run_closed or not EvoManager.mutation_fusion_catabolica:
		if is_instance_valid(_fusion_burst_btn):
			_fusion_burst_btn.visible = false
		return
	if _fusion_burst_btn == null or not is_instance_valid(_fusion_burst_btn):
		_fusion_burst_btn = Button.new()
		_fusion_burst_btn.clip_text = true
		_fusion_burst_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(16))
		_fusion_burst_btn.add_theme_color_override("font_color", Color(0.3, 0.95, 0.8))
		_fusion_burst_btn.custom_minimum_size = Vector2(0, 50)
		_fusion_burst_btn.pressed.connect(_on_fusion_burst_pressed)
		var panel := _right_panel()
		if panel:
			panel.add_child(_fusion_burst_btn)
			panel.move_child(_fusion_burst_btn, 0)
	if EvoManager.fusion_burst_timer > 0.0:
		_fusion_burst_btn.text = EmojiToRichText.strip(TranslationServer.translate("BTN_FUSION_ACTIVE") % EvoManager.fusion_burst_timer)
		_fusion_burst_btn.disabled = true
	elif EvoManager.fusion_burst_cooldown > 0.0:
		_fusion_burst_btn.text = EmojiToRichText.strip(TranslationServer.translate("BTN_FUSION_COOLDOWN") % EvoManager.fusion_burst_cooldown)
		_fusion_burst_btn.disabled = true
	else:
		_fusion_burst_btn.text = EmojiToRichText.strip(TranslationServer.translate("BTN_FUSION_READY") % Balance.FUSION_BURST_DURATION)
		_fusion_burst_btn.disabled = false
	_fusion_burst_btn.visible = true

func _on_fusion_burst_pressed() -> void:
	EvoManager.activate_fusion_burst()
	_update_fusion_burst_button()

func _update_fusion_cd_button() -> void:
	if RunManager.run_closed or not EvoManager.mutation_fusion_catabolica:
		if is_instance_valid(_fusion_cd_btn):
			_fusion_cd_btn.visible = false
		return
	if _fusion_cd_btn == null or not is_instance_valid(_fusion_cd_btn):
		_fusion_cd_btn = Button.new()
		_fusion_cd_btn.clip_text = true
		_fusion_cd_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(15))
		_fusion_cd_btn.add_theme_color_override("font_color", Color(0.97, 0.82, 0.3))
		_fusion_cd_btn.custom_minimum_size = Vector2(0, 46)
		_fusion_cd_btn.pressed.connect(_on_fusion_cd_pressed)
		var panel := _right_panel()
		if panel:
			panel.add_child(_fusion_cd_btn)
			panel.move_child(_fusion_cd_btn, 1)  # debajo del botón de ráfaga
	if EvoManager.fusion_cd_maxed():
		_fusion_cd_btn.text = EmojiToRichText.strip(TranslationServer.translate("BTN_FUSION_CD_MAXED") % Balance.FUSION_CD_FLOOR)
		_fusion_cd_btn.disabled = true
	else:
		var cur_cd := EvoManager.fusion_effective_cooldown()
		var next_cd := maxf(Balance.FUSION_CD_FLOOR, Balance.FUSION_BURST_COOLDOWN * pow(1.0 - Balance.FUSION_CD_REDUCE_PCT, EvoManager.fusion_cd_level + 1))
		var cost := EvoManager.fusion_cd_cost()
		_fusion_cd_btn.text = EmojiToRichText.strip(TranslationServer.translate("BTN_FUSION_CD") % [cur_cd, next_cd, UITextBuilders.format_compact(cost)])
		_fusion_cd_btn.disabled = not EvoManager.can_buy_fusion_cd()
	_fusion_cd_btn.visible = true

func _on_fusion_cd_pressed() -> void:
	EvoManager.buy_fusion_cd()
	_update_fusion_cd_button()

func _update_fusion_seal_button() -> void:
	if RunManager.run_closed or not EvoManager.mutation_fusion_catabolica or not EvoManager.fusion_seal_ready():
		if is_instance_valid(_fusion_seal_btn):
			_fusion_seal_btn.visible = false
		return
	if _fusion_seal_btn == null or not is_instance_valid(_fusion_seal_btn):
		_fusion_seal_btn = Button.new()
		_fusion_seal_btn.clip_text = true
		_fusion_seal_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(15))
		_fusion_seal_btn.add_theme_color_override("font_color", Color(0.4, 0.95, 0.82))
		_fusion_seal_btn.custom_minimum_size = Vector2(0, 70)
		_fusion_seal_btn.pressed.connect(_on_fusion_seal_pressed)
		var panel := _right_panel()
		if panel:
			panel.add_child(_fusion_seal_btn)
			panel.move_child(_fusion_seal_btn, 0)
	var pl: int = int(Balance.PL_REWARDS.get("FUSIÓN CATABÓLICA", 9))
	_fusion_seal_btn.text = EmojiToRichText.strip(TranslationServer.translate("BTN_FUSION_SEAL") % pl)
	_fusion_seal_btn.visible = true

func _on_fusion_seal_pressed() -> void:
	if RunManager.run_closed or not EvoManager.fusion_seal_ready():
		return
	if is_instance_valid(_fusion_seal_btn):
		_fusion_seal_btn.visible = false
	RunManager.close_run("FUSIÓN CATABÓLICA", TranslationServer.translate("CLOSE_FUSION"))

# ── AYUNO PRIMORDIAL (transmutación SOMBRA): burst de Silencio + Ascesis + sello ──
func _update_ayuno_buttons() -> void:
	_update_ayuno_burst_button()
	_update_ayuno_ascesis_button()
	_update_ayuno_seal_button()

func _update_ayuno_burst_button() -> void:
	if RunManager.run_closed or not EvoManager.mutation_ayuno_primordial:
		if is_instance_valid(_ayuno_burst_btn):
			_ayuno_burst_btn.visible = false
		return
	if _ayuno_burst_btn == null or not is_instance_valid(_ayuno_burst_btn):
		_ayuno_burst_btn = Button.new()
		_ayuno_burst_btn.clip_text = true
		_ayuno_burst_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(16))
		_ayuno_burst_btn.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
		_ayuno_burst_btn.custom_minimum_size = Vector2(0, 50)
		_ayuno_burst_btn.pressed.connect(_on_ayuno_burst_pressed)
		var panel := _right_panel()
		if panel:
			panel.add_child(_ayuno_burst_btn)
			panel.move_child(_ayuno_burst_btn, 0)
	if EvoManager.ayuno_burst_active:
		_ayuno_burst_btn.text = EmojiToRichText.strip(TranslationServer.translate("BTN_AYUNO_BURST_ACTIVE") % EvoManager.ayuno_burst_timer)
		_ayuno_burst_btn.disabled = true
	else:
		var s_val := EvoManager.ayuno_silencio
		_ayuno_burst_btn.text = EmojiToRichText.strip(TranslationServer.translate("BTN_AYUNO_BURST_READY") % [s_val, 1.0 + s_val / Balance.AYUNO_BURST_DIVISOR])
		_ayuno_burst_btn.disabled = false
	_ayuno_burst_btn.visible = true

func _on_ayuno_burst_pressed() -> void:
	EvoManager.activate_ayuno_burst()
	_update_ayuno_burst_button()

func _update_ayuno_ascesis_button() -> void:
	if RunManager.run_closed or not EvoManager.mutation_ayuno_primordial:
		if is_instance_valid(_ayuno_ascesis_btn):
			_ayuno_ascesis_btn.visible = false
		return
	if _ayuno_ascesis_btn == null or not is_instance_valid(_ayuno_ascesis_btn):
		_ayuno_ascesis_btn = Button.new()
		_ayuno_ascesis_btn.clip_text = true
		_ayuno_ascesis_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(15))
		_ayuno_ascesis_btn.add_theme_color_override("font_color", Color(0.65, 0.75, 0.88))
		_ayuno_ascesis_btn.custom_minimum_size = Vector2(0, 46)
		_ayuno_ascesis_btn.pressed.connect(_on_ayuno_ascesis_pressed)
		var panel := _right_panel()
		if panel:
			panel.add_child(_ayuno_ascesis_btn)
			panel.move_child(_ayuno_ascesis_btn, 1)
	var cost := EvoManager.ayuno_ascesis_cost()
	var current_bonus := EvoManager.ayuno_ascesis_level * Balance.AYUNO_ASCESIS_RATE_BONUS * 100.0
	var next_bonus := (EvoManager.ayuno_ascesis_level + 1) * Balance.AYUNO_ASCESIS_RATE_BONUS * 100.0
	_ayuno_ascesis_btn.text = EmojiToRichText.strip(TranslationServer.translate("BTN_AYUNO_ASCESIS") % [EvoManager.ayuno_ascesis_level, current_bonus, next_bonus, UITextBuilders.format_compact(cost)])
	_ayuno_ascesis_btn.disabled = not EvoManager.can_buy_ayuno_ascesis()
	_ayuno_ascesis_btn.visible = true

func _on_ayuno_ascesis_pressed() -> void:
	EvoManager.buy_ayuno_ascesis()
	_update_ayuno_ascesis_button()

func _update_ayuno_seal_button() -> void:
	if RunManager.run_closed or not EvoManager.mutation_ayuno_primordial or not EvoManager.ayuno_seal_ready():
		if is_instance_valid(_ayuno_seal_btn):
			_ayuno_seal_btn.visible = false
		return
	if _ayuno_seal_btn == null or not is_instance_valid(_ayuno_seal_btn):
		_ayuno_seal_btn = Button.new()
		_ayuno_seal_btn.clip_text = true
		_ayuno_seal_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(15))
		_ayuno_seal_btn.add_theme_color_override("font_color", Color(0.8, 0.92, 1.0))
		_ayuno_seal_btn.custom_minimum_size = Vector2(0, 70)
		_ayuno_seal_btn.pressed.connect(_on_ayuno_seal_pressed)
		var panel := _right_panel()
		if panel:
			panel.add_child(_ayuno_seal_btn)
			panel.move_child(_ayuno_seal_btn, 0)
	var pl: int = int(Balance.PL_REWARDS.get("AYUNO PRIMORDIAL", 8))
	_ayuno_seal_btn.text = EmojiToRichText.strip(TranslationServer.translate("BTN_AYUNO_SEAL") % pl)
	_ayuno_seal_btn.visible = true

func _on_ayuno_seal_pressed() -> void:
	if RunManager.run_closed or not EvoManager.ayuno_seal_ready():
		return
	if is_instance_valid(_ayuno_seal_btn):
		_ayuno_seal_btn.visible = false
	RunManager.close_run("AYUNO PRIMORDIAL", TranslationServer.translate("CLOSE_AYUNO"))

func _update_simbiosis_seal_button() -> void:
	if RunManager.run_closed or not EvoManager.mutation_symbiosis:
		if is_instance_valid(_simbiosis_seal_btn):
			_simbiosis_seal_btn.visible = false
		return
	if EvoManager.red_branch_selected == EvoManager.RedBranch.SYMBIOSIS:
		if is_instance_valid(_simbiosis_seal_btn):
			_simbiosis_seal_btn.visible = false
		return
	if RunManager.run_time < 60.0:
		return
	if _simbiosis_seal_btn == null or not is_instance_valid(_simbiosis_seal_btn):
		_simbiosis_seal_btn = Button.new()
		_simbiosis_seal_btn.clip_text = true
		_simbiosis_seal_btn.text = EmojiToRichText.strip("🌱 " + TranslationServer.translate("BTN_SEAL_SIMB"))
		_simbiosis_seal_btn.add_theme_font_size_override("font_size", AccessibilityManager.fs(15))
		_simbiosis_seal_btn.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
		_simbiosis_seal_btn.custom_minimum_size = Vector2(0, 70)
		_simbiosis_seal_btn.pressed.connect(_on_simbiosis_seal_pressed)
		var panel := _right_panel()
		if panel:
			panel.add_child(_simbiosis_seal_btn)
			panel.move_child(_simbiosis_seal_btn, 0)
	_simbiosis_seal_btn.visible = true

func _on_simbiosis_seal_pressed() -> void:
	if is_instance_valid(_simbiosis_seal_btn):
		_simbiosis_seal_btn.visible = false
	RunManager.close_run("SIMBIOSIS", TranslationServer.translate("CLOSE_SIMBIOSIS_BASE"))
