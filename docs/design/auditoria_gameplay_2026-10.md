# Auditoría de gameplay (v1.1 · Fase A)

Iniciada 2026-10-12. Objetivo: que **cada final y cada logro sea alcanzable jugando** (no vía
DebugPanel) y que el simulador tenga, para cada ruta, el **camino más rápido** para cerrarla.
Plan general en [`roadmap_v1.1_en_adelante.md`](../roadmaps/roadmap_v1.1_en_adelante.md).

## A1 — Auditoría estática de los 81 logros ✅

Script de referencias cruzadas (disparador → quién lo emite/evalúa) sobre todo el código:

| Chequeo | Resultado |
|---|---|
| Logros `event` / `event_count` cuyo evento nunca se emite | **0** (14 eventos emitidos, todos usados) |
| Logros `threshold` / `sustained*` cuya métrica no está en el snapshot | **0** |
| Logros `custom` sin evaluador registrado ni `unlock("id")` directo | **0** (26 evaluadores + 20 unlocks directos) |
| Condiciones de evento con claves ausentes del payload | **0** (payload de `run_closed` revisado clave por clave) |
| Rutas en condiciones que no coinciden con los textos de `close_run` (tildes) | **0** |
| Logros que leen estado de la run en `on_run_closed` después de que se limpia | **0** (`on_run_closed` se llama al principio de `close_run`) |

**Conclusión:** el cableado es correcto en los 81. Lo que falta probar es la **factibilidad**
(que las condiciones se puedan cumplir a la vez dentro de una run real) → A2/A3 con el bot.

Señal del banco del autor: 79/81 obtenidos (pero el DebugPanel también desbloquea, así que no prueba
alcanzabilidad). Faltan:
- `ayuno_perfecto` (MYTHIC): cerrar Ayuno con racha limpia ≥ 180 s **y** ≥ 7 ciclos. Tensión real:
  romper el ayuno (ciclo) corta la racha → hay que hacer la racha larga primero. Verificar con bot.
- `trampa_del_vacio` (ANCESTRAL, secreto): alcanzable desde `074c7c7`; verificar con bot.

### Hallazgos de A1
| # | Hallazgo | Estado |
|---|---|---|
| G1 | Fusión y Ayuno podían estar activas a la vez y el checklist no decía cuál se disparaba | ✅ `9a3c473` |
| G2 | `COLAPSO SINTÉTICO` (Omega-Cero por inanición) da 0 PL base (`PL_REWARDS.get(route, 0)`) | **confirmar intención** (¿fracaso sin premio?) |
| G3 | `SINGULARIDAD` no está en `PL_REWARDS`: OK, otorga 6 + bonus ε antes de `close_run` | ✅ sin cambio |
| G4 | La regla de Escalado Alostático vivía en el tick de UI | ✅ `40451d9` |

## A2 — Perfil "más rápido" por final (en curso, retomada 2026-10-15)

Finales con perfil de bot que cierra jugando (tiempos = segundos de run, semilla 1337):

