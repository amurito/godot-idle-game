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
const MET_OSCURO_CRITICAL_MONEY  := 1000.0 # "recursos críticos": plata < max(esto, N s de ingreso)…
const MET_OSCURO_CRITICAL_SECS   := 3.0    # …(G16: con legados de ingreso grandes, < $1000 era imposible)

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

# ── AUTOFAGIA NECRÓTICA (sub-ruta de Met. Oscuro, post-Esclerocio) ─
# El hongo digiere sus propias estructuras para liberar energía. Irreversible.
const AUTOLISIS_BIO_REQ         := 50.0   # biomasa mínima para iniciar la autofagia
const AUTOLISIS_UPGRADES_REQ    := 5      # niveles de upgrades disponibles mínimos al activar
const AUTOLISIS_DEVOUR_INTERVAL := 30.0   # s entre cada auto-devour
const AUTOLISIS_BIO_BURST       := 8.0    # biomasa fija por devour (además del burst de $)
const AUTOLISIS_BIO_BURST_CAP   := 400.0        # techo de bio que un SOLO devour puede liberar (anti-snowball)
const AUTOLISIS_MONEY_BURST_MULT := 3.0          # el burst de $ = costo del upgrade devorado × este mult
const AUTOLISIS_MONEY_BURST_CAP  := 1_000_000.0   # techo de $ que un SOLO devour puede liberar ($1M; ampliable con buff futuro)
const AUTOLISIS_CLICK_MULT      := 5.0    # click ×5 mientras autólisis activa (reemplaza ×3 de MO)
const AUTOLISIS_PASSIVE_MULT    := 2.0    # pasivo ×2 (restaura el pasivo anulado por MO)
# Cierre voluntario: botón "colapsar núcleo" disponible tras N devours.
const AUTOFAGIA_COLAPSO_MIN_DEVOURS := 40  # devours mínimos para habilitar el colapso voluntario (cierre manual NO da PL bonus)
# ── Mejoras de autofagia (multinivel, costo en biomasa + dinero, capeadas) ──
# Enzimas Líticas: aceleran el intervalo entre devours (piso 5s).
const AUTOFAGIA_SPEED_MAX_LEVEL    := 5      # 30s → 5s (-5s por nivel)
const AUTOFAGIA_SPEED_REDUCTION    := 5.0    # s que resta cada nivel al intervalo
const AUTOFAGIA_DEVOUR_FLOOR       := 5.0    # piso del intervalo entre devours
# Fagocitosis Doble: chance de devorar 1 extra (2º devour) en cada tick, vía tirada d20.
const AUTOFAGIA_DOUBLE_MAX_LEVEL   := 5      # 5 × 16% = 80% (techo, nunca garantizado)
const AUTOFAGIA_DOUBLE_PER_LEVEL   := 0.16   # +16% chance de devour extra por nivel
const AUTOFAGIA_DOUBLE_MAX_CHANCE  := 0.80   # cap duro de la chance del 2º devour
const AUTOFAGIA_TRIPLE_CRIT        := 20     # crítico natural en d20 → 3er devour (triple)
# Digestión Masiva: costo único por uso (se paga antes de devorar).
const AUTOFAGIA_BURST_BIO_COST     := 500.0       # biomasa requerida por uso
const AUTOFAGIA_BURST_MONEY_COST   := 5_000_000.0 # dinero requerido por uso ($5M)
# Gate por devours: para comprar el nivel N de Fagocitosis Doble se requieren ≥ devours acumulados.
# Premia jugar la mecánica (no solo tener recursos) para desbloquear el techo de chance.
const AUTOFAGIA_DOUBLE_GATE := {4: 30, 5: 40}  # {nivel_destino: devours_requeridos}
# Costo de las mejoras: escala con el nivel (mismo growth para ambas).
const AUTOFAGIA_UPG_BIO_BASE       := 150.0    # biomasa del 1er nivel
const AUTOFAGIA_UPG_MONEY_BASE     := 80000.0  # dinero del 1er nivel
const AUTOFAGIA_UPG_COST_GROWTH    := 2.0      # multiplicador de costo por nivel comprado
# Bio pasivo durante autolisis (reemplaza el 0.1/s estándar de MO).
const AUTOLISIS_BIO_PASSIVE        := 1.0      # bio/s pasivo mientras autólisis activa (×10 del MO base)
# Escala el burst de bio por devour: bio_burst = max(BIO_BURST, cost / divisor).
# A $4.4M → 88 bio; a $320K → 6.4 (capped al floor BIO_BURST=8).
const AUTOLISIS_BIO_FROM_COST_DIVISOR := 50000.0
# NG+ Catabolismo Heredado (buff de Banco Genético al cerrar AUTOFAGIA NECRÓTICA).
const CATABOLISMO_HEREDADO_BIO := 10.0   # +bio por nivel al inicio de cada run
# NG+ Ciclo Catabólico (cross AUTOFAGIA NECRÓTICA → DEPREDADOR DE REALIDADES).
const CICLO_CATABOLICO_BIO_MULT := 1.5   # todos los devours dan ×1.5 bio

