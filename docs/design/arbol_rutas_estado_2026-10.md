# Árbol de rutas — estado real (2026-10-17)

> Fuente única para redibujar el árbol de evoluciones (el artifact y `docs/arbol_evoluciones.png` quedaron
> viejos). Todo lo marcado **hoy** está implementado en el juego; lo marcado **plan** está decidido pero no
> implementado. Colores = paleta del núcleo 2026-10-16 (`UIManager.get_reactor_color()`).
> Docs de detalle: `involucion_transmutaciones.md`, `biologia_mutualismo_endosimbiosis.md`,
> `auditoria_gameplay_2026-10.md`, `../roadmaps/pendientes_2026-10.md`.

## 1. Familias y colores

| Familia | Tono del núcleo | Rutas |
|---|---|---|
| Base | celeste `#26a6ff` | núcleo sin mutación |
| Colapso | rojos | Hiperasimilación `#f20d0d`, Depredador `#ff0054`, Fractura (destello) `#e6f4ff` |
| Oscuro | violetas / apagados | Met. Oscuro `#8745ab`, Autofagia `#a60a2e`, Necrosis `#408014`, Esclerocio (sellado) `#3a2410`, Omega-Cero `#a58ce0`, Colapso Sintético (sellado) `#003a30` |
| Biología | naranja → rosa | Parasitismo `#ff7300`, Simbiosis `#ff8fd0`, Mutualismo `#ffc2a8`, Holobionte `#e8578f`, Endosimbiosis `#ff9a5c` |
| Red micelial | verdes | Red Micelial `#4cff4c`, Colonización `#b0ff1a`, Esporulación `#c8ffa0`, Seta `#e0b070`, Simbiosis Mecánica `#00e6ff` |
| Orden | turquesas | Homeostasis `#0de0ad`, Allostasis `#00a88a`, Homeorresis `#b5fff0`, Núcleo de Conciencia `#a8c4ff` |
| Redención | luz | Remisión `#fff1d6` |
| Post-trascendencia | violeta | Vacío Hambriento `#bf33ff` |
| Transmutaciones (A→A+) | complemento de su base | Fusión oro `#f7c20d`, Caos fucsia `#ff2bd0`, Coro coral `#ff6b5c`, Micelio violeta `#b86bff`, Huésped índigo `#4a52ff` |
| Sombras (A→anti-A) | casi negro | Ayuno `#262e38` (sellado plateado `#8c9eb3`) |
| Fracaso | apagado | Micelio Fragmentado `#6b4a6b` |

## 2. Mutaciones base (columna 1) — T0

| Mutación | Cómo entra | Final (PL base) |
|---|---|---|
| **Hiperasimilación** | activo > 80 %, ε > 0.4, biomasa > 4, sin Contabilidad, run > 180 s (60 s si T > 2) | HIPERASIMILACIÓN (1) — colapso por saturación |
| **Parasitismo** | 120 s sin clickear con biomasa > 3 · Masa Crítica (biomasa > 6, ε > 0.35, sin Contabilidad, run > 420 s) · estancamiento (run > 30 min) | PARASITISMO (2) |
| **Simbiosis** | Contabilidad ≥ 1, hifas ≥ 5, Ω ≥ 0.40, click dominante | SIMBIOSIS (4) — botón a los 60 s o sola tras 300 s en banda |
| **Homeostasis** | ε en banda 0.03–0.30, Ω, flujos duales | HOMEOSTASIS (3) |
| **Red Micelial** | hifas / micelio | (no cierra sola: bifurca) |

## 3. Evoluciones por familia

**Orden** — Homeostasis → **Allostasis** (4) → **Homeorresis** (8). Tiers dentro de la misma run.

**Red micelial** — bifurcación (botón "Decidir después" + ELEGIR RAMA para volver):
- **Colonización** (empujar la frontera) → Primordio (regar) → **Seta** → **ESPORULACIÓN** (5) o **PANSPERMIA NEGRA** (10, ventana de lanzamiento).
- **Simbiosis Mecánica** (Ω ≥ 0.50) → **Núcleo de Conciencia** → **SINGULARIDAD** (6 + bonus por ε bajo) o **MENTE COLMENA DISTRIBUIDA** (8, ráfaga IA).

