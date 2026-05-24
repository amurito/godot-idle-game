extends Node

# Twemoji PNG locales en res://emoji/{codepoint}.png
# Solo actúa en web (OS.get_name() == "Web")

const _BASE := "res://emoji/"
const _SZ   := 16  # px, alineado con font_size 11-13

const EMOJI_TO_FILE: Dictionary = {
	"🟤": "1f7e4", "⚪": "26aa",  "🟡": "1f7e1", "🔴": "1f534", "🟣": "1f7e3",
	"🟢": "1f7e2", "🔵": "1f535",
	"🏁": "1f3c1", "✨": "2728",  "🌑": "1f311", "⚡": "26a1",
	# Con y sin variation selector (FE0F). Los strings de Godot/locale a veces
	# llegan sin el FE0F invisible que normalmente acompaña a estos chars, y
	# el match es por substring exacto. Mantener ambas variantes evita boxes
	# de fallback en runtime web.
	"☠️": "2620", "☠": "2620",
	"⚠️": "26a0", "⚠": "26a0",
	"☣️": "2623", "☣": "2623",
	"⚖️": "2696", "⚖": "2696",
	"🕸️": "1f578", "🕸": "1f578",
	"🕳️": "1f573", "🕳": "1f573",
	"⚱️": "26b1", "⚱": "26b1",
	"🏛️": "1f3db", "🏛": "1f3db",
	"🌪️": "1f32a", "🌪": "1f32a",
	"🏗️": "1f3d7", "🏗": "1f3d7",
	"💾": "1f4be", "🧬": "1f9ec", "🔬": "1f52c", "🔥": "1f525",
	"💜": "1f49c", "💎": "1f48e", "💚": "1f49a", "📡": "1f4e1",
	"🧠": "1f9e0", "🚀": "1f680", "👾": "1f47e", "🎭": "1f3ad",
	"🎓": "1f393", "🍄": "1f344", "💀": "1f480", "🦠": "1f9a0",
	"🌿": "1f33f", "🌱": "1f331", "📤": "1f4e4", "🏠": "1f3e0",
	"🔒": "1f512", "📜": "1f4dc", "📋": "1f4cb", "🐛": "1f41b",
	"💸": "1f4b8", "🌋": "1f30b", "🛸": "1f6f8", "🚩": "1f6a9",
	"⏩": "23e9",  "✅": "2705",  "🤝": "1f91d", "🌀": "1f300",
	"🎯": "1f3af", "💥": "1f4a5",
}

const BMP_SYMBOLS: Dictionary = {
	# IMPORTANTE: iterar este dict en orden de inserción al hacer replace().
	# Las claves COMPUESTAS (c₀, cₙ, fⁿ) deben venir ANTES que las bare (₀, ₙ, ⁿ)
	# para que el match más específico tenga precedencia. Si "₀" se reemplaza
	# primero, "c₀" ya no matchearía después.
	"▲": "+",
	"▼": "-",
	"▶": ">",
	"●": "*",
	"→": "->",
	"←": "<",
	"↑": "^",
	"↓": "v",
	"═": "=",
	"─": "-",
	"█": "|",
	"▓": "|",
	"░": ".",
	"✓": "v",
	"✗": "x",
	"★": "*",
	"✦": "*",
	"◈": "*",
	"⚫": "*",
	"c₀": "c0",
	"cₙ": "cn",
	"fⁿ": "fn",
	"₀": "0",
	"ₙ": "n",
	"ⁿ": "n",
	"≤": "<=",
	"≥": ">=",
	"≈": "~",
	"−": "-",
	"⏱": "T",
	"⏰": "T",
	"⌨": "",
	"🕳️": "",
	"⚱️": "",
	"⚙": "",
	"⚙️": "",
}

var _web: bool = false

func _ready() -> void:
	_web = OS.get_name() == "Web"

# Para RichTextLabel con bbcode_enabled=true: reemplaza emoji con [img] y símbolos BMP con ASCII
func rich(text: String) -> String:
	if not _web:
		return text
	for em: String in EMOJI_TO_FILE:
		if em in text:
			text = text.replace(em, "[img=%d]%s%s.png[/img]" % [_SZ, _BASE, EMOJI_TO_FILE[em]])
	for sym: String in BMP_SYMBOLS:
		if sym in text:
			text = text.replace(sym, BMP_SYMBOLS[sym])
	return text

# Para nodos Icon (TextureRect): carga el PNG Twemoji correspondiente al emoji.
# Útil cuando querés mostrar el icono como imagen en lugar de glifo de fuente
# (necesario en web; consistente y más limpio en desktop).
# Retorna true si pudo cargar la textura, false si no encontró el emoji.
func set_icon_texture(rect: TextureRect, emoji_char: String) -> bool:
	if not is_instance_valid(rect):
		return false
	if not EMOJI_TO_FILE.has(emoji_char):
		rect.texture = null
		return false
	var path: String = _BASE + String(EMOJI_TO_FILE[emoji_char]) + ".png"
	if not ResourceLoader.exists(path):
		rect.texture = null
		return false
	rect.texture = load(path)
	return true


# Para Label / Button: elimina el emoji y reemplaza símbolos BMP con ASCII
func strip(text: String) -> String:
	if not _web:
		return text
	for em: String in EMOJI_TO_FILE:
		text = text.replace(em, "")
	for sym: String in BMP_SYMBOLS:
		text = text.replace(sym, BMP_SYMBOLS[sym])
	return text.strip_edges()
