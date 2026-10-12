# Involución: Transmutaciones, Sombras y Redenciones

> **Estado: SPEC PARA REVISIÓN (2026-10-12).** Nada de esto está implementado todavía salvo lo marcado ✅.
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

**Ayuno Primordial (rework):** deja de colgar del disparador de Hiper.

| Hiperasimilación pide | Espejo → Ayuno pide |
|---|---|
| activo > 80 % | activo < 20 % (casi sin clickear) |
| ε > 0.40 | ε < 0.10 |
| biomasa > 4 | biomasa < 1 (dejarla morir) |
| Contabilidad = 0 | (sin requisito: el ayuno no es una tensión de build) |
| run_time > 60 s (T>2) | run_time > 60 s |

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

### 5.2 Homeostasis → **CAOS ORQUESTADO**
*Homeostasis aprendió a no temerle al caos: lo dirige.*
- Pierde: el +50 % en banda y la estabilización de ε (tiers de homeostasis).
- Digiere: Ω_min +0.15 (la estabilidad acumulada queda como reserva).
- Economía: **ε alimenta la producción** — +5 % a todo el ingreso por cada 0.1 de ε; Ω no baja de 0.20.
- [Q] **Colapso Dirigido**: ε → 0 y ×2 producción 20 s (cooldown). [W] sink: acorta el cooldown.
- Sello (ejes: riesgo · control · volumen): sostener ε ≥ 0.60 un total de N s · M colapsos dirigidos
  · $X generados.
- Legado (propuesta): *Orquesta Interna* — la zona roja de ε penaliza menos en todas las runs.
- Distinción con su Sombra **Inestabilidad Consciente**: Caos = *domina* ε (poder);
  Inestabilidad = *renuncia* a controlarlo y paga el precio, a cambio de OBSERVAR (visibilidad).

### 5.3 Simbiosis → **CORO SIMBIÓTICO** *(ex "Singularidad Distribuida")*
*La cooperación deja de ser un pacto y se vuelve un ritmo.*
- Pierde: click ×2.5 y pasivo ×0.5.
- Digiere: biomasa ×2 (cap).
- Economía: **ritmo** — cada click da +x % a todos los upgrades por 5 s, acumulable (stacks);
  dejar de clickear los deja caer.
- [Q] **Sobrecarga**: auto-click ×50 durante 10 s, pero ε +0.2. [W] sink: más duración de stacks.
- Sello (ejes: ritmo · riesgo · volumen): pico de stacks ≥ S · N sobrecargas · $X.
- Legado (propuesta): *Eco del Coro* — los primeros stacks de cada run no decaen.

### 5.4 Red Micelial → **MICELIO OMNISCIENTE**
*La red deja de crecer hacia afuera y empieza a verlo todo desde adentro.*
- Pierde: pasivo ×2.5 y click ×0.5 (y la rama Colonización/Simbiosis de esa run).
- Digiere: micelio al 100 % + hifas ×1.5.
- Economía: **todo el ingreso ×1.8**; hifas y micelio sin cap.
- [Q] **Colonizar**: gasta micelio para ×2 pasivo 60 s. [W] sink: menos costo de micelio.
- Sello (ejes: expansión · gasto · volumen): hifas ≥ H · micelio gastado total ≥ M · $X.
- Legado (propuesta): *Red Latente* — arranque de run con micelio parcial.

### 5.5 Parasitismo → **HUÉSPED SOBERANO** *(ex "Simbiosis Depredadora")*
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
| R1 | Sistema común: botón de reversión (patrón de apariciones, diálogo, hotkey, save), digestión, genoma "revertido", llave sin toggle + migración de saves. Disparador espejo genérico para Sombras. |
| R2 | Rework de **Fusión** (botón) y **Ayuno** (espejo) sobre R1. Re-balance con el simulador. Codex/locale. |
| R3–R6 | Una transmutación nueva por paso: Caos Orquestado, Coro Simbiótico, Micelio Omnisciente, Huésped Soberano. Cada una con spec propia de números, bot, golden, logros, Codex ES/EN. |
| R7 | Retomar la auditoría de gameplay (A2/A3) con las rutas ya en su forma final. |

---

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
