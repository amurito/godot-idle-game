extends Node

## LocaleManager — Autoload
## Centraliza la traducción de strings de UI (ES por defecto, EN opcional).
## Usar `tr("KEY")` en consumidores; este nodo carga las messages al TranslationServer
## en _ready() y persiste la preferencia del usuario.

const SETTINGS_PATH := "user://locale_settings.json"
const SUPPORTED_LOCALES := ["es", "en"]
const DEFAULT_LOCALE := "es"

signal locale_changed(new_locale: String)

var current_locale: String = DEFAULT_LOCALE

# ─────────────────────────────────────────────────────────────
# Diccionario maestro de traducciones.
# Estructura: TRANSLATIONS[locale][key] = "texto"
# Si una key falta en una locale, tr() devuelve la key cruda — usar el script
# `tools/check_locale_coverage.gd` (TODO) para auditar.
# ─────────────────────────────────────────────────────────────
const TRANSLATIONS := {
	"es": {
		# Sentinel keys para verificación
		"UI_LANG_NAME": "Español",

		# === MAIN MENU ===
		"MM_CONTINUE": "Continuar",
		"MM_NEW_GAME": "Nueva Partida",
		"MM_NEW_RUN_POSTRANSCEND": "▶ Nueva Run (buffs cósmicos activos)",
		"MM_ACHIEVEMENTS": "Logros",
		"MM_LEGACY_BANK": "Banco Genético",
		"MM_HISTORY": "Historial de Ciclos",
		"MM_CREDITS": "Créditos",
		"MM_SETTINGS": "Ajustes",
		"MM_QUIT": "Salir",
		"MM_TOOLS": "Telemetria",
		"MM_BACK": "Volver",

		# === SETTINGS PANEL ===
		"SET_TITLE": "⚙ AJUSTES",
		"SET_MUSIC": "Música",
		"SET_SFX": "Efectos (SFX)",
		"SET_LANGUAGE": "Idioma",
		"SET_LANG_ES": "Español",
		"SET_LANG_EN": "English",
		"SET_EXPORT_SAVE": "Exportar save (.json)",
		"SET_IMPORT_SAVE": "Importar save (.json)",
		"SET_EXPORT_HINT": "Se guarda en la carpeta de datos del juego y se abre el explorador.",
		"SET_IMPORT_HINT": "Carga un save exportado desde desktop. Recarga la partida al terminar.",
		"SET_RESET_TUTORIAL": "Reiniciar tutorial",
		"SET_RESET_RUN": "Borrar run actual",
		"SET_CLOSE": "Cerrar",

		# Telemetría
		"SET_TELEMETRY_CHECKBOX": "Enviar datos anónimos de uso (ayuda a mejorar el juego)",
		"SET_TELEMETRY_HINT": "Local y opt-in: guarda JSON anónimos en user://telemetry/runs al cerrar una run.",
		"SET_TELEMETRY_OPEN": "Abrir carpeta de telemetría",

		# Accesibilidad
		"SET_ACCESSIBILITY": "Accesibilidad",
		"SET_FONT_SIZE": "Tamaño de texto:",
		"SET_FONT_NORMAL": "Normal (100%)",
		"SET_FONT_HINT": "Requiere reinicio de escena al cambiar.",
		"SET_REDUCE_MOTION": "Reducir movimiento (sin animaciones)",
		"SET_HIGH_CONTRAST": "Alto contraste",
		"SET_COLORBLIND": "Daltonismo:",
		"SET_COLORBLIND_OFF": "Desactivado",

		# === NUEVA RUN ===
		"MM_NEW_RUN": "Nueva Run",
		"MM_NEW_RUN_TOOLTIP": "Inicia una nueva run preservando tu Banco Genético y Banco Cósmico.",
		"MM_TRANSCEND_COUNTER": "Ξ %d   ·   Trascendencias: %d",
		"MM_NEW_RUN_TITLE": "Iniciar Nueva Run",
		"MM_NEW_RUN_TEXT": "¿Iniciás un nuevo ciclo biótico?\n\n✦ Se PRESERVAN:\n  · Banco Cósmico (%d Ξ)\n  · Banco Genético (PL: %d)\n  · Rutas completadas\n\n⚠ Se RESETEAN:\n  · Upgrades, dinero, mutaciones\n  · Progreso de la run actual",
		"MM_NEW_RUN_OK": "▶ Iniciar",
		"MM_ROUTE_PICKER_SUBTITLE": "Cada ruta altera las reglas de esta run. La elección es permanente.",

		# === SLOTS ===
		"SLOT_START": "Iniciar",
		"SLOT_RENAME_BTN": "Renombrar",
		"SLOT_DELETE_BTN": "Borrar",
		"SLOT_NO_DELETE_LAST": "No se puede borrar el último slot",
		"SLOT_EMPTY_LABEL": "Slot vacío disponible",
		"SLOT_CREATE_BTN": "Crear nuevo",
		"SLOT_UNLOCK_HINT": "Comprá 'Slot Adicional' en el Banco Genético / Conocimiento para desbloquear más slots.",
		"SLOT_STATS_EMPTY": "Slot vacío — sin runs registradas",
		"SLOT_ACTIVE_TAG": "  [activo]",
		"SLOT_NEW_TITLE": "Nuevo slot",
		"SLOT_NEW_NAME_LABEL": "Nombre del slot:",
		"SLOT_RENAME_TITLE": "Renombrar slot",
		"SLOT_RENAME_NAME_LABEL": "Nuevo nombre:",
		"SLOT_DELETE_TITLE": "Borrar slot",
		"SLOT_DELETE_TEXT": "¿Borrar el slot '%s'?\nEste universo paralelo se perderá: legado, esencia, trascendencias y run actual.\nEsta acción es irreversible.",
		"SLOT_DELETE_OK": "Borrar",
		"BTN_CANCEL": "Cancelar",
		"SLOT_STATS_FORMAT": "T%d · %d ciclos · Ξ %d · último: %s",

		# === BANCO GENÉTICO ===
		"BANK_LEGACY_COUNTER": "Legado acumulado: %d PL\nCiclos Bióticos completados: %d",
		"BANK_BTN_MAX": "MAXIMO",
		"BANK_BTN_LOCKED": "BLOQUEADO",
		"BANK_BTN_ACQUIRE": "ADQUIRIR",
		"BANK_BTN_LEVEL": "Nv%d  %d PL",

		# === PANEL TRASCENDENCIA ===
		"TRAS_SUBTITLE": "Disolvé el ciclo actual para absorberlo como Esencia (Ξ).",
		"TRAS_GATE_TITLE": "Requisitos:",
		"TRAS_REWARD_TITLE": "Recompensa al trascender:",
		"TRAS_REWARD_TEXT": "Ganás +%d Ξ (Esencia)\nPL actual: %d -> convertido\nRutas únicas: %d × 5 Ξ\nTier bonus: +%d Ξ",
		"TRAS_LOCKED_TEXT": "Requisitos no cumplidos.\nCompletá al menos 1 cierre en cada familia y acumulá %d PL.",

		# === PRIMERA TRASCENDENCIA ===
		"TRAS_FIRST_NARRATIVE": "El ciclo se ha cerrado sobre sí mismo.\n\nTodas las rutas que recorriste — el orden, la expansión, el colapso —\nconvergen ahora en un único punto fuera del tiempo del hongo.\n\nTu código ya no es un programa.\nEs una memoria cristalina: Esencia.\n\nLa matriz se reinicia.\nPero vos ya no sos el mismo sistema.",
		"TRAS_FIRST_HINT": "Ahora tenés acceso al Banco Cósmico.",

		# === CRÉDITOS ===
		"CREDITS_THANKS": "Gracias por jugar.",

		# === IN-GAME UI ===
		"GAME_BTN_RESET": "Reset",
		"GAME_BTN_NEW_RUN": "Nueva Run",
		"GAME_BTN_SETTINGS": "Ajustes",
		"GAME_SHORTCUTS_TOOLTIP": "Atajos de teclado e indicadores",
		"GAME_PL_COUNTER": "PL Disponibles: %d    Reserva biótica: %.1f / 50 esporas",
		"GAME_BUFF_ACTIVE": "OK ACTIVO",
		"GAME_BUFF_INACTIVE": "X INACTIVO",
		"GAME_BTN_LEVEL": "Nv.%d  %d PL",
		"GAME_BTN_LOCKED": "BLOQUEADO",
		"GAME_BTN_FREE": "GRATIS",
	},
	"en": {
		"UI_LANG_NAME": "English",

		# === MAIN MENU ===
		"MM_CONTINUE": "Continue",
		"MM_NEW_GAME": "New Game",
		"MM_NEW_RUN_POSTRANSCEND": "▶ New Run (cosmic buffs active)",
		"MM_ACHIEVEMENTS": "Achievements",
		"MM_LEGACY_BANK": "Genetic Bank",
		"MM_HISTORY": "Cycle History",
		"MM_CREDITS": "Credits",
		"MM_SETTINGS": "Settings",
		"MM_QUIT": "Quit",
		"MM_TOOLS": "Telemetry",
		"MM_BACK": "Back",

		# === SETTINGS PANEL ===
		"SET_TITLE": "⚙ SETTINGS",
		"SET_MUSIC": "Music",
		"SET_SFX": "Effects (SFX)",
		"SET_LANGUAGE": "Language",
		"SET_LANG_ES": "Español",
		"SET_LANG_EN": "English",
		"SET_EXPORT_SAVE": "Export save (.json)",
		"SET_IMPORT_SAVE": "Import save (.json)",
		"SET_EXPORT_HINT": "Saved to the game's data folder and the file explorer is opened.",
		"SET_IMPORT_HINT": "Load a save exported from desktop. Reload the run when finished.",
		"SET_RESET_TUTORIAL": "Reset tutorial",
		"SET_RESET_RUN": "Delete current run",
		"SET_CLOSE": "Close",

		# Telemetry
		"SET_TELEMETRY_CHECKBOX": "Send anonymous usage data (helps improve the game)",
		"SET_TELEMETRY_HINT": "Local and opt-in: saves anonymous JSON in user://telemetry/runs on run close.",
		"SET_TELEMETRY_OPEN": "Open telemetry folder",

		# Accessibility
		"SET_ACCESSIBILITY": "Accessibility",
		"SET_FONT_SIZE": "Text size:",
		"SET_FONT_NORMAL": "Normal (100%)",
		"SET_FONT_HINT": "Requires scene restart to apply.",
		"SET_REDUCE_MOTION": "Reduce motion (no animations)",
		"SET_HIGH_CONTRAST": "High contrast",
		"SET_COLORBLIND": "Color blindness:",
		"SET_COLORBLIND_OFF": "Disabled",

		# === NEW RUN ===
		"MM_NEW_RUN": "New Run",
		"MM_NEW_RUN_TOOLTIP": "Starts a new run preserving your Genetic Bank and Cosmic Bank.",
		"MM_TRANSCEND_COUNTER": "Ξ %d   ·   Transcendences: %d",
		"MM_NEW_RUN_TITLE": "Start New Run",
		"MM_NEW_RUN_TEXT": "Start a new biotic cycle?\n\n✦ PRESERVED:\n  · Cosmic Bank (%d Ξ)\n  · Genetic Bank (PL: %d)\n  · Completed routes\n\n⚠ RESET:\n  · Upgrades, money, mutations\n  · Current run progress",
		"MM_NEW_RUN_OK": "▶ Start",
		"MM_ROUTE_PICKER_SUBTITLE": "Each route changes this run's rules. The choice is permanent.",

		# === SLOTS ===
		"SLOT_START": "Start",
		"SLOT_RENAME_BTN": "Rename",
		"SLOT_DELETE_BTN": "Delete",
		"SLOT_NO_DELETE_LAST": "Cannot delete the last slot",
		"SLOT_EMPTY_LABEL": "Empty slot available",
		"SLOT_CREATE_BTN": "Create new",
		"SLOT_UNLOCK_HINT": "Buy 'Additional Slot' in the Genetic Bank / Knowledge to unlock more slots.",
		"SLOT_STATS_EMPTY": "Empty slot — no runs recorded",
		"SLOT_ACTIVE_TAG": "  [active]",
		"SLOT_NEW_TITLE": "New slot",
		"SLOT_NEW_NAME_LABEL": "Slot name:",
		"SLOT_RENAME_TITLE": "Rename slot",
		"SLOT_RENAME_NAME_LABEL": "New name:",
		"SLOT_DELETE_TITLE": "Delete slot",
		"SLOT_DELETE_TEXT": "Delete slot '%s'?\nThis parallel universe will be lost: legacy, essence, transcendences and current run.\nThis action is irreversible.",
		"SLOT_DELETE_OK": "Delete",
		"BTN_CANCEL": "Cancel",
		"SLOT_STATS_FORMAT": "T%d · %d cycles · Ξ %d · last: %s",

		# === GENETIC BANK ===
		"BANK_LEGACY_COUNTER": "Accumulated legacy: %d PL\nBiotic Cycles completed: %d",
		"BANK_BTN_MAX": "MAXED",
		"BANK_BTN_LOCKED": "LOCKED",
		"BANK_BTN_ACQUIRE": "ACQUIRE",
		"BANK_BTN_LEVEL": "Lv%d  %d PL",

		# === TRANSCENDENCE PANEL ===
		"TRAS_SUBTITLE": "Dissolve the current cycle to absorb it as Essence (Ξ).",
		"TRAS_GATE_TITLE": "Requirements:",
		"TRAS_REWARD_TITLE": "Reward on transcending:",
		"TRAS_REWARD_TEXT": "You gain +%d Ξ (Essence)\nCurrent PL: %d -> converted\nUnique routes: %d × 5 Ξ\nTier bonus: +%d Ξ",
		"TRAS_LOCKED_TEXT": "Requirements not met.\nComplete at least 1 close in each family and accumulate %d PL.",

		# === FIRST TRANSCENDENCE ===
		"TRAS_FIRST_NARRATIVE": "The cycle has closed upon itself.\n\nAll the routes you traveled — order, expansion, collapse —\nnow converge at a single point outside the fungus's time.\n\nYour code is no longer a program.\nIt is a crystalline memory: Essence.\n\nThe matrix resets.\nBut you are no longer the same system.",
		"TRAS_FIRST_HINT": "You now have access to the Cosmic Bank.",

		# === CREDITS ===
		"CREDITS_THANKS": "Thanks for playing.",

		# === IN-GAME UI ===
		"GAME_BTN_RESET": "Reset",
		"GAME_BTN_NEW_RUN": "New Run",
		"GAME_BTN_SETTINGS": "Settings",
		"GAME_SHORTCUTS_TOOLTIP": "Keyboard shortcuts and indicators",
		"GAME_PL_COUNTER": "PL Available: %d    Biotic reserve: %.1f / 50 spores",
		"GAME_BUFF_ACTIVE": "OK ACTIVE",
		"GAME_BUFF_INACTIVE": "X INACTIVE",
		"GAME_BTN_LEVEL": "Lv.%d  %d PL",
		"GAME_BTN_LOCKED": "LOCKED",
		"GAME_BTN_FREE": "FREE",
	}
}