# ── NECROSIS CONTROLADA (sub-ruta de Met. Oscuro, doble economía Ν) ─
# El hongo desmantela su estructura para liberar energía. Ω deja de ser salud
# y se vuelve combustible: cuanto más bajo, más produce. Cierre al floor.
const NECROSIS_BIO_REQ            := 50.0    # biomasa mínima para activar
const NECROSIS_FLOW_REQ           := 200.0   # Δ$ total mínimo (economía activa corriendo)
const NECROSIS_OMEGA_START        := 0.10    # Ω inicial (heredado del clamp de MO)
const NECROSIS_OMEGA_FLOOR        := 0.001   # Ω de cierre (función pura sin overhead)
const NECROSIS_MULT_CAP           := 25.0    # tope del multiplicador necrótico
# Ν generada por click = pow(poder, MASA_EXP) × CONVERSION × (1−toxicidad).
# Sublineal (sqrt) → desacopla la Ν del click power gigante de late-game.
const NECROSIS_CONVERSION         := 0.8     # coeficiente de generación de Ν
const NECROSIS_MASA_EXP           := 0.5     # exponente sublineal sobre el poder de click
const NECROSIS_AGENT_OMEGA_FACTOR := 0.72    # cada Agente Necrótico: Ω ×= esto (~14 al floor)
const NECROSIS_AGENT_COST_BASE    := 100.0   # costo en Ν del 1er agente
const NECROSIS_AGENT_COST_GROWTH  := 1.75    # ×costo en Ν por agente comprado
# Toxicidad Necrótica: cada agente envenena el sustrato y frena la generación de Ν.
const NECROSIS_TOX_PER_AGENT      := 0.20    # +toxicidad base por agente desplegado
const NECROSIS_TOX_SCALE_PER_AGENT := 0.06   # escala adicional por agente: agente N → ×(1 + (N-1)×0.06)
const NECROSIS_TOX_FLOOR_PER_AGENT := 0.03   # floor permanente por agente: tox nunca decae por debajo de n×0.03
const NECROSIS_TOX_DECAY          := 0.006   # toxicidad/s que decae pasivamente (muy lento → purga obligatoria)
const NECROSIS_EFF_FLOOR          := 0.15    # piso de eficiencia de Ν (nunca trabás del todo, excepto en sobredosis)
const NECROSIS_TOX_OVERDOSE_RECOVER := 0.80  # sobredosis se recupera cuando tox baja de este umbral
const NECROSIS_PASSIVE_FRACTION    := 0.01   # % del pasivo de economía que se convierte en Ν/s
# Depuración: gastás Ν para limpiar toxicidad (decisión: banco Ν vs mantener ritmo).
const NECROSIS_PURGE_FRACTION     := 0.4     # toxicidad ×= esto al purgar (limpia 60%)
const NECROSIS_PURGE_COST_BASE    := 150.0   # costo base en Ν · escala con la toxicidad actual
# Catalizador Necrótico: sink de Ν que acelera la propia generación de Ν (aditivo, "ligero").
const NECROSIS_CATALYST_PER_LEVEL := 0.20    # +20% Ν por nivel (1 + nivel×0.20, lineal)
const NECROSIS_CATALYST_COST_BASE := 200.0   # costo en Ν del 1er nivel
const NECROSIS_CATALYST_COST_GROWTH := 2.0   # ×costo por nivel comprado

# ── PROTOCOLO OMEGA-CERO (final del árbol oscuro — síntesis de las 3 sub-rutas) ─
# Desbloqueo en Banco Genético (12 PL) tras cerrar AUTOFAGIA + NECROSIS + ESCLEROCIO.
# Loop activo que sintetiza los tres ecos: devour (autofagia) + Ω-combustible (necrosis)
# + sello intencional por Φ (esclerocio). El hongo ejecuta los tres a la vez.
const OMEGA_CERO_BIO_REQ          := 50.0    # biomasa mínima para activar dentro de MO
const OMEGA_CERO_DEVOUR_REQ       := 5       # devours previos en MO requeridos (ya demostró depredar)
const OMEGA_CERO_PHI_TARGET       := 300.0   # Φ necesaria para habilitar el sello
const OMEGA_CERO_PHI_BASE         := 4.0     # Φ base por devour (antes del multiplicador por rigidez)
const OMEGA_CERO_K                := 0.10    # numerador del phi_mult (0.10/Ω) — a Ω=0.10 mult=1.0
const OMEGA_CERO_PHI_CAP          := 10.0    # tope del multiplicador de Φ por devour
const OMEGA_CERO_OMEGA_START      := 0.10    # Ω inicial (heredado del clamp de MO)
const OMEGA_CERO_OMEGA_FACTOR     := 0.82    # cada devour: Ω ×= esto (~12 devours a Ω≤0.01)
const OMEGA_CERO_OMEGA_FLOOR      := 0.001   # Ω de cierre de emergencia (igual que necrosis)
const OMEGA_CERO_DEVOUR_INTERVAL  := 6.0     # s entre devours automáticos
const OMEGA_CERO_MONEY_BURST_MULT := 0.0     # devour no devuelve plata (evita loop compra→devour→recompra)
const OMEGA_CERO_KERNEL_CAP       := 3.0     # tope del Núcleo Φ (phi_al_cierre / target) → intensidad del buff
# Buff NG+ "Memoria Sináptica": término pasivo aditivo exp(k·(1−Ω))−1, acotado.
const OMEGA_CERO_BUFF_K_BASE      := 3.5     # k base (escalado por el kernel logrado, cap KERNEL_CAP)
const OMEGA_CERO_BUFF_CAP         := 50000.0 # tope del pasivo aditivo de Memoria Sináptica ($/s)
# Logro "Singularidad Perfecta": sellar con Φ y Ω extremos (dejar correr el loop, no sellar al mínimo).
const OMEGA_CERO_ACH_PHI          := 500.0   # Φ ≥ esto (doble del target)
const OMEGA_CERO_ACH_OMEGA        := 0.01    # Ω ≤ esto al cerrar
# Inanición: si el loop no puede devorar N ticks consecutivos, Φ empieza a decaer.
const OMEGA_CERO_STARVE_GRACE     := 1       # ticks de gracia sin material antes de penalizar
const OMEGA_CERO_PHI_DECAY_TICK   := 20.0   # Φ perdido por tick de inanición (post-gracia)
const OMEGA_CERO_BATCH_SIZE       := 10      # upgrades devorados por tick (batch)
const OMEGA_CERO_PHI_CLICK_AMP    := 0.5    # Φ acumulada amplifica click power durante la run (aditivo)

