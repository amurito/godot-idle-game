# 🗺️ ROADMAP — IDLE FUNGI

## 📍 SITUACIÓN ACTUAL — v0.8.2

### ✅ Sistemas COMPLETOS

| Sistema | Estado | Notas |
|---|---|---|
| **Economía** | ✅ Sólido | click/auto/trueque + biomasa + μ + 8 multiplicadores |
| **Estructural** | ✅ Sólido | ε, Ω, persistence, accounting, perturbaciones |
| **Mutaciones (Tier 1)** | ✅ 5/5 | Hiper, Parasitismo, Red Micelial, Simbiosis, Homeostasis |
| **Tiers Homeostasis** | ✅ 3/3 | Homeo → Allostasis → Homeorhesis |
| **Rama Verde** | ✅ 2/2 | Colonización → Esporulación → Panspermia (secreto) |
| **Rama Azul** | ✅ 2/2 | Simb. Mecánica → Singularidad → Mente Colmena (NG+) |
| **NG+ Colapso** | ✅ 2/2 | Depredador → Metabolismo Oscuro |
| **Banco Genético** | ✅ 40/40 | Todos los efectos mecánicos implementados (recién) |
| **Banco Cósmico** | ✅ 10/10 | Tier 1/2/3 todos funcionales |
| **Trascendencia** | ✅ Funcional | 3 familias gate + PL ≥ 50 + post-trans handling |
| **Esencia (Ξ)** | ✅ Funcional | Cálculo, persistencia, gasto |
| **Logros** | ✅ ~30+ | AchievementManager activo |

### ⚠️ Sistemas PARCIALES

| Sistema | Estado | Faltante |
|---|---|---|
| **UI Layout** | 🟡 50% | Plan `jolly-fluttering-seahorse` solo Phase 1 hecho |
| **Tutorial / onboarding** | 🟡 30% | Notificaciones existen, falta guía estructurada |
| **Testing** | 🟡 ~40% | Test runner existe, cobertura parcial |
| **Lab Mode** | 🟡 80% | Funcional (tecla L) pero falta polish |

### 🔧 Deuda Técnica Conocida

- `main.gd` ~1700 líneas — mezcla logic + UI + signals
- Algunos formula labels duplicados entre managers
- `MainMenu.gd` tiene lógica que debería estar en SaveManager
- Falta separar EvoManager por ramas (red_micelial vs orden vs colapso)

---

## 🎯 FASE INMEDIATA — v0.9 "Post-Trascendencia"

> **Objetivo:** Dar contenido a quien ya trascendió. Hoy el juego "termina" en trascendencia +1; queremos que la 2da, 3ra, 4ta sean *distintas*.

### 🔥 Sprint 1 — Las 3 Rutas Post-Trascendencia (4-6 semanas)

#### 🕳️ VACÍO HAMBRIENTO *(complejidad: media)*
- **Pre-requisitos en código:** sistema de "consumir buff cósmico" (no existe)
- **Archivos a tocar:** `LegacyManager.gd`, `EvoManager.gd`, `main.gd`
- **Riesgo:** medio — hay que cambiar `cosmic_unlocked` para soportar consumo temporal
- **Tiempo estimado:** 1.5 semanas
- **Por qué primera:** se apoya en sistema existente (Banco Cósmico), poco código nuevo

#### 🎭 CARNAVAL DE MUTACIONES *(complejidad: alta)*
- **Pre-requisitos en código:** rotación de mutaciones sin reset (no existe — hoy las mutaciones son irreversibles)
- **Archivos a tocar:** `EvoManager.gd` (mucho), `BiosphereEngine.gd`, `EconomyManager.gd`
- **Riesgo:** alto — rompe el contrato "mutación = irreversible"
- **Tiempo estimado:** 2.5 semanas
- **Por qué segunda:** reusa lógica de cada mutación, pero la rotación es nueva

#### ⚱️ REENCARNACIÓN HEREDADA *(complejidad: media-alta)*
- **Pre-requisitos en código:** sistema de "deuda" como contra-recurso (no existe)
- **Archivos a tocar:** `UpgradeManager.gd`, `MainMenu.gd`, `LegacyManager.gd`
- **Riesgo:** medio — afecta el inicio de run, fácil regresión
- **Tiempo estimado:** 1.5 semanas
- **Por qué tercera:** requiere mecánica nueva (deuda) pero contenida

**Hito v0.9:** las 3 rutas activas + indicador visual en árbol + condiciones de unlock + 1 logro por cada una.

---

### ⚙️ Sprint 2 — Polish & UI (2-3 semanas)

- Continuar plan **`jolly-fluttering-seahorse`** (UI rework Phases 2-6)
- Indicador visual de **condiciones cósmicas activas** en HUD (hoy son invisibles)
- Panel de **trascendencias acumuladas** con título cosmético (Trascendido → Demiurgo)
- Tooltip de árbol de evoluciones in-game (no solo en HTML doc)

---

## 🌌 FASE MEDIANA — v0.9.5 "Expansión Cósmica"

> **Objetivo:** Profundizar el meta-loop. Que trascender N veces sea progresivamente distinto.

### 📦 Sprint 3 — Más Rutas Post-Trascendencia (6-8 semanas)
Las restantes 10 rutas del brainstorming, en orden de impacto/complejidad:

