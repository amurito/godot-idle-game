extends Node

# Twemoji PNG locales en res://emoji/{codepoint}.png
# Solo actúa en web (OS.get_name() == "Web")

const _BASE := "res://emoji/"
const _SZ   := 16  # px, alineado con font_size 11-13

const EMOJI_TO_FILE: Dictionary = {
	"🟤": "1f7e4", "⚪": "26aa",  "🟡": "1f7e1", "🔴": "1f534", "🟣": "1f7e3",
	"🟢": "1f7e2", "🔵": "1f535",
	"🏁": "1f3c1", "✨": "2728",  "🌑": "1f311", "⚡": "26a1",
	"☠️": "2620", "⚠️": "26a0", "☣️": "2623",
	"⚖️": "2696", "🕸️": "1f578", "🕳️": "1f573",
	"⚱️": "26b1", "🏛️": "1f3db", "🌪️": "1f32a",
	"💾": "1f4be", "🧬": "1f9ec", "🔬": "1f52c", "🔥": "1f525",
	"💜": "1f49c", "💎": "1f48e", "💚": "1f49a", "📡": "1f4e1",
	"🧠": "1f9e0", "🚀": "1f680", "👾": "1f47e", "🎭": "1f3ad",
	"🎓": "1f393", "🍄": "1f344", "💀": "1f480", "🦠": "1f9a0",
	"🌿": "1f33f", "🌱": "1f331", "📤": "1f4e4", "🏠": "1f3e0",
	"🔒": "1f512", "📜": "1f4dc", "📋": "1f4cb", "🐛": "1f41b",
	"💸": "1f4b8", "🌋": "1f30b", "🛸": "1f6f8", "🚩": "1f6a9",
	"⏩": "23e9",  "✅": "2705",  "🤝": "1f91d", "🌀": "1f300",
	"🎯": "1f3af", "💥": "1f4a5", "🏗️": "1f3d7",
}

const BMP_SYMBOLS: Dictionary = {
	"▲": "+",
	"▼": "-",
	"▶": ">",
	"●": "*",
	"→": "->",
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
	"c₀": "c0",
	"cₙ": "cn",
	"fⁿ": "fn",
	"⏱": "T",
	"⏰": "T",
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

# Para Label / Button: elimina el emoji y reemplaza símbolos BMP con ASCII
func strip(text: String) -> String:
	if not _web:
		return text
	for em: String in EMOJI_TO_FILE:
		text = text.replace(em, "")
	for sym: String in BMP_SYMBOLS:
		text = text.replace(sym, BMP_SYMBOLS[sym])
	return text.strip_edges()
