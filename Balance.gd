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

# ── ESCLEROCIO OSCURO (salida alternativa de Met. Oscuro) ────────
# Gate lore-accurate (procesar la oscuridad, no esperar reloj): autofagia + masa + autorregulación.
const ESCLEROCIO_DEVOURED_REQ    := 30     # devours acumulados (material para endurecer el esclerocio)
const ESCLEROCIO_BIO_REQ         := 50.0   # biomasa mínima para encapsular
const ESCLEROCIO_EPS_MAX         := 0.25   # ε máximo (domesticó la oscuridad antes de sellarla)
# Buff "Memoria Oscura" — carga consumible en la run SIGUIENTE
const MEMORIA_OSCURA_BIO_MULT       := 1.15  # +15% crecimiento de biomasa
const MEMORIA_OSCURA_EPS_RISE_DAMP  := 0.70  # la subida de ε se amortigua 30% (resiste la entropía)
const MEMORIA_OSCURA_MO_THRESH_MULT := 0.90  # −10% al threshold de activación de Met. Oscuro
# Legado permanente desbloqueado por el cruce ESCLEROCIO → PANSPERMIA NEGRA
const SEMILLA_OSCURA_PASIVO_MULT    := 3.0   # ×pasivo del legado Semilla Cósmica Oscura

# ── AUTÓLISIS DIRIGIDA (sub-ruta de Met. Oscuro, post-Esclerocio) ─
# El hongo digiere sus propias estructuras para liberar energía. Irreversible.
const AUTOLISIS_BIO_REQ         := 50.0   # biomasa mínima para iniciar la autofagia
const AUTOLISIS_UPGRADES_REQ    := 5      # niveles de upgrades disponibles mínimos al activar
const AUTOLISIS_DEVOUR_INTERVAL := 30.0   # s entre cada auto-devour
const AUTOLISIS_BIO_BURST       := 8.0    # biomasa fija por devour (además del burst de $)
const AUTOLISIS_MONEY_BURST_MULT := 3.0   # el burst de $ = costo del upgrade devorado × este mult
const AUTOLISIS_CLICK_MULT      := 5.0    # click ×5 mientras autólisis activa (reemplaza ×3 de MO)
const AUTOLISIS_PASSIVE_MULT    := 2.0    # pasivo ×2 (restaura el pasivo anulado por MO)

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

# ── RAMA VERDE · COLONIZACIÓN activa (Empuje de Frontera) ────────
# Anti-AFK: el micelio ya NO se llena solo desde hifas. Las hifas sólo sostienen
# un piso bajo; por encima la frontera RETROCEDE. Se empuja con clicks manuales
# (on_reactor_click). Sin clicks → la frontera decae y nunca llega a 60%.
const MICELIO_SUPPORT_FLOOR    := 8.0    # % piso que sostienen las hifas (≥5) sin clickear
const MICELIO_COLONIZ_DECAY    := 2.0    # %/s que retrocede la frontera por encima del piso
const MICELIO_PULSE_GAIN       := 1.2    # % de micelio que aporta cada click manual en colonización
const COLONIZ_PERT_INTERVAL    := 14.0   # s entre eventos de retracción del sustrato
const COLONIZ_PERT_BITE_BASE   := 4.0    # % base que muerde la retracción
const COLONIZ_PERT_BITE_SCALE  := 0.05   # +% por segundo en fase: la retracción escala con el tiempo
const COLONIZ_PERT_BITE_MAX    := 18.0   # cap de la mordida de retracción

# ── RAMA VERDE · PRIMORDIO activo (Maduración del cuerpo fructífero) ──
# Anti-AFK: la maduración sólo progresa con ε dentro de una banda de incubación;
# la integridad se drena fuera de banda + por contaminaciones que escalan.
# Acción "Regar": gasta biomasa para restaurar integridad y reencauzar ε.
const PRIMORDIO_BIO_MATURE      := 60.0   # s (no sobrecalentado) necesarios para madurar la seta
const PRIMORDIO_BAND_LO         := 0.30   # objetivo de enfriamiento al Regar (zona segura)
const PRIMORDIO_BAND_HI         := 0.50   # techo: por encima el embrión se SOBRECALIENTA (drena + estanca)
const PRIMORDIO_INTEGRITY_MAX   := 100.0  # integridad del primordio
const PRIMORDIO_OOB_DRAIN       := 4.0    # integridad/s drenada mientras está sobrecalentado
const PRIMORDIO_PERT_INTERVAL   := 6.0    # s entre contaminaciones
const PRIMORDIO_PERT_DMG_BASE   := 14.0   # daño base a integridad por contaminación
const PRIMORDIO_PERT_DMG_SCALE  := 0.15   # +daño por s de maduración (escala)
const PRIMORDIO_PERT_DMG_MAX    := 30.0   # cap del daño por contaminación
const PRIMORDIO_PERT_EPS_KICK   := 0.16   # ε que patea la contaminación (saca de banda)
const PRIMORDIO_REGAR_HEAL      := 18.0   # integridad restaurada por Regar
const PRIMORDIO_REGAR_COST_BIO  := 2.0    # biomasa por Regar (biomasa NO regenera en primordio → finita)
const PRIMORDIO_REGAR_EPS_PULL  := 0.10   # cuánto enfría ε (hacia BAND_LO) cada Regar
const PRIMORDIO_REGAR_CD        := 0.0    # sin cooldown: cada click riega (la biomasa finita ya limita)

