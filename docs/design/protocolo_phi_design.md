# PROTOCOLO Φ — Fago Algorítmico (v3)

**Tipo:** cuarta ruta post-trascendencia, junto a Vacío Hambriento, Carnaval y Reencarnación.
**Estado:** spec v3 (2026-10-18), sin implementar. Es la v2 recortada y re-anclada al juego.
La v2 completa queda archivada en `protocolo_phi_design_v2.md`: es la cantera para la Fase 3.
**Identidad:** el primer modo **activo** del juego. El hongo deja de observar su ecuación y pasa a **escribir
genoma sintético**. Lore: Evo (Arc Institute) diseñó genomas completos del fago ΦX174. **T** es la temperatura
de muestreo del modelo y **FC** el *fold change* del paper.

---

## 0. Qué cambió respecto de v2 (y por qué)

| v2 | v3 | Por qué |
|---|---|---|
| `PhiManager` autoload nuevo | `routes/RoutePhi.gd` (clase `PostTrasRoute`) registrada en `RouteManager.ROUTE_DEFS` | Hereda gratis el bloqueo de mutaciones, el save, la elección en el menú y el cierre. |
| `randf()` para outcome y ruido | Hash entero determinista (como las rupturas de Micelio) | Goldens y bot reproducibles. Salir y volver a entrar no re-tira el resultado. |
| FC = suma lineal → terna dominante, parcheada con Sobrecarga, Momentum y racha INERT | Módulos con trade-offs contra el sistema que ya existe: su ε empuja el ε de la run y Ω pone el **tope** del FC | La mejor terna depende del estado de la run; no hace falta castigar la repetición. |
| El virus multiplica la biomasa (exponencial) | El virus multiplica el **ingreso** | Con las mutaciones bloqueadas la biomasa no sirve, y la fórmula se disparaba. |
| Letal sólo con T > 0.9 | Letal gradual desde T 0.75 | La estrategia segura tiene que tener riesgo; si no, el slider pierde tensión. |
| Síntesis 15 s + virus 60 s | **8 s + 40 s** | Es el modo activo: más decisiones por minuto. |
| ~12 subsistemas | Núcleo + C con 2 acciones + Memoria Viral | Cada Sombra tuvo 4 palancas y necesitó 5–6 vueltas de calibración. |
| 5 finales + voluntario, 5 buffs genéticos, 3 cósmicos | 1 sello + 1 fracaso (con variante secreta) + voluntario; 1 cósmico + 1 legado | El Banco ya está cargado; mismo criterio que las Sombras. |

Se sacan de v1 (quedan en la v2 por si el bot muestra un loop monótono): Ventana de Óptimo Inestable, eventos
deterministas, sinergias, grupos/Resonancia, Momentum Viral, Sobrecarga de Laboratorio, racha INERT y los
módulos desbloqueables.

---

## 1. Posicionamiento y acceso

- Ruta post-trascendencia **elegible en la pantalla de rutas**, como Carnaval: `ROUTE_DEFS["phi"]`.
  - `tier: "avanzada"`, `min_tras: 5` (plan de T: contenido de T5, junto a las Redenciones), `consumable: true`.
  - `requires: {"cosmic": "phi_unlock", "ending": "METABOLISMO OSCURO"}`. Hay que extender
    `RouteManager._meets_requires` con esas dos claves.
- Mientras está activa:
  - `allows_bifurcation() = false`;
  - `update_genome` sale temprano con todas las mutaciones base en `bloqueado` (como las Sombras).
- **La economía normal sigue funcionando** (click, auto, trueque, mejoras). El loop Φ se suma encima.

## 2. El loop (≈ 50 s por ciclo)

```
ELEGIR 3 MÓDULOS → AJUSTAR T → [Q] SINTETIZAR (8 s) → OUTCOME → VIRUS (40 s) → repetir
```

- **Un virus a la vez**: no se puede sintetizar con un virus vivo. Durante la síntesis no se cambia nada.
- **Outcomes**:
  - **ALIVE**: el virus vive 40 s;
  - **INERT** (FC < 2): ciclo perdido, sin castigo;
  - **LETHAL**: ε +0.25 de golpe, C −30, sin virus.
- No se tipea ADN. La secuencia ATCG es una capa visual que el sistema genera a partir de los módulos.

