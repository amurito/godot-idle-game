# Rework de la Rama Verde (Red Micelial) — Anti-AFK

> Estado: **TODAS las fases (1, 1b, 2, 3, 4, 5) implementadas y compilando en main.**
> Rework de la rama verde completo. Pendiente: playtest/tuning final + commit.
>
> ⚠️ Trabajar SIEMPRE en main (`C:\Users\nicol\Desktop\idleantigravity`), no en
> worktrees — el worktree `great-turing-aa67fe` está stale (pre-Balance.gd).

## Nomenclatura (corregida) — según `docs/arbol_evoluciones.html`

- **Red Micelial = RAMA VERDE** (biología). NO roja (roja = colapso/caos).
- Bifurca en Fase A:
  - **COLONIZACIÓN** (rama biológica, verde lima) → Seta → Esporulación → Panspermia
  - **SIMB. MECÁNICA** (rama azul, cian) → Núcleo Conciencia → Singularidad → Mente Colmena
- **Familias de Trascendencia** (cross-family, respetar al tocar `endings_achieved`):
  - ORDEN: Homeostasis, Allostasis, Homeorhesis, **SINGULARIDAD**
  - BIOLOGÍA: Parasitismo, Simbiosis, **Esporulación, Panspermia Negra, Mente Colmena**
  - COLAPSO: Hiperasimilación, Depredador, Met. Oscuro

## Problema (verificado en main)

Las 5 salidas comparten el gate "sostener postura pasiva durante T s":

| Ruta | Gate | Ref (main) |
|---|---|---|
| Colonización | `micelio += hifas·0.4·dt` hasta 60% (se llena solo) | `BiosphereEngine.gd:_grow_micelio` |
| Seta/Primordio | sobrevivir 90s sin ε≥0.50, hifas≥60, delta<50 | `EvoManager.gd:_process_primordio_biological` |
| Panspermia | ESPORULACIÓN previa + primordio activo + `money≥100000` | `main.gd:_on_sporulation_final_pressed` |
| Singularidad | accounting≥2 + ε≤0.25, 90s (acelera con estabilidad) | `EvoManager.gd:_process_primordio_mechanical` |
| Mente colmena | ratio 50/50 ±2% 180s → reward = auto-play | `main.gd` logic tick + `RunManager.activate_mente_colmena` |

## Principio rector

"Sostené X durante T s" → "gestioná un proceso que decae si no lo alimentás, bajo
perturbaciones que escalan". Reusa el patrón Depredador (timer + acción que gasta
recurso) y el anti-AFK de ASCESIS. Constantes nuevas → `Balance.gd`. Persistencia
nueva → `SaveManager` bloque `evo` (serialize ~77 / deserialize ~194).

---

## Fase 1 — COLONIZACIÓN: "Empuje de Frontera" ✅ IMPLEMENTADA

El micelio dejó de llenarse solo. Ahora:

- **`BiosphereEngine._grow_micelio(is_colonization)`**: en colonización las hifas sólo
  sostienen un piso (`MICELIO_SUPPORT_FLOOR=8%`); por encima la frontera **decae**
  (`MICELIO_COLONIZ_DECAY=2%/s`). Congelado una vez que arranca el primordio.
- **`EvoManager.colonizacion_pulse()`** llamado desde `main.on_reactor_click()`: cada
  **click manual** empuja `+MICELIO_PULSE_GAIN=1.2%`. → clickeo activo sostenido para
  llegar al 60% contra el decay. Sin clics, retrocede.
- **`EvoManager.process_colonizacion(dt)`** (logic tick): retracciones cada
  `COLONIZ_PERT_INTERVAL=14s`, mordida `BITE_BASE=4%` que **escala** con el tiempo en
  fase (`+0.05%/s`, cap `18%`). Log + toast.
- UI: hint en el checklist de bifurcación (`UIManager` rama COLONIZATION).
- Anti-AFK: el decay ya castiga el abandono; no hace falta timer de click aparte.
- Posture switch intencional: se entra a Red Micelial con pasivo dominante; al elegir
  Colonización hay que **clickear** para colonizar.