# ── RAMA VERDE · PANSPERMIA NEGRA (Secuencia de Lanzamiento) ──────
# Secreto post-ESPORULACIÓN: reformar la seta y EYECTAR N veces hacia el espacio.
# Cada eyección cuesta $ (escalado) y suma CALOR; el calor disipa con el tiempo.
# Si una eyección sobrepasaría el calor máximo → falla (sobrecarga): ritmo pulsar-esperar.
const PANSPERMIA_CHARGE_GOAL       := 100.0   # carga necesaria para velocidad de escape
const PANSPERMIA_CHARGE_GAIN       := 15.0    # carga que suma cada eyección
const PANSPERMIA_CHARGE_DECAY      := 7.0     # carga/s que se disipa → no podés ir lento
const PANSPERMIA_HEAT_PER_PULSE    := 25.0    # calor que suma cada eyección
const PANSPERMIA_HEAT_MAX          := 100.0   # tope: una eyección que lo pasaría → MISFIRE
const PANSPERMIA_HEAT_DECAY        := 15.0    # calor/s que disipa → no podés ir rápido
const PANSPERMIA_OVERLOAD_PENALTY  := 18.0    # carga que se pierde al sobrecalentar (misfire)
const PANSPERMIA_MAX_MISFIRES      := 5       # sobrecargas antes de abortar el lanzamiento → esporulación base
const PANSPERMIA_PULSE_COST        := 12000.0 # $ por eyección (sink menor)
const PANSPERMIA_PULSE_EPS         := 0.05    # ε que añade cada eyección (estrés del lanzamiento)
const PANSPERMIA_PL                := 10       # PL del lanzamiento exitoso

# ── RAMA AZUL · SINGULARIDAD (Integración de Cómputo) — Fase 4 ────
# Tras estabilizar (acc≥2, ε≤0.25) se habilita integrar ciclos de cómputo manualmente.
# Cada pulso sube SINCRONÍA (cuesta $ creciente) y TEMPERATURA del núcleo. La sincronía
# decae (no podés ir lento); si el pulso sobrecalienta → throttle (sin progreso, sin castigo).
# SINCRONIZACIÓN: el medidor sube mientras se cumplen TODAS las condiciones de fase a la vez.
const NUCLEO_SYNC_GOAL    := 100.0   # sincronía (%) para el Núcleo de Conciencia
const NUCLEO_SYNC_RATE    := 6.0     # sincronía/s mientras TODAS las condiciones se cumplen (~17s de hold)
const NUCLEO_SYNC_DECAY   := 9.0     # sincronía/s perdida si se rompe alguna (>rate → sostenerlas exige atención)
const NUCLEO_ACC_MIN      := 3       # contabilidad mínima (sustrato de cómputo)
const NUCLEO_OMEGA_MIN    := 0.55    # orden estructural (Ω)
const NUCLEO_EPS_LO       := 0.10    # banda de fase: ε mínimo (el núcleo debe latir, no idle)
const NUCLEO_EPS_HI       := 0.22    # banda de fase: ε máximo (coherencia, sin ruido)
const NUCLEO_BIO_MIN      := 6.0     # tejido biológico a integrar

# ── RAMA AZUL · MENTE COLMENA (Fase 5) ──────────────────────────
# Buff ACOTADO: el auto-play deja de ser permanente → ráfaga activable con cooldown.
# El pasivo ×3 del legado queda permanente (efecto separado).
const MC_BURST_DURATION   := 18.0    # s que corre la IA (auto-click + auto-compra) por activación
const MC_BURST_COOLDOWN   := 45.0    # s de cooldown tras la ráfaga
# Gate ENDURECIDO: sostener simetría + estabilidad + producción SIMULTÁNEAS (reset al romper).
const MC_GATE_HOLD        := 100.0   # s sostenidos sin romper para sincronizar con la IA
const MC_GATE_RATIO_TOL   := 0.03    # tolerancia del ratio activo/pasivo respecto a 0.50
const MC_GATE_EPS_LO      := 0.20    # banda de ε: el sistema debe estar "vivo"
const MC_GATE_EPS_HI      := 0.45    # banda de ε: sin caos
const MC_GATE_DELTA_MIN   := 200.0   # Δ$/s mínimo — throughput real (no idle)

# ── LogManager ──────────────────────────────────────────────────
const MAX_LAPS := 200  # máximo de eventos en lap_events (FIFO, descarta el más viejo)

# ── Multiplicadores de ruta ──────────────────────────────────────
const VACIO_HAMBRIENTO_MULT      := 100.0  # producción ×100 en VACÍO HAMBRIENTO
const REENCARNACION_COST_MULT    := 1.5    # costos de upgrades ×1.5 en REENCARNACIÓN HEREDADA

# ── PL base por ruta de cierre ───────────────────────────────────
# Usado en RunManager.close_run() — otorga Y loguea el PL base de cada ruta.
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
	"ESCLEROCIO OSCURO":         6,
	"AUTÓLISIS DIRIGIDA":        6,
	"MENTE COLMENA DISTRIBUIDA": 8,
	"DEPREDADOR DE REALIDADES":  12,
	"COLAPSO DEPREDATORIO":      8,
	"PANSPERMIA NEGRA":          10,
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
	"ESCLEROCIO OSCURO":         8,
	"AUTÓLISIS DIRIGIDA":        8,
	"POLIMORFÍA TOTAL":          8,
	"POLIMORFIA TOTAL":          8,
	"DOMADOR DEL CAOS":          8,
	"ASCESIS_PROFUNDA":          6,
	"MENTE COLMENA DISTRIBUIDA": 8,
	"DEPREDADOR DE REALIDADES":  8,
	"COLAPSO DEPREDATORIO":      5,
	"PANSPERMIA NEGRA":          6,
}
