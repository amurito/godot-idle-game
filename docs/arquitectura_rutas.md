# Arquitectura de rutas post-trascendencia (plan)

Estado: **diseño / no implementado**. Última actualización: 2026-05-31.

Documento de decisión para escalar las rutas post-trascendencia más allá de las 3 actuales
(VACÍO HAMBRIENTO, CARNAVAL, REENCARNACIÓN HEREDADA). El contenido de diseño de las rutas
avanzadas y el meta-endgame vive en [`nuevas transmutaciones.md`](nuevas%20transmutaciones.md).

---

## Problema: las rutas están hardcodeadas en 6 lugares

Agregar una ruta hoy obliga a tocar:

| Archivo | Qué tiene |
|---|---|
| `RunManager.gd` | un `bool *_active` por ruta + `_activate_X()` + `match route` en `activate_post_tras_route()` (~L513) + **15 referencias** a los flags + guards dispersos `if carnaval_active or run_closed...` en producción (L238, L312, L336, L366, L384) |
| `main.gd:1565-1573` | `match` hardcodeado seteando `post_tras_route` (**duplicado** con MainMenu) |
| `MainMenu.gd:238-255` | array local `ROUTES` con metadata (icon/color/name/desc), **sin gate** — las 3 siempre se muestran (4º duplicado de metadata) |
| `LegacyManager.gd` | `post_tras_route` (string) + serialize |
| `Balance.gd` | constantes sueltas (VACIO_HAMBRIENTO_MULT, CARNAVAL_INTERVAL…) |
| `LocaleManager` | claves `ROUTE_*` |

Las fórmulas de PL por ruta están inline en `close_run` (RunManager L182-186). No escala a 5+ transmutaciones + meta-endgame.

---

## Tres sistemas distintos (no "más rutas")

El doc `nuevas transmutaciones.md` mezcla tres cosas que van en lugares diferentes:

| Contenido | Qué es | Dónde vive |
|---|---|---|
| **Transmutaciones** (revertir Homeostasis/Simbiosis/etc.) | La **llave**: buff del Banco Genético que cambia el comportamiento de una mutación y desbloquea una ruta | `LegacyManager.LEGACY_DEFS`, categoría nueva `"transmutaciones"` + hooks en `EvoManager` |
| **Rutas** (básicas y avanzadas) | Algo que **modifica el loop del run** (hooks activate/tick/production/close) | **`RouteManager`** (registry único) |
| **Meta-endgame "Jardín Primigenio"** | **Subjuego paralelo** (moneda EP, tick y save propios) | **`MetaEndgameManager`** + escena `JardinPrimigenio.tscn` |

Regla mental: las **transmutaciones son la llave, no la puerta**. El meta-endgame no es una ruta:
corre en paralelo al run principal.

---

## RouteManager: registry único, separación por DATOS (no por manager)

Las rutas simples y avanzadas comparten la misma interfaz (modifican el run). No necesitan
managers distintos — se diferencian por un campo `tier` + `min_tras` + `requires`. Separar en
dos managers solo duplicaría dispatch/serialize/tick.

```gdscript
# RouteManager.gd (autoload nuevo; va DESPUÉS de LegacyManager/SlotManager en [autoload])
const ROUTE_DEFS := {
    "vacio":    { "tier": "basica", "min_tras": 1, "consumable": true, "icon": "🕳️", ... },
    "carnaval": { "tier": "basica", "min_tras": 1, "consumable": true, ... },
    "reencarnacion": { "tier": "basica", "min_tras": 1, "consumable": true, ... },
    "caos_orquestado": {
        "tier": "avanzada", "min_tras": 2, "consumable": false,
        "requires": { "transmutacion": "homeostasis_revertida" },
        ...
    },
}

func get_selectable_routes() -> Array:
    # ÚNICO lugar con la lógica de gating
    var out := []
    for id in ROUTE_DEFS:
        var d = ROUTE_DEFS[id]
        if LegacyManager.trascendencia_count < d.min_tras: continue
        if d.has("requires") and not _meets(d.requires): continue
        out.append(id)
    return out
```

### Taxonomía de tiers

