# PROTOCOLO Φ — Fago Algorítmico

**Tipo:** Cuarta ruta post-trascendencia (suma a VACÍO HAMBRIENTO / CARNAVAL / REENCARNACIÓN).
**Estado:** Diseño v2 — sin implementar.
**Cambios v2:** C activa, INERT consolación, Momentum Viral, Splice cap, Sobrecarga por repetición, Ventana de Óptimo Inestable, Eventos deterministas, 2 sinergias semi-visibles, feedback visual desde Fase 1.
**Identidad tonal:** se sacrifica "Observatorio fⁿ". El jugador deja de observar y pasa a **escribir genoma sintético** dentro del organismo. Es el primer modo activo del juego.

---

## 1. Posicionamiento

- Es un **modo de run alternativo**, no un buff que se activa mid-run.
- Se elige desde MainMenu antes de empezar la run, igual que CARNAVAL DE MUTACIONES en el plan v0.9.
- Mientras `phi_run_active`, las mutaciones normales (Hiperasimilación, Parasitismo, Red Micelial, Homeostasis…) quedan **bloqueadas** — sus FSM van a `bloqueado` desde el `_ready`. Esta run es Φ y nada más.
- Cierra con sus propias rutas, no con las clásicas.

### 1.1 Gates de desbloqueo

Para que el toggle "🧬 Iniciar Run Φ" aparezca en MainMenu:

- `LegacyManager.trascendencia_count >= 3`
- Haber cerrado al menos una run con `MET.OSCURO` (suma `met_oscuro_closed_count >= 1`).
- Haber comprado el cosmic `phi_unlock` (~10 Ξ, Tier 4 nuevo en Banco Cósmico).

---

## 2. Loop jugable (60–90s por ciclo)

```
SELECCIONAR MÓDULOS (3) → SETEAR T → SINTETIZAR (15s) → OUTCOME → VIRUS ACTIVO (60s) → REPEAT
```

1. **Seleccionar 3 módulos** de un pool inicial de ~6 (más se desbloquean por Memoria Viral).
2. **Setear T** (slider 0.5–1.0). Es la única variable continua que toca el jugador.
3. **Click "SINTETIZAR"** → barra de progreso 15s (animación Gibson). Durante este timer no podés cambiar nada.
4. **Outcome**: ALIVE / INERT / LETHAL (ver §4).
5. **Si ALIVE**: el virus aplica multiplicador a biomasa durante 60s. Su FC final queda como score visible.
6. **Memoria Viral**: si FC ≥ 20, el patrón (3 módulos + T usado) se guarda en slot reusable.
7. Volver a 1.

El jugador no escribe ATCG en ningún momento. La capa "ADN" es flavor visual debajo, generada por el sistema según los módulos.

---

## 3. Variables visibles (3, no más)

| Variable | Rango | Significado | Persistencia |
|---|---|---|---|
| **T (Temperatura)** | 0.5 – 1.0 | Slider riesgo/recompensa. 0.7–0.9 es sweet spot. | Por ciclo (se elige cada vez) |
| **C (Coherencia)** | 0 – 100 | **Recurso activo gastable.** Reduce chance de LETHAL pasivamente, y se puede gastar para acciones (reroll, estabilizar, extender peak window). | Run-scoped |
| **FC (Fold Change)** | 0 – ~80 | Output del último virus. Métrica de éxito. | Volátil, último ciclo |

Variables internas (no se muestran al jugador):
- `phi_run_active: bool`
- `phi_synthesis_progress: float` (0–15s timer)
- `phi_virus_fc: float`, `phi_virus_remaining: float`
- `phi_memoria_viral: Array[Dictionary]` (max 5 slots)
- `phi_max_fc_run: float` (para logros y PL)
- `phi_viable_count: int`, `phi_lethal_count: int`

---

## 4. Fórmulas

### 4.1 Cálculo del FC

```gdscript
var fc_base: float = 0.0
var eps_cost: float = 0.0
var c_cost: float = 0.0
for mod in selected_modules:
    fc_base += mod.fc_contrib
    eps_cost += mod.eps_contrib
    c_cost += mod.c_contrib

# T-multiplier: T=0.7 neutral, T=1.0 → 2.2x, T=0.5 → 0.2x
var t_mult: float = 1.0 + (T - 0.7) * 4.0
eps_cost *= t_mult
```