| Final | Perfil | Cierra a | Notas |
|---|---|---:|---|
| HIPERASIMILACIÓN | `fresh_hiper` | 180 s | |
| PARASITISMO | `fresh_idle` · `fresh_buy_all` | 200 · 421 s | inactividad · Masa Crítica |
| SIMBIOSIS | `fresh_simbiosis` | 427 s | |
| HOMEOSTASIS | `fresh_homeostasis` | **603 s** | ✅ el bot no apretaba "SELLAR FINAL" (opción `evo_seal`) |
| ALLOSTASIS | `t1_allostasis` (T1 tras Homeostasis) | **1282 s** | ✅ nuevo |
| HOMEORHESIS | `t2_homeorhesis` (T2 tras Allostasis) | **1399 s** | ✅ nuevo |
| ESPORULACIÓN | `fresh_red_micelial` | **714 s** | ✅ perfil roto (nunca llegaba a Red Micelial) + el bot aprendió la rama verde (`green`: empujar frontera, Primordio, Regar, final) |
| AYUNO PRIMORDIAL | `ng_ayuno_player` | **500 s** (320 desde el ayuno) | ✅ caía en la Trampa del Vacío: rompía el ayuno tras >120 s sin clickear (`ayuno_safe_burst`) y nunca juntaba la racha de 180 s (`ayuno_streak_first`) |
| PARASITISMO (Trampa del Vacío) | `ng_ayuno_trap_huesped` | 242 s | romper el ayuno sin clickear antes |
| FUSIÓN CATABÓLICA | `ng_fusion_natural` | 1176 s | `ng_fusion_player` (golden) no sella: tope de pasivo 15 % toda la run — es a propósito |
| CAOS · CORO · MICELIO · HUÉSPED | `ng_*_player` | 1297 · 874 · 1619 · 867 s | perfiles de la calibración R3–R6 |
| PANSPERMIA NEGRA | `t1_panspermia` (T1 tras Esporulación) | **886 s** | ✅ bot `green` + eyección sin sobrecalentar; ahorra ~25 eyecciones ($300K) antes de lanzar |
| SINGULARIDAD | `fresh_singularidad` (rama Simbiosis) | **1461 s** | ✅ termostato de ε (`eps_band`) + `blue_seal` |
| MENTE COLMENA DISTRIBUIDA | `t1_mente_colmena` | **949 s** | ✅ tras el arreglo de G8 (el equilibrio se mide sin los multiplicadores de Red Micelial) |
| COLAPSO DEPREDATORIO | `t2_depredador` (T2 tras Parasitismo) | **285 s** | ✅ Hiper frenética → Depredador (215 s) y dejarlo correr |
| METABOLISMO OSCURO | `t2_met_oscuro` | **246 s** | ✅ en el Depredador deja de clickear y gasta todo (< $1000); `mo_seal_bio` |
| DEPREDADOR DE REALIDADES | `t2_depredador_realidades` | **287 s** | ✅ llega con ~40 niveles (sólo click + Trabajo Manual) y no recompra |
| ESCLEROCIO OSCURO | `t3_esclerocio` | **241 s** | ✅ bot `dark`: 30 devorados en el Depredador, "Comprar tiempo" con biomasa para bajar de $1000, ε < 0.25 |
| AUTOFAGIA NECRÓTICA | `t3_autofagia` | **860 s** | ✅ compra velocidad/doble y no recompra hasta que se come todo |
| NECROSIS CONTROLADA | `t2_necrosis` · `t3_necrosis` | **585 · 534 s** | ✅ clickea para generar Necromasa, agentes con toxicidad < 55 %, depura; en T3 tras el arreglo de G11 |
| PROTOCOLO OMEGA-CERO | `t3_omega_cero` | **316 s** | ✅ recompra para realimentar el loop y sella con Φ ≥ 300 |
| COLAPSO SINTÉTICO | `t3_colapso_sintetico` | **268 s** | ✅ Omega-Cero sin recomprar: inanición |
| REMISIÓN METABÓLICA | `t3_remision` | **286 s** | ✅ sigue el centro de la banda con ± y sella |
| ASCESIS PROFUNDA | `t1_ascesis` (ruta Vacío) | **623 s** | ✅ sólo clicks, termostato ε < 0.22, ahorra $10M |
| DOMADOR DEL CAOS | `t1_domador` (ruta Carnaval) | **540 s** | ✅ invierte 6.5 min y ahorra hasta $1M de pico |
| POLIMORFÍA TOTAL | `t1_polimorfia` (ruta Carnaval) | **720 s** | ✅ gasta todo para no pasar de $1M y ahorra desde la rotación 11 |
| COLAPSO CONTROLADO | `t3_colapso_controlado` (cósmico Fractura) | **260 s** | ✅ frena ε < 0.35 hasta biomasa 5.6 antes de Hiper (G13) y sostiene ε 0.91–0.94 |
| (Reencarnación Heredada) | `a3_reencarnacion` | — | no tiene final propio: es una ruta que arranca con los niveles del ciclo anterior |

### Hallazgos de A2
| # | Hallazgo | Estado |
|---|---|---|
| G5 | "Romper el Ayuno" tras >120 s sin clickear dispara la Trampa del Vacío al instante (la ráfaga suma +5 de biomasa). Es el diseño, y el panel avisa desde los 100 s; la cuenta regresiva de Parasitismo no aparece porque en Ayuno la biomasa está en ~0 | sin cambio (aviso existente) |
| G6 | El panel de Ayuno tiene textos fijos en español (no pasan por `tr()`) | pendiente (localización) |
| G7 | Huésped Soberano podía activarse sobre un Ayuno (Trampa del Vacío) y dejar las dos rutas vivas | ✅ `41898d4` |
| G8 | ✅ **(opción A del autor)** **Mente Colmena era prácticamente inalcanzable.** El portal pide activo/pasivo 50 % ± 3 durante 100 s, pero se juega con Red Micelial activa (click ×0.5, pasivo ×2.5) y Red Micelial sólo se activa con el pasivo ya dominante. Comprando sólo upgrades de click, el activo sube de 24 % a 44 % en 2.5 h | ✅ el portal mide el equilibrio sin los multiplicadores de Red Micelial → 949 s |
| G9 | Sello de Metabolismo Oscuro: los escalones de PL por biomasa estaban invertidos (< 50 daba 4 y 50–100 daba 2; el botón prometía 2 y 4) | ✅ |
| G10 | Panspermia: al ritmo que permite el calor, la carga sube neto ~+2/s → un lanzamiento cuesta ~21 eyecciones (~$250K) y el juego no lo dice; el jugador lo descubre fallando | ✅ la barra de Panspermia muestra "lanzamiento ≈ N eyecciones ($X)" (`PrimordioLogic.panspermia_launch_estimate`, simula el ritmo máximo que permite el calor) |
| G11 | En T3+ la economía del Depredador es grande: la plata no baja de $1000 sólo gastando (el "vuelto" de la compra más barata ya supera $1000). Se entra a Met. Oscuro con **Comprar tiempo** (biomasa): el Depredador devora más y la economía se achica. Pero así se llega a MO con Δ ≈ $130/s y **Necrosis pide Δ ≥ $200/s** dentro de MO (donde no se puede comprar). En T2 se llega a MO con la economía viva y Necrosis entra | ✅ **(decisión del autor)** el requisito se mide con el Δ$/s al ENTRAR a MO (`met_oscuro_entry_delta`) |
| G12 | Necrosis sólo progresa clickeando (la Necromasa sale de los clicks); el panel lo dice ("sin clicks no hay progreso") | sin cambio |
| G13 | **Colapso Controlado exige entrar a Hiper con biomasa > 5**, pero Hiper se activa sola apenas la biomasa pasa de 4 y, una vez activa, gasta los nutrientes y la biomasa queda congelada. Hay que frenar ε < 0.4 antes de Hiper hasta juntar biomasa; nada en el juego lo sugiere | ✅ se quitó el requisito oculto "biomasa > 5" (`RunManager.is_fractura_epistemica_available`). Textos del Codex y del legado corregidos: decían "Ω > 0.30" (nunca se chequeó; en Hiper Ω queda en 0.30) y ahora dicen ε > 0.90 sostenido 20 s con la run pasados 4 min, y avisan que con ε > 0.95 entra antes el Depredador |
| G14 | **El Dios de las Moscas podía quedar imposible**: su lista dice "ESPORULACION"/"HIPERASIMILACION" sin tilde y el botón de la rama verde cierra como "ESPORULACIÓN"; el registro de finales no normaliza | ✅ la comparación del logro ignora tildes |
| G15 | El simulador no registraba los logros desbloqueados en el arranque (iniciar ruta Vacío/Carnaval/Reencarnación) | ✅ (herramienta) |