# ── REMISIÓN METABÓLICA (última post-MO — sanación / floración) ──────────────
# Desbloqueo en Banco Genético tras cerrar las 4 sub-rutas oscuras (incl. OMEGA-CERO).
# Loop activo: Ω deriva sola hacia el colapso; el jugador la empuja con botones ±
# para mantenerla dentro de una banda móvil. Dentro de banda la biomasa florece y
# el contador Θ sube; fuera, la biomasa se marchita. Θ≥target → sello. Si la biomasa
# cae bajo el piso, la run NO cierra: INVOLUCIONA de vuelta a Met. Oscuro (REMISIÓN
# queda bloqueada esa run; el jugador debe elegir otra sub-ruta).
const REMISION_BIO_GATE        := 150.0   # biomasa requerida en MO para abrir el gate
const REMISION_OMEGA_START     := 0.30    # Ω inicial (centro de banda)
const REMISION_OMEGA_DRIFT     := 0.015   # Ω cae sola por segundo (la "enfermedad" tira al colapso)
const REMISION_NUDGE           := 0.03    # empuje de Ω por click de botón ±
const REMISION_BAND_CENTER     := 0.30    # centro base de la banda objetivo
const REMISION_BAND_AMP        := 0.12    # amplitud del desplazamiento senoidal del centro
const REMISION_BAND_FREQ       := 0.35    # rad/s del desplazamiento del centro
const REMISION_BAND_HALF       := 0.04    # medio ancho de la banda (dentro si |Ω−c(t)|≤esto)
const REMISION_THETA_TARGET    := 60.0    # s continuos dentro de banda para armar el sello
const REMISION_BLOOM_RATE      := 0.03    # +3%/s biomasa dentro de banda (compuesto)
const REMISION_WITHER_RATE     := 0.05    # −5%/s biomasa fuera de banda
const REMISION_THETA_DECAY     := 1.0     # Θ/s perdido fuera de banda (acumulás 1/s dentro — neto 0 al 50/50)
const REMISION_BIO_FLOOR       := 30.0    # biomasa < esto → involución a Met. Oscuro
const REMISION_OMEGA_MIN       := 0.01    # clamp inferior de la Ω controlada
const REMISION_OMEGA_MAX       := 0.60    # clamp superior de la Ω controlada
const REMISION_PL_DIVISOR      := 50.0    # bonus PL al cerrar = biomasa_final / esto (cap NG genérico)
# Buff NG+ "Control de Ω": en runs normales habilita empujar Ω con cooldown (influencia gradual).
const CONTROL_OMEGA_NUDGE      := 0.02    # empuje de Ω por pulso en runs normales
const CONTROL_OMEGA_COOLDOWN   := 1.0     # cooldown del pulso (s)
const CONTROL_OMEGA_MAX        := 0.15    # magnitud máxima del offset acumulado (influencia acotada)

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

# ── INVOLUCIÓN · sistema común (docs/design/involucion_transmutaciones.md) ──
# TRANSMUTACIÓN (A → A+): con la llave del Banco y A activa, el botón de reversión [T] aparece
# TRANSMUT_APPEARANCES veces × TRANSMUT_APPEAR_DURATION s dentro de una ventana adaptada a la vida
# de A, y después desaparece esa run. Ver TransmutationLogic.slots().
const TRANSMUT_FIRST_DELAY      := 60.0   # s con A activa antes de la 1ª aparición (o W/4 si A vive poco)
const TRANSMUT_WINDOW_MAX       := 300.0  # ventana máxima (5 min)
const TRANSMUT_WINDOW_MARGIN    := 20.0   # la ventana termina este margen antes de la vida esperada de A
const TRANSMUT_APPEARANCES      := 3
const TRANSMUT_APPEAR_DURATION  := 20.0
const TRANSMUT_DIGEST_HIPER     := 0.5    # Hiper se digiere en $: 50 % de lo generado con Hiper activa

# ── TRANSMUTACIÓN · FUSIÓN CATABÓLICA (revierte HIPERASIMILACIÓN) ──
# "Un paso atrás para tomar impulso": con la llave transmut_fusion y Hiperasimilación activa,
# el botón [T] la revierte (digestión en $) y activa FUSIÓN CATABÓLICA: la run NO se cierra.
# Se sacrifica el ×10 salvaje de click por un Click ×5 + Pasivo ×5 estable + una ráfaga
# activable (Metabolismo Híbrido) anti-AFK. Cierre voluntario al sello tras alcanzar el hito.
const FUSION_CLICK_MULT       := 5.0        # click ×5 (reemplaza el ×10 de Hiperasimilación)
const FUSION_PASSIVE_MULT     := 5.0        # pasivo ×5 (restaura el pasivo que hiper nerfeaba a ×0.25)
const FUSION_BURST_MULT       := 2.0        # Metabolismo Híbrido: ×2 a TODO el ingreso mientras corre
const FUSION_BURST_DURATION   := 30.0       # s que dura la ráfaga
const FUSION_BURST_COOLDOWN   := 120.0      # s de cooldown tras la ráfaga
const FUSION_FORCED_MELT      := 3          # FRACASO: ráfagas FORZADAS seguidas (durante el cooldown) que funden
                                            # el motor → cierra como HIPERASIMILACIÓN (una ráfaga normal resetea)
const FUSION_SEAL_MONEY       := 100_000_000.0 # $ generados para habilitar el sello del final
const FUSION_SEAL_BURST_MONEY := 50_000_000.0 # $ generados DURANTE ráfagas: premia usar [Q] y hace útil [W].
                                              # Con cooldown base ~1/3 del ingreso cae en ráfaga: 50M queda por
                                              # encima de 1/3 de $100M → es la condición que define el sello.
                                              # Simulador (2026-10): sella a ~18 min con [W], ~20 sin [W]; sin
                                              # usar la ráfaga no sella (ng_fusion_lazy_bursts).
const FUSION_SEAL_STRUCTURAL_N := 150       # upgrades estructurales (n) mínimos: fuerza inversión estructural real
# Reducción de cooldown de la ráfaga (sink de dinero, tecla W). El $ abundante acelera las ráfagas.
# Cada nivel multiplica el cooldown por (1 - PCT): efecto compuesto, claramente perceptible.
const FUSION_CD_REDUCE_PCT        := 0.20   # -20% del cooldown por nivel comprado
const FUSION_CD_FLOOR             := 30.0   # cooldown mínimo alcanzable (no baja de aquí)
const FUSION_CD_COST_BASE         := 1_000_000.0 # costo del nivel 1 (antes 10M: nunca convenía)
const FUSION_CD_COST_GROWTH       := 1.9    # multiplicador de costo por nivel

