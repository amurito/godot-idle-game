# HYPHAE: genesis — Compendio Matemático v1.0
## Todas las fórmulas, constantes, variables, modificadores y buffs del sistema

> **Fuente de verdad**: este documento se reconcilia con el código de [main.gd](../main.gd), [EcoModel.gd](../EcoModel.gd), [StructuralModel.gd](../StructuralModel.gd), [BiosphereEngine.gd](../BiosphereEngine.gd), [EconomyManager.gd](../EconomyManager.gd), [LegacyManager.gd](../LegacyManager.gd), [RunManager.gd](../RunManager.gd), [EvoManager.gd](../EvoManager.gd) y [upgrades/*.tres](../upgrades).
>
> Documentos previos integrados:
> - `modelo_matematico_v0.7.md` — fórmulas base (producción, μ, κμ, fⁿ, sigmoide)
> - `matematica_v0.8.md` — DLC fúngico (biosfera, biomasa, micelio, metabolismo)
> - `manual_ingenieria_viva.md` — interpretación física/biológica del modelo
> - `modelo_economico.md` — rutas evolutivas (estado conceptual)
> - `instituciones_epsilon_runtime.md` — ε_runtime e Instituciones
>
> **Convenciones**:
> - latinas minúsculas (a, b, d, e) → flujos de energía/dinero
> - griegas (μ, κ, ε, ω, β) → estructura / meta-sistema
> - subíndices (cₙ, ε_eff) → estado dinámico observado
> - superíndices (fⁿ) → función teórica esperada

---

## ÍNDICE

1. [Variables del sistema](#1-variables-del-sistema)
2. [Constantes globales](#2-constantes-globales)
3. [Producción — Δ$ total](#3-producción--δ-total)
4. [Persistencia estructural — cₙ, fⁿ, κμ](#4-persistencia-estructural--cₙ-fⁿ-κμ)
5. [Sigmoide de convergencia α(n)](#5-sigmoide-de-convergencia-αn)
6. [Capital cognitivo μ](#6-capital-cognitivo-μ)
7. [ε — Estrés estructural](#7-ε--estrés-estructural)
8. [Ω — Flexibilidad](#8-ω--flexibilidad)
9. [Biosfera fúngica — B, N, hifas, micelio](#9-biosfera-fúngica--b-n-hifas-micelio)
10. [Metabolismo](#10-metabolismo)
11. [Upgrades — costos y curvas](#11-upgrades--costos-y-curvas)
12. [Mutaciones y rutas — modificadores](#12-mutaciones-y-rutas--modificadores)
13. [Banco Genético (PL) — buffs de legado](#13-banco-genético-pl--buffs-de-legado)
14. [Banco Cósmico (Ξ) — buffs post-trascendencia](#14-banco-cósmico-ξ--buffs-post-trascendencia)
15. [Rutas post-trascendencia](#15-rutas-post-trascendencia)
16. [Cierre de run — PL y NG+ bonus](#16-cierre-de-run--pl-y-ng-bonus)
17. [Perturbaciones, resiliencia, homeostasis](#17-perturbaciones-resiliencia-homeostasis)
18. [Logros (achievements)](#18-logros-achievements)
19. [Apéndice — pipeline tick a tick](#19-apéndice--pipeline-tick-a-tick)

---

## 1. Variables del sistema

### 1.1 Económicas (`EconomyManager`)

| Símbolo | Variable código | Descripción | Valor inicial | Rango |
|---|---|---|---|---|
| $ | `money` | Dinero actual | 0.0 | ≥ 0 |
| $ₜ | `total_money_generated` | Dinero histórico total de la run | 0.0 | ≥ 0 |
| Δ$ | `delta_per_sec` | Producción agregada por segundo | 0.0 | ≥ 0 |
| μ_cache | `cached_mu` | μ recalculado por tick | 1.0 | ≥ 1 |
| t_click | `time_since_last_click` | Segundos desde último click | 0.0 | ≥ 0 |
| φ_paras | `parasitism_corrosion` | Factor de corrosión parasitaria | 1.0 | 0.0 → 1.0 |
| — | `mutation_auto_factor` | Multiplicador md vía mutaciones | 1.0 | — |
| — | `mutation_trueque_factor` | Multiplicador me vía mutaciones | 1.0 | — |
| — | `mutation_accounting_bonus` | Aditivo a accounting_effect | 0.0 | — |

### 1.2 Estructurales (`StructuralModel`)

| Símbolo | Variable código | Descripción | Inicial |
|---|---|---|---|
| cₙ | `persistence_dynamic` | Persistencia dinámica observada | 1.4 |
| c₀ | `persistence_base` | Persistencia base | 1.4 |
| η | `persistence_inertia` | Inercia (multiplicador de convergencia) | 1.0 |
| ε_rt | `epsilon_runtime` | Estrés runtime mezclado y amortiguado | 0.0 |
| ε_peak | `epsilon_peak` | Pico histórico de ε en la run | 0.0 |
| ε_act | `epsilon_active` | Componente activa (producción/composición) | 0.0 |
| ε_pas | `epsilon_passive` | Componente pasiva (rigidez/cristalización) | 0.0 |
| ε_cmp | `epsilon_complex` | Componente de complejidad estructural | 0.0 |
| ε_eff | `epsilon_effective` | ε después de absorción biosférica | 0.0 |
| Ω | `omega` | Flexibilidad del sistema | 1.0 |
| Ω_min | `omega_min` | Piso histórico de flexibilidad | 0.0 |

### 1.3 Biológicas (`BiosphereEngine`)

| Símbolo | Variable código | Descripción | Inicial | Cap |
|---|---|---|---|---|
| B | `biomasa` | Biomasa activa | 0.0 (+ buffs legado) | 8.0 / 10.0 / 20.0 |
| N | `nutrientes` | Nutrientes acumulados | 0.0 | — |
| H | `hifas` | Hifas (función de pasivo) | 0.0 | ~40 (asíntota) |
| M | `micelio` | Micelio cristalizado | 0.0 | 100.0 |
| a_abs | `absorption` | Coef. absorción ε | 0.15 | — |
| ε_b | `efficiency` | Coef. impacto en β(B) | 0.03 | — |
| p_pl | `plasticity` | Coef. plasticidad μ_fungi | 0.05 | — |

### 1.4 Meta / Legado (`LegacyManager`)

| Símbolo | Variable código | Descripción |
|---|---|---|
| PL | `legacy_points` | Puntos de Legado (moneda Banco Genético) |
| Ξ | `esencia` | Esencia Cósmica (moneda Banco Cósmico) |
| t | `trascendencia_count` | Cantidad de trascendencias acumuladas |
| — | `buffs` | `{id: {level, seen}}` |
| — | `cosmic_unlocked` | `{id: true}` |
| — | `endings_achieved` | `{nombre_ruta: true}` |

---

## 2. Constantes globales

| Const | Valor | Archivo | Uso |
|---|---|---|---|
| `K_PERSISTENCE` | 1.25 | StructuralModel | k base de κμ |
| `ALPHA_KAPPA` | 0.55 | StructuralModel | techo de α(n) por defecto |
| `COGNITIVE_MULTIPLIER` | 0.05 | StructuralModel | coef. log de μ (vía nivel cognitive) |
| `EPSILON_DEBUG_INTERVAL` | 0.25 | StructuralModel | throttle de logs |
| `STRUCTURAL_COOLDOWN_TIME` | 8.0 | StructuralModel | cooldown post-cambio estructural |
| `CLICK_RATE` | 1.0 | EconomyManager / main | factor multiplicador del click base |
| `EPS_PASSIVE_SCALE` | 0.24 | main.gd | escalamiento de ε pasivo |
| `PASSIVE_RATIO_START` | 0.60 | main.gd | umbral de pasivo_ratio para activar ε pasivo |
| `LOGIC_TICK` | 0.2 | RunManager | tick de lógica (5 Hz) |
| `UI_TICK` | 0.1 | main.gd | tick de UI (10 Hz) |
| `AUTOSAVE_INTERVAL` | 30.0 | main.gd | autoguardado en segundos |
| `PRE_HOMEOSTASIS_CAP` | 8.0 | BiosphereEngine | cap suave de biomasa pre-homeostasis |
| `BIOMASS_CAP` | 10.0 | BiosphereEngine | cap duro en homeostasis |
| `HOMEOSTASIS_TIME_REQUIRED` | 18.0 | RunManager | s para considerar homeostasis estable |
| `DISTURBANCE_INTERVAL` | 20.0 | RunManager | s entre perturbaciones |
| `ASCESIS_DURATION` | 300.0 | RunManager | s sostenidos para cerrar ASCESIS PROFUNDA |
| `ASCESIS_MIN_RUN_TIME` | 300.0 | Balance | gate de tiempo de ASCESIS (antes 900) |
| `ASCESIS_MONEY_REQ` | 10000000.0 | Balance | gate de dinero ASCESIS, solo clicks (antes 1M) |
| `ASCESIS_CLICK_TIMEOUT` | 10.0 | Balance | s máx sin click antes de pausar el timer (anti-AFK) |
| `CARNAVAL_INTERVAL` | 60.0 | RunManager | rotación de mutaciones en Carnaval |
| `MENTE_COLMENA_BUY_INTERVAL` | 8.0 | RunManager | s entre auto-buys IA |
| `PRIMORDIO_DURATION` | 90.0 | EvoManager | duración Primordio |
| `DEPREDADOR_STATUS_INTERVAL` | 10.0 | EvoManager | log de status Depredador |
| `MET_OSCURO_REQUIRED_TIME` | 15.0 | Balance | s sostenidos para activar Met. Oscuro (×0.6 con `arbol_acelerado`) |
| `MET_OSCURO_SEAL_COOLDOWN` | 120.0 | Balance | s mínimos activos antes de habilitar el sello |
| `MET_OSCURO_DEVOURED_REQ` | 10 | Balance | devorados necesarios para sellar Met. Oscuro |
| `MET_OSCURO_BIO_REQ` | 50.0 | Balance | biomasa necesaria para sellar Met. Oscuro |
| `DEPREDADOR_INESTABILIDAD_MAX` | 60.0 | EvoManager | s hasta implosión (COLAPSO DEPREDATORIO) |
| `DEP_TIME_EXTENSION` | 10.0 | Balance | s que resta al timer cada compra de ESTABILIZAR |
| `DEP_TIME_COST_BASE` | 40.0 | Balance | costo biomasa de la 1ª compra de ESTABILIZAR |
| `DEP_TIME_COST_GROWTH` | 1.8 | Balance | ×costo por compra acumulada (`depredador_timer_buys`) |
| `DEP_DEVOUR_MILESTONES` | [30,50,70,90] | Balance | hitos de devorado que restan tiempo al timer |
| `DEP_DEVOUR_MILESTONE_BONUS` | 10.0 | Balance | s restados al cruzar cada hito |
| `DEP_DEVOUR_TICK_BASE` | 1.5 | Balance | s entre devorados (inicio) |
| `DEP_DEVOUR_TICK_FAST` | 1.2 | Balance | s entre devorados tras `DEP_DEVOUR_TICK_FAST_AT` comidos |
| `DEP_DEVOUR_TICK_FAST_AT` | 50 | Balance | umbral de comidos para acelerar el tick |
| `PARASITISM_STATUS_INTERVAL` | 45.0 | main.gd | log status parásito |
| `TRASCENDENCIA_PL_GATE` | 50 | LegacyManager | PL requerido para 1ª trascendencia |

---

## 3. Producción — Δ$ total

### 3.1 Identidad fundamental

```
Δ$ = Δ$_click + Δ$_pasivo
Δ$_pasivo = d_eff + e_eff
```

### 3.2 Click — `get_click_power()`

```
Δ$_click  =  click_base · click_mult · cₙ · μ_cache
```

Con `click_base = UpgradeManager.value("click")` (base 1.0, +1 por nivel, lineal),
y `click_mult = UpgradeManager.value("click_mult")` (base 1.0, ×1.06 por nivel).

**Cadena de modificadores aplicados sobre el resultado anterior, en este orden:**

| # | Buff / Mutación | Operación |
|---|---|---|
| 1 | Legado `impulso_manual` | `click_base *= 2.0` (antes del cálculo) |
| 2 | Legado `sincronia_total` | `power *= β(B)` |
| 3 | Mutación `simbiosis` | `power *= 2.5` |
| 4 | Mutación `red_micelial` | `power *= 0.5` |
| 5 | Mutación `hyperassimilation` | `power *= 10.0` |
| 6 | Mutación `homeostasis` | `power *= 1.5` |
| 7 | Mutación `met_oscuro` | `power *= 3.0` |
| 8 | Legado `aura_dorada` | `power *= 2.5` |
| 9 | Cósmico `convergencia_ciclica` | `power *= (1 + t · 0.05)` |
| 10 | Legado `semilla_cosmica` | `power *= 2.0` |
| 11 | Legado `metabolismo_glitch` (si ε_rt > 0.40) | `power *= 1.50` |
| 12 | Mutación `parasitism` | `power *= parasitism_corrosion` |
| 13 | Legado `resonancia_simbionte` | `power *= min(1 + B·0.05, 2.5)` |
| 14 | Legado `simbiosis_agresiva` (si SIMBIOSIS+PARASITISMO) | `power *= 1.15` |
| 15 | Legado `eco_primordial` | `power *= 1.10` |
| 16 | Legado `resonancia_cognitiva` | `power *= (1 + acc_lvl · 0.05)` |
| 17 | Ruta `vacio_hambriento` | `power *= 100.0` |

### 3.3 Pasivo manual `d` (Trabajo Manual + Ritmo + Especialización)

```
d_eff = d · md · so · μ_cache · β(B) · (1 + acc_lvl · 0.05)
```

Donde:
- `d = UpgradeManager.value("auto")` — lineal, +1 por nivel
- `md = UpgradeManager.value("auto_mult") · mutation_auto_factor` — base 1.0, ×1.06 por nivel
- `so = UpgradeManager.value("specialization")` — base 1.0, ×1.10 por nivel
- `acc_lvl = UpgradeManager.level("accounting")`

Adicionales:
- Legado `inercia_escala`: `md *= (1 + acc_lvl · 0.05)`
- Mutación `allostasis`: `d_eff *= 5.0`

### 3.4 Pasivo de red `e` (Trueque)

```
e_raw  = trueque · 6.0 · 0.75 (configurado vía gain del .tres)
e_eff  = e_raw · me · μ · β(B) · (1 + acc_lvl · 0.05)
```

Con `me = UpgradeManager.value("trueque_net") · mutation_trueque_factor · trueque_allo`.

`trueque_allo`: si `level > 0` → `value` (base 1.0, ×2.0 por nivel, cost_scale 3.5).

Adicionales:
- Legado `red_confianza`: `e_eff *= 1.10`

### 3.5 Pasivo total — `get_passive_total()`

```
P = d_eff + e_eff
```

**Cadena de modificadores sobre P** (orden de aplicación):

| Buff / Mutación | Operación |
|---|---|
| Legado `redireccion_energia` | `P += click_power · 0.10` |
| Mut. `simbiosis` | `P *= 0.5` |
| Mut. `red_micelial` | `P *= 2.5` |
| Mut. `hyperassimilation` | `P *= 0.25` |
| Mut. `homeostasis` | `P *= 1.5` |
| Mut. `parasitism` | `P *= 1.2 · parasitism_corrosion` |
| Mut. `met_oscuro` | `P = 0.0` (ingreso solo desde biomasa) |
| Legado `semilla_cosmica` | `P *= 2.0` |
| Legado `mente_colmena` | `P *= 3.0` |
| Legado `metabolismo_glitch` (si ε_rt > 0.40) | `P *= 1.80` |
| Cósmico `convergencia_ciclica` | `P *= (1 + t · 0.05)` |
| Rama `COLONIZATION` | `P *= 2.5` |
| Legado `glitch_persistente` (red_micelial o nucleo_conciencia) | `P *= 1.15` |
| Legado `simbiosis_agresiva` | `P *= 1.15` |
| Legado `eco_primordial` | `P *= 1.10` |
| Legado `resonancia_cognitiva` | `P *= (1 + acc_lvl · 0.05)` |
| Ruta `vacio_hambriento` | `P *= 100.0` |

---

## 4. Persistencia estructural — cₙ, fⁿ, κμ

### 4.1 n efectivo

```
n_struct_raw = Σ niveles de upgrades estructurales
n_eff        = n_struct_raw / (1 + acc_lvl · 0.3)
```

Upgrades que cuentan (`get_structural_upgrades()`):
- `auto`, `auto_mult`, `trueque`, `trueque_net`, `cognitive`, `accounting`, `specialization`
- `trueque_allo` × 3 (peso triple)
- `+5` si `persistence_upgrade_unlocked`

### 4.2 k base, α(n), κμ

```
k_base(n) = 1.05 + log(1 + n) · 0.05    [cap 1.25]
α(n)      = 0.10 + log(1 + n) · 0.12    [cap 0.55]
κμ = k_base(n) · (1 + α(n) · (μ - 1))
```

**Legado `horizonte_estructural`** levanta el suelo y elimina el cap:
- `k_base` floor pasa de 1.05 a 1.25 (sin cap)
- `α(n)` floor pasa de 0.10 a 0.55 (sin cap)

### 4.3 fⁿ — Persistencia teórica

```
fⁿ = c₀ · κμ^(1 - 1/n)        si n > 1
fⁿ = c₀                       si n ≤ 1
```

### 4.4 cₙ — Persistencia dinámica observada

```
cₙ(t+Δt) = lerp(cₙ, fⁿ, clamp(α_sigmoid · Δt · 0.4 · η · (1 + s_conv), 0, 0.25))
```

Donde:
- `α_sigmoid = f_n_alpha(n_struct_raw)` (ver §5)
- `η = persistence_inertia` (default 1.0)
- `s_conv = LegacyManager.get_effect_value("persistence_conv_speed")` — `deriva_controlada` aporta `0.40`

### 4.5 Upgrade `persistence`

- Eleva `persistence_base` (c₀) en `+0.25` por compra (gain = 1.25, multiplicativo).
- Base price 10.000, cost_scale 1.0 (no escala — el costo fijo se compensa con `pow(1.5, lvl)` en `purchase_upgrade`).

### 4.6 ε del modelo (diagnóstico)

```
ε_modelo = |fⁿ - cₙ_modelo|
```

En el código `cₙ_modelo = fⁿ` (snapshot teórico), por lo que `ε_modelo ≈ 0` salvo transiciones. Es la base de la sección "ε" del HUD modelo, no afecta gameplay.

---

## 5. Sigmoide de convergencia α(n)

```
α_sigmoid(n) = 1 / (1 + exp(-0.35 · (n - 6)))
```

| Fase | n | α_sigmoid | Síntoma |
|---|---|---|---|
| Temprana | < 6 | < 0.5 | convergencia lenta de cₙ → fⁿ |
| Transición | ≈ 6 | 0.5 | inflexión |
| Madura | > 10 | → 1.0 | adopción casi instantánea |

Parámetros jugables a futuro:
- **0.35** (pendiente) — abrupto vs gradual
- **6** (centro) — momento de la transición

---

## 6. Capital cognitivo μ

### 6.1 Definición base

```
μ_cog(n_cog) = 1 + log(1 + n_cog) · COGNITIVE_MULTIPLIER
             = 1 + log(1 + n_cog) · 0.05            (vía StructuralModel.get_cognitive_mu)
```

Nota: el otro path `get_mu_structural_factor()` usa `0.08` (no `0.05`) — éste es el μ que entra en cálculos económicos:

```
μ_base = 1 + log(1 + nivel_cognitive) · 0.08
μ_fungi = 1 + log(1 + B) · plasticity   [con plasticity = 0.05]
μ_total = μ_base · μ_fungi
```

### 6.2 Modificadores de μ_total

| Modificador | Operación | Origen |
|---|---|---|
| Mutación `hyperassimilation` | `μ_fungi *= 0.85` | BiosphereEngine |
| Mutación `homeostasis` | `plasticity *= 0.5` | BiosphereEngine |
| Contabilidad | `μ_total *= (1 + acc_lvl · 0.08)` | StructuralModel |
| Resiliencia (`homeostasis_mode`) | `μ_total *= (1 + min(resilience/300, 1) · 0.30)` | StructuralModel |

`μ_cache` (en `EconomyManager`) es el snapshot recalculado por tick.

### 6.3 Acoplamiento μ → estructura

```
κμ depende de μ vía α(n)·(μ-1)
β(B) depende de μ vía plasticity (composición μ_fungi)
```

---

## 7. ε — Estrés estructural

### 7.1 Componentes (`update_epsilon_runtime` en main.gd:1404)

**ε_activo** (producción vs composición esperada):

```
expected_Δ$    = baseline_struct · κμ^(1 - 1/n_eff)
ε_prod         = max(0, (Δ$_actual / expected_Δ$) - 1)
ratio_activo   = click / (click + pasivo)
target_activo  = lerp(0.8, 0.4, clamp(n_eff/40, 0, 1))
ε_comp         = |ratio_activo - target_activo| · (1 - acc_effect)
decay          = clamp(1 - t_click/5, 0, 1)       [si no se clickea 5s+, ε_activo → 0]
ε_activo       = (ε_prod + ε_comp) · decay
```

**ε_pasivo** (rigidez si el sistema es demasiado pasivo):

```
si ratio_pasivo > 0.60:
    excess     = ratio_pasivo - 0.60
    rigidity   = 1 - Ω
    size_fact  = log(1 + n_eff) · 0.45
    ε_pasivo   = excess · size_fact · rigidity · 0.24 · (1 - acc_effect)
sino:
    ε_pasivo   = 0
```

**ε_complejidad** (complejidad estructural intrínseca):

```
ε_cmp = 0.0012 · n_eff · κμ
```

### 7.2 ε_runtime — mezcla y amortiguación

```
ε_raw     = ε_activo + ε_pasivo + ε_cmp

bio_absorption = clamp(ε_eff / ε_rt, 0.4, 1.0)    [si biosfera está enfriando]
                 = 1.0                              [si no]

ε_rt(t+Δt) = lerp(ε_rt, ε_raw · bio_absorption, 0.045)
ε_rt       = clamp(ε_rt, 0, 2)

si COLONIZATION: ε_rt = max(ε_rt, 0.25)
ε_peak     = max(ε_peak, ε_rt)
```

### 7.3 ε_efectivo — absorción biosférica

(Calculado en `BiosphereEngine._compute_epsilon_breakdown`)

| Caso | Fórmula |
|---|---|
| `hifas ≤ 0` | `ε_eff = ε_rt` |
| Hiperasimilación | `ε_eff = ε_rt · (1 + B · 0.25)`  *(feedback positivo: amplifica)* |
| Simbiosis | `ε_eff = ε_rt · 0.25`  *(disipa 75%)* |
| Estándar (con biomasa) | `ε_eff = ε_rt / (1 + B · 0.5)` |

### 7.4 Lectura cualitativa

| ε_rt | Estado |
|---|---|
| < 0.05 | Alineado |
| 0.05 – 0.15 | Fricción leve |
| 0.15 – 0.30 | Tensionado |
| > 0.30 | Estrés estructural |
| ε_rt > 0.90 ∧ Ω > 0.30 | Gate de **COLAPSO CONTROLADO** (con `fractura_epistemica` cósmico) |

### 7.5 accounting_effect

```
acc_effect = acc_lvl · 0.05
           + mutation_accounting_bonus
           + (0.05 si legacy_homeostasis)
```

### 7.6 Presión estructural (diagnóstico)

```
pressure_raw = ε_eff · (1 + ε_peak) · n_struct
pressure_mit = pressure_raw · (1 - acc_effect)
```

---

## 8. Ω — Flexibilidad

### 8.1 Cálculo base

```
denom = 1 + ε_rt · κμ · n_eff^0.85
Ω     = 1 / max(denom, 0.0001)
```

(El exponente `0.85` suaviza el impacto de n para evitar cristalización temprana.)

### 8.2 Ω_min y techos/pisos por ruta

`Ω_min` se actualiza: `move_toward(Ω_min, Ω, 0.002)` si Ω > Ω_min.
Tras eso, `Ω = max(Ω, Ω_min)` (Ω_min protege el piso real).

**Pisos**:

| Condición | Piso aplicado a Ω |
|---|---|
| `mutation_homeostasis` | `Ω_min ≥ 0.35` |
| `mutation_allostasis` | `Ω ≥ 0.60` |
| Legado `legado_homeorresis` | `Ω ≥ 0.55` |
| Legado `legado_alostasis` | `Ω ≥ 0.45` |
| Legado `plasticidad_adaptativa` | `Ω_min ≥ 0.30` |
| Cósmico `omega_primordial` | `Ω_min += 0.05` al inicio |
| Rama `SYMBIOSIS` | `Ω ≥ 0.50` |

**Techos**:

| Condición | Techo |
|---|---|
| `mutation_parasitism` | `Ω ≤ 0.25`, `Ω_min ≤ 0.25` |
| `mutation_hyperassimilation` | `Ω ≤ 0.75`, cₙ decae hacia 1.0 |
| Met. Oscuro | `Ω ≤ 0.10` (techo duro) |

---

## 9. Biosfera fúngica — B, N, hifas, micelio

### 9.1 Hifas

```
H_raw = passive_income^0.6
H     = H_raw / (1 + H_raw/40)        [asíntota suave en ~40]
si homeostasis: H *= 0.85
```

### 9.2 Nutrientes

```
diff = ε_rt - ε_eff

si diff > 0:        N += diff · 12 · Δt        [absorción genera N]
si ε_eff > ε_rt:    N -= (ε_eff - ε_rt) · 25 · Δt   [hiperasimilación gasta N]
N = max(N, 0)
```

### 9.3 Biomasa

```
gain = hifas · √N · 0.02 · Δt
si parasitism: gain *= 2.0
si legado absorcion_mejorada: gain *= (1 + 0.20·level)

B += gain
N -= gain · 0.5
```

**Caps de biomasa** (Δt-relajación con lerp):

| Estado | Cap | Modo |
|---|---|---|
| Colonización | 20.0 | lerp suave (15% · Δt · 60) |
| Pre-homeostasis (otras ramas) | 8.0 | lerp suave (15% · Δt · 60) |
| Homeostasis | 10.0 | clamp duro |
| Parasitismo / Hiperasimilación | sin cap | — |

### 9.4 Micelio (Tier 2)

Solo activo en `is_red_micelial == true`:

```
si hifas ≥ 5: M = min(M + hifas · 0.4 · Δt, 100)
si hifas < 5: M = max(M - 1.5 · Δt, 0)
```

### 9.5 β(B) — multiplicador biosférico

```
β(B) = 1 + log(1 + B) · efficiency        [efficiency = 0.03 base]

si legado micelio_resiliente:
    β = max(β, beta_floor)        [floor = 1.0]
```

`β(B)` se aplica a `d_eff`, `e_eff` y (con `sincronia_total`) al click.

### 9.6 μ_fungi

```
p = plasticity (0.05)
si homeostasis: p *= 0.5
μ_fungi = 1 + log(1 + B) · p
si hyperassimilation: μ_fungi *= 0.85
```

### 9.7 Esporulación

```
spores = B · 0.8
si seta_formada (ciclo biológico): spores *= 3.0

post-evento:
    B *= 0.1
    H *= 0.1
    N += spores · 1.5
```

### 9.8 Buffs permanentes en biosfera (parasitismo)

`apply_parasitism_buffs()`:
- `absorption *= 1.6`
- `efficiency *= 1.3`

---

## 10. Metabolismo

Indicador, no variable persistente:

```
M_health = B / Δ$
```

| M_health | Estado |
|---|---|
| > 0.12 | Estable |
| 0.06 – 0.12 | Forzado |
| 0.03 – 0.06 | Agotado |
| < 0.03 | Crítico (pre-colapso) |

---

## 11. Upgrades — costos y curvas

### 11.1 Definiciones base (de `upgrades/*.tres`)

| id | label | base_cost | cost_scale | gain | mult? | base_value | requiere |
|---|---|---|---|---|---|---|---|
| `click` | Mejorar click | 5 | 1.5 | 1.0 | no | 1.0 | — |
| `click_mult` | Memoria Numérica | 200 | 1.4 | 1.06 | sí | 1.0 | — |
| `auto` | Trabajo Manual | 10 | 1.6 | 1.0 | no | 0.0 | — |
| `auto_mult` | Ritmo de Trabajo | 1.200 | 1.2 | 1.06 | sí | 1.0 | — |
| `specialization` | Especialización de Oficio | 9.000 | 1.35 | 1.10 | sí | 1.0 | — |
| `trueque` | Trueque | 3.000 | 1.45 | 6.0 | no | 0.0 | — |
| `trueque_net` | Red de Intercambio | 6.000 | 1.35 | 1.12 | sí | 1.0 | — |
| `trueque_allo` | Escalado Alostático | 25.000 | 3.5 | 2.0 | sí | 1.0 | — |
| `cognitive` | Capital Cognitivo (μ) | 15.000 | 1.45 | 1.0 | no | 0.0 | `trueque_net` |
| `accounting` | Contabilidad Básica | 10.000 | 2.0 | 1.0 | no | 0.0 | — |
| `persistence` | Memoria Operativa (c₀ +25%) | 10.000 | 1.0 | 1.25 | sí | 1.4 | — |

### 11.2 Curvas de costo

**Aditivos** (`is_multiplicative = false`): `value(lvl) = base_value + lvl · gain`
**Multiplicativos** (`is_multiplicative = true`): `value(lvl) = base_value · gain^lvl`

Costo en compra (incremento aplicado al estado tras pago):

```
cost(lvl)     = base_cost · cost_scale^lvl · 1.5^lvl       (modelo efectivo)
```

Con `effective_cost_scale` modulada por:

| Modificador | Operación sobre `cost_scale` |
|---|---|
| Legado `deflacion` (`price_scaling_mult` 0.95) | `effective = 1 + (cs - 1) · 0.95` |
| Cósmico `deflacion_cosmica` (8% adicional) | (etapa similar — `deflacion_cosmica` opera vía `price_scaling_mult`) |
| Legado `memoria_estructural` (`structural_cost_reduction`) | `-0.05 · level` por compra (`1 - reducción`) |
| Legado `presion_rentable` (si ε_rt activo) | descuento `0.80` (paga 80% del precio) |

Adicionalmente: el `purchase_upgrade` multiplica el estado por `effective_cost_scale * 1.5` por compra (componente exponencial duro garantizado).

### 11.3 Helpers de coste especial

- Cósmico `memoria_persistente`: primer nivel de `accounting` y `trueque` gratuitos al inicio de la run.
- Legado `memoria_recurso`: primer productor (click, auto o trueque) sin coste por run.

---

## 12. Mutaciones y rutas — modificadores

### 12.1 Mutaciones Tier 1 (multiplicadores directos sobre producción)

| Mutación | Click | Pasivo (P) | Notas adicionales |
|---|---|---|---|
| **simbiosis** | ×2.5 | ×0.5 | ε_eff disipado al 25% (absorción 75%) |
| **red_micelial** | ×0.5 | ×2.5 | habilita crecimiento de micelio |
| **hyperassimilation** | ×10.0 | ×0.25 | Ω ≤ 0.75; cₙ decae a 1.0; ε_eff amplifica con B |
| **homeostasis** | ×1.5 | ×1.5 | Ω_min ≥ 0.35; plasticity μ_fungi ×0.5; cap duro B = 10 |
| **parasitism** | ×corrosión | ×1.2·corrosión | Ω ≤ 0.25; B sin cap; biomasa crece ×2.0 |
| **allostasis** | (vía pasivo) | d_eff ×5.0 | Ω ≥ 0.60 (piso adaptativo) |
| **homeorhesis** | — | — | (estado conceptual, gate via legado_homeorresis) |
| **met_oscuro** | ×3.0 | =0 (ingreso solo biomasa) | Ω ≤ 0.10 |
| **depredador** | — | — | NG+ post-PARASITISMO; timer de inestabilidad + 3 salidas → ver §15.4 |
| **sporulation** | — | — | trigger de cierre vía esporulación |

### 12.2 Ramas Red Micelial (`EvoManager.RedBranch`)

| Rama | Efecto |
|---|---|
| `COLONIZATION` | Pasivo ×2.5; ε_rt piso 0.25; cap biomasa elevado a 20 |
| `SYMBIOSIS` | Ω piso 0.50 |

### 12.3 Corrosión parasitaria

`parasitism_corrosion` converge de 1.0 hacia 0.0 mientras la mutación está activa. Multiplicador uniforme sobre click y pasivo.

---

## 13. Banco Genético (PL) — buffs de legado

> Categorías: ECONOMÍA, ESTRUCTURA, BIOLOGÍA, CONOCIMIENTO, RUTAS, NG+, ???
> Toggle on/off por buff. Default ON al comprar.

### 13.1 Economía

| id | nombre | costo PL | max | efecto |
|---|---|---|---|---|
| `deflacion` | Deflación Biótica | 4 | 1 | `price_scaling_mult = 0.95` |
| `memoria_recurso` | Memoria de Recurso | 5 | 1 | primer productor de cada categoría gratis |
| `red_confianza` | Red de Confianza | 3 | 1 | `trueque_efficiency_add = +0.10` |
| `impulso_manual` | Impulso Manual | 3 | 1 | `click_base_add = +1.0` (×2 del base) |
| `redireccion_energia` | Redirección de Energía | 5 | 1 | `click_to_passive_ratio = 0.10` (10% del click va a P) |
| `legado_metabolico` | Legado Metabólico | 3 (×1.40, max 5) | 5 | `run_start_money = +150` por nivel |
| `sincronia_total` | Sincronía Total | 7 | 1 | `beta_affects_click = 1.0` (β afecta click) |

### 13.2 Estructura

| id | nombre | costo | max | efecto |
|---|---|---|---|---|
| `inercia_escala` | Inercia de Escala | 6 | 1 | `accounting_md_bonus = 0.05` por nivel |
| `horizonte_estructural` | Horizonte Estructural | 10 | 1 | elimina cap de κμ y α |
| `deriva_controlada` | Deriva Controlada | 5 | 1 | `persistence_conv_speed = 0.40` (+40% velocidad) |
| `plasticidad_adaptativa` | Plasticidad Adaptativa | 6 | 1 | `omega_min_floor = 0.30` |
| `memoria_estructural` | Memoria Estructural | 4 (×1.40, max 3) | 3 | `structural_cost_reduction = 0.05` por nivel |

### 13.3 Biología

| id | nombre | costo | max | efecto |
|---|---|---|---|---|
| `absorcion_mejorada` | Absorción Mejorada | 4 (×1.50, max 2) | 2 | `nutrient_absorb_mult = +0.20` por nivel |
| `hifas_persistentes` | Hifas Persistentes | — | 1 | `start_biomasa = +0.5` |
| `micelio_resiliente` | Micelio Resiliente | — | 1 | `beta_floor = 1.0` |

### 13.4 Conocimiento

| id | efecto |
|---|---|
| `observatorio_genomico` | `unlock_hidden_achievements` |
| `analisis_de_tension` | `show_epsilon_detail` |
| `memoria_de_run` | `show_run_history` |
| `predictor_estructural` | `warn_epsilon_threshold` |
| `slot_extra` | `unlock_save_slot` |

### 13.5 Rutas

| id | efecto |
|---|---|
| `presion_rentable` | descuento 0.80 en upgrades de click cuando ε_rt activo |
| `equilibrio_heredado` | `omega_min_per_disturbance = +0.04` |
| `sangre_negra` | biomasa inicial en parasitismo ×1.30 |
| `resonancia_simbionte` | click ×(1+B·0.05), cap ×2.5 |
| `deriva_esporada` | `pl_gain_mult = ×1.25` |
| `umbral_cognitivo` | `start_nivel_cognitivo_bonus = +1` |
| `umbral_adaptativo` | `disturbance_recovery_speed = ×1.40` |
| `cristalizacion_permanente` | `omega_shock_reduction = ×0.50` |
| `eco_panspermico` | `start_biomasa = +1.0` |
| `simbiosis_agresiva` | ×1.15 a click y pasivo si SIMBIOSIS+PARASITISMO completadas |
| `colapso_controlado` | `epsilon_peak_pl_bonus = 2.0` (PL extra por ε_peak al cerrar) |
| `resonancia_cognitiva` | `cognitivo_income_mult_per_level = 0.05` (a click y pasivo) |
| `entropia_domesticada` | `entropia_domesticada_mult = 2.0`: si ε_rt > 0.65, click y pasivo ×`clampf(1+(ε−0.65)·2, 1, 2)` (~×1.7 a ε=1.0). Reveal+unlock: cerrar **COLAPSO CONTROLADO** |

### 13.6 NG+ / Trascendencia (revealed por hitos)

| id | efecto |
|---|---|
| `legado_alostasis` | Ω ≥ 0.45 permanente |
| `legado_homeorresis` | Ω ≥ 0.55 permanente |
| `semilla_cosmica` | click ×2.0, P ×2.0 |
| `mente_colmena` | P ×3.0 + auto-buy de upgrades |
| `metabolismo_glitch` | si ε_rt > 0.40: click ×1.50, P ×1.80 |
| `aura_dorada` | click ×2.5 |
| `glitch_persistente` | P ×1.15 si red_micelial o nucleo_conciencia |
| `setpoint_adaptativo` | `omega_recovery_speed = ×1.50` |
| `eco_primordial` | `all_income_mult = +0.10` |

---

## 14. Banco Cósmico (Ξ) — buffs post-trascendencia

| id | costo Ξ | tier | efecto |
|---|---|---|---|
| `impulso_inicial` | 6 | 1 | $500 de inicio |
| `omega_primordial` | 8 | 1 | Ω_min +0.05 al inicio |
| `resonancia_biotica` | 10 | 1 | biomasa inicial +1.5 |
| `deflacion_cosmica` | 12 | 1 | escalado de precios -8% adicional |
| `eco_de_legado` | 15 | 1 | +5 PL al inicio de cada run |
| `arbol_acelerado` | 18 | 2 | timers MET.OSCURO y DEPREDADOR -40% |
| `memoria_persistente` | 22 | 2 | accounting nivel 1 + trueque nivel 1 gratis |
| `convergencia_ciclica` | 28 | 2 | click y pasivo ×(1 + t · 0.05) |
| `fractura_epistemica` | 35 | 3 | desbloquea COLAPSO CONTROLADO (gate: `ε_rt > 0.90 ∧ Ω > 0.30`) |
| `sustrato_cosmico` | 50 | 3 | próxima trascendencia ×2 Ξ (one-shot) |

Gate inicial: `TRASCENDENCIA_PL_GATE = 50` PL para la primera trascendencia.

---

## 15. Rutas post-trascendencia

### 15.1 VACÍO HAMBRIENTO

```
vacio_hambriento_active = true
vacio_hambriento_mult   = 100.0   [click y pasivo ×100]
ASCESIS_DURATION        = 300 s
```

Tradeoff: consume buffs cósmicos al activar; produce ASCESIS_PROFUNDA si se completa.

#### ASCESIS PROFUNDA (sub-cierre de Vacío Hambriento) — rework anti-AFK

Renuncia ACTIVA: sin pasivo, sin biósfera, dinero solo por clicks.

```
Gate de entrada (ambos):
  run_time  >= ASCESIS_MIN_RUN_TIME  = 300 s
  money     >= ASCESIS_MONEY_REQ     = 10_000_000   [solo por clicks: pasivo prohibido]

Sostener ASCESIS_DURATION = 300 s con TODAS:
  biomasa < 0.5
  level(auto) == 0 and level(trueque) == 0      [sin pasivo]
  epsilon_runtime < 0.25
  time_since_last_click < ASCESIS_CLICK_TIMEOUT = 10 s   [anti-AFK: si se va, el timer se PAUSA]
```

Si falla cualquier condición el timer se pausa (no resetea). Reward: +7 PL + logro Mythic "Vacío Absoluto".
Diseño previo (abandonado): gate de 900s + $1M → AFK puro (el $1M llegaba en <3 min y el resto era espera muerta).

### 15.2 CARNAVAL DE MUTACIONES

```
CARNAVAL_POOL     = ["homeostasis", "simbiosis", "red_micelial", "parasitismo", "hiperasimilacion"]
CARNAVAL_INTERVAL = 60 s         [rota a la siguiente mutación]
3 mutaciones aleatorias rotando hasta cerrar la run.
```

Métricas tracked:
- `carnaval_total_rotations` — gate para POLIMORFÍA TOTAL
- `carnaval_peak_money` — gate para DOMADOR DEL CAOS

### 15.3 REENCARNACIÓN HEREDADA

Snapshot `reencarnacion_snapshot` (UpgradeManager serializado al trascender). Al iniciar la run próxima se aplica el snapshot.

### 15.4 Árbol Depredador (NG+, post-PARASITISMO)

Al activarse la mutación `depredador` arranca `depredador_inestabilidad` (cuenta de 0 → `DEPREDADOR_INESTABILIDAD_MAX = 60s`). Cada `DEP_DEVOUR_TICK` se devora un upgrade (`devour_random_upgrade()` reduce nivel en 1, no borra → se puede recomprar para "realimentar"). Cada devorado: `B += 15`, `met_oscuro_devoured_count += 1`. Tres salidas con identidad propia:

| Salida | Condición | PL |
|---|---|---|
| **COLAPSO DEPREDATORIO** | el timer llega a `MAX` sin resolver → implosión. Reactor a rojo casi negro `Color(0.12,0,0.02)` | 8 |
| **DEPREDADOR DE REALIDADES** | `devour_random_upgrade()` retorna `false` (todo a nivel 0 antes del timer) | 12 |
| **METABOLISMO OSCURO** (sello) | sostener `devorados ≥ MET_OSCURO_DEVOURED_REQ(10) ∧ B ≥ MET_OSCURO_BIO_REQ(50)` durante `MET_OSCURO_REQUIRED_TIME(15s)` | sella (ver §16) |

**Velocidad de devorado:** `DEP_DEVOUR_TICK_BASE = 1.5s`, baja a `DEP_DEVOUR_TICK_FAST = 1.2s` tras `DEP_DEVOUR_TICK_FAST_AT = 50` comidos.

**Ayudas al timer** (restan a `depredador_inestabilidad`, clamp en 0):
- **Botón ESTABILIZAR** (`RightPanel`): resta `DEP_TIME_EXTENSION = 10s` pagando biomasa. Costo `DEP_TIME_COST_BASE(40) · DEP_TIME_COST_GROWTH(1.8)^depredador_timer_buys`. Se auto-oculta si run cerrada, no-depredador o met_oscuro activo.
- **Hitos de devorado** `DEP_DEVOUR_MILESTONES = [30,50,70,90]`: cada uno resta `DEP_DEVOUR_MILESTONE_BONUS = 10s`. Se cruzan exactamente una vez (`count in MILESTONES`).

**Persistencia:** `depredador_inestabilidad` y `depredador_timer_buys` se guardan en SaveManager (bloque `evolution`).

---

## 16. Cierre de run — PL y NG+ bonus

### 16.1 PL base por ruta (`close_run`)

| Ruta | PL base |
|---|---|
| HOMEOSTASIS | 3 |
| ALLOSTASIS | 4 |
| HOMEORHESIS | 8 |
| SIMBIOSIS | 4 |
| SINGULARIDAD | 6 + bonus_ε (otorgado en main.gd) |
| ESPORULACIÓN / TOTAL | 5 |
| PARASITISMO | 2 |
| HIPERASIMILACIÓN | 1 |
| METABOLISMO OSCURO / MUTACION_FINAL | 4 |
| MENTE COLMENA DISTRIBUIDA | 8 |
| DEPREDADOR DE REALIDADES | 12 |
| COLAPSO DEPREDATORIO | 8 |
| PANSPERMIA NEGRA | 0 (PL otorgado en main.gd) |
| COLAPSO CONTROLADO | 6 |
| POLIMORFÍA TOTAL | 9 |
| DOMADOR DEL CAOS | 11 |
| ASCESIS_PROFUNDA | 7 |

### 16.2 PL bonus por buff `colapso_controlado`

```
extra_PL = floor(ε_peak · epsilon_peak_pl_bonus)
         = floor(ε_peak · 2.0)
```

### 16.3 NG+ bonus (si `trascendencia_count ≥ 1`)

| Ruta | Fórmula NG+ | Cap |
|---|---|---|
| HOMEOSTASIS | `floor(resilience / 50)` | 6 |
| SIMBIOSIS | `floor(run_time / 300)` | 6 |
| HIPERASIMILACIÓN | `floor(ε_peak · 5)` | 5 |
| PARASITISMO | `floor(B / 8)` | 4 |
| ESPORULACIÓN | `floor(M / 20)` | 5 |
| ALLOSTASIS | `disturbances_survived` | 5 |
| HOMEORHESIS | `floor(omega_min_peak · 10)` | 7 |
| METABOLISMO OSCURO | `devoured · 2` | 8 |
| POLIMORFÍA TOTAL | `floor(rotaciones / 2)` | 8 |
| DOMADOR DEL CAOS | `floor(peak_money / 500K)` | 8 |
| ASCESIS PROFUNDA | `floor(omega_min_peak · 10)` | 6 |
| MENTE COLMENA DIST. | `floor(run_time / 600)` | 8 |
| DEPREDADOR | `devoured` | 8 |
| COLAPSO DEPREDATORIO | `devoured · 2` | 5 |
| PANSPERMIA NEGRA | `floor(M / 20)` | 6 |

PL final: `PL_base + PL_bonus_colapso + NG+_bonus` (multiplicado por `pl_gain_mult` si `deriva_esporada` está activo).

### 16.4 Trascendencia

- Requiere haber cerrado al menos 1 ruta de cada familia (ENDING_FAMILIES: orden, biología, colapso) — gate aproximado.
- Reset de PL/upgrades; preserva Ξ acumulado.
- Otorga Ξ según ruta cerrada.
- `sustrato_cosmico` activo: Ξ otorgada ×2 (consumible).

---

## 17. Perturbaciones, resiliencia, homeostasis

### 17.1 Disturbance

```
DISTURBANCE_INTERVAL = 20 s

shock ∈ [0, 1]      [magnitud aleatoria]
extreme = (shock > 0.8)
```

Efectos del shock:
- Reduce `Ω` temporalmente (modulado por `cristalizacion_permanente`: `×0.5`)
- Empuja `ε_rt` hacia arriba
- Si se mantiene `en_banda_homeostatica`, suma `resilience_score`

Recovery speed: `disturbance_recovery_speed = 1.40` con `umbral_adaptativo`.

### 17.2 Banda homeostática

```
en_banda = (0.03 ≤ ε_eff ≤ 0.30)
```

### 17.3 Resilience score

Acumula por cada tick en banda con shocks superados. Cap implícito en `300` para el bonus de μ (`min(res/300, 1) · 0.30`).

### 17.4 Homeostasis mode

```
HOMEOSTASIS_TIME_REQUIRED = 18 s en banda → habilita homeostasis_mode
```

Gate para Tier 2 (ALLOSTASIS, HOMEORHESIS).

---

## 18. Logros (achievements)

> Fuente: [AchievementManager.gd](../AchievementManager.gd). Catálogo `DEFS`: 50+ entradas en 5 tiers. Persistencia en `legacy_bank.json` vía `LegacyManager.save_achievement_data()`.

### 18.1 Tiers

| Tier | Enum | Color (RGB) | Ícono | Uso |
|---|---|---|---|---|
| MICELIO | 0 | (0.72, 0.48, 0.25) marrón | 🟤 | onboarding, primeros hitos |
| ESPORA | 1 | (0.90, 0.90, 0.92) blanco | ⚪ | progresión media, primeras rutas |
| FRUTO | 2 | (1.00, 0.80, 0.25) dorado | 🟡 | hitos avanzados, optimización |
| ANCESTRAL | 3 | (0.85, 0.20, 0.30) rojo | 🔴 | desafíos endgame, secretos |
| MYTHIC | 4 | (0.55, 0.10, 0.85) violeta | 🟣 | rutas exóticas, meta-logros |

### 18.2 Trigger types

| Tipo | Schema | Cómo dispara |
|---|---|---|
| `threshold` | `metric, target` | snapshot[metric] ≥ target una vez |
| `sustained` | `metric, op, target, duration` | snapshot[metric] op target sostenido N segundos (timer en `_timers`) |
| `sustained_between` | `metric, min, max, duration` | snapshot[metric] ∈ [min,max] N segundos |
| `event` | `event_name, conditions?` | `push_event(event_name)` con conditions match |
| `event_count` | `event_name, target` | acumula en `_progress[id]`, dispara al llegar a target |
| `custom` | `evaluator, duration?` | callable en `CUSTOM_EVALUATORS[evaluator]`; con duration usa timer |

### 18.3 Toast levels

| `toast` | UI |
|---|---|
| `silent` | sin popup (logros de onboarding) |
| `small` | popup discreto |
| `full` | popup normal |
| `legendary` | popup destacado (ANCESTRAL/MYTHIC + key) |

### 18.4 Snapshot — métricas disponibles

`push_snapshot(data)` se llama cada UI tick desde `main.gd`. Keys relevantes para evaluadores:

| Key | Tipo | Fuente |
|---|---|---|
| `total_money` | float | `EconomyManager.total_money_generated` |
| `money` | float | `EconomyManager.money` |
| `delta_total` | float | `EconomyManager.delta_per_sec` |
| `epsilon` | float | `StructuralModel.epsilon_effective` |
| `k_eff` | float | `StructuralModel.get_k_eff()` |
| `biomasa` | float | `BiosphereEngine.biomasa` |
| `hifas` | float | `BiosphereEngine.hifas` |
| `resilience_score` | float | `RunManager.resilience_score` |
| `trascendencia_count` | float | `LegacyManager.trascendencia_count` |
| `dominant_term` | String | `EconomyManager.get_dominant_term()` |

### 18.5 Catálogo — MICELIO (14)

| id | nombre | trigger | gate |
|---|---|---|---|
| `primera_espora` | Primera Espora | event `run_closed` | cualquier ruta |
| `brote_inicial` | Brote Inicial | threshold | `total_money ≥ 1.000` |
| `pequena_red` | Pequeña Red | event_count 5 | upgrades comprados |
| `raices_profundas` | Raíces Profundas | threshold | `biomasa ≥ 5.0` |
| `umbral_verde` | Umbral Verde | custom | `B ≥ 3.0 ∧ ε < 0.30` |
| `sistema_respira` | El Sistema Respira | sustained **180s** | `ε < 0.20` |
| `metabolismo_estable` | Metabolismo Estable | sustained 60s | `Δ$ ≥ 25/s` |
| `delta_100` | Δ$ ≥ 100/s | threshold | `delta_total ≥ 100` |
| `arbol_productivo` | Árbol Productivo | custom | d + md + so + e + me + cognitive + persistence + accounting (todos lvl ≥ 1) |
| `passive_dominance` | Dominancia Pasiva | custom | `get_dominant_term()` ∈ {Trabajo Manual, Trueque} |
| `jardin_controlado` | Jardín Controlado | event `run_closed` | `disturbances_survived == 0 ∧ Ω ≥ 0.50` |
| `mano_ligera` | Mano Ligera | event `run_closed` | `click_count < 50` |
| `primer_click_letal` | Primer Click Letal | event `big_click` | `power ≥ 10.000` |

> **Eliminados en v1.0.0.10**: `primer_eslabon` (overlap con `pequena_red`), `primer_latido` (trivial), `click_dominance` (sustituido por `passive_dominance` con lógica opuesta — no migra).

### 18.6 Catálogo — ESPORA (14+)

| id | nombre | trigger | gate |
|---|---|---|---|
| `red_micelial_activada` | Red Micelial | event | activar mutación |
| `ruta_hiperasimilacion` | Hiperasimilación | run_closed | route ∈ HIPERASIMILACIÓN |
| `ruta_simbiosis` | Simbiosis Estructural | run_closed | route == SIMBIOSIS |
| `ruta_esporulacion` | Esporulación Irreversible | run_closed | route ∈ ESPORULACIÓN |
| `tension_productiva` | Tensión Productiva | custom | homeostasis + red_micelial en `latente` |
| `arquitecto_caos` | Arquitecto del Caos | event | `disturbance_streak ≥ 3` (sin reset) |
| `punto_inflexion` | Punto de Inflexión | event_count 3 | `dominant_switch` |
| `sin_tocar` 🔒 | Sin Tocar | run_closed | HOMEOSTASIS + `click_count ≤ 10` |
| `economia_guerra` | Economía de Guerra | custom | parasitism + `Δ$ ≥ 10.000` |
| `cultivo_cruzado` | Cultivo Cruzado | event_count 2 | mutaciones activas |
| `presion_adaptativa` | Presión Adaptativa | event `disturbance_survived` | `ε > 0.50` durante shock |
| `motor_autotrofo` | Motor Autótrofo | threshold | `delta_total ≥ 50.000` |
| `cosecha_temprana` | Cosecha Temprana | run_closed | `run_time < 300s` |
| `simetria_viva` | Simetría Viva | sustained_between 90s | `B ∈ [4.0, 6.0]` |
| `bioma_despierto` | Bioma Despierto | threshold | `hifas ≥ 10` |
| `escalado_alostatico` | Escalado Alostático | event `upgrade_bought` | `id == "trueque_allo"` (primera compra del upgrade ea) |
| `carnaval_iniciado` | ¡Que Comience el Carnaval! | event | post_tras_route == carnaval |
| `reencarnado` | El Eterno Retorno | event | post_tras_route == reencarnacion |
| `vacio_iniciado` | Hambre Cósmica | event | post_tras_route == vacio |

### 18.7 Catálogo — FRUTO (14+)

| id | nombre | trigger | gate |
|---|---|---|---|
| `ruta_parasitismo` | Parasitismo Consumado | run_closed | route == PARASITISMO |
| `homeostasis_perfecta` | Homeostasis Perfecta | event `homeostasis_tier_reached` | `score ≥ 300` |
| `millonario` | Millonario de Esporas | threshold | `total_money ≥ 1M` |
| `equilibrio_fragil` | Equilibrio Frágil | sustained_between 60s | `ε ∈ [0.10, 0.20]` |
| `parasito_insaciable` | Parásito Insaciable | custom | parasitism + `B ≥ 20` |
| `ciclo_completo` | Ciclo Completo | unlock en `on_run_closed` | ESPORULACIÓN + `seta_formed` |
| `resiliencia_cristalina` | Resiliencia Cristalina | threshold | `resilience_score ≥ 500` |
| `kappa_maximo` | Kappa Máximo | threshold | `k_eff ≥ 1.80` |
| `micelio_salvaje` 🔒 | Micelio Salvaje | unlock en `on_run_closed` | PARASITISMO + sin Contabilidad + `click_count ≥ 100` (anti-AFK) |
| `fruta_prohibida` | Fruta Prohibida | run_closed | PARASITISMO/HIPER + `ε_peak > 0.80` (usa pico, no ε al cerrar) |
| `maquina_organica` | Máquina Orgánica | threshold | `money ≥ 100K` (simultáneo) |
| `eficiencia_brutal` | Eficiencia Brutal | run_closed | `resilience ≥ 200 ∧ click_count ≤ 30` |

> **Eliminado en v1.0.0.10**: `hambre_elegante` (overlap fuerte con `parasito_insaciable`).
| `latido_cosmico` | Latido Cósmico | custom + timer 90s | `Δ$ ≥ 500 ∧ ε < 0.15 ∧ B ≥ 5` |
| `ruta_allostasis` | Alostasis Estructural | run_closed | route == ALLOSTASIS |
| `cinco_legados` | Cinco Legados | custom | ≥5 buffs Banco Genético comprados |

### 18.8 Catálogo — ANCESTRAL (8+, mayoría secretos)

| id | nombre | trigger | gate |
|---|---|---|---|
| `hongo_realidad` 🔒 | El Hongo se Come la Realidad | event | Depredador activado |
| `bioquimica_oscura` 🔒 | Bioquímica Oscura | event | Met. Oscuro activado |
| `tres_vidas_camino` 🔒 | Tres Vidas, Un Camino | custom | HOMEOSTASIS + ALLOSTASIS + HOMEORHESIS achieved |
| `entropia_cero` 🔒 | Entropía Cero | custom + timer 120s | `ε < 0.05 ∧ B > 8` |
| `organismo_total` 🔒 | Organismo Total | custom | `B > 10 ∧ k_eff > 1.6 ∧ ε < 0.15` |
| `depredador_total` 🔒 | Depredador Absoluto | event_count 50 | `depredador_devour` en una run |
| `ruta_homeorhesis` 🔒 | Homeorhesis | run_closed | route == HOMEORHESIS |
| `omega_inviolable` 🔒 | Omega Inviolable | custom + timer 120s | `Ω_min ≥ 0.55 ∧ Ω ≥ Ω_min` |
| `sin_dioses_ni_clicks` 🔒 | Sin Dioses ni Clicks | run_closed | ruta endgame + `clicks_after_minute_one == 0` |
| `run_imposible` 🔒 | La Run Imposible | run_closed | `mutations_active_count ≥ 3` |
| `reino_subterraneo` 🔒 | Reino Subterráneo | custom + meta | todos MICELIO + ESPORA + FRUTO unlocked |
| `ultima_espora` 🔒 | Última Espora | custom + meta | todos los demás logros desbloqueados (se excluye a sí mismo) |

### 18.9 Catálogo — MYTHIC (8+, todos secretos)

| id | nombre | trigger | gate |
|---|---|---|---|
| `saturacion_total` 🔒 | Saturación Total | custom + `on_run_closed` | METABOLISMO OSCURO por "Saturación Oscura" (B ≥ 100) |
| `colapso_depredatorio` 🔒 | Colapso Depredatorio | custom + `on_run_closed` | route == **COLAPSO DEPREDATORIO** |
| `polimorfia_total` 🔒 | Polimorfía Total | custom | route == POLIMORFÍA TOTAL |
| `domador_del_caos` 🔒 | Domador del Caos | custom | route == DOMADOR DEL CAOS |
| `ruta_ascesis` 🔒 | Ascesis Profunda | run_closed | route == ASCESIS_PROFUNDA |
| `ruta_reencarnacion` 🔒 | Reencarnación Consumada | run_closed | `reencarnacion_active == true` |
| `metabolismo_oscuro_pico` 🔒 | Pico Metabólico Oscuro | custom + timer 30s | met_oscuro + `Δ$ ≥ 500.000` |
| `legado_absoluto` 🔒 | Legado Absoluto | custom + meta | todos los `LEGACY_DEFS` con `level > 0` |
| `ascension_total` 🔒 | Ascensión Total | threshold | `trascendencia_count ≥ 5` |
| `dios_de_las_moscas` 🔒 | El Dios de las Moscas | custom + meta | todos los `ALL_ENDINGS` en `endings_achieved` |

### 18.10 Custom evaluators

23 callables registradas en `CUSTOM_EVALUATORS`:

```
umbral_verde, arbol_productivo, passive_dominance, tension_productiva,
economia_guerra, parasito_insaciable, ciclo_completo, micelio_salvaje,
latido_cosmico, tres_vidas_camino, entropia_cero,
organismo_total, reino_subterraneo, ultima_espora, saturacion_total,
colapso_depredatorio, polimorfia_total, domador_del_caos, cinco_legados,
omega_inviolable, metabolismo_oscuro_pico, legado_absoluto,
dios_de_las_moscas
```

5 usan timer custom (en `CUSTOM_TIMER_IDS`):
`latido_cosmico, entropia_cero, omega_inviolable, metabolismo_oscuro_pico`.

Convención: si el evaluator devuelve `true` durante `duration` segundos consecutivos, dispara unlock. Si interrumpe, el timer resetea a 0.

### 18.11 Meta-achievements

Recalculados en `_check_meta_achievements()` (ejecuta tras cada unlock):
- `cinco_legados` — ≥5 buffs Banco Genético con level > 0
- `legado_absoluto` — todos los buffs del Banco Genético comprados
- `dios_de_las_moscas` — todos los `ALL_ENDINGS` cerrados
- `reino_subterraneo` — todos los MICELIO + ESPORA + FRUTO unlocked
- `ultima_espora` — TODOS los logros unlocked (meta-cap)

`ALL_ENDINGS` (17 rutas):
```
HOMEOSTASIS, ALLOSTASIS, HOMEORHESIS,
HIPERASIMILACION, ESPORULACION, PARASITISMO, SIMBIOSIS,
METABOLISMO OSCURO, COLAPSO DEPREDATORIO, DEPREDADOR DE REALIDADES,
COLAPSO CONTROLADO,
POLIMORFÍA TOTAL, DOMADOR DEL CAOS, ASCESIS_PROFUNDA,
SINGULARIDAD, PANSPERMIA NEGRA, MENTE COLMENA DISTRIBUIDA
```

### 18.12 Hooks de eventos (API push_event)

| Función | Evento emitido | Logros consumidores |
|---|---|---|
| `on_run_closed(route)` | `run_closed` con payload completo | todos los `event run_closed` + unlocks especiales |
| `on_upgrade_bought(id)` | `upgrade_bought` | pequena_red |
| `on_click()` | (cuenta interna) | mano_ligera, sin_tocar, etc. via run_closed |
| `on_disturbance_streak(n)` | `disturbance_streak` | arquitecto_caos |
| `on_disturbance_survived(ε)` | `disturbance_survived` | presion_adaptativa |
| `on_homeostasis_tier_reached(tier, score)` | `homeostasis_tier_reached` | homeostasis_perfecta |
| `on_mutation_activated(id)` | `mutation_activated` | cultivo_cruzado |
| `on_depredador_activated()` | `depredador_activated` | hongo_realidad |
| `on_met_oscuro_activated()` | `met_oscuro_activated` | bioquimica_oscura |
| `on_red_micelial_activated()` | `red_micelial_activated` + `mutation_activated` | red_micelial_activada |
| `on_seta_formed()` | (flag interna) | ciclo_completo via run_closed |

Eventos secundarios usados pero no expuestos como hook único:
- `big_click` (push manual desde main.gd cuando un click es ≥ 10K)
- `post_tras_route` (al activar Vacío / Carnaval / Reencarnación)
- `dominant_switch` (cada vez que `get_dominant_term()` cambia)
- `depredador_devour` (por upgrade devorado en run de DEPREDADOR)

### 18.13 Persistencia y reset

- **Persistente** (entre runs y trascendencias): `unlocked: {id: {unlocked_at, seen}}` → `legacy_bank.json`.
- **Efímero** (per run, se resetea en `reset_run_state()`): `_progress`, `_timers`, `_run_time`, `_click_count`, `_clicks_after_minute_one`, `_upgrades_this_run`, `_mutations_this_run`, `_last_dominant`, `_bought_accounting_this_run`, `_seta_formed_this_run`.
- **Cross-run trackeable** (en LegacyManager, no AchievementManager): `endings_achieved`, `mu_peak_achieved`, `trascendencia_count`.

### 18.14 Caveats / inconsistencias detectadas

1. ~~**`fractura_epistemica` ambiguo**~~ → **resuelto en v1.0.0.10**: el achievement se renombró a `colapso_depredatorio` (id + display name). El cosmic buff sigue llamándose `fractura_epistemica` y sigue desbloqueando COLAPSO CONTROLADO. Migración automática en `load_data` vía `ID_RENAMES` preserva unlock de saves viejos.
2. ~~**`ALL_ENDINGS` no incluye `COLAPSO CONTROLADO`**~~ → **resuelto en v1.0.0.10**: agregado al array. `MUTACION_FINAL` queda como alias interno de `METABOLISMO OSCURO` y no requiere entrada propia.
3. ~~**`ciclo_completo._eval`** devuelve siempre `false`~~ → **resuelto**: el id se removió de `CUSTOM_EVALUATORS`. La función stub permanece documentada. Unlock exclusivo en `on_run_closed` (`route ∈ ESPORULACIÓN ∧ seta_formed_this_run`).
4. ~~**`micelio_salvaje._eval`** idem~~ → **resuelto**: mismo tratamiento. Unlock vía `on_run_closed` (`route == PARASITISMO ∧ not _bought_accounting_this_run`).
5. ~~**`tres_vidas_camino`** doble path redundante~~ → **documentado como intencional**: el evaluador de tick sirve para concesión retroactiva (saves migrados con 3 endings previos sin el logro); el check explícito en `on_run_closed` dispara inmediatamente al cerrar HOMEORHESIS. Ambos son idempotentes. Comentario añadido en código.
6. ~~**`main.gd:434` conectaba `run_ended_by_mutation` a `close_run` inexistente**~~ → **resuelto**: cambiado a `RunManager.close_run`. Antes el signal era no-op silencioso, bloqueando cierre por HIPERASIMILACIÓN (ruta única). Afectaba `ruta_hiperasimilacion`, `fruta_prohibida` (path HIPER) y `dios_de_las_moscas` (meta).
7. ~~**Mismatch acentual `Saturación Oscura`**~~ → **resuelto**: EvoManager emitía `"Saturacion Oscura"` (sin tilde); achievement esperaba `"Saturación Oscura"` (con tilde). `saturacion_total` (ANCESTRAL secret) era inobtenible. Corregida la tilde en EvoManager.gd:781.
8. ~~**`ultima_espora` self-reference inalcanzable**~~ → **resuelto en v1.0.0.10**: `_eval_ultima_espora` chequeaba `unlocked.size() >= DEFS.size()` (incluye al propio logro → catch-22). Reemplazado por iteración que excluye `"ultima_espora"` del conteo.

---

## 19. Apéndice — pipeline tick a tick

### 18.1 Logic tick (5 Hz, Δt = 0.2 s)

```
1. RunManager.run_time += Δt
2. EconomyManager: cached_mu = StructuralModel.get_mu_structural_factor()
3. EconomyManager: delta_per_sec = get_click_power() + get_passive_total()
4. EconomyManager.update_economy(Δt): money += delta_per_sec · Δt
5. main.update_epsilon_runtime():
     ε_activo, ε_pasivo, ε_complejidad → ε_runtime (lerp 0.045) → Ω → Ω_min
6. BiosphereEngine.process_tick(Δt, P, ε_rt, flags...):
     hifas → N (de diff ε) → B (gain hifa·√N·0.02·Δt) → M → ε_eff
7. StructuralModel.apply_dynamic_persistence(Δt):
     cₙ lerp hacia fⁿ con α_sigmoid(n_struct_raw)
8. RunManager.disturbance_timer chequeo y trigger
9. EvoManager: timers de mutaciones (primordio, met_oscuro, depredador)
10. RunManager carnaval/vacío/etc.
11. AchievementManager: evaluación de triggers
```

### 18.2 UI tick (10 Hz, 0.1 s)

Refresco de labels y HUD. Cosmético — no toca estado.

### 18.3 Autosave

Cada 30 s. Antes de escribir crea `.bak` del save anterior; recovery automático si el primario está vacío/corrupto.

---

## 19. Resumen de invariantes

- `μ ≥ 1` siempre.
- `cₙ ≥ c₀` por convergencia hacia fⁿ.
- `0 ≤ Ω ≤ 1`.
- `0 ≤ ε_rt ≤ 2` (clamp explícito).
- `B ≥ 0` (clamp en update_nutrients y consumo).
- `M` nunca decrece salvo decadencia con hifas < 5 en `red_micelial`.
- Caps de β(B), κμ, α(n) levantables sólo con `horizonte_estructural`.

---

**Última revisión**: v1.0.0.10 (rebalance catálogo de logros) — código actual en `claude/great-turing-aa67fe`.

**Cambios incluidos en v1.0.0.10** (pre-launch):
- Gate de COLAPSO CONTROLADO: `ε_effective > 0.90` → `ε_runtime > 0.90` (ahora alcanzable con biomasa activa).
- Achievement `fractura_epistemica` renombrado a `colapso_depredatorio` (resuelve colisión con cosmic buff).
- `ALL_ENDINGS` incluye ahora `COLAPSO CONTROLADO` para meta `dios_de_las_moscas`.
- **Save import en desktop**: `SaveManager.import_save_json()` ahora abre `FileDialog` nativo en plataformas no-Web (antes era solo Web). Botón "Importar save" visible en ajustes en todas las plataformas.
- **Caveats 3-4 resueltos**: `ciclo_completo` y `micelio_salvaje` removidos de `CUSTOM_EVALUATORS` (sus evaluadores eran stubs siempre-false; unlock sigue siendo exclusivo de `on_run_closed`).
- **Caveat 5 documentado**: doble path `tres_vidas_camino` es intencional — tick para retroactividad, `on_run_closed` para disparo inmediato.
- **Auditoría de obtenibilidad**: 2 bugs críticos detectados y arreglados.
  - `main.gd:434`: signal `run_ended_by_mutation` conectado a `close_run` inexistente. Ahora conecta a `RunManager.close_run`. Esto desbloqueó la ruta HIPERASIMILACIÓN entera y, por carambola, `dios_de_las_moscas`.
  - `EvoManager.gd:781`: `"Saturacion Oscura"` corregido a `"Saturación Oscura"` para matchear el evaluador del achievement `saturacion_total`.
- **Rebalance catálogo de logros (v1.0.0.10)**:
  - **Eliminados** (cleanup de early-game spam/triviales): `primer_eslabon`, `primer_latido`, `hambre_elegante`.
  - **Reemplazado**: `click_dominance` → `passive_dominance` (lógica opuesta — premia que Trabajo Manual o Trueque domine en lugar de CLICK). No se migra; el unlock viejo queda como dead entry.
  - **Modificados**:
    - `sistema_respira`: 60s → 180s (3 minutos).
    - `arbol_productivo`: añadidos `cognitive`, `persistence` y `accounting` a los requisitos.
    - `jardin_controlado`: añadida condición `Ω ≥ 0.50` al cerrar (omega ahora viaja en payload de `run_closed`).
    - `bioma_despierto`: hifas ≥ 0.5 → **hifas ≥ 10** (red micelial verdaderamente madura).
    - `micelio_salvaje`: añadida condición `click_count ≥ 100` (anti-AFK farm).
  - **Nuevo**: `escalado_alostatico` (ESPORA, no-secret) — comprar el upgrade Escalado Alostático (`trueque_allo`, ×2 al Trueque) por primera vez.
  - **Bug fix**: `ultima_espora` ahora alcanzable (excluye el propio logro del conteo).

**Próxima revisión sugerida**: tras formalizar las mutaciones revertidas (`docs/nuevas transmutaciones.md`) y al integrar el meta-endgame "Jardín Primigenio" si se implementa.
