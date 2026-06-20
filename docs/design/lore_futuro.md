# Lore Futuro — Rutas Post-METABOLISMO OSCURO

> Documento de diseño narrativo. Ideas generadas 2026-05-20.
> Contexto: METABOLISMO OSCURO es la ruta final del árbol Depredador.
> El hongo activó bioquímica alternativa "que la ciencia no predijo" sobreviviendo
> con < 20% recursos, Ω forzado a 0.10, upgrades bloqueadas, alimentado solo por
> biomasa oscura y devours previos.

---

## Premisas del árbol

El hongo llegó a Dark Met por: Hiperasimilación → Depredador (3+ devours) → colapso de recursos sostenido 15s.
Es un organismo que sobrevivió lo imposible a través de la depredación y luego de la autosuficiencia extrema.
Cualquier ruta posterior hereda ese trauma y esa capacidad.

---

## Rama A — Profundizar en la oscuridad

### AUTÓLISIS DIRIGIDA
*"La ciencia llama a esto autofagia. El hongo lo llama almuerzo."*

El hongo descubre que puede digerir sus propias estructuras para liberar energía concentrada.
Como un árbol en otoño: la destrucción controlada como estrategia de supervivencia.

**Condición de activación:** Bio ≥ 50 dentro de Dark Met + al menos 5 upgrades comprados en la run
**Mecánica:**
- Cada 30s el hongo "consume" un upgrade (destruye 1 nivel del más caro disponible)
- Cada consumo → burst masivo de $ y bio
- Al quedarse sin upgrades el hongo colapsa → run closes forzosamente
**Tensión:** cuánto esperás para activarla vs. cuándo te quedás sin material
**Efectos:** Click ×5, Passive ×2 durante los últimos devours, PL base +6
**Negativo:** No hay forma de parar la autólisis una vez iniciada
**Flavor:** *"Los restos de lo que construiste ahora te sostienen. Irónicamente, era lo que necesitabas siempre."*

---

### NECROSIS CONTROLADA
*"Morir en partes es sobrevivir en totalidad."*

Los segmentos periféricos del micelio mueren deliberadamente para nutrir el núcleo central.
La fragilidad extrema de Ω se convierte en la herramienta.

**Condición:** Dark Met activo + Ω decae a ≤ 0.05 naturalmente (sin intervención)
**Mecánica:**
- Ω sigue cayendo hasta 0.02
- Pero cada tick de ε genera burst pasivo proporcional a (1/Ω): cuanto más frágil, más productivo
- Si Ω toca 0 sin haber llegado a Bio ≥ 75 → colapso total
**Tensión:** la mecánica es maximizar producción mientras Ω se desintegra
**PL:** base +5, +3 adicionales si Bio ≥ 75 antes del cierre
**Flavor:** *"La periferia se sacrifica. El centro recuerda."*

---

### PROTOCOLO OMEGA-CERO — ✅ IMPLEMENTADO (v1.0.1.5, 2026-06-13)

> Diseño original descartado (Singularidad Inversa 45s + passive→click). Rediseñado como
> loop activo que sintetiza las tres rutas oscuras previas. La mecánica anterior no tenía
> gameplay claro y el gate ("Ω llega naturalmente a 0.01" dentro de Necrosis) era
> contradicción — en Necrosis, Ω solo baja al comprar Agentes, no hay decay pasivo.
> Implementado y validado con parse-check headless. Constantes en `Balance.gd` (bloque OMEGA_CERO_*).

*"De la autofagia aprendió que destruir lo propio genera más energía que conservarlo. De la necrosis aprendió que la rigidez extrema no es una falla sino una herramienta. Del esclerocio aprendió que el colapso puede ser intencional, preciso, y dejar algo atrás. El Protocolo Omega-Cero es la síntesis: el hongo ejecuta los tres simultáneamente. Ya no sobrevive a través de uno. Los sintetiza en un único acto final."*

**Color reactor:** `Color(0.28, 0.18, 0.38)` — gris oscuro-violáceo (no colisiona con MO `(0.53,0.27,0.67)` ni VACÍO `(0.75,0.2,1.0)`)

**Desbloqueo — Banco Genético:**
- Costo: **12 PL** (el más caro del banco; refleja que es el endgame del árbol oscuro)
- Condición de disponibilidad para comprar: `endings_achieved` contiene los tres:
  `"AUTOFAGIA NECRÓTICA"`, `"NECROSIS CONTROLADA"`, `"ESCLEROCIO OSCURO"`
  (en distintas runs, no necesariamente en la misma)