# ── TRANSMUTACIÓN · CAOS ORQUESTADO (revierte HOMEOSTASIS) — CaosOrquestadoLogic ──
# "Homeostasis aprendió a no temerle al caos: lo dirige." Valores iniciales aprobados por el
# autor (2026-10-12); a calibrar con el simulador (objetivo 15–25 min desde la reversión).
const CAOS_DIGEST_OMEGA_MIN      := 0.15   # digestión: Ω_min += esto por el resto de la run
const CAOS_FUEL_K                := 1.0    # combustible: ingreso × (1 + k·ε)
const CAOS_FUEL_CAP              := 3.0    # tope del combustible
const CAOS_CHARGE_RATE           := 0.01   # carga de caos /s (piso de ε): 0.6 en 60 s, 1.0 en 100 s
const CAOS_CHARGE_MAX            := 2.0
const CAOS_OMEGA_FLOOR           := 0.20   # Ω no baja de esto con Caos activo
const CAOS_COLLAPSE_K            := 2.0    # [Q] Colapso Dirigido: ráfaga × (1 + k·ε cobrado)
const CAOS_COLLAPSE_DURATION     := 20.0
const CAOS_COLLAPSE_COOLDOWN     := 90.0
const CAOS_CD_REDUCE_PCT         := 0.20   # [W] "Afinar": −20 % de cooldown por nivel…
const CAOS_CD_CHARGE_BONUS       := 0.25   # …+25 % de velocidad de carga por nivel…
const CAOS_CD_BURST_BONUS        := 0.15   # …y +15 % al multiplicador del Colapso (el Gran Colapso lo limita la ráfaga)
const CAOS_CD_FLOOR              := 30.0
const CAOS_CD_COST_BASE          := 500_000.0
const CAOS_CD_COST_GROWTH        := 1.9
const CAOS_RED_EPS               := 0.60   # zona roja (sello + "colapso con carga")
# Sello = GRAN COLAPSO (§10.1): un Colapso cobrado con ε ≥ GRAND_EPS cuya ráfaga genere ≥ GRAND_MONEY
# sella la ruta al terminar. Es la apuesta al extremo: esperar la carga larga y una economía grande.
const CAOS_GRAND_EPS             := 1.8
const CAOS_GRAND_FAILS        := 5          # FRACASO: Grandes Colapsos fallidos → cierra como HOMEOSTASIS (con 3 el jugador normal fracasaba)
const CAOS_GRAND_MONEY           := 5_000_000.0  # simulador: ~15 min con [W], ~20 sin [W]

# ── TRANSMUTACIÓN · CORO SIMBIÓTICO (revierte SIMBIOSIS) — CoroSimbioticoLogic ──
# "La cooperación deja de ser un pacto y se vuelve un ritmo." Valores iniciales aprobados por el
# autor (2026-10-12); a calibrar con el simulador (objetivo 15–25 min desde la reversión).
const TRANSMUT_LIFE_SIMBIOSIS    := 160.0  # vida estimada de Simbiosis para la agenda del botón [T]
                                           # (su cierre automático espera mientras queden apariciones)
const CORO_DIGEST_COMBO          := 16     # digestión: combo inicial (se va si no lo sostenés)
const CORO_TEMPOS                := [80.0, 95.0, 110.0]   # BPM por movimiento: I Andante · II Moderato · III Allegro
                                                          # (autor 2026-10-13: 90/110/130 con ±0.15 s se sentía muy difícil)
const CORO_MOVEMENT_BARS         := [16, 20, 24]          # ACENTOS acertados por movimiento (antes 40/60/80
                                                            # compases de 4 golpes: el autor lo sentía largo y tedioso)
const CORO_ACCENT_COMBO          := 3      # combo por acento acertado (antes +1 por golpe, 4 por compás)
const CORO_BEATS_PER_BAR         := 4
const CORO_HIT_WINDOW            := 0.20   # s: ventana de acierto a cada lado del golpe (tolerante a latencia web)
const CORO_COMBO_BONUS           := 0.04   # ingreso × (1 + 0.04 · combo)…
const CORO_COMBO_CAP             := 64     # …tope ×3.56
const CORO_SKIP_DECAY            := 4      # combo perdido por acento salteado (no se arma y se suelta)
const CORO_FAIL_STREAK           := 8      # FRACASO: acentos seguidos sin acertar → cierra como SIMBIOSIS
const CORO_LEGACY_TEMPO          := 90.0   # legado Compás Interno: metrónomo suave en todas las runs…
const CORO_LEGACY_BONUS          := 0.01   # …+1 % de click por golpe a tiempo seguido…
const CORO_LEGACY_CAP            := 0.15   # …tope +15 %

