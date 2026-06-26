extends Control
class_name CodexPanel

## Compendio (Codex) — overlay autocontenido, instanciable desde el menú y desde la run.
## Se construye solo en _ready(). El estado persistente (entradas vistas) vive en
## LegacyManager.codex_seen. Emite `closed` al cerrarse.
##
## Master-detail estilo Civilopedia: árbol de categorías colapsables + buscador a la
## izquierda; contenido de la entrada seleccionada a la derecha. Soporta links cruzados
## ("Ver también") y contador de progreso por categoría + total.

signal closed

# ── Paleta (fría, tipo Civilopedia) ───────────────────────────────────────────
const COL_BG       := Color(0.04, 0.06, 0.10, 0.99)
const COL_CAT      := Color(0.62, 0.80, 1.0)
const COL_ENTRY    := Color(0.86, 0.88, 0.96)
const COL_NEW      := Color(1.0, 0.86, 0.33)
const COL_LOCKED   := Color(0.42, 0.44, 0.50)

var _tree: Tree = null
var _label: RichTextLabel = null
var _search: LineEdit = null
var _progress: Label = null
var _filter: String = ""
var _id_to_item: Dictionary = {}   # entry_id → TreeItem (para links y selección)
var _current_id: String = ""

func _ready() -> void:
	_build()
	refresh()

# ──────────────────────────────────────────────────────────────────────────────
#  CONSTRUCCIÓN
# ──────────────────────────────────────────────────────────────────────────────
func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_BG
	bg.add_theme_stylebox_override("panel", sb)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16)
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)

	# Cabecera: título + contador de progreso.
	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title_lbl := Label.new()
	title_lbl.text = tr("MM_CODEX").to_upper()
	title_lbl.add_theme_font_size_override("font_size", AccessibilityManager.fs(22))
	title_lbl.add_theme_color_override("font_color", COL_CAT)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_lbl)
	_progress = Label.new()
	_progress.add_theme_font_size_override("font_size", AccessibilityManager.fs(15))
	_progress.add_theme_color_override("font_color", Color(0.55, 0.65, 0.82))
	_progress.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_progress)

	# Buscador.
	_search = LineEdit.new()
	_search.placeholder_text = tr("CODEX_SEARCH")
	_search.clear_button_enabled = true
	_search.text_changed.connect(_on_search_changed)
	vbox.add_child(_search)

	# Cuerpo: árbol (izq) + contenido (der).
	var hbox := HBoxContainer.new()
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 14)
	vbox.add_child(hbox)

	_tree = Tree.new()
	_tree.hide_root = true
	_tree.custom_minimum_size = Vector2(320, 0)
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.allow_reselect = true
	_tree.item_selected.connect(_on_entry_selected)
	hbox.add_child(_tree)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_child(scroll)

	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.meta_underlined = true
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_label.meta_clicked.connect(_on_meta_clicked)
	scroll.add_child(_label)

	var btn_back := Button.new()
	btn_back.text = tr("MM_BACK")
	btn_back.custom_minimum_size = Vector2(0, 44)
	btn_back.pressed.connect(_on_back)
	vbox.add_child(btn_back)

# ──────────────────────────────────────────────────────────────────────────────
#  POBLADO DEL ÁRBOL + PROGRESO
# ──────────────────────────────────────────────────────────────────────────────
func refresh() -> void:
	_populate_tree()
	if _current_id != "" and _id_to_item.has(_current_id):
		_show_entry(_current_id)
	else:
		_show_welcome()

func _populate_tree() -> void:
	if not is_instance_valid(_tree):
		return
	_tree.clear()
	_id_to_item.clear()
	var use_en: bool = LocaleManager.current_locale == "en"
	var root := _tree.create_item()
	var total_unlocked := 0
	var total_count := 0

	for cat in CodexDefs.CATEGORIES:
		# Recolectar entradas de la categoría (respetando el filtro de búsqueda).
		var rows: Array = []
		var cat_unlocked := 0
		var cat_total := 0
		for id in CodexDefs.ENTRIES:
			var entry: Dictionary = CodexDefs.ENTRIES[id]
			if entry.get("cat", "") != cat:
				continue
			cat_total += 1
			var unlocked: bool = LegacyManager.check_condition(entry.get("unlock", {"type": "always"}))
			if unlocked:
				cat_unlocked += 1
			var name_str: String = entry.get("name_en" if use_en else "name_es", id)
			# Filtro: solo aplica a entradas reveladas (las bloqueadas son "???").
			if _filter != "":
				if not unlocked or not name_str.to_lower().contains(_filter):
					continue
			rows.append({"id": id, "unlocked": unlocked, "name": name_str})
		total_unlocked += cat_unlocked
		total_count += cat_total

		if rows.is_empty():
			continue
		var cat_name: String = CodexDefs.CATEGORY_NAMES[cat].get("en" if use_en else "es", cat)
		var cat_item := _tree.create_item(root)
		cat_item.set_text(0, "%s · %d/%d" % [cat_name.to_upper(), cat_unlocked, cat_total])
		cat_item.set_selectable(0, false)
		cat_item.set_custom_color(0, COL_CAT)
		cat_item.set_collapsed(false)
		for row in rows:
			var child := _tree.create_item(cat_item)
			if not row.unlocked:
				child.set_text(0, "??? " + ("[locked]" if use_en else "[bloqueado]"))
				child.set_selectable(0, false)
				child.set_custom_color(0, COL_LOCKED)
			else:
				var is_new: bool = not LegacyManager.codex_seen.get(row.id, false)
				child.set_metadata(0, row.id)
				child.set_text(0, ("• " + row.name) if is_new else row.name)
				child.set_custom_color(0, COL_NEW if is_new else COL_ENTRY)
				_id_to_item[row.id] = child

	if is_instance_valid(_progress):
		var lbl := "Discovered" if use_en else "Descubiertas"
		_progress.text = "%s  %d/%d" % [lbl, total_unlocked, total_count]

