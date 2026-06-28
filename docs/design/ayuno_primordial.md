# Ayuno Primordial — la segunda transmutación (SOMBRA de Hiperasimilación)

> **Estado: diseño aprobado, pendiente de implementación.**
> Este doc es la **spec de diseño canónica** de AYUNO PRIMORDIAL — primera ruta de la familia SOMBRA.
> Para la teoría general de transmutaciones ver [`enciclopedia_rutas.md`](enciclopedia_rutas.md).
> Blueprint de archivos a tocar: seguir el mismo patrón de [`fusion_catabolica.md`](fusion_catabolica.md).

---

## 1. Qué es

AYUNO PRIMORDIAL es la **SOMBRA** de Hiperasimilación: su opuesto mecánico y filosófico.

| | Hiperasimilación | Ayuno Primordial |
|---|---|---|
| Verbo | devorar | abstenerse |
| Recurso clave | Biomasa (B) | Silencio (S) |
| ε | se amplifica con B | tiende a 0 |
| Producción | click ×10 + caos | pasivo desde el vacío |
| Acción activa | devorar | romper el ayuno |

**No es** "Hiper más disciplinada" — eso es Fusión Catabólica. Ayuno abandona el consumo por completo y
descubre que el vacío también produce. Son mutuamente excluyentes: el jugador activa `transmut_fusion` O
`transmut_ayuno` en el Banco Genético, nunca los dos.

---

## 2. La "llave" en el Banco Genético

```
id: "transmut_ayuno"
cat: "transmutaciones"
cost_pl: 20
min_tras: 1
requires: haber cerrado HIPERASIMILACIÓN al menos una vez (flag: hiper_completada)
toggle: activable/desactivable (como todos los buffs)
mutex: transmut_fusion  ← solo uno activo a la vez
reveal: al cerrar Hiperasimilación por primera vez
icon_hint: ⟳ sobre el emoji de Hiper
```

Costo 20 PL (más que FC a 15 PL) porque introduce un sistema más radicalmente distinto.

---

## 3. Mecanismo de disparo

`GenomeEvaluator.update_hiperasimilacion()` ya evalúa las condiciones de entrada.
Si se cumplen **y** `LegacyManager.get_buff_value("transmut_ayuno")` está activo →
llama a `EvoManager.activate_ayuno_primordial()` en lugar de `activate_hyperassimilation()`.

---

## 4. Estado en EvoManager

```gdscript
# campos nuevos en EvoManager
var ayuno_active: bool = false
var silencio: float = 0.0          # S — recurso central
var silencio_peak: float = 0.0     # máximo histórico de la run (para NG+)
var silencio_total: float = 0.0    # acumulado total de la run (para sello 2)
var ayuno_longest_streak: float = 0.0   # segundos consecutivos en ayuno limpio (para sello 3)
var ayuno_cycles: int = 0          # veces que se activó ROMPER EL AYUNO (para sello 1)
var ayuno_streak_timer: float = 0.0    # timer del streak actual
var ayuno_burst_active: bool = false
var ayuno_burst_timer: float = 0.0
var ascesis_level: int = 0         # nivel del upgrade ASCESIS [W]
```

---

## 5. Recurso nuevo: Silencio (S)

S se acumula cuando el sistema está "en ayuno": B bajo y ε bajo.

```gdscript
# en EvoManager._process(delta) cuando ayuno_active
const SILENCIO_BASE_RATE: float = 1.0  # S por segundo en condiciones ideales

func _tick_silencio(delta: float) -> void:
    var b_factor: float = clampf(1.0 - state.biomasa * 0.2, 0.0, 1.0)
    var e_factor: float = clampf(1.0 - state.epsilon_rt * 3.0, 0.0, 1.0)
    var ascesis_bonus: float = 1.0 + ascesis_level * Balance.AYUNO_ASCESIS_RATE_BONUS
    var rate: float = SILENCIO_BASE_RATE * b_factor * e_factor * ascesis_bonus
    silencio += rate * delta
    silencio_total += rate * delta
    silencio_peak = maxf(silencio_peak, silencio)
    # streak limpio: B < 1 y ε < 0.10
    if state.biomasa < 1.0 and state.epsilon_rt < 0.10:
        ayuno_streak_timer += delta
        ayuno_longest_streak = maxf(ayuno_longest_streak, ayuno_streak_timer)
    else:
        ayuno_streak_timer = 0.0
```

