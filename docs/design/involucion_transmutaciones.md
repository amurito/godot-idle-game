# Involución: Transmutaciones, Sombras y Redenciones

> **Estado (2026-10-12):** spec aprobada por el autor. **R1 + R2 + R3 + R4 implementados** (sistema común,
> Fusión por botón, Ayuno por espejo de conducta, Caos Orquestado, Coro Simbiótico). R5–R6 pendientes.
> Reemplaza la implementación actual de transmutaciones (toggle en el Banco que *reemplaza* el
> disparador de Hiperasimilación), que se desvió de la idea original de
> [`nuevas transmutaciones.md`](nuevas%20transmutaciones.md). Decisiones del autor: ver §8.

---

## 1. La idea (volver al origen)

> *"Poder revertir una mutación — volver a un estado anterior, o **digerir** la mutación para obtener
> un beneficio — pero a cambio de perder algunos efectos y abrir nuevas posibilidades."*
> *"El paso atrás para tomar impulso: desaprender para aprender más fuerte. El jugador sacrifica su
> mutación actual (que ya le dio beneficios) para acceder a rutas ocultas y más poderosas."*

**Qué se había tergiversado:** hoy una transmutación no revierte nada. Es un toggle del Banco que
cambia *qué mutación se activa* cuando se cumplen las condiciones de Hiper. El jugador nunca tiene
la mutación, nunca la pierde, nunca decide nada en la run — y Fusión y Ayuno cuelgan del mismo
disparador, así que se pisan.

## 2. Taxonomía: tres familias de involución

| Familia | Verbo | Relación con A | Cómo se entra | Recompensa |
|---|---|---|---|---|
| **TRANSMUTACIÓN** | desaprender para crecer | **A → A+** | Llave (Banco) + **botón de reversión** con A activa | **Poder**: ruta OP de endgame |
| **SOMBRA** | abandonar | **A → anti-A** | Llave (Banco) + **disparador espejo**: jugar lo opuesto de A | **Visibilidad / sistema nuevo** (OBSERVAR), no multiplicadores |
| **REDENCIÓN** | sanar | sale del colapso | Su propio camino (Remisión: desde Met. Oscuro) | Recuperación, cierre luminoso |

- **Involución táctica** (fracaso → retroceder dentro de la run, como la involución de Remisión)
  sigue siendo un mecanismo reutilizable por cualquier familia.
- Regla de horizonte: **cada mutación base tiene una Transmutación y una Sombra** (grilla 5 × 2, §6).
- Transmutación y Sombra de la misma A **nunca compiten**: una se toma *teniendo* A, la otra
  *jugando al revés* de A. Una run puede llevarte a cualquiera según cómo jugás.

---

## 3. Sistema común de TRANSMUTACIÓN

### 3.1 La llave
- Buff permanente del Banco, categoría `transmutaciones` (una por mutación base).
- Revelado: T ≥ 3 **y** haber cerrado la ruta de A alguna vez. Costo 15–20 PL (como hoy).
- **Sin toggle**: la llave sólo habilita el botón; la decisión es en la run. (La exclusión
  `EXCLUSIVE_GROUPS` de `9a3c473` deja de hacer falta para Fusión/Ayuno.)
- Saves existentes: quien tiene `transmut_fusion` conserva la llave con el comportamiento nuevo.

### 3.2 El botón de reversión
- Aparece **flotante y parpadeante** cuando A está activa, con la llave comprada.
- Patrón (autor): **aparece y desaparece 3 veces × 20 s dentro de 5 min, y después se va para
  siempre esa run**. Primera aparición tras **60 s** con A activa (primero se disfruta A).
- ⚠️ **Adaptación necesaria** — algunas A no viven 5 min:
  - Hiperasimilación cierra a los 180 s (`HYPER_TIMEOUT`) si no carga Depredador.
  - Parasitismo puede cerrar en < 1 min por drenaje/bancarrota/masa crítica.
  - Propuesta: la ventana es `min(5 min, vida esperada de A − 20 s)` y las 3 apariciones se reparten
    dentro de ella; constantes por transmutación en `Balance` (Hiper: 40 / 90 / 140 s). A revisar (§8).
- Al presionarlo: diálogo **"¿Seguro que querés revertir [A]? Vas a perder [efectos]. Esta decisión
  no se puede deshacer en esta run."** con la lista concreta de lo que se pierde y lo que se digiere.
- Si no se revierte, A sigue su curso normal (su final, Depredador, etc.).
- Hotkey sugerida: **[T]** (Transmutar). Estado persistido en el save (apariciones usadas).

### 3.3 Revertir = perder A + digerirla
1. **Se pierde A**: `mutation_A = false`, sus multiplicadores y su final propio dejan de aplicar,
   y su genoma queda "revertido" (no puede reactivarse esa run).
2. **Digestión — pago inmediato** proporcional a lo que A dio. Cada mutación se digiere en **el
   recurso que la definía** (todos los números a calibrar con el simulador):

