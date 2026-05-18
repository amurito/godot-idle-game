# Roadmap post-v1.0.0.3

Última actualización: 2026-05-17

---

## v1.0.0.5 – Pulido y calidad de vida

### Estado corregido

| Feature | Estado real |
|---------|-------------|
| Consolidar versión (`Version.get_version_string()`) | ✅ Hecho — v1.0.0.3 |
| Auditar hot-patches (código muerto, flags obsoletos) | ✅ Hecho — v1.0.0.3 |
| `Balance.gd` autoload (timers, PL_REWARDS, NG_CAPS) | ✅ Hecho — v1.0.0.3 |
| Cap de laps en LogManager (`Balance.MAX_LAPS = 200`) | ✅ Hecho — v1.0.0.4 |
| Tabla de PL por ruta → `Balance.PL_REWARDS` dict | ✅ Hecho — v1.0.0.4 |
| save_version + `_migrate()` unificado en SaveManager | ✅ Hecho — v1.0.0.4 |
| Extraer rutas NG+ (Depredador/MetOscuro/Carnaval/Reenc/Vacío) | ✅ Ya estaba — RunManager + EvoManager |
| Aviso cuenta regresiva "Serás consumido" | 🔜 Hotfix A |
| Buff cósmico "Memoria de Recurso Cósmica" | 🔜 Hotfix B |
| Sugerencia contextual avanzada (50s hint → 60s push) | 🔜 Hotfix C |
| Localización ES/EN completar | 🔜 Hotfix D (WIP) |

La v1.1 técnica está **cerrada**. Lo pendiente son 3-4 features de contenido/UX menores, tratados como hotfixes.

---

## Hotfixes Pendientes (v1.0.0.5)

### Hotfix A — Countdown "Serás consumido"

**Objetivo:** mostrar cuenta regresiva visual 10-9-8… en los últimos 10s antes de que se active el Depredador o Metabolismo Oscuro.

**Análisis del código:**
- `EvoManager.gd`: `depredador_timer` va de 0→30s (threshold 30s). Ya hay un toast de progreso en `process_depredador_progress()` cada 10s.
- `EvoManager.gd`: `met_oscuro_timer` va de 0→`Balance.MET_OSCURO_REQUIRED_TIME` (≈15s).
- El toast actual es solo texto en el log. Falta un overlay dramático en la UI.

**Implementación:**

1. **`EvoManager.gd`** — agregar señal y emisión:
   ```gdscript
   signal activation_countdown(seconds_left: int, event_id: String)
   
   # En _update_depredador(): cuando timer > threshold - 10.0
   var secs_left := int(threshold - depredador_timer)
   if secs_left <= 10 and secs_left >= 0:
       emit_signal("activation_countdown", secs_left, "DEPREDADOR")
   
   # En _update_met_oscuro(): análogo con met_oscuro_timer
   ```

2. **`UIManager.gd`** — función `show_countdown_overlay(n: int, label: String)`:
   - Label grande centrado, color rojo, fuente grande
   - Se auto-destruye si n == 0 o si el timer se resetea
   - No bloquea interacción (CanvasLayer encima)

3. **`main.gd`** — conectar señal en `_ready()`:
   ```gdscript
   EvoManager.activation_countdown.connect(UIManager.show_countdown_overlay)
   ```

**Alcance:** ~30 líneas en EvoManager, ~25 líneas en UIManager, 1 línea en main.gd.

---

### Hotfix B — Buff cósmico "Memoria de Recurso Cósmica"

**Objetivo:** nuevo buff en el Banco Cósmico que hace gratuitas las primeras 2 compras de cada upgrade por run. Sinergia con `memoria_recurso` (legacy buff que da 3 compras gratis).

**Análisis del código:**
- `LegacyManager.gd`: cosmic tiers existentes — T1 (6-15Ξ), T2 (18-28Ξ), T3 (35-50Ξ).
- El buff más parecido es `memoria_persistente` (T2, 22Ξ) que da nivel 1 gratis de Contabilidad y Trueque — implementado en `apply_cosmic_buffs()`.
- `UpgradeManager.gd`: `purchase_upgrade()` es el punto de intercepción para aplicar el descuento.
- `LegacyManager.gd`: `memoria_recurso` legacy buff — verificar su efecto real con `get_buff_value("memoria_recurso")`.

