# Enciclopedia de Rutas — HYPHAE: genesis

> **Qué es este documento.** Índice maestro de TODAS las rutas del juego: implementadas, diseñadas-sin-implementar e ideas. Consolida [`lore_futuro.md`](lore_futuro.md), [`nuevas transmutaciones.md`](nuevas%20transmutaciones.md) y [`arquitectura_rutas.md`](arquitectura_rutas.md), y suma las dos direcciones nuevas: **REDENCIÓN** y el refinamiento de **INVOLUCIÓN como anti-A**.
> Última actualización: 2026-06-18 (v1.0.2.0).
>
> El detalle mecánico de cada ruta vive en su doc fuente; acá está el **mapa + la columna vertebral conceptual**.

---

## 0. La columna vertebral: INVOLUCIÓN

El endgame de HYPHAE se organiza en un arco filosófico:

| Fase | Verbo | Qué hace el jugador |
|---|---|---|
| **Evolución** | agregar | compra mutaciones, mejora, especializa |
| **Metabolismo Oscuro** | sobrevivir | las capacidades ya no alcanzan; sobrevive al colapso |
| **Involución** | renunciar | sacrifica capacidades para retroceder y abrir algo nuevo |
| **Meta-endgame** | recordar | descubre lo que existía *antes* de la evolución |

> *El jugador pasa la primera mitad aprendiendo a convertirse en algo. La segunda, aprendiendo a dejar de serlo.*

**INVOLUCIÓN no es una ruta — es el mecanismo.** Se manifiesta a dos escalas:

- **Involución TÁCTICA (intra-run):** una ruta falla y te manda atrás para reintentar distinto. Ya implementado en REMISIÓN (biomasa<30 → vuelve a Met. Oscuro, esa sub-ruta queda bloqueada esa run). No es derrota: es redirección. Patrón reutilizable.
- **Involución ESTRATÉGICA (meta-progresión):** revertir una mutación *ya completada* desde el Banco Genético (pagando PL). Es la **llave** que abre una rama nueva. *(Las transmutaciones son la llave, no la puerta.)*

La involución estratégica produce **dos familias de rutas según su tono emocional**:

- **SOMBRA (anti-A):** el opuesto doloroso de la mutación revertida. La ruta NO es una versión más fuerte de la mutación — es la consecuencia de haberla abandonado. `A → anti-A`, no `A → A+`.
- **REDENCIÓN (luminosa):** el camino de recuperación. Sanar en vez de colapsar. REMISIÓN es la primera.

**Principio de recompensa (clave):** la involución NO recompensa con un multiplicador. Recompensa con **un sistema nuevo o información antes invisible** (el botón OBSERVAR / una capa de juego). Igual que el árbol oscuro ya da Φ / núcleos / memorias / estados persistentes en vez de solo "×N producción".

---

## 1. Familias de rutas (taxonomía)

| Familia | Tono | Origen | Estado |
|---|---|---|---|
| **BIOLOGÍA** | crecimiento | rama verde (Red Micelial) + esporulación/panspermia | ✅ implementada |
| **ORDEN** | equilibrio | rama azul (Singularidad / Mente Colmena) | ✅ implementada |
| **COLAPSO** | supervivencia extrema | árbol oscuro (Met. Oscuro) | ✅ **completa** (v1.0.2.0) |
| **REDENCIÓN** | sanación | involución luminosa | 🌱 1 de N (REMISIÓN) |
| **SOMBRA** | renuncia / anti-A | involución estratégica | 💡 idea |
| **FANTASMA** | combos de reversión | 2+ transmutaciones | 💡 idea |
| **SECRETA** | easter egg | condiciones raras | 💡 idea |
| **META-ENDGAME** | recordar | subjuego paralelo | 💡 idea |

---

## 2. COLAPSO — el árbol oscuro (✅ COMPLETO)

Sub-rutas de Metabolismo Oscuro. Todas implementadas en v1.0.2.0. Detalle en [`lore_futuro.md`](lore_futuro.md) y memoria `project_post_tras_routes.md`.

| Ruta | Lección | Estado |
|---|---|---|
| **AUTOFAGIA NECRÓTICA** | consumirse para sostenerse | ✅ v1.0.2.0 |
| **NECROSIS CONTROLADA** | la fragilidad como herramienta | ✅ v1.0.2.0 |
| **ESCLEROCIO OSCURO** | el colapso intencional deja memoria | ✅ v1.0.0.11 |
| **PROTOCOLO OMEGA-CERO** | síntesis de las tres anteriores | ✅ v1.0.1.5 |
| **REMISIÓN METABÓLICA** | aprender a sanar *(→ familia REDENCIÓN)* | ✅ v1.0.2.0 |