Orden de trabajo propuesto (por dependencia de mecánicas del bot):
1. T0/Tier 2 (Homeostasis, Simbiosis, Alostasis, Homeorresis) + arreglar perfiles ⚠️.
2. Rama verde/azul (Esporulación → Panspermia Negra; Singularidad → Mente Colmena).
3. Depredador y sus 3 salidas.
4. Árbol oscuro (5 sub-rutas + Colapso Sintético).
5. Post-trascendencia (Vacío/Ascesis, Carnaval ×2, Reencarnación) + Colapso Controlado.

Cada perfil: `Scenarios.gd` con legado mínimo necesario + acciones del bot por el mismo camino de
código que la UI; se registra el tiempo mínimo, y los finales sin trayectoria golden ganan una.

## A3 — Logros difíciles ✅ (2026-10-16)

Se corrieron todos los escenarios (≈ 60) y se cruzaron los logros desbloqueados con los 89 definidos.
**85 de 89 salen jugando con algún perfil del bot.** Los 4 restantes son **de cuenta**, no de una run:
Reino Subterráneo, Legado Absoluto, El Dios de las Moscas y Última Espora (todos los logros de un tier, todo el Banco,
todos los finales, todos los logros). Se verificaron sus listas: El Dios de las Moscas tenía el problema de tildes de G14.

Función Pura y Autofagia Perfecta salieron recién después de G16: piden una economía fuerte **dentro** de Met. Oscuro,
y con legado de fin de juego no se podía entrar a MO. Ahora, con legado T6: Función Pura (Necrosis en 7 s) y
Autofagia Perfecta (mejoras al máximo, 1500 s; `a3_*_late`).

Perfiles nuevos de A3 (`tests/sim/Scenarios.gd`, prefijo `a3_`): Coloso Estructural (Fusión sellada con $1.200M, 2669 s),
Ayuno Absoluto (7 ciclos), Singularidad Perfecta (Omega-Cero con Φ ≥ 500 y Ω ≤ 0.01), Reencarnación Consumada,
Maestro del Catalizador, Mano Ligera / Eficiencia Brutal / Sin Tocar (un click cada 110 s; Sin Tocar con legado T6 a los
113 s con 1 click), Escalado Alostático (prioridad de compra) y Economía de Guerra (legado T6, Masa Crítica con $15.5K/s).

### Hallazgos de A3
| # | Hallazgo | Estado |
|---|---|---|
| G16 | **Met. Oscuro choca con una economía grande.** La entrada pide plata < $1000 sostenida 15 s; con legados de ingreso (fin de juego) el ingreso supera $1000/s y no se puede, ni gastando ni comprando tiempo. La salida del jugador es apagar legados de ingreso en el Banco antes de la run (los toggles existen), pero el juego no lo sugiere | ✅ "recursos críticos" = plata < max($1000, 3 s de ingreso) (`DarkTreeLogic.mo_critical_money`, `Balance.MET_OSCURO_CRITICAL_*`); el panel muestra el umbral vigente |
| G17 | La pista "MET.OSCURO DISPONIBLE" y el Codex mostraban requisitos viejos (3 devorados, biomasa 25, < $1k); el juego pide 10 y 50 | ✅ la pista lee las constantes de Balance; Codex corregido |

