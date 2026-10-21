class_name RouteUpgrades

## MEJORAS DE RUTA — la economía como combustible de la mecánica de cada Sombra.
## Feedback del autor (2026-10-20): en las Sombras la economía pasaba a segundo plano; la mecánica era lo
## único relevante. Cada Sombra tiene mejoras únicas que se compran con plata a precio FIJO en $ (no en
## "segundos de ingreso": ese costo se ajusta solo y hacía irrelevante tener una economía fuerte).
## Quien llega con mejor economía compra más y sella antes; la mecánica sigue siendo necesaria.
## Spec: docs/design/sombras.md §15. Niveles en EvoManager.route_upg (por run).

## Una lista por ruta. Cada mejora: id, costo base ($), crecimiento por nivel, nivel máximo.
## Los efectos los leen las lógicas de cada ruta con level(id).
const DEFS := {
	"inestabilidad": [
		{"id": "inest_observador", "base": 2500.0, "growth": 2.2, "max": 3},   # observar perturba −0.04/nivel
		{"id": "inest_integral",   "base": 2000.0, "growth": 2.2, "max": 3},   # integrar baja P +0.10/nivel
		{"id": "inest_asistida",   "base": 3000.0, "growth": 2.2, "max": 4},   # lemas progresan +25 %/nivel
	],
	"procariota": [
		{"id": "proc_medio",       "base": 2500.0, "growth": 2.2, "max": 4},   # crecimiento +20 %/nivel
		{"id": "proc_pared",       "base": 2000.0, "growth": 2.2, "max": 3},   # toxinas −20 %/nivel
		{"id": "proc_senal",       "base": 3000.0, "growth": 2.2, "max": 3},   # quorum +0.75·N/K por nivel
	],
	"antibiosis": [
		{"id": "anti_sintesis",    "base": 2500.0, "growth": 2.2, "max": 4},   # daño +20 %/nivel
		{"id": "anti_rotacion",    "base": 2000.0, "growth": 2.2, "max": 3},   # resistencia por uso −0.04/nivel
		{"id": "anti_biofilm",     "base": 3000.0, "growth": 2.2, "max": 2},   # cada rival roba menos (×0.85, ×0.9)
		{"id": "anti_expansion",   "base": 2500.0, "growth": 2.2, "max": 3},   # los rivales llegan −3 s/nivel (más riesgo, sello antes)
	],
	"autosuficiencia": [
		{"id": "auto_compostera",  "base": 2000.0, "growth": 2.2, "max": 3},   # fermentar +25 % nutrientes y −3 de olor/nivel
		{"id": "auto_riego",       "base": 2500.0, "growth": 2.2, "max": 3},   # cultivo −2 s/nivel
		{"id": "auto_abono",       "base": 3000.0, "growth": 2.2, "max": 4},   # cultivo −10 % nutrientes/nivel
	],
	"pionera": [
		{"id": "pion_lipidos",     "base": 2000.0, "growth": 2.2, "max": 3},   # +20 energía máx y +15 energía al comprar
		{"id": "pion_apical",      "base": 3000.0, "growth": 2.2, "max": 4},   # velocidad base +0.5 m/s/nivel
		{"id": "pion_quimio",      "base": 2000.0, "growth": 2.2, "max": 3},   # sondear −2 energía/nivel
		{"id": "pion_punta",       "base": 2500.0, "growth": 2.2, "max": 3},   # roca +0.15 velocidad, toxinas −5/nivel
	],
}

## Ruta con mejoras activa ahora ("" = ninguna).
static func active_route() -> String:
	if RunManager.run_closed:
		return ""
	if EvoManager.mutation_inestabilidad: return "inestabilidad"
	if EvoManager.mutation_procariota: return "procariota"
	if EvoManager.mutation_antibiosis: return "antibiosis"
	if EvoManager.mutation_autosuficiencia: return "autosuficiencia"
	if EvoManager.mutation_hifa_pionera: return "pionera"
	return ""

static func active_defs() -> Array:
	var r := active_route()
	return DEFS.get(r, []) if r != "" else []

static func _def(id: String) -> Dictionary:
	for r in DEFS:
		for d in DEFS[r]:
			if d.id == id:
				return d
	return {}

static func level(id: String) -> int:
	return int(EvoManager.route_upg.get(id, 0))

static func maxed(id: String) -> bool:
	return level(id) >= int(_def(id).get("max", 0))

static func cost(id: String) -> float:
	var d := _def(id)
	return float(d.base) * pow(float(d.growth), level(id))

static func can_buy(id: String) -> bool:
	var d := _def(id)
	return not d.is_empty() and active_route() != "" and DEFS[active_route()].has(d) \
		and not maxed(id) and EconomyManager.money >= cost(id)

static func buy(id: String) -> void:
	if not can_buy(id):
		return
	EconomyManager.money -= cost(id)
	EvoManager.route_upg[id] = level(id) + 1
	EvoManager.route_upg_spent += 1
	# Reservas Lipídicas: además de la energía máxima, la compra repone energía.
	if id == "pion_lipidos":
		EvoManager.pion_energy = minf(EvoManager.pion_energy + Balance.PION_LIPIDOS_REFILL, PioneraLogic.energy_max())
	UIManager.show_toast(TranslationServer.translate("TOAST_ROUTE_UPG") % [
		TranslationServer.translate("RUPG_" + id.to_upper() + "_NAME"), level(id)])