## 3. Variables visibles

| Variable | Rango | Qué es |
|---|---|---|
| **T** (temperatura) | 0.50 – 1.00, pasos de 0.05 | El único control continuo: riesgo contra recompensa. |
| **C** (coherencia) | 0 – 100, arranca en 30 | Recurso gastable: reduce el riesgo letal y paga 2 acciones. |
| **FC** (fold change) | 0 – ~80 | El resultado del último virus. |

## 4. Fórmulas (primera propuesta, a calibrar con bot)

### 4.1 Aleatoriedad determinista
`u(salt) = hash32(phi_synth_index, ids de los módulos ordenados, round(T·100), salt) / 2³²`.
Es la misma familia que `_roll` de Micelio Omnisciente. El Reroll usa otro `salt`.

### 4.2 FC
```
fc_base = Σ fc(módulo)              # Splice: + duplica el menor, tope +10
t_mult  = 1 + (T − 0.70) · 3        # T 0.5 → ×0.4 · 0.7 → ×1.0 · 1.0 → ×1.9
ruido   = 0.80 + 0.40 · u(1)
fc_cap  = PHI_FC_CAP · (0.4 + Ω)    # Ω pone el techo: con la run estresada no hay F69
FC      = min(fc_base · t_mult · ruido, fc_cap)      # INERT si FC < 2
```

### 4.3 Riesgo letal
```
letal = max(0, (T − 0.75) · 2)       # 0 % hasta 0.75 · 50 % en 1.0
letal *= (1 − C / 200)               # C llena lo reduce a la mitad
letal *= (1 − defensa)               # módulos defensivos (Tropismo −30 %)
letal += letal_mod                   # Lisina +10 %
LETHAL si u(2) < letal
```

### 4.4 Costo en ε (lo que conecta Φ con el resto del juego)
Cada síntesis suma `Σ ε(módulo) · t_mult · 0.05` a una **perturbación** `phi_perturb`, que se agrega al objetivo
de ε en `StructuralModel`, igual que la P de Inestabilidad, y decae 0.01/s.
- Más ε baja Ω, y con Ω bajo cae el techo del FC.
- Los módulos agresivos rinden ahora y limitan las próximas síntesis.
- El Inhibidor (ε negativo) es la forma de recuperar el techo.

### 4.5 Virus ALIVE
`ingreso × (1 + FC / 20)` durante 40 s: FC 20 da ×2, FC 65 da ×4.25. Al terminar sin letal en el medio, C +8.

### 4.6 Coherencia: 2 acciones
| Acción | Costo | Efecto |
|---|---|---|
| **[W] Reroll** | 20 C | Re-tira el outcome de la síntesis recién resuelta, una vez por ciclo. |
| **[E] Estabilizar** | 15 C | Antes de sintetizar: el riesgo letal de esta síntesis se reduce a la mitad. |

## 5. Módulos (6, todos desde el principio)

| Módulo | FC | ε | Efecto | Rol |
|---|---|---|---|---|
| Cápside Básica | 5 | +1 | — | relleno estable |
| Replicasa Optimizada | 10 | +4 | — | daño, cuesta techo |
| Lisina Promotora | 8 | +3 | letal +10 % | agresivo |
| Splice Recursivo | 0 | +2 | duplica el FC del módulo menor (tope +10) | combinatorio |
| Tropismo Selectivo | 4 | 0 | letal −30 % | defensivo |
| Inhibidor Eucariota | 3 | −3 | baja ε → recupera Ω | reparador |

No hay terna dominante fija:
- Con la run limpia (Ω alto) conviene Replicasa + Lisina + Splice a T alta.
- Después del pico, el techo cae y hay que meter el Inhibidor o el Tropismo.

La Memoria Viral (§6) guarda las ternas que funcionaron.

## 6. Memoria Viral (la identidad de "deckbuilder")
- Un ALIVE con FC ≥ 20 guarda su patrón (3 módulos + T) en hasta 5 slots. Cargar un slot arma la síntesis con un
  click.
- Los slots duran lo que dura la run Φ.

## 7. Cierres