S no tiene cap: recompensa la paciencia ilimitadamente.

---

## 6. Qué hace el ayuno a la economía

Al activarse `ayuno_active`:

- **B drena** activamente a ~0.5/s (constante en Balance: `AYUNO_BIOMASA_DRAIN`)
- **Nutrientes bloqueados** — no hay absorción de ε porque no hay B que procese
- **ε tiende a 0** — sin B, ε_efectivo baja naturalmente
- **Click** reducido: multiplier ×1.0 (sin bonus de Hiper)
- **Pasivo** amplificado por S: `pasivo_base × (1.0 + silencio × AYUNO_SILENCIO_FACTOR)`
  - Con S=0: pasivo normal
  - Con S=100: pasivo ×2.0 (factor 0.01)
  - Con S=300: pasivo ×4.0

```gdscript
# en EconomyManager, aplica si EvoManager.ayuno_active
func get_ayuno_pasivo_mult() -> float:
    if not EvoManager.ayuno_active:
        return 1.0
    return 1.0 + EvoManager.silencio * Balance.AYUNO_SILENCIO_FACTOR
```

---

## 7. Botón activo: [Q] ROMPER EL AYUNO

```
Cooldown: implícito (rebuild de S; no hay cooldown de tiempo)
Efecto: burst de producción basado en S acumulado
Duración burst: 15 s
Multiplicador burst: 1.0 + silencio / 50
Tras el burst:
  - silencio = 0
  - B sube +5 (el sistema "comió")
  - ayuno_cycles += 1
  - ayuno_burst_active = true por 15 s
```

La habilidad está en **el timing**: romper con S=50 da ×2.0, romper con S=200 da ×5.0.
El jugador aprende cuándo vale más romper (sello 1 exige frecuencia; sello 3 exige resistir).

---

## 8. Upgrade interno: [W] ASCESIS

```
Nombre: ASCESIS
Tecla: W (mientras ayuno_active)
Efecto: +AYUNO_ASCESIS_RATE_BONUS por nivel (sugerido: +15% a S_rate)
Costo: dinero escalante, base Balance.AYUNO_ASCESIS_COST × Balance.AYUNO_ASCESIS_SCALE^n
Max nivel: sin límite (o cap 10 para la primera iteración)
```

No cambia el ritmo del loop — hace cada ayuno más eficiente en silencio producido.

---

## 9. Condiciones de sello (3 gates)

| # | Condición | Qué empuja |
|---|---|---|
| 1 | `ayuno_cycles >= 5` | Romper frecuentemente |
| 2 | `silencio_total >= 500` | Ayunos largos o muchos ciclos |
| 3 | `ayuno_longest_streak >= 90.0` | Un ayuno sostenido sin B ni ε |

Las tres son ortogonales: el jugador que rompe rápido cumple 1 pero le cuesta 3.
El que espera mucho cumple 3 pero necesita más tiempo para 1.

Checklist visible en el panel evo vía `UITextBuilders.build_evo_checklist`.

---

## 10. PL y NG+ bonus al sellar

- **PL base:** +8 (más que Hiper a +1, refleja la dificultad de la ruta)
- **NG+ bonus:** `floor(silencio_peak / 50)`, cap 8
  - Incentiva ayunos cada vez más largos en runs repetidas
  - Con S_peak = 400 → +8 extra PL (cap)

---

## 11. Legado al sellar: `legado_primicia_del_vacio`

```
id: legado_primicia_del_vacio
efecto: al inicio de cada run futura, el pasivo arranca amplificado ×2.0
        y decrece linealmente hasta ×1.0 en los primeros 90 segundos.
narrativa: "el sistema ya estaba produciendo en el silencio antes de nacer"
```

Aplica siempre (el early run tiene B=0 de todas formas), es visible y notable,
y no requiere mantener ninguna condición especial.

Implementación: flag en LegacyManager `has_legacy_primicia`, aplicado en `EconomyManager`
durante los primeros 90 s de cada run como decaying multiplier en pasivo.

---

## 12. Logros

| id | tier | condición | nombre sugerido |
|---|---|---|---|
| `ayuno_iniciado` | ESPORA | activar la ruta por primera vez | "El Primer Silencio" |
| `primer_ayuno` | ANCESTRAL | cerrar AYUNO PRIMORDIAL | "Primicia del Vacío" |
| `ayuno_perfecto` | MYTHIC | cerrar con streak ≥ 180 s Y cycles ≥ 7 | "Ayuno Absoluto" |