# ── TRANSMUTACIÓN · MICELIO OMNISCIENTE (revierte RED MICELIAL) — MicelioOmniscienteLogic ──
# Verbo: ASIGNAR. "La red deja de crecer hacia afuera y empieza a verlo todo desde adentro."
# Spec §10.3 (2026-10-12); a calibrar con el simulador (objetivo 15–20 min desde la reversión).
const MICELIO_DIGEST_POOL        := 60.0   # digestión: micelio libre inicial = max(micelio de la red, esto)
const MICELIO_GROW_PER_HIFA      := 0.05   # micelio libre /s por hifa
const MICELIO_CAP_BASE           := 60.0   # tope (libre + conectado) = base + por_hifa · hifas
const MICELIO_CAP_PER_HIFA       := 4.0    # 180 (red completa) ≈ 30 hifas
const MICELIO_NODE_STEP          := 5.0    # micelio por click derecho
const MICELIO_NODE_MAX           := 20.0   # conexión máxima por nodo (lleno = autocompra)
const MICELIO_NODE_BONUS         := 1.0    # lo que aportan los niveles × (1 + bonus · conexión/máx)
const MICELIO_NODE_DISCOUNT      := 0.015  # −1.5 % de costo por punto conectado (−30 % lleno)
const MICELIO_DRIFT_INTERVAL     := 10.0   # s: 1 punto libre fluye solo al nodo más comprado
const MICELIO_SEAL_HOLD          := 60.0   # s con los 9 nodos llenos para habilitar el sello
const MICELIO_LATENT_MULT        := 1.25   # legado Nodo Latente: el primer nodo lleno, en todas las runs
# Rupturas (pedido del autor 2026-10-17: "no tiene forma de perder"). Secuencia pseudoaleatoria fija
# (reproducible para bot y goldens): cada intervalo el micelio cruje sobre un nodo conectado.
const MICELIO_RUPTURE_INTERVALS  := [80.0, 65.0, 110.0, 75.0, 120.0, 90.0, 70.0, 100.0]  # > sello (60 s): con 40–80 s sellar era suerte
const MICELIO_RUPTURE_WARN       := 4.0    # s de aviso (el nodo se puede salvar desconectándolo)
const MICELIO_RUPTURE_CHANCE     := 0.50   # probabilidad base de que el crujido rompa
const MICELIO_RUPTURE_DAMAGE     := 0.60   # fracción de la conexión del nodo que se pierde (no vuelve al pozo)
const MICELIO_REINFORCE_MAX      := 4      # [W] Reforzar: niveles…
const MICELIO_REINFORCE_CHANCE   := 0.20   # …−20 % de probabilidad por nivel…
const MICELIO_REINFORCE_DAMAGE   := 0.15   # …−15 % de daño por nivel…
const MICELIO_REINFORCE_SECS     := 15.0   # …cuesta 15 s de ingreso…
const MICELIO_REINFORCE_GROWTH   := 1.6    # …× 1.6 por nivel
const MICELIO_COLLAPSE_FULL      := 4      # FRACASO: nodos LLENOS rotos → la red colapsa → MICELIO FRAGMENTADO
const MICELIO_SCAR_CHANCE        := 0.75   # legado Cicatriz Micelial: probabilidad de ruptura × 0.75

# ── TRANSMUTACIÓN · HUÉSPED SOBERANO (revierte PARASITISMO) — HuespedSoberanoLogic ──
# Verbo: DOMESTICAR. Spec §10.4 (2026-10-13); a calibrar con el simulador.
const TRANSMUT_LIFE_PARASITISMO  := 120.0  # Parasitismo vive 13–20 s: su cierre espera al botón [T] (25/52/80 s)
const HUESPED_PANTRY_BIO_PER_MEAL := 2.0   # digestión: 1 comida de despensa por cada 2 de biomasa robada
const HUESPED_HUNGER_START       := 50.0
const HUESPED_HUNGER_RATE        := 2.0    # hambre /s…
const HUESPED_HUNGER_LEVEL_K     := 0.2    # …× (1 + 0.2 · nivel de confianza): el parásito crece
const HUESPED_FEED               := 30.0   # [Q] Alimentar: −30 de hambre
const HUESPED_FEED_MONEY_PCT     := 0.04   # sin despensa cuesta el 4 % del dinero actual (10 % congelaba la economía)
const HUESPED_BAND_LO            := 25.0   # banda de domesticación (confianza sube): 50 de ancho deja
                                           # lugar para anticipar un antojo (con 30–70 había casos sin salida)
const HUESPED_BAND_HI            := 75.0
const HUESPED_TRUST_GAIN         := 1.0    # confianza /s en banda
const HUESPED_TRUST_LOSS         := 0.5    # confianza /s perdida si está saciado (perezoso)
const HUESPED_BITE_CORROSION     := 0.004  # corrosión /s mientras muerde (hambre > banda)
const HUESPED_LEVELS             := [60, 150, 270, 420, 600]  # confianza para cada nivel (el 5 sella)
const HUESPED_GIFT_INTERVAL      := 20.0   # s en banda entre regalos…
const HUESPED_GIFT_SECS_PER_LEVEL := 5.0   # …de (5 · nivel) s de ingreso
const HUESPED_TRUEQUE_PER_LEVEL  := 0.2    # trueque × (1 + 0.2 · nivel)
const HUESPED_CRAVING_INTERVALS  := [40.0, 30.0, 50.0, 35.0, 45.0]  # antojos (secuencia fija, sin RNG)
const HUESPED_CRAVING_WARN       := 4.0    # s de aviso antes del antojo
const HUESPED_CRAVING_HUNGER     := 15.0   # hambre que suma el antojo
const HUESPED_PACT_CORROSION     := 0.5    # legado Pacto Soberano: corrosión de Parasitismo × 0.5
const HUESPED_STARVE_TIME        := 15.0   # FRACASO: s con el hambre en 100 → te come → cierra como PARASITISMO