**Biología** (nuevo, 2026-10):
- Simbiosis → **MUTUALISMO** (T1, 6): negociar ofertas con la Raíz. Abusar del socio → cierra como PARASITISMO; dar de más → SIMBIOSIS.
- Mutualismo → **HOLOBIONTE** (T2, 8): sostener 4 socios (Raíz, Bacteria, Alga, Levadura). 5 muertes → cierra como MUTUALISMO.
- **ENDOSIMBIOSIS** (T2, 8): cruce. `last_run` Parasitismo (o Huésped) + Simbiosis → botón ENGULLIR. Transferir 6 genes dosificando; rechazo o escape → PARASITISMO.

**Colapso**:
- **Depredador** (T > 1 o `last_run` Parasitismo; ε > 0.95 en Hiper) → **DEPREDADOR DE REALIDADES** (12) o **COLAPSO DEPREDATORIO** (8).
- **Fractura Epistémica** (buff cósmico; Hiper con ε > 0.90 sostenido 20 s, run > 4 min) → **COLAPSO CONTROLADO** (6).
- Depredador → **Metabolismo Oscuro** (devorar 10, biomasa 50, plata crítica) → **METABOLISMO OSCURO** (4) o sus sub-rutas:

| Sub-ruta del árbol oscuro | Acceso (Banco Genético) | Final (PL) |
|---|---|---|
| Esclerocio | T ≥ 1 (30 PL) | ESCLEROCIO OSCURO (6) |
| Autofagia | cerrar Depredador de Realidades (50 PL) | AUTOFAGIA NECRÓTICA (6) |
| Necrosis | cerrar MO, Esclerocio o Autofagia (50 PL) | NECROSIS CONTROLADA (5) |
| Omega-Cero | cerrar Autofagia + Necrosis + Esclerocio (100 PL) | PROTOCOLO OMEGA-CERO (8); su fracaso → COLAPSO SINTÉTICO (0) |
| **Remisión** (Redención) | cerrar las 4 anteriores (15 PL) | REMISIÓN METABÓLICA (8); falla → vuelve a Met. Oscuro |

**Post-trascendencia** (rutas de run): Vacío Hambriento → ASCESIS PROFUNDA (7) · Carnaval → POLIMORFÍA TOTAL (9) / DOMADOR DEL CAOS (11) · Reencarnación.

## 4. Involución (T3): transmutaciones A → A+ y su fracaso

Llave en el Banco (15 PL, tras cerrar la base). Con la base activa aparece el botón **[T]** (3 veces en ~5 min); al revertir, la base se **digiere** en un recurso inicial.

| Base | Transmutación (verbo) | Sello (PL 9) | **Fracaso → vuelve a la base** |
|---|---|---|---|
| Hiperasimilación | **Fusión Catabólica** (ráfaga + sumidero) | $ generados + $ en ráfagas + estructura | 3 ráfagas FORZADAS seguidas (durante el enfriamiento) funden el motor → HIPERASIMILACIÓN |
| Homeostasis | **Caos Orquestado** (ε como combustible) | Gran Colapso: ε ≥ 1.8 y $5M en la ráfaga | 5 Grandes Colapsos fallidos → HOMEOSTASIS |
| Simbiosis | **Coro Simbiótico** (ritmo: sólo acentos) | partitura 16 / 20 / 24 acentos (80 / 95 / 110 BPM) | 8 acentos seguidos sin acertar → SIMBIOSIS |
| Red Micelial | **Micelio Omnisciente** (asignar micelio a 9 nodos) | 9 nodos llenos 60 s; rupturas pseudoaleatorias + [W] Reforzar | 4 nodos llenos rotos → **MICELIO FRAGMENTADO** (3, final propio: nunca hubo seta) + Legado Cicatriz Micelial |
| Parasitismo | **Huésped Soberano** (domesticar el hambre) | confianza nivel 5 | hambre en 100 durante 15 s → PARASITISMO |