| A | Se digiere en | Fórmula inicial |
|---|---|---|
| Hiperasimilación | dinero (era un rush de click) | 50 % del $ generado con Hiper activa |
| Homeostasis | Ω (reserva de estabilidad) | Ω_min += 0.15 por el resto de la run |
| Simbiosis | biomasa | +biomasa = 2 × biomasa actual (cap) |
| Red Micelial | hifas / micelio | micelio al 100 % + hifas × 1.5 |
| Parasitismo | dinero desde la biomasa robada | biomasa × costo medio de upgrade × 0.2 |

3. **Se entra a la ruta A+** con su economía propia (§5).

### 3.4 Cada ruta A+ (blueprint, igual que Fusión)
Economía propia + **[Q] loop activo** + **[W] sink de dinero** + **sello de 3 condiciones en ejes
distintos** + **legado permanente** + 2 logros (ANCESTRAL cerrar, MYTHIC desafío) + Codex ES/EN +
perfil de bot + trayectoria golden. Duración objetivo: **15–25 min** desde la reversión.

---

## 4. Sistema común de SOMBRA

- Llave permanente en el Banco (sin toggle).
- **Disparador espejo**: la Sombra de A se activa cumpliendo **las condiciones opuestas** a las de A
  durante el mismo tiempo mínimo. No hay botón: la Sombra es *consecuencia* de cómo jugaste.
- Recompensa: un **sistema o visibilidad nueva** (OBSERVAR, estadísticas ocultas, una capa de juego),
  nunca sólo ×N. Es el contraste con la Transmutación, que sí da poder.

**Ayuno Primordial (rework) ✅** — deja de colgar del disparador de Hiper.

El espejo *literal* de los números de Hiper (activo < 20 %, ε < 0.10, biomasa < 1) resultó
**inalcanzable** al medirlo: "activo %" no mide si clickeás (un jugador que dejó de clickear sigue en
~70 %), y la biomasa sólo crece (< 1 sólo en los primeros ~110 s). Decisión del autor: **espejo de
conducta** — Hiper es clickear frenético; Ayuno es renunciar a clickear:

| Ayuno pide (`GenomeEvaluator.update_ayuno_espejo`) | Constante |
|---|---|
| no clickear durante 60 s | `AYUNO_MIRROR_IDLE` |
| pasivo propio ≥ 10 $/s (sin economía no hay ayuno, hay abandono) | `AYUNO_MIRROR_PASSIVE_MIN` |
| ε < 0.10 | `AYUNO_MIRROR_EPS_MAX` |
| run ≥ 60 s | `AYUNO_MIRROR_MIN_RUN` |

Aviso **10 s antes** ("el hongo empieza a ayunar… clickeá para evitarlo", `AYUNO_MIRROR_WARN`):
decisión del autor para que un AFK no entre por sorpresa. Gana al Parasitismo por inactividad (120 s);
dentro del ayuno, quedarse quieto demasiado sigue llevando a la Trampa del Vacío.

Riesgo a vigilar: **ASCESIS PROFUNDA** (post-trascendencia de Vacío) también es una ruta de renuncia.
Mantener identidades distintas: Ascesis = renuncia *activa* (clicks sin pasivo); Ayuno = renuncia al
*consumo* (sin clicks, biomasa muerta, Silencio).

---

## 5. Las cinco Transmutaciones (fila A+ completa — v1.1)

Nombres: se renombran los dos del brainstorm que chocaban con rutas existentes (decisión del autor).

### 5.1 Hiperasimilación → **FUSIÓN CATABÓLICA** ✅ (rework)
- Ya implementada; cambia sólo la entrada: Hiper se activa normal, y el botón la revierte.
- Pierde: click ×10, pasivo ×0.25 (y el camino a Depredador esa run).
- Digiere: 50 % del $ generado durante Hiper.
- Economía, [Q]/[W], sello ($100M · $50M en ráfaga · n≥150) y legado Motor Fundido: sin cambios
  (rebalance `0bf4bd0`). Re-medir duración: ahora arranca con el burst de digestión.

### 5.2 Homeostasis → **CAOS ORQUESTADO** ✅ (R3, 2026-10-12)
*Homeostasis aprendió a no temerle al caos: lo dirige.* Código: `CaosOrquestadoLogic.gd`.