# ── BIOLOGÍA · MUTUALISMO (tier 2 de SIMBIOSIS) — MutualismoLogic ──
# Verbo: NEGOCIAR. Spec docs/design/biologia_mutualismo_endosimbiosis.md §4. Todo en SEGUNDOS DE
# INGRESO (EconomyManager.get_delta_total()). A calibrar con el simulador.
const MUTUALISMO_MIN_T           := 1      # se desbloquea con la 1ª trascendencia
const MUTUALISMO_ENTRY_TIME      := 60.0   # s de run para el botón ACEPTAR PACTO (= botón de sellar Simbiosis)
const MUTUALISMO_FIRST_OFFER     := 10.0   # s hasta la primera oferta
const MUTUALISMO_OFFER_INTERVAL  := 25.0   # s entre ofertas
const MUTUALISMO_DECIDE_TIME     := 10.0   # s para [A]/[R]; sin decidir = rechazar
const MUTUALISMO_EXCHANGE_GIVE   := 15.0   # Intercambio: das 15 s de ingreso…
const MUTUALISMO_EXCHANGE_MULT   := 1.5    # …y recibís ×1.5 al ingreso…
const MUTUALISMO_EXCHANGE_SECS   := 30.0   # …durante 30 s (= 15 s de ingreso: trato justo)
const MUTUALISMO_LOAN_GET        := 20.0   # Préstamo: recibís 20 s ya…
const MUTUALISMO_LOAN_PAY        := 25.0   # …y el socio cobra 25 s…
const MUTUALISMO_LOAN_TERM       := 40.0   # …a los 40 s (sin plata: incumplimiento, −3 confianza)
const MUTUALISMO_AID_GIVE        := 20.0   # Auxilio: das 20 s sin nada a cambio…
const MUTUALISMO_AID_RETURN      := 30.0   # …y a los 60 s la gratitud devuelve 30 s
const MUTUALISMO_AID_GRATITUDE_TIME := 60.0
const MUTUALISMO_TEMPT_GET       := 40.0   # Tentación: tomás 40 s gratis (−4 confianza)
const MUTUALISMO_REJECT_STREAK   := 3      # rechazos seguidos (sin contar Tentación) → −1 confianza
const MUTUALISMO_TRUST_SEAL      := 8      # confianza para sellar…
const MUTUALISMO_FAIR_BAND       := 30.0   # …con |R| ≤ 30 s (banda justa)
const MUTUALISMO_BREAK           := 60.0   # |R| ≥ 60: ruptura (R < 0 → PARASITISMO, R > 0 → SIMBIOSIS)

# Legados de Biología (B4): sirven también fuera de la Biología.
const MICORRIZA_PASSIVE          := 1.10   # Legado Micorriza (sellar Mutualismo): pasivo ×1.10 en todas las runs
const MICROBIOMA_DAMPEN          := 0.75   # Legado Microbioma (sellar Holobionte): shocks y corrosión ×0.75
const MITOCONDRIA_MULT           := 1.15   # Legado Mitocondria (sellar Endosimbiosis): click y pasivo ×1.15…
const MITOCONDRIA_EPS_MAX        := 0.30   # …mientras ε < 0.30
# Logros de Biología (B4)
const ACH_COMERCIO_JUSTO_R       := 5.0    # sellar Mutualismo con |R| ≤ 5
const ACH_BUEN_PAGADOR_LOANS     := 5      # préstamos pagados en una run
const ACH_CONTRARRELOJ_SECS      := 240.0  # Endosimbiosis: los 6 genes en < 4 min desde ENGULLIR
const ACH_HUESPED_PERFECTO_REJ   := 50.0   # Endosimbiosis MYTHIC: rechazo pico ≤ 50

# ── BIOLOGÍA · HOLOBIONTE (tier 3 de SIMBIOSIS) — HolobionteLogic ──
# Verbo: SOSTENER UN ECOSISTEMA. Spec §5. A calibrar con el simulador.
const HOLOBIONTE_MIN_T           := 2      # árbol de T2 (decisión del autor 2026-10-16)
const HOLO_OFFER_INTERVAL        := 40.0   # s entre ofertas de la Raíz dentro de Holobionte
const HOLO_RECRUIT_INTERVAL      := 45.0   # s entre llegadas de socios (y tras un rechazo)
const HOLO_RESPAWN               := 60.0   # s hasta que un socio muerto vuelve a ofrecerse
const HOLO_JOIN_HEALTH           := 60.0   # salud al sumarse
const HOLO_HEAL                  := 1.0    # salud /s con la necesidad cumplida
const HOLO_HURT                  := 2.0    # salud /s perdida sin la necesidad
const HOLO_DEATH_TRUST           := 3      # confianza perdida cuando muere un socio
const HOLO_COLLAPSE_DEATHS       := 5      # muertes que desarman el ecosistema (cierra como MUTUALISMO)
const HOLO_SEAL_HEALTH           := 70.0   # sello: los 4 socios ≥ 70…
const HOLO_SEAL_HOLD             := 90.0   # …durante 90 s seguidos
const HOLO_CPS_TAU               := 10.0   # s de la media móvil de clicks (Bacteria)
const HOLO_RAIZ_PASSIVE_SHARE    := 0.33   # Raíz: pasivo ≥ 1/3 del ingreso (con 50 % era inalcanzable:
                                           # Simbiosis deja el ingreso ~75 % activo; comprando sólo pasivo ~37 %)
const HOLO_RAIZ_MULT             := 1.5    #   da pasivo ×1.5
const HOLO_BACTERIA_CPS          := 1.0    # Bacteria: ≥ 1 click/s de media
const HOLO_BACTERIA_MULT         := 1.2    #   da TODO el ingreso ×1.2 (con click ×1.5 hundía el pasivo
                                           #   y la Raíz moría siempre: los premios no deben sabotearse)
const HOLO_ALGA_EPS              := 0.30   # Alga: ε ≤ 0.30
const HOLO_ALGA_OMEGA            := 0.10   #   da Ω +0.10
const HOLO_LEVADURA_BUY_EVERY    := 60.0   # Levadura: una compra cada 60 s
const HOLO_LEVADURA_DISCOUNT     := 0.90   #   da mejoras −10 %

# ── BIOLOGÍA · ENDOSIMBIOSIS (cruce Parasitismo × Simbiosis) — EndosimbiosisLogic ──
# Verbo: DOSIFICAR. Spec §6. ATP en unidades fijas (no depende de la escala de la run). A calibrar.
const ENDOSIMBIOSIS_MIN_T        := 2      # árbol de T2 (decisión del autor 2026-10-16)
const ENDO_WINDOW_START          := 30.0   # s de Simbiosis elegible hasta que aparece ENGULLIR…
const ENDO_WINDOW_LEN            := 20.0   # …y cuánto dura el botón
const ENDO_ATP_RATE              := 0.8    # ATP/s a autonomía 100 (escala con la autonomía)
const ENDO_ATP_START             := 50.0   # ATP al engullir (lo que había robado el parásito): alcanza para 3
                                           # genes seguidos → la tentación de apurarse (sin esto el ATP marcaba solo el ritmo)
