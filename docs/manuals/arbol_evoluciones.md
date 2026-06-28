# ÁRBOL DE EVOLUCIONES — HYPHAE: genesis
## Sistema completo · v1.0.3.0

> Familias de rutas: **ORDEN** (azul) · **BIOLOGÍA** (verde) · **COLAPSO** (rojo) · **REDENCIÓN** (teal) · **POST-TRASCENDENCIA** (violeta) · **SECRETO/FINAL** (magenta)

---

## NÚCLEO FÚNGICO

Estado inicial de cada run. El hongo observa el entorno y evalúa qué mutación activar.

---

## TIER 1 — Mutaciones principales

### 🔥 HIPERASIMILACIÓN · [COLAPSO]

**Condiciones:**
- Click domina >80% ingresos
- ε_runtime > 0.40
- Biomasa > 4.0
- Contabilidad = Nv.0
- Tiempo > 180s

**Efectos:**
- Click ×10 (RUSH extremo)
- Pasivo ×0.25 (−75%)
- Biomasa sin cap

**PL al cerrar:** 1
**Nota:** Si last_run = PARASITISMO, no cierra — espera DEPREDADOR.

---

### ☣️ PARASITISMO · [BIOLOGÍA]

**Condiciones (cualquiera):**
- Bio>6 + ε>0.35 + acc=0 + t>420s
- Inactividad (sin click >120s) + bio>3
- Estancamiento (t>1800s, bio>5)

**Efectos:**
- Crecimiento biomasa ×2
- Pasivo ×1.2 (inicial)
- Corrosión parasitaria (↓ click con tiempo)

**PL al cerrar:** 2
**Cierre:** bio≥15 + dinero<1000 · O · bio≥25 (masa crítica)

---

### 🕸️ RED MICELIAL · [RAMA VERDE]

**Condiciones:**
- Hifas ≥ 5.0
- ε entre 0.15–0.45
- Click domina (activo > pasivo)
- Contabilidad ≥ Nv.1

**Efectos:**
- Pasivo ×2.5, Click ×0.5
- Fase A → elegir rama: COLONIZACIÓN (biológica) o SIMB. MECÁNICA (azul)

---

### 🤝 SIMBIOSIS ESTRUCTURAL · [BIOLOGÍA]

**Condiciones:**
- Contabilidad ≥ Nv.1
- Hifas ≥ 3.0–5.0
- Ω ≥ 0.40
- Click domina (activo > pasivo)

**Efectos:**
- Click ×2.5
- Pasivo ×0.5
- ε disipado al 25% (biosfera)

**PL al cerrar:** 4
**Cierre:** 5min en banda estable · O · Ω≥0.50 por 60s (rama mecánica)

---

### ⚖️ HOMEOSTASIS · [ORDEN]

**Condiciones:**
- Contabilidad ≥ Nv.1 activa
- Biomasa > 1.0 O hifas > 2.0
- ε_runtime < 0.50
- Hifas < 8.0

**Efectos:**
- Pasivo ×1.5 (Orden Admin)
- Cap biomasa en 10.0
- Habilita sistema de perturbaciones

**PL al cerrar:** 3 → 4 → 8 (tiers progresivos: HOMEOSTASIS → ALLOSTASIS → HOMEORHESIS)

---

## TIER 2

### ☠️ DEPREDADOR DE REALIDADES · [COLAPSO · NG+]

**Prerequisito:** last_run = PARASITISMO

**Condiciones adicionales (dentro de HIPERASIMILACIÓN activa):**
- ε_runtime > 0.95
- Mantener 30s (18s con Árbol Acelerado)

**Efectos:**
- Devora un upgrade cada 1.5s
- Cada devour: +15 biomasa
- Desbloquea Legado: METABOLISMO GLITCH

**PL al cerrar:** 12

---

### Ramas de RED MICELIAL

#### 🌿 COLONIZACIÓN · [RAMA BIOLÓGICA]

Elegida en Fase A de Red Micelial.

**Transición Fase A→B:**
- Hifas ≥ 11.5, Biomasa ≥ 5.0, ε ≤ 0.65, Tiempo ≥ 200s

**Efectos:**
- Pasivo ×2.5 (bonus colonización)
- Habilita Primordio Biológico
- Cap biomasa sube a 20.0

#### ⚙️ SIMBIOSIS MECÁNICA · [RAMA AZUL]

Elegida en Fase A de Red Micelial.

