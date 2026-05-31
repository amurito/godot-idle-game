extends Node

# ================================================================
# Balance.gd — Autoload de constantes de diseño
# Un solo lugar para ajustar timers de mecánicas, PL y caps NG+.
# Sin lógica: solo datos. No depende de otros autoloads.
# ================================================================

# ── Timers de mecánicas ──────────────────────────────────────────
const HOMEOSTASIS_TIME_REQUIRED  := 18.0   # s en banda homeostática para desbloquear Tier 1
const HOMEORHESIS_MIN_RUN_TIME   := 600.0 # s mínimos de run para desbloquear Tier 3
const HYPER_TIMEOUT              := 180.0 # s máximos en Hiperasimilación sin Depredador antes de cerrar
const MENTE_COLMENA_BUY_INTERVAL := 8.0    # s entre auto-compras de IA
const ASCESIS_DURATION           := 300.0  # s de ascesis profunda para cierre
const ASCESIS_MIN_RUN_TIME       := 300.0  # s mínimos de run para habilitar ascesis (antes 900)
const ASCESIS_MONEY_REQ          := 10000000.0 # $ alcanzados SOLO por clicks (sin pasivo) — antes 1M
const ASCESIS_CLICK_TIMEOUT      := 10.0   # s máx sin clickear; si se supera, el timer de ascesis se pausa (anti-AFK)
const CARNAVAL_INTERVAL          := 60.0   # s entre rotaciones de mutación
const PRIMORDIO_DURATION         := 90.0   # s por ciclo biológico primordio
const MET_OSCURO_REQUIRED_TIME   := 15.0   # s de activación met. oscuro
const MET_OSCURO_SEAL_COOLDOWN   := 120.0  # s de cooldown tras sellado
const MET_OSCURO_DEVOURED_REQ    := 10     # devours necesarios para sellar MET.OSCURO
const MET_OSCURO_BIO_REQ         := 50.0   # biomasa necesaria para sellar MET.OSCURO

# ── Depredador: compra de tiempo del timer de inestabilidad ──────
# (el máximo del timer vive en EvoManager.DEPREDADOR_INESTABILIDAD_MAX)
const DEP_TIME_EXTENSION           := 10.0  # s que resta al timer cada compra
const DEP_TIME_COST_BASE           := 40.0  # costo en biomasa de la 1ª compra
const DEP_TIME_COST_GROWTH         := 1.8   # multiplicador de costo por compra acumulada
# Hitos de devorado: al alcanzar N upgrades comidos, regalar tiempo (resta al timer).
# Premia el progreso hacia DEPREDADOR DE REALIDADES (comer toda la realidad antes de implosionar).
const DEP_DEVOUR_MILESTONES        := [30, 50, 70, 90]  # cada hito resta tiempo al timer
const DEP_DEVOUR_MILESTONE_BONUS   := 10.0  # s que resta al timer al cruzar cada hito
# Velocidad de devorado: el frenesí se acelera al pasar cierto umbral de comidos.
const DEP_DEVOUR_TICK_BASE         := 1.5   # s entre devorados al inicio
const DEP_DEVOUR_TICK_FAST         := 1.2   # s entre devorados tras DEP_DEVOUR_TICK_FAST_AT
const DEP_DEVOUR_TICK_FAST_AT      := 50    # a partir de N devorados el tick acelera

# ── LogManager ──────────────────────────────────────────────────
const MAX_LAPS := 200  # máximo de eventos en lap_events (FIFO, descarta el más viejo)

# ── Multiplicadores de ruta ──────────────────────────────────────
const VACIO_HAMBRIENTO_MULT      := 100.0  # producción ×100 en VACÍO HAMBRIENTO
const REENCARNACION_COST_MULT    := 1.5    # costos de upgrades ×1.5 en REENCARNACIÓN HEREDADA

# ── PL base por ruta de cierre ───────────────────────────────────
# Usado en RunManager.close_run(). PANSPERMIA NEGRA = 0 (PL se otorga antes explícitamente).
const PL_REWARDS: Dictionary = {
	"HOMEOSTASIS":               3,
	"ALLOSTASIS":                4,
	"HOMEORHESIS":               8,
	"SIMBIOSIS":                 4,
	"ESPORULACION":              5,
	"ESPORULACIÓN":              5,
	"ESPORULACION TOTAL":        5,
	"PARASITISMO":               2,
	"HIPERASIMILACION":          1,
	"HIPERASIMILACIÓN":          1,
	"MUTACION_FINAL":            4,
	"METABOLISMO OSCURO":        4,
	"MENTE COLMENA DISTRIBUIDA": 8,
	"DEPREDADOR DE REALIDADES":  12,
	"COLAPSO DEPREDATORIO":      8,
	"PANSPERMIA NEGRA":          0,
	"COLAPSO CONTROLADO":        6,
	"POLIMORFÍA TOTAL":          9,
	"POLIMORFIA TOTAL":          9,
	"DOMADOR DEL CAOS":          11,
	"ASCESIS_PROFUNDA":          7,
}

# ── Caps de bonus NG+ por ruta ───────────────────────────────────
# PL adicional máximo que puede ganar la fórmula variable en NG+.
const NG_CAPS: Dictionary = {
	"HOMEOSTASIS":               6,
	"SIMBIOSIS":                 6,
	"HIPERASIMILACION":          5,
	"HIPERASIMILACIÓN":          5,
	"PARASITISMO":               4,
	"ESPORULACION":              5,
	"ESPORULACIÓN":              5,
	"ESPORULACION TOTAL":        5,
	"ALLOSTASIS":                5,
	"HOMEORHESIS":               7,
	"MUTACION_FINAL":            8,
	"METABOLISMO OSCURO":        8,
	"POLIMORFÍA TOTAL":          8,
	"POLIMORFIA TOTAL":          8,
	"DOMADOR DEL CAOS":          8,
	"ASCESIS_PROFUNDA":          6,
	"MENTE COLMENA DISTRIBUIDA": 8,
	"DEPREDADOR DE REALIDADES":  8,
	"COLAPSO DEPREDATORIO":      5,
	"PANSPERMIA NEGRA":          6,
}
