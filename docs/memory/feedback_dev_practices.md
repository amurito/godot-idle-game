---
name: Dev practices and lessons learned
description: Prácticas aprendidas durante el desarrollo de HYPHAE: genesis — worktrees, cost vs display, GDScript quirks
type: feedback
originSessionId: 554b9b8e-33ea-46f2-85ae-400b8aa51329
---
## Usar funciones manager, no datos raw
Siempre usar `UpgradeManager.cost(id)` en lugar de `state.current_cost`.
**Why:** `state.current_cost` bypasea la lógica de descuentos (deflacion, memoria_estructural, presion_rentable, legado_ciclo, memoria_recurso).
**How to apply:** Cualquier lugar que muestre o cobre el precio de un upgrade debe pasar por `UpgradeManager.cost()`.

## Separar display_cost de actual_cost
Cuando hay casos especiales (como memoria_recurso), display y costo real son diferentes.
**Why:** memoria_recurso muestra el precio real con "(GRATIS)" pero no cobra nada. El botón se deshabilita hasta tener el dinero mostrado.
**How to apply:** display_cost = lo que ve el jugador; actual_cost = lo que se cobra. Affordability usa display_cost.

## Type hints explícitos en variables complejas
Usar `var is_free: bool = (condition)` en lugar de `var is_free := (condition)`.
**Why:** Type inference puede fallar en GDScript con condiciones complejas.
**How to apply:** Siempre que la variable sea bool y la condición sea larga/compleja.

## No usar multi-line con backslash en GDScript
Evitar `var x := (cond1 \\\n    and cond2)`. Poner todo en una línea o usar variable intermedia.
**Why:** Causa errores de parsing en GDScript.

## Actualizar SaveManager al agregar campos persistentes
Cualquier campo nuevo debe agregarse a serialize/deserialize en SaveManager.
**Why:** Sin esto el campo no persiste entre reloads.
**How to apply:** Después de agregar un campo nuevo, inmediatamente buscar en SaveManager dónde va el bloque correspondiente.

## Un solo branch/worktree activo durante desarrollo
No cambiar de branch/worktree entre cambios relacionados.
**Why:** Causa pérdida de contexto y duplicación de trabajo entre sesiones.

## Reemplazar emojis en UI con texto plano
Usar "OK/FALLA", "X/." en lugar de "⚫✓✗".
**Why:** Los emojis causan rendering issues en Godot.

## custom_minimum_size no fuerza el tamaño real del panel
Para forzar tamaño de un panel flotante usar `panel.size = ...` y `panel.position = ...` además de `custom_minimum_size`.
**Why:** `custom_minimum_size` solo fija el mínimo; si el panel tiene anchors fijos en el .tscn, el layout engine los respeta primero.
**How to apply:** Para paneles que se redimensionan en runtime, asignar size y position directamente. Para paneles que siempre deben llenar su parent, corregir los anchors en el .tscn (anchors_preset = 15 + offsets).

## El VBoxContainer interno puede limitar el ancho aunque el padre sea full-screen
Si un ColorRect/Panel llena la pantalla pero su VBoxContainer hijo tiene `anchor_left = 0.5`, el contenido queda centrado y estrecho.
**Why:** Godot respeta los anchors del hijo, no los del padre.
**How to apply:** Cuando el contenido no llena el panel, revisar los anchors del primer hijo contenedor en el .tscn.

## Stash antes de mergear si hay cambios locales no commiteados
El main worktree a veces tiene cambios del editor de Godot (UIDs, reorden de propiedades).
**Why:** `git merge` falla si hay cambios locales en archivos que el merge toca.
**How to apply:** `git stash && git merge ... && git stash pop`. Si hay conflictos post-stash pop, resolverlos manualmente.

## RichTextLabel dentro de ScrollContainer requiere fit_content = true
Sin `fit_content = true`, el RichTextLabel colapsa a altura 0 y el contenido no se ve.
**Why:** El ScrollContainer no le da altura al hijo — el hijo debe autodimensionarse con fit_content.
**How to apply:** Siempre que haya un RichTextLabel (logros, banco, etc.) dentro de un ScrollContainer, agregar `fit_content = true` en el .tscn.

## AchievementManager: threshold y sustained no soportan conditions
Solo los triggers `event` y `event_count` soportan el array `"conditions"`.
**Why:** `_eval_thresholds()` y `_eval_sustained()` solo leen métricas del snapshot, no condiciones extra.
**How to apply:** Si un logro necesita "X métrica + Y condición externa", usar trigger `"custom"` con evaluador que lea ambos directamente (ej: `EvoManager.mutation_parasitism and s.get("biomasa") >= 20`).

## Agregar evaluadores custom al CUSTOM_EVALUATORS dict Y al CUSTOM_TIMER_IDS
Al crear un custom evaluator con duración (timer), hay que registrarlo en DOS lugares.
**Why:** `_eval_custom_one_shot()` solo ejecuta los sin duration; `_eval_custom_timers()` solo ejecuta los listados en CUSTOM_TIMER_IDS.
**How to apply:** Nuevo logro custom con `"duration"` → agregarlo a CUSTOM_EVALUATORS (función) Y a CUSTOM_TIMER_IDS (const array).

## Meta-achievements necesitan registrarse en _check_meta_achievements
Logros que dependen de otros logros o del estado global (legado_absoluto, reino_subterraneo, etc.) no se disparan solos.
**Why:** Solo se evalúan cuando se llama a `_check_meta_achievements()`, que se llama al final de `unlock()`.
**How to apply:** Todo logro cuya condición sea "tener X logros" o "tener todos los buffs" debe agregarse en `_check_meta_achievements()`.

## Omega floor puede ser sobreescrito por el logic tick si hay doble cálculo
`update_epsilon_runtime()` aplica floors correctamente, pero si el paso 8 del tick recalcula omega desde epsilon_effective sin re-aplicar floors, el valor baja igual.
**Why:** Dos lugares calculan omega independientemente; el segundo sobreescribe al primero.
**How to apply:** Después de cualquier recalculo de omega en el logic tick, re-aplicar los floors activos (omega_min, allostasis, legado_alostasis, legado_homeorresis).

## on_run_closed payload no incluye todos los campos por defecto
Campos como `biomasa` o `reencarnacion_active` no están en el payload inicial de on_run_closed.
**Why:** El payload se construye manualmente en `AchievementManager.on_run_closed()`.
**How to apply:** Cuando se propone un logro de tipo `event: run_closed` con condición sobre un campo nuevo, verificar que ese campo esté en el payload y agregarlo si no está.
