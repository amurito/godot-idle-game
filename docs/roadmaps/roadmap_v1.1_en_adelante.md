# Roadmap v1.1 en adelante

Última actualización: 2026-10-12 · Reemplaza la sección "Próximas versiones" de
[`roadmap_post_v1.0.0.3.md`](roadmap_post_v1.0.0.3.md) (que queda como historial).

**Dónde estamos.** Publicado: `v1.0.3.0` (Codex + Fusión Catabólica). Sin publicar, ya en `main`:
Ayuno Primordial, sprint de deuda técnica (−80 % CPU, ~12 bugs de juego corregidos, CI con goldens),
rebalance de Fusión y transmutaciones excluyentes. Decisión del autor (2026-10-12): **no publicar
esto como parche suelto** — el regreso es `v1.1` y sale con una ruta nueva grande.

**Principios que rigen todas las versiones**
- Cada ruta nueva agrega **un sistema o una visibilidad**, no sólo un multiplicador
  ([`enciclopedia_rutas.md`](../design/enciclopedia_rutas.md) §9).
- Ninguna ruta entra sin: perfil de bot que la cierra (`tests/sim/Scenarios.gd`), trayectoria golden,
  entrada de Codex ES/EN y logro(s) verificados alcanzables por el bot.
- Comportamiento que cambia → goldens regrabados revisando el diff; refactor → goldens idénticos.
- CI (`.github/workflows/tests.yml`) en verde antes de cada release.

---

## v1.1 "Redención" — el regreso

Una versión que se pueda contar en una línea: *"el hongo aprende a sanar desde la vida"* — la segunda
ruta de REDENCIÓN — más todo lo que se hizo mientras el juego estaba quieto.

### Fase A — Auditoría de gameplay (antes de diseñar contenido nuevo)
> **Estado (2026-10-12):** A1 hecha. A2/A3 (perfiles de bot por final) **en pausa** a pedido del autor: antes se revisan los conceptos de transmutación / Sombra / Redención (pueden cambiar cómo se entra a varias rutas, y con eso los perfiles). Matriz y plan en [`auditoria_gameplay_2026-10.md`](../design/auditoria_gameplay_2026-10.md).

Objetivo: que cada final y cada logro sea **alcanzable jugando** (no vía DebugPanel) y que el
simulador sepa llegar a cada ruta por su **camino más rápido**.

| # | Entregable |
|---|---|
| A1 | Auditoría estática de los 81 logros: disparador → código que lo evalúa → condición satisfacible. Lista de inalcanzables / mal cableados. |
| A2 | Perfil de bot "camino más rápido" para cada uno de los 25 finales (matriz abajo). |
| A3 | Escenario por logro difícil (MYTHIC/ANCESTRAL/secretos) o justificación de por qué no es simulable. |
| A4 | Reporte: tiempo mínimo por ruta, rutas demasiado largas/cortas, finales sin PL definido, rutas que el bot no logra cerrar → bugs. |
| A5 | Trayectorias golden nuevas para las rutas que hoy no tienen ninguna. |

**Matriz de finales** (estado del perfil de bot al 2026-10-12)

| Familia | Final | Perfil de bot | Nota |
|---|---|---|---|
| T0 | HIPERASIMILACIÓN | ✅ `fresh_hiper` (180 s) | |
| T0 | PARASITISMO | ✅ `fresh_buy_all` / `fresh_idle` | |
| T0 | HOMEOSTASIS | ⚠️ `fresh_homeostasis` no cierra en 40 min | ¿bot o ruta? |
| T0 | SIMBIOSIS | ❌ | |
| Tier 2 | ALLOSTASIS · HOMEORHESIS | ❌ (bot tiene `allostasis`) | |
| Rama verde | ESPORULACIÓN · PANSPERMIA NEGRA | ⚠️ `fresh_red_micelial` termina en Parasitismo | |
| Rama azul | SINGULARIDAD · MENTE COLMENA DISTRIBUIDA | ❌ | SINGULARIDAD sin PL en `Balance.PL_REWARDS` |
| Depredador | COLAPSO DEPREDATORIO · DEPREDADOR DE REALIDADES · METABOLISMO OSCURO | ❌ | |
| Árbol oscuro | ESCLEROCIO · AUTOFAGIA · NECROSIS · OMEGA-CERO · COLAPSO SINTÉTICO · REMISIÓN | ❌ | COLAPSO SINTÉTICO sin PL |
| Post-trascendencia | ASCESIS PROFUNDA · DOMADOR DEL CAOS · POLIMORFÍA TOTAL · (Reencarnación) | ❌ | |
| Cósmico | COLAPSO CONTROLADO | ❌ | |
| Transmutaciones | FUSIÓN CATABÓLICA · AYUNO PRIMORDIAL | ✅ `ng_fusion_*` / `ng_ayuno_player` | |