| | Implementado | Constante |
|---|---|---|
| Llave | 15 PL, revela T ≥ 3, se habilita tras cerrar Homeostasis | `transmut_caos` |
| Botón [T] | 60 / 170 / 280 s de Homeostasis activa (no cierra sola → ventana completa) | |
| Pierde | +50 % en banda, piso Ω 0.35, shocks, Alostasis/Homeorresis esa run | |
| Digestión | Ω_min +0.15 | `CAOS_DIGEST_OMEGA_MIN` |
| Combustible | ingreso × (1 + 1.0·ε), tope ×3; Ω ≥ 0.20 | `CAOS_FUEL_K/CAP`, `CAOS_OMEGA_FLOOR` |
| **Carga de caos** | +0.01/s, piso de ε, tope 2.0; el Colapso la vacía | `CAOS_CHARGE_RATE/MAX` |
| [Q] Colapso Dirigido | ráfaga × (1 + 2·ε cobrado) 20 s, ε → 0, cooldown 90 s | `CAOS_COLLAPSE_*` |
| [W] **Afinar** | −20 % cooldown **y +25 % velocidad de carga** por nivel, desde $500K ×1.9 | `CAOS_CD_*` |
| Sello | 360 s con ε ≥ 0.60 · 10 Colapsos con carga · $30M desde la reversión | `CAOS_SEAL_*` |
| PL | 9 + floor(colapsos con carga / 2), tope 8 | |
| Legado | **Batuta**: ε → 0 una vez por run, en cualquier run (botón) | `legado_batuta` |
| Logros | ANCESTRAL *Director de Orquesta* · MYTHIC *Sinfonía del Caos*: **todos** los Colapsos con ε ≥ 1.5 | |

**Cambios respecto de la propuesta aprobada, por lo que mostró el simulador:**
1. **Carga de caos (nuevo).** Sin ella, ε converge a su equilibrio estructural (~0.56 cuando domina el
   pasivo) y se queda debajo de la zona roja: la ruta **no se podía sellar**. Idea: *el caos se acumula
   si no lo dirigís*.
2. **[W] también acelera la carga.** Sólo acortar el cooldown no aceleraba el sello (el ciclo lo limita
   lo que tarda la carga en volver a la zona roja); con $50K además era trivial.
3. **Sello recalibrado** ($1M era trivial: el ingreso pasa de ~300 $/s a ~30K $/s en 3 min).
4. **MYTHIC**: "un Colapso con ε ≥ 1.5" salía sin buscarlo (al principio ε llega a 2.0 clickeando);
   ahora exige **todos** los Colapsos a ε ≥ 1.5 (paciencia: esperar la carga larga).

| Perfil (`tests/sim/Scenarios.gd`) | Sella desde la reversión |
|---|---:|
| `ng_caos_player` — cobra con ε ≥ 0.8 y compra [W] | **15.3 min** |
| `ng_caos_no_cd` — igual, sin [W] | **17.8 min** |
| `ng_caos_sinfonia` — cobra sólo con ε ≥ 1.5 (logra el MYTHIC) | 21.0 min |

### 5.3 Simbiosis → **CORO SIMBIÓTICO** ✅ (R4, 2026-10-12) — ⚠️ se rehace como ritmo: ver §10.2 *(ex "Singularidad Distribuida")*
*La cooperación deja de ser un pacto y se vuelve un ritmo.* Código: `CoroSimbioticoLogic.gd`.

| | Implementado | Constante |
|---|---|---|
| Llave | 15 PL, revela T ≥ 3, se habilita tras cerrar Simbiosis | `transmut_coro` |
| Botón [T] | 35 / 78 / 120 s; **el cierre automático de Simbiosis espera** mientras queden apariciones | `TRANSMUT_LIFE_SIMBIOSIS` |
| Pierde | click ×2.5, pasivo ×0.5, final Simbiosis | |
| Digestión | **40 de ritmo inicial** (decae si no se sostiene) — decisión del autor en lugar de biomasa ×2 | `CORO_DIGEST_STACKS` |
| Ritmo | cada click +1; decae con constante = ventana (≈ clicks/s × ventana). +2 % de ingreso por punto, tope 100. Se cuenta en todas las runs | `CORO_STACK_*`, `CORO_WINDOW_BASE` |
| Desafinación | bonus × (1 − ε/2) | |
| [Q] Sobrecarga | 10 s de auto-click a 20/s, ε +0.20, cooldown 90 s | `CORO_OVERLOAD_*` |
| [W] Sostener | +1 s de ventana por nivel (máx. 5), desde $100K ×1.9 | `CORO_W_*` |
| Sello | **ritmo ≥ 35** sostenido 300 s · 6 Sobrecargas · $10M desde la reversión | `CORO_SEAL_*` |
| PL | 9 + floor(pico de ritmo / 20), tope 8 | |
| Legado | **Eco del Coro**: en todas las runs, +0.5 % por punto de ritmo, tope +20 % | `CORO_ECHO_*` |
| Logros | ANCESTRAL *Coro Completo* · MYTHIC *Fortissimo*: ≥ 50 de ritmo 30 s seguidos sin Sobrecarga | |

**Calibración:** con umbral 30 [W] no aportaba (a 6 clicks/s × 5 s el ritmo ya daba 30); con **35**, el
jugador promedio necesita [W] (o clickear más rápido) para sostenerlo.