### 4.2 Roll de outcome

```gdscript
# Letal solo si T > 0.9
var lethal_chance: float = 0.0
if T > 0.9:
    lethal_chance = (T - 0.9) * 4.0  # T=1.0 → 40% (mapea al paper)
    lethal_chance *= (1.0 - C / 100.0)  # C protege

if randf() < lethal_chance:
    return OUTCOME_LETHAL  # ε spike + C drain

var random_factor: float = randf_range(0.7, 1.3)
var fc_final: float = fc_base * t_mult * random_factor

if fc_final < 2.0:
    return OUTCOME_INERT  # ciclo desperdiciado, sin penalty
return OUTCOME_ALIVE
```

### 4.3 Efecto del virus ALIVE

```gdscript
# Mientras virus activo (cada tick):
var biomass_mult: float = 1.0 + fc_final / 10.0  # FC=10 → 2x, FC=50 → 6x
BiosphereEngine.biomasa += BiosphereEngine.biomasa * biomass_mult * dt * 0.01

# Estrés acumulado por T alto
StructuralModel.epsilon_runtime += (0.005 + 0.01 * T) * dt
```

### 4.4 Coherencia (regen pasiva)

```gdscript
# +5 C cuando virus llega a término sin colapsar (caps en 100)
# -25 C en LETHAL
# +1 C por cada módulo que pasa Tier 1 (validez de secuencia)
```

### 4.5 Coherencia activa (acciones gastables)

C deja de ser solo escudo. Se gasta vía botones contextuales:

| Acción | Costo | Efecto |
|---|---|---|
| **Reroll outcome** | 20 C | Re-tira el outcome de la síntesis recién resuelta (una sola vez por ciclo). |
| **Estabilizar virus** | 30 C | Bloquea el FC actual del virus en su valor pico durante 30s extra. Solo válido durante ventana de óptimo (§4.9). |
| **Extender peak window** | 15 C | Empuja la ventana de óptimo +5s (acumulable hasta 3 veces, con riesgo de colapso anticipado). |

Diseño: hace que C importe minute-to-minute, no solo como buffer pasivo.

### 4.6 INERT como resorte

```gdscript
# Outcome INERT (FC < 2)
phi_inert_streak = min(phi_inert_streak + 1, 4)
# Próxima síntesis: fc_base *= (1.0 + 0.05 * phi_inert_streak)  # cap +20%
# Streak se rompe con ALIVE o LETHAL (no se acumula con éxito)
```

### 4.7 Momentum Viral

```gdscript
# +5% FC base por cada ALIVE consecutivo, cap +25%
phi_momentum = min(phi_momentum + 1, 5)  # 5 stacks = +25%
# Se rompe SOLO con LETHAL (INERT no rompe el momentum)
# fc_base *= (1.0 + 0.05 * phi_momentum)
```

### 4.8 Sobrecarga de Laboratorio (anti-repetición)

No castiga velocidad — castiga repetir el mismo build. Empuja experimentación.

```gdscript
# Cada síntesis: comparar set de módulos contra los últimos 3 sets.
var repeat_score: int = 0
for past_set in last_3_sets:
    var matches: int = count_module_matches(current_set, past_set)
    if matches >= 2:
        repeat_score += matches  # 2 módulos repetidos = +2, 3 idénticos = +3

phi_overheat += repeat_score * 0.05  # cap 0.5
phi_overheat = max(0.0, phi_overheat - 0.1 * dt)  # decae con tiempo

# Aplicado en outcome:
eps_cost *= (1.0 + phi_overheat)
fc_base *= (1.0 - phi_overheat * 0.3)  # también penaliza output, no solo input
```

### 4.9 Ventana de Óptimo Inestable

Durante el virus ALIVE (60s totales), hay una ventana de pico:

```gdscript
# Por defecto: ventana entre segundos 20 y 30 del virus
var peak_start: float = 20.0
var peak_end: float = 30.0  # mutable con "Extender peak window" (§4.5)

# Durante peak window:
if virus_age >= peak_start and virus_age <= peak_end:
    biomass_mult *= 2.0  # FC efectivo se duplica en este lapso

# Si el jugador extendió la ventana > 3 veces (peak_end > 45s):
# Riesgo de colapso anticipado: 5% por segundo de exceso
if peak_end > 45.0 and randf() < (peak_end - 45.0) * 0.05 * dt:
    virus_collapse()  # virus muere prematuramente, queda 0s
```

