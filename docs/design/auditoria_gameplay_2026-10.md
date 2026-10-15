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
| PANSPERMIA NEGRA · SINGULARIDAD · MENTE COLMENA | ❌ | | paso 2 |
| COLAPSO DEPREDATORIO · DEPREDADOR DE REALIDADES · METABOLISMO OSCURO | ❌ | | paso 3 |
| ESCLEROCIO · AUTOFAGIA · NECROSIS · OMEGA-CERO · COLAPSO SINTÉTICO · REMISIÓN | ❌ | | paso 4 |
| ASCESIS · DOMADOR · POLIMORFÍA · (REENCARNACIÓN) · COLAPSO CONTROLADO | ❌ | | paso 5 |

### Hallazgos de A2
| # | Hallazgo | Estado |
|---|---|---|
| G5 | "Romper el Ayuno" tras >120 s sin clickear dispara la Trampa del Vacío al instante (la ráfaga suma +5 de biomasa). Es el diseño, y el panel avisa desde los 100 s; la cuenta regresiva de Parasitismo no aparece porque en Ayuno la biomasa está en ~0 | sin cambio (aviso existente) |
| G6 | El panel de Ayuno tiene textos fijos en español (no pasan por `tr()`) | pendiente (localización) |
| G7 | Huésped Soberano podía activarse sobre un Ayuno (Trampa del Vacío) y dejar las dos rutas vivas | ✅ `41898d4` |

Orden de trabajo propuesto (por dependencia de mecánicas del bot):
1. T0/Tier 2 (Homeostasis, Simbiosis, Alostasis, Homeorresis) + arreglar perfiles ⚠️.
2. Rama verde/azul (Esporulación → Panspermia Negra; Singularidad → Mente Colmena).
3. Depredador y sus 3 salidas.
4. Árbol oscuro (5 sub-rutas + Colapso Sintético).
5. Post-trascendencia (Vacío/Ascesis, Carnaval ×2, Reencarnación) + Colapso Controlado.

Cada perfil: `Scenarios.gd` con legado mínimo necesario + acciones del bot por el mismo camino de
código que la UI; se registra el tiempo mínimo, y los finales sin trayectoria golden ganan una.

## A3 — Logros difíciles (pendiente)
Un escenario por MYTHIC/ANCESTRAL/secreto con condición propia (ayuno_perfecto, autolisis_perfecta,
funcion_pura, singularidad_perfecta, esclerocio_contingencia, coloso_estructural, trampa_del_vacio,
…), o justificación de por qué no es simulable.