**Transición Fase A→B:**
- Hifas ≥ 9.5, Biomasa ≥ 5.0, ε ≤ 0.35, Tiempo ≥ 200s

**Efectos:**
- Habilita Núcleo de Conciencia
- μ bonus por micelio
- Bonus contabilidad permanente

---

### 💜 ALLOSTASIS · [ORDEN · TIER 2]

**Condiciones (dentro de HOMEOSTASIS activa):**
- ≥ 3 perturbaciones sobrevividas
- Ω_min ≥ 0.40
- Resiliencia ≥ 150
- Contabilidad ≥ Nv.2
- Delta total > $200/s

**Efectos:**
- Otorga Legado: RESILIENCIA ALOSTÁTICA
- Ω_min garantizado ≥ 0.45 (NG+)

**PL al cerrar:** 4

---

## TIER 3

### 🌑 METABOLISMO OSCURO · [COLAPSO · NG++]

**Prerequisito:** DEPREDADOR activo

**Condiciones adicionales:**
- Devours acumulados ≥ 10
- Biomasa ≥ 50
- Mantener 15s (9s con Árbol Acelerado)

**Efectos:**
- Pasivo = Bio × 0.8/s
- Click ×3 (reemplaza ×10 de Hiper)
- ε decae automáticamente (−0.05/s)
- Ω bloqueado en 0.10 (fragilidad total)

**PL al cerrar:** 4
**Cierre:** Bio≥100 O Dinero≥$1M → PORTAL al ÁRBOL OSCURO (5 sub-rutas, ver más abajo)

---

### Hitos intermedios (RED MICELIAL)

#### 🍄 SETA FORMADA · [hito — no es final]

**Primordio Biológico (90s):**
- Hifas ≥ 14.5, Biomasa ≥ 8.0, ε < 0.50 durante 90s, Delta > $50/s durante 90s, Hifas < 60 durante 90s

Habilita: Esporulación (botón) + Bonus esporas ×3 al cerrar.

#### 💾 NÚCLEO DE CONCIENCIA · [hito — no es final]

**Primordio Mecánico (90s):**
- Contabilidad ≥ Nv.2, ε ≤ 0.25 durante 90s

Habilita: SINGULARIDAD (botón) + +0.20 bonus contabilidad permanente.

---

### 💎 HOMEORHESIS · [ORDEN · TIER 3]

**Condiciones (dentro de ALLOSTASIS alcanzada):**
- Shock EXTREMO sobrevivido
- Resiliencia ≥ 400
- Ω_min ≥ 0.50
- ≥ 5 perturbaciones sobrevividas
- Delta > $300/s
- Tiempo ≥ 1200s (20 min)

**Efectos:**
- Otorga Legado: TRASCENDENCIA CRISTALINA
- Ω_min garantizado ≥ 0.55 (NG+)
- Penalización shocks −50%

**PL al cerrar:** 8

---

## TIER 4 — Finales principales

### 🌱 ESPORULACIÓN · [BIOLOGÍA]

**Requiere:** Seta Formada (hito completado) + botón manual.

**Efectos:**
- Biomasa colapsa al 10%
- Genera esporas (→ PL)
- Con Seta: esporas ×3

**PL al cerrar:** 5

---

### ⚡ SINGULARIDAD MECÁNICA · [ORDEN]

**Requiere:** Núcleo de Conciencia (hito completado) + botón manual.

**Efectos:**
- PL = 6 + bonus por estabilidad (ε bajo)
- Bonus max: +5 PL si ε ≈ 0

**PL al cerrar:** 6–11

---

## TIER 5 — Secretos / NG+

### 🚀 PANSPERMIA NEGRA · [BIOLOGÍA · SECRETO]

**Prerequisitos:** last_run = ESPORULACIÓN + Primordio activo en run actual + $100.000 gastados + botón manual.

**Efectos:**
- Otorga Legado: SEMILLA CÓSMICA
- Las esporas llegan al espacio exterior

**PL al cerrar:** 10

---

### 🧠 MENTE COLMENA DISTRIBUIDA · [BIOLOGÍA · NG+]

**Prerequisito:** last_run = SINGULARIDAD

**Condiciones adicionales:**
- Rama SIMB. MECÁNICA activa
- Ratio activo/pasivo = 50% ± 2%
- Mantener 180s
- ε < 0.50 durante el proceso