Diseño: builds estables cosechan los 60s lineales. Builds arriesgadas extienden el peak con C, ganando picos brutales pero arriesgando colapso.

### 4.10 Eventos deterministas durante virus

Triggers basados en estado del sistema, no aleatorios. Se disparan una vez por virus:

| Trigger | Condición | Efecto |
|---|---|---|
| **Inestabilidad tardía** | `fc_final > 40` | A los 35s del virus, FC sufre -20% por 10s (luego se recupera). |
| **Micro-colapso** | `epsilon_runtime > 1.0` al sintetizar | Al iniciar virus, biomasa pierde 5% instantáneo. |
| **Estabilización espontánea** | `C >= 80` al sintetizar | Virus no colapsa por overheat ni por extensión de peak. |
| **Resonancia genómica** | Set incluye 2+ módulos del mismo "grupo" | Peak window dura 5s extra gratis (sin costo de C). |

---

## 5. Pool de módulos

**Iniciales (6, todos disponibles desde el primer ciclo):**

| Módulo | FC | ε | C | Notas |
|---|---|---|---|---|
| Cápside Básica | +5 | +1 | 0 | Replicador simple |
| Tropismo E.coli | +3 | 0 | -2 (refund) | Safety pick |
| Lisina Promotora | +8 | +3 | +2 | Agresivo |
| Replicasa Optimizada | +10 | +4 | +1 | Damage |
| Inhibidor Eucariota | +4 | -2 (REDUCE!) | +3 | Defensivo |
| Splice Recursivo | +6 | +2 | 0 | Duplica el FC del módulo de **menor** contribución del set. Cap absoluto: +10 al combo |

**Desbloqueables (4, vía Memoria Viral usándose 3+ veces o logros):**

| Módulo | FC | ε | C | Notas |
|---|---|---|---|---|
| CRISPR Cassette | +15 | +6 | +5 | Glass cannon |
| Latencia Lisogénica | +0 → +12 | 0 | 0 | FC inicial 0; sube a 12 después de 30s del virus |
| Quórum Sensor | +(3 × viable_count) | +1 | +1 | Escala con runs viables previas |
| Mutación Legendaria | random 0–50 | random 0–10 | +10 | Solo aparece random cada N ciclos |

### 5.1 Sinergias semi-visibles

No son secretos puros. Los tooltips de los módulos sugieren compatibilidad ("resuena con edición genética avanzada", "afín a estructuras agresivas"), pero el efecto exacto se descubre al usarlas. Solo 2 sinergias en v1, no más:

| Combo | Tooltip hint | Efecto al detectarse |
|---|---|---|
| **CRISPR Cassette + Splice Recursivo** | "resuena con edición genética avanzada" | +5 FC al combo, ε del Splice se reduce a 0 |
| **Latencia Lisogénica + Quórum Sensor** | "patrón cooperativo dormido" | El payoff diferido de Latencia se adelanta 10s |

UI: cuando el set seleccionado activa una sinergia, aparece chip "✓ Sinergia detectada" antes de sintetizar.

### 5.2 Grupos para Resonancia genómica (§4.10)

- **Replicativos**: Cápside Básica, Replicasa Optimizada, CRISPR Cassette
- **Defensivos**: Tropismo E.coli, Inhibidor Eucariota
- **Combinatorios**: Splice Recursivo, Latencia Lisogénica, Quórum Sensor
- **Caóticos**: Lisina Promotora, Mutación Legendaria

2+ módulos del mismo grupo → activa "Resonancia genómica" en §4.10.

---

## 6. Cierres (rutas de finalización)

Todas usan `RunManager.close_run("PROTOCOLO Φ", reason)`:

### 6.1 Éxito

| Ruta | Condición | PL |
|---|---|---|
| **DOMINANCIA F69** | Alcanzar FC ≥ 65 en una síntesis | +8 |
| **DECKBUILDER GENÉTICO** | 5/5 slots Memoria Viral con FC ≥ 30 cada uno | +6 |
| **PERPLEXIDAD MÍNIMA** | 10 viables consecutivos sin letal ni inert | +5 |

### 6.2 Colapso

| Ruta | Condición | PL |
|---|---|---|
| **LISIS DEL INGENIERO** | C llega a 0 con `ε_runtime > 1.5` | +3 (consuelo) |
| **CASCADA EPISTÁTICA** | 3 letales en menos de 60s | +2 |