| Tier | `min_tras` | Rutas (del doc) | Modelo de selección |
|---|---|---|---|
| `basica` | 1 | Vacío, Carnaval, Reencarnación | Consumible: elegís 1 por trascendencia, se borra tras el run |
| `avanzada` | 2–3 + transmutación comprada | Caos Orquestado, Micelio Omnisciente, Fusión Catabólica, Simbiosis Depredadora, Singularidad Distribuida | Desbloqueada y re-elegible |
| `fantasma` | 3 + 2 transmutaciones | Dualidad Corrosiva, Eco Silencioso | Requiere combo de reversiones |
| `secreta` | condición rara | Glitch Supremo (revertir Depredador) | Easter egg |

Campos clave que distinguen simples de avanzadas:
- **`consumable`**: básicas se borran tras el run (`post_tras_route = ""`); avanzadas son re-elegibles.
- **`selection_model`**: básicas = picker post-trascendencia; avanzadas podrían entrarse desde un menú endgame, compartiendo el registry.

### Beneficios
- Gating en UN lugar (`get_selectable_routes`), no disperso en 15 guards + main.gd + MainMenu.
- MainMenu deja de duplicar metadata: itera `get_selectable_routes()` y agrupa por `tier`
  ("Rutas básicas" / "Rutas avanzadas 🔒"). El 4º duplicado desaparece.
- Producción/guards preguntan al manager (`RouteManager.production_mult()`,
  `RouteManager.allows_bifurcation()`) en vez de chequear `carnaval_active` literal.

---

## Mapa de dependencias

```
LegacyManager (Banco Genético)
 └─ categoría "transmutaciones"  ← LLAVE (revierte mutación + unlock_route)
        │ desbloquea
        ▼
RouteManager (registry único; tier / min_tras / requires / consumable)
 ├─ tier basica   (t≥1, consumible)   vacio / carnaval / reencarnacion
 ├─ tier avanzada (t≥2, gated)        caos_orquestado, micelio_omnisciente, …
 ├─ tier fantasma (t≥3, combos)       dualidad_corrosiva, eco_silencioso
 └─ tier secreta                      glitch_supremo

MetaEndgameManager + JardinPrimigenio.tscn   ← subjuego paralelo, save propio
```

---

## Dos opciones de implementación del registry

**Opción A — `ROUTE_DEFS` dict + callbacks por nombre de método** (menor refactor)
- Pro: mínimo cambio, consistente con UpgradeManager/AchievementManager, serialize trivial.
- Contra: rutas con mucho estado (Carnaval: timer/índice/pico) ensucian el dict.

**Opción B — clase base `PostTrasRoute` (RefCounted) + un `.gd` por ruta** (refactor mayor)
```gdscript
class_name PostTrasRoute
func activate() -> void: pass
func tick(delta: float) -> void: pass
func production_mult() -> float: return 1.0
func allows_bifurcation() -> bool: return true
func close_bonus(payload: Dictionary) -> Dictionary: return {}
func serialize() -> Dictionary: return {}
func deserialize(d: Dictionary) -> void: pass
```
- Pro: escala a rutas complejas; cada ruta encapsula estado + serialize; testeable aislada.
- Contra: más boilerplate; migrar save (`post_tras_route` string → `{id, state}`).

**Recomendación:** B para el horizonte completo. Si se quiere incremental, A primero y migrar a B
cuando una ruta necesite >3 campos de estado.

---

## Pasos sugeridos (cuando se arranque, en rama)

1. **Unificar selección de ruta**: borrar el `match` de `main.gd:1565`, dejar solo el picker de MainMenu → una sola fuente.
2. **Crear `RouteManager`** y mover los 3 `_activate_*` + flags + guards ahí. RunManager queda con el ciclo de vida del run.
3. **Sacar fórmulas de PL de `close_run`** a `route.close_bonus(payload)`.
4. **Banco Genético: categoría `transmutaciones`** en `LEGACY_DEFS` con flag `unlock_route`.
5. **`MetaEndgameManager` + escena `JardinPrimigenio.tscn`** como sistema aparte, con `meta_endgame.json` (autobackup como el resto).

### Reglas del repo a respetar en el refactor
- Todo campo persistente nuevo → `SaveManager` serialize/deserialize, o no persiste.
- `RouteManager` después de `LegacyManager`/`SlotManager` en `[autoload]` (orden importa).
- Estado que cambia con run/slot → método `reset()`/`reload_for_slot()` explícito (los autoloads no se reinician con `reload_current_scene()`).
- Migrar saves viejos: `post_tras_route` string → estructura nueva con `data.get(..., default)`.
- Type hints explícitos; sin backslash multi-line; funciones de manager sobre raw state.