Legados al sellar: Motor Fundido (Fusión), Batuta (Caos), Compás Interno (Coro), Nodo Latente (Micelio), Pacto Soberano (Huésped).

**Sombras (A → anti-A)** — disparador espejo, no hay botón:
- **Ayuno Primordial** (anti-Hiper, 8): con la llave y **Hiperasimilación latente**, 60 s sin clickear con pasivo ≥ 10/s y ε < 0.10. Si entra Parasitismo durante el ayuno → Trampa del Vacío (cierra PARASITISMO).
- **Inestabilidad Consciente** (anti-Homeostasis, 9; lore matemático): con la llave, habiendo tenido Homeostasis elegible y Contabilidad ≥ 1, acumular 45 s con ε ≥ 0.45 (un bajón descuenta, no reinicia). [Q] OBSERVAR revela lemas (P +0.20, y cada lema abierto sigue empujando), [W] INTEGRAR baja P. Sello **Q.E.D.**: 5 lemas (impulso, Lyapunov, inercia, estructura, elasticidad). Fracaso → HOMEOSTASIS: diverge (ε > 1.2 10 s) o converge (ε < 0.35 60 s). Recompensa: los 3 legados de conocimiento + Lema de Lyapunov. Spec `docs/design/sombras.md` §9.
- **Procariota** (anti-Endosimbiosis, 9): con la llave, dejar pasar ENGULLIR sin engullir. Colonia logística (ingreso ×0.3 → ×2.0); toxinas desde el 90 % → lisis. [W] Quorum desde el 80 % (× 1 + 4·N/K), [Q] cosechar, [E] plásmido (resistencia / virulencia / metabólico). Sello: 8 quorums. Fracaso → SIMBIOSIS: 3 lisis o extinción. Recompensa: Legado Plásmido (expresión génica de los legados). Spec §10.
- **Antibiosis** (anti-Simbiosis, 9; ex Autarquía): con la llave, Simbiosis elegible antes, hifas ≥ 5, click dominante y ε ≥ 0.40, 45 s acumulados. Rivales que roban ingreso (×0.8 cada uno, nacen resistentes a un antibiótico); [Q] [W] [E] antibióticos con resistencia global: hay que rotar. Sello: 15 rivales. Fracaso → SIMBIOSIS: 3 rivales vivos. Recompensa: Legado Penicilina (el parásito, a la vista en el panel de ε). Spec §11.

## 5. Estructura por trascendencia (plan decidido 2026-10-16; hoy todas las llaves se revelan en T ≥ 3)

| T | Se abre |
|---|---|
| 0 | mutaciones base + ramas directas |
| 1 | post-trascendencia + **Mutualismo** |
| 2 | árbol oscuro (Depredador / MO y sub-rutas) + **Holobionte** + **Endosimbiosis** |
| 3 | las 5 transmutaciones |
| 4 | Sombras (Ayuno pasa acá) |
| 5 | Redenciones (Remisión pasa acá) |
| 6 | Fantasma (combos de 2 llaves) |

## 6. Huecos y plan (no implementado)

- **Sombras** pendientes (spec `docs/design/sombras.md`): Autosuficiencia (anti-Parasitismo), Hifa Pionera (anti-Red Micelial, ex Núcleo Aislado; fracaso → final propio HIFA EXTRAVIADA).
- **Redenciones**: Redención de la Red (tras Esporulación / Panspermia; candidata a salir de Micelio Fragmentado), Redención del Orden (tras Singularidad / Mente Colmena), Redención de la Biología.
- **Fantasma** (2 llaves): Dualidad Corrosiva (Fusión + Huésped), Eco Silencioso (Micelio + Caos).
- **Secretas**: Glitch Supremo, El Susurro (0 PL, desde MO), El Origen.
- **Meta**: Jardín Primigenio → Retorno al Origen (v2.0).
