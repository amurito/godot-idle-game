# Arquitectura de scripts — HYPHAE: genesis

Última actualización: 2026-06-27 (refactor v1.0.3.0: DarkTreeLogic + NGPlusButtonManager).
Refactor previo: 2026-06-07 (steps 6–9, v1.0.1).

> **Regla de techo: ~600 LOC por archivo.** Cuando un archivo supera ese umbral, evaluar
> extracción *antes* de añadir el siguiente bloque de funcionalidad. Razón doble: legibilidad
> y costo de lectura (un archivo de 1200L cuesta el doble de tokens leer que uno de 600L; si el
> trabajo está en una sola sección, cargar el archivo entero desperdicia contexto). Esta regla
> nació porque `EvoManager.gd` creció a 1225L acumulando árbol oscuro sin extracción planificada.

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
| `UIManager.gd` | 1251 | UI runtime: toasts, paneles, labels, reactor color, legacy store. **Los botones NG+ se delegan a NGPlusButtonManager.** |
| `EvoManager.gd` | 620 | Estado de mutaciones y genome (flags, timers, fases). Delega evaluación a GenomeEvaluator/PrimordioLogic y **el árbol oscuro completo a DarkTreeLogic** |
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
| `SaveSchema.gd` | 300 | **Esquema declarativo del savegame**: única fuente de verdad de qué se persiste y con qué semántica (default, saneamiento, casteo). `SaveManager.build_save_data()`/`apply_save_data()` lo recorren. `validate()` detecta propiedades inexistentes (refactor 2026-10) |
| `PrimordioLogic.gd` | 245 | Ciclo biológico: Primordio, Panspermia Negra, Colonización activa |
| `DarkTreeLogic.gd` | 625 | **Árbol oscuro completo**: met_oscuro, autólisis/autofagia, necrosis, omega_cero, remisión, depredador, glitch. Extraído de EvoManager (2026-06-27). El estado vive en EvoManager; ésta es lógica pura |
| `UITextBuilders.gd` | 1227 | Constructores de texto para HUD: fórmula, click stats, genome panel, checklist evo, paneles de Fusión Catabólica |
| `AchievementDefs.gd` | 532 | `enum Tier` + `TIER_NAMES/COLORS/ICONS` + `DEFS` (50 logros) |
| `LegacyDefs.gd` | 383 | `LEGACY_DEFS` (40 buffs) + `CAT_ORDER`/`CAT_NAMES` |
| `Balance.gd` | 182 | Constantes de balance del juego (autoload, pero es solo consts) |
| `EcoModel.gd` | 62 | Helpers de fórmula económica |
| `RunSnapshot.gd` | 175 | Estructura de snapshot de run (para evaluadores de logros) |
| `EmojiToRichText.gd` | 124 | Emoji → BBCode/textura (sistema Twemoji) |

### Clases instanciadas (`RefCounted` con estado, no autoload)

Tercer tipo de objeto: una clase con `class_name X extends RefCounted` que **sí tiene estado mutable**
pero **no es autoload** — la instancia y posee otro objeto. Se usa cuando la lógica maneja referencias
a nodos de escena (Button, Label, Control) como estado, lo que impide usar una static class.

| Archivo | LOC | Rol | Quién lo instancia |
|---|---|---|---|
| `NGPlusButtonManager.gd` | 1096 | Todos los botones dinámicos de rutas NG+ (árbol oscuro, Fusión Catabólica, simbiosis, dado d20, panel de buffs heredados). Extraído de UIManager (2026-06-27) | `UIManager` en `setup()` vía `_ng_buttons.setup(root, scene)` |

**Por qué RefCounted y no static:** maneja refs a `Button`/`Label`/`Control` como estado interno → una
static class no puede tener estado. **Por qué no autoload:** es un colaborador privado de UIManager, no
un singleton global. UIManager le delega `update_ng_plus_buttons()` / `reset_ng_plus_buttons()`.

