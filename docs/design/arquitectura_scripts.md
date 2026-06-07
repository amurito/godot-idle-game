# Arquitectura de scripts — HYPHAE: genesis

Última actualización: 2026-06-07 (post-refactor steps 6–9, v1.0.1)

---

## Dos tipos de objetos GDScript

### Autoloads (`extends Node`)
- Tienen **estado mutable** (`var` persistentes entre frames).
- Registrados en `project.godot` → accesibles como singletons desde cualquier script.
- Tienen `_ready()`, señales, pueden conectarse a eventos.
- Acceso: `ManagerName.method()` o `ManagerName.variable` directamente.

### `class_name` estáticos (sin `extends`, sin autoload)
- **Cero estado** — solo `static func` y `const`.
- Godot los registra automáticamente por `class_name`; no van en project.godot.
- No tienen instancia ni `self`. Para acceder a otro autoload, se usa el nombre explícito: `EvoManager.primordio_active`.
- Dentro de la misma clase, las static funcs se llaman sin prefijo: `_begin_primordio_biological()`.
- Acceso: `ClassName.method()` desde cualquier parte.

---

## Inventario de archivos (line counts post-refactor)

### Autoloads — coordinación y estado

| Archivo | LOC | Rol |
|---|---|---|
| `main.gd` | 1214 | Orquestador de escena: loop `_process`, input, conecta managers en `_ready`. **No contiene sistemas.** |
| `UIManager.gd` | 1266 | Toda la UI runtime: toasts, paneles, labels, botones NG+, reactor color, legacy store |
| `EvoManager.gd` | 494 | Estado de mutaciones y genome (flags, timers, fases). Delega lógica a GenomeEvaluator/PrimordioLogic |
| `StructuralModel.gd` | 312 | ε/ω/persistence math. `update_runtime()` calcula ε cada tick |
| `RunManager.gd` | 678 | Tiempo de run, `close_run()`, `LOGIC_TICK`, historial de ciclos |
| `EconomyManager.gd` | 303 | `money`, `delta`, income acumulado |
| `BiosphereEngine.gd` | 208 | `micelio`, `biomasa`, `hifas`, `nutrientes`, sporulation |
| `LegacyManager.gd` | 925 | Buffs, legacy_points, trascendencia, save/load banco, rutas post-tras |
| `AchievementManager.gd` | 763 | Unlock de logros, evaluadores custom, toasts de logros |
| `UpgradeManager.gd` | 324 | Niveles de upgrades, precios, compra |
| `SaveManager.gd` | 555 | Save/load de slots (3 slots + autosave) |
| `SlotManager.gd` | 283 | Selección de slot, autobackup, `reload_for_slot()` |
| `AudioManager.gd` | 626 | SFX + panel de settings de audio |
| `RouteManager.gd` | 226 | Rutas post-trascendencia; `ROUTE_DEFS`; `get_selectable_routes()` |
| `LogManager.gd` | 210 | Log de run (texto), toggle compact/expanded |
| `TutorialManager.gd` | 1032 | Pasos de tutorial, condiciones de avance |
| `LocaleManager.gd` | 2512 | i18n ES/EN, `tr()` wrapper |
| `TelemetryManager.gd` | 357 | Eventos opt-in, post al hub en `close_run` |
| `AccessibilityManager.gd` | 138 | Font size, contraste, daltonismo |

### `class_name` estáticos — lógica pura y datos

| Archivo | LOC | Rol |
|---|---|---|
| `GenomeEvaluator.gd` | 310 | Toda la lógica de evaluación del genoma (llamada desde `EvoManager.update_genome()`) |
| `PrimordioLogic.gd` | 245 | Ciclo biológico: Primordio, Panspermia Negra, Colonización activa |
| `UITextBuilders.gd` | 983 | Constructores de texto para HUD: fórmula, click stats, genome panel |
| `AchievementDefs.gd` | 532 | `enum Tier` + `TIER_NAMES/COLORS/ICONS` + `DEFS` (50 logros) |
| `LegacyDefs.gd` | 383 | `LEGACY_DEFS` (40 buffs) + `CAT_ORDER`/`CAT_NAMES` |
| `Balance.gd` | 182 | Constantes de balance del juego (autoload, pero es solo consts) |
| `EcoModel.gd` | 62 | Helpers de fórmula económica |
| `RunSnapshot.gd` | 175 | Estructura de snapshot de run (para evaluadores de logros) |
| `EmojiToRichText.gd` | 124 | Emoji → BBCode/textura (sistema Twemoji) |

### Scripts de escena (attachados a nodos)

| Archivo | LOC | Rol |
|---|---|---|
| `MainMenu.gd` | 1559 | Menú principal, panel de logros, settings |
| `DebugPanel.gd` | 232 | Overlay de debug (excluido del export) |
| `Reactor3D.gd` | 210 | Visual 3D del reactor (SubViewport) |
| `ReactorVisual.gd` | 203 | Visual 2D del reactor (partículas ADD, zoom) |
| `UpgradeButton.gd` | 188 | Botón de upgrade con auto-resolve de `upgrade_id` |
| `fungi_ui.gd` | 148 | Barra del ciclo fúngico |
| `Reactor3DContainer.gd` | 31 | Viewport container para el 3D |
| `producer_item.gd` | 27 | Item de productor en UI |
| `big_click_button.gd` | 13 | Botón de click principal |
| `version.gd` | 36 | Constante de versión |

