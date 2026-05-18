extends Node

# ================================================================
# Balance.gd — Autoload de constantes de diseño
# Un solo lugar para ajustar timers de mecánicas, PL y caps NG+.
# Sin lógica: solo datos. No depende de otros autoloads.
# ================================================================

# ── Timers de mecánicas ──────────────────────────────────────────
const HOMEOSTASIS_TIME_REQUIRED  := 18.0   # s en banda homeostática para desbloquear Tier 1
const HOMEORHESIS_MIN_RUN_TIME   := 1200.0 # s mínimos de run para desbloquear Tier 3
const MENTE_COLMENA_BUY_INTERVAL := 8.0    # s entre auto-compras de IA
const ASCESIS_DURATION           := 300.0  # s de ascesis profunda para cierre
const CARNAVAL_INTERVAL          := 60.0   # s entre rotaciones de mutación
const PRIMORDIO_DURATION         := 90.0   # s por ciclo biológico primordio
const MET_OSCURO_REQUIRED_TIME   := 15.0   # s de activación met. oscuro
const MET_OSCURO_SEAL_COOLDOWN   := 120.0  # s de cooldown tras sellado

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
