# Fusión Catabólica — la primera transmutación

> **Estado: implementada y commiteada en v1.0.3.0 (2026-06-27).**
> Este doc es la **spec de diseño canónica** de la primera transmutación del juego y el **blueprint**
> para diseñar las siguientes (SOMBRA, FANTASMA). Para la teoría general de transmutaciones ver
> [`enciclopedia_rutas.md`](enciclopedia_rutas.md) y [`arquitectura_rutas.md`](arquitectura_rutas.md).

---

## 1. Qué es

FUSIÓN CATABÓLICA es una **transmutación**: no es una ruta nueva ni una mutación más fuerte, sino la
**transformación de una mutación existente** (HIPERASIMILACIÓN). Cuando el jugador posee el buff
`transmut_fusion` del Banco Genético, las condiciones que normalmente detonarían Hiperasimilación
detonan en su lugar una Fusión Catabólica: la asimilación descontrolada se estabiliza en un **motor
metabólico permanente**.

La diferencia conceptual con una ruta post-trascendencia: una transmutación **reescribe el
comportamiento de una mutación que el jugador ya conocía**. La sorpresa es ver familiar-pero-distinto.

---

## 2. Mecanismo de disparo

`GenomeEvaluator.update_hiperasimilacion()` evalúa las 5 condiciones de entrada cada tick. Si se
cumplen **y** `LegacyManager.get_buff_value("transmut_fusion")` está activo → llama a
`EvoManager.activate_fusion_catabolica()` en lugar de `activate_hyperassimilation()`.

**Condiciones de entrada** (checklist visible en el panel evo, vía `UITextBuilders.build_evo_checklist`):

| # | Condición | Lectura |
|---|---|---|
| 1 | `activo > 80%` | el sistema casi todo activo |
| 2 | `ε_runtime > 0.40` | epsilon alto |
| 3 | `biomasa > 4` | biosfera mínima |
| 4 | `accounting == 0` | **comprar Contabilidad bloquea la transmutación** (decisión irreversible en el run) |
| 5 | `run_time > hiper_req` | 60s si `trascendencia_count > 2`, si no 180s |

La condición 4 es de diseño: introduce una **tensión de build** — Contabilidad es un upgrade útil que
el jugador debe renunciar conscientemente para acceder a la transmutación.

---

## 3. Economía durante la transmutación

| Elemento | Valor | Constante |
|---|---|---|
| Click | **×5** estable | `FUSION_CLICK_MULT` |
| Pasivo | **×5** estable | `FUSION_PASSIVE_MULT` |
| Ráfaga **[Q]** "Metabolismo Híbrido" | ×2 durante 30s | `FUSION_BURST_MULT`, `FUSION_BURST_DURATION` |
| Cooldown base de la ráfaga | 120s | `FUSION_BURST_COOLDOWN` |
| Reducción de cooldown **[W]** | −20% compounding por nivel | `FUSION_CD_REDUCE_PCT` |
| Piso de cooldown | 30s | `FUSION_CD_FLOOR` |
| Costo del upgrade [W] | $1M × 1.9^n (antes $10M) | `FUSION_CD_COST_BASE` / `FUSION_CD_COST_GROWTH` |

**Loop activo:** la ráfaga [Q] es el feedback de corto plazo (clickeás cuando está lista); el sink [W]
es el long loop (gastás dinero para que la ráfaga vuelva más rápido). Color del reactor: amber/gold
`Color(0.97, 0.76, 0.05)` en ráfaga, `Color(0.45, 0.30, 0.01)` sellada/final.

---

## 4. Condiciones de sello (cierre del final)

`EvoManager.fusion_seal_ready()` devuelve true cuando se cumplen las 3:

| Condición | Constante | Valor |
|---|---|---|
| Upgrades estructurales (n) | `FUSION_SEAL_STRUCTURAL_N` | ≥ 150 |
| Dinero **generado** (total acumulado) | `FUSION_SEAL_MONEY` | ≥ $100M |
| Dinero generado **durante ráfagas** | `FUSION_SEAL_BURST_MONEY` | ≥ $50M |

Las 3 empujan al jugador en direcciones distintas: estructura (comprar mucho), volumen (generar
ingreso), y uso activo (usar la ráfaga). Un final no se "espera", se **trabaja**.

> Nota de implementación: `total_money_generated` acumula tanto pasivo como clicks. Hubo que sumar
> `+= power` en `main.gd:on_reactor_click` y en el bloque Mente Colmena para que los clicks contaran.
> La plata en ráfaga (`EvoManager.fusion_burst_money`) se mide en `process_fusion()` como lo que creció
> `total_money_generated` entre ticks mientras la ráfaga estaba activa (se persiste en el save).

### Rebalance 2026-10 (con el simulador)

La versión original pedía **3 ráfagas**. El simulador (`tools/sim`, escenarios `ng_fusion_*`) mostró:

- La condición de ráfagas se cumplía sola a los 6 min: el eje "uso activo" no exigía nada.
- El sink [W] a $10M no lo compraba nunca ningún perfil (10 % de toda la plata de la run).
- El sello **no** era inalcanzable: los bots viejos mantenían el pasivo < 15 % toda la run (hábito de
  Hiper). Un jugador que, ya en Fusión, invierte en estructura llega a n=150 a los ~11 min.