# ──────────────────────────────────────────────────────────────────────────────
#  CONTENIDO
# ──────────────────────────────────────────────────────────────────────────────
func _show_welcome() -> void:
	if not is_instance_valid(_label):
		return
	_current_id = ""
	var use_en: bool = LocaleManager.current_locale == "en"
	var body := (
		"Select an entry on the left to read it. Locked entries reveal themselves as you progress."
		if use_en else
		"Elegí una entrada a la izquierda para leerla. Las entradas bloqueadas se revelan a medida que progresás."
	)
	_label.text = EmojiToRichText.rich("[color=#7fa8d8][i]%s[/i][/color]" % body)

func _show_entry(id: String) -> void:
	if not CodexDefs.ENTRIES.has(id):
		return
	_current_id = id
	var entry: Dictionary = CodexDefs.ENTRIES[id]
	var use_en: bool = LocaleManager.current_locale == "en"
	var name_str: String = entry.get("name_en" if use_en else "name_es", id)
	var content := "[color=#e6ecff][b][font_size=20]%s[/font_size][/b][/color]\n\n" % name_str
	var body_str: String = entry.get("body_en" if use_en else "body_es", "")
	if body_str != "":
		content += "[color=#c8d4e8]%s[/color]\n\n" % body_str
	if entry.has("lore_prefix"):
		content += _compose_lore(str(entry["lore_prefix"]), use_en)
	# Links cruzados ("Ver también") — solo hacia entradas ya reveladas (no spoilear).
	var see_also: Array = entry.get("see_also", [])
	if not see_also.is_empty():
		var links: Array = []
		for ref in see_also:
			if not CodexDefs.ENTRIES.has(ref):
				continue
			if not LegacyManager.check_condition(CodexDefs.ENTRIES[ref].get("unlock", {"type": "always"})):
				continue
			var rname: String = CodexDefs.ENTRIES[ref].get("name_en" if use_en else "name_es", ref)
			links.append("[url=codex:%s][color=#8fc4ff]%s[/color][/url]" % [ref, rname])
		if not links.is_empty():
			content += "\n[color=#6a7a92]%s[/color] %s" % [
				("See also:" if use_en else "Ver también:"), "  ·  ".join(links)
			]
	_label.text = EmojiToRichText.rich(content)
	_mark_seen(id)

## Compone el cuerpo desde claves de localización LORE_<prefix>_*.
func _compose_lore(prefix: String, use_en: bool) -> String:
	var out := ""
	var lore_key := prefix + "_LORE"
	var lore_txt := tr(lore_key)
	if lore_txt != lore_key:
		out += "[color=#9aa8c8][i]%s[/i][/color]\n\n" % lore_txt
	var pros := ""
	for i in range(1, 7):
		var k := "%s_B%d" % [prefix, i]
		var t := tr(k)
		if t != k:
			pros += "[color=#8fdba0]  +  %s[/color]\n" % t
	if pros != "":
		out += ("[color=#6fae80][b]%s[/b][/color]\n" % ("Benefits" if use_en else "Beneficios")) + pros + "\n"
	var cons := ""
	for i in range(1, 7):
		var k := "%s_N%d" % [prefix, i]
		var t := tr(k)
		if t != k:
			cons += "[color=#e09a9a]  −  %s[/color]\n" % t
	if cons != "":
		out += ("[color=#c87a7a][b]%s[/b][/color]\n" % ("Costs / Requirements" if use_en else "Costos / Requisitos")) + cons
	return out

func _mark_seen(id: String) -> void:
	if LegacyManager.codex_seen.get(id, false):
		return
	LegacyManager.codex_seen[id] = true
	LegacyManager.save_legacy()
	# Quitar el realce dorado del item correspondiente.
	if _id_to_item.has(id):
		var item: TreeItem = _id_to_item[id]
		if is_instance_valid(item):
			var use_en: bool = LocaleManager.current_locale == "en"
			item.set_text(0, CodexDefs.ENTRIES[id].get("name_en" if use_en else "name_es", id))
			item.set_custom_color(0, COL_ENTRY)

# ──────────────────────────────────────────────────────────────────────────────
#  EVENTOS
# ──────────────────────────────────────────────────────────────────────────────
func _on_entry_selected() -> void:
	var item := _tree.get_selected()
	if item == null:
		return
	var id_var = item.get_metadata(0)
	if id_var == null:
		return
	_show_entry(str(id_var))

func _on_meta_clicked(meta) -> void:
	var s := str(meta)
	if s.begins_with("codex:"):
		var id := s.substr(6)
		# Solo navegar a entradas reveladas (los links ya se filtran, esto es defensa extra).
		if _id_to_item.has(id):
			_id_to_item[id].select(0)
			_tree.scroll_to_item(_id_to_item[id])
			_show_entry(id)

func _on_search_changed(text: String) -> void:
	_filter = text.strip_edges().to_lower()
	_populate_tree()

func _on_back() -> void:
	close()

## Cierra el panel (oculta y avisa). Público para que el contenedor lo cierre con ESC.
func close() -> void:
	hide()
	closed.emit()

## Abre el panel mostrándolo y refrescando (para reusar la misma instancia).
func open() -> void:
	visible = true
	refresh()