**Efectos:**
- IA auto-click activa permanente
- Auto-compra upgrades cada 8s
- Otorga Legado: MENTE COLMENA (Pasivo ×3 NG+)

**PL al cerrar:** 8

---

## 🌀 TRASCENDENCIA

**Requisitos:**
- 1 ruta de FAMILIA ORDEN
- 1 ruta de FAMILIA BIOLOGÍA
- 1 ruta de FAMILIA COLAPSO
- PL acumulado ≥ 50

**Recompensa:**
- Esencia (Ξ) = PL/10 + rutas×5 + ciclos×2
- Banco Cósmico desbloqueado (NG+)
- Buffs cósmicos permanentes
- Run se reinicia con buffs activos

**Reset:** PL, buffs, esporas, total runs
**Preserva:** Ξ, rutas completadas, cósmicos

---

### Familias que cuentan para Trascendencia

**ORDEN:** HOMEOSTASIS · ALLOSTASIS · HOMEORHESIS · SINGULARIDAD

**BIOLOGÍA:** PARASITISMO · SIMBIOSIS · ESPORULACIÓN · PANSPERMIA NEGRA · MENTE COLMENA DIST.

**COLAPSO:** HIPERASIMILACIÓN · DEPREDADOR DE REALIDADES · METABOLISMO OSCURO
↳ ESCLEROCIO OSCURO · AUTOFAGIA NECRÓTICA · NECROSIS CONTROLADA · PROTOCOLO OMEGA-CERO
↳ REMISIÓN METABÓLICA (redención)

---

## POST-TRASCENDENCIA — 3 caminos (NG+)

### 🔵 VACÍO HAMBRIENTO → ✨ ASCESIS PROFUNDA

**Fase preparatoria (Vacío Hambriento):**
- Run ≥ 15 min · Dinero ≥ $1M

**Final (Ascesis Profunda):**
- Biomasa < 0.5
- Sin auto-pasivo (auto=0, trueque=0)
- ε_runtime < 0.25 durante 300s

**Efectos:** Logro VACÍO ABSOLUTO. Máxima purificación del sistema.
**PL al cerrar:** 7

---

### 🎪 CARNAVAL DE MUTACIONES → dos finales

Rotación automática cada 60s. Pool: homeostasis, simbiosis, red_micelial, parasitismo, hiperasimilacion.

**🎭 POLIMORFÍA TOTAL (12+ rotaciones):**
- Biomasa ≥ 8.0, Ω ≥ 0.35, Dinero ≥ $300K
- Legado: MEMORIA POLIMÓRFICA (Pasivo ×1.25, biomasa inicial +1.5)
- PL al cerrar: 9

**👑 DOMADOR DEL CAOS (3+ rotaciones + $1M):**
- Domina caos mutacional
- Legado: MEMORIA DEL CAOS (Todos los ingresos ×1.30 NG+)
- PL al cerrar: 11

---

### ⚱️ REENCARNACIÓN HEREDADA → 🔄 REENCARNACIÓN CONSUMADA

**Fase preparatoria:** snapshot de upgrades guardado, costos ×1.5.

**Final (Reencarnación Consumada):**
- $800K dinero, Ω ≥ 0.40, ε_peak ≥ 0.60, n > 30 upgrades estructurales

**Efectos:** Hongo supera encarnación anterior.
Legado: MEMORIA DEL CICLO (Todos los upgrades −15% NG+)
**PL al cerrar:** 8

---

## 🌑 ÁRBOL OSCURO — Sub-rutas de Metabolismo Oscuro

Se activan DENTRO de Metabolismo Oscuro (no son rutas post-trascendencia). Las cuatro primeras son familia COLAPSO; REMISIÓN inaugura la familia REDENCIÓN. OMEGA-CERO requiere cerrar las 3 anteriores; REMISIÓN, las 4.

**Gates de acceso (v1.0.3.0):** las rutas oscuras requieren permisos del Banco Genético (PL) además de las condiciones en-run.

---

### 🌰 ESCLEROCIO OSCURO · [COLAPSO]

**Gate (dentro de MO):**
- Devorados ≥ 30, Biomasa ≥ 50, ε_runtime < 0.25

**Efectos:** Cápsula de dormancia. Otorga SEMILLA DURMIENTE (Memoria Oscura): +15% bio, ε resiste, −10% threshold MO en TODAS las runs mientras haya carga.