### 6.3 Voluntario

- Botón "🧬 SELLAR PROTOCOLO Φ" — disponible después de 5 min en run.
- PL escalonado por `phi_max_fc_run`:
  - max_FC < 20 → +2 PL
  - max_FC 20–40 → +4 PL
  - max_FC 40–65 → +6 PL
  - max_FC ≥ 65 → es DOMINANCIA F69 (no voluntario)

---

## 7. Integración con managers existentes

### 7.1 PhiManager.gd (NUEVO autoload)

Owns:
- Estado de la síntesis actual (módulos seleccionados, T, progreso, virus activo).
- Pool de módulos (Dictionary con stats).
- Memoria Viral pool (max 5).
- Counters (viable_count, lethal_count, max_fc_run).

Métodos:
- `start_synthesis(modules: Array, t: float)`
- `tick(dt: float)` — llamado desde main `_on_logic_tick`.
- `_resolve_outcome()` — calcula ALIVE/INERT/LETHAL.
- `apply_virus_effect(dt)` — biomasa boost mientras activo.
- `save_to_memoria_viral(modules, t, fc)`.
- `load_pattern(slot_idx)`.
- Señales: `synthesis_completed(outcome, fc)`, `virus_expired(fc)`, `memoria_slot_filled(idx)`.

### 7.2 EvoManager.gd

- Nuevo flag `phi_run_active: bool` (proxy a `PhiManager.active`).
- En `update_genome()`, si `phi_run_active`, **bloquear todas las mutaciones** (set a `bloqueado`). Salir de `update_genome()` early.

### 7.3 RunManager.gd

- Aceptar `"PROTOCOLO Φ"` como `final_route` válido.
- En `close_run()`, si la ruta es "PROTOCOLO Φ", llamar a `PhiManager.calculate_pl_bonus()` para sumar PL extra al base.

### 7.4 StructuralModel.gd

Sin cambios estructurales. Solo recibe pushes de ε desde PhiManager.tick.

### 7.5 LegacyManager.gd — Banco Genético (nuevos buffs)

| ID | Efecto | PL | Slot |
|---|---|---|---|
| `phi_t_lock` | T se clampea automáticamente a [0.7, 0.9] | 8 | run-Φ-only |
| `phi_module_slot_4` | 4 módulos por síntesis (en vez de 3) | 12 | run-Φ-only |
| `phi_lethal_immunity` | Primer LETHAL de la run es ignorado | 6 | run-Φ-only |
| `phi_starting_coherencia` | Empezás con 50 C en vez de 0 | 4 | run-Φ-only |
| `phi_memoria_extended` | 7 slots de Memoria Viral en vez de 5 | 6 | run-Φ-only |

### 7.6 LegacyManager.gd — Banco Cósmico (nuevo Tier 4)

| ID | Efecto | Ξ |
|---|---|---|
| `phi_unlock` | Habilita el modo Run Φ | 10 |
| `phi_pool_expanded` | Inicial pool incluye CRISPR Cassette desde el ciclo 1 | 6 |
| `phi_persistencia_memoria` | Memoria Viral persiste entre trascendencias | 8 |

### 7.7 AchievementManager.gd

| ID | Tier | Trigger |
|---|---|---|
| `phi_primer_viable` | Common | Primer ALIVE |
| `phi_dominancia_f69` | Ancestral | Cierre por DOMINANCIA F69 |
| `phi_lisis_ingeniero` | Mythic (secret) | Cierre por LISIS DEL INGENIERO |
| `phi_deckbuilder` | Ancestral | Cierre por DECKBUILDER GENÉTICO |
| `phi_mutacion_legendaria` | Mythic (secret) | Usar módulo Mutación Legendaria con FC ≥ 40 |
| `phi_cero_letal` | Rare | Cerrar Run Φ con 0 LETHAL acumulados |

### 7.8 MainMenu.gd

- Toggle "🧬 Iniciar Run Φ" visible solo si gates §1.1 cumplidos.
- Si toggle está activo al hacer "Comenzar", se llama `PhiManager.activate_run_mode()` antes del primer tick.

### 7.9 UI

Nuevo panel `phi_lab.tscn` (controller `phi_lab.gd`):