| Perfil | Sella desde la reversión |
|---|---:|
| `ng_coro_player` — 6 clicks/s, Sobrecarga, [W] | **17.2 min** |
| `ng_coro_no_w` — igual, sin [W] | **22.1 min** |
| `ng_coro_fortissimo` — 11 clicks/s (logra el MYTHIC) | 12.2 min |

### 5.4 Red Micelial → **MICELIO OMNISCIENTE** — ⚠️ reemplazado por §10.3 (asignar)
*La red deja de crecer hacia afuera y empieza a verlo todo desde adentro.*
- Pierde: pasivo ×2.5 y click ×0.5 (y la rama Colonización/Simbiosis de esa run).
- Digiere: micelio al 100 % + hifas ×1.5.
- Economía: **todo el ingreso ×1.8**; hifas y micelio sin cap.
- [Q] **Colonizar**: gasta micelio para ×2 pasivo 60 s. [W] sink: menos costo de micelio.
- Sello (ejes: expansión · gasto · volumen): hifas ≥ H · micelio gastado total ≥ M · $X.
- Legado (propuesta): *Red Latente* — arranque de run con micelio parcial.

### 5.5 Parasitismo → **HUÉSPED SOBERANO** *(ex "Simbiosis Depredadora")* — ⚠️ reemplazado por §10.4 (domesticar)
*El huésped deja de ser víctima: domestica a su parásito.*
- Pierde: crecimiento de biomasa ×2, corrosión y drenaje (y sus finales de colapso).
- Digiere: biomasa robada → dinero.
- Economía: **click y trueque se potencian mutuamente** (cada uno sube al otro, con techo).
- [Q] **Depredar**: convierte 10 % de la biomasa en dinero instantáneo. [W] sink: % convertido.
- Sello (ejes: depredación · equilibrio · volumen): biomasa convertida total ≥ B · ratio
  click/trueque dentro de banda N s · $X.
- Legado (propuesta): *Pacto Soberano* — la corrosión de Parasitismo es 50 % más lenta en todas las runs.
- ⚠️ Parasitismo vive poco (drena rápido): es la que más necesita la ventana adaptada de §3.2.

---

## 6. Horizonte: la grilla completa

| Mutación base | Transmutación (A+, poder) | Sombra (anti-A, visibilidad) | Redención |
|---|---|---|---|
| Hiperasimilación | ✅ Fusión Catabólica | ✅ Ayuno Primordial | — |
| Homeostasis | Caos Orquestado (v1.1) | Inestabilidad Consciente (OBSERVAR) | — |
| Simbiosis | Coro Simbiótico (v1.1) | Autarquía | — |
| Red Micelial | Micelio Omnisciente (v1.1) | Núcleo Aislado | Redención de la Red |
| Parasitismo | Huésped Soberano (v1.1) | Autosuficiencia | — |
| Met. Oscuro | — | — | ✅ Remisión Metabólica |
| Orden (rama azul) | — | — | Redención del Orden |

FANTASMA (combos de dos llaves) queda para después de la grilla (requiere ≥ 3 transmutaciones).

---

## 7. Plan de implementación (spec primero, después código)

| Paso | Contenido |
|---|---|
| R0 | **Esta spec revisada y aprobada** por el autor (§8). |
| R1 ✅ | Sistema común: `TransmutationLogic.gd` (agenda de apariciones adaptada a la vida de A, digestión, revert), botón flotante parpadeante + diálogo + [T] (`NGPlusButtonManager`), estado en save (`transmut_*`), llaves sin toggle; se quitó la exclusión del Banco. 7 tests unitarios de la agenda. |
| R2 ✅ | **Fusión** por botón (Hiper a los 83 s → revierte a los 124 s → sella ~17.5 min después) y **Ayuno** por espejo de conducta. Codex ES/EN reescrito (intro de involución, Fusión, Ayuno — corrige además 3 números viejos de Ayuno). Escenarios `ng_hiper_key_no_revert` (camino "no revierto") y bot que transmuta por el diálogo. |
| R3 ✅ | **Caos Orquestado** (§5.2): calibrado con 3 perfiles de bot, trayectoria golden `ng_caos_player` (cubre además Homeostasis, que no tenía ninguna). |
| R4 ✅ | **Coro Simbiótico** (§5.3) + paleta y animación de transmutación (§9). |
| R5–R6 | **Rediseño por verbos (§10)**: R5 Micelio (asignar), R4b Coro (ritmo), R3b Caos (Gran Colapso), R6 Huésped (domesticar). Cada una con propuesta de números → aprobación → implementación → calibración con bot, golden, logros, Codex ES/EN. |
| R7 | Retomar la auditoría de gameplay (A2/A3) con las rutas ya en su forma final. |

---

## 10. Rediseño: un verbo por transmutación (propuesta 2026-10-12, para revisión)