- Una vez comprado: aparece como botón `[IRREVERSIBLE]` dentro de MO, como Autofagia y Necrosis

**Gate en-run (botón en RightPanel):**
- `mutation_met_oscuro == true`
- `biomasa >= OMEGA_CERO_BIO_REQ` (sugerido: 50, igual que Autofagia/Necrosis)
- `met_oscuro_devoured_count >= OMEGA_CERO_DEVOUR_REQ` (sugerido: 5 — ya demostró que puede devourar)
- `not run_closed`

**Recurso central: Φ (Phi)**
- Chip en header: `"Φ %.0f / %.0f" % [phi, PHI_TARGET]` — color `#8a6fa8`
- `PHI_TARGET = 100` (constante en Balance.gd)
- Φ se acumula exclusivamente via el loop de devour

**Mecánica — tres ecos simultáneos:**

*Eco autolítico (de Autofagia):*
- Loop de devour: cada `omega_cero_devour_interval()` segundos devora el upgrade más caro
- Cada devour genera Φ base: `phi_per_devour = OMEGA_CERO_PHI_BASE * omega_cero_phi_mult()`
- Compras siguen abiertas (recomprar para realimentar — mismo patrón que Autofagia)
- Las mejoras de velocidad de Autofagia (Enzimas Líticas) NO aplican aquí — intervalo propio

*Eco necrótico (de Necrosis):*
- Cada devour reduce Ω: `necrosis_omega *= OMEGA_CERO_OMEGA_FACTOR` (ej: ×0.82)
- El multiplicador de Φ por devour escala con la rigidez actual:
  `omega_cero_phi_mult() = min(OMEGA_CERO_K / StructuralModel.omega, OMEGA_CERO_PHI_CAP)`
  donde `OMEGA_CERO_K = 0.10` → a Ω=0.10: mult=1.0; a Ω=0.01: mult=10.0 (capeado)
- Sin clicks → sin $ → sin recompras → sin devours → sin Φ → sin baja de Ω

*Eco escleroidal (de Esclerocio):*
- El cierre es intencional: botón **SELLAR PROTOCOLO** se habilita cuando `phi >= PHI_TARGET`
- No hay cierre automático por tiempo (el hongo decide cuándo está listo)
- Cierre de emergencia si Ω llega a floor absoluto `NECROSIS_OMEGA_FLOOR = 0.001` (mismo del sistema)
- El "Núcleo Φ" al cierre se preserva como escalar que determina la intensidad del buff NG+:
  `omega_cero_kernel = phi / PHI_TARGET` (ej: si cerró con 200 Φ → kernel = 2.0, capeado en 3.0)

**Cierre y PL:**
- `PL_REWARDS["PROTOCOLO OMEGA-CERO"] = 8`
- NG+ bonus: `floor(omega_cero_devour_count / 4)` cap 12 en `NG_CAPS`
- Final route string visible: `"PROTOCOLO OMEGA-CERO"`

**Buff NG+ — "Memoria Sináptica" (`memoria_sinaptica`):**
Agrega un término pasivo en `get_passive_total()` que crece exponencialmente con la caída de Ω, acotado por CAP:

```
k_efectivo = OMEGA_CERO_BUFF_K_BASE * clamp(omega_cero_kernel, 1.0, 3.0)
             donde OMEGA_CERO_BUFF_K_BASE ≈ 3.5

P_Ω = min(exp(k_efectivo * (1.0 - Ω)) - 1.0, OMEGA_CERO_BUFF_CAP)
```

Comportamiento:
- A Ω=1.0 (run normal): P_Ω ≈ 0 — buff inerte
- A Ω=0.10 (MO estándar): P_Ω ≈ 30 $/s adicionales (con kernel=1, k=3.5)
- A Ω=0.01 (Omega-Cero profundo): P_Ω → CAP
- `OMEGA_CERO_BUFF_CAP`: suficiente para ser relevante en árbol oscuro pero no romper runs normales
  (sugerido: ~50.000 $/s o `20 × pasivo_base_de_la_run` — a calibrar en balance)

Intensidad variable: kernel más alto (más Φ acumulado antes de sellar) → k más alto → curva más empinada → más pasivo en el régimen de Ω baja. Incentiva no sellar en el mínimo de 100Φ.

Reveal/unlock: `route_closed: "PROTOCOLO OMEGA-CERO"` (gratis al cerrar la 1ª vez, igual que Apoptosis y Catabolismo).