Regla de diseño: dos logros por cerrar (ESPORA al activar + ANCESTRAL al cerrar)
y uno de mastery por condición extrema (MYTHIC).

---

## 13. Visual del reactor

| Estado | Visual |
|---|---|
| Durante el ayuno | reactor muy oscuro, casi negro; pulso lento de luz plateada/blanca |
| Burst activo (15 s) | flash blanco brillante que decae gradualmente |
| Al sellar | tono plateado suave permanente hasta fin de run |

Opuesto al rojo frenético de Hiperasimilación.

---

## 14. Color de núcleo (NGPlus panel)

Sugerido: `#C0C8D0` (plateado frío) — contrasta con el dorado de FC y el rojo de Hiper.

---

## 15. Lore (Codex)

```
body_es: "La hiperasimilación enseñó al sistema a consumirlo todo. El ayuno le enseña
lo que existía antes de que tuviera hambre. La primera espora no necesitaba comer —
era sostenida por el cosmos mientras esperaba aprender a devorar."

lore_prefix: entrada de lore de AYUNO PRIMORDIAL en LocaleManager
```

Unlock: `route_closed` con id `ayuno_primordial`.

---

## 16. Constantes en Balance.gd

```gdscript
# AYUNO PRIMORDIAL
const AYUNO_BIOMASA_DRAIN: float = 0.5        # B perdida por segundo
const AYUNO_SILENCIO_FACTOR: float = 0.01     # S × factor = bonus pasivo
const AYUNO_ASCESIS_RATE_BONUS: float = 0.15  # +15% S_rate por nivel de Ascesis
const AYUNO_ASCESIS_COST: float = 50.0        # costo base del primer nivel
const AYUNO_ASCESIS_SCALE: float = 2.5        # escala de costo
const AYUNO_BURST_DURATION: float = 15.0      # segundos de burst
const AYUNO_BURST_DIVISOR: float = 50.0       # mult = 1 + S / 50
const AYUNO_BURST_BIO_SPIKE: float = 5.0      # B añadida al romper
const AYUNO_SELLO_CYCLES: int = 5
const AYUNO_SELLO_TOTAL: float = 500.0
const AYUNO_SELLO_STREAK: float = 90.0
const AYUNO_NG_PEAK_DIV: float = 50.0         # floor(S_peak / div), cap 8
const AYUNO_NG_CAP: int = 8
const AYUNO_PL_BASE: int = 8
const AYUNO_LEGACY_DURATION: float = 90.0     # s de primicia_del_vacio
const AYUNO_LEGACY_MULT_START: float = 2.0    # ×2.0 → ×1.0 lineal
```

---

## 17. Archivos a tocar (blueprint)

1. **`Balance.gd`** — constantes (§16)
2. **`LegacyDefs.gd`** — buff `transmut_ayuno` en categoría `transmutaciones`; legado `legado_primicia_del_vacio`
3. **`GenomeEvaluator.gd`** — hook mutex: si `transmut_ayuno` activo → desviar a `activate_ayuno_primordial()`
4. **`EvoManager.gd`** — `activate_ayuno_primordial()`, `_tick_silencio()`, sello checks, `reset()`
5. **`EconomyManager.gd`** — `get_ayuno_pasivo_mult()`, legacy decaying mult en early-run
6. **`NGPlusButtonManager.gd`** — botones [Q] ROMPER EL AYUNO y [W] ASCESIS
7. **`UITextBuilders.gd`** — checklist de sello, panel evo texto
8. **`AchievementDefs.gd`** — 3 logros (§12)
9. **`CodexDefs.gd`** — entrada `ayuno_primordial`
10. **`LocaleManager.gd`** — todas las claves ES/EN
11. **`SaveManager.gd`** — serializar/deserializar campos nuevos de EvoManager

---

## 18. Orden de implementación sugerido

1. Balance.gd + LegacyDefs.gd (la "llave" y el legado)
2. EvoManager: activate + tick + sello + reset
3. EconomyManager: multiplicadores
4. NGPlusButtonManager: botones Q y W
5. UITextBuilders: checklist
6. SaveManager: persistencia
7. AchievementDefs + CodexDefs + LocaleManager: wrap-up