### Fase B — 2ª Redención (la ruta nueva)
Diseño pendiente (decisiones abiertas abajo). Esqueleto acordado en la enciclopedia: sanar desde la
**vida**; un loop activo propio (no clonar la banda de REMISIÓN); involución táctica como fracaso.

| # | Entregable |
|---|---|
| B1 | Spec de diseño en `docs/design/` con el blueprint de transmutación/ruta (mismo formato que `fusion_catabolica.md`). |
| B2 | Implementación + Codex + logros + legado NG+. |
| B3 | Perfil de bot + golden + balance con el simulador (duración objetivo acordada antes de implementar). |

### Fase C — Calidad de vida y lanzamiento
- Prueba manual en Godot desktop **y web** (lo que los goldens no ven: input, visual, export).
- Selector/estado de transmutación visible ✅ (hecho: exclusión en Banco + título real).
- Localización del 2 % restante (LEGACY_DEFS) si entra en tiempo.
- Bump de versión, tag `v1.1.0`, export web + exe, itch.io, devlog *"el regreso"* (perf web −80 %,
  2 rutas nuevas desde la última versión pública: Ayuno + Redención II), marketing
  (r/incremental_games, Idle Sloth).

---

## v1.2 "Sombra II" — OBSERVAR
- **INESTABILIDAD CONSCIENTE** (anti-Homeostasis): deja de reducir ε y lo *usa*.
- Estrena el **botón OBSERVAR**: una capa de información nueva (la recompensa de las rutas Sombra es
  visibilidad, no multiplicadores) — se reutiliza en rutas posteriores y en el Laboratorio.
- Riesgo: es la ruta con más UI nueva; prototipar OBSERVAR primero.

## v1.3 "Redención III" o "Núcleo Aislado"
- La Redención que no se hizo en v1.1 (Orden ↔ Red Micelial) **cierra la trilogía** de Redención, o
- **NÚCLEO AISLADO** (anti-Red Micelial): economía de una sola célula.
- Elegir según lo que haya funcionado en v1.1/v1.2 (telemetría del hub + feedback).

## v1.4 "Fantasma" + secretos
- Combos de 2 transmutaciones: **DUALIDAD CORROSIVA**, **ECO SILENCIOSO**.
- Secretos: GLITCH SUPREMO, EL SUSURRO (ambos usan OBSERVAR).
- Prerrequisito: ≥ 3 transmutaciones existentes (Fusión, Ayuno, + la de v1.2/v1.3).

## v2.0 "El Jardín Primigenio"
- Meta-endgame: subjuego paralelo con save propio (`MetaEndgameManager`). Último por tamaño.
- Antes de empezarlo: auditoría de arquitectura nueva (patrón de esta, con goldens).

---

## Decisiones abiertas (para el autor)

| Tema | Opciones | Cuándo |
|---|---|---|
| Host de la 2ª Redención | Orden (rama azul: soltar el equilibrio perfecto sin caer en el caos) · Red Micelial (podar la colonia para que florezca) | Antes de Fase B |
| Duración objetivo de la ruta nueva | p.ej. 15–25 min como Fusión | Antes de B3 |
| Finales sin PL (SINGULARIDAD, COLAPSO SINTÉTICO) | definir valor o confirmar que heredan de otro | Fase A |
| Cadencia post-v1.1 | release por ruta (~v1.x cada ruta) vs. agrupar | Tras lanzar v1.1 |