**Cross-link con REMISIÓN METABÓLICA — "Síntesis Vital" (`sintesis_vital`):**
- Flag: `omega_remision_done: bool` en LegacyManager (persiste al trascender)
- Condición: haber cerrado REMISIÓN METABÓLICA teniendo OMEGA-CERO en `endings_achieved` (o viceversa)
- Efecto: cuando simultáneamente `Ω < 0.20` Y `biomasa >= 80`, click + pasivo ×2.0
- Lore: *"El hongo que tocó el piso absoluto y el hongo que se recuperó al máximo aprendieron que colapso y crecimiento son el mismo proceso."*
- Costo en Banco Genético: 8 PL, unlock condición `legacy_flag: omega_remision_done`
- ⚠️ El placeholder en LEGACY_DEFS se agrega al implementar OMEGA-CERO aunque REMISIÓN no esté implementada

**Estado/Save (bloque `evolution` en SaveManager):**
```
mutation_omega_cero: bool
omega_cero_phi: float
omega_cero_devour_count: int
omega_cero_devour_timer: float
omega_cero_kernel: float        # se fija al cerrar, persiste para el buff
```

**Debug (DebugPanel):**
- "Activar Omega-Cero"
- "+50 Φ"
- "Marcar Autofagia+Necrosis+Esclerocio" (para testear el desbloqueo en Banco)

**Logro Mythic "Singularidad Perfecta"** (`singularidad_perfecta`, secret, AchievementDefs):
- Sellar PROTOCOLO OMEGA-CERO con `omega_cero_phi >= OMEGA_CERO_ACH_PHI(200)` Y `omega_cero_omega <= OMEGA_CERO_ACH_OMEGA(0.01)`.
- Premia dejar correr la síntesis hasta el borde en vez de sellar al mínimo (100Φ). Evaluador custom `_eval_singularidad_perfecta` + dispatch en `on_run_closed`.

---

**Archivos tocados en la implementación:** `Balance.gd` (constantes + PL_REWARDS + NG_CAPS), `EvoManager.gd` (estado + reset + gate/activate/loop/seal/finalize), `SaveManager.gd` (6 campos con _sf), `StructuralModel.gd` + `main.gd` (override Ω + dispatch loop + hotkey [R]), `EconomyManager.gd` (click ×5 + pasivo + memoria_sinaptica aditivo + sintesis_vital), `UpgradeManager.gd` (can_buy excepción), `UIManager.gd` (2 botones + chip Φ + reactor color + exclusión mutua), `UITextBuilders.gd` (lore + status genoma), `LegacyManager.gd` (flags omega_remision_done + omega_cero_kernel_max + record_omega_cero_kernel), `LegacyDefs.gd` (3 buffs: protocolo_omega_cero/memoria_sinaptica/sintesis_vital), `RunManager.gd` (close_run grant + cross), `AchievementManager.gd` + `AchievementDefs.gd` (logro), `LocaleManager.gd` (ES+EN), `DebugPanel.gd` (3 botones).

---

## Rama B — Salir de la oscuridad

### REMISIÓN METABÓLICA — 🔮 pendiente de diseño detallado

*"La ciencia tampoco predijo esto."*

El hongo que sobrevivió lo imposible empieza a repararse.
Los pathways oscuros se integran al metabolismo normal, creando algo que no era ni hongo ni oscuridad.
La única ruta con "happy ending" del árbol.

**Condición (borrador):** Bio ≥ 200 dentro de Dark Met (extremadamente difícil con los penalties)
**Mecánica (borrador):**
- Desbloquea compras nuevamente pero a ×10 de costo (cicatrización estructural)
- Ω sube gradualmente +0.01/30s hasta 0.30
- ε_runtime deja de decaer
**PL:** base +5, +3 si se completan 3 compras post-remisión
**Nota de diseño:** Es la "ruta difícil con recompensa justa" — requiere dominar el Dark Met
**Flavor:** *"Algunos organismos no superan la oscuridad. Este la absorbió."*

**⚠️ Cross-link con PROTOCOLO OMEGA-CERO — "Síntesis Vital" (`sintesis_vital`):**
Al implementar REMISIÓN, verificar que `omega_remision_done` se setea al cerrar REMISIÓN si
`"PROTOCOLO OMEGA-CERO"` ya está en `endings_achieved` (o viceversa).
El placeholder en `LegacyManager.LEGACY_DEFS` ya existe desde la implementación de OMEGA-CERO.
Ver spec completa en la sección PROTOCOLO OMEGA-CERO arriba.

---

