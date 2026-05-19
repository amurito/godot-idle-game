extends Node

## AccessibilityManager — Autoload
## Gestiona opciones de accesibilidad: escala de fuente, movimiento reducido, alto contraste.
## Los cambios de font_scale requieren reload_current_scene() para aplicarse (se hace automático).
## reduce_motion y high_contrast se aplican en el próximo ciclo de UI sin reload.

const SETTINGS_PATH := "user://accessibility_settings.json"

enum ColorblindMode { OFF = 0, DEUTAN = 1, PROTAN = 2, TRITAN = 3 }

## Escala de fuente. Opciones: 0.85 / 1.00 / 1.15 / 1.30
var font_scale: float = 1.0

## Si true, salta animaciones de tween (toasts, créditos, overlays)
var reduce_motion: bool = false

## Si true, usa paleta de alto contraste (blanco/negro en lugar de verde/gris)
var high_contrast: bool = false

## Modo daltonismo. 0=OFF 1=Deuteranopía 2=Protanopía 3=Tritanopía
var colorblind_mode: int = ColorblindMode.OFF

## Si true, muestra reactor 3D; si false, muestra reactor 2D con efectos por ruta
var reactor_3d_enabled: bool = true

signal settings_changed


## Color "OK / puede comprar" como Color (para StyleBoxFlat)
func cok() -> Color:
	match colorblind_mode:
		ColorblindMode.DEUTAN, ColorblindMode.PROTAN:
			return Color(0.27, 0.53, 1.0)    # azul
		ColorblindMode.TRITAN:
			return Color(1.0, 0.27, 1.0)     # magenta
		_:
			return Color(0.0, 1.0, 0.0)      # verde

## Color "FAIL / no puede comprar" como Color (para StyleBoxFlat)
func cno() -> Color:
	match colorblind_mode:
		ColorblindMode.DEUTAN, ColorblindMode.PROTAN:
			return Color(1.0, 0.53, 0.0)     # naranja
		ColorblindMode.TRITAN:
			return Color(1.0, 0.27, 0.0)     # rojo-naranja
		_:
			return Color(1.0, 0.27, 0.27)    # rojo

## Color "OK" como string hex para BBCode [color=...]
func cok_hex() -> String:
	match colorblind_mode:
		ColorblindMode.DEUTAN, ColorblindMode.PROTAN: return "#4488ff"
		ColorblindMode.TRITAN:                        return "#ff44ff"
		_:                                            return "#00ff00"

## Color "FAIL" como string hex para BBCode [color=...]
func cno_hex() -> String:
	match colorblind_mode:
		ColorblindMode.DEUTAN, ColorblindMode.PROTAN: return "#ff8800"
		ColorblindMode.TRITAN:                        return "#ff4400"
		_:                                            return "#ff4444"


func _ready() -> void:
	_load_settings()


## Helper: devuelve un font size escalado. Usar en todo add_theme_font_size_override.
func fs(base: int) -> int:
	if font_scale == 1.0:
		return base
	return maxi(6, int(base * font_scale))


func set_font_scale(v: float) -> void:
	font_scale = clampf(v, 0.5, 2.0)
	_save_settings()
	settings_changed.emit()
	# Reload para que toda la UI se reconstruya con la nueva escala
	get_tree().reload_current_scene()


func set_reduce_motion(v: bool) -> void:
	reduce_motion = v
	_save_settings()
	settings_changed.emit()


func set_high_contrast(v: bool) -> void:
	high_contrast = v
	_save_settings()
	settings_changed.emit()


func set_colorblind_mode(v: int) -> void:
	colorblind_mode = v
	_save_settings()
	settings_changed.emit()


func set_reactor_3d(v: bool) -> void:
	reactor_3d_enabled = v
	_save_settings()
	settings_changed.emit()


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
	font_scale         = float(data.get("font_scale",         1.0))
	reduce_motion      = bool(data.get("reduce_motion",      false))
	high_contrast      = bool(data.get("high_contrast",      false))
	colorblind_mode    = int(data.get("colorblind_mode",     0))
	reactor_3d_enabled = bool(data.get("reactor_3d_enabled", true))


func _save_settings() -> void:
	var data := {
		"font_scale":         font_scale,
		"reduce_motion":      reduce_motion,
		"high_contrast":      high_contrast,
		"colorblind_mode":    colorblind_mode,
		"reactor_3d_enabled": reactor_3d_enabled,
	}
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