| # | Ruta | Complejidad | Mecánica clave |
|---|---|---|---|
| 4 | ⚛️ FUSIÓN PARADÓJICA | Media | Invertir efecto ε/Ω |
| 5 | 🪞 DUALIDAD IMPOSIBLE | Alta | Doble run paralela |
| 6 | 🧬 GENOMA RECURSIVO | Media | Compound de buffs cósmicos |
| 7 | 🦇 VAMPIRISMO ESTRUCTURAL | Baja | Roba entre upgrades |
| 8 | 🌠 ENJAMBRE ETERNO | Muy alta | N runs ghost simultáneas |
| 9 | 🏛️ INSTITUCIONALIZACIÓN | Baja | Quitar cap de accounting |
| 10 | 📡 BROADCAST UNIVERSAL | Media | Mejora retroactiva |
| 11 | ⏳ NECROSIS TEMPORAL | Alta | Toca el LOGIC_TICK |
| 12 | 🔬 ARQUITECTO | Muy alta | Modificar constantes |
| 13 | ☄️ APOCALIPSIS | Media | Run de 60s exacto |

**No todas tienen que entrar.** Sugerencia: **6-8 de las 10**, descartando las más quirúrgicas (Arquitecto, Enjambre).

---

### 🏆 Sprint 4 — Sistema de Logros Legendarios (1-2 semanas)

- Logros por trascender N veces
- Logros por completar N rutas post-trascendencia
- Logros "speedrun" (trascender en menos de X minutos)
- Logros "completionist" (todas las rutas + todos los buffs)
- Cada logro otorga título + Ξ bonus

---

### 🎚️ Sprint 5 — Balance Pass (2 semanas)

- Revisar curva de PL: ¿sigue siendo accesible llegar a 50 después del nerf de v0.8?
- Revisar valor de cada buff cósmico: ¿alguno es OP/UP?
- Revisar tiempo medio para 1ra trascendencia (target: ~2 horas)
- Revisar tiempo medio para 5ta trascendencia (target: ~10-15 horas)

---

## 🚀 FASE LARGA — v1.0 "Lanzamiento"

> **Objetivo:** Pulir y empaquetar. El juego está completo en mecánicas; ahora hay que hacerlo *vendible*.

### 🎨 Sprint 6 — Narrativa (3-4 semanas)
- Diálogos / textos narrativos por ruta (hoy son flavor texts cortos)
- Cinemática mínima al cerrar cada ruta única (text-based, estilo terminal)
- Lore document (¿Quién es el hongo? ¿Quién observa?)
- Final secreto: "**EL OBSERVADOR**" — desbloqueado al completar TODAS las rutas

### 🎵 Sprint 7 — Audio (2-3 semanas)
- 5-7 tracks ambiente (uno por familia + variantes post-trascendencia)
- SFX para click, compra, perturbación, mutación, trascendencia
- Volumen master + por categoría

### 🏗️ Sprint 8 — Arquitectura (2 semanas)
- Refactor `main.gd` → separar en `MainController.gd` + `UIController.gd`
- Test coverage objetivo: 70%+
- Performance pass: ¿el juego corre fluido en 1000+ runs?

### 📦 Sprint 9 — Distribución (1-2 semanas)
- Build para Windows / Linux / Mac
- Save migration (compatibilidad con saves de v0.8/0.9)
- Steam page / itch.io
- Trailer corto

---

## 🌠 FASE FUTURA — Post v1.0 (opcional)

| Idea | Complejidad | Valor |
|---|---|---|
| **DLC narrativo** — más rutas con storyline | Alta | Medio |
| **Mobile port** — tap-friendly UI | Muy alta | Alto |
| **Modding** — exponer LegacyManager y UpgradeDef como editables | Media | Bajo |
| **Multi-save** — 3 perfiles paralelos | Baja | Medio |
| **Cloud save** — Steam Cloud | Baja | Medio |
| **Daily challenges** — semilla diaria con modificadores | Media | Alto |

---

## 📊 Resumen Visual del Roadmap

```
v0.8.2 (HOY)  ────────────────●────────────────────────────────────►
                              │
                              ├─ Sprint 1: 3 rutas post-trans  (~5 sem)
                              ├─ Sprint 2: UI polish           (~2 sem)
                              │
v0.9          ────────────────────────●────────────────────────────►
                                       │
                                       ├─ Sprint 3: +10 rutas  (~7 sem)
                                       ├─ Sprint 4: logros     (~2 sem)
                                       ├─ Sprint 5: balance    (~2 sem)
                                       │
v0.9.5        ──────────────────────────────────●─────────────────►
                                                 │
                                                 ├─ Sprint 6: narrativa (~3 sem)
                                                 ├─ Sprint 7: audio     (~3 sem)
                                                 ├─ Sprint 8: arch     (~2 sem)
                                                 ├─ Sprint 9: release  (~2 sem)
                                                 │
v1.0          ──────────────────────────────────────────●─────────►
                                                        │
                                                        └─ Post-launch: opcional
```

**Tiempo total estimado v0.8 → v1.0:** ~7-9 meses solo, ~3-5 meses con dedicación intensa

---

## 🎯 Decisión Inmediata

**Próximo paso concreto:** Diseñar en detalle **🕳️ VACÍO HAMBRIENTO** (Sprint 1, ruta 1)
- ¿Cómo se desbloquea visualmente? (¿botón en el árbol? ¿condición silenciosa?)
- ¿Cuántos buffs cósmicos puede devorar por run? (¿1? ¿todos?)
- ¿El consumo es permanente o solo para esa run?
- ¿Cómo se balancea con `arbol_acelerado` y otros que afectan timing?

¿Arrancamos por ese diseño detallado, o querés ajustar el roadmap primero?