## Rama C — El legado de lo oscuro

### ESPORAS DE CONTINGENCIA
*"No todas las muertes son finales. Esta tampoco."*

Sabiendo que el colapso es inevitable, el hongo invierte todo en producir esporas
ultra-resistentes codificadas con la memoria de la bioquímica oscura.
Muere. Pero sus esporas recuerdan.

**Condición:** Dark Met activo + run_time ≥ 600s + cualquier cierre voluntario activado
**Mecánica:**
- El hongo cierra la run voluntariamente al activarla (no espera colapso)
- Produce un "Legado Oscuro" que se transmite a la siguiente run via LegacyManager
- En la siguiente run: un buff único "Memoria Oscura" activo desde el inicio
  - +15% Bio pasivo, ε decae 30% más lento, Depredador se activa 20% más rápido
**Interacción NG+:** Si la siguiente run llega a REENCARNACIÓN HEREDADA,
  el buff Memoria Oscura se vuelve permanente en el ciclo (stacks con legado_ciclo)
**PL:** base +4 (bajo, pero el valor real está en el buff transmitido)
**Flavor:** *"El ancestral que logró lo imposible deja algo que la ciencia tampoco esperaba."*

---

### ESCLEROCIO OSCURO  — ✅ IMPLEMENTADO (v1.0.0.11, 2026-06-02)

> **Estado:** implementado, validado y commiteado en `main`. Esta sección documenta
> el diseño final. Cambio clave respecto a la spec original: la Memoria Oscura es una
> **semilla durmiente** (activa en todas las runs mientras haya carga), no una carga
> que se consume al iniciar la run siguiente — eso hacía el cruce con Panspermia
> inalcanzable (Panspermia requiere `last_run == ESPORULACIÓN`, que se pisaba con el consumo).

> **Renombrado** de "Esporas de Contingencia". El nombre original colisionaba
> temáticamente con la rama biológica de esporas que ya existe (ESPORULACIÓN →
> PANSPERMIA NEGRA, familia BIOLOGÍA). El *esclerocio* es la estructura real con la
> que los hongos sobreviven condiciones hostiles: masa endurecida de micelio que
> entra en dormancia y germina cuando el ambiente mejora — exactamente el
> Metabolismo Oscuro (Ω 0.10, ε decayendo, biomasa oscura). Sin colisión de naming
> y más lore-accurate. Vive en la **familia COLAPSO**, no toca la rama BIOLOGÍA.

*"No es una semilla para crecer. Es una cápsula para recordar."*

Salida alternativa al sello normal de Metabolismo Oscuro. Cambia un poco de PL
inmediato por una carga latente que potencia la run siguiente — y, si esa run
llega a PANSPERMIA NEGRA, desbloquea un legado permanente que cruza COLAPSO×BIOLOGÍA.

**Gate de entrada (segundo botón en RightPanel, bajo el sello normal de MO) — lore-accurate, sin reloj fijo:**
- `EvoManager.mutation_met_oscuro == true`
- `EvoManager.met_oscuro_devoured_count >= 30` — autofagia: material consumido para endurecer el esclerocio (ya hay milestone en 30)
- `BiosphereEngine.biomasa >= 50` — masa de micelio suficiente para encapsular
- `StructuralModel.epsilon_runtime < 0.25` — domesticó la oscuridad antes de sellarla (MO ya hace decaer ε; premia esperar la autorregulación)
- `not RunManager.run_closed`

**Recompensa PL:**
- `PL_REWARDS["ESCLEROCIO OSCURO"] = 6`, `NG_CAPS = 8`
- Fórmula NG+ (t>=1): `min(floor(met_oscuro_devoured_count / 8), cap)` — premia cuánto devoraste

**Buff "Memoria Oscura" (SEMILLA DURMIENTE — activa en cada run mientras haya carga):**
- +15% crecimiento de biomasa (`BiosphereEngine._grow_biomass`, `MEMORIA_OSCURA_BIO_MULT`)
- ε resiste la entropía: su SUBIDA se amortigua 30% (`main.gd` cálculo de epsilon_runtime,
  `MEMORIA_OSCURA_EPS_RISE_DAMP`). Interpretación beneficiosa de "ε decae más lento" — el
  literal no servía en run normal (ε alto penaliza)
- −10% al threshold de activación de MO (`EvoManager`, `MEMORIA_OSCURA_MO_THRESH_MULT`)
- `RunManager.is_memoria_oscura_active()` → `dark_legacy_charges > 0 or legado permanente`