**Problema (autor):** las cuatro transmutaciones implementadas o propuestas comparten el mismo molde
— [Q] ráfaga activable, [W] sumidero de $, sello de 3 casillas, legado "+% de ingreso" — y se sienten
iguales. **Decisión:** cada una tiene un **verbo propio**; el sello y el legado también cambian de forma.
Coro se rehace (hoy es "clickear rápido", casi lo mismo que Hiper/Fusión); Caos sólo cambia el sello.

| Transmutación | Verbo | Teclas | Forma del sello | Forma del legado |
|---|---|---|---|---|
| Fusión Catabólica ✅ | **Ráfaga** | Q · W | 3 casillas (queda: es el molde original) | ingreso |
| Caos Orquestado ✅ | **Apuesta** | Q · W | **un solo Gran Colapso** | botón (Batuta) |
| Coro Simbiótico | **Ritmo** (a tiempo, no rápido) | ninguna: el núcleo | **partitura** en 3 movimientos | click |
| Micelio Omnisciente | **Asignar** | click derecho en upgrades | **red completa** | un nodo elegido |
| Huésped Soberano | **Domesticar** | Q (alimentar) | **confianza** nivel 5 | corrosión más lenta |

Todos los números de abajo son **propuesta para calibrar con el simulador** (mismo proceso que R3/R4:
nada inalcanzable, el bot normal no saca el MYTHIC, objetivo ~15–20 min desde la reversión).

### 10.1 Caos Orquestado — sello de **Gran Colapso** ✅ (R3b, 2026-10-13)

**Implementado:** un Colapso cobrado con ε ≥ 1.8 cuya ráfaga genere **$5M** sella la ruta al terminar
(sin botón). Dos cambios por el simulador:
1. **[W] también suma +15 % al multiplicador del Colapso por nivel.** Sólo acortar cooldown/acelerar la
   carga no movía el sello: el Gran Colapso lo limita lo que rinde una ráfaga.
2. **MYTHIC *Sinfonía del Caos* = sellar con el primer Gran Colapso intentado** (ni un intento fallido).
   "Todos los Colapsos con ε ≥ 1.5" salía solo jugando a la ruta nueva. Ahora pide cultivar cobrando por
   debajo de 1.8 y apostar una sola vez, en el momento justo.

| Perfil | Sella desde la reversión | MYTHIC |
|---|---:|---|
| `ng_caos_player` — cobra con ε ≥ 0.8, [W], a los 8 min busca el Gran Colapso | **14.8 min** (4 intentos) | no |
| `ng_caos_no_cd` — igual sin [W] | 20.5 min | no |
| `ng_caos_sinfonia` — cultiva con ε < 1.6, un solo intento a los 19 min | 21.3 min | sí |

**Diseño original de §10.1:**
- Hoy: 360 s con ε ≥ 0.60 · 10 Colapsos con carga · $30M (tres casillas).
- Propuesta: **un Colapso Dirigido cobrado con ε ≥ 1.8 que genere ≥ $X durante su ráfaga** sella la
  ruta al terminar la ráfaga. Es la apuesta llevada al extremo: esperar la carga larga (ε llega a 1.8
  sólo con la carga de caos), y que la economía ya sea grande para que la ráfaga alcance.
- Si la ráfaga no llega a $X, no pasa nada: volvés a cargar (cooldown + carga = el costo del intento).
- $X a calibrar para ~15 min (punto de partida: $15M en 20 s). [W] se queda (acelera la carga = más
  intentos). MYTHIC *Sinfonía del Caos* sin cambios (todos los Colapsos con ε ≥ 1.5).
- Panel: muestra "Gran Colapso: ε cobrado X / 1.8 · ráfaga $Y / $X" del último intento.

### 10.2 Coro Simbiótico — **ritmo de verdad** ✅ (R4b, 2026-10-13) · `CoroSimbioticoLogic.gd` + `MetronomeRing.gd`

> **Ajuste del autor (2026-10-13):** "lo siento muy difícil, dale más tiempo para acertar" → ventana
> **±0.20 s** (antes ±0.15) y tempos **80 / 95 / 110 BPM** (antes 90/110/130); legado a 90 BPM.
> Perfil normal: 9.0 min (antes 7.8). Los números de abajo son los de la primera versión.

**Implementado con estos ajustes (simulador):**
- **La partitura cuenta compases, no combo.** Compás = 4 golpes seguidos a tiempo; I 40 compases (90 BPM),
  II 60 (110), III 80 (130). Con "combo 16/32/64" y el combo a la mitad al fallar, un jugador con 94 %
  de precisión no llegaba nunca a 64. Ahora fallar corta el **combo** (ingreso) pero no borra compases.
- **Golpe salteado: combo −4** (sin esto se arma ×3.5 y se queda AFK).
- **Fortissimo (MYTHIC)** = sellar con 0 clicks fuera de tiempo en el Allegro (320 golpes).
- **Metrónomo**: aro sobre el núcleo + tick sintetizado (acento en el 1er golpe), volumen propio en
  Ajustes; suena también con el legado **Compás Interno** (100 BPM, +1 % click por golpe seguido, tope 15 %).
