class_name IncomeModifiers

## Tabla declarativa de modificadores de ingreso (rutas, legados, buffs cósmicos).
##
## Una FILA por regla, con su efecto sobre el click y sobre el pasivo lado a lado: si un buff
## afecta a los dos canales se define una sola vez, y si afecta a uno solo se ve explícitamente
## (antes eran ~15 reglas copiadas en get_click_power y get_passive_total; ver la cicatriz de
## aura_dorada). La UI (chips del header) lee la misma tabla.
##
## Cada factor es un Callable sin argumentos → float:
##   1.0 = inactivo (no se aplica);  0.0 = anula el canal (x = 0, no x * 0);  otro = x *= factor.
##
## CLICK_ORDER / PASSIVE_ORDER fijan el orden de aplicación por canal. El producto en coma
## flotante no es asociativo: reordenar cambia los últimos bits (y los golden lo detectan).
## Términos que no son multiplicadores (bases, aditivos) siguen en EconomyManager.

const CLICK_ORDER := [
	"sincronia_total", "symbiosis", "red_micelial", "hyperassimilation", "fusion_catabolica",
	"caos_fuel", "caos_burst",
	"homeostasis_banda", "met_oscuro", "necrosis", "apoptosis_heredada", "plasticidad_terminal",
	"sintesis_vital", "aura_dorada", "convergencia_ciclica", "semilla_cosmica",
	"metabolismo_glitch", "entropia_domesticada", "parasitism_corrosion", "resonancia_simbionte",
	"simbiosis_agresiva", "eco_primordial", "resonancia_cognitiva", "vacio",
]

const PASSIVE_ORDER := [
	"symbiosis", "red_micelial", "hyperassimilation", "fusion_catabolica", "caos_fuel", "caos_burst",
	"ayuno_primordial",
	"primicia_del_vacio", "homeostasis_banda", "parasitism_growth", "parasitism_corrosion",
	"met_oscuro", "semilla_cosmica", "semilla_cosmica_oscura", "mente_colmena",
	"metabolismo_glitch", "entropia_domesticada", "convergencia_ciclica", "apoptosis_heredada",
	"plasticidad_terminal", "sintesis_vital", "control_omega", "colonization",
	"glitch_persistente", "simbiosis_agresiva", "eco_primordial", "resonancia_cognitiva", "vacio",
]

## Fuente de cada fila: "route" (mutación/rama de la run), "legacy" (banco de legado),
## "cosmic" (banco cósmico), "post" (ruta post-trascendencia).
static var _rows: Dictionary = {}
## Callables precompilados por canal, en orden: apply() es ruta caliente (decenas de llamadas
## por tick) y así evita dos búsquedas en diccionario por fila.
static var _click_fns: Array[Callable] = []
static var _passive_fns: Array[Callable] = []


static func rows() -> Dictionary:
	if _rows.is_empty():
		_rows = _build()
		for id in CLICK_ORDER:
			_click_fns.append(_rows[id].click)
		for id in PASSIVE_ORDER:
			_passive_fns.append(_rows[id].passive)
	return _rows


## Aplica en orden los modificadores del canal ("click" | "passive") sobre x.
static func apply(channel: String, x: float) -> float:
	if _rows.is_empty():
		rows()
	for fn in (_click_fns if channel == "click" else _passive_fns):
		var f: float = fn.call()
		if f == 1.0:
			continue
		if f == 0.0:
			x = 0.0
		else:
			x *= f
	return x


## Modificadores activos de un canal (factor ≠ 1), en orden de aplicación, filtrados por fuente.
## [{ id, name, factor, source }]
static func active(channel: String, sources: Array = []) -> Array:
	var out: Array = []
	var r := rows()
	for id in (CLICK_ORDER if channel == "click" else PASSIVE_ORDER):
		var row: Dictionary = r[id]
		if not sources.is_empty() and not (row.source in sources):
			continue
		var f: float = row[channel].call()
		if f != 1.0:
			out.append({"id": id, "name": row.name, "factor": f, "source": row.source})
	return out


static func _row(name: String, source: String, click: Callable, passive: Callable) -> Dictionary:
	var one := func() -> float: return 1.0
	return {"name": name, "source": source,
		"click": click if click.is_valid() else one, "passive": passive if passive.is_valid() else one}