**Aplicación y consumo (semilla durmiente):**
- `LegacyManager.dark_legacy_charges: int` (meta-estado, persiste en save_legacy/
  build_legacy_data/deserialize). Es la ÚNICA fuente de verdad — NO hay flag per-run.
- Al cerrar por ESCLEROCIO OSCURO: `dark_legacy_charges += 1` (siembra)
- Mientras `> 0`: Memoria Oscura activa en TODAS las runs (no se consume al iniciar)
- Germina (consume 1) al cerrar por PANSPERMIA NEGRA → desbloquea el legado
- Se borra al trascender (como las esporas). Sin reembolso (ya no se consume al abandonar).

**Interacción NG+ → cruce con PANSPERMIA NEGRA:**
- Si hay semilla durmiente activa (`dark_legacy_charges > 0`) al cerrar por **PANSPERMIA NEGRA**,
  germina: `dark_legacy_charges -= 1` y (primera vez) `esclerocio_panspermia_done = true`,
  desbloqueando el legado **"Semilla Cósmica Oscura"** (`semilla_cosmica_oscura`).
- Une familia COLAPSO × familia BIOLOGÍA — el cruce que premia la Trascendencia.

**Legado `semilla_cosmica_oscura` (LegacyManager.LEGACY_DEFS):**
- `cat: "ng_plus"`, costo 8 PL, `max_level: 1`
- `reveal/unlock`: tipo nuevo `legacy_flag` → lee `esclerocio_panspermia_done`
  (branch agregado en `_check_condition` + `describe_unlock`)
- **Efecto:** Memoria Oscura **permanente** (vía `is_memoria_oscura_active()`) + ×3 pasivo
  (`SEMILLA_OSCURA_PASIVO_MULT` en `EconomyManager.get_passive_total`)
- `esclerocio_panspermia_done` se PRESERVA al trascender (el legado sigue desbloqueable)

**Implementado en:**
- Botón ESCLEROCIO + chip 🌑 header + lore de cierre: `main.gd`, `UIManager._build_run_end_lore`
- Cierre/cruce/siembra: `RunManager.close_run` + `is_memoria_oscura_active()`
- Logro Mythic "Esporas de Contingencia" (cerrar con 50+ devours): `AchievementManager`
- Lore variante de Panspermia si `esclerocio_panspermia_done`: `UIManager._build_run_end_lore`
- i18n ES/EN completo. Botón debug temporal en `DebugPanel` (F1): "Sembrar Esclerocio" + "Cruce Panspermia"
- Commit `9937274` (feature base) + rediseño semilla durmiente + lore (commit siguiente)
- Color reactor: prioridad en get_reactor_color() cuando salida disponible o buff activo
- Logro Mythic "El que se encapsuló" al primer cierre por ESCLEROCIO OSCURO

---

## Árbol de decisión completo

```
METABOLISMO OSCURO
├── (Bio ≥ 50 + upgrades)     → AUTÓLISIS DIRIGIDA
│   └── (timing perfecto)     → PL+6 máximo
│
├── (Ω decae a 0.05 natural)  → NECROSIS CONTROLADA
│   └── (Ω llega a 0.01)      → PROTOCOLO OMEGA-CERO → PL+8
│
├── (Bio ≥ 200)               → REMISIÓN METABÓLICA  → PL+8 total
│
└── (run_time ≥ 600s)         → ESPORAS DE CONTINGENCIA → buff NG+
```

---

## Notas de implementación

- Todas estas rutas requieren que Dark Met ya esté activo → son sub-rutas, no rutas paralelas
- Ninguna desbloquea Simbiosis ni Red Micelial (ya bloqueadas por Dark Met)
- ESPORAS es la más viable primero: usa sistemas existentes (LegacyManager, SaveManager)
- PROTOCOLO OMEGA-CERO es la más espectacular pero más compleja (Singularidad Inversa UI)
- Los colores sugeridos: Autólisis (naranja oscuro), Necrosis (rojo apagado), Omega-0 (blanco), Remisión (verde oscuro), Esporas (lila/gris)
- Revisar EvoManager para ver dónde enganchar los checks de condición

---

## Frases de flavor adicionales

- "La bioquímica oscura no tiene nombre en los libros. El hongo tampoco lo necesita."
- "Ω = 0. Los modelos matemáticos no contemplan este estado. El hongo sí."
- "Autofagia: consumirse para sobrevivir. El hongo lo hace con precisión quirúrgica."
- "Las esporas no saben que su creador ya no existe. Solo saben lo que aprendió."
