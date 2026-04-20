extends Node

# LegacyManager.gd — Autoload Global
# Gestiona los Puntos de Legado (PL) y las mejoras persistentes entre partidas.

const LEGACY_PATH := "user://legacy_bank.json"

# --- ESTADO GLOBAL ---
var legacy_points: int = 0
var unlocked_legacies: Dictionary = {
	"deflacion": false,      # Reduce factor de precios un 5%
	"memoria_recurso": false, # Primera compra gratis
	"red_confianza": false,   # Trueque eficiencia 0.75 -> 0.85
	"impulso_manual": false,  # Click base 1.0 -> 2.0
	"sincronia_total": false, # Bonus biomasa afecta al click
	"inercia_escala": false,   # Bonus md por nivel contabilidad
	"horizonte_estructural": false, # Rompe el cap de alpha y k
	"redireccion_energia": false,   # 10% click power a pasivo
	"legado_alostasis": false, # NG+ Secreto (Homeostasis -> Alostasis)
	"legado_homeorresis": false, # NG+ Secreto (Alostasis -> Homeorresis)
	"semilla_cosmica": false, # NG+ Secreto (Esporulación -> Panspermia)
	"mente_colmena": false, # NG+ Secreto (Singularidad -> IA)
	"metabolismo_glitch": false # NG+ Secreto (Parasitismo -> Survival)
}
var total_runs: int = 0
var last_run_ending: String = ""

# =====================================================
#  TRASCENDENCIA — Meta-prestige (v0.9.2)
# =====================================================
# Esencia (Ξ): moneda meta obtenida al trascender. Persiste forever.
var esencia: int = 0
# Cantidad de veces que el jugador trascendió. Define el "tier" cósmico.
var trascendencia_count: int = 0
# Flag que indica si ya se mostró la pantalla narrativa especial de primera trascendencia.
var first_trascendencia_shown: bool = false
# Set persistente de rutas de cierre completadas (clave → true). Persiste entre trascendencias.
# Se usa para el gate de trascendencia (familias completas).
var endings_achieved: Dictionary = {}
# Upgrades del Banco Cósmico comprados con Ξ (persisten entre trascendencias).
var cosmic_unlocked: Dictionary = {}

# Mapeo ruta de cierre → familia. Usado por el gate (requiere 1 cierre por familia).
const ENDING_FAMILIES := {
	# Familia ORDEN (regulación homeostática)
	"HOMEOSTASIS": "orden",
	"ALLOSTASIS": "orden",
	"HOMEORHESIS": "orden",
	"SINGULARIDAD": "orden",

	# Familia BIOLOGÍA (expansión biótica)
	"ESPORULACION": "biologia",
	"ESPORULACIÓN": "biologia",
	"ESPORULACION TOTAL": "biologia",
	"PARASITISMO": "biologia",
	"SIMBIOSIS": "biologia",
	"PANSPERMIA NEGRA": "biologia",
	"MENTE COLMENA DISTRIBUIDA": "biologia",

	# Familia COLAPSO (rutas destructivas / NG++)
	"HIPERASIMILACION": "colapso",
	"HIPERASIMILACIÓN": "colapso",
	"DEPREDADOR DE REALIDADES": "colapso",
	"METABOLISMO OSCURO": "colapso",
	"MUTACION_FINAL": "colapso"
}

const TRASCENDENCIA_PL_GATE := 50

# Títulos cósmicos según cantidad de trascendencias
const TRASCENDENCIA_TITLES := [
	"",                          # 0
	"Trascendido",              # 1
	"Trascendido II",           # 2
	"Trascendido III",          # 3
	"Arquitecto Cósmico",       # 4
	"Arquitecto Cósmico II",    # 5
	"Demiurgo",                 # 6+
]

# --- DEFINICIÓN DE COSTOS Y DESCRIPCIONES ---
const LEGACY_DATA := {
	"deflacion": {"cost": 4, "name": "Deflación Biótica", "desc": "Reduce un 5% el escalado de precios de todas las mejoras."},
	"memoria_recurso": {"cost": 5, "name": "Memoria de Recurso", "desc": "La primera compra de cada productor es GRATUITA al inicio de la run."},
	"red_confianza": {"cost": 3, "name": "Red de Confianza", "desc": "La eficiencia base del Trueque sube permanentemente del 75% al 85%."},
	"impulso_manual": {"cost": 3, "name": "Impulso Manual", "desc": "Tu click base inicial es el doble de potente (1.0 -> 2.0)."},
	"sincronia_total": {"cost": 7, "name": "Sincronía Total", "desc": "El bonus de biomasa (Beta) ahora también multiplica el poder de tus clicks."},
	"inercia_escala": {"cost": 6, "name": "Inercia de Escala", "desc": "Cada nivel de Contabilidad potencia un +5% extra al Trabajo Manual (md)."},
	"horizonte_estructural": {"cost": 10, "name": "Horizonte Estructural", "desc": "Rompe los límites de Rigidez (k) y Adaptación (α), permitiendo escalado infinito."},
	"redireccion_energia": {"cost": 5, "name": "Redirección de Energía", "desc": "El 10% de tu potencia de Click se suma automáticamente a tus ingresos pasivos por segundo."},
	"legado_alostasis": {"cost": 0, "name": "Resiliencia Alostática", "desc": "El sistema ha aprendido a recalibrarse tras el caos. Bonus permanentes de Alostasis activos."},
	"legado_homeorresis": {"cost": 0, "name": "Trascendencia Cristalina", "desc": "El hongo ya no requiere regular su estrés; directamente, lo ha trascendido."}
}

