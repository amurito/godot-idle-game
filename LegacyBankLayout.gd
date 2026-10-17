class_name LegacyBankLayout

## Reparto del Banco Genético en columnas parejas (lo usan MainMenu y el panel de la run).
## Antes cada columna tenía categorías fijas y la última (Transmutaciones + NG+ + Secreto) crecía
## sin techo → scroll eterno. Ahora las categorías van en orden y se cortan donde haga falta para
## que todas las columnas queden de alto parecido; una categoría cortada repite su encabezado.

const CAT_ORDER: Array = [
	"economia", "estructura", "biologia", "conocimiento", "ruta", "transmutaciones", "ng_plus", "secreto",
]
const CAT_COLORS: Dictionary = {
	"economia": Color(0.9, 0.85, 0.4), "estructura": Color(0.5, 0.8, 1.0),
	"biologia": Color(0.4, 0.9, 0.5),  "conocimiento": Color(0.8, 0.6, 1.0),
	"ruta": Color(1.0, 0.65, 0.2),     "ng_plus": Color(0.9, 0.3, 0.9),
	"transmutaciones": Color(0.2, 0.9, 0.75), "secreto": Color(0.5, 0.5, 0.5),
}
const MIN_COL_W := 270.0
const HEADER_WEIGHT := 0.6


## Cantidad de columnas que entran en `width` px (entre 3 y 7).
static func column_count(width: float) -> int:
	return clampi(int(width / MIN_COL_W), 3, 7)


## Ids revelados por categoría, en el orden del banco.
static func revealed_by_cat() -> Array:
	var out: Array = []
	for cat in CAT_ORDER:
		var ids: Array = []
		for id in LegacyManager.LEGACY_DEFS:
			if LegacyManager.LEGACY_DEFS[id].get("cat", "") == cat and LegacyManager.is_revealed(id):
				ids.append(id)
		if not ids.is_empty():
			out.append({"cat": cat, "ids": ids})
	return out


## Alto estimado de un ítem (1 = título + 1 línea de descripción).
static func item_weight(id: String, col_w: float) -> float:
	var chars_per_line: float = maxf((col_w - 110.0) / 6.0, 20.0)
	var desc: String = TranslationServer.translate("LEGACY_" + id.to_upper() + "_FLAVOR")
	var lines: int = int(ceil(float(desc.length()) / chars_per_line))
	return 1.0 + 0.45 * maxf(lines - 1, 0)


## Reparte las categorías en `n_cols` columnas. Devuelve un Array por columna con segmentos
## {cat, ids, cont} (`cont` = continuación de una categoría que empezó en la columna anterior).
static func distribute(n_cols: int, col_w: float) -> Array:
	var cats: Array = revealed_by_cat()
	var total: float = 0.0
	for c in cats:
		total += HEADER_WEIGHT
		for id in c.ids:
			total += item_weight(id, col_w)
	var target: float = total / float(n_cols)

	var cols: Array = [[]]
	var acc: float = 0.0
	for c in cats:
		var seg: Dictionary = {"cat": c.cat, "ids": [], "cont": false}
		# Si el encabezado + el primer ítem ya no entran, la categoría arranca en la columna siguiente.
		if acc > 0.0 and cols.size() < n_cols and acc + HEADER_WEIGHT + item_weight(c.ids[0], col_w) > target * 1.08:
			cols.append([])
			acc = 0.0
		acc += HEADER_WEIGHT
		for id in c.ids:
			var w: float = item_weight(id, col_w)
			if acc + w > target * 1.08 and cols.size() < n_cols and not seg.ids.is_empty():
				cols[-1].append(seg)
				cols.append([])
				seg = {"cat": c.cat, "ids": [], "cont": true}
				acc = HEADER_WEIGHT
			seg.ids.append(id)
			acc += w
		cols[-1].append(seg)
	return cols


## Encabezado de categoría (o de su continuación).
static func header(cat: String, cont: bool, font_size: int) -> Label:
	var hdr := Label.new()
	var name: String = TranslationServer.translate("LEGACY_CAT_" + cat.to_upper())
	hdr.text = ("-- %s (cont.) --" if cont else "-- %s --") % name
	hdr.add_theme_font_size_override("font_size", font_size)
	hdr.modulate = CAT_COLORS.get(cat, Color.WHITE)
	hdr.custom_minimum_size.y = 22
	return hdr


## Fila compacta: título + descripción a la izquierda, controles (botones) a la derecha.
static func compact_row(left: Control, right: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right.custom_minimum_size.x = 96
	row.add_child(left)
	row.add_child(right)
	return row