**Pendiente Fase 1 (polish):** clave i18n `EVO_COLONIZ_HINT` (hoy hardcoded ES);
opcional panel/visual dedicado de frontera; tuning de números tras playtest.

## Fase 2 — SETA / PRIMORDIO: "Maduración activa" ✅ IMPLEMENTADA

Reemplaza "sobrevivir 90s pasivo". Ahora la maduración es un balanceo activo:

- **Banda de incubación** `ε ∈ [0.30, 0.48]` (`PRIMORDIO_BAND_*`): la maduración
  (`primordio_timer` → `PRIMORDIO_BIO_MATURE=60s`) **sólo avanza en banda**. El piso
  de ε de colonización es 0.25 (< banda) → en reposo el progreso se estanca: hay que
  **clickear** para meter ε en banda (sin pasarse de 0.48).
- **Integridad** (`primordio_integrity`, 0–100): se drena fuera de banda
  (`PRIMORDIO_OOB_DRAIN`) y por **contaminaciones** cada `PRIMORDIO_PERT_INTERVAL=8s`
  (daño escala con la maduración, patean ε fuera de banda). Si llega a 0 → aborta
  (reusa `_abort_primordio`, coste micelio).
- **Acción "Regar"** (el PrimordioButton se vuelve `Regar (-bio)` durante el primordio):
  gasta biomasa → restaura integridad + reencauza ε al centro de banda. `main._on_primordio_button_pressed`
  ramifica: activo → `primordio_regar()`, si no → `try_iniciar_primordio()`.
- **Inicio** (auto o botón) ahora exige `micelio≥60` → ata la Fase 1 (antes el auto-start
  ignoraba el micelio y salteaba colonización). Unificado en `_begin_primordio_biological()`.
- UI: la `FungalCycleBar` muestra **maduración %** con color por integridad (verde→rojo);
  checklist con estado de banda + integridad. i18n: claves `PRIMORDIO_*` (ES+EN).

**Decisión:** NO se extrajo una primitiva `RedProcess` genérica — tanto Fase 1
(micelio/decay/pulsos) como Fase 2 (banda/integridad) quedaron bespoke y limpias.
Se evaluará extraer helpers compartidos si Fase 3/4 muestran duplicación real.

**Pendiente Fase 2 (polish):** tuning de números tras playtest (ancho de banda,
cadencia/daño de contaminación, heal/coste de Regar, duración 60s).

## Fase 3 — ESPORULAR / PANSPERMIA: "Secuencia de Lanzamiento" ✅ IMPLEMENTADA

El `money≥100k` (checkbox) → **lanzamiento de dos presiones**. Disponible cuando
reformás la seta en una run post-ESPORULACIÓN (`is_panspermia_window()`): el botón
final pasa a ser EYECTAR. Cada eyección sube **carga** (`PANSPERMIA_CHARGE_GAIN`) y
**calor** (`PANSPERMIA_HEAT_PER_PULSE`). Ambos **decaen** en el logic tick
(`process_panspermia`):
- la **carga decae** (`CHARGE_DECAY`) → no podés ir lento (tenés que seguir eyectando);
- si una eyección sobrepasaría `HEAT_MAX` → **MISFIRE**: pierde carga
  (`OVERLOAD_PENALTY`), calor al tope → no podés ir rápido.
- El sweet spot es un ritmo: eyectar firme sin sobrecalentar. Llegar a
  `CHARGE_GOAL=100` → PANSPERMIA NEGRA (+10 PL, legado semilla_cosmica).

**Why del rework (v2):** la v1 (5 pulsos discretos + calor) era trivial — el jugador
auto-pausaba y el calor nunca mordía + dinero irrelevante late-game. La carga-que-decae
fuerza el ritmo y vuelve el calor una amenaza real. Self-contained (no ε/Ω). Estado
`panspermia_charge`/`panspermia_heat` + SaveManager. La `FungalCycleBar` muestra la carga
durante el lanzamiento. i18n `PANSPERMIA_*` (ES+EN). Fijé el toast de Semilla Cósmica.

**Pendiente Fase 3 (polish):** tuning de la ventana de ritmo (gain/decay de carga y
calor, penalty); color de la barra por calor (hoy queda verde, el calor va en el label).