const ENDO_GENE_COST             := 12.0   # ATP del 1er gen…
const ENDO_GENE_COST_GROWTH      := 1.35   # …× 1.35 por gen
const ENDO_AUTONOMY_START        := 60.0
const ENDO_AUTONOMY_REGEN        := 0.4    # autonomía /s (a 100 se escapa): sin genes, ~50 s por gen como máximo
const ENDO_TRANSFER_AUTONOMY     := 20.0   # autonomía que quita cada gen
const ENDO_TRANSFER_REJECTION    := 35.0   # rechazo que suma cada gen, Genoma incluido (a 100 lo expulsa):
                                           # tres genes seguidos = expulsión; sostenido, ~35 s por gen
const ENDO_REJECTION_DECAY       := 1.0    # rechazo /s que se disipa
const ENDO_DRAIN                 := 0.10   # sin Membrana drena el 10 % del ingreso
const ENDO_FEED_SECS             := 10.0   # [W] Alimentar: hasta 10 s de ingreso…
const ENDO_FEED_ATP              := 8.0    # …→ 8 ATP (en proporción a lo pagado)
const ENDO_FEED_COOLDOWN         := 10.0   # s entre alimentaciones (sin esto se compraban todos los genes en 1 min)
const ENDO_RESPIRACION_MULT      := 1.5    # gen 1: pasivo ×1.5
const ENDO_REPLICACION_MULT      := 1.5    # gen 3: click ×1.5
const ENDO_SENALIZACION_OMEGA    := 0.10   # gen 4: Ω +0.10
const ENDO_METABOLISMO_DISCOUNT  := 0.85   # gen 5: mejoras −15 %

# ── SOMBRA · INESTABILIDAD CONSCIENTE (anti-Homeostasis) — InestabilidadLogic ──
# Verbo: OBSERVAR (lore matemático). Spec docs/design/sombras.md §9. Calibrado con el simulador.
const INEST_MIRROR_EPS           := 0.50   # espejo: ε ≥ esto… (0.60 quedaba en el borde de lo alcanzable clickeando)
const INEST_MIRROR_TIME          := 60.0   # …sostenido estos s (con Homeostasis latente antes y Contabilidad ≥ 1)
const INEST_MIRROR_WARN          := 10.0   # aviso previo con cuenta regresiva
const INEST_OBSERVE_P            := 0.20   # [Q] OBSERVAR: perturbación que suma al objetivo de ε
const INEST_OBSERVE_CD           := 6.0
const INEST_P_MAX                := 1.5
const INEST_P_MIN                := -0.30  # integrar de más amortigua el ε natural
const INEST_INTEGRATE_P          := 0.25   # [W] INTEGRAR: P −= esto…
const INEST_INTEGRATE_CD         := 20.0
const INEST_INTEGRATE_SECS       := 10.0   # …y cuesta 10 s de ingreso
const INEST_INTEGRATE_MIN_COST   := 100.0
const INEST_LEMMA_HOLD := {"impulso": 40.0, "lyapunov": 60.0, "inercia": 40.0, "elasticidad": 30.0}  # s de demostración
const INEST_PROGRESS_DECAY       := 0.5    # el progreso baja a la mitad de velocidad si la condición se rompe
const INEST_CPS_TAU              := 5.0    # media móvil de clicks/s (Lema del impulso)
const INEST_IMPULSO_CPS          := 3.0    # a: ≥ 3 clicks/s
const INEST_LYAPUNOV_LO          := 0.90   # ε: al borde…
const INEST_LYAPUNOV_HI          := 1.10   # …sin caer
const INEST_INERCIA_IDLE         := 3.0    # d: sin clickear (s)…
const INEST_INERCIA_EPS          := 0.60   # …con ε ≥ esto (sin clicks ε ≈ P + pasivo: pide ≥ 4 observaciones)
const INEST_STRUCT_UPGRADES      := 5      # n: mejoras estructurales desde que se reveló
const INEST_ELASTIC_RATIO        := 1.75   # Ω ≥ ×1.75 su mínimo desde que se reveló: estirarse y recuperarse
                                           # (relativo: Ω absoluto depende de n y con muchas mejoras pedía ε < 0.35)
const INEST_OPEN_DRIFT           := 0.002  # P/s por cada lema revelado sin demostrar (lo observado sigue perturbando)
const INEST_THEOREM_BONUS        := 0.10   # ingreso × (1 + 0.10 · lemas demostrados)
const INEST_DIVERGE_EPS          := 1.20   # FRACASO: ε > esto…
const INEST_DIVERGE_TIME         := 10.0   # …durante estos s → HOMEOSTASIS (la ecuación diverge)
const INEST_CONVERGE_EPS         := 0.35   # FRACASO: ε < esto…
const INEST_CONVERGE_TIME        := 60.0   # …durante estos s → HOMEOSTASIS (converge sola: el AFK no traba la run)
const INEST_NG_BASE              := 8      # NG+: elegancia = 8 − integraciones
const ACH_INEST_ELEGANT_MAX      := 5      # MYTHIC Demostración Elegante: ≤ 5 integraciones (bot experto 5, jugador normal 7)
const PREDICTOR_MARGIN           := 0.05   # legado Predictor Estructural: avisa a esta distancia de un umbral de ε