```
┌────────────────────────────────┐
│ 🧬 LABORATORIO Φ               │
│                                │
│ T:  [0.5 ────●─────── 1.0]    │
│       0.75                     │
│                                │
│ Módulos (3/3):                 │
│  • Cápside Básica              │
│  • Lisina Promotora            │
│  • Splice Recursivo            │
│                                │
│ [SINTETIZAR]                   │
│ ████████░░░░░░░░ 8/15s         │
│                                │
│ ── ESTADO ──                   │
│ Virus: ACTIVO  FC=23.4         │
│ ████████░░ 32s restantes       │
│                                │
│ Coherencia: 67/100             │
│ Memoria Viral: 2/5             │
│  [slot 1] FC=42 (Cápside+Lis+CRISPR @ 0.85)
│  [slot 2] FC=31 (...)          │
│                                │
│ [Pool de módulos] [Memoria]    │
└────────────────────────────────┘
```

El panel reemplaza al "Árbol de Mutaciones" durante run Φ. UI clean.

---

## 8. Lo que NO se incluye (sacrificado intencionalmente)

- Tipear ATCG (anti-idle).
- Filtros GC%, AAI, perplexidad como variables del jugador (van internas o eliminadas).
- StripedHyena / Fourier (lore puro, no se traduce).
- Filtro Eucariota (lore sin mecánica).
- Simulación previa (mata la tensión del slider T).
- Co-evolución de la biomasa que se defiende (merece ser su propia ruta).
- Parásitos de parásitos (caro, poco retorno).
- Lectores SAE (ChatGPT idea 4 — no traduce a nada accionable).

---

## 9. Implementación por fases

**Fase 1 — MVP jugable (1 semana)**
- PhiManager.gd con synthesis loop + 3 outcomes.
- Pool de 6 módulos iniciales.
- Slider T + 3 slots de selección.
- Cierre voluntario + DOMINANCIA F69.
- C activa: solo "Reroll outcome" (las otras 2 acciones quedan para Fase 2).
- INERT consolación + Momentum Viral (mecánicas baratas, alto valor).
- **Feedback visual mínimo desde día 1**: barra de FC que crece con tween agresivo, número grande pulsante al revelar outcome, color del panel cambia con T (azul frío → rojo caliente). Sin sonido, sin partículas — solo lo necesario para que se sienta el FC.
- UI mínima sin Memoria Viral.

**Fase 2 — Memoria Viral + C activa completa (4 días)**
- Slot system + load pattern.
- Persistencia run-scoped.
- C activa: agregar "Estabilizar virus" y "Extender peak window".
- Ventana de óptimo inestable (peak window §4.9).
- Logro deckbuilder.

**Fase 3 — Módulos late-game + sinergias (4 días)**
- Pool desbloqueable (4 módulos extra).
- Mutación Legendaria como random encounter.
- Sinergias semi-visibles (§5.1).
- Resonancia genómica (§4.10 trigger).
- Logros mythic.

**Fase 4 — Eventos deterministas + Sobrecarga (3 días)**
- Eventos durante virus (§4.10): inestabilidad tardía, micro-colapso, estabilización espontánea.
- Sobrecarga de Laboratorio (§4.8): tracking de last_3_sets + penalty.
- Hints soft de UI ("⚠ inestabilidad acumulada", "✓ sinergia detectada").

**Fase 5 — Banco Genético / Cósmico (2 días)**
- 5 buffs Φ + 3 cosmics.
- Cosmic gate `phi_unlock`.

**Fase 6 — Polish + balance (3 días)**
- Animaciones de síntesis (más allá del feedback mínimo de Fase 1).
- Sound cues.
- Balance pass de FC, ε_cost, costos de C.

**Total estimado**: ~3 semanas.

---

## 10. Decisiones cerradas

1. **Un virus a la vez.** No se puede sintetizar mientras hay virus ALIVE. Cada decisión pesa.
2. **Coherencia resetea por run.** Excepción: buff `phi_starting_coherencia` (Banco Genético) arranca con 50 C.
3. **Memoria Viral cross-trascendencia solo via cosmic** `phi_persistencia_memoria`. Sin el cosmic, los slots se borran al trascender. Protege la curva de progresión.
4. **Economía normal habilitada durante Run Φ.** Money/click/auto/trueque siguen funcionando. El loop Φ se suma, no reemplaza la economía base. Esto evita que Φ se sienta aislado del resto del juego.