Cambio: "3 ráfagas" → **$50M generados durante ráfagas** + [W] desde **$1M**. Con cooldown base,
~1/3 del ingreso cae en ráfaga, así que 50M (por encima de 1/3 de $100M) pasa a ser la condición que
define el sello y acortar el cooldown rinde.

| Perfil (desde la activación) | Sella |
|---|---:|
| Natural, usa [Q] siempre y compra [W] | ~18 min |
| Natural, nunca compra [W] | ~20 min |
| Sólo estructurales (descuida el click) | ~29 min |
| Usa la ráfaga 3 veces y se olvida | no sella |
| Hábito de Hiper (pasivo < 15 %) | no sella (n ≈ 80): el panel ahora explica qué suma a n |

---

## 5. Recompensa permanente

Al sellar, se otorga el legado **`legado_motor_fundido`** (buff del Banco Genético, categoría
`transmutaciones`):

- **+25 % a todo el ingreso** (`all_income_mult`, stackeable).
- Visible en el LAB dentro de "Legados de ingreso".
- Se otorga una sola vez; si ya existe, no se duplica.

Principio de diseño (regla de oro de las rutas): **el premio es permanente y multiplicativo, pero el
valor real fue el sistema nuevo que jugaste para conseguirlo**, no el ×1.25.

---

## 6. Logros

| ID | Nombre | Tier | Condición |
|---|---|---|---|
| `ruta_fusion_catabolica` | Motor Singular | ANCESTRAL | Cerrar un run con la ruta FUSIÓN CATABÓLICA |
| `coloso_estructural` | Coloso Estructural | MYTHIC | Cerrar run con $1B generado **+** n≥200 upgrades estructurales |

`coloso_estructural` es un evaluador custom (`AchievementManager.on_run_closed()`) — un objetivo
"coloso" deliberadamente por encima del sello, para los jugadores que quieran exprimir la transmutación.

---

## 7. Lore

La hiperasimilación es hambre sin freno: el organismo devora hasta consumirse. La Fusión Catabólica es
lo que pasa cuando esa hambre, en vez de colapsar, **se pliega sobre sí misma y se vuelve estructura**:
el catabolismo (romper para obtener energía) se funde con la síntesis. El "Motor Fundido" es el residuo
permanente de haber domado el hambre una vez — el cuerpo recuerda cómo quemar de forma estable.

---

## 8. Blueprint: cómo diseñar la próxima transmutación

Fusión Catabólica define el patrón reutilizable. Una transmutación nueva (incl. las SOMBRA) necesita:

1. **La llave** — un buff en `LegacyDefs.LEGACY_DEFS`, categoría `transmutaciones`, comprable con PL
   tras trascender + completar la mutación base. Es lo que cambia el comportamiento.
2. **El hook de disparo** — en `GenomeEvaluator` (o donde viva la mutación base): detectar el buff y
   bifurcar a la activación transmutada en vez de la normal.
3. **Una economía propia** durante la transmutación — al menos un loop activo (botón tipo ráfaga) y un
   sink de largo plazo. Vive en `EvoManager` (estado) + helpers.
4. **Botones** — en `NGPlusButtonManager.gd` (no en UIManager). `_update_X_button()` + `_on_X_pressed()`,
   registrados en `update_ng_plus_buttons()` y `reset_ng_plus_buttons()`.
5. **Condiciones de sello** — 2-3 condiciones que empujen al jugador en direcciones distintas (no una
   sola métrica). Función `X_seal_ready()` en EvoManager.
6. **Recompensa permanente** — otro legado en `transmutaciones`, otorgado una vez en
   `RunManager.close_run()` cuando `route == "..."`.
7. **2 logros** — uno por cerrar la ruta (tier alto), uno "coloso" custom por exprimirla.
8. **Persistencia** — cualquier campo nuevo (ej. `fusion_cd_level`) va en `SaveManager`
   build/apply_save_data, o no persiste.
9. **Codex** — entrada en `CodexDefs.gd` con requisitos, teclas y recompensa.
10. **Locale ES/EN** — todas las claves nuevas en `LocaleManager.gd`. El toast de logro usa la clave
    `ACH_<ID_MAYUSC>_NAME`, no el campo `name` del DEFS.

> Regla de oro (de [`enciclopedia_rutas.md`](enciclopedia_rutas.md)): cada transmutación debe **agregar
> un sistema o una visibilidad**, no solo un multiplicador. Si solo da ×N, es un buff de Banco, no una
> transmutación.

---

## 9. Archivos tocados (referencia de implementación)

`EvoManager.gd` (estado + activación + sello), `EconomyManager.gd` (multiplicadores), `UIManager.gd`
→ `NGPlusButtonManager.gd` (botones [Q]/[W]/sello), `UITextBuilders.gd` (checklist + paneles FC),
`LocaleManager.gd` (claves ES/EN), `Balance.gd` (constantes `FUSION_*`), `LegacyDefs.gd`
(`legado_motor_fundido`), `AchievementDefs.gd` + `AchievementManager.gd` (2 logros), `RunManager.gd`
(otorga legado + NG+ tier), `SaveManager.gd` (`fusion_cd_level`), `CodexDefs.gd` (entrada
`transmut_fusion`).
