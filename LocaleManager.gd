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
