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

## A2 — Perfil "más rápido" por final (pendiente)

25 finales distintos en el código. Estado del bot:

| Final | Perfil | Notas |
|---|---|---|
| HIPERASIMILACIÓN | ✅ `fresh_hiper` | 180 s |
| PARASITISMO | ✅ `fresh_buy_all`, `fresh_idle` | 200–420 s |
| FUSIÓN CATABÓLICA | ✅ `ng_fusion_natural` | ~18 min desde la activación |
| AYUNO PRIMORDIAL | ⚠️ `ng_ayuno_player` termina en PARASITISMO a 230 s | revisar perfil |
| HOMEOSTASIS | ⚠️ `fresh_homeostasis` no cierra en 40 min | revisar perfil / ruta |
| ESPORULACIÓN | ⚠️ `fresh_red_micelial` termina en PARASITISMO | revisar perfil / ruta |
| SIMBIOSIS · ALLOSTASIS · HOMEORHESIS | ❌ | el bot ya sabe elegir Homeostasis/Simbiosis/Alostasis |
| PANSPERMIA NEGRA · SINGULARIDAD · MENTE COLMENA | ❌ | requieren legado previo (ESCLEROCIO, SINGULARIDAD) |
| COLAPSO DEPREDATORIO · DEPREDADOR DE REALIDADES · METABOLISMO OSCURO | ❌ | bot no sabe Depredador |
| ESCLEROCIO · AUTOFAGIA · NECROSIS · OMEGA-CERO · COLAPSO SINTÉTICO · REMISIÓN | ❌ | bot no sabe árbol oscuro |
| ASCESIS · DOMADOR · POLIMORFÍA · (REENCARNACIÓN) | ❌ | bot no sabe rutas post-trascendencia |
| COLAPSO CONTROLADO | ❌ | requiere buff cósmico |

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