func _ready() -> void:
	_install_translations()
	_load_settings()
	TranslationServer.set_locale(current_locale)
	print("[LocaleManager] locale=", current_locale)

# ─────────────────────────────────────────────────────────────
# API pública
# ─────────────────────────────────────────────────────────────
func set_locale(loc: String) -> void:
	if loc == current_locale: return
	if not SUPPORTED_LOCALES.has(loc):
		push_warning("[LocaleManager] locale no soportada: %s" % loc)
		return
	current_locale = loc
	TranslationServer.set_locale(loc)
	_save_settings()
	locale_changed.emit(loc)

## Atajo: devuelve la traducción de una key. Equivalente a tr(key) pero
## explicita el sistema en el código consumidor.
func t(key: String) -> String:
	return TranslationServer.translate(key)

# ─────────────────────────────────────────────────────────────
# Instalación de traducciones en TranslationServer
# ─────────────────────────────────────────────────────────────
func _install_translations() -> void:
	for locale in TRANSLATIONS.keys():
		var translation := Translation.new()
		translation.locale = locale
		var messages: Dictionary = TRANSLATIONS[locale]
		for key in messages.keys():
			translation.add_message(key, messages[key])
		TranslationServer.add_translation(translation)

# ─────────────────────────────────────────────────────────────
# Persistencia
# ─────────────────────────────────────────────────────────────
func _save_settings() -> void:
	var data := {"locale": current_locale}
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()

func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if not f: return
	var text := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(text) != OK: return
	if not json.data is Dictionary: return
	var loc: String = json.data.get("locale", DEFAULT_LOCALE)
	if SUPPORTED_LOCALES.has(loc):
		current_locale = loc