- Reloj: `RunManager.run_time` (por frame) → juicio de ±150 ms determinista en el simulador.

| Perfil | Precisión | Sella desde la reversión | MYTHIC |
|---|---:|---:|---|
| `ng_coro_player` | 94 % | **7.8 min** | no (33 fallos en el Allegro) |
| `ng_coro_sloppy` | 85 % | 9.6 min | no |
| `ng_coro_fortissimo` | 99.95 % | 6.4 min | sí |

Es la transmutación más corta (~8 min) pero **toda activa**: el tiempo lo pone la partitura, no la economía.

*La cooperación deja de ser un pacto y se vuelve un ritmo.* Reemplaza la mecánica de R4.
- **Metrónomo:** el núcleo late a un tempo visible (aro que se cierra hacia el golpe; reutiliza el
  latido a contrafase de `ReactorFX`). Clickear **en el golpe** (±150 ms, tolerante a la latencia web)
  suma 1 al **compás** (combo). Clickear fuera de tiempo **corta el compás a la mitad**; los clicks
  siguen dando $ normal, pero spamear rompe el combo → el verbo es la precisión, no la velocidad.
- **Economía:** ingreso × (1 + 0.04·compás), tope compás 64 (×3.56). Pierde click ×2.5 y pasivo ×0.5
  de Simbiosis (como hoy). A 90–130 BPM clickeás 1.5–2.2 veces por segundo: la run es activa pero calma.
- **Partitura (sello):** tres movimientos en orden; cada uno fija el tempo:
  | Movimiento | Tempo | Objetivo |
  |---|---|---|
  | I. *Andante* | 90 BPM | compás 16 |
  | II. *Moderato* | 110 BPM | compás 32 |
  | III. *Allegro* | 130 BPM | compás 64 |
  Completar el III habilita el botón de sellar. Romper el compás no te baja de movimiento.
- **Digestión:** arrancás con compás 16 (el Movimiento I a medio camino… o completo si lo sostenés).
- Salen Sobrecarga [Q] y Sostener [W]. Sin teclas: todo pasa en el núcleo.
- **Legado — Compás Interno:** en todas las runs el núcleo marca un pulso suave; cada click en el
  golpe suma +1 % de click, tope +15 %, y se corta al fallar.
- **MYTHIC — Fortissimo:** completar el Allegro sin cortar nunca el compás (una toma limpia de 64).
- **Bot:** perfil que clickea en el golpe con precisión p (RNG con semilla): p = 0.9 (jugador normal)
  y p = 0.99 (MYTHIC). Sirve también de test de la ventana ±150 ms.
- **Abierto:** ¿sonido de metrónomo (tick suave) además del visual? Recomiendo sí, con volumen propio.

#### 10.2b Rework "sólo los acentos" (2026-10-17, feedback del autor: "muy largo y tedioso")
- Se juzga sólo el **acento** (1 de cada 4 golpes). Alrededor de cada acento hay una zona de ±medio golpe: el
  **primer** click en la zona se juzga (±0.20 s = acierto, combo +3; si no, combo a la mitad). Fuera de las zonas
  se clickea libre (spamear no sirve: el primer click de la zona es el que cuenta). Acento salteado: −4.
- Partitura: 16 / 20 / 24 acentos (antes 40 / 60 / 80 compases de 4 golpes).
- Bot: 94 % → 2.7 min dentro de Coro (antes 7.8); 85 % → 3 min (antes 9.6); Fortissimo sigue saliendo al 99.95 %.

### 10.3 Micelio Omnisciente — **asignar** ✅ (R5, 2026-10-12) · código `MicelioOmniscienteLogic.gd`

**Implementado como abajo, con dos cambios por el simulador:**
1. **MYTHIC *Ojo de la Red*** = sin desconectar nunca **y sin comprar un upgrade a mano** tras revertir
   (la red compra por vos). "Sin desconectar" solo lo sacaba también el jugador AFK.