func _ready():
	load_legacy()

# --- PERSISTENCIA ---
func save_legacy():
	var data = {
		"legacy_points": legacy_points,
		"unlocked_legacies": unlocked_legacies,
		"spores_buffer": internal_spores_total,
		"total_runs": total_runs,
		"last_run_ending": last_run_ending,
		# --- TRASCENDENCIA v0.9.2 ---
		"esencia": esencia,
		"trascendencia_count": trascendencia_count,
		"first_trascendencia_shown": first_trascendencia_shown,
		"endings_achieved": endings_achieved,
		"cosmic_unlocked": cosmic_unlocked
	}
	var file = FileAccess.open(LEGACY_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		print("💾 [Legacy] Banco genético guardado.")

func load_legacy():
	if not FileAccess.file_exists(LEGACY_PATH):
		return
	var file = FileAccess.open(LEGACY_PATH, FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data = json.data
			legacy_points = data.get("legacy_points", 0)
			var loaded_unlocked = data.get("unlocked_legacies", {})
			for key in loaded_unlocked.keys():
				if unlocked_legacies.has(key):
					unlocked_legacies[key] = loaded_unlocked[key]

			internal_spores_total = data.get("spores_buffer", 0.0)
			total_runs = data.get("total_runs", 0)
			last_run_ending = data.get("last_run_ending", "")

			# --- TRASCENDENCIA v0.9.2 ---
			esencia = data.get("esencia", 0)
			trascendencia_count = data.get("trascendencia_count", 0)
			first_trascendencia_shown = data.get("first_trascendencia_shown", false)
			endings_achieved = data.get("endings_achieved", {})
			cosmic_unlocked = data.get("cosmic_unlocked", {})

			# Migración retroactiva para saves pre-v0.9.2:
			# inferir rutas ya completadas desde buffs legacy y last_run_ending
			_migrate_retroactive_endings()

			print("📂 [Legacy] Banco genético cargado. PL:", legacy_points, " Ξ:", esencia, " T#:", trascendencia_count)
		file.close()

# Migración: si endings_achieved está vacío pero hay evidencia de rutas previas,
# inferirlas desde unlocked_legacies (buffs NG+) y last_run_ending
func _migrate_retroactive_endings() -> void:
	if endings_achieved.size() > 0:
		return # Ya migrado o registrado normalmente
	if total_runs == 0 and last_run_ending == "":
		return # Save nuevo, nada que migrar

	# Inferir desde buffs NG+ desbloqueados (cada uno implica una ruta completada)
	if unlocked_legacies.get("legado_alostasis", false):
		endings_achieved["ALLOSTASIS"] = true
		endings_achieved["HOMEOSTASIS"] = true # Prerequisito
	if unlocked_legacies.get("legado_homeorresis", false):
		endings_achieved["HOMEORHESIS"] = true
		endings_achieved["ALLOSTASIS"] = true
		endings_achieved["HOMEOSTASIS"] = true
	if unlocked_legacies.get("semilla_cosmica", false):
		endings_achieved["PANSPERMIA NEGRA"] = true
		endings_achieved["ESPORULACIÓN"] = true
	if unlocked_legacies.get("mente_colmena", false):
		endings_achieved["MENTE COLMENA DISTRIBUIDA"] = true
		endings_achieved["SINGULARIDAD"] = true
	if unlocked_legacies.get("metabolismo_glitch", false):
		endings_achieved["PARASITISMO"] = true

	# Last run ending como fallback mínimo
	if last_run_ending != "" and last_run_ending != "NONE":
		endings_achieved[last_run_ending] = true

	if endings_achieved.size() > 0:
		print("🔄 [Legacy] Migración retroactiva: ", endings_achieved.size(), " rutas recuperadas")
		save_legacy()

# --- LÓGICA DEL BANCO ---
func can_afford(legacy_id: String) -> bool:
	if not LEGACY_DATA.has(legacy_id): return false
	return legacy_points >= LEGACY_DATA[legacy_id].cost and not unlocked_legacies[legacy_id]

func purchase_legacy(legacy_id: String) -> bool:
	if can_afford(legacy_id):
		legacy_points -= LEGACY_DATA[legacy_id].cost
		unlocked_legacies[legacy_id] = true
		save_legacy()
		return true
	return false

# --- CONVERSIÓN DE ESPORAS (v0.8.42) ---
var internal_spores_total: float = 0.0

func add_spores(amount: float):
	internal_spores_total += amount
	var new_pl = int(internal_spores_total / 50.0)
	if new_pl > 0:
		add_pl(new_pl)
		internal_spores_total -= (new_pl * 50.0)
	save_legacy()

func add_pl(amount: int):
	legacy_points += amount
	save_legacy()
	print("✨ [Legacy] Ganaste +", amount, " PL. Total:", legacy_points)

# --- GETTERS PARA EL JUEGO ---
func get_buff_value(legacy_id: String) -> bool:
	return unlocked_legacies.get(legacy_id, false)

func increment_run():
	total_runs += 1
	save_legacy()
	print("📈 Ciclo Biótico completado. Total: ", total_runs)

# =====================================================
#  TRASCENDENCIA — API pública (v0.9.2)
# =====================================================

## Registra una ruta de cierre como completada (persiste entre trascendencias).
## Se llama desde RunManager.close_run().
func mark_ending_achieved(route: String) -> void:
	if route == "" or route == "NONE": return
	if not endings_achieved.get(route, false):
		endings_achieved[route] = true
		save_legacy()
		print("🏁 [Legacy] Ruta registrada: ", route)

## Devuelve un dict { "orden": bool, "biologia": bool, "colapso": bool }
## indicando si cada familia tiene al menos 1 cierre completado.
func get_family_progress() -> Dictionary:
	var prog := {"orden": false, "biologia": false, "colapso": false}
	for route in endings_achieved.keys():
		if endings_achieved[route]:
			var fam: String = ENDING_FAMILIES.get(route, "")
			if prog.has(fam):
				prog[fam] = true
	return prog

## Total de rutas únicas completadas (para calcular Ξ).
func unique_endings_count() -> int:
	var n := 0
	for route in endings_achieved.keys():
		if endings_achieved[route]: n += 1
	return n

## Gate de activación: requiere 3 familias completas + PL ≥ 50
func can_transcend() -> bool:
	var prog := get_family_progress()
	if not (prog.orden and prog.biologia and prog.colapso):
		return false
	if legacy_points < TRASCENDENCIA_PL_GATE:
		return false
	return true

## Texto descriptivo del estado del gate (para UI)
func get_transcend_gate_status() -> String:
	var prog := get_family_progress()
	var t := ""
	t += ("✓" if prog.orden else "✗") + " Familia ORDEN (Homeostasis/Allostasis/Homeorresis/Singularidad)\n"
	t += ("✓" if prog.biologia else "✗") + " Familia BIOLOGÍA (Esporulación/Parasitismo/Simbiosis/Panspermia)\n"
	t += ("✓" if prog.colapso else "✗") + " Familia COLAPSO (Hiperasimilación/Depredador/Met.Oscuro)\n"
	t += ("✓" if legacy_points >= TRASCENDENCIA_PL_GATE else "✗") + " PL acumulado ≥ %d (tenés %d)" % [TRASCENDENCIA_PL_GATE, legacy_points]
	return t

## Calcula cuánta Esencia (Ξ) otorga la trascendencia actual.
## Fórmula: 1 Ξ por cada 10 PL + 5 Ξ por cada ruta única + bonus por tier actual
func calculate_esencia_gain() -> int:
	var from_pl := int(legacy_points / 10.0)
	var from_routes := unique_endings_count() * 5
	var tier_bonus := trascendencia_count * 2  # Cada trascendencia previa suma +2 Ξ al siguiente ciclo
	return from_pl + from_routes + tier_bonus

## Ejecuta la trascendencia: reset completo + award de Ξ + incremento.
## Returns: int (Esencia ganada)
func transcend() -> int:
	if not can_transcend():
		return 0

	var esencia_gain := calculate_esencia_gain()

	# SUSTRATO CÓSMICO: dobla la Esencia de esta trascendencia (uso único por compra)
	if has_cosmic_buff("sustrato_cosmico"):
		esencia_gain *= 2
		# Resetear el upgrade para que el efecto sea de un solo uso
		cosmic_unlocked["sustrato_cosmico"] = false
		print("✦ [Cosmic] Sustrato Cósmico consumido — Esencia ×2 aplicado")

	esencia += esencia_gain
	trascendencia_count += 1

	# Reset de estado acumulable entre runs (PL, buffs legacy, esporas internas)
	legacy_points = 0
	internal_spores_total = 0.0
	for id in unlocked_legacies:
		unlocked_legacies[id] = false
	total_runs = 0
	last_run_ending = ""

	# Preservamos: esencia, trascendencia_count, first_trascendencia_shown,
	# endings_achieved (histórico), cosmic_unlocked (upgrades meta)

	save_legacy()
	print("⚡ [TRASCENDENCIA #%d] +%d Ξ · Total: %d Ξ" % [trascendencia_count, esencia_gain, esencia])
	return esencia_gain

## Devuelve el título cósmico actual según cantidad de trascendencias.
func get_trascendencia_title() -> String:
	if trascendencia_count <= 0:
		return ""
	var idx: int = min(trascendencia_count, TRASCENDENCIA_TITLES.size() - 1)
	return TRASCENDENCIA_TITLES[idx]

# =====================================================
#  BANCO CÓSMICO — Upgrades con Esencia (v0.9.2)
# =====================================================
const COSMIC_DATA := {
	# --- TIER 1: Fundamentos ---
	"impulso_inicial": {
		"cost": 6,
		"name": "Impulso Inicial",
		"desc": "Comenzás cada run con $500 ya generados. La economía tiene memoria del ciclo anterior.",
		"tier": 1
	},
	"omega_primordial": {
		"cost": 8,
		"name": "Omega Primordial",
		"desc": "Tu Ω_min sube permanentemente +0.05 al inicio de cada run. El sistema recuerda su flexibilidad.",
		"tier": 1
	},
	"resonancia_biotica": {
		"cost": 10,
		"name": "Resonancia Biótica",
		"desc": "Tu biomasa inicial es 1.5 (en lugar de 0). El sustrato biológico persiste entre ciclos.",
		"tier": 1
	},
	"deflacion_cosmica": {
		"cost": 12,
		"name": "Deflación Cósmica",
		"desc": "El escalado de precios de todos los upgrades se reduce un 8% adicional (apilable con Deflación Biótica).",
		"tier": 1
	},
	"eco_de_legado": {
		"cost": 15,
		"name": "Eco de Legado",
		"desc": "Al inicio de cada run ganás +5 PL automáticos para gastar en el Banco Genético.",
		"tier": 1
	},
	# --- TIER 2: Catalizadores ---
	"arbol_acelerado": {
		"cost": 18,
		"name": "Árbol Acelerado",
		"desc": "Los timers de activación de MET.OSCURO y DEPREDADOR se reducen un 40%. La evolución recuerda el camino.",
		"tier": 2
	},
	"memoria_persistente": {
		"cost": 22,
		"name": "Memoria Persistente",
		"desc": "Al inicio de run, el primer nivel de Contabilidad y Trueque son gratuitos automáticamente.",
		"tier": 2
	},
	"convergencia_ciclica": {
		"cost": 28,
		"name": "Convergencia Cíclica",
		"desc": "Cada trascendencia acumulada suma +5% a todos tus ingresos globales de forma permanente.",
		"tier": 2
	},
	# --- TIER 3: Transformadores ---
	"fractura_epistemica": {
		"cost": 35,
		"name": "Fractura Epistémica",
		"desc": "Desbloquea la ruta COLAPSO CONTROLADO: cuando ε > 0.90 y Ω > 0.30, podés cerrar la run con +6 PL.",
		"tier": 3
	},
	"sustrato_cosmico": {
		"cost": 50,
		"name": "Sustrato Cósmico",
		"desc": "La próxima trascendencia otorga el doble de Esencia (Ξ ×2). Efecto de un solo uso por compra. Desbloquea el Lore Fragment I.",
		"tier": 3
	}
}

func can_afford_cosmic(cosmic_id: String) -> bool:
	if not COSMIC_DATA.has(cosmic_id): return false
	if cosmic_unlocked.get(cosmic_id, false): return false
	return esencia >= COSMIC_DATA[cosmic_id].cost

func purchase_cosmic(cosmic_id: String) -> bool:
	if not can_afford_cosmic(cosmic_id): return false
	esencia -= COSMIC_DATA[cosmic_id].cost
	cosmic_unlocked[cosmic_id] = true
	save_legacy()
	print("✨ [Cosmic] Desbloqueado: ", cosmic_id)
	return true

func has_cosmic_buff(cosmic_id: String) -> bool:
	return cosmic_unlocked.get(cosmic_id, false)