# ── SOMBRA · AYUNO PRIMORDIAL (anti-Hiperasimilación) ────────────
# Disparador ESPEJO (no hay botón: es consecuencia de cómo jugás): Hiper es clickear frenético;
# Ayuno es renunciar a clickear. Con la llave transmut_ayuno, no clickear AYUNO_MIRROR_IDLE s
# teniendo pasivo propio y ε bajo activa el ayuno. Se avisa AYUNO_MIRROR_WARN s antes.
const AYUNO_MIRROR_IDLE           := 60.0   # s sin clickear
const AYUNO_MIRROR_WARN           := 10.0   # aviso previo ("el hongo empieza a ayunar…")
const AYUNO_MIRROR_EPS_MAX        := 0.10   # ε por debajo de esto
const AYUNO_MIRROR_PASSIVE_MIN    := 10.0   # $/s de pasivo propio (sin economía no hay ayuno, hay abandono)
const AYUNO_MIRROR_MIN_RUN        := 60.0   # s mínimos de run
# El ayuno drena B activamente; la ausencia de B/ε acumula Silencio (S) que amplifica el pasivo.
# [Q] ROMPER EL AYUNO: burst basado en S acumulado, resetea S. [W] ASCESIS: mejora S_rate Y pasivo.
const AYUNO_BIOMASA_DRAIN         := 2.0    # componente fija del drain de B (/s)
const AYUNO_BIOMASA_DRAIN_PCT     := 0.20   # componente proporcional: drain += B × 0.20 /s
const AYUNO_SILENCIO_FACTOR       := 0.01   # pasivo × (1 + S × factor); S=100 → ×2.0
const AYUNO_ASCESIS_RATE_BONUS    := 0.15   # +15% a S_rate por nivel de Ascesis
const AYUNO_ASCESIS_PASSIVE_BONUS := 0.08   # +8% al mult pasivo por nivel (directo, stacks con S)
const AYUNO_ASCESIS_COST          := 50.0   # costo base ($ del primer nivel)
const AYUNO_ASCESIS_SCALE         := 2.5    # multiplicador de costo por nivel
const AYUNO_BURST_DURATION        := 15.0   # s que dura el burst de ROMPER EL AYUNO
const AYUNO_BURST_DIVISOR         := 50.0   # burst_mult = 1 + S / divisor (S=50→×2, S=200→×5)
const AYUNO_BURST_BIO_SPIKE       := 5.0    # B añadida al romper el ayuno (el sistema "comió")
const AYUNO_SELLO_CYCLES          := 5      # ciclos (bursts) mínimos para sello 1
const AYUNO_SELLO_TOTAL           := 500.0  # S acumulado total mínimo para sello 2
const AYUNO_SELLO_STREAK          := 180.0  # s de silencio sin click NI [Q] (antes 90s)
const AYUNO_NG_PEAK_DIV           := 50.0   # NG+ bonus = floor(S_peak / div), cap AYUNO_NG_CAP
const AYUNO_NG_CAP                := 8      # cap del bonus NG+ variable
const AYUNO_PL_BASE               := 8      # PL base al sellar AYUNO PRIMORDIAL
const AYUNO_LEGACY_DURATION       := 600.0  # s que dura el efecto legado_primicia_del_vacio (antes 90s)
const AYUNO_LEGACY_MULT_START     := 3.0    # pasivo ×3.0 al inicio, decae a ×1.0 en 10 min

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
# Multiplicadores de Red Micelial (IncomeModifiers). El portal de Mente Colmena mide el equilibrio
# SIN ellos (G8, auditoría 2026-10): con click ×0.5 y pasivo ×2.5 el 50/50 era inalcanzable.
const RED_MICELIAL_CLICK_MULT   := 0.5
const RED_MICELIAL_PASSIVE_MULT := 2.5
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
	"MUTUALISMO":                6,
	"HOLOBIONTE":                8,
	"ENDOSIMBIOSIS":             8,
	"ESPORULACION":              5,
	"ESPORULACIÓN":              5,
	"ESPORULACION TOTAL":        5,
	"PARASITISMO":               2,
	"HIPERASIMILACION":          1,
	"HIPERASIMILACIÓN":          1,
	"MUTACION_FINAL":            4,
	"METABOLISMO OSCURO":        4,
	"ESCLEROCIO OSCURO":         6,
	"AUTOFAGIA NECRÓTICA":        6,
	"NECROSIS CONTROLADA":       5,
	"PROTOCOLO OMEGA-CERO":      8,
	"REMISIÓN METABÓLICA":       8,
	"MENTE COLMENA DISTRIBUIDA": 8,
	"DEPREDADOR DE REALIDADES":  12,
	"COLAPSO DEPREDATORIO":      8,
	"PANSPERMIA NEGRA":          10,
	"COLAPSO CONTROLADO":        6,
	"POLIMORFÍA TOTAL":          9,
	"POLIMORFIA TOTAL":          9,
	"DOMADOR DEL CAOS":          11,
	"ASCESIS_PROFUNDA":          7,
	"FUSIÓN CATABÓLICA":         9,
	"CAOS ORQUESTADO":           9,
	"CORO SIMBIÓTICO":           9,
	"MICELIO OMNISCIENTE":       9,
	"HUÉSPED SOBERANO":          9,
	"MICELIO FRAGMENTADO":       3,
	"FUSION CATABOLICA":         9,
	"AYUNO PRIMORDIAL":          8,
	"INESTABILIDAD CONSCIENTE":  9,
}

# ── Caps de bonus NG+ por ruta ───────────────────────────────────
# PL adicional máximo que puede ganar la fórmula variable en NG+.
const NG_CAPS: Dictionary = {
	"HOMEOSTASIS":               6,
	"SIMBIOSIS":                 6,
	"MUTUALISMO":                6,
	"HOLOBIONTE":                8,
	"ENDOSIMBIOSIS":             8,
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
	"AUTOFAGIA NECRÓTICA":        8,
	"NECROSIS CONTROLADA":       8,
	"PROTOCOLO OMEGA-CERO":      12,
	"REMISIÓN METABÓLICA":       12,
	"POLIMORFÍA TOTAL":          8,
	"POLIMORFIA TOTAL":          8,
	"DOMADOR DEL CAOS":          8,
	"ASCESIS_PROFUNDA":          6,
	"MENTE COLMENA DISTRIBUIDA": 8,
	"DEPREDADOR DE REALIDADES":  8,
	"COLAPSO DEPREDATORIO":      5,
	"PANSPERMIA NEGRA":          6,
	"FUSIÓN CATABÓLICA":         8,
	"CAOS ORQUESTADO":           8,
	"CORO SIMBIÓTICO":           8,
	"MICELIO OMNISCIENTE":       8,
	"HUÉSPED SOBERANO":          8,
	"MICELIO FRAGMENTADO":       3,
	"FUSION CATABOLICA":         8,
	"AYUNO PRIMORDIAL":          8,
	"INESTABILIDAD CONSCIENTE":  8,
}