**PL al cerrar:** 6 (NG+ hasta 8)
**Cruce → Panspermia Negra:** desbloquea SEMILLA CÓSMICA OSCURA (×3 pasivo)

---

### 🩸 AUTOFAGIA NECRÓTICA · [COLAPSO]

**Gate:** Biomasa ≥ 50 + ≥ 5 niveles de upgrades

**Efectos:** Loop activo — cada 30s→5s devora el upgrade más caro → burst de $ y bio. Click ×5, Pasivo ×2. Recomprás para realimentar. Enzimas (velocidad) + Fagocitosis (2º/3º devour).

**PL al cerrar:** 6 (NG+ hasta 8)
**Cierre:** COLAPSAR (≥40 devours) o agotamiento.
**Buffs:** Catabolismo Heredado, Ciclo Catabólico

---

### 💀 NECROSIS CONTROLADA · [COLAPSO]

**Gate:** Biomasa ≥ 50 + flujo total ≥ $200/s

**Efectos:** Doble economía — el flujo genera NECROMASA (Ν) por click. Con Ν comprás Agentes (Ω ×0.72 c/u). Renta ×(0.10/Ω), cap ×25. Gestionás TOXICIDAD o purga.

**PL al cerrar:** 5 (NG+ hasta 8)
**Cierre:** Ω ≤ 0.001. 100% anti-AFK.
**Buffs:** Apoptosis Heredada, Plasticidad Terminal

---

### ⬛ PROTOCOLO OMEGA-CERO · [COLAPSO · permiso 12 PL]

**Permiso (Banco):** cerrar AUTOFAGIA + NECROSIS + ESCLEROCIO

**Gate:** Biomasa ≥ 50 + 5 devours previos

**Efectos:** Síntesis de las 3 anteriores. Genera Φ rigidizando Ω. Sello a Φ ≥ 300. El Núcleo Φ logrado determina la potencia del buff.

**PL al cerrar:** 8 (NG+ hasta 12)
**Buffs:** Memoria Sináptica, Síntesis Vital
**Logro Mythic:** Φ≥500 ∧ Ω≤0.01

---

### 🌿 REMISIÓN METABÓLICA · [REDENCIÓN · permiso 15 PL]

**Permiso (Banco):** cerrar las 4 sub-rutas oscuras

**Gate:** Biomasa ≥ 150 en MO

**Efectos:** El final luminoso. Ω deriva al colapso; la empujás (W/S) para mantenerla en una BANDA móvil → la biomasa florece +3%/s. Sello a Θ ≥ 60s dentro de banda.

**Involución:** si bio < 30, volvés a Met. Oscuro — ir atrás para tomar impulso.

**PL al cerrar:** 8 (NG+ hasta 12)
**Buff:** Control de Ω (empuje manual + producción)
**Logro Mythic:** Remisión Completa

---

## TRANSMUTACIONES (Banco Genético — categoría especial)

Las transmutaciones modifican una mutación existente en vez de agregar una ruta nueva. Requieren comprar el buff correspondiente en el Banco Genético antes del run.

### ⊗ FUSIÓN CATABÓLICA (transmutación de HIPERASIMILACIÓN)

**Requisito:** buff `transmut_fusion` activo en Banco Genético.

**Disparo:** las mismas condiciones de HIPERASIMILACIÓN + Contabilidad = 0 (Contabilidad bloquea la transmutación).

Condiciones de entrada:
- activo > 80%, ε_runtime > 0.40, biomasa > 4, accounting = 0, run_time > hiper_req

**Economía durante la transmutación:**
- Click ×5, Pasivo ×5 (estables)
- Ráfaga [Q] "Metabolismo Híbrido": ×2 durante 30s, cooldown base 120s
- Reducción de cooldown [W]: −20% compounding por nivel, piso 30s, costo $10M × 1.9^n

**Condiciones de sello:**
- Upgrades estructurales ≥ 150
- Dinero generado (total acumulado) ≥ $100M
- Ráfagas activadas ≥ 3

**Recompensa permanente:** `legado_motor_fundido` — +25% all_income_mult (stackeable).

**Logros:**
- Motor Singular (ANCESTRAL): cerrar run con ruta FUSIÓN CATABÓLICA
- Coloso Estructural (MYTHIC): cerrar run con $1B generado + n≥200 upgrades estructurales

> Spec completa: `docs/design/fusion_catabolica.md`

---

*Última actualización: 2026-06-28*