2. **Legado *Nodo Latente*** = el **primer** nodo que llenaste (al sellar los 9 están llenos: "el más
   conectado" no distinguía).

| Perfil (`tests/sim/Scenarios.gd`) | Sella desde la reversión | MYTHIC |
|---|---:|---|
| `ng_micelio_player` — conecta en orden, corrige el plan una vez, compra a mano | **16.1 min** | no |
| `ng_micelio_planner` — plan fijo sin desconectar, compra a mano | 16.1 min | no |
| `ng_micelio_ojo` — Trueque primero, sólo autocompra | **13.8 min** | sí |
| `ng_micelio_afk` — no conecta nada (sólo deriva) | 31.6 min | no |

El orden del plan mueve poco (15.5–17.5 min): lo que limita es el tope de 180 (≈30 hifas = economía
pasiva). Jugar contra AFK: ×2. Dejar que la red compre es lo más rápido (autocompra con −30 % y sólo en
nodos llenos, contra un comprador "lo más barato" que dispersa la plata).
⚠️ Hallazgo para la auditoría: el perfil viejo `fresh_red_micelial` **nunca llega a Red Micelial**
(no compra Contabilidad, pasivo ~75 $/s a los 30 min); los perfiles de Micelio usan clicks 4/s los
primeros 7 min y después sólo pasivo (`buy_ids_from`).

*La red deja de crecer hacia afuera y empieza a verlo todo desde adentro.* Reemplaza Colonizar/Anastomosis.
- **Presupuesto de micelio:** crece 0.05·hifas %/s hasta el **tope = 60 + 4·hifas** (≈100 con 10 hifas,
  ≈180 con 30). La digestión de Red Micelial deja el micelio en max(actual, 60).
- **Nodos = los 9 upgrades.** Click derecho en un upgrade le conecta 5 de micelio (máx. 20 por nodo);
  Shift + click derecho le saca 5 (vuelve al presupuesto). Cada nodo muestra una barrita violeta.
- **Efecto por nodo:** su aporte × (1 + conexión/20) (hasta ×2) y su costo −1.5 % por punto (hasta −30 %).
  **Un nodo en 20 se autocompra** cuando alcanza la plata: *la red lo ve*. La run se vuelve de
  planificación: qué conectás primero y qué dejás que la red compre sola.
- **Deriva:** el micelio sin asignar fluye solo (1 punto cada 10 s) al nodo más comprado: jugar AFK
  funciona, pero peor que planificar.
- **Sello — red completa:** los 9 nodos en 20 (= 180 de micelio → necesitás ~30 hifas, o sea una
  economía pasiva grande) sostenidos 60 s.
- Pierde: pasivo ×2.5 / click ×0.5 de Red Micelial, la bifurcación y Esporulación. El botón [T]
  desaparece si ya arrancó el primordio (punto sin retorno).
- **Legado — Nodo Latente:** el upgrade más conectado al sellar queda con ×1.25 en todas las runs
  (lo elegís vos con tu forma de jugar).
- **MYTHIC — Ojo de la Red:** sellar sin desconectar nunca un nodo (cero reasignaciones).
- Recordatorio medido: biomasa, micelio e hifas **no generan $** por sí solos (las hifas se recalculan
  cada tick desde el pasivo), por eso acá el micelio pasa a ser el recurso que mueve la economía.

#### 10.3b Rupturas de micelio (2026-10-17, feedback del autor: "es trivial, no tiene forma de perder")
- Cada 65–120 s (secuencia fija) el micelio **cruje** sobre un nodo conectado (pseudoaleatorio con hash: reproducible),
  avisando 4 s antes con el nombre del nodo: desconectarlo salva los puntos (cuenta como desconexión para el MYTHIC).
- Con 50 % se **rompe**: el nodo pierde el 60 % de su conexión (no vuelve al pozo).
- **[W] Reforzar** (4 niveles, 15 s de ingreso × 1.6): −20 % de probabilidad y −15 % de daño por nivel.
- **Colapso**: 4 nodos LLENOS rotos → la red colapsa → cierra como ESPORULACIÓN.
- Bot: jugador completo (refuerza + esquiva) 25.8 min total (antes 16); refuerza sin esquivar 26.5; MYTHIC Ojo de la
  Red 30.5 (sale); AFK colapsa a 38.8 (antes sellaba solo a 31.6).

### 10.4 Huésped Soberano — **domesticar** ✅ (R6, 2026-10-13) · `HuespedSoberanoLogic.gd`

**Implementado con estos ajustes (simulador):**
- **Ventana del botón:** Parasitismo vive 13–20 s. Con la llave, su cierre **espera mientras el botón [T]
  tenga apariciones** (25 / 52 / 80 s); el parásito sigue drenando mientras dudás.
- **Banda 25–75** (no 30–70): con 30–70, alimentar −30 y antojo +15, había momentos sin salida (ni
  alimentar ni esperar evitaban salir de la banda) y el MYTHIC era imposible incluso jugando perfecto.
- **Antojos** (+15, cada 40/30/50/35/45 s, aviso 4 s antes): sin ellos, alimentar en piloto automático
  sacaba el MYTHIC.
- **Alimentar sin despensa cuesta el 4 %** del dinero (10 % congelaba la economía en ~90 s de ingreso).
- Despensa = 1 comida cada 2 de biomasa robada. Sin [W].

| Perfil | Juego | Sella desde la reversión | MYTHIC |
|---|---|---:|---|
| `ng_huesped_player` | alimenta con hambre 68 | **10.0 min** (1 s de mordida) | no |
| `ng_huesped_lazy` | alimenta con hambre 85 | 16.0 min (6 min mordiendo, economía a 0) | no |
| `ng_huesped_perfect` | alimenta a 60 y anticipa los antojos | 10.0 min | sí |

Como Coro, es corta (~10 min) pero toda activa.

**Diseño original de §10.4:**
*El huésped deja de ser víctima: domestica a su parásito.*
- **El parásito tiene hambre** (0–100), sube +2/s. **[Q] Alimentar**: −30 de hambre, cuesta 10 % del
  dinero actual o 2 de biomasa si tenés (la biomasa es comida barata).
- **Banda de domesticación 30–70:** la **confianza** sube +1/s.
  - Hambre > 70: muerde → vuelve la corrosión de Parasitismo mientras siga hambriento.
  - Hambre < 30: saciado y perezoso → no trae regalos y la confianza baja −0.5/s.
- **Regalos por nivel de confianza** (niveles a los 60 / 150 / 270 / 420 / 600 de confianza):
  cada 20 s deja una gota de $ = (nivel × 5) s de ingreso, y el trueque sube ×(1 + 0.2·nivel).
- **Sello: confianza nivel 5** (≈ 10 min dentro de la banda). Ritmo de cuidado: alimentar cada ~15–20 s.
- **Digestión:** la biomasa robada durante Parasitismo pasa a la **despensa** (comida gratis).
- Pierde: crecimiento de biomasa ×2, drenaje y los finales de colapso de Parasitismo.
- **Legado — Pacto Soberano:** la corrosión de Parasitismo es 50 % más lenta en todas las runs.
- **MYTHIC — Simbionte Perfecto:** desde el nivel 1, no salir nunca de la banda hasta sellar.
- ⚠️ Parasitismo vive poco: medir su vida real con el bot antes de fijar la agenda del botón [T].

### 10.5 Orden de implementación propuesto
1. ✅ **R5 Micelio (asignar)** — barras en upgrades + click derecho.
2. ✅ **R4b Coro (ritmo)** — metrónomo visual + sonido, bot con precisión.
3. ✅ **R3b Caos (Gran Colapso)**.
4. ✅ **R6 Huésped (domesticar)**. **Fila de 5 transmutaciones completa.**

## 9. Identidad visual de las transmutaciones (2026-10-12)

**Paleta — complementario separado** (decisión del autor): cada transmutación toma el lado opuesto
del círculo cromático de su evolución, corrido lo justo para distinguirse (el complementario exacto
dejaba tres en rosa-magenta, porque Homeostasis, Simbiosis y Red Micelial son verdes/turquesas).

| Evolución | Transmutación | Activa | Sellada |
|---|---|---|---|
| Hiperasimilación (rojo) | Fusión Catabólica | **oro** (excepción: se mantiene) | ámbar oscuro |
| Homeostasis (turquesa) | Caos Orquestado | **rojo-rosado** (más vivo con más ε) | rojo-rosado profundo |
| Simbiosis (verde agua) | Coro Simbiótico | **coral** (más vivo con más ritmo) | coral profundo |
| Red Micelial (verde) | Micelio Omnisciente | violeta (pendiente) | |
| Parasitismo (naranja) | Huésped Soberano | azul (pendiente) | |
| — Sombras — | Ayuno Primordial | casi negro | plateado frío |

**Animación (`ReactorFX.gd`, 2D y 3D):**
- **Compresión al transmutar** (~1.7 s): el núcleo se comprime mientras el color de la evolución pasa a
  blanco, aguanta un instante y se expande con rebote en el color de la transmutación.
- **Latido a contrafase** mientras una transmutación A+ está activa: el núcleo se contrae en el golpe
  (las evoluciones laten hacia afuera).
- Puramente visual (reloj de pared, no entra en el estado del juego ni en los goldens).

## 8. Decisiones

**Tomadas por el autor (2026-10-12):**
- Tres familias separadas: Transmutación (A→A+), Sombra (A→anti-A), Redención.
- Sombras por **disparador espejo**. Llave **permanente**; la decisión de revertir es en la run.
- Revertir **digiere** A con un pago inmediato.
- Botón: **3 apariciones × 20 s en 5 min**, después desaparece.
- Grilla 5 × 2 como horizonte. Caos Orquestado = A+, Inestabilidad Consciente = anti-A.
- v1.1 = rework + **fila completa de 5 Transmutaciones**. Renombrar los nombres que chocaban.
- Proceso: spec primero, después código.

**Abiertas (para revisar en esta spec):**
1. Ventana adaptada a la vida de A (§3.2): ¿OK la regla `min(5 min, vida de A − 20 s)`?
2. Fórmulas de digestión (§3.3): ¿el recurso de cada una tiene sentido?
3. Nombres nuevos: **Coro Simbiótico** y **Huésped Soberano**.
4. Mecánicas y sellos de las 4 nuevas (§5.2–5.5): son la base del brainstorm; ¿alguna querés cambiar?
5. Hotkey [T] para transmutar.
6. ¿Dónde vive la 2ª Redención ahora que v1.1 es la fila de Transmutaciones? (¿v1.2?)