> REMISIÓN nació dentro de COLAPSO pero **inaugura REDENCIÓN**: es el puente entre las dos familias.

---

## 3. REDENCIÓN — la involución luminosa (🌱 nueva)

Runs sobre **sanar / volver** en vez de colapsar. Contraparte luminosa de COLAPSO. La mecánica núcleo es la **involución táctica**: si fallás, retrocedés para reintentar.

| Ruta | Host | Lección | Estado |
|---|---|---|---|
| **REMISIÓN METABÓLICA** | Met. Oscuro | sanar desde la muerte | ✅ v1.0.2.0 |
| **REDENCIÓN DEL ORDEN** *(nombre tentativo)* | rama azul (Singularidad/Mente Colmena) | sanar desde el control | 💡 idea |
| **REDENCIÓN DE LA RED** *(nombre tentativo)* | rama verde (Red Micelial) | sanar desde la abundancia | 💡 idea |

**Frame narrativo:** *"El organismo aprendió a sanar desde la muerte. Todavía le queda aprender a sanar desde la vida."*

**Notas de diseño (sin mecánica definida aún):**
- Cada redención debería tener su propio "loop de banda" o equivalente activo, no clonar el de REMISIÓN. La de Orden podría ser sobre *soltar* el equilibrio perfecto sin caer en el caos; la de Red, sobre *podar* la colonia para que florezca.
- Reutilizan involución táctica como mecanismo de fracaso→reintento.
- Teaser ya sembrado en el devlog v1.0.2 (`docs/devlogs/devlog_v1.0.2_redencion.md`).

---

## 4. SOMBRA — la involución anti-A (💡 idea)

Revertir una mutación Tier-1 desde el Banco Genético abre su **opuesto mecánico**. La ruta es la consecuencia de *abandonar* la mutación, no una versión mejorada. Recompensa = sistema/visibilidad nueva, no multiplicador.

| Mutación | Lección | SOMBRA (anti-A) | Idea de mecánica |
|---|---|---|---|
| **Hiperasimilación** | consumir | **AYUNO PRIMORDIAL** | produce sin alimentarse durante minutos; mecánica opuesta a devorar |
| **Red Micelial** | conectar | **NÚCLEO AISLADO** | corta todas las conexiones; una célula vale más que la colonia |
| **Simbiosis** | cooperar | **AUTARQUÍA** | desaparecen los bonus compartidos; surge una economía nueva |
| **Homeostasis** | equilibrio | **INESTABILIDAD CONSCIENTE** | deja de reducir ε; lo *usa*. Desbloquea botón **OBSERVAR** → capa nueva |
| **Parasitismo** | dependencia | **AUTOSUFICIENCIA** | anula la corrosión; nueva fuente propia |
| **Depredador** | dominación | **OBSERVACIÓN** | deja de devorar; ve lo que antes consumía |

> ⚠️ **Scope.** Cada anti-A es una economía nueva entera (≈ una sub-ruta oscura de trabajo). **No comprometerse con las 6.** Elegir 2-3 con identidad mecánica fuerte. Candidatas más jugosas: **AYUNO** (opuesto limpio y legible), **INESTABILIDAD CONSCIENTE** (engancha con OBSERVAR + el lab/observatorio), **NÚCLEO AISLADO** (one-cell economy, distinto a todo).

**La llave (transmutaciones) — categoría nueva en `LegacyManager.LEGACY_DEFS`:**
- Aparecen tras trascender ≥1 + haber completado la mutación.
- Costo en PL (10-15) o más para las OP.
- Toggle activable/desactivable como los otros buffs.
- Ícono distintivo (ej: `⟳` sobre el emoji de la mutación).
- Categoría `"transmutaciones"` en el Banco.

---

## 5. FANTASMA — combos de reversión (💡 idea)

Requieren revertir **dos** mutaciones (o una + un hito). Tier `fantasma` (min_tras 3 + 2 transmutaciones).

| Requisito | Ruta | Semilla |
|---|---|---|
| Hiper + Parasitismo revertidos | **DUALIDAD CORROSIVA** | doble filo: muy OP con coste real |
| Red Micelial + Homeostasis revertidos | **ECO SILENCIOSO** | estado "silencioso": sin ε, Ω fijo alto, no podés mutar más; botón "Renacer" |

---

## 6. SECRETA / EASTER EGGS (💡 idea)