### Rutas post-trascendencia (`routes/`)

| Archivo | Rol |
|---|---|
| `routes/PostTrasRoute.gd` | Base class (`class_name PostTrasRoute extends RefCounted`): `activate`, `tick`, `production_mult`, `serialize`/`deserialize` |
| `routes/RouteVacio.gd` | Vacío Hambriento |
| `routes/RouteCarnaval.gd` | Carnaval (rotación de mutaciones) |
| `routes/RouteReencarnacion.gd` | Reencarnación Heredada (snapshot de upgrades) |

---

## Dónde poner código nuevo

| Si necesitás agregar... | Lo ponés en... | Notas |
|---|---|---|
| Nueva mutación del genoma (lógica de evaluación) | `GenomeEvaluator.gd` — nuevo `static func update_X(ctx: Dictionary)` | Registrarlo en `EvoManager.update_genome()` también |
| Nuevo flag/estado de mutación | `EvoManager.gd` — nueva `var` | El estado vive acá; la lógica en GenomeEvaluator |
| Nueva mecánica de Primordio/Panspermia/Colonización | `PrimordioLogic.gd` | Agregar thin delegate en EvoManager si hay callers externos |
| Nuevo logro | `AchievementDefs.gd` — nueva entrada en `DEFS` | Tipo `threshold`, `event`, `event_count`, o `custom` |
| Nuevo evaluador custom de logro | `AchievementManager.gd` — nuevo `_eval_X()` + registrar en `CUSTOM_EVALUATORS` | |
| Nuevo buff de legado | `LegacyDefs.gd` — nueva entrada en `LEGACY_DEFS` | Categoría en `cat:`, `effect.type` debe ser manejado en `get_effect_value()` |
| Nueva constante de balance | `Balance.gd` | Usar `const` con nombre `UPPER_CASE` |
| Nuevo panel de UI o label | `UIManager.gd` | Onready vars en `setup()`, funciones de update separadas |
| Nuevo constructor de texto para HUD | `UITextBuilders.gd` | `static func`, accede a autoloads por nombre explícito |
| Nueva ruta post-trascendencia | `routes/RouteX.gd` + registrar en `RouteManager.ROUTE_DEFS` | Extender `PostTrasRoute` |
| Nueva métrica estructural (derivada de ε/ω) | `StructuralModel.gd` | Dentro de `update_runtime()` o nueva func |
| Nuevo efecto de economía | `EconomyManager.gd` | |
| Nueva mecánica de biosfera | `BiosphereEngine.gd` | |
| Nuevo evento de telemetría | `TelemetryManager.gd` | |

---

## Patrones establecidos

### Thin delegate (para mantener callers externos sin cambios)

Cuando se extrae lógica de un autoload que tiene muchos callers externos, se deja un wrapper 1-liner en el autoload original:

```gdscript
# EvoManager.gd
func update_primordio(m: Node) -> void: PrimordioLogic.update_primordio(m)
func primordio_regar() -> void: PrimordioLogic.primordio_regar()
```

Los callers en `main.gd`, `UIManager.gd`, etc. no necesitan cambios.

### Alias const (para mover datos fuera de autoloads con callers externos)

Cuando se extrae un dict/enum de un autoload que es referenciado externamente como `Autoload.CONST`:

```gdscript
# AchievementManager.gd — main.gd y MainMenu.gd usan AchievementManager.Tier.* sin cambios
const Tier        = AchievementDefs.Tier
const TIER_NAMES  = AchievementDefs.TIER_NAMES
const DEFS        = AchievementDefs.DEFS
```

### Context dict en evaluadores

`GenomeEvaluator.build_eval_context()` devuelve un `Dictionary` con todos los valores del tick (snapshot de autoloads) para pasarlos a cada `update_X(ctx)`. Esto evita que cada evaluador acceda individualmente a múltiples autoloads para los mismos valores.

### Codificación UTF-8 en scripts Python de edición

Los archivos `.gd` contienen caracteres especiales (`∂`, `é`, `─`, `═`). Siempre usar:
```python
open(path, 'r', encoding='utf-8')
open(path, 'w', encoding='utf-8')
```
El Edit tool del CLI puede corromper estos chars. Preferir Python para ediciones que involucren esas líneas.

---

## Orden de autoloads en project.godot

Orden real verificado (v1.0.1, crítico — Balance debe ir último):

```
Version → SlotManager → LegacyManager → SaveManager → EcoModel → BiosphereEngine →
EvoManager → UIManager → LogManager → UpgradeManager → AchievementManager → RunManager →
RouteManager → EconomyManager → StructuralModel → EmojiToRichText → AccessibilityManager →
AudioManager → TutorialManager → TelemetryManager → LocaleManager → Balance
```

`Balance` siempre al final porque sus constantes son usadas en los `_ready()` de otros managers.
`RouteManager` después de `RunManager` (depende de RunManager en init).