| Final | Condición | PL |
|---|---|---|
| **DOMINANCIA F69** (sello) | Un virus con FC ≥ 65 | +8 (+ bonus NG+) |
| **Sellar Φ** (voluntario, tras 5 min) | Botón | max FC < 20 → 2 · 20–40 → 4 · 40–65 → 6 |
| **CASCADA EPISTÁTICA** (fracaso) | 3 LETHAL en 120 s | +2 |
| **LISIS DEL INGENIERO** (variante secreta) | La cascada ocurre con C = 0 | +3 |

## 8. Recompensas
- **Cósmico** `phi_unlock` (10 Ξ, Banco Cósmico): habilita la ruta. Es contenido nuevo para el Banco Cósmico.
- **Legado: Vector Viral** (al sellar DOMINANCIA F69; sistema, no ×N): en las runs normales, **una vez por run** podés
  liberar el mejor virus de tu última Memoria Viral (`ingreso × (1 + FC/20)` durante 20 s). Es un puente entre Φ y
  el resto del juego.
- **Logros**:
  - Primer Viable (ESPORA): primer ALIVE;
  - Dominancia F69 (ANCESTRAL);
  - Deckbuilder Genético (FRUTO): 5 slots con FC ≥ 30;
  - Perplejidad Mínima (FRUTO): 10 ALIVE seguidos;
  - Lisis del Ingeniero (MYTHIC secreto);
  - **F69 Limpio** (MYTHIC): DOMINANCIA sin ningún LETHAL en la run. A validar con un bot experto: si no lo
    logra, se cambia la condición (lección de Antibiosis).

## 9. Integración

| Archivo | Cambio |
|---|---|
| `routes/RoutePhi.gd` (nuevo) | Estado del loop, `tick`, `serialize/deserialize`, `production_mult` (el virus), cierres. Constantes `PHI_*` en Balance. |
| `RouteManager.gd` | `ROUTE_DEFS["phi"]`, `requires` cosmic + ending. |
| `EvoManager.gd` | Salida temprana de `update_genome` con `RouteManager.is_active("phi")`. |
| `StructuralModel.gd` | `+ phi_perturb` al objetivo de ε (al lado de la P de Inestabilidad). |
| `UITextBuilders` / `UIManager` | El panel de la ruta reemplaza al de genoma: módulos, T, C, FC, Memoria. |
| `NGPlusButtonManager` | Botones de módulos, T −/+, [Q] Sintetizar, [W] Reroll, [E] Estabilizar, Sellar, slots de Memoria. |
| `main.gd` | Teclas Q/W/E; A/D para T ±0.05. |
| `RunManager` | Finales, PL, NG+ (`max_fc / 10`, tope 8), legado. |
| LegacyDefs, AchievementDefs, CodexDefs, LocaleManager | Lo de §8, en ES/EN. |
| `tests/sim` | Política del bot y escenarios (§10), trayectoria golden. |

## 10. Calibración con bot (objetivos)

| Escenario | Esperado |
|---|---|
| `phi_player`: rota ternas según el techo, T 0.8–0.85, Estabiliza con C ≥ 40 | DOMINANCIA F69 en 12–18 min |
| `phi_safe`: T ≤ 0.75 siempre | Nunca llega a 65: sella voluntario con 4–6 PL |
| `phi_greedy`: T 1.0, siempre la terna de más FC | CASCADA EPISTÁTICA en pocos minutos |
| `phi_afk`: no sintetiza | No cierra solo; sella voluntario o queda abierta (economía normal). A decidir si necesita un timeout. |
| `a3_phi_limpio`: experto | F69 sin letales → MYTHIC (si no lo logra, cambiar la condición) |

## 11. Fases
1. **Núcleo**: RoutePhi + 6 módulos + T + síntesis/outcome/virus + C con 2 acciones + cierres + panel + bot.
2. **Memoria Viral + logros + legado Vector Viral + Compendio.**
3. **Sólo si el bot muestra un loop monótono**: traer piezas de la v2, una por vez.

## 12. Preguntas abiertas para el autor
1. ¿T5 te parece bien, o la querés en T6, con el Fantasma?
2. ¿El AFK dentro de Φ necesita un cierre automático? Ejemplo: 5 min sin sintetizar cierran como Sellar Φ con lo
   que haya.
3. ¿El legado Vector Viral te convence, o preferís una recompensa de visibilidad como las de las Sombras?