No cuestan PL; se activan por condiciones raras.

| Condición | Desbloqueo |
|---|---|
| Revertir Depredador tras activarlo | **GLITCH SUPREMO** — inestabilidad visual + ganancias ×rand(1.5,3) cada 10s |
| Revertir Metabolismo Oscuro | **EL SUSURRO** — buff 0 PL que requiere "haber sufrido"; tema Albino + botón OBSERVAR (stats ocultas) |
| Revertir las 5 mutaciones Tier-1 (entre runs) | **EL ORIGEN** — diálogo meta + título "Primigenio" |
| Todas las reversiones activas alguna vez | **EL HONGO QUE SE TRASCIENDE A SÍ MISMO** — logro + título |

Otros easter eggs cosméticos/diálogo en [`nuevas transmutaciones.md`](nuevas%20transmutaciones.md) (El Hongo Parlante, El Código Olvidado, El Origen de las Especies, El Abismo Te Responde).

---

## 7. META-ENDGAME — "El Jardín Primigenio" (💡 idea, scope grande)

**No es una ruta — es un subjuego paralelo** que corre mientras el juego principal sigue. Se accede tras revertir suficientes mutaciones ("Recordar"). Vive en `MetaEndgameManager` + escena `JardinPrimigenio.tscn`, con save propio.

- Cultivás una única espora que genera **Esencia Primigenia (EP)**.
- Jardín 3×3 de "Recuerdos" (fragmentos de runs pasadas) que dan buffs permanentes al juego principal (equipás 3 a la vez).
- Estética sepia/monocromo, música distinta.
- Final: **RETORNO AL ORIGEN** → mutación neutral "Esencia Primigenia" + legado "Semilla Eterna" + Galería de Recuerdos.

> Es el horizonte más lejano. Spec completa en [`nuevas transmutaciones.md`](nuevas%20transmutaciones.md) sección "META-ENDGAME". Mantener fuera del diseño de rutas hasta que SOMBRA/REDENCIÓN estén andando.

---

## 8. Arquitectura (cómo se enchufa todo)

Del [`arquitectura_rutas.md`](arquitectura_rutas.md) — ya parcialmente implementado (RouteManager Opción B mergeado 2026-06-06):

```
LegacyManager (Banco Genético)
 └─ categoría "transmutaciones"  ← LA LLAVE (revierte mutación + unlock_route)
        │ desbloquea
        ▼
RouteManager (registry único; tier / min_tras / requires / consumable)
 ├─ basica   (t≥1, consumible)   vacio / carnaval / reencarnacion        ✅
 ├─ colapso  (sub-rutas MO)      autofagia / necrosis / esclerocio / Ω-cero / remisión  ✅
 ├─ redencion (involución luminosa)  remisión + futuras (Orden, Red)     🌱
 ├─ sombra   (anti-A, t≥2 + transmutación)  ayuno / aislamiento / …      💡
 ├─ fantasma (t≥3, combos)       dualidad_corrosiva / eco_silencioso     💡
 └─ secreta                      glitch_supremo / el_susurro             💡

MetaEndgameManager + JardinPrimigenio.tscn   ← subjuego paralelo, save propio   💡
```

**Reglas del repo a respetar** (del arquitectura doc):
- Campo persistente nuevo → `SaveManager` serialize/deserialize.
- `RouteManager` después de `LegacyManager`/`SlotManager` en `[autoload]`.
- Estado que cambia con run/slot → `reset()`/`reload_for_slot()` explícito.
- Para agregar ruta: `routes/RouteX.gd extends PostTrasRoute` + entry en `ROUTE_DEFS` + case en `activate()`. Sin tocar RunManager/SaveManager/MainMenu.

---

## 9. Orden de implementación sugerido

1. **Categoría `transmutaciones` en el Banco** (la llave) — es prerequisito de SOMBRA y FANTASMA.
2. **1 ruta SOMBRA piloto** (recomendado: AYUNO PRIMORDIAL o INESTABILIDAD CONSCIENTE) — valida el patrón anti-A + OBSERVAR end-to-end antes de comprometerse a más.
3. **2ª REDENCIÓN** (Orden o Red) — extiende la familia que ya tiene a REMISIÓN de ancla.
4. Resto de SOMBRA elegidas + FANTASMA.
5. **Meta-endgame** (Jardín) — último, es el subjuego más grande.

> Regla de oro: cada ruta nueva debe **agregar un sistema o una visibilidad**, no solo un multiplicador. Si solo da ×N, es un buff de Banco, no una ruta.