## Fase 4 — SINGULARIDAD (rama azul): "Integración de Cómputo" ✅ IMPLEMENTADA

**Identidad = SINCRONIZACIÓN por condiciones (NO minijuego de botón).** Coherente con
"poner los subsistemas en fase". Un medidor `nucleo_sync` sube (`NUCLEO_SYNC_RATE`) mientras
se cumplen **las 4 condiciones a la vez**, y baja (`NUCLEO_SYNC_DECAY` > rate) si se rompe
alguna. Llegar a `NUCLEO_SYNC_GOAL=100` → Núcleo de Conciencia → CONECTAR SINGULARIDAD.
- **Contabilidad ≥ `NUCLEO_ACC_MIN`** (sustrato de cómputo)
- **Ω ≥ `NUCLEO_OMEGA_MIN`** (orden estructural)
- **ε en banda [`NUCLEO_EPS_LO`, `NUCLEO_EPS_HI`]** ← eje activo: ni idle (ε cae) ni ruido
  (ε sube); hay que *mantener la frecuencia de fase* modulando los clicks
- **Biomasa ≥ `NUCLEO_BIO_MIN`** (tejido a integrar)

`_nucleo_conditions_met()` en EvoManager; sin botón (la acción es sostener el estado ~17s).
Checklist azul lista las 4 condiciones + medidor de sincronía %.

**Why de los rework:** v1 (gasto $ + throttle) = "tener plata y comprar", calor
intrascendente. v2 (overclock térmico) = trivial. v3 (condiciones de fase) = gate de
estado sostenido como Homeostasis/Allostasis pero temático de "sincronizar", distinto de
los minijuegos de las otras fases (tap/carga/regar).

**Lore/log:** SINGULARIDAD tiene PL variable (6 + bonus ε) otorgado en main → se loguea ahí
(`LOG_PL_BASE`); `close_run` ya no logea "+0" para rutas de PL variable (guardado dentro de
`if pl_to_add > 0`). Consistente con el panel.

**Pendiente Fase 4 (polish):** tuning (gain base, overclock K, penalty, decay).

## Fase 5 — MENTE COLMENA ✅ IMPLEMENTADA

**Buff acotado (decisión: ráfaga activable):** el auto-play deja de ser permanente.
El legado `mente_colmena` ahora habilita un botón **"Override IA"** (RightPanel,
`_update_mc_override_button`): lo disparás → la IA corre `MC_BURST_DURATION=18s`
(auto-click ×10 + auto-compra), luego `MC_BURST_COOLDOWN=45s` de cooldown. `RunManager`:
`mc_burst_timer`/`mc_cooldown_timer` + `activate_mc_burst()`/`tick_mc_burst()`.
El **pasivo ×3 queda permanente** (efecto de legado separado). LegacyManager ya NO
auto-activa el auto-play al iniciar run.

**Gate endurecido (decisión: rework):** de "ratio 50/50 ±2% por 180s" a sostener
SIMULTÁNEAS y sin romper durante `MC_GATE_HOLD=100s`:
- ratio activo/pasivo en 50/50 ±`MC_GATE_RATIO_TOL`
- ε en banda [`MC_GATE_EPS_LO`, `MC_GATE_EPS_HI`] (sistema vivo y estable)
- Δ$/s ≥ `MC_GATE_DELTA_MIN` (throughput real)
Reset al romper cualquiera. Tema: "la IA aprende tu patrón simétrico, estable y productivo".

i18n `BTN_MC_*`/`TOAST_MC_*` + lore `LORE_MENTE_*` actualizado (ES+EN).

**Pendiente Fase 5 (polish):** tuning (duración/cooldown de ráfaga, dureza del gate).

---

## No romper

- Logros: `red_micelial_activada`, `ruta_esporulacion`, meta seta+esporular.
- Legados: `semilla_cosmica`, `mente_colmena`, `resonancia_simbionte`,
  `deriva_esporada`, `micelio_resiliente`.
- `endings_achieved` (gate Trascendencia) — preservar nombres de ruta exactos.
- Carnaval reusa `red_micelial` phase 0 sin primordio → `_grow_micelio` con
  `is_colonization=false` mantiene el auto-fill legacy ahí. ✅ contemplado.