**Implementación:**

1. **`LegacyManager.gd`** — agregar en `COSMIC_UPGRADES`:
   ```gdscript
   "memoria_recurso_cosmica": {
       "cost": 15, "name": "Memoria de Recurso Cósmica",
       "desc": "Las primeras 2 compras de cada upgrade por run son gratuitas. Se acumula con Memoria de Recurso.",
       "tier": 2,
   },
   ```
   > Nota: repensar el cost — 15Ξ ya lo ocupa `eco_de_legado` (T1). Sugerir 20Ξ para que caiga en T2.

2. **`UpgradeManager.gd`** — trackear compras gratuitas en `purchase_upgrade()`:
   ```gdscript
   var _free_purchases: Dictionary = {}  # upgrade_id → int (compras gratis usadas)
   
   func _get_free_purchases_left(id: String) -> int:
       var cap := 0
       if LegacyManager.has_cosmic_buff("memoria_recurso_cosmica"):
           cap += 2
       # Sinergia: memoria_recurso legacy suma más (verificar su efecto actual)
       var used := _free_purchases.get(id, 0)
       return max(0, cap - used)
   ```

3. **Resetear** `_free_purchases = {}` en `reset_for_new_run()` de UpgradeManager.

4. **`SaveManager.gd`** — no necesita cambios (es estado de run, no persistido).

**Alcance:** ~20 líneas en LegacyManager, ~15 líneas en UpgradeManager.

---

### Hotfix C — Sugerencia contextual avanzada

**Objetivo:** sistema de dos fases de idle: a los 50s muestra hint suave, a los 60s si sigue inactivo da un pequeño push ($10 + mensaje).

**Análisis del código:**
- `TutorialManager.gd`: ya existe sistema anti-stuck con `ANTISTUCK_THRESHOLD = 90.0` y `ANTISTUCK_COOLDOWN = 150.0`.
- `_check_antistuck()` y `_build_contextual_hint()` ya implementados.
- `_time_idle` se incrementa cada frame cuando `_step >= 3 or _completed`.

**Implementación:**

1. **`TutorialManager.gd`** — ajustar thresholds y agregar fase push:
   ```gdscript
   const ANTISTUCK_THRESHOLD := 50.0   # era 90s — primera fase: hint suave
   const ANTISTUCK_PUSH      := 60.0   # segunda fase: $10 + mensaje
   const ANTISTUCK_COOLDOWN  := 150.0  # sin cambio
   
   var _push_given: bool = false
   
   # En _process():
   if _time_idle >= ANTISTUCK_PUSH and not _push_given and _antistuck_cooldown <= 0.0:
       _give_idle_push()
   ```

2. **`_give_idle_push()`** — nueva función:
   ```gdscript
   func _give_idle_push() -> void:
       _push_given = true
       var gift := 10.0 * max(1.0, EconomyManager.get_passive_total())
       EconomyManager.money += gift
       _show_antistuck_hint("El sistema detecta inactividad.\n+$%.0f de impulso." % gift)
   ```
   > El regalo escala con el pasivo actual para no ser trivial en endgame ni roto en early.

3. **Resetear** `_push_given = false` en `notify_any_action()` (cuando el jugador hace algo).

**Alcance:** ~15 líneas en TutorialManager. Cero cambios en otros archivos.

---

### Hotfix D — Localización ES/EN (WIP)

Sin plan detallado aún — depende de qué strings quedan sin cubrir. Ver `project_localization.md` para el estado actual. Baja prioridad hasta que se decida si EN es objetivo real de release.

---

## Siguiente versión real: v1.0.0.5

Una vez aplicados los hotfixes, v1.0.0.5 arranca limpia con el contenido de las **mutaciones revertidas** (5 rutas, ver IDEAS DE ROADMAPS FUTUROS.md § v1.2).