## Fast-path: en una run típica casi ningún legado está comprado; buffs.has() descarta sin
## pagar la llamada a get_buff_value (mismo resultado: sin entrada → false).
static func _buff(id: String) -> bool:
	return LegacyManager.buffs.has(id) and LegacyManager.get_buff_value(id)


static func _build() -> Dictionary:
	var none := Callable()
	var d := {}

	# ── Mutaciones / ramas de la run ─────────────────────────────────────────
	d["symbiosis"] = _row("Simbiosis", "route",
		func() -> float: return 2.5 if EvoManager.mutation_symbiosis else 1.0,
		func() -> float: return 0.5 if EvoManager.mutation_symbiosis else 1.0)
	d["red_micelial"] = _row("Red Micelial", "route",
		func() -> float: return 0.5 if EvoManager.mutation_red_micelial else 1.0,
		func() -> float: return 2.5 if EvoManager.mutation_red_micelial else 1.0)
	# Hiperasimilación: deja de aplicar bajo MET.OSCURO (MO reemplaza la economía).
	# Click: RUSH DE CLICK EXTREMO. Pasivo: se sacrifica por el núcleo.
	d["hyperassimilation"] = _row("Hiperasimilación", "route",
		func() -> float: return 10.0 if EvoManager.mutation_hyperassimilation and not EvoManager.mutation_met_oscuro else 1.0,
		func() -> float: return 0.25 if EvoManager.mutation_hyperassimilation and not EvoManager.mutation_met_oscuro else 1.0)
	# FUSIÓN CATABÓLICA (transmutación): ×5 estable en ambos + ráfaga Metabolismo Híbrido ×2
	d["fusion_catabolica"] = _row("Fusión Catabólica", "route",
		func() -> float: return Balance.FUSION_CLICK_MULT * EvoManager.fusion_burst_mult() if EvoManager.mutation_fusion_catabolica else 1.0,
		func() -> float: return Balance.FUSION_PASSIVE_MULT * EvoManager.fusion_burst_mult() if EvoManager.mutation_fusion_catabolica else 1.0)
	# CAOS ORQUESTADO (transmutación de Homeostasis): ε es combustible + Colapso Dirigido.
	var caos_fuel := func() -> float: return CaosOrquestadoLogic.fuel_mult()
	d["caos_fuel"] = _row("Caos Orquestado (ε)", "route", caos_fuel, caos_fuel)
	var caos_burst := func() -> float: return CaosOrquestadoLogic.burst_mult()
	d["caos_burst"] = _row("Colapso Dirigido", "route", caos_burst, caos_burst)
	# AYUNO PRIMORDIAL (transmutación): pasivo amplificado por Silencio + burst al romper
	d["ayuno_primordial"] = _row("Ayuno Primordial", "route", none,
		func() -> float: return EvoManager.ayuno_silencio_mult() * EvoManager.ayuno_burst_mult() if EvoManager.mutation_ayuno_primordial else 1.0)
	# HOMEOSTASIS: Orden Administrativo — +50% sólo mientras ε está en banda (0.03–0.30)
	var homeo := func() -> float: return 1.5 if EvoManager.mutation_homeostasis and RunManager.get_en_banda_homeostatica() else 1.0
	d["homeostasis_banda"] = _row("Orden Administrativo", "route", homeo, homeo)
	# PARASITISMO: crecimiento parásito inicial (pasivo) y corrosión que converge a 0 (ambos)
	d["parasitism_growth"] = _row("Crecimiento Parásito", "route", none,
		func() -> float: return 1.2 if EvoManager.mutation_parasitism else 1.0)
	var corrosion := func() -> float: return EconomyManager.parasitism_corrosion if EvoManager.mutation_parasitism else 1.0
	d["parasitism_corrosion"] = _row("Corrosión Parasitaria", "route", corrosion, corrosion)
	# MET.OSCURO: click ×3 de energía alternativa (×AUTOLISIS_CLICK_MULT en Autofagia / Omega-Cero,
	# que reabren las compras). Pasivo anulado salvo en las sub-rutas que lo liberan:
	# Autólisis ×AUTOLISIS_PASSIVE_MULT, Necrosis y Omega-Cero ×1.
	var mo_click := func() -> float:
		if not EvoManager.mutation_met_oscuro:
			return 1.0
		var loop_route: bool = EvoManager.mutation_autolisis or EvoManager.mutation_omega_cero
		return Balance.AUTOLISIS_CLICK_MULT if loop_route else 3.0
	var mo_passive := func() -> float:
		if not EvoManager.mutation_met_oscuro:
			return 1.0
		if EvoManager.mutation_autolisis:
			return Balance.AUTOLISIS_PASSIVE_MULT
		if EvoManager.mutation_necrosis or EvoManager.mutation_omega_cero:
			return 1.0
		return 0.0
	d["met_oscuro"] = _row("Metabolismo Oscuro", "route", mo_click, mo_passive)
	# NECROSIS CONTROLADA: multiplicador necrótico (cuanto más bajo Ω, más produce)
	d["necrosis"] = _row("Necrosis Controlada", "route",
		func() -> float: return EvoManager.necrosis_mult() if EvoManager.mutation_necrosis else 1.0, none)
	d["colonization"] = _row("Rama Colonización", "route", none,
		func() -> float: return 2.5 if EvoManager.red_branch_selected == EvoManager.RedBranch.COLONIZATION else 1.0)
	# VACÍO HAMBRIENTO (post-trascendencia): ×100 producción a cambio de buffs cósmicos
	var vacio := func() -> float: return RouteManager.production_mult() if RouteManager.is_active("vacio") else 1.0
	d["vacio"] = _row("Vacío Hambriento", "post", vacio, vacio)

	# ── Legados ──────────────────────────────────────────────────────────────
	d["sincronia_total"] = _row("Sincronía Total", "legacy",
		func() -> float: return BiosphereEngine.get_biomass_beta() if _buff("sincronia_total") else 1.0, none)
	# APOPTOSIS HEREDADA: income escala suavemente con Ω bajo
	var apoptosis := func() -> float:
		if _buff("apoptosis_heredada") and StructuralModel.omega < 0.30:
			return clampf(1.0 + (0.30 - StructuralModel.omega) * 1.67, 1.0, 1.5)
		return 1.0
	d["apoptosis_heredada"] = _row("Apoptosis Heredada", "legacy", apoptosis, apoptosis)
	# PLASTICIDAD TERMINAL (cross HOMEORHESIS→NECROSIS): premia ambos extremos de Ω
	var plasticidad := func() -> float:
		return 1.5 if _buff("plasticidad_terminal") and (StructuralModel.omega > 0.55 or StructuralModel.omega < 0.10) else 1.0
	d["plasticidad_terminal"] = _row("Plasticidad Terminal", "legacy", plasticidad, plasticidad)
	# SÍNTESIS VITAL (cross OMEGA-CERO↔REMISIÓN): fragilidad + abundancia simultáneas
	var sintesis := func() -> float:
		return 2.0 if _buff("sintesis_vital") and StructuralModel.omega < 0.20 and BiosphereEngine.biomasa >= 80.0 else 1.0
	d["sintesis_vital"] = _row("Síntesis Vital", "legacy", sintesis, sintesis)
	# AURA DORADA: especializada en click (desde el rework NO afecta pasivo)
	d["aura_dorada"] = _row("Aura Dorada", "legacy",
		func() -> float: return 2.5 if _buff("aura_dorada") else 1.0, none)
	var semilla := func() -> float: return 2.0 if _buff("semilla_cosmica") else 1.0
	d["semilla_cosmica"] = _row("Semilla Cósmica", "legacy", semilla, semilla)
	d["semilla_cosmica_oscura"] = _row("Semilla Cósmica Oscura", "legacy", none,
		func() -> float: return Balance.SEMILLA_OSCURA_PASIVO_MULT if _buff("semilla_cosmica_oscura") else 1.0)
	d["mente_colmena"] = _row("Mente Colmena", "legacy", none,
		func() -> float: return 3.0 if _buff("mente_colmena") else 1.0)
	# METABOLISMO GLITCH: el parásito prospera en el caos (ε > 0.40) — click ×1.5, pasivo ×1.8
	d["metabolismo_glitch"] = _row("Metabolismo Glitch", "legacy",
		func() -> float: return 1.5 if _buff("metabolismo_glitch") and StructuralModel.epsilon_runtime > 0.40 else 1.0,
		func() -> float: return 1.8 if _buff("metabolismo_glitch") and StructuralModel.epsilon_runtime > 0.40 else 1.0)
	# ENTROPÍA DOMESTICADA (COLAPSO CONTROLADO): la zona roja (ε>0.65) deja de penalizar y escala
	var entropia := func() -> float:
		var k: float = LegacyManager.get_effect_value("entropia_domesticada_mult")
		if k > 0.0 and StructuralModel.epsilon_runtime > 0.65:
			return clampf(1.0 + (StructuralModel.epsilon_runtime - 0.65) * k, 1.0, 2.0)
		return 1.0
	d["entropia_domesticada"] = _row("Entropía Domesticada", "legacy", entropia, entropia)
	# RESONANCIA SIMBIONTE: click escala con biomasa actual (cap ×2.5)
	d["resonancia_simbionte"] = _row("Resonancia Simbionte", "legacy",
		func() -> float: return min(1.0 + BiosphereEngine.biomasa * 0.05, 2.5) if _buff("resonancia_simbionte") else 1.0, none)
	# SIMBIOSIS AGRESIVA: ×1.15 si se completaron SIMBIOSIS y PARASITISMO
	var agresiva := func() -> float:
		if _buff("simbiosis_agresiva") and LegacyManager.endings_achieved.get("SIMBIOSIS", false) and LegacyManager.endings_achieved.get("PARASITISMO", false):
			return 1.15
		return 1.0
	d["simbiosis_agresiva"] = _row("Simbiosis Agresiva", "legacy", agresiva, agresiva)
	# ECO PRIMORDIAL / MOTOR FUNDIDO: +X% a todos los ingresos
	var eco := func() -> float:
		var v: float = LegacyManager.get_effect_value("all_income_mult")
		return 1.0 + v if v > 0.0 else 1.0
	d["eco_primordial"] = _row("Eco Primordial", "legacy", eco, eco)
	# RESONANCIA COGNITIVA: +X% por nivel de contabilidad
	var cognitiva := func() -> float:
		var v: float = LegacyManager.get_effect_value("cognitivo_income_mult_per_level")
		if v > 0.0:
			var acc_lvl: int = UpgradeManager.level("accounting")
			if acc_lvl > 0:
				return 1.0 + acc_lvl * v
		return 1.0
	d["resonancia_cognitiva"] = _row("Resonancia Cognitiva", "legacy", cognitiva, cognitiva)
	# LEGADO PRIMICIA DEL VACÍO: pasivo ×3.0→×1.0 linealmente en los primeros 10 min de run
	var primicia := func() -> float:
		if _buff("legado_primicia_del_vacio") and RunManager.run_time < Balance.AYUNO_LEGACY_DURATION:
			var t: float = clampf(RunManager.run_time / Balance.AYUNO_LEGACY_DURATION, 0.0, 1.0)
			return lerpf(Balance.AYUNO_LEGACY_MULT_START, 1.0, t)
		return 1.0
	d["primicia_del_vacio"] = _row("Primicia del Vacío", "legacy", none, primicia)
	# CONTROL DE Ω: offset positivo → eficiencia de producción (max +30% a offset máx)
	var control := func() -> float:
		if _buff("control_omega") and StructuralModel.control_omega_offset > 0.0:
			return 1.0 + StructuralModel.control_omega_offset * 2.0
		return 1.0
	d["control_omega"] = _row("Control de Ω", "legacy", none, control)
	# GLITCH PERSISTENTE: +15% pasivo en ruta Singularidad/Mente Colmena
	d["glitch_persistente"] = _row("Glitch Persistente", "legacy", none,
		func() -> float: return 1.15 if _buff("glitch_persistente") and (EvoManager.mutation_red_micelial or EvoManager.nucleo_conciencia) else 1.0)

	# ── Banco cósmico ────────────────────────────────────────────────────────
	# CONVERGENCIA CÍCLICA (T2): +5% por trascendencia acumulada
	var convergencia := func() -> float:
		if LegacyManager.has_cosmic_buff("convergencia_ciclica") and LegacyManager.trascendencia_count > 0:
			return 1.0 + LegacyManager.trascendencia_count * 0.05
		return 1.0
	d["convergencia_ciclica"] = _row("Convergencia Cíclica", "cosmic", convergencia, convergencia)

	for id in CLICK_ORDER + PASSIVE_ORDER:
		assert(d.has(id), "IncomeModifiers: id sin fila: " + str(id))
	return d