> ⚠️ `RefCounted` **no extiende `Node`** → no tiene `tr()`, `create_tween()`, `get_tree()`, etc.
> - `tr("KEY")` → `TranslationServer.translate("KEY")`
> - `create_tween()` → guardar un ref a un `Node` (aquí `_scene`) y usar `_scene.create_tween()`
> - señales de otros autoloads se conectan al método de la instancia: `EvoManager.señal.connect(_ng_buttons._on_x)`

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
| Nuevo campo persistente (save) | `SaveSchema.gd` — UNA línea `_f(...)` en la sección | Campos nuevos: `"default"` literal (saves viejos no lo tienen). Floats: `save_sf` + `load_sf`. Después: `run_golden.ps1` falla como corresponde → re-grabar con `-Mode record` |
| Nueva mecánica de Primordio/Panspermia/Colonización | `PrimordioLogic.gd` | Agregar thin delegate en EvoManager si hay callers externos |
| Nuevo logro | `AchievementDefs.gd` — nueva entrada en `DEFS` | Tipo `threshold`, `event`, `event_count`, o `custom` |
| Nuevo evaluador custom de logro | `AchievementManager.gd` — nuevo `_eval_X()` + registrar en `CUSTOM_EVALUATORS` | |
| Nuevo buff de legado | `LegacyDefs.gd` — nueva entrada en `LEGACY_DEFS` | Categoría en `cat:`, `effect.type` debe ser manejado en `get_effect_value()` |
| Nueva constante de balance | `Balance.gd` | Usar `const` con nombre `UPPER_CASE` |
| Nueva mecánica de árbol oscuro / sub-ruta de colapso | `DarkTreeLogic.gd` — nuevo `static func` | El estado (flags/timers) vive en `EvoManager`; agregar thin delegate ahí |
| Botón dinámico de ruta NG+ (árbol oscuro, SOMBRA, transmutaciones) | `NGPlusButtonManager.gd` | Crear `_update_X_button()` + `_on_X_pressed()`; registrar en `update_ng_plus_buttons()` y `reset_ng_plus_buttons()` |
| Nuevo panel de UI o label (no-NG+) | `UIManager.gd` | Onready vars en `setup()`, funciones de update separadas |
| Nuevo constructor de texto para HUD | `UITextBuilders.gd` | `static func`, accede a autoloads por nombre explícito. `tr()` no existe en static → `TranslationServer.translate()` |
| Nueva ruta post-trascendencia | `routes/RouteX.gd` + registrar en `RouteManager.ROUTE_DEFS` | Extender `PostTrasRoute` |
| Nueva transmutación (revertir/transformar mutación) | Ver [`fusion_catabolica.md`](fusion_catabolica.md) — es el blueprint completo | Buff `transmutaciones` en `LegacyDefs` + hook en `GenomeEvaluator` + botones en `NGPlusButtonManager` |
| Nueva métrica estructural (derivada de ε/ω) | `StructuralModel.gd` | Dentro de `update_runtime()` o nueva func |
| Nuevo efecto de economía | `EconomyManager.gd` | |
| Nueva mecánica de biosfera | `BiosphereEngine.gd` | |
| Nuevo evento de telemetría | `TelemetryManager.gd` | |
| Escenario de simulación / test | `tests/sim/Scenarios.gd`, `tests/golden/` | Correr SIEMPRE vía `tools/sim/*.ps1` (sandbox con `user://` propio). Ver `docs/design/auditoria_arquitectura_2026-10.md` |

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

### `tr()` solo existe en contexto Node

`tr()` es método de instancia de `Object`/`Node`. **No es invocable desde `static func` ni desde
`RefCounted`.** En esos contextos usar `TranslationServer.translate("KEY")` (idéntico resultado).
Aplica a: `UITextBuilders`, `DarkTreeLogic` (static), `NGPlusButtonManager` (RefCounted).

### Extracción dirigida por tamaño (cómo se hizo DarkTreeLogic + NGPlusButtonManager)

Cuando un archivo supera el techo de ~600L y la lógica forma un bloque cohesivo:

1. **Mapear dependencias antes de mover** (grep): qué del bloque se llama desde afuera (necesita
   thin delegate) y qué del resto del archivo usa el bloque (no se mueve).
2. **Elegir el tipo de objeto destino**:
   - bloque sin estado, sin node refs → **static class** (`DarkTreeLogic`)
   - bloque con node refs como estado → **clase instanciada `RefCounted`** (`NGPlusButtonManager`)
3. **Mover con script Python** (no a mano) si el bloque tiene emojis/símbolos especiales — el Edit
   tool los corrompe. Usar `assert` de sanidad sobre el contenido esperado en cada índice de corte,
   para que el script falle en vez de corromper si algún número está corrido.
4. **Dejar thin delegates** en el archivo original para los callers externos → cero cambios en
   `main.gd`/`DebugPanel`/etc.

---

## Orden de autoloads en project.godot

> `DarkTreeLogic` y `NGPlusButtonManager` **no son autoloads** (uno es static, el otro es instanciado
> por UIManager) → no van en esta lista ni en `project.godot`. Godot los registra por `class_name`.

Orden real verificado (v1.0.1, crítico — Balance debe ir último):

```
Version → SlotManager → LegacyManager → SaveManager → EcoModel → BiosphereEngine →
EvoManager → UIManager → LogManager → UpgradeManager → AchievementManager → RunManager →
RouteManager → EconomyManager → StructuralModel → EmojiToRichText → AccessibilityManager →
AudioManager → TutorialManager → TelemetryManager → LocaleManager → Balance
```

`Balance` siempre al final porque sus constantes son usadas en los `_ready()` de otros managers.
`RouteManager` después de `RunManager` (depende de RunManager en init).